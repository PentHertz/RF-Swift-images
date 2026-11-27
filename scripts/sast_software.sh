#!/bin/env bash

# Adapted from (tested on ubuntu 22.04):
# https://github.com/20urc3/Talks/tree/main/leHack

# set -euo pipefail // -> some scripts fails to install properly, and binaries are normally working. TODO: Need see why some install processes are failing with it.


function LLVM_install() { # newest stable LLVM from apt.llvm.org; no riscv64 builds there
    # ARCH is not set globally: each ./entrypoint.sh call is its own process
    local ARCH
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]] || [[ "$ARCH" == "amd64" ]] || [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        # apt.llvm.org publishes 21+ for resolute (17-20 are 404); the distro ships 21 and 22
        LLVM_VERSION=23

        goodecho "[+] installing LLVM ${LLVM_VERSION}"

        [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
        cd /root/thirdparty

        rm -f llvm.sh  # wget -c would append to a stale copy
        installfromnet "wget" "-q" "-O" "llvm.sh" "https://apt.llvm.org/llvm.sh"

        chmod +x llvm.sh
        ./llvm.sh ${LLVM_VERSION}  # clang, lldb, lld, clangd (versioned names: clang-${LLVM_VERSION}, ...)
        # llvm-config plus llvm-objdump/-readelf/-nm/-symbolizer/... (bin dir /usr/lib/llvm-N/bin)
        install_dependencies "llvm-${LLVM_VERSION}"

        # Clang picks the newest /usr/lib/gcc/<triple>/N even when that GCC has no libstdc++
        # headers (resolute: libopenmpi-dev -> gfortran-16 brings GCC 16's dir while only
        # libstdc++-15-dev is installed), and then every C++ build fails on <atomic>. If so,
        # pin it to the system gcc's install dir through clang's default config files.
        local llvm_bin="/usr/lib/llvm-${LLVM_VERSION}/bin" gcc_dir cfg
        if command -v gcc > /dev/null 2>&1 && [ -x "${llvm_bin}/clang" ] \
            && ! echo '#include <atomic>' | "${llvm_bin}/clang++" -x c++ -fsyntax-only - > /dev/null 2>&1; then
            gcc_dir=$(dirname "$(gcc -print-libgcc-file-name)")
            for cfg in clang clang++; do
                echo "--gcc-install-dir=${gcc_dir}" > "${llvm_bin}/${cfg}.cfg"
            done
            if echo '#include <atomic>' | "${llvm_bin}/clang++" -x c++ -fsyntax-only - > /dev/null 2>&1; then
                goodecho "[+] clang-${LLVM_VERSION} pinned to ${gcc_dir} (libstdc++ headers)"
            else
                record_build_failure "build" "llvm-${LLVM_VERSION}" "clang++ cannot find libstdc++ headers"
            fi
        fi

        # Export LLVM_CONFIG for interactive shells (and keep it through sudo); an export
        # here would die with this process.
        if command -v "llvm-config-${LLVM_VERSION}" > /dev/null 2>&1; then
            local rc line="export LLVM_CONFIG=llvm-config-${LLVM_VERSION}"
            for rc in ~/.zshrc ~/.bashrc; do
                [ -f "$rc" ] || continue
                sed -i '/^export LLVM_CONFIG=llvm-config-[0-9]*$/d' "$rc"
                echo "$line" >> "$rc"
            done
            if [ -d /etc/sudoers.d ]; then
                echo 'Defaults env_keep += "LLVM_CONFIG"' > /etc/sudoers.d/rfswift-llvm
                chmod 0440 /etc/sudoers.d/rfswift-llvm
            fi
        fi
    fi
}

function semgrep_install() {
    goodecho "[+] installing Semgrep"
    pip3install "semgrep"
}

function cppcheck_install() {
    goodecho "[+] installing cppcheck"
    install_dependencies "cppcheck"
}

function AFL_install() {
    goodecho "[+] installing AFL++"
    install_dependencies "clang build-essential afl++"
}

function honggfuzz_install() {
    goodecho "[+] Checking system architecture..."
    ARCH=$(uname -m)
    if [ "$ARCH" = "riscv64" ]; then
        criticalecho-noexit "[-] honggfuzz: -mtune=native unsupported under QEMU RISC-V64, skipping"
        return 0
    fi
    if [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]]; then
        criticalecho-noexit "[-] Unsupported architecture: $ARCH"
        criticalecho-noexit "    Honggfuzz installation is supported only on arm64/aarch64 or amd64."
        return 0
    fi
    goodecho "[+] Architecture $ARCH supported. Proceeding with installation."
    goodecho "[+] Installing honggfuzz"
    install_dependencies "binutils-dev libunwind-dev libblocksruntime-dev git"
    [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    cd /root/thirdparty
    git clone https://github.com/google/honggfuzz
    cd honggfuzz && make && make install
}

function clang_static_analyzer_install() {
    echo "[+] installing clang-static-analyzer"
    install_dependencies "clang clang-tools"
}

function joernsast_install() {
    echo "[+] Installing Joern"
    install_dependencies "apt-transport-https curl gnupg"
    echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo tee /etc/apt/sources.list.d/sbt.list
    echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt_old.list

    # Fetch ASCII-armored key, dearmor to binary, write directly to trusted keyring
    curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" \
        | gpg --dearmor \
        | sudo tee /etc/apt/trusted.gpg.d/scalasbt-release.gpg > /dev/null
    sudo chmod 644 /etc/apt/trusted.gpg.d/scalasbt-release.gpg

    # One bad third-party list makes apt-get update exit 100 and errexit abort the layer,
    # e.g. corebuild's netbird repo serving a Release file dated in the future ("not valid
    # yet"). The other lists still refresh, and a missing sbt is caught by install_dependencies.
    sudo apt-get update || criticalecho-noexit "[!] apt-get update reported errors, continuing with the lists that refreshed"
    install_dependencies "sbt"
    [ -d /sast ] || mkdir -p /sast
    cd /sast
    gitinstall "https://github.com/FlUxIuS/joern.git"
    cd joern
    sbt stage
    for bin in joern joern-cli joern-export joern-flow joern-parse joern-scan joern-slice joern-vectors c2cpg.sh; do
        ln -sf $(pwd)/${bin} /usr/local/bin/${bin}
    done
    ln -sf $(pwd)/c2cpg.sh /usr/local/bin/c2cpg
}

function trivy_install() {
    # Trivy: vulnerability / misconfig / secret / SBOM scanner for container
    # images, filesystems and repos -- used here to triage extracted firmware
    # and dependency trees during reversing.
    goodecho "[+] Installing Trivy"

    local arch asset
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)  asset="Linux-64bit" ;;
        aarch64|arm64) asset="Linux-ARM64" ;;
        *)             asset="" ;;
    esac

    # Prefer the upstream install script (fetches the prebuilt release binary for
    # the detected arch into /usr/local/bin, tracking the latest release).
    if [ -n "$asset" ]; then
        installfromnet "curl" "-sfL" "https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh" "-o" "/tmp/trivy-install.sh"
        if [ -s /tmp/trivy-install.sh ]; then
            sh /tmp/trivy-install.sh -b /usr/local/bin
            rm -f /tmp/trivy-install.sh
        fi
        if command -v trivy >/dev/null 2>&1; then
            goodecho "[+] Trivy installed: $(command -v trivy)"
            return 0
        fi
        record_build_failure "download" "trivy" "install script failed; falling back to go install"
    fi

    # No prebuilt binary for this arch (e.g. riscv64) or the download failed:
    # build from source with the Go toolchain from corebuild's install_go.
    ensure_go
    if command -v go >/dev/null 2>&1; then
        GOBIN=/usr/local/bin go install github.com/aquasecurity/trivy/cmd/trivy@latest \
            || record_build_failure "build" "trivy" "go install failed"
    else
        record_build_failure "build" "trivy" "no prebuilt binary for $arch and go unavailable"
    fi
}

function sighthound_install() {
    # Sighthound: tree-sitter based static vulnerability scanner (pattern +
    # source->sink taint flow) over Python/JS/TS/Java/PHP/C#/Go/Ruby, with
    # text/JSON/CSV/SARIF output. Complements semgrep in the reversing SAST set.
    # Not published on crates.io and ships no release binaries -> build from git
    # with the rustup toolchain from corebuild's rust_tools (needs Rust 1.85+).
    goodecho "[+] Installing Sighthound"
    if ! command -v cargo >/dev/null 2>&1; then
        record_build_failure "build" "sighthound" "cargo toolchain unavailable"
        return 0
    fi
    local repo="https://github.com/Corgea/Sighthound.git"
    # Prefer the pinned Cargo.lock for a reproducible build; retry unlocked if the
    # lockfile can't resolve against the installed toolchain.
    cargo install --git "$repo" --bin sighthound --root /usr/local --locked \
        || cargo install --git "$repo" --bin sighthound --root /usr/local \
        || record_build_failure "build" "sighthound" "cargo install --git failed"
}
