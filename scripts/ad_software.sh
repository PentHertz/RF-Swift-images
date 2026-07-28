#!/bin/bash
#
# Active Directory (AD) tooling for RF-Swift. Built on top of the network image.
# RF-Swift helpers (install_dependencies / pipx / go install / gitinstall) with
# best-effort build reporting so one failing tool never aborts the image.
#
# The shared AD tools that also live in the network scripts (impacket, responder,
# netexec, DonPAPI, DonPwner) are installed here too via their existing functions.

AD_DIR="/opt/ad"

function ad_apt_tools_install() {
    goodecho "[+] Installing AD apt tooling"
    install_dependencies "smbclient ldap-utils krb5-user samdump2 onesixtyone nbtscan crackmapexec dnsutils gcc-mingw-w64-x86-64 libpcap-dev"
}

# Small helper: pipx install with best-effort reporting + optional symlink.
function _ad_pipx() {
    local name="$1" spec="$2" bin="$3"
    pipx install "$spec" \
        || record_build_failure "pip" "$name" "pipx install failed"
    if [ -n "$bin" ] && [ -e "/root/.local/bin/$bin" ]; then
        ln -sf "/root/.local/bin/$bin" "/usr/sbin/$bin"
    fi
    # Best-effort helper: a missing binary (e.g. pipx install failed above and was
    # recorded) must not become this function's exit status and abort the build.
    return 0
}

function ldapdomaindump_soft_install() {
    goodecho "[+] Installing ldapdomaindump"
    install_dependencies "pipx git"; pipx ensurepath
    _ad_pipx "ldapdomaindump" "git+https://github.com/dirkjanm/ldapdomaindump" "ldapdomaindump"
}

function bloodhound_py_soft_install() {
    goodecho "[+] Installing BloodHound.py ingestor"
    install_dependencies "pipx git"; pipx ensurepath
    _ad_pipx "bloodhound.py" "git+https://github.com/fox-it/BloodHound.py" "bloodhound-python"
}

function certipy_soft_install() {
    goodecho "[+] Installing Certipy"
    install_dependencies "pipx git"; pipx ensurepath
    _ad_pipx "certipy" "certipy-ad" "certipy"
}

function mitm6_soft_install() {
    goodecho "[+] Installing mitm6"
    install_dependencies "pipx git"; pipx ensurepath
    _ad_pipx "mitm6" "mitm6" "mitm6"
}

function lsassy_soft_install() {
    goodecho "[+] Installing lsassy"
    install_dependencies "pipx git"; pipx ensurepath
    _ad_pipx "lsassy" "lsassy" "lsassy"
}

function bloodyad_soft_install() {
    goodecho "[+] Installing bloodyAD"
    install_dependencies "pipx git"; pipx ensurepath
    _ad_pipx "bloodyAD" "git+https://github.com/CravateRouge/bloodyAD" "bloodyAD"
}

function certsync_soft_install() {
    goodecho "[+] Installing certsync"
    install_dependencies "pipx git"; pipx ensurepath
    _ad_pipx "certsync" "git+https://github.com/zblurx/certsync" "certsync"
}

function sprayhound_soft_install() {
    goodecho "[+] Installing sprayhound"
    install_dependencies "pipx git"; pipx ensurepath
    _ad_pipx "sprayhound" "sprayhound" "sprayhound"
}

function kerbrute_soft_install() {
    goodecho "[+] Installing kerbrute (Go)"
    install_dependencies "golang-go git"
    if GOBIN=/usr/local/bin go install github.com/ropnop/kerbrute@latest; then
        goodecho "[+] kerbrute installed: /usr/local/bin/kerbrute"
    else
        record_build_failure "build" "kerbrute" "go install failed"
    fi
}

function sharplaps_soft_install() {
    # SharpLAPS is a C#/.NET tool (reads LAPS passwords from LDAP) meant to run
    # against Windows targets. We stage the repo (source + any prebuilt binary)
    # rather than compiling it on Linux; symlink the .exe if one ships in the repo.
    goodecho "[+] Installing SharpLAPS (LAPS-from-LDAP dumper; staged for target use)"
    [ -d "$AD_DIR" ] || mkdir -p "$AD_DIR"
    cd "$AD_DIR"
    gitinstall "https://github.com/swisskyrepo/SharpLAPS.git" "sharplaps_soft_install"
    if [ -d SharpLAPS ]; then
        local exe; exe=$(find "$AD_DIR/SharpLAPS" -iname 'SharpLAPS.exe' 2>/dev/null | head -1)
        if [ -n "$exe" ]; then
            ln -sf "$exe" /usr/local/bin/SharpLAPS.exe
        else
            goodecho "[+] SharpLAPS staged as source (no prebuilt .exe in repo; build it on/against a Windows target)"
        fi
    else
        record_build_failure "git" "SharpLAPS" "clone failed"
    fi
    # Staging the source is the goal; a missing prebuilt .exe (the normal case for
    # this C#/source-only repo) must not fail the build via the trailing test above.
    return 0
}

function skewrun_soft_install() {
    # skewrun resolves a Domain Controller's time over AD protocols and wraps a
    # target process with libfaketime (LD_PRELOAD) so tools like Impacket/NetExec
    # survive Kerberos KRB_AP_ERR_SKEW without root or touching the system clock.
    goodecho "[+] Installing skewrun (AD clock-skew wrapper)"
    install_dependencies "libfaketime"

    local arch asset
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)  asset="skewrun-x86_64-linux-musl" ;;
        aarch64|arm64) asset="skewrun-aarch64-linux-musl" ;;
        *)             asset="" ;;
    esac

    # Prefer the upstream static musl release (no toolchain, tracks latest).
    if [ -n "$asset" ]; then
        installfromnet "wget -O /usr/local/bin/skewrun https://github.com/JVBotelho/skewrun/releases/latest/download/$asset"
        if [ -s /usr/local/bin/skewrun ] && head -c4 /usr/local/bin/skewrun | grep -q $'\x7fELF'; then
            chmod +x /usr/local/bin/skewrun
            goodecho "[+] skewrun installed: /usr/local/bin/skewrun"
            return 0
        fi
        rm -f /usr/local/bin/skewrun
        record_build_failure "download" "skewrun" "release binary download failed; falling back to cargo"
    fi

    # No prebuilt binary for this arch (e.g. riscv64) or the download failed:
    # build from crates.io using the cargo toolchain from corebuild's rust_tools.
    if command -v cargo >/dev/null 2>&1; then
        cargo install skewrun --root /usr/local \
            || record_build_failure "build" "skewrun" "cargo install failed"
    else
        record_build_failure "build" "skewrun" "no prebuilt binary for $arch and cargo unavailable"
    fi
}
