#!/usr/bin/env bash
# Resolve and validate EVERY image before promoting any version tags.
set -euo pipefail
: "${DEV_REGISTRY:?}" "${RELEASE_REGISTRY:?}" "${ARCH:?}" "${GITHUB_REF_NAME:?}"
version=${GITHUB_REF_NAME#v}
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$ ]] || { echo 'Invalid release version' >&2; exit 1; }
revision=$(git rev-parse HEAD)
manifest=$(mktemp)
trap 'rm -f "$manifest"' EXIT
for image in "$@"; do
    [[ $image =~ ^[A-Za-z0-9_]+$ ]] || exit 1
    descriptor=$(docker buildx imagetools inspect "$DEV_REGISTRY:${image}_$ARCH" --format '{{json .Manifest}}')
    digest=$(jq -er '.digest | select(test("^sha256:[0-9a-f]{64}$"))' <<< "$descriptor")
    source="$DEV_REGISTRY@$digest"
    config=$(docker buildx imagetools inspect "$source" --format '{{json .Image}}')
    built_revision=$(jq -er --arg arch "$ARCH" '
      [ (if has("architecture") then . else .[] end)
        | select(.architecture == $arch and .os == "linux")
        | .config.Labels["org.opencontainers.image.revision"] ]
      | if length == 1 then .[0] // error("missing source revision") else error("ambiguous architecture") end
    ' <<< "$config")
    if [[ $built_revision != "$revision" ]]; then
        echo "Refusing $image/$ARCH: build revision $built_revision does not match release $revision." >&2
        echo 'Run a forced full image build for the tagged commit, then rerun this release.' >&2
        exit 1
    fi
    jq -cn --arg image "$image" --arg source "$source" --arg revision "$revision" --arg arch "$ARCH" \
        '{image:$image,source:$source,revision:$revision,architecture:$arch}' >> "$manifest"
done
[[ -s $manifest ]] || { echo 'No release images selected' >&2; exit 1; }
# Digest references remain fixed even if another build moves a development tag.
while IFS= read -r entry; do
    image=$(jq -r .image <<< "$entry")
    source=$(jq -r .source <<< "$entry")
    docker buildx imagetools create --tag "$RELEASE_REGISTRY:${image}_${version}_$ARCH" "$source"
    docker buildx imagetools create --tag "$RELEASE_REGISTRY:${image}_$ARCH" "$source"
done < "$manifest"
if [[ -n ${GITHUB_STEP_SUMMARY:-} ]]; then
    printf '\n### Promoted immutable image sources\n\n' >> "$GITHUB_STEP_SUMMARY"
    jq -r '"- " + .image + " (" + .architecture + "): " + .source + " — " + .revision' "$manifest" >> "$GITHUB_STEP_SUMMARY"
fi
