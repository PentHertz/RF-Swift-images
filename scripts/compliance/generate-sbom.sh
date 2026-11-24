#!/usr/bin/env bash
# This file is part of the RF Swift project (GPL-3.0-or-later, see LICENSE).
#
# Adapted from scripts/generate-sbom.sh of Drost Community Edition
# (https://github.com/drost-ai/drost-community), Copyright 2026 Drost, licensed
# under the Apache License, Version 2.0 (scripts/compliance/LICENSE-Apache-2.0).
# Changed for RF Swift: RF Swift image tags and platforms, all-layers scope,
# image inventory pick-up, text and JSON policy reports, checksums over them.
#
# Usage: generate-sbom.sh IMAGE [OUT_DIR] [PLATFORM]
#   IMAGE     an RF Swift tag (network_amd64 -> $REGISTRY_IMAGE:network_amd64,
#             default repository penthertz/rfswiftdev_resolute) or any image
#             reference syft accepts, optionally with a scheme (registry:...)
#   OUT_DIR   output directory (default: compliance-out)
#   PLATFORM  e.g. linux/arm64 (default: taken from the tag's _<arch>)
#
# Writes <prefix>.cdx.json (CycloneDX), <prefix>.spdx.json (SPDX), the policy
# report <prefix>.policy.txt / <prefix>.policy.json and SHA256SUMS-<prefix>,
# where <prefix> is the image name and tag (rfswiftdev_resolute_network_amd64).
# Exits with the policy check's status: 1 when a blocked component is found.
#
# Environment:
#   SYFT_FROM   syft source, e.g. "registry" to read the registry rather than
#               a local Docker daemon (do not combine with a registry: prefix)
#   SYFT_SCOPE  layers to catalog (default all-layers: files deleted by a later
#               layer are still distributed with the image)
#   POLICY      policy file (default compliance/license-policy.json)
#   INVENTORY   inventory from image-inventory.sh (default
#               OUT_DIR/<prefix>.inventory.tsv when that file exists)
set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/compliance/common.sh
source "$here/common.sh"

if [[ $# -lt 1 || $# -gt 3 || -z $1 ]]; then
    echo "usage: $0 IMAGE [OUT_DIR] [PLATFORM]" >&2
    echo "example: $0 network_amd64 compliance-out" >&2
    exit 2
fi

image=$(compliance_image_ref "$1")
out=${2:-compliance-out}
platform=${3:-$(compliance_platform "$image")}
policy=${POLICY:-$here/../../compliance/license-policy.json}
scope=${SYFT_SCOPE:-all-layers}
prefix=$(compliance_prefix "$image")

for tool in syft python3; do
    if ! command -v "$tool" > /dev/null 2>&1; then
        echo "error: $tool is required (syft: https://github.com/anchore/syft)" >&2
        exit 1
    fi
done

mkdir -p "$out"
cdx="$out/$prefix.cdx.json"
spdx="$out/$prefix.spdx.json"
report_txt="$out/$prefix.policy.txt"
report_json="$out/$prefix.policy.json"

arguments=(
    scan "$image"
    --scope "$scope"
    --override-default-catalogers package
    --select-catalogers=-file
    --output "cyclonedx-json=$cdx"
    --output "spdx-json=$spdx"
)
if [[ -n $platform ]]; then
    arguments+=(--platform "$platform")
fi
if [[ -n ${SYFT_FROM:-} ]]; then
    arguments+=(--from "$SYFT_FROM")
fi

echo "syft: scanning $image${platform:+ ($platform)}, scope $scope" >&2
SYFT_CHECK_FOR_APP_UPDATE=false \
SYFT_FILE_METADATA_SELECTION=none \
SYFT_PACKAGE_EXCLUDE_BINARY_OVERLAP_BY_OWNERSHIP=false \
SYFT_RELATIONSHIPS_PACKAGE_FILE_OWNERSHIP=false \
SYFT_RELATIONSHIPS_PACKAGE_FILE_OWNERSHIP_OVERLAP=false \
    syft "${arguments[@]}"

check=(python3 -I "$here/check-license-policy.py" "$cdx" --policy "$policy" --json "$report_json")
inventory=${INVENTORY:-$out/$prefix.inventory.tsv}
if [[ -s $inventory ]]; then
    check+=(--inventory "$inventory")
elif [[ -n ${INVENTORY:-} ]]; then
    echo "error: inventory $INVENTORY is missing or empty" >&2
    exit 2
fi

status=0
"${check[@]}" 2>&1 | tee "$report_txt" || status=$?

files=("$(basename "$cdx")" "$(basename "$spdx")" "$(basename "$report_txt")")
if [[ -f $report_json ]]; then
    files+=("$(basename "$report_json")")
fi
compliance_sha256 "$out" "${files[@]}" > "$out/SHA256SUMS-$prefix"

for file in "${files[@]}" "SHA256SUMS-$prefix"; do
    echo "wrote $out/$file" >&2
done
exit "$status"
