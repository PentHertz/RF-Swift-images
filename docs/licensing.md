# Licensing of the published images

RF Swift images redistribute a lot of third-party software: Ubuntu packages, tools built
from upstream source, Python/npm/Go/Rust packages, and vendor binaries for radio and test
equipment. Each keeps its own licence (see [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md)).
Some of them need a notice or their source kept available, and some need a decision
before they are redistributed in a public image at all. The licence-compliance pipeline
finds those components in a built image and reports them.

It is an engineering aid, not legal advice: it flags components, and the decisions on the
review list are Penthertz's. For the components listed today, the decision (2026-11-24) is to
keep publishing them in the images; the pipeline's job is now to keep their notices, record
what each image contains, and flag new components that need the same look.

## Files

| File | Role |
| --- | --- |
| `compliance/license-policy.json` | The policy: blocked, review-required and notice-required components, with the images they are in, why, what to decide or keep, and how to recognise them |
| `scripts/compliance/generate-sbom.sh` | syft scan of an image to CycloneDX and SPDX JSON, checksums, then the policy check |
| `scripts/compliance/check-license-policy.py` | Checks an SBOM (and optionally an inventory) against the policy |
| `scripts/compliance/image-inventory.sh` | Runs the image to list what syft cannot see and to collect its licence texts |
| `scripts/compliance/common.sh` | Helpers shared by the two shell scripts (image tag, output prefix, platform) |
| `tests/license-policy.sh` | Tests of the checker and the two scripts on synthetic SBOMs (syft and docker stubbed) |
| `.github/workflows/license_compliance.yml` | Manual CI run for one image |
| `THIRD_PARTY_NOTICES.md` | Generic notice, copied by `corebuild.docker` to `/usr/share/rfswift/licenses/` with `LICENSE` |
| `SOURCE_OFFER.md` | **Draft** written source offer, not in effect and not copied into images |

