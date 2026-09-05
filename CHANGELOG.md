# Changelog

## Unreleased

### Fixed

- Installation retries return the last failure after five attempts. Call sites
  pass argument vectors, preserving spaces and literal glob characters. The npm
  bootstrap downloads its script before running it instead of passing a pipe as
  a curl argument.
- Image change detection covers every commit in a push, with a full-build
  fallback for unavailable base commits and workflow changes.
- Full builds now carry source-revision labels.
- Added regression tests for retries and multi-commit selection;
  added the missing keep-running script interpreter declaration.

### Notes

- Release workflows retain the existing per-image retagging behavior, using the
  available development tags even if some images were not rebuilt for the release.
  Base-image and upstream tool version pinning remain separate reproducibility
  work. No container images were published by this patch.
