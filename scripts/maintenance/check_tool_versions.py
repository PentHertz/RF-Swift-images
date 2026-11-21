#!/usr/bin/env python3
"""Check (and optionally bump) the manually-pinned tool versions in RF-Swift scripts.

Why this exists: a lot of tools in scripts/*.sh are pinned by a hand-edited version
string. This script reads each pin out of its script, asks the upstream (GitHub / PyPI /
nodejs.org / go.dev) for the latest, and tells you what drifted.

It will NOT blindly rewrite anything risky. Each tool has a class:
  simple     - the version is a standalone string; `--bump` can edit it in place.
  needs-care - a bump also requires changing a SHA256, an asset/file name, a companion
               patch, or crosses a major version. `--bump` refuses these and says why.
  locked     - must stay pinned (e.g. scapy, held for Mirage BLE compatibility).
  manual     - vendor download with no machine-readable "latest"; check the URL by hand.

Usage:
  python3 check_tool_versions.py                 # check everything, print a table
  python3 check_tool_versions.py --only jadx uv  # check just these
  python3 check_tool_versions.py --json          # machine-readable
  python3 check_tool_versions.py --bump jadx      # bump a `simple` tool to latest in its .sh
  python3 check_tool_versions.py --bump jadx=1.5.7 # bump to an explicit version

Network: unauthenticated GitHub API is rate-limited to ~60 req/h per IP. Set GITHUB_TOKEN
to raise that. No credentials or personal data are ever sent; a generic User-Agent is used.
Run from anywhere; paths are resolved relative to the scripts/ directory above this file.
"""
import argparse
import json
import os
import re
import sys
import urllib.request
import urllib.error

SCRIPTS_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UA = "rfswift-version-check"