The three compliance scripts are adapted from Drost Community Edition
(<https://github.com/drost-ai/drost-community>, Apache-2.0); their headers say so and
`scripts/compliance/LICENSE-Apache-2.0` holds that licence.

## How it works

1. **SBOM.** `generate-sbom.sh` runs syft with all package catalogers on **all layers** of
   the image: a file deleted by a later layer (`rm -rf /root/thirdparty` at the end of most
   Dockerfiles) is still distributed in the image's layers. It writes
   `<prefix>.cdx.json` and `<prefix>.spdx.json`, where `<prefix>` is the repository name and
   tag (`rfswiftdev_resolute_network_amd64`).
2. **Inventory** (optional, needs Docker). syft recognises packages that have metadata:
   Debian packages, Python distributions, npm packages, Go and Rust binaries with build
   information, Java archives. It does not recognise most of what RF Swift builds from git,
   unpacks from tarballs or AppImages, or copies from vendor SDKs. `image-inventory.sh` runs
   the image (`docker run --rm --network none --entrypoint sh`) and records:
   - the install functions RF Swift ran in that image (`/var/lib/db/rfswift_components.lst`),
   - the commands (`command -v`) and paths of every component the policy names that are present,
   - every Debian package with its source package and version (`dpkg-query`),
   - every git checkout under the tool roots with its remote and commit,

   and collects the `copyright`, `LICENSE*`, `COPYING*` and `NOTICE*` files of
   `/usr/share/doc`, `/usr/share/rfswift`, `/usr/local`, `/opt`, `/rftools`, `/telecom`,
   `/hardware`, `/reverse`, `/automotive`, `/security`, `/nettools`, `/sast`, `/mobile` and
   `/root` into a tarball, plus RF Swift's own records (`/var/lib/db/rfswift_*`).
3. **Policy check.** `check-license-policy.py` matches each policy entry against the SBOM
   components (name, Debian source name, purl, file locations) and the inventory
   (install functions, commands, paths, Debian packages). It prints `BLOCKED`, `REVIEW` and
   `NOTICE` lines, each with the evidence that matched, and a summary; `--json` writes the
   same as JSON. Exit status: 0, or 1 when a blocked component is found, or 2 on unreadable
   input or a malformed policy.

## Running it locally

Needs syft (<https://github.com/anchore/syft>, CI pins 1.57.1), Python 3 and, for the
inventory, Docker. A bare tag is looked up in `penthertz/rfswiftdev_resolute` (set
`REGISTRY_IMAGE=penthertz/rfswift_resolute` for the release repository); the platform comes
from the tag's `_<arch>`.

```sh
# 1. optional: run the image, list what syft cannot see, collect licence texts
scripts/compliance/image-inventory.sh network_amd64             # writes to compliance-out/
# 2. SBOMs and the policy check (uses compliance-out/<prefix>.inventory.tsv if present)
SYFT_FROM=registry scripts/compliance/generate-sbom.sh network_amd64 compliance-out
# re-run only the check, for example after editing the policy
python3 -I scripts/compliance/check-license-policy.py \
    compliance-out/rfswiftdev_resolute_network_amd64.cdx.json \
    --inventory compliance-out/rfswiftdev_resolute_network_amd64.inventory.tsv \
    --json compliance-out/rfswiftdev_resolute_network_amd64.policy.json
bash tests/license-policy.sh                                     # the tests
```

`SYFT_FROM=registry` makes syft read the registry directly rather than a local Docker
daemon (do not combine it with a `registry:` prefix on the image). `SYFT_SCOPE=squashed`
scans only the final filesystem. Large images (`sdr_full`, the telecom images) take a long
time and several GB of temporary space in `$TMPDIR`.

## Running it in CI

Actions → **License compliance (manual)** → Run workflow, with:

- `image`: a tag such as `network_amd64` (or a full reference),
- `registry_image`: `penthertz/rfswiftdev_resolute` (default) or `penthertz/rfswift_resolute`,
- `inventory`: also pull and run the image (default on; arm64 and riscv64 images run under QEMU).

The job runs the tests, installs syft 1.57.1 (checked against its pinned SHA-256, the way
the install scripts check downloads), runs the inventory (then removes the pulled image to
free disk), generates the SBOMs from the registry and checks the policy. The report is in
the job summary; everything in `compliance-out/` (SBOMs, inventory, licence-text tarball,
reports, checksums) is uploaded as the artifact `license-compliance-<prefix>`. A blocked
component fails the job after the upload. One run covers one tag, so one architecture.

Pushing the workflow file, like any change under `.github/`, makes the next push build
select every image (`.github/scripts/changed-files.sh`).

## The policy file

`blocked_components`, `review_required_components` and `notice_required_components` hold
entries of this form:

```json
{
  "id": "waybackurls",
  "name": "waybackurls (tomnomnom)",
  "status": "installed",
  "installed_in": ["osint"],
  "images": ["osint"],
  "licence": "None: ...",
  "found_in": ["scripts/osint_software.sh: osint_go_tools_install (...)"],
  "reason": "Why it is listed",
  "decision": "What the owner has to decide (review, blocked)",
  "keep": "What must be kept or provided (notice)",
  "match": {
    "names": ["github.com/tomnomnom/waybackurls"],
    "purls": ["pkg:golang/github.com/tomnomnom/waybackurls*"],
    "paths": ["/usr/local/bin/waybackurls"],
    "executables": ["waybackurls"]
  }
}
```

`match` also takes `install_functions` (names of install functions, as recorded in
`/var/lib/db/rfswift_components.lst`); waybackurls has none because
`osint_go_tools_install` installs other tools too.

- `names` are compared case-insensitively with component names, Debian source names and the
  name part of purls; `purls` are shell patterns on the purl without its version (`%40` and
  `@` both work for npm scopes); `paths` are prefixes (a trailing `/` means the directory
  and everything in it); `executables` and `install_functions` are exact. Use an install
  function only when it installs nothing else.
- `installed_in` names the images whose Dockerfile installs the component; `images` lists
  those plus every image built on them, following `image_tree` (from `Dockerfiles/Makefile`).
  The checker warns when `images` misses one, and the tests fail on any warning.
- When an install script gains a vendor download, a binary without package metadata, a
  licence-acceptance step or a copyleft server, add an entry with the commands or paths
  that identify it, then run `bash tests/license-policy.sh`.

## Blocked

| Component | Why | Decision |
| --- | --- | --- |
| **OFRAK** (opt-in, never pre-installed) | The repository's own notes: its Community License covers academic and personal non-commercial use and does not allow redistribution, so published images must not carry it | None; the entry is a guard that fails the check if an image ever ships it, and removes nothing |

## Review required

Penthertz decided on 2026-11-24 to keep publishing all of these in the images. The table
records why each one was listed, so the reasons stay visible when a component or its terms
change; the policy check reports them as review items and does not fail on them. `sdrsa_devices+` means `sdrsa_devices` (and its `_antsdr` and
`_rtlsdrv4` variants) and every image built on it: `sdr_light*`, `sdr_full*`,
`sdr_gnuradio4`, `sdr_hacks`, `deeptempest`, `network`, `wifi`, `ad`, `bluetooth`,
`hardware` and all `telecom_*`. `sdr_light+` means `sdr_light` and the images built on it.

| Component | Images | Why it is listed | Alternative noted at review |
| --- | --- | --- | --- |
| Burp Suite Community Edition | `network`, `wifi`, `ad`, `telecom_5G_train` | Proprietary; no clear grant to redistribute it in a public image (Drost blocks it) | PortSwigger's written permission, or install it at run time |
| Caido Desktop | `network`, `wifi`, `ad` | Closed-source; licence terms not recorded; latest release, unpinned | Check its licence or get permission; otherwise install at run time |
| Claude Code | `llm` | npm licence "SEE LICENSE IN README.md"; LICENSE.md: all rights reserved, use subject to Anthropic's legal agreements | Confirm Anthropic allows redistribution of the npm package in a public image, or install it on first use |
| NodeTerm Server | `llm` | BUSL-1.1: redistribution allowed, production use limited to the Additional Use Grant; tracks the default branch | Whether a BUSL server belongs in the image; keep its LICENSE; tell users; consider pinning |
| waybackurls | `osint` | No upstream licence, so no right to redistribute (Drost blocks it) | Ask the author for a licence, replace it (gau, urlfinder), or install at run time |
| Saleae Logic 2 | `hardware` | Proprietary, redistributed extracted from its AppImage | Check Saleae's licence or ask Saleae |
| Harogic SAStudio4, HTRA and H2 APIs, SGStudio, VNA Studio | `sdrsa_devices+` (VNA Studio: `sdr_light+`) | Proprietary, re-hosted on PentHertz's GitHub (no licence file); bundles Qt (LGPL), Intel MKL, Arm RAL; GPL modules (gr-htra, SoapyHarogic, gr-harogic_sg) link the proprietary API | Keep Harogic's written agreement for public redistribution on file; check bundled notices; decide how GPL modules linked to the API are shipped |
| Signal Hound Spike, VSG, SDK | `sdrsa_devices+` (gr-signal-hound and the SDR++ plugin: `sdr_light+`) | Proprietary, downloaded from Signal Hound and redistributed; GPL code (gr-signal-hound, SDR++ plugin) linked to the proprietary API; Spike's wrapper expects a MATLAB Runtime | Check Signal Hound's licence or get permission; decide on prebuilt GPL modules linked to vendor libraries |
| Deepace KC908 SDK, gr-kc_sdr, KCSDI | `sdr_light+` | Proprietary, re-hosted on PentHertz's GitHub under a moving `nightly` tag, no checksum; ships FTDI D3XX | Keep Deepace's agreement on file; pin and checksum the assets |
| FTDI D2XX / D3XX drivers | `sdrsa_devices+`, `sdr_light+` | Proprietary driver licence with conditions on redistribution; one copy re-hosted by PentHertz | Read FTDI's licence for these versions; otherwise fetch at run time |
| NVIDIA CUDA / OpenCL packages | `hardware`, `sdr_full*`, `sdr_light_nvidiagpu` | Ubuntu multiverse, NVIDIA's terms | Read the packages' copyright files in a built image; keep only if they allow redistribution |
| AMD packages from repo.radeon.com | `hardware`, `sdr_full*` | Vendor repository with an EULA mechanism; meant to install open packages only, not checked | Confirm from the package list that nothing EULA-bound was installed |
| Nordic nRF Sniffer 4.1.1 | `bluetooth` | Vendor zip redistributed as downloaded; terms not checked | Check the licence in the zip |
| fpv_capture host tools and boot files | `sdr_hacks` | No upstream licence; boot images not inspected for GPL parts | Ask upstream for a licence and sources, or install at run time |
| ETSI TETRA ACELP codec | none (installer only, in `sdr_full`) | Built only when a user runs `install-tetra-codec`, because of ETSI's terms | None while it stays a user step |
| pocketVNA (unofficial re-host) | none (no Dockerfile calls it) | Vendor `.run` binary re-hosted by PentHertz | None while unused |

## Notice required

These may be redistributed, but their notices and source must be kept:

| Component | Images | Licence | Keep |
| --- | --- | --- | --- |
| Nmap | `network`, `wifi`, `ad`, `telecom_5G_train`, `telecom_5G_bladerf` | Nmap Public Source License | `/usr/share/doc/nmap/copyright`, the Ubuntu source package; do not present it as GPL-3.0 |
| Open5GS | Open5GS telecom images | AGPL-3.0 | Source tree, LICENSE, the commit built; AGPL section 13 for modified network services |
| srsRAN 4G, srsRAN Project (bladeRF fork), UERANSIM, PyHSS, jSS7, LTESniffer, OpenBTS/Osmocom/Yate | telecom images | AGPL-3.0 (Yate and some Osmocom libraries GPL) | Licence files, the commits (and PentHertz forks) as source |
| OCUDU | `telecom_4Gto5G`, `telecom_5G` | BSD-3-Clause-Open-MPI (not AGPL) | LICENSE, COPYRIGHTS.txt, LICENSES/ |
| OpenAirInterface 5G | `telecom_5G_oai` | OAI Public License v1.1 | LICENSE, NOTICE, the tag |
| MongoDB 6.0 server | Open5GS telecom images | SSPL-1.0 | Its licence files; MongoDB's source for the version |
| Redis | `telecom_utils` and the images built on it | Whatever Ubuntu's copyright file says (Redis 7.4+ is not BSD-only) | The copyright file; treat as AGPL if it is |
| Arduino IDE 2 | `hardware` | AGPL-3.0 | The AppImage unmodified; the release tag |
| Vulnhuntr | `llm` | AGPL-3.0 | Its licence; the commit |
| Cairn | none (opt-in) | AGPL-3.0 | If pre-installed one day: licence, source, commit |
| ARTEX | `artex`, `llm` (skills) | AGPL-3.0 | LICENSE; the ARTEX commit built (`ARTEX_REF`) |
| Open WebUI | `llm` | Open WebUI License (BSD-3 plus a branding clause) | Its licence; the branding unchanged |
| Little Snitch | every corebuild-based image | Freeware licence (redistribution allowed unmodified, with the licence, not sold alone) and GPL-2.0 parts | `/usr/share/doc/littlesnitch/copyright`; the binary unmodified |
| Metasploit Framework | `network`, `wifi`, `ad` | BSD-3-Clause plus bundled components | Licence files under `/opt/metasploit-framework` |
| Volatility 3 | `reversing` | Volatility Software License 1.0 | The complete licence text |
| GNU Radio and OOT modules, Wireshark | SDR and network images | GPL | Copyright files; Ubuntu source packages and module commits |
| DSView, PulseView, antsdr-uhd, URH (built by PentHertz) | `hardware`, `sdrsa_devices_antsdr`, `sdr_light+` | GPL-3.0 | PentHertz's fork sources at the release tags |
| Trail of Bits skills | `llm` | CC-BY-SA-4.0 | LICENSE and attribution |

The exact wording, sources and match rules are in `compliance/license-policy.json`.

Checked and not listed: Codex (Apache-2.0), OpenCode (MIT), Mistral Vibe (Apache-2.0),
Strix (Apache-2.0), pentest-ai (MIT; its acceptable-use prompt is left to the user), REA
(MIT), CodeGraph (MIT), Craft Anything (Apache-2.0), Hermes Agent (MIT), the other skill
packs (MIT or Apache-2.0), the Tailscale and NetBird clients, Firefox from the Mozilla
PPA. IDA, Binary Ninja and Hopper are not installed (REA uses them only when a user
adds them); Vivado/Vitis are not shipped.

## What it cannot detect

- **Components the policy does not name.** syft lists packages with metadata, and the
  inventory only probes the commands and paths in the policy. A new vendor binary, an
  unpacked tarball or a hand-copied library is found only once an entry names it.
- **Licences as such.** The check matches component identities; it does not read licence
  texts or evaluate licence expressions. syft's licence fields are kept in the SBOMs for
  reference only.
- **Whether redistribution is allowed.** It flags; the answer is a decision, often a
  contract with the vendor.
- **Deleted files.** The inventory and the licence texts come from the final filesystem.
  The all-layers SBOM sees packages in every layer, but not loose files that a later layer
  deleted.
- **Exact sources of deleted builds.** Tools built in `/root/thirdparty` are deleted after
  the build and most git installs track the default branch, so their commit is not
  recorded anywhere.
- **Run-time downloads.** Anything fetched when the user runs a command (models,
  `install-tetra-codec`, `mtk_nds32_toolchain_fetch`, opt-in installers) is not in the image.
- **Renamed or generic names.** Names match exactly, so a fork published under another
  name is missed; a generic command name (`claude`, `arduino`) can match an unrelated
  program. The evidence lines say what matched.
- **Other architectures and tags.** One run covers one tag. Some components exist on
  amd64 only (Saleae, the Burp installer, KC908, Signal Hound applications).
- **Images not built on corebuild.** `artex` is built from upstream ARTEX and does not get
  `/usr/share/rfswift/licenses/`.
