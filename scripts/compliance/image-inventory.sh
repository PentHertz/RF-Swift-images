#!/usr/bin/env bash
# This file is part of the RF Swift project (GPL-3.0-or-later, see LICENSE).
#
# Adapted from scripts/generate-license-bundle.sh and scripts/check-image-compliance.sh
# of Drost Community Edition (https://github.com/drost-ai/drost-community), Copyright
# 2026 Drost, licensed under the Apache License, Version 2.0
# (scripts/compliance/LICENSE-Apache-2.0). Changed for RF Swift: probes taken from
# the licence policy, RF Swift's install records, git checkouts with their commits,
# and the RF Swift tool roots searched for licence texts.
#
# Usage: image-inventory.sh IMAGE [PLATFORM]
#   IMAGE     an RF Swift tag (network_amd64 -> $REGISTRY_IMAGE:network_amd64) or
#             an image reference Docker can run
#   PLATFORM  e.g. linux/arm64 (default: taken from the tag's _<arch>)
#
# Runs the image three times (docker run --rm --network none --entrypoint sh) and
# writes to $OUT_DIR (default compliance-out), <prefix> being the image name and tag:
#   <prefix>.inventory.tsv               input for check-license-policy.py --inventory
#                                        (generate-sbom.sh picks it up): RF Swift install
#                                        functions, commands and paths of the policy's
#                                        components that are present, Debian packages,
#                                        git checkouts
#   <prefix>.debian-source-packages.tsv  source, source version, binary, version
#   <prefix>.git-checkouts.tsv           path, remote URL, commit of each git checkout
#                                        under the tool roots (the source of what was built)
#   <prefix>.license-texts.tar.gz        copyright, LICENSE*, COPYING*, NOTICE* files
#   <prefix>.rfswift-records.tar.gz      /var/lib/db/rfswift_* (install records, build report)
#   INVENTORY-SHA256SUMS-<prefix>
# Only the final filesystem is visible here: files deleted by a later layer are still
# distributed in the image's layers (the all-layers SBOM covers the packages among them).
set -euo pipefail

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/compliance/common.sh
source "$here/common.sh"

if [[ $# -lt 1 || $# -gt 2 || -z $1 ]]; then
    echo "usage: $0 IMAGE [PLATFORM]" >&2
    echo "example: OUT_DIR=compliance-out $0 network_amd64" >&2
    exit 2
fi

image=$(compliance_strip_scheme "$(compliance_image_ref "$1")")
platform=${2:-$(compliance_platform "$image")}
policy=${POLICY:-$here/../../compliance/license-policy.json}
out=${OUT_DIR:-compliance-out}
prefix=$(compliance_prefix "$image")

for tool in docker python3; do
    if ! command -v "$tool" > /dev/null 2>&1; then
        echo "error: $tool is required" >&2
        exit 1
    fi
done

# "exe:NAME" and "path:PREFIX" probes for every component the policy names
probe_text=$(python3 -I - "$policy" << 'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    policy = json.load(handle)
seen = set()
for section in ("blocked_components", "review_required_components", "notice_required_components"):
    for entry in policy.get(section, []):
        match = entry.get("match") or {}
        for kind, key in (("exe", "executables"), ("path", "paths")):
            for value in match.get(key, []):
                probe = f"{kind}:{value}"
                if probe not in seen:
                    seen.add(probe)
                    print(probe)
PY
)
mapfile -t probes <<< "$probe_text"

docker_arguments=(run --rm --network none)
if [[ -n $platform ]]; then
    docker_arguments+=(--platform "$platform")
fi
docker_arguments+=(--entrypoint sh "$image" -c)

# Inventory: one "kind<TAB>value..." line per finding (see check-license-policy.py)
read -r -d '' inventory_script << 'SH' || true
# rfswift-inventory: inventory
set -u
if [ -r /var/lib/db/rfswift_components.lst ]; then
    awk 'NF { print "func\t" $1 }' /var/lib/db/rfswift_components.lst | sort -u
fi
for probe in "$@"; do
    kind=${probe%%:*}
    value=${probe#*:}
    case $kind in
        exe)
            if found=$(command -v "$value" 2> /dev/null) && [ -n "$found" ]; then
                resolved=$(readlink -f "$found" 2> /dev/null) || resolved=$found
                printf 'exe\t%s\t%s\n' "$value" "${resolved:-$found}"
            fi
            ;;
        path)
            case $value in
                */) if [ -e "${value%/}" ]; then printf 'path\t%s\n' "${value%/}"; fi ;;
                *) for candidate in "$value"*; do
                       if [ -e "$candidate" ] || [ -L "$candidate" ]; then
                           printf 'path\t%s\n' "$candidate"
                       fi
                   done ;;
            esac
            ;;
    esac
done
if command -v dpkg-query > /dev/null 2>&1; then
    dpkg-query -W -f='deb\t${source:Package}\t${source:Version}\t${binary:Package}\t${Version}\n' 2> /dev/null | sort -u
