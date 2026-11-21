# Maintaining manually-pinned tool versions

Some tools in `scripts/*.sh` are installed at a **hand-pinned version**: a version string
you edit in the script (as opposed to tools that always pull `latest`, a distro package, or
build from a tracked git branch). This page lists those pins and how to keep them current.

A helper script checks them against upstream:

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

Versions below are current as of the 2026-11-20 audit.

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

### locked (do not bump)

| Tool | Version | File | Why |
|------|---------|------|-----|
| scapy | 2.5.0 | `rf_tools.sh` (Mirage venv) | Mirage's `ble.py` uses `HCI_Cmd_LE_Host_Supported`, `HCI_Cmd_Connect_Accept_Timeout`, `HCI_Cmd_LE_Start_Encryption_Request`; scapy renamed/removed these after 2.5.0, so a newer scapy breaks Mirage's BLE connect/encryption. The other (unpinned) scapy uses in the repo are unaffected. |

### manual (vendor downloads — check the URL by hand)

| Tool | Version | File | Where to check |
|------|---------|------|----------------|
| burp | 2026.11.2 | `network_common.sh` | https://portswigger.net/burp/releases |
| little-snitch | 1.1.1 | `corebuild.sh` | https://obdev.at/products/littlesnitch/ |
| python310 | 3.10.22 | `rf_tools.sh` | python.org — note 3.10 is **EOL**; 3.10.22 is the final patch |

## Other vendor / firmware blobs (not tracked by the checker)

These also carry hardcoded versions but are vendor SDKs, device firmware, or PentHertz
re-hosted artifacts; bumping them means re-packaging/re-hosting, not editing a number. Update
by hand when you refresh the artifact:

- Harogic SAStudio4 (`sa_devices.sh`), Harogic SGStudio / H2 API, Harogic HTRA SDK
- SignalHound SDK (`sa_devices.sh`, dated zip), FTDI D2XX (`gr_oot_modules.sh`)
- AMD GPU installer (`corebuild.sh`), nRF Sniffer for BLE (`rf_tools.sh`)
- btlejack (`rf_tools.sh`), dex2jar (`mobile_software.sh`), injectable-firmware / blerp /
  lr2021 / esp-sdr-bridge firmware, libresdr B2xx images, quictls openssl fork
- **URH** — installed via the PentHertz `urh-ng` repackage (`sdr_softwares.sh`, pinned at the
  repackage version, not upstream URH). Bump by cutting a new `urh-ng` release first.
