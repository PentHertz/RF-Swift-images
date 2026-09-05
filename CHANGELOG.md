# Changelog

## Unreleased

### Fixed

- Installation retries return the last failure after five attempts. Call sites
  pass argument vectors, preserving spaces and literal glob characters. The npm
  bootstrap downloads its script before running it instead of passing a pipe as
  a curl argument.
- Image change detection covers every commit in a push, with a full-build
  fallback for unavailable base commits and workflow changes.
- Release promotion resolves immutable digests, checks each image's source
  revision and architecture against the checked-out release commit, and validates
  every image before publishing any tags for that architecture. Full builds now
  carry source-revision labels. Older/unlabelled or stale builds are rejected;
  run a forced full build of the tagged commit before rerunning promotion.
- Added regression tests for retries, multi-commit selection and release guards;
  added the missing keep-running script interpreter declaration.

### Notes

- Release preflight is per architecture; publishing across registries/architectures
  is not atomic. Base-image and upstream tool version pinning remain separate
  reproducibility work. No container images were published by this patch.
