#!/bin/bash

set -eo pipefail

### Part picket from Exegol project with love <3 (https://github.com/ThePorgs/Exegol)

export RED='\033[1;31m'
export BLUE='\033[1;34m'
export GREEN='\033[1;32m'
export NOCOLOR='\033[0m'

### Echo functions

function colorecho () {
    echo -e "${BLUE}$*${NOCOLOR}"
}

function criticalecho () {
    echo -e "${RED}$*${NOCOLOR}" 2>&1
    exit 1
}

function criticalecho-noexit () {
    echo -e "${RED}$*${NOCOLOR}" 2>&1
}

### </3 Love comes to an end

function goodecho () {
    echo -e "${GREEN}$*${NOCOLOR}" 2>&1
}

# ---------------------------------------------------------------------------
# Build failure reporting
#
# record_build_failure logs anything that failed to install during a build so
# we can keep track of tools that did not make it into the image. Each failure
# is both appended to a TSV report baked into the image and echoed as a
# uniquely greppable marker line so it always shows up in CI logs, even when a
# later step hard-fails and the image is never produced.
#
# Report columns (TAB separated): category  stage  item  detail
#   category : apt | git | pip | build | net | other
#   stage    : which install script raised it (RFSWIFT_BUILD_STAGE or source file)
#   item     : the package / repo / step that failed
#   detail   : short reason
# ---------------------------------------------------------------------------
RFSWIFT_BUILD_REPORT="${RFSWIFT_BUILD_REPORT:-/var/lib/db/rfswift_build_report.tsv}"
RFSWIFT_REPORT_MARKER="::RFSWIFT-BUILD-FAILURE::"

function record_build_failure() {
    local category="$1" item="$2" detail="$3"
    local stage="${RFSWIFT_BUILD_STAGE:-$(basename "${BASH_SOURCE[1]:-unknown}" .sh)}"
    # strip tabs/newlines so the TSV stays one record per line
    item="${item//$'\t'/ }"; item="${item//$'\n'/ }"
    detail="${detail//$'\t'/ }"; detail="${detail//$'\n'/ }"
    [ -d "$(dirname "$RFSWIFT_BUILD_REPORT")" ] || mkdir -p "$(dirname "$RFSWIFT_BUILD_REPORT")" 2>/dev/null
    printf '%s\t%s\t%s\t%s\n' "$category" "$stage" "$item" "$detail" >> "$RFSWIFT_BUILD_REPORT" 2>/dev/null
    # greppable single-line marker for CI logs
    criticalecho-noexit "${RFSWIFT_REPORT_MARKER} ${category} | ${stage} | ${item} | ${detail}"
}

# Pretty-print the accumulated report (used as the last build step / on demand).
function print_build_report() {
    if [ ! -s "$RFSWIFT_BUILD_REPORT" ]; then
        goodecho "[=] Build report: no install failures recorded \\o/"
        return 0
    fi
    criticalecho-noexit "[=] Build report: the following items failed to install"
    printf 'CATEGORY\tSTAGE\tITEM\tDETAIL\n'
    cat "$RFSWIFT_BUILD_REPORT"
    local n; n=$(wc -l < "$RFSWIFT_BUILD_REPORT")
    criticalecho-noexit "[=] ${n} failure(s) recorded in ${RFSWIFT_BUILD_REPORT}"
    return 0
}

function installfromnet() {
    n=0
    until [ "$n" -ge 5 ]
    do
        colorecho "[Internet][Download] Try number: $n"
        $* && break
        n=$((n+1))
        sleep 15
    done
}

# Best-effort apt install: try the whole list, and if that fails fall back to
# installing each package individually so one missing package no longer aborts
# the build (or silently drops the rest of the list). Every package that still
# cannot be installed is recorded in the build report. Always returns 0.
function install_dependencies() {
    local dependencies=$1
    goodecho "[+] Installing dependencies: ${dependencies}"

    # Fast path: bulk install. Guarded by `if` so errexit never aborts here.
    if apt-fast install -y ${dependencies}; then
        return 0
    fi

    criticalecho-noexit "[!] Bulk install failed -- retrying package-by-package to isolate the culprits"
    local pkg ok=0 bad=0
    for pkg in ${dependencies}; do
        if apt-fast install -y "$pkg" > /dev/null 2>&1; then
            ok=$((ok + 1))
        else
            record_build_failure "apt" "$pkg" "no installation candidate or unmet dependencies"
            bad=$((bad + 1))
        fi
    done
    goodecho "[+] Dependencies for this group: ${ok} installed, ${bad} failed (see build report)"
    return 0
}

