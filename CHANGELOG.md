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

- Tool-version maintenance: `scripts/maintenance/check_tool_versions.py` to check (and
  bump the simple ones) against upstream, and `docs/maintaining-tool-versions.md` listing
  every hand-pinned version with its update caveats.

### Changed

- Bumped pinned tool versions after an upstream audit: jadx `1.5.6→1.5.7`, uv `0.13.8→0.13.9`,
  Arduino IDE `2.3.10→2.3.11`, Sniffle firmware `v1.10.0→v1.11.0`, Burp Suite Community
  `2026.10.1→2026.11.2`, and the Mirage-side CPython source build `3.10.13→3.10.22`.
- sdrangel `v7.21.3→v8.2.0`: upstream v8 dropped the `sdrangel-<build>-master.tar.gz`
  bundle for a native `sdrangel_8.2.0_ubuntu-26.04_amd64.deb`, so the installer now fetches
  and installs that directly (major version jump; not build-verified here).
- Left pinned on purpose: scapy stays at `2.5.0` (Mirage's BLE code depends on `HCI_Cmd_*`
  names scapy renamed afterwards); Detect-It-Easy (`4.0.0` has no Ubuntu-26.04 build), Kaleido
  (v1.x is pip-only), LLVM (`17`→`23` is a 6-major jump), and hostapd (`2.12` has no aircrack-ng
  WPE patch yet) all need manual work and were not bumped.

### Fixed

- ipsw installer: version was pinned as `v3.1.745` but the URL template already prepends
  `v`, producing a broken `.../vv3.1.745/ipsw_v3.1.745_...` path; the pin is now the bare
  version (`3.1.749`), matching the real release asset names.

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
