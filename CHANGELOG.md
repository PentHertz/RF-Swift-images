# Changelog

## Unreleased

### Added

- `corebuild` and every image built on it: See (`see_soft_install`), a native desktop
  source-code reader (<https://see.wibus.ren>) for extracted firmware, tool sources and
  scripts: file tree, tabs, fuzzy file and symbol search, workspace search with ripgrep, Git
  status/diff/blame/history, a terminal, Markdown and hex preview, and language servers when
  installed. `see <folder>`, `see --diff <a> <b>`, `cmd | see -`, or the desktop menu. amd64
  and arm64 (no riscv64 release). The Linux tarball goes to `/opt/see`; it needs GTK 3 only,
  not the WebKitGTK the `.deb` declares. Builds take the newest release and check the tarball
  like See's updater does (ed25519 signature of its SHA-256 from `update-linux-<arch>.json`,
  against the pinned update key); 0.3.9 is the known-good fallback. Automatic update checks
  start off; Settings > Updates turns them on.
- `network`: OWASP ZAP (`zaproxy_soft_install`), the open
  alternative to Burp Suite for device web UIs and companion-app APIs. The pure-Java
  Linux release is installed in `/opt/zaproxy` on every architecture and checked against
  its SHA-256 (newer releases against `ZapVersions.xml`); the `zap` / `zap.sh` wrapper
  runs it on Ubuntu's OpenJDK 21. Headless: `zap -cmd ...`, `zap -daemon ...` or the
  automation framework (`zap -cmd -autorun <plan.yaml>`).
- `network`: hashID (`hashid`, with the hashcat mode and John format) and patator, from
  Ubuntu's packages, with `python3-zombie-telnetlib` (patator's `telnet_login` on Python
  3.13+) and `ike-scan`. patator's `default-jre` dependency adds Java 25.
- `network`: opt-in cloud-posture tools for IoT back ends, each in its own uv tool venv:
  Prowler (`prowler`), ScoutSuite (`scout`) and Checkov (`checkov`). They are large, so
  their RUN line is commented; install them in a running container with
  `cd /root/scripts && ./entrypoint.sh prowler_soft_install` (or `scoutsuite_soft_install`,
  `checkov_soft_install`).
