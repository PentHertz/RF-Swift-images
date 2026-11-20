# Changelog

## Unreleased

### Added

- `network`: Nuclei (ProjectDiscovery), upstream release binary checked against
  its checksums file (amd64/arm64, `go install` elsewhere), with the community
  templates.
- `llm`: Strix AI pentest agent (`strix-agent`, uv tool) and the Semgrep CLI;
  new `cloudflare` (security-audit), `strix` and `artex` skill packs in
  `llm-skills`, enabled by default; NodeTerm Server Edition (`nodeterm-server`,
  browser terminal/agent canvas on `:8443`), built from source (amd64/arm64).
- ARTEX (agent-driven web-security platform) built straight from upstream (latest
  `main`, `ARTEX_REF` to pin): a single image `make artex` with PostgreSQL inside,
  started from the shell by hand (`artex-postgres`, `artex-start`) like Open5GS; and
  a two-container compose stack under `extras/artex/`. Used through its web UI on
  `:8787`; not wired into the `llm` image. AGPL-3.0 with authorized-use-only terms.
  A manual CI workflow (`.github/workflows/build_artex.yml`, `workflow_dispatch` with
  an `artex_ref` input, plus a push trigger on the wrapper files) builds and publishes
  it for amd64/arm64; the full-build workflows deliberately leave ARTEX out since it
  tracks upstream rather than this repo's image chain.

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
