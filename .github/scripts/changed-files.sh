#!/usr/bin/env bash
# Print all files changed by the push, or the existing full-build sentinel.
set -euo pipefail
before=${RFSWIFT_BEFORE:-}
after=${GITHUB_SHA:-HEAD}
if [[ ${RFSWIFT_FORCE_ALL:-false} == true ]] ||
   [[ ! $before =~ ^[0-9a-fA-F]{40,64}$ ]] ||
   [[ $before =~ ^0+$ ]] ||
   ! git cat-file -e "$before^{commit}" 2>/dev/null ||
   ! git cat-file -e "$after^{commit}" 2>/dev/null; then
    printf 'config/\n'
    exit 0
fi
changed=$(git diff --name-only "$before" "$after") || { printf 'config/\n'; exit 0; }
printf '%s\n' "$changed"
# Changes to CI selection itself must also rebuild every image.
if [[ $changed == *".github/"* ]]; then printf 'config/\n'; fi