- `reversing`: carving and memory forensics for raw flash and RAM dumps. bulk_extractor is
  built from the newest release (checked against its `SHA256SUMS`) on every architecture,
  since Ubuntu 26.04 does not package it; scalpel and foremost come from Ubuntu; Volatility 3
  (`vol`, `volshell`) is the PyPI release in a uv tool venv on Python 3.13, with dwarf2json
  for Linux symbol tables.

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
- `reversing`: OFRAK (`ofrak_soft_install`, amd64 only, Python 3.13 via uv, with the capstone and angr
  backends and the unpackers' tools) in `/opt/ofrak`, with `ofrak` and `ofrak-python` wrappers.
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
- `llm`: Decepticon skill pack in `llm-skills` (297 of its 329 skills, from
  BitterSecurity/Decepticon, formerly PurpleAILAB). Only its skills tree is fetched, as a sparse
  blobless checkout of about 14 MB instead of 90 MB. Its IoT, wireless and ICS/OT skills (34) are
  enabled, and the rest are reached through a `decepticon-skills` index skill and
  `llm-skills search`. The platform-internal skills are left out: benchmark marker, pipeline role
  prompts, orchestrator, planning templates, finding workflow and reference catalogue.
  `llm-skills` now handles nested skill trees and frontmatter `metadata:` blocks (subdomain, tags,
  keywords; comma-separated or `[a, b]` tags). Ids come from the skill `name`, and one that clashes
  with an earlier pack is prefixed `decepticon-` with its name rewritten. Decepticon's in-sandbox
  skill paths are rewritten to the local copies. Skills that call Decepticon's own tools
  (`kg_add_node`, `bash(..., session=...)`, `load_skill`...) get a note saying those tools do not
  exist here and what to do instead.
- `llm`: pentest-ai (PyPI `ptai`), an offensive-security MCP server, installed with uv on
  Python 3.12. It is registered as `pentest-ai` with Claude Code, Codex, OpenCode, Mistral Vibe and
  Hermes through `ptai-mcp`, which runs upstream's `ptai mcp`. Its Acceptable Use Policy is not
  accepted in the image. Upstream's MCP tools never ask for it, so `ptai-mcp` starts the server only
  after the operator has accepted it with `ptai-aup` (pentest-ai's own prompt). Telemetry (opt-in
  upstream) and the PyPI version check are off. Builds take the newest release, and
  `PENTESTAI_REVIEWED_VERSION` records the last one read. New helper `llm_mcp_register` registers a
  stdio MCP server with every agent in the image.
- `llm` (opt-in): Cairn (oritera), a fact-graph engine for AI pentesting, from upstream
  `main` into `/opt/cairn`, nothing vendored. Its dependencies are the versions and hashes of
  upstream's `uv.lock`, fetched from PyPI rather than the lock's Aliyun mirror. A ready local-mode
  dispatcher config uses the image's `claude` and `codex` CLIs as workers, with one project and two
  workers at a time. The `cairn` wrapper keeps `cairn serve` on `127.0.0.1:8000`, since the server
  has no authentication. `CAIRN_REVIEWED_COMMIT` records the last commit read.
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

- `sdr_full`: `sdrmm_soft_install` aborted the build with exit code 22 whenever github.com
  answered the latest-release lookup with an HTTP error (common on shared CI runners): the
  lookup was a bare `curl -f` in a command substitution, so `set -eo pipefail` stopped the
  RUN before the fallback version applied. The lookup is now a single request that reads the
  redirect without following it, and a failure falls back to the tested release.
- `sdr_full`: RFQuack was never installed. Its pinned 2022 requirements (PyYAML 6.0 and others)
  do not install on Python 3.14, which also left PlatformIO's `pio` missing for the firmware
  build. RFQuack now uses a uv-managed Python 3.10 venv in `/opt/rfquack-env` (upstream
  requires ^3.10, and every compiled pin has 3.10 wheels for amd64 and arm64) with its client
  (`rfq`, `rq`) and PlatformIO, and builds the firmware with that `pio`.

- `telecom_4G_5GNSA`, `telecom_4Gto5G`, `all`: srsRAN 4G was not built. Since 5937dde the
  installer clones upstream `srsRAN_4G` but still entered the PentHertz fork's directory
  (`srsRAN_4G_resolute`); it now enters the clone and records a build-report entry if the
  clone is missing.

- Go-based installers (`go_install_tool`, kerbrute, the OSINT Go tools, Amass) installed
  Ubuntu's `golang-go` unconditionally, which replaced the newest go.dev toolchain that
  corebuild puts in `/usr/bin/go` with Ubuntu's older one in the `network`, `ad` and
  `osint` images. They now use the toolchain already present (`ensure_go`) and fall back
  to `golang-go` only when there is none.

- `network`: `hashcat_soft_install` installed pixiewps instead of hashcat (and was defined
  twice), so the `network` and `ad` images had no hashcat although the tool list said so. It
  now installs `hashcat` with `pocl-opencl-icd`, which gives it a CPU OpenCL device in
  containers without a GPU runtime. pixiewps keeps its own `pixiewps_soft_install` in the Wi-Fi
  images.
- `rfid`: `chameleon_ultra_soft_install` was defined twice and the second copy (nfcpy only, which
  has its own function) replaced the real one, so `chameleon_cli` was never installed. The
  duplicate is gone; the installer now records a build-report entry instead of continuing
  silently when `uv sync` or the native key-recovery helpers fail.
- `network`/`wifi`: `bettercap_soft_install` linked `/usr/bin/bettercap` to a misspelled
  `/rftools/bluetoot/` path (a dangling link; `make install` still put it in `/usr/local/bin`).
- `sdr_full`: trunk-recorder was never installed. `trunkrecorder_soft_install` (defined twice)
  ran `./install`, copied from op25's installer; trunk-recorder has no such script and the
  failure was hidden by `|| true`. It is now built with CMake against the image's GNU Radio,
  gr-osmosdr, UHD and HackRF (upstream's `install.sh` would apt-install Debian's GNU Radio with
  sudo over them), and a failed build is recorded in the build report.
- `telecom_utils`: `pyhss_soft_install` installed bromelia (a copy of `bromelia_soft_install`), so
  PyHSS was missing. It now installs PyHSS from its new home, github.com/pyhss/pyhss,
  in a Python 3.12 venv under `/telecom/core/pyhss`, with `redis-server`, its `pyhss_*` service
  commands in `/usr/local/bin` and upstream's `config.yaml` as `/etc/pyhss/config.yaml`.
- `telecom_utils`: the Dockerfile's default `BASE_IMAGE` was `sdr_light` while the Makefile builds
  it on `sdrsa_devices`; the default now matches, so a manual build gets the same layers.
- `wifi_basic`: `hcxdumptool_soft_install` was defined twice (identical); one copy removed.
- Repository: Python bytecode caches (`__pycache__/*.pyc`) are no longer tracked; a
  `.gitignore` now excludes them.

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
