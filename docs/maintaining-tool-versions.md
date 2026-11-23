# Maintaining manually-pinned tool versions

Some tools in `scripts/*.sh` carry a version string in their script, as opposed to tools
that always pull `latest`, a distro package, or build from a tracked git branch. This page
lists those versions and how to keep them current.

## Newest release at build time

Most of these tools **take their newest release on every build**. The version in the script
is the **known-good fallback**, used when:

- the newest-release lookup fails (GitHub/vendor down, network issue), or
- the newest release no longer ships the asset the installer expects (renamed file, dropped
  architecture or Ubuntu build, missing companion patch).

Builds never install anything older than known-good. The helpers live in `scripts/common.sh`:
`latest_release_version OWNER/REPO KNOWN_GOOD [URL_TEMPLATE...]` and `pick_version`. A
URL template is the download URL with `@V@` in place of the version. GitHub's newest release
is read from the `/releases/latest` redirect, which needs no API call and so has no rate limit.

Every fallback is written to the image's build report under category **`fallback`**, with
the reason, for example `4.0.0 has no die_4.0.0_Ubuntu_26.04_amd64.deb; built known-good 3.21`.
Read it with `make report IMG=<image>` or in the CI job summary. A fallback is not an error.
It means upstream changed something and that installer (or its known-good version) needs a look.

**When the lookup actually runs.** The newest release is fetched when an install layer is
rebuilt, not when a cached layer is reused:

- **CI:** install layers re-run on every image build. The registry cache is only read
  (`--cache-to` is off), and `COPY scripts` comes before the installs. But CI only builds an
  image when its files change or on a manual `force_all` dispatch, so an upstream release on
  its own does not trigger a build.
- **Local:** buildx reuses cached layers when nothing changed. Use `make <image> NO_CACHE=1`
  to force a fresh lookup.

Integrity checks are kept where upstream publishes checksums:

| Tool | Newest release is verified with |
|------|---------------------------------|
| Node.js (v24 line) | that release's `SHASUMS256.txt` |
| Craft Anything | that release's `SHA256SUMS.txt` |
| Go | the sha256 from go.dev's release list (new: the old install had no check) |
| geckodriver | **TLS only**: Mozilla publishes `.asc` signatures but no checksum file. The pinned SHA256 still applies when the known-good version is installed |

**Still pinned** (the build installs exactly the version in the script): Kaleido (v1.x is a
different distribution), LLVM (toolchain major, bump deliberately), scapy (locked for Mirage),
and the vendor downloads Burp Suite and Little Snitch.

## Tracking upstream against a reviewed version

Some tools take upstream's newest code at every build, but the installer records the last
version someone reviewed. If a build installs something newer, it adds an entry to the build
report under category **`review`**. The build still succeeds; the entry means "read the diff,
then move the marker":

| Tool | Marker | File |
|------|--------|------|
| Vulnhuntr | `VULNHUNTR_REVIEWED_COMMIT` (main) | `llm_software.sh` |
| CodeGraph | `CODEGRAPH_REVIEWED_VERSION` (npm release) | `llm_software.sh` |
| fpv_capture host tools | `FPVCAPTURE_REVIEWED_COMMIT` (master) | `sdr_hacks.sh` |

The fpv_capture installer also adds a `review` entry when a release newer than
`FPVCAPTURE_RELEASE` is out, because its boot files stay pinned by SHA-256.

## Checking versions

A helper script compares the versions in the scripts with upstream. For floating tools it
tells you when the known-good fallback has fallen behind:

```sh
# check everything (needs network; GitHub API is rate-limited — set GITHUB_TOKEN to raise it)
python3 scripts/maintenance/check_tool_versions.py

# check a subset, or emit JSON
python3 scripts/maintenance/check_tool_versions.py --only jadx uv sdrangel
python3 scripts/maintenance/check_tool_versions.py --json

# bump a *simple* tool in place (edits the .sh), to latest or to an explicit version
python3 scripts/maintenance/check_tool_versions.py --bump jadx
python3 scripts/maintenance/check_tool_versions.py --bump jadx=1.5.7

python3 scripts/maintenance/check_tool_versions.py --list   # all known pins + class
```

Each pin has a **class** that says how safe a bump is:

- **simple** — the version is a standalone string; `--bump` can edit it directly. Still
  confirm the new release ships the same asset layout before building.
- **needs-care** — a bump *also* requires changing a SHA256 constant, an asset/file name, a
  companion patch, or crosses a major version. `--bump` refuses these and prints the reason;
  edit the script by hand.
- **locked** — must stay pinned. Do not bump.
- **manual** — vendor download with no machine-readable "latest"; check the URL by hand.

> Why the care? A version bump is often **not** just a number. Examples found in this repo:
> geckodriver / Kaleido / Node / Craft Anything carry `SHA256` constants that must match the
> new artifact; DIE and sdrangel encode the version in the **asset file name** (and DIE 4.0.0
> dropped the Ubuntu build, sdrangel v8 dropped the tarball); hostapd needs a matching
> `hostapd-<ver>-wpe.patch` from aircrack-ng; and **scapy is locked** because Mirage calls
> `HCI_Cmd_*` names that scapy renamed after 2.5.0 (bumping breaks BLE).

## Tracked pins

Versions below are the values in the scripts as of 2026-11-21. Every tool in the **simple**
and **needs-care** tables takes the newest release at build time, except **kaleido** and
**llvm**, so for those tools the version shown is the known-good fallback. The classes still
describe how safe it is to bump that fallback.