function grclone_and_build() {
    local repo_url=$1
    local repo_subdir=$2
    local method=$3  # Custom method name
    local build_dir="build"
    local branch=""
    shift 3

    # Check if a branch is specified (e.g., -b branch_name)
    if [[ $1 == "-b" ]]; then
        branch=$2
        shift 2
    fi

    local reset_commit=""
    if [[ $1 == "-c" ]]; then
        reset_commit=$2
        shift 2
    fi

    local cmake_args=("$@")  # Capture all remaining arguments as CMake arguments

    # Create the base directory if it doesn't exist
    [ -d /rftools/sdr/oot ] || mkdir -p /rftools/sdr/oot
    cd /rftools/sdr/oot || exit

    # If no subdirectory is provided, use the repository name as the build directory
    if [ -z "$repo_subdir" ]; then
        repo_subdir=$build_dir
    else
        repo_subdir=$repo_subdir/$build_dir
    fi

    # Clone the repository and switch to the specified branch if provided
    cmake_clone_and_build "$repo_url" "$repo_subdir" "$branch" "$reset_commit" "$method" "-DCMAKE_INSTALL_PREFIX=/usr/local" "${cmake_args[@]}"
}

function gitinstall() {
    # Extract the repository URL from the argument
    repo_url="$1"
    method="$2"
    branch="$3"
    
    # Extract the repository name (last part of the URL without .git)
    repo_name=$(basename "$repo_url" .git)

    # Check if the repository already exists in the current directory
    if [ -d "$repo_name" ]; then
        colorecho "Repository '$repo_name' already exists. Pulling latest changes..."
        cd "$repo_name" || exit
        installfromnet "git pull"
        if [ $? -eq 0 ]; then
            goodecho "Repository '$repo_name' updated successfully."
        else
            criticalecho-noexit "Failed to update the repository."
        fi
        cd ..
    else
        # Clone the repository with the specified branch if provided
        if [ -n "$branch" ]; then
            installfromnet "git clone -b $branch $repo_url"
        else
            installfromnet "git clone $repo_url"
        fi

        # installfromnet swallows the exit code, so judge success by whether the
        # checkout actually exists rather than by $?.
        if [ -d "$repo_name" ]; then
            # Ensure the directory /var/lib/db/ exists, create if not
            if [ ! -d "/var/lib/db/" ]; then
                sudo mkdir -p /var/lib/db/
            fi

            # Get the absolute path of the repository
            repo_abs_path="$(pwd)/$repo_name"
            cd $repo_name
            # Attempt to update submodules; continue regardless of success
            git submodule update --init --recursive || {
                goodecho "Failed to update submodules, but continuing."
            }
            cd ..

            # Append the repository name, absolute path, and method to the file
            echo "$repo_name:$repo_abs_path:$method" | sudo tee -a /var/lib/db/rfswift_github.lst > /dev/null

            colorecho "Repository '$repo_name' cloned successfully."
            colorecho "Added '$repo_name $repo_abs_path' to /var/lib/db/rfswift_github.lst"
        else
            # Best-effort: record the gap and let the build continue instead of
            # aborting the whole image for one unreachable repository.
            record_build_failure "git" "$repo_name" "clone failed: $repo_url"
            return 1
        fi
    fi
}

