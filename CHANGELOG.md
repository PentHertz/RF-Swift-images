# Changelog

## Unreleased

### Added

- `network`: Nuclei (ProjectDiscovery), upstream release binary checked against
  its checksums file (amd64/arm64, `go install` elsewhere), with the community
  templates.
- `network`: recent-CVE exploit PoCs under `/opt/network/exploits/`, each pinned to a
  statically reviewed commit (authorized testing only): SIP2Shell (CVE-2026-116779, plus
  its nuclei template in `/opt/network/nuclei-templates-custom/`), the CVE-2026-123007
  NGINX HTTP/2 PoC and the Censys nginx2root lab suite in the default build;
  php2shell-poc (CVE-2026-109618/109619) and brotli2crash (CVE-2026-111497) as opt-in
  because they crash the target. See `docs/network-exploit-pocs.md`.
- `network`: exploit collections and frameworks that track upstream (not pinned):
  Exploit-DB with `searchsploit`, commix, RouterSploit (`rsf`, own venv, plus `telnetlib3`
  for Python ≥ 3.13), and the PoC-in-GitHub index with a `poc-lookup` helper (lookup only;
  the repos it lists are unvetted). Adds about 450 MB to `network` and `ad`.
- `llm`: Strix AI pentest agent (`strix-agent`, uv tool) and the Semgrep CLI;
  new `cloudflare` (security-audit), `strix` and `artex` skill packs in
  `llm-skills`, enabled by default; NodeTerm Server Edition (`nodeterm-server`,
  browser terminal/agent canvas on `:8443`), built from source (amd64/arm64).
- `sdr_gnuradio4`: GR4 Studio, built in the GR4 `full` preset with the control plane (amd64/arm64).
  `gr4-studio-web` serves the browser app on `127.0.0.1:8080` (`GR4_STUDIO_WEB_BIND` /
  `GR4_STUDIO_WEB_PORT` to change), with `gr4cp_server` kept on a loopback port. `gr4-studio`
  starts the desktop Electron app, made to run as root in a container (no-sandbox shim, which
  bypasses the host AppArmor setup step). Also the ZeroMQ, SDR (SoapySDR) and Audio (libsoundio)
  block families. See `docs/gnuradio4.md`.
- `sdr_light`: Harogic VNA Studio 1.0.8 for Harogic vector network analysers, with `vnastudio`
  (GUI) and `vnaserver` (headless VNAServer: `--no-gui`, `--list-devices-json`), the udev rules
  for its USB devices, and the amd64 and arm64 portable bundles checked against their published
  SHA-256. It is skipped on riscv64, which has no build.
- `reversing`: crypto-analysis tools. bkcrack (ZipCrypto known-plaintext attack) is built from the
  newest release's source on every architecture, with `bkcrack-inflate` / `bkcrack-deflate` helpers.
  fplll and fpylll (LLL / BKZ lattice reduction) come from Ubuntu's packages.
- `reversing`: opt-in OFRAK (`ofrak_soft_install`, amd64 only, Python 3.13 via uv, with the capstone and angr
  backends and the unpackers' tools). It is never pre-installed: the OFRAK Community License covers academic
  and personal non-commercial use and does not allow redistributing it. The installer only runs with
  `OFRAK_ACCEPT_LICENSE=yes`, and each user then registers their own licence with `ofrak license`.
- `reversing`: opt-in SageMath through passagemath (`sage_soft_install`, amd64/arm64). It is about
  1.3 GB of wheels and 4 to 5 GB installed, so its RUN line is commented. Install it in a running
  container with `cd /root/scripts && ./entrypoint.sh sage_soft_install`.
- `reversing`: Ropper, next to pwntools, ROPgadget and one_gadget. It is installed with uv on Python 3.13
  because its filebytes dependency does not build on Python 3.14. `ropper --chain` needs keystone-engine,
  which is installed on amd64 only.
- `sdr_hacks`: fpv_capture (black-pigeon), the analog FPV scanner firmware for the AntSDR E200 and
  E310. The image stages the v0.1 boot files for the SD card under `/rftools/sdr/fpv_capture/bootfiles/`
  (checked against SHA-256) and installs `fpv-receive`, the host frame recorder. It also builds the
  U220 PAL/NTSC test transmitter: `u220-fpv-tx`, which transmits only with `--transmit`, plus
  `u220-fpv-gui` and `u220-fpv-generate`. Host tools track master against a reviewed commit, and
  the boot files are listed in `check_tool_versions.py`.
- `llm`: opt-in LangGraph (`langgraph_soft_install`), for writing your own agents. It installs to a
  venv in `/opt/langgraph` with the Anthropic, OpenAI and MCP integrations and the `langgraph` CLI with
  its local dev server, and provides the `langgraph` and `langgraph-python` commands. Its CLI analytics,
  dev-server version check and LangSmith tracing are turned off in `llm.docker` and in the wrappers.
- `llm`: opt-in skill packs `ponytail` (6 skills: write only what is needed, plus review and audit)
  and `caveman` (16 voice and workflow skills). Enable them with `llm-skills enable <pack>`.
  caveman's CLI and proxy are not installed, and its Caveman Cloud / gateway skills are excluded
  through a new per-pack `exclude` list in `llm-skills`.
- `llm`: CodeGraph, a code knowledge graph that the agents query over MCP. It is registered with
  Claude Code, Codex, OpenCode and Hermes. It comes from npm `@colbymchenry/codegraph` with its
  platform build (about 300 MB, own Node runtime), so nothing is downloaded at run time
  (`CODEGRAPH_NO_DOWNLOAD=1`). Telemetry and the update check are off by default. Builds take
  the newest release, and `CODEGRAPH_REVIEWED_VERSION` records the last version reviewed.
- `llm`: Vulnhuntr (Protect AI), LLM-driven vulnerability discovery in Python projects, from
  `protectai/vulnhuntr` latest main. It is not taken from the PyPI project of the same name,
  which is a third-party fork. The last reviewed commit is recorded as
  `VULNHUNTR_REVIEWED_COMMIT`, and a build on a newer commit adds a `review` entry to the build
  report. Python 3.10 via uv, the missing `requests` dependency added, and the wrapper defaults
  `ANTHROPIC_MODEL` to `claude-opus-4-5`. Vulnhuntr pre-fills Claude's reply, which current
  Claude models reject, and its own default model is retired.
- `llm` (opt-in): ARTEMIS (Stanford Trinity) multi-agent red teaming as `artemis-redteam`,
  pinned to a reviewed commit (upstream has no releases). Its Codex fork is built from source,
  kept off `PATH` and given its own `CODEX_HOME`, so it never shadows or reconfigures the real
  Codex CLI. Python 3.12 via uv. Not in the default build because of the slow Rust build.
  AresValley's Artemis signal-identification app (SDR images) keeps its `Artemis` command.
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

- Builds take the newest release of 20 hand-pinned tools (jadx, ipsw, uv, Arduino IDE,
  ImHex, whisper.cpp, CyberEther, qFlipper, geckodriver, Node.js v24, Craft Anything, Ghidra,
  Detect-It-Easy, sdrangel, Go, Sniffle firmware, hostapd-wpe, DSView, PulseView, ANTSDR UHD).
  The version in each script is now a known-good fallback, used when the lookup fails or the
  newest release lacks the expected asset (DIE 4.0.0 has no 26.04 `.deb`; hostapd 2.12 has no
  WPE patch). Each fallback is recorded in the build report under `fallback`. New helpers in
  `scripts/common.sh` (`latest_release_version`, `pick_version`) read GitHub's
  `/releases/latest` redirect, so there is no API rate limit. Node.js and Craft Anything are
  verified against their release checksum files, and Go now against go.dev's sha256 (it was
  unchecked before). A newer geckodriver is TLS-only, because upstream publishes no checksum
  file. Kaleido, LLVM, scapy, Burp Suite and Little Snitch stay pinned.