fi
head_commit() {
    gitdir=$1
    head=$(cat "$gitdir/HEAD" 2> /dev/null) || return 0
    case $head in
        "ref: "*)
            ref=${head#ref: }
            if [ -f "$gitdir/$ref" ]; then
                cat "$gitdir/$ref"
            elif [ -f "$gitdir/packed-refs" ]; then
                awk -v ref="$ref" '$2 == ref { print $1; exit }' "$gitdir/packed-refs"
            fi
            ;;
        *) printf '%s\n' "$head" ;;
    esac
}
for root in /opt /rftools /telecom /hardware /reverse /automotive /security /nettools /sast /mobile /root /usr/local/src /usr/src; do
    [ -d "$root" ] || continue
    find "$root" -maxdepth 6 \( -name node_modules -o -name site-packages -o -name dist-packages \) -prune \
        -o -name .git -print 2> /dev/null
done | sort -u | while IFS= read -r gitpath; do
    repo=${gitpath%/.git}
    gitdir=$gitpath
    if [ -f "$gitpath" ]; then
        gitdir=$(sed -n 's/^gitdir: //p' "$gitpath")
        case $gitdir in /*) ;; *) gitdir=$repo/$gitdir ;; esac
    fi
    remote=$(git -C "$repo" config --get remote.origin.url 2> /dev/null) \
        || remote=$(sed -n 's/^[[:space:]]*url[[:space:]]*=[[:space:]]*//p' "$gitdir/config" 2> /dev/null | head -n 1)
    commit=$(git -C "$repo" rev-parse HEAD 2> /dev/null) || commit=$(head_commit "$gitdir")
    remote=$(printf '%s' "$remote" | sed 's#://[^/@]*@#://#')
    printf 'git\t%s\t%s\t%s\n' "$repo" "${remote:-unknown}" "${commit:-unknown}"
done
exit 0
SH

# Licence texts: Ubuntu copyright files and the files found
# in the tool roots, Python/npm/Go/Rust package trees
read -r -d '' licence_script << 'SH' || true
# rfswift-inventory: licence texts
set -u
roots=""
for root in /usr/share/doc /usr/share/common-licenses /usr/share/licenses \
    /usr/local/share /usr/local/lib /usr/lib/node_modules /usr/lib/python3/dist-packages \
    /opt /rftools /telecom /hardware /reverse /automotive /security /nettools /sast /mobile \
    /root /usr/local/src; do
    if [ -d "$root" ]; then roots="$roots $root"; fi
done
# shellcheck disable=SC2086
find $roots -name .git -prune -o -xtype f \
    \( -iname copyright -o -iname 'copyright.*' -o -iname 'licen[cs]e*' -o -iname 'copying*' \
       -o -iname 'notice*' -o -iname 'third_party_notices*' -o -iname 'thirdpartynotices*' \
       -o -path '*/LICENSES/*' \) \
    ! -iname '*.py' ! -iname '*.pyc' ! -iname '*.js' ! -iname '*.mjs' ! -iname '*.ts' \
    ! -iname '*.go' ! -iname '*.c' ! -iname '*.h' ! -iname '*.cpp' ! -iname '*.class' \
    ! -iname '*.json' ! -iname '*.png' ! -iname '*.svg' \
    -print0 2> /dev/null \
    | sort -zu \
    | tar --null --no-recursion --dereference --ignore-failed-read -T - -czf -
SH

# RF Swift's own install records: git manifest, managed components, build report
read -r -d '' records_script << 'SH' || true
# rfswift-inventory: records
set --
for file in /var/lib/db/rfswift_*; do
    if [ -e "$file" ]; then set -- "$@" "${file#/}"; fi
done
if [ "$#" -gt 0 ]; then
    tar -C / -czf - "$@"
else
    tar -czf - -T /dev/null
fi
SH

mkdir -p "$out"
inventory="$out/$prefix.inventory.tsv"
debs="$out/$prefix.debian-source-packages.tsv"
gits="$out/$prefix.git-checkouts.tsv"
licences="$out/$prefix.license-texts.tar.gz"
records="$out/$prefix.rfswift-records.tar.gz"

echo "docker: inventory of $image${platform:+ ($platform)}" >&2
{
    printf '# image-inventory.sh %s%s\n' "$image" "${platform:+ $platform}"
    docker "${docker_arguments[@]}" "$inventory_script" sh "${probes[@]}"
} > "$inventory"
{ grep '^deb' "$inventory" || true; } | cut -f 2- > "$debs"
{ grep '^git' "$inventory" || true; } | cut -f 2- > "$gits"

echo "docker: licence texts" >&2
docker "${docker_arguments[@]}" "$licence_script" > "$licences"
echo "docker: RF Swift install records" >&2
docker "${docker_arguments[@]}" "$records_script" > "$records"

names=()
for file in "$inventory" "$debs" "$gits" "$licences" "$records"; do
    names+=("$(basename "$file")")
done
compliance_sha256 "$out" "${names[@]}" > "$out/INVENTORY-SHA256SUMS-$prefix"

count() { grep -c "^$1"$'\t' "$inventory" || true; }
echo "found: $(count func) install functions, $(count exe) commands and $(count path) paths" \
    "named by the policy, $(count deb) Debian packages, $(count git) git checkouts" >&2
for name in "${names[@]}" "INVENTORY-SHA256SUMS-$prefix"; do
    echo "wrote $out/$name" >&2
done
echo "next: scripts/compliance/generate-sbom.sh $image $out (uses $inventory)" >&2
