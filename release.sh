#!/usr/bin/env bash
#
# release.sh - prepare and publish an RF-Swift image release.
#
# Pipeline: produce a dev image (fresh BUILD or incremental UPDATE), then TAG it
# into the release registry as <image>_<version>_<arch> (+ the <image>_<arch>
# "latest"), matching the tagged_release_* workflows.
#
#   ./release.sh build   <image> --arch amd64
#   ./release.sh update  <image> --arch amd64 --version 1.0.1 [--mode recipe|latest|force]
#   ./release.sh tag     <image> --arch amd64 --version 1.0.1 [--source <tag>]
#   ./release.sh release <image> --arch amd64 --version 1.0.1 --from build|update
#
# release = (build | update, per --from) then tag, in one shot.
#
# <image> may be 'all' (every image, in dependency order) and --arch may be
# 'all' (amd64 arm64 riscv64). They combine: ./release.sh release all --arch all
# --version X.Y.Z --from build|update. The run keeps going past a failing image
# and prints an ok/FAILED summary per arch.
#
#   build   : fresh `make` build -> pushes dev  <DEV>:<image>_<arch>      (overwrites base)
#   update  : rfswift_update in container -> pushes dev <DEV>:<image>_<arch>_<version> (rebased)
#   tag     : imagetools retag a dev image -> <REL>:<image>_<version>_<arch> and <REL>:<image>_<arch>
#
# Requires: docker (with buildx) and `docker login` to the registries first.

set -euo pipefail

# ---- defaults (override via flags / env) ----------------------------------
ARCH="amd64"
ALL_ARCHS="amd64 arm64 riscv64"
VERSION=""
FROM="build"                 # for 'release': build | update
MODE="recipe"                # for update: recipe | latest | force
BRANCH="${RFSWIFT_SCRIPTS_BRANCH:-ubuntu_resolute}"
APT="true"                   # update apt phase
SOURCE=""                    # override tag source for 'tag'
DRYRUN="false"
DEV_REGISTRY="${DEV_REGISTRY:-penthertz/rfswiftdev_resolute}"
RELEASE_REGISTRY="${RELEASE_REGISTRY:-penthertz/rfswift_resolute}"

VALID_IMAGES="corebuild sdrsa_devices sdr_light sdr_gnuradio4 sdr_full automotive android osint reversing rfid network ad wifi bluetooth hardware telecom_utils telecom_2Gto3G telecom_4G_5GNSA telecom_5G deeptempest"
# Topological order (each image builds FROM an earlier one). Used for `all`.
ALL_IMAGES="corebuild sdrsa_devices sdr_light sdr_gnuradio4 sdr_full reversing rfid automotive android osint network ad wifi bluetooth hardware deeptempest telecom_utils telecom_2Gto3G telecom_4G_5GNSA telecom_5G"

# ---- helpers ---------------------------------------------------------------
die()  { printf '\033[1;31m[!] %s\033[0m\n' "$*" >&2; exit 1; }
info() { printf '\033[1;32m[+] %s\033[0m\n' "$*"; }
run()  { printf '\033[1;34m+ %s\033[0m\n' "$*"; [ "$DRYRUN" = true ] || "$@"; }

usage() { sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

# Image tag -> Makefile target (most are identity; a few differ).
make_target() {
    case "$1" in
        corebuild)     echo common ;;
        sdrsa_devices) echo sdrsadevices ;;
        sdr_light)     echo sdrlight ;;
        sdr_gnuradio4) echo sdrgnuradio4 ;;
        sdr_full)      echo sdrfull ;;
        *)             echo "$1" ;;
    esac
}

require_version() { [ -n "$VERSION" ] || die "this command needs --version X.Y.Z"; }
valid_image() { case " $VALID_IMAGES " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

# ---- operations ------------------------------------------------------------
do_build() {
    local image="$1" target; target="$(make_target "$image")"
    info "Fresh build: $image (make $target, arch=$ARCH) -> ${DEV_REGISTRY}:${image}_${ARCH}"
    ( cd "$(dirname "$0")/Dockerfiles" && \
      run env STORAGE_TYPE=registry ARCH="$ARCH" \
              CACHE_REPO="$DEV_REGISTRY" REGISTRY_IMAGE="$DEV_REGISTRY" \
              make "$target" )
}

do_update() {
    local image="$1"
    require_version
    local src="${DEV_REGISTRY}:${image}_${ARCH}"
    local dest="${DEV_REGISTRY}:${image}_${ARCH}_${VERSION}"
    info "Incremental update (rebased): $src -> $dest"

    local flags="--sync"
    [ "$APT" = "true" ] || flags="$flags --no-apt"
    case "$MODE" in latest) flags="$flags --latest" ;; force) flags="$flags --force" ;; esac

    run docker pull --platform "linux/${ARCH}" "$src"

    local ep="null" cmd="null"
    if [ "$DRYRUN" = false ]; then
        ep="$(docker inspect -f '{{json .Config.Entrypoint}}' "$src" 2>/dev/null || echo null)"
        cmd="$(docker inspect -f '{{json .Config.Cmd}}' "$src" 2>/dev/null || echo null)"
        if ! docker run --rm --platform "linux/${ARCH}" --entrypoint sh "$src" \
                -c 'command -v rfswift_update >/dev/null' 2>/dev/null; then
            die "$src has no rfswift_update -- build it fresh first (./release.sh build $image)"
        fi
    fi

    run docker rm -f rfrelease >/dev/null 2>&1 || true
    # shellcheck disable=SC2086
    run docker run --name rfrelease --platform "linux/${ARCH}" \
        -e RFSWIFT_SCRIPTS_BRANCH="$BRANCH" \
        --entrypoint /usr/sbin/rfswift_update "$src" $flags

    local commit=(docker commit)
    [ "$ep"  != "null" ] && commit+=(--change="ENTRYPOINT $ep")
    [ "$cmd" != "null" ] && commit+=(--change="CMD $cmd")
    run "${commit[@]}" rfrelease "$dest"
    run docker push "$dest"
    run docker rm -f rfrelease >/dev/null 2>&1 || true
}

