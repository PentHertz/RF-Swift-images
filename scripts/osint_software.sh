#!/bin/bash
#
# OSINT (open-source intelligence) tooling for RF-Swift. Built on the corebuild
# base. RF-Swift helpers (install_dependencies / pipx / go install / gitinstall)
# with best-effort build reporting so one failing tool never aborts the image.

OSINT_DIR="/opt/osint"

function osint_apt_tools_install() {
    goodecho "[+] Installing OSINT apt tooling"
    install_dependencies "libimage-exiftool-perl exiftran dnsenum tor whois dnsutils"
}

# pipx install with best-effort reporting + optional symlink of the entrypoint.
function _osint_pipx() {
    local name="$1" spec="$2" bin="$3"
    pipx install "$spec" \
        || record_build_failure "pip" "$name" "pipx install failed"
    [ -n "$bin" ] && [ -e "/root/.local/bin/$bin" ] && ln -sf "/root/.local/bin/$bin" "/usr/sbin/$bin"
}

function osint_pipx_tools_install() {
    goodecho "[+] Installing OSINT pipx tools"
    install_dependencies "pipx git"; pipx ensurepath
    _osint_pipx "theHarvester" "git+https://github.com/laramies/theHarvester" "theHarvester"
    _osint_pipx "sherlock"     "sherlock-project"                              "sherlock"
    _osint_pipx "holehe"       "holehe"                                        "holehe"
    _osint_pipx "maigret"      "maigret"                                       "maigret"
    _osint_pipx "sublist3r"    "git+https://github.com/aboul3la/Sublist3r"     "sublist3r"
    _osint_pipx "h8mail"       "h8mail"                                        "h8mail"
    _osint_pipx "ghunt"        "ghunt"                                         "ghunt"
    _osint_pipx "instaloader"  "instaloader"                                   "instaloader"
    _osint_pipx "toutatis"     "toutatis"                                      "toutatis"
    _osint_pipx "censys"       "censys"                                        "censys"
}

function osint_go_tools_install() {
    goodecho "[+] Installing OSINT Go tools"
    install_dependencies "golang-go git"
    local t
    for t in \
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest" \
        "github.com/tomnomnom/assetfinder@latest" \
        "github.com/tomnomnom/waybackurls@latest" ; do
        GOBIN=/usr/local/bin go install "$t" \
            || record_build_failure "build" "go:${t%@*}" "go install failed"
    done
}

function spiderfoot_soft_install() {
    goodecho "[+] Installing SpiderFoot"
    install_dependencies "python3-venv git"
    [ -d "$OSINT_DIR" ] || mkdir -p "$OSINT_DIR"
    cd "$OSINT_DIR"
    gitinstall "https://github.com/smicallef/spiderfoot.git" "spiderfoot_soft_install"
    if [ -d spiderfoot ]; then
        cd spiderfoot
        python3 -m venv venv
        CFLAGS="${CFLAGS:-} -Wno-incompatible-pointer-types -Wno-int-conversion -Wno-implicit-function-declaration" \
            ./venv/bin/pip install -r requirements.txt \
            || record_build_failure "pip" "spiderfoot" "requirements install failed"
        cat > /usr/local/bin/spiderfoot <<EOF
#!/bin/bash
cd "$OSINT_DIR/spiderfoot" && exec ./venv/bin/python sf.py "\$@"
EOF
        chmod +x /usr/local/bin/spiderfoot
    else
        record_build_failure "git" "spiderfoot" "clone failed"
    fi
}

function reconng_soft_install() {
    goodecho "[+] Installing recon-ng"
    install_dependencies "python3-venv git"
    [ -d "$OSINT_DIR" ] || mkdir -p "$OSINT_DIR"
    cd "$OSINT_DIR"
    gitinstall "https://github.com/lanmaster53/recon-ng.git" "reconng_soft_install"
    if [ -d recon-ng ]; then
        cd recon-ng
        python3 -m venv venv
        CFLAGS="${CFLAGS:-} -Wno-incompatible-pointer-types -Wno-int-conversion -Wno-implicit-function-declaration" \
            ./venv/bin/pip install -r REQUIREMENTS \
            || record_build_failure "pip" "recon-ng" "requirements install failed"
        cat > /usr/local/bin/recon-ng <<EOF
#!/bin/bash
cd "$OSINT_DIR/recon-ng" && exec ./venv/bin/python recon-ng "\$@"
EOF
        chmod +x /usr/local/bin/recon-ng
    else
        record_build_failure "git" "recon-ng" "clone failed"
    fi
}

function finalrecon_soft_install() {
    goodecho "[+] Installing FinalRecon"
    install_dependencies "python3-venv git"
    [ -d "$OSINT_DIR" ] || mkdir -p "$OSINT_DIR"
    cd "$OSINT_DIR"
    gitinstall "https://github.com/thewhiteh4t/FinalRecon.git" "finalrecon_soft_install"
    if [ -d FinalRecon ]; then
        cd FinalRecon
        python3 -m venv venv
        CFLAGS="${CFLAGS:-} -Wno-incompatible-pointer-types -Wno-int-conversion -Wno-implicit-function-declaration" \
            ./venv/bin/pip install -r requirements.txt \
            || record_build_failure "pip" "finalrecon" "requirements install failed"
        cat > /usr/local/bin/finalrecon <<EOF
#!/bin/bash
cd "$OSINT_DIR/FinalRecon" && exec ./venv/bin/python finalrecon.py "\$@"
EOF
        chmod +x /usr/local/bin/finalrecon
    else
        record_build_failure "git" "finalrecon" "clone failed"
    fi
}