### simple (auto-bumpable)

| Tool | Version | File | Upstream |
|------|---------|------|----------|
| jadx | 1.5.7 | `mobile_software.sh` | skylot/jadx |
| ipsw | 3.1.749 | `mobile_software.sh` | blacktop/ipsw |
| uv | 0.13.9 | `corebuild.sh` | astral-sh/uv |
| arduino-ide | 2.3.11 | `hardware.sh` | arduino/arduino-ide |
| imhex | 1.38.1 | `reverse_software.sh` | WerWolv/ImHex |
| whispercpp | 1.9.5 | `llm_software.sh` | ggml-org/whisper.cpp |
| cyberether | 1.19.2 | `sdr_softwares.sh` | luigifcruz/CyberEther |
| qflipper | 1.3.3 | `rf_tools.sh` | flipperdevices/qFlipper (x86_64 AppImage only) |

### needs-care

| Tool | Version | File | Caveat on bump |
|------|---------|------|----------------|
| geckodriver | 0.37.1 | `ad_software.sh` | update `GECKODRIVER_SHA256_LINUX64` / `_AARCH64` |
| kaleido | 0.2.1 | `reverse_software.sh` | v1.x is pip-only (no prebuilt binary) + has SHA consts |
| node-llm | 24.22.3 | `llm_software.sh` | tracks the **v24 LTS** line on purpose; update `LLM_NODE_SHA256_*` |
| craft | 0.6.1 | `llm_software.sh` | update `CRAFT_SHA256_X86_64` / `_AARCH64` / `_RISCV64` |
| ghidra | 12.2 | `reverse_software.sh` | `ghidra_date` must match the release build date |
| die | 3.21 | `reverse_software.sh` | asset name encodes Ubuntu codename; 4.0.0 has no 26.04 build |
| sdrangel | 8.2.0 | `sdr_softwares.sh` | version is in the tag **and** the `.deb` file name |
| go | 1.27.4 | `corebuild.sh` | toolchain; bump deliberately, rebuild dependents |
| llvm | 17 | `sast_software.sh` | major-only via apt.llvm.org; verify resolute packaging + dependents |
| sniffle-fw | 1.11.0 | `rf_tools.sh` | firmware; confirm the per-board `.hex` asset set is unchanged |
| hostapd | 2.11 | `rf_tools.sh` | needs a matching `hostapd-<ver>-wpe.patch` in aircrack-ng (2.12 has none yet) |
| dsview | 1.3.4 | `hardware.sh` | **PentHertz fork**; cut a fork release before bumping |
| pulseview | 0.4.4 | `hardware.sh` | **PentHertz fork**; cut a fork release before bumping |
| antsdr-uhd | 4.1.0.0 | `sdr_peripherals.sh` | PentHertz repackage of MicroPhase UHD |
| fpv-capture | 0.1 | `sdr_hacks.sh` | AntSDR boot files: asset names carry a build date; update the names and SHA-256 in `FPVCAPTURE_BOOTFILES` |

### locked (do not bump)

| Tool | Version | File | Why |
|------|---------|------|-----|
| scapy | 2.5.0 | `rf_tools.sh` (Mirage venv) | Mirage's `ble.py` uses `HCI_Cmd_LE_Host_Supported`, `HCI_Cmd_Connect_Accept_Timeout`, `HCI_Cmd_LE_Start_Encryption_Request`; scapy renamed/removed these after 2.5.0, so a newer scapy breaks Mirage's BLE connect/encryption. The other (unpinned) scapy uses in the repo are unaffected. |

### manual (vendor downloads — check the URL by hand)

| Tool | Version | File | Where to check |
|------|---------|------|----------------|
| burp | 2026.11.2 | `network_common.sh` | https://portswigger.net/burp/releases |
| little-snitch | 1.1.1 | `corebuild.sh` | https://obdev.at/products/littlesnitch/ |

> Old Python versions are not pinned here: tools that need one (bluing and Mirage need 3.10)
> get it from `uv python install <ver>` and a `uv venv --seed --python <ver>` venv behind a
> wrapper. uv serves current patch releases for amd64, arm64 and riscv64.

## Other vendor / firmware blobs (not tracked by the checker)

These also carry hardcoded versions but are vendor SDKs, device firmware, or PentHertz
re-hosted artifacts; bumping them means re-packaging/re-hosting, not editing a number. Update
by hand when you refresh the artifact:

- Harogic SAStudio4 (`sa_devices.sh`), Harogic SGStudio / H2 API, Harogic HTRA SDK
- Harogic VNA Studio (`cal_devices.sh`, `HAROGIC_VNA_VERSION` plus the two `HAROGIC_VNA_SHA256_*`
  values, taken from the SHA-256 digests GitHub shows for the `vna_<version>` release assets)
- SignalHound SDK (`sa_devices.sh`, dated zip), FTDI D2XX (`gr_oot_modules.sh`)
- AMD GPU installer (`corebuild.sh`), nRF Sniffer for BLE (`rf_tools.sh`)
- btlejack (`rf_tools.sh`), dex2jar (`mobile_software.sh`), injectable-firmware / blerp /
  lr2021 / esp-sdr-bridge firmware, libresdr B2xx images, quictls openssl fork
- **URH** — installed via the PentHertz `urh-ng` repackage (`sdr_softwares.sh`, pinned at the
  repackage version, not upstream URH). Bump by cutting a new `urh-ng` release first.