do_tag() {
    local image="$1" source_tag="$2"
    require_version
    local rel_v="${RELEASE_REGISTRY}:${image}_${VERSION}_${ARCH}"
    local rel_l="${RELEASE_REGISTRY}:${image}_${ARCH}"
    info "Release tag: $source_tag -> $rel_v (+ latest $rel_l)"
    run docker buildx imagetools create --tag "$rel_v" --tag "$rel_l" "$source_tag"
}

# Run one command for one image.
do_one() {
    local cmd="$1" image="$2"
    case "$cmd" in
        build)  do_build "$image" ;;
        update) do_update "$image" ;;
        tag)    do_tag "$image" "${SOURCE:-${DEV_REGISTRY}:${image}_${ARCH}}" ;;
        release)
            case "$FROM" in
                build)  do_build "$image";  do_tag "$image" "${DEV_REGISTRY}:${image}_${ARCH}" ;;
                update) do_update "$image"; do_tag "$image" "${DEV_REGISTRY}:${image}_${ARCH}_${VERSION}" ;;
                *) die "bad --from '$FROM' (build|update)" ;;
            esac ;;
    esac
}

# Run one command across every image (dependency order); keep going on failure.
run_all() {
    local cmd="$1" img ok=() fail=()
    info "Running '$cmd' for ALL images (arch=$ARCH): $ALL_IMAGES"
    for img in $ALL_IMAGES; do
        echo; info "================= $cmd: $img ================="
        if ( do_one "$cmd" "$img" ); then ok+=("$img"); else fail+=("$img"); fi
    done
    echo
    info "ALL '$cmd' summary: ${#ok[@]} ok, ${#fail[@]} failed"
    [ ${#ok[@]}   -gt 0 ] && printf '    ok    : %s\n' "${ok[*]}"
    if [ ${#fail[@]} -gt 0 ]; then
        printf '\033[1;31m    FAILED: %s\033[0m\n' "${fail[*]}"
        return 1
    fi
    return 0
}

# ---- arg parsing -----------------------------------------------------------
[ $# -ge 1 ] || usage 1
CMD="$1"; shift || true
case "$CMD" in build|update|tag|release) ;; -h|--help|help) usage 0 ;; *) die "unknown command: $CMD (build|update|tag|release)" ;; esac

[ $# -ge 1 ] || die "missing <image> ('all' or one of: $VALID_IMAGES)"
IMAGE="$1"; shift || true
[ "$IMAGE" = "all" ] || valid_image "$IMAGE" || die "unknown image '$IMAGE'. Use 'all' or: $VALID_IMAGES"

while [ $# -gt 0 ]; do
    case "$1" in
        --arch)             ARCH="$2"; shift 2 ;;
        --version)          VERSION="${2#v}"; shift 2 ;;   # strip leading v
        --from)             FROM="$2"; shift 2 ;;
        --mode)             MODE="$2"; shift 2 ;;
        --branch)           BRANCH="$2"; shift 2 ;;
        --source)           SOURCE="$2"; shift 2 ;;
        --no-apt)           APT="false"; shift ;;
        --dry-run)          DRYRUN="true"; shift ;;
        --dev-registry)     DEV_REGISTRY="$2"; shift 2 ;;
        --release-registry) RELEASE_REGISTRY="$2"; shift 2 ;;
        -h|--help)          usage 0 ;;
        *) die "unknown option: $1" ;;
    esac
done
# Resolve the arch list ('all' -> every arch).
if [ "$ARCH" = "all" ]; then ARCHS="$ALL_ARCHS"; else ARCHS="$ARCH"; fi
for a in $ARCHS; do
    case "$a" in amd64|arm64|riscv64) ;; *) die "bad arch '$a' (amd64|arm64|riscv64|all)" ;; esac
done
case "$CMD" in tag|release) require_version ;; esac

# ---- dispatch (arch x image matrix) ----------------------------------------
overall_fail=0
for a in $ARCHS; do
    ARCH="$a"   # consumed by do_one/do_build/do_update/do_tag
    [ "$ARCH" = all ] || info "########## arch: $ARCH ##########"
    if [ "$IMAGE" = "all" ]; then
        run_all "$CMD" || overall_fail=1
    elif ( do_one "$CMD" "$IMAGE" ); then
        :
    else
        printf '\033[1;31m[!] %s failed for %s (%s)\033[0m\n' "$CMD" "$IMAGE" "$ARCH"
        overall_fail=1
    fi
done

[ "$overall_fail" -eq 0 ] || die "one or more operations failed (see summary above)"
info "Done."