# Each entry:
#   file   - script under scripts/ that holds the pin
#   pat    - regex with a (?P<ver>...) group capturing the CURRENT version in `file`
#   source - how to find the latest upstream version (see fetch_latest)
#   cls    - simple | needs-care | locked | manual
#   note   - shown for needs-care/locked/manual to explain the caveat
MANIFEST = {
    # ---- simple string bumps (safe for --bump) ----
    "jadx":        {"file": "mobile_software.sh", "pat": r'JADX_VERSION="(?P<ver>[\d.]+)"',
                    "source": ("github", "skylot/jadx"), "cls": "simple"},
    "ipsw":        {"file": "mobile_software.sh", "pat": r'IPSW_VERSION="(?P<ver>[\d.]+)"',
                    "source": ("github", "blacktop/ipsw"), "cls": "simple"},
    "uv":          {"file": "corebuild.sh", "pat": r'UV_VERSION="(?P<ver>[\d.]+)"',
                    "source": ("github", "astral-sh/uv"), "cls": "simple"},
    "arduino-ide": {"file": "hardware.sh", "pat": r'IDE_VERSION="(?P<ver>[\d.]+)"',
                    "source": ("github", "arduino/arduino-ide"), "cls": "simple"},
    "imhex":       {"file": "reverse_software.sh", "pat": r'IMH_VERSION="(?P<ver>[\d.]+)"',
                    "source": ("github", "WerWolv/ImHex"), "cls": "simple"},
    "whispercpp":  {"file": "llm_software.sh", "pat": r'WHISPERCPP_VERSION="v(?P<ver>[\d.]+)"',
                    "source": ("github", "ggml-org/whisper.cpp"), "cls": "simple"},
    "cyberether":  {"file": "sdr_softwares.sh", "pat": r'CYBERETHER_VERSION="(?P<ver>[\d.]+)"',
                    "source": ("github", "luigifcruz/CyberEther"), "cls": "simple"},
    "qflipper":    {"file": "rf_tools.sh", "pat": r'QFLIPPER_VERSION="(?P<ver>[\d.]+)"',
                    "source": ("github", "flipperdevices/qFlipper"), "cls": "simple",
                    "note": "x86_64-only AppImage; version string itself is a clean bump"},

    # ---- need care: SHA / asset-name / patch / major-version coupling ----
    "geckodriver": {"file": "ad_software.sh", "pat": r'GECKODRIVER_VERSION="v(?P<ver>[\d.]+)"',
                    "source": ("github", "mozilla/geckodriver"), "cls": "needs-care",
                    "note": "also update GECKODRIVER_SHA256_LINUX64 / _AARCH64"},
    "kaleido":     {"file": "reverse_software.sh", "pat": r'KALEIDO_VERSION="v(?P<ver>[\d.]+)"',
                    "source": ("github", "plotly/Kaleido"), "cls": "needs-care",
                    "note": "v1.x dropped the prebuilt binary (pip-only); not a string bump + has SHA consts"},
    "node-llm":    {"file": "llm_software.sh", "pat": r'LLM_NODE_VERSION="v(?P<ver>[\d.]+)"',
                    "source": ("nodejs_v24",), "cls": "needs-care",
                    "note": "tracks the v24 LTS line on purpose; also update LLM_NODE_SHA256_*"},
    "craft":       {"file": "llm_software.sh", "pat": r'CRAFT_VERSION="(?P<ver>[\d.]+)"',
                    "source": ("github", "storytold/craft-anything"), "cls": "needs-care",
                    "note": "also update CRAFT_SHA256_X86_64 / _AARCH64 / _RISCV64"},
    "ghidra":      {"file": "reverse_software.sh", "pat": r'ghidra_version="(?P<ver>[\d.]+)"',
                    "source": ("github", "NationalSecurityAgency/ghidra"), "cls": "needs-care",
                    "note": "ghidra_date must match the release's build date"},
    "die":         {"file": "reverse_software.sh", "pat": r'DIE_VERSION="(?P<ver>[\d.]+)"',
                    "source": ("github", "horsicq/DIE-engine"), "cls": "needs-care",
                    "note": "asset name encodes the Ubuntu codename; 4.0.0 has no 26.04/Ubuntu build"},
    "sdrangel":    {"file": "sdr_softwares.sh", "pat": r'SDRANGEL_VERSION="(?P<ver>[\d.]+)"',
                    "source": ("github", "f4exb/sdrangel"), "cls": "needs-care",
                    "note": "version appears in the tag AND the .deb file name; v7->v8 changed packaging"},
    "go":          {"file": "corebuild.sh", "pat": r'GO_VERSION="(?P<ver>[\d.]+)"',
                    "source": ("go_dl",), "cls": "needs-care",
                    "note": "toolchain; bump deliberately and rebuild dependents"},
    "llvm":        {"file": "sast_software.sh", "pat": r'LLVM_VERSION=(?P<ver>\d+)',
                    "source": ("github", "llvm/llvm-project"), "cls": "needs-care",
                    "note": "major-only pin via apt.llvm.org; verify resolute packaging + dependents"},
    "sniffle-fw":  {"file": "rf_tools.sh", "pat": r'SNIFFLE_FW_VERSION="(?P<ver>[\d.]+)"',
                    "source": ("github", "nccgroup/Sniffle"), "cls": "needs-care",
                    "note": "firmware; confirm the per-board .hex asset set is unchanged"},
    "hostapd":     {"file": "rf_tools.sh", "pat": r'HOSTAPD_VERSION="(?P<ver>[\d.]+)"',
                    "source": ("w1fi_hostapd",), "cls": "needs-care",
                    "note": "needs a matching hostapd-<ver>-wpe.patch in aircrack-ng (2.12 has none yet)"},
    "dsview":      {"file": "hardware.sh", "pat": r'DSVIEW_VERSION="(?P<ver>[\d.]+)"',
                    "source": ("github", "PentHertz/DSView"), "cls": "needs-care",
                    "note": "PentHertz fork; cut a fork release before bumping"},
    "pulseview":   {"file": "hardware.sh", "pat": r'PULSEVIEW_VERSION="(?P<ver>[\d.]+)"',
                    "source": ("github", "PentHertz/pulseview"), "cls": "needs-care",
                    "note": "PentHertz fork; cut a fork release before bumping"},
    "antsdr-uhd":  {"file": "sdr_peripherals.sh", "pat": r'ANTSDR_VERSION="(?P<ver>[\d.]+)"',
                    "source": ("github", "PentHertz/antsdr_uhd"), "cls": "needs-care",
                    "note": "PentHertz repackage of MicroPhase UHD"},

    # ---- locked: must not be bumped ----
    "scapy":       {"file": "rf_tools.sh", "pat": r'scapy==(?P<ver>[\d.]+)',
                    "source": ("pypi", "scapy"), "cls": "locked",
                    "note": "Mirage's ble.py uses HCI_Cmd_* names scapy renamed after 2.5.0; bumping breaks BLE"},

    # ---- manual: vendor downloads, no machine-readable 'latest' ----
    "burp":        {"file": "network_common.sh", "pat": r'\$\{1:-(?P<ver>[\d.]+)\}',
                    "source": ("manual", "https://portswigger.net/burp/releases"), "cls": "manual"},
    "little-snitch": {"file": "corebuild.sh", "pat": r'local version="(?P<ver>[\d.]+)"',
                    "source": ("manual", "https://obdev.at/products/littlesnitch/"), "cls": "manual",
                    "note": "first `local version=` match in file; verify it is the Little Snitch one"},
}