- `make <image> NO_CACHE=1` rebuilds every layer (`--no-cache`), so a local rebuild picks up
  the newest releases even when no script changed.

- Bumped pinned tool versions after an upstream audit: jadx `1.5.6→1.5.7`, uv `0.13.8→0.13.9`,
  Arduino IDE `2.3.10→2.3.11`, Sniffle firmware `v1.10.0→v1.11.0`, Burp Suite Community
  `2026.10.1→2026.11.2`.
- bluing and Mirage get Python 3.10 from uv (`uv python install 3.10` + `uv venv --seed`)
  on amd64/arm64/riscv64, replacing bluing's riscv64 CPython source build and the
  deadsnakes PPA. Mirage no longer depends on bluing having installed `python3.10` first.
- sdrangel `v7.21.3→v8.2.0`: upstream v8 dropped the `sdrangel-<build>-master.tar.gz`
  bundle for a native `sdrangel_8.2.0_ubuntu-26.04_amd64.deb`, so the installer now fetches
  and installs that directly (major version jump; not build-verified here).
- Left pinned on purpose: scapy stays at `2.5.0` (Mirage's BLE code depends on `HCI_Cmd_*`
  names scapy renamed afterwards); Detect-It-Easy (`4.0.0` has no Ubuntu-26.04 build), Kaleido
  (v1.x is pip-only), LLVM (`17`→`23` is a 6-major jump), and hostapd (`2.12` has no aircrack-ng
  WPE patch yet) all need manual work and were not bumped.

### Fixed

- `sdr_gnuradio4`: the GNU Radio 4 build is aligned with 4.0.0-RC3, the newest tag. RC3 turned
  `gnuradio/gnuradio4` into a super-repo with renamed CMake options. The old flags
  (`WARNINGS_AS_ERRORS`, `ENABLE_TESTING`, `ENABLE_EXAMPLES`) were ignored, so the build ran
  with warnings-as-errors and the full test suite on. The old dependency list also lacked
  `cpp-httplib`, which `gnuradio4-core` requires, so configure stopped there. The installer now
  follows upstream's own Ubuntu 26.04 recipe (dependency list and `full` preset, with Release,
  no tests and warnings not fatal), requires CMake ≥ 3.27, installs to `/opt/gnuradio4/install`
  with a POSIX `env.sh`, removes the build tree afterwards, and runs upstream's `oot-smoke` and
  `control-plane-smoke` checks against the installed result. Precompiled headers are now off
  (each block family's was 400-600 MB; the blocks build had used 5.9 GB after 4 % of it,
  against a ~1.5 GB peak for the whole build without them), and `libsoundio-dev` is added so
  the Audio block family is built instead of silently skipped. Verified natively on Ubuntu
  26.04 / GCC 15.2: core, library and blocks (with the SDR family) built with no errors in 31 min
  on 24 cores, and `oot-smoke` passed against the installed SDK.

- Fluxion installer: it announced itself as "Installing eaphammer" and passed a misspelled
  label (`fluxius_soft_install`) to `gitinstall`, so failures were reported under that name.
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
