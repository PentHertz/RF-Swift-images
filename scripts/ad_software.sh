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
    [ -n "$bin" ] && [ -e "/root/.local/bin/$bin" ] && ln -sf "/root/.local/bin/$bin" "/usr/sbin/$bin"
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