function cmake_clone_and_build() {
    local repo_url=$1
    local build_dir=$2  # This should be a path relative to the repo root
    local branch=$3
    local reset_commit=$4
    local method=$5
    shift 5
    local cmake_args=("$@")

    local repo_name=$(basename "$repo_url" .git)

    echo "Checking directory for: $repo_name"

    if [ ! -d "$repo_name" ]; then
        echo "Cloning repository..."
        gitinstall "$repo_url" "$method" "$branch"
        cd "$repo_name" || exit
        should_build=true
    else
        echo "Repository exists. Ensuring it's up to date..."
        cd "$repo_name" || exit
        installfromnet "git fetch"
        local LOCAL=$(git rev-parse @)
        local REMOTE=$(git rev-parse @{u})
        if [ "$LOCAL" != "$REMOTE" ]; then
            installfromnet "git pull"
            should_build=true
        else
            echo "No updates needed."
            should_build=false
        fi
    fi

    if [ -n "$reset_commit" ]; then
        echo "Resetting repository to commit/tag $reset_commit"
        git reset --hard "$reset_commit"
    fi

    if [ "$should_build" = true ]; then
        if [ ! -d "$build_dir" ]; then
            echo "Creating build directory..."
            mkdir -p "$build_dir"
        fi
        cd "$build_dir" || exit
        echo "Running CMake and building..."
        cmake "${cmake_args[@]}" ../
        make -j$(nproc)
        sudo make install
        cd ..
        rm -rf build/ # Cleaning build directory
    fi
}

function check_and_install_lib() {
    local lib_name=$1
    local pkg_config_name=$2

    # Check if the library is installed using pkg-config
    if pkg-config --exists "$pkg_config_name"; then
        goodecho "[+] $lib_name is already installed."
    else
        colorecho "[!] $lib_name is not installed. Attempting to install..."
        
        # Attempt to install the library using apt-get
        installfromnet "apt-fast update"
        installfromnet "apt-fast -y install $lib_name"

        # Verify the installation
        if pkg-config --exists "$pkg_config_name"; then
            goodecho "[+] $lib_name has been successfully installed."
        else
            criticalecho "[!] Failed to install $lib_name. Please check the package name or install it manually."
        fi
    fi
}

function pip3install() {
    local n=0
    local install_args="$*"  # Capture all arguments passed to the function
    
    goodecho "[+] Installing Python package(s): ${install_args}"
    
    # Try up to 5 times
    until [ "$n" -ge 5 ]
    do
        colorecho "[pip3][Install] Try number: $n"
        if [[ "$install_args" == *"-r "* ]] || [[ "$install_args" == *"--requirement "* ]]; then
            # Handle requirements file installation
            pip3 install --break-system-packages --ignore-installed $install_args && {
                goodecho "[+] Successfully installed packages from requirements file"
                return 0
            }
        else
            # Handle single package or other pip arguments
            pip3 install --break-system-packages --ignore-installed $install_args && {
                goodecho "[+] Successfully installed ${install_args}"
                return 0
            }
        fi
        n=$((n+1))
        sleep 15
    done
    
    record_build_failure "pip" "${install_args}" "pip install failed after 5 attempts"
    return 1
}

