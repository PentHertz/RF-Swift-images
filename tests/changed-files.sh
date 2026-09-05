#!/usr/bin/env bash
set -euo pipefail
script=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.github/scripts/changed-files.sh
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
cd "$fixture"
git init -q
git config user.email fixture@example.invalid
git config user.name fixture
printf 'first\n' > README
git add README
git commit -qm initial
base=$(git rev-parse HEAD)
mkdir scripts
printf 'changed\n' > scripts/common.sh
git add scripts/common.sh
git commit -qm code
printf 'docs\n' >> README
git add README
git commit -qm docs
got=$(RFSWIFT_BEFORE="$base" GITHUB_SHA=HEAD bash "$script")
[[ $got == *scripts/common.sh* && $got == *README* ]]
[[ $(RFSWIFT_BEFORE=missing bash "$script") == config/ ]]
[[ $(RFSWIFT_FORCE_ALL=true bash "$script") == config/ ]]
echo 'multi-commit selection tests: ok'
