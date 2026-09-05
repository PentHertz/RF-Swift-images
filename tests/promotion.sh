#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
export RFSWIFT_TEST_LOG="$fixture/promotions" RFSWIFT_TEST_REVISION
RFSWIFT_TEST_REVISION=$(git rev-parse HEAD)
export DEV_REGISTRY=example/dev RELEASE_REGISTRY=example/release ARCH=amd64 GITHUB_REF_NAME=v1.2.3
export RFSWIFT_TEST_MODE=good
docker() {
    [[ $1 == buildx && $2 == imagetools ]] || return 1
    if [[ $3 == create ]]; then
        printf '%s\n' "$*" >> "$RFSWIFT_TEST_LOG"
    elif [[ $3 == inspect && $5 == --format ]]; then
        if [[ $6 == '{{json .Manifest}}' ]]; then
            printf '{"digest":"sha256:%064d"}\n' 1
        else
            local revision="$RFSWIFT_TEST_REVISION" arch=amd64
            [[ $RFSWIFT_TEST_MODE != stale ]] || revision=old
            [[ $RFSWIFT_TEST_MODE != wrongarch ]] || arch=arm64
            jq -cn --arg rev "$revision" --arg arch "$arch" \
              '{architecture:$arch,os:"linux",config:{Labels:{"org.opencontainers.image.revision":$rev}}}'
        fi
    else return 1; fi
}
export -f docker
bash .github/scripts/promote-images.sh corebuild network
[[ $(wc -l < "$RFSWIFT_TEST_LOG") == 4 ]]
! grep -q 'example/dev:' "$RFSWIFT_TEST_LOG"
for mode in stale wrongarch; do
    : > "$RFSWIFT_TEST_LOG"
    if RFSWIFT_TEST_MODE=$mode bash .github/scripts/promote-images.sh corebuild network; then
        echo "accepted $mode image" >&2; exit 1
    fi
    [[ ! -s $RFSWIFT_TEST_LOG ]]
done
echo 'release promotion guard tests: ok'