# Tools whose installer takes the newest release at build time (scripts/common.sh:
# latest_release_version / pick_version). For these the version in the script is only the
# known-good fallback, used when the lookup fails or the newest release lacks the expected
# asset. Everything else is pinned and installs exactly the version in the script.
FLOATING = {
    "jadx", "ipsw", "uv", "arduino-ide", "imhex", "whispercpp", "cyberether", "qflipper",
    "geckodriver", "node-llm", "craft", "ghidra", "die", "sdrangel", "go", "sniffle-fw",
    "hostapd", "dsview", "pulseview", "antsdr-uhd",
}


def http_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    tok = os.environ.get("GITHUB_TOKEN")
    if tok and "api.github.com" in url:
        req.add_header("Authorization", f"Bearer {tok}")
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def http_text(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as r:
        return r.read().decode("utf-8", "replace")


def fetch_latest(source):
    kind = source[0]
    try:
        if kind == "github":
            repo = source[1]
            try:
                tag = http_json(f"https://api.github.com/repos/{repo}/releases/latest").get("tag_name", "")
            except urllib.error.HTTPError:
                rel = http_json(f"https://api.github.com/repos/{repo}/releases?per_page=1")
                tag = rel[0]["tag_name"] if rel else ""
            # tags vary (v8.2.0, 4.0.0, Ghidra_12.2_build): pull the numeric version out
            m = re.search(r"\d+(?:\.\d+)+", tag)
            return m.group(0) if m else (tag.lstrip("vV") or None)
        if kind == "pypi":
            return http_json(f"https://pypi.org/pypi/{source[1]}/json")["info"]["version"]
        if kind == "nodejs_v24":
            data = http_json("https://nodejs.org/dist/index.json")
            v24 = [d["version"].lstrip("v") for d in data if d["version"].startswith("v24.")]
            return v24[0] if v24 else None
        if kind == "go_dl":
            data = http_json("https://go.dev/dl/?mode=json")
            return data[0]["version"].replace("go", "") if data else None
        if kind == "w1fi_hostapd":
            txt = http_text("https://w1.fi/releases/")
            vers = re.findall(r"hostapd-(\d+\.\d+)\.tar\.gz", txt)
            return sorted(set(vers), key=lambda s: [int(x) for x in s.split(".")])[-1] if vers else None
        if kind == "manual":
            return None
    except Exception as e:
        return f"ERR:{type(e).__name__}"
    return None


def vkey(v):
    out = []
    for part in re.split(r"[.\-]", str(v)):
        out.append((0, int(part)) if part.isdigit() else (1, part))
    return out


def read_current(entry):
    path = os.path.join(SCRIPTS_DIR, entry["file"])
    with open(path) as fh:
        text = fh.read()
    m = re.search(entry["pat"], text, re.DOTALL)
    return (m.group("ver") if m else None), text, path


def status_for(cur, latest):
    if latest is None:
        return "manual"
    if isinstance(latest, str) and latest.startswith("ERR:"):
        return latest
    if cur is None:
        return "pin-not-found"
    if vkey(cur) == vkey(latest):
        return "up-to-date"
    if vkey(cur) < vkey(latest):
        return "OUTDATED"
    return "ahead"  # local pin newer than upstream (forks / insider builds)


def do_check(names, as_json):
    rows = []
    for name in names:
        e = MANIFEST[name]
        cur, _, _ = read_current(e)
        latest = fetch_latest(e["source"])
        rows.append({"tool": name, "current": cur, "latest": latest,
                     "status": status_for(cur, latest), "class": e["cls"],
                     "build": "latest" if name in FLOATING else "pinned",
                     "file": e["file"], "note": e.get("note", "")})
    if as_json:
        print(json.dumps(rows, indent=2))
        return rows
    w = max(len(r["tool"]) for r in rows)
    print("CURRENT is the version in the script: the installed version for BUILD=pinned, the")
    print("known-good fallback for BUILD=latest (those builds already take the newest release).\n")
    print(f"{'TOOL':<{w}}  {'CURRENT':<12} {'LATEST':<12} {'STATUS':<13} {'BUILD':<7} CLASS")
    for r in sorted(rows, key=lambda x: (x["status"] != "OUTDATED", x["build"] != "pinned", x["tool"])):
        lat = "-" if r["latest"] is None else str(r["latest"])
        print(f"{r['tool']:<{w}}  {str(r['current'] or '?'):<12} {lat:<12} "
              f"{r['status']:<13} {r['build']:<7} {r['class']}")
        if r["note"] and r["status"] in ("OUTDATED", "manual", "locked") or (r["note"] and r["class"] != "simple"):
            print(f"{'':<{w}}    ^ {r['note']}")
    out = [r for r in rows if r["status"] == "OUTDATED"]
    pinned_out = [r for r in out if r["build"] == "pinned"]
    print(f"\n{len(out)} outdated of {len(rows)} checked: {len(pinned_out)} pinned "
          f"(install an old version), {len(out) - len(pinned_out)} known-good fallbacks behind "
          f"upstream (builds take the newest when it ships the expected assets; a build that "
          f"fell back says so in its build report under 'fallback').")
    return rows


def do_bump(spec):
    name, _, want = spec.partition("=")
    if name not in MANIFEST:
        sys.exit(f"unknown tool '{name}'")
    e = MANIFEST[name]
    if e["cls"] != "simple":
        sys.exit(f"'{name}' is class '{e['cls']}', not auto-bumpable.\n"
                 f"  reason: {e.get('note','')}\n"
                 f"  edit {e['file']} by hand (and any SHA/asset/patch it couples to).")
    cur, text, path = read_current(e)
    if cur is None:
        sys.exit(f"could not locate the current version in {e['file']}")
    new = want or fetch_latest(e["source"])
    if not new or str(new).startswith("ERR:"):
        sys.exit(f"could not determine target version ({new})")
    if vkey(new) == vkey(cur):
        print(f"{name} already at {cur}; nothing to do.")
        return
    m = re.search(e["pat"], text, re.DOTALL)
    old_sub = m.group(0)
    new_sub = old_sub.replace(cur, new)
    with open(path, "w") as fh:
        fh.write(text.replace(old_sub, new_sub, 1))
    print(f"{name}: {cur} -> {new}  (in {e['file']})")
    print("  NOTE: verify the new release ships the same asset layout before you build.")


def main():
    ap = argparse.ArgumentParser(description="Check/bump RF-Swift pinned tool versions.")
    ap.add_argument("--only", nargs="+", metavar="TOOL", help="check only these tools")
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    ap.add_argument("--bump", metavar="TOOL[=VERSION]", help="bump a simple-class tool in place")
    ap.add_argument("--list", action="store_true", help="list known tools and exit")
    args = ap.parse_args()
    if args.list:
        for n, e in sorted(MANIFEST.items()):
            print(f"{n:<14} {e['cls']:<11} {e['file']}")
        return
    if args.bump:
        do_bump(args.bump)
        return
    names = args.only or list(MANIFEST)
    bad = [n for n in names if n not in MANIFEST]
    if bad:
        sys.exit(f"unknown tool(s): {', '.join(bad)}")
    do_check(names, args.json)


if __name__ == "__main__":
    main()
