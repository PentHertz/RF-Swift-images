# shellcheck shell=bash
# This file is part of the RF Swift project (GPL-3.0-or-later, see LICENSE).
# Helpers shared by generate-sbom.sh and image-inventory.sh (sourced, not run).

COMPLIANCE_REGISTRY_IMAGE=${REGISTRY_IMAGE:-penthertz/rfswiftdev_resolute}

# compliance_image_ref TAG_OR_REF: a bare RF Swift tag (network_amd64) becomes
# $REGISTRY_IMAGE:network_amd64; a reference with "/", ":" or "@" is kept as is.
compliance_image_ref() {
    case $1 in
        */* | *:* | *@*) printf '%s\n' "$1" ;;
        *) printf '%s:%s\n' "$COMPLIANCE_REGISTRY_IMAGE" "$1" ;;
    esac
}

# compliance_strip_scheme REF: drop a syft source scheme (registry:, docker:, ...).
compliance_strip_scheme() {
    case $1 in
        registry:* | docker:* | podman:* | containerd:* | docker-archive:* | oci-archive:* | oci-dir:* | singularity:*)
            printf '%s\n' "${1#*:}" ;;
        *) printf '%s\n' "$1" ;;
    esac
}

# compliance_prefix REF: output file prefix, e.g. rfswiftdev_resolute_network_amd64.
compliance_prefix() {
    local ref name
    ref=$(compliance_strip_scheme "$1")
    name=${ref##*/}
    name=${name//[^A-Za-z0-9._-]/_}
    printf '%s\n' "${name:-image}"
}

# compliance_platform REF: linux/<arch> from the tag's arch (<image>_<arch>,
# <image>_<arch>_<version> or <image>_<version>_<arch>), or nothing.
compliance_platform() {
    local tag
    tag=$(compliance_strip_scheme "$1")
    tag=${tag##*/}
    tag=${tag%%@*}
    case $tag in
        *:*_amd64 | *:*_amd64_*) printf 'linux/amd64\n' ;;
        *:*_arm64 | *:*_arm64_*) printf 'linux/arm64\n' ;;
        *:*_riscv64 | *:*_riscv64_*) printf 'linux/riscv64\n' ;;
    esac
}

# compliance_sha256 DIR FILE...: SHA-256 lines for files relative to DIR.
compliance_sha256() {
    local dir=$1
    shift
    if command -v sha256sum > /dev/null 2>&1; then
        (cd "$dir" && sha256sum "$@")
    else
        (cd "$dir" && shasum -a 256 "$@")
    fi
}