# ---------------------------------------------------------------------------
# In-container incremental updater
#
# Rebuilds an installed tool by re-running the install function that built it.
# That function is the single source of truth for the tool's version, so this
# honours every manual pin in the scripts regardless of how it is expressed:
#   * a hardcoded download version  (ghidra_version="12.1.2", IDE_VERSION, the
#     Spike/VSG60 filename strings, ...)
#   * a git commit/tag pin          (cmake_clone_and_build ... -c <sha>,
#                                     `git reset --hard <tag>`)
#   * a floating git checkout        (no pin -- tracks upstream)
#
# Which functions are managed: every install function dispatched through
# entrypoint.sh is recorded in the components manifest
# (/var/lib/db/rfswift_components.lst) at build time. Older git tools recorded
# only in the git manifest (/var/lib/db/rfswift_github.lst) are picked up too.
#
# Rebuild trigger (this is what makes manual versions safe):
#   * default  -> rebuild a tool only when its install function's SOURCE text
#                 changed since the last run -- i.e. you edited the version in
#                 the script and re-synced. Untouched pins are never rebuilt
#                 and the updater never chases upstream on its own.
#   * --latest -> additionally fetch floating git tools and rebuild any whose
#                 upstream HEAD moved. Use only for tools you want to float;
#                 pinned tools re-pin themselves, so this is a no-op for them.
#   * --force  -> rebuild every managed tool regardless.
#
# First run on a freshly built image has no recipe state, so it adopts the
# current function hashes as the baseline and rebuilds nothing (unless
# --force/--latest) -- the image already matches its scripts.
#
# To pick up newly published install logic before rebuilding, sync the scripts
# first (the run/rfswift_update wrapper's --sync flag, or update_rfscripts).
#
# Usage (inside a running container):
#   rfswift_update                 # apt upgrade + rebuild recipe-changed tools
#   rfswift_update --latest        # also pull/rebuild floating git tools
#   rfswift_update --no-apt        # skip the apt phase
#   rfswift_update --force         # rebuild every managed tool
#   rfswift_update ghidra uv       # only tools whose function name matches
# ---------------------------------------------------------------------------
RFSWIFT_MANIFEST="${RFSWIFT_MANIFEST:-/var/lib/db/rfswift_github.lst}"
RFSWIFT_COMPONENTS="${RFSWIFT_COMPONENTS:-/var/lib/db/rfswift_components.lst}"
RFSWIFT_STATE="${RFSWIFT_STATE:-/var/lib/db/rfswift_state.lst}"
# Install functions that are not safe/meaningful to re-run unattended
# (append to rc files, or fully covered by the apt phase). Override via env.
RFSWIFT_UPDATE_SKIP="${RFSWIFT_UPDATE_SKIP:-rfswift_shell_setup docker_preinstall print_build_report record_build_failure}"

# Record an install function as a managed component (called from entrypoint.sh
# at build time). Also seals the build-time recipe hash as the update baseline,
# so a freshly built image ships with correct state: a later rfswift_update can
# tell which tools the scripts changed *since this image was built*, and rebuild
# exactly those. Without this seal, the first update on a fresh base would see
# no state, treat it as baseline, and rebuild nothing.
function rfswift_register_component() {
    local fn="$1"
    [ -n "$fn" ] || return 0
    declare -f "$fn" > /dev/null 2>&1 || return 0   # only real functions
    [ -d "$(dirname "$RFSWIFT_COMPONENTS")" ] || sudo mkdir -p "$(dirname "$RFSWIFT_COMPONENTS")"
    touch "$RFSWIFT_COMPONENTS" "$RFSWIFT_STATE"
    grep -qxF "$fn" "$RFSWIFT_COMPONENTS" 2>/dev/null || echo "$fn" | sudo tee -a "$RFSWIFT_COMPONENTS" > /dev/null
    # First seal wins (the hash of the recipe actually used to build this image).
    grep -q "^${fn}:" "$RFSWIFT_STATE" 2>/dev/null || \
        echo "${fn}:$(_rfswift_fnhash "$fn")" | sudo tee -a "$RFSWIFT_STATE" > /dev/null
}

# Stable hash of an install function's source, used to detect recipe changes.
function _rfswift_fnhash() {
    declare -f "$1" 2>/dev/null | sha1sum | cut -d' ' -f1
}

function rfswift_update() {
    local do_apt=true force=false latest=false
    local -a only=()
    local arg
    for arg in "$@"; do
        case "$arg" in
            --no-apt) do_apt=false ;;
            --force)  force=true ;;
            --latest) latest=true ;;
            --*)      criticalecho-noexit "[!] Unknown option: $arg" ;;
            *)        only+=("$arg") ;;
        esac
    done

    # The loop must survive a failing tool, so relax errexit for orchestration
    # and re-enable it strictly inside each rebuild subshell.
    local restore_e=false
    case "$-" in *e*) restore_e=true ;; esac
    set +e

    if [ "$do_apt" = true ]; then
        goodecho "[+] Refreshing apt packages (upgrade only, no removals)"
        installfromnet "apt-fast update"
        DEBIAN_FRONTEND=noninteractive installfromnet "apt-fast upgrade -y" \
            || criticalecho-noexit "[!] apt upgrade reported errors; continuing"
    fi

    # Collect the managed install functions: the components manifest is the
    # primary source; the git manifest's method field is folded in so tools
    # from images built before the components manifest existed still work.
    local -A managed=() fnpath=()
    local line fn name path method
    if [ -f "$RFSWIFT_COMPONENTS" ]; then
        while read -r fn; do
            [ -n "$fn" ] && declare -f "$fn" > /dev/null 2>&1 && managed["$fn"]=1
        done < "$RFSWIFT_COMPONENTS"
    fi
    if [ -f "$RFSWIFT_MANIFEST" ]; then
        while IFS=: read -r name path method; do
            [ -n "$method" ] && declare -f "$method" > /dev/null 2>&1 || continue
            managed["$method"]=1
            [ -d "$path/.git" ] && fnpath["$method"]="$path"   # for --latest
        done < "$RFSWIFT_MANIFEST"
    fi

    if [ "${#managed[@]}" -eq 0 ]; then
        goodecho "[+] No managed install functions found; nothing to rebuild (apt phase done)"
        [ "$restore_e" = true ] && set -e
        return 0
    fi

    # Load recorded recipe hashes; absence of the state file means first run.
    local -A state=()
    local baseline=false sname shash
    if [ -f "$RFSWIFT_STATE" ]; then
        while IFS=: read -r sname shash; do
            [ -n "$sname" ] && state["$sname"]="$shash"
        done < "$RFSWIFT_STATE"
    else
        baseline=true
        goodecho "[+] No recipe state yet -- recording current versions as baseline (no rebuilds)"
    fi

    local -a updated=() skipped=() failed=() floated=()

    for fn in "${!managed[@]}"; do
        # skip-list
        case " $RFSWIFT_UPDATE_SKIP " in *" $fn "*) continue ;; esac

        # optional name filter: substring match against the function name
        if [ "${#only[@]}" -gt 0 ]; then
            local match=false o
            for o in "${only[@]}"; do [[ "$fn" == *"$o"* ]] && match=true; done
            [ "$match" = true ] || continue
        fi

        local curhash; curhash=$(_rfswift_fnhash "$fn")
        local reason=""
        if [ "$force" = true ]; then
            reason="forced"
        elif [ "$baseline" = false ] && [ "${state[$fn]:-}" != "$curhash" ]; then
            reason="install recipe changed"
        elif [ "$latest" = true ] && [ -n "${fnpath[$fn]:-}" ]; then
            local p="${fnpath[$fn]}"
            ( cd "$p" && installfromnet "git fetch --quiet" ) \
                || criticalecho-noexit "[!] $fn: git fetch failed"
            local localrev remoterev
            localrev=$(git -C "$p" rev-parse @ 2>/dev/null || true)
            remoterev=$(git -C "$p" rev-parse @{u} 2>/dev/null || true)
            if [ -n "$remoterev" ] && [ "$localrev" != "$remoterev" ]; then
                reason="upstream advanced (--latest)"
                floated+=("$fn")
            fi
        fi

        if [ -z "$reason" ]; then
            skipped+=("$fn")
            state["$fn"]="$curhash"               # keep baseline current
            continue
        fi

        colorecho "[~] $fn: rebuilding (${reason})"
        if ( set -e; "$fn" ); then
            updated+=("$fn")
            state["$fn"]="$curhash"               # only record on success
        else
            failed+=("$fn")                       # leave stale so it retries
        fi
    done

    # Persist updated recipe state.
    if [ "${#state[@]}" -gt 0 ]; then
        [ -d "$(dirname "$RFSWIFT_STATE")" ] || sudo mkdir -p "$(dirname "$RFSWIFT_STATE")"
        local k
        : > "$RFSWIFT_STATE"
        for k in "${!state[@]}"; do echo "$k:${state[$k]}" >> "$RFSWIFT_STATE"; done
    fi

    echo
    goodecho            "[=] Update summary"
    goodecho            "    rebuilt/updated : ${updated[*]:-none}"
    [ "$latest" = true ] && colorecho "    floated to HEAD : ${floated[*]:-none}"
    colorecho           "    already current : ${skipped[*]:-none}"
    [ "${#failed[@]}" -gt 0 ] && criticalecho-noexit "    FAILED          : ${failed[*]}"

    [ "$restore_e" = true ] && set -e
    [ "${#failed[@]}" -gt 0 ] && return 1
    return 0
}
