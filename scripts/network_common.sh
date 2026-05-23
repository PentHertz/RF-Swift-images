#!/bin/bash

# ---------------------------------------------------------------------------
# VPN tools
# ---------------------------------------------------------------------------

function wireguard_install() {
    goodecho "[+] Installing WireGuard tools"
    install_dependencies "wireguard-tools"
}

function openvpn_install() {
    goodecho "[+] Installing OpenVPN"
    install_dependencies "openvpn"
}

function tailscale_install() {
    goodecho "[+] Installing Tailscale"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    installfromnet "curl -fsSL https://tailscale.com/install.sh -o /root/thirdparty/tailscale_install.sh"
    chmod +x /root/thirdparty/tailscale_install.sh
    APT_SYSTEMCTL_START=false /root/thirdparty/tailscale_install.sh
}

function netbird_install() {
    goodecho "[+] Installing Netbird"
    
    # Netbird does not provide RISC-V64 packages yet
    if [ "$(uname -m)" = "riscv64" ]; then
        criticalecho-noexit "[-] Netbird is not yet available for RISC-V64, skipping."
        return 0
    fi
    
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    installfromnet "curl -fsSL https://pkgs.netbird.io/install.sh -o /root/thirdparty/netbird_install.sh"
    chmod +x /root/thirdparty/netbird_install.sh
    /root/thirdparty/netbird_install.sh
}

function vpn_tools_install() {
    goodecho "[+] Installing all VPN tools (WireGuard, OpenVPN, Tailscale, Netbird)"
    wireguard_install
    openvpn_install
    tailscale_install
    netbird_install
}

# ---------------------------------------------------------------------------
# Network tools
# ---------------------------------------------------------------------------

function nmap_soft_install() {
	goodecho "[+] Installing Nmap from package manager"
	install_dependencies "nmap"
}

function hping3_soft_install() {
    goodecho "[+] Installing hping3"
    install_dependencies "hping3"
}

function arping_soft_install() {
    goodecho "[+] Installing arping"
    install_dependencies "arping"
}

function wireshark_soft_install() {
	goodecho "[+] Installing Wireshark from package manager"
	echo "wireshark-common wireshark-common/install-setuid boolean true" | sudo debconf-set-selections
	install_dependencies "wireshark"
}

function metasploit_soft_install() {
    # Get system architecture
    ARCH=$(uname -m)
    
    # Check if architecture is supported
    if [[ "$ARCH" == "x86_64" ]] || [[ "$ARCH" == "amd64" ]] || [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        goodecho "[+] Installing Metasploit for $ARCH architecture"
        [ -d /root/thirdparty ] || mkdir /root/thirdparty
        cd /root/thirdparty
        curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
        chmod 755 msfinstall
        sudo ./msfinstall
    else
        criticalecho-noexit "[-] Unsupported architecture: $ARCH"
        criticalecho-noexit "[-] Metasploit installation is only supported on amd64/x86_64 and arm64/aarch64"
    fi
}

function tshark_soft_install() {
	goodecho "[+] Installing TShark from package manager"
	install_dependencies "tshark"
}

function impacket_soft_install() {
	goodecho "[+] Installing Impacket from package manager"
	install_dependencies "python3-impacket"
}

function autorecon_soft_install() {
	goodecho "[+] Installing Autorecon from GitHub with PIP"
    ARCH=$(uname -m)
    
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then # TODO: do not compile in arm64
	   pipx install git+https://github.com/Tib3rius/AutoRecon.git
    fi
}

function responder_soft_install() {
	goodecho "[+] Installing Responder from GitHub"
	[ -d /opt/network ] || mkdir -p /opt/network
	cd /opt/network
    ARCH=$(uname -m)
    
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        gitinstall "https://github.com/lgandx/Responder.git" "responder_soft_install"
        cd Responder
        pip3install -r requirements.txt
    else
        goodecho "[-] Unsupported architecture: $ARCH" # TODO: check why RISC-V is failling
    fi
}

function kismet_soft_install() {
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        goodecho "[+] Installing Kismet from official repository for $ARCH"
        
        # Download and install GPG key
        installfromnet "wget -qO /tmp/kismet-release.gpg.key https://www.kismetwireless.net/repos/kismet-release.gpg.key"
        gpg --dearmor < /tmp/kismet-release.gpg.key > /usr/share/keyrings/kismet-archive-keyring.gpg
        rm -f /tmp/kismet-release.gpg.key
        
        # Add repository
        echo 'deb [signed-by=/usr/share/keyrings/kismet-archive-keyring.gpg] https://www.kismetwireless.net/repos/apt/release/noble noble main' > /etc/apt/sources.list.d/kismet.list
        
        apt-get update
        install_dependencies "kismet"
        
    elif [ "$ARCH" = "riscv64" ]; then
        goodecho "[+] RISC-V architecture detected, installing Kismet from source"
        kismet_soft_install_fromsource
        
    else
        goodecho "[-] Unsupported architecture: $ARCH"
        goodecho "[!] Attempting to install from source as fallback"
        kismet_soft_install_fromsource
    fi
}

function kismet_soft_install_fromsource() {
	goodecho "[+] Installing Kismet dependencies"
	[ -d /rftools ] || mkdir -p /rftools
	cd /rftools
	check_and_install_lib "librtlsdr-dev librtlsdr2" "librtlsdr"
	install_dependencies "libsqlite3-dev ubertooth libprelude-dev build-essential git libwebsockets-dev pkg-config zlib1g-dev libnl-3-dev libnl-genl-3-dev libcap-dev libpcap-dev libnm-dev libdw-dev libsqlite3-dev libprotobuf-dev libprotobuf-c-dev protobuf-compiler protobuf-c-compiler libsensors-dev libusb-1.0-0-dev python3 python3-setuptools python3-protobuf python3-requests python3-serial python3-usb python3-dev python3-websockets libubertooth-dev libbtbb-dev libmosquitto-dev"
	goodecho "[+] Installing Kismet"
	installfromnet "git clone https://www.kismetwireless.net/git/kismet.git"
	cd kismet
	./configure --enable-bladerf --enable-wifi-coconut --enable-btgeiger --enable-prelude --enable-python-tools
	make
	make -j$(nproc)
	make suidinstall
	make forceconfigs
	make install
}

function gowitnes_soft_install() {
    goodecho "[+] Installing gowitness"
    ARCH=$(uname -m)
    
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then # TODO: takes forever to compile on arm64
        export GOPROXY=https://proxy.golang.org,direct
        export GOSUMDB=sum.golang.org
        go install github.com/sensepost/gowitness@latest
    fi
}

function webcopilot_soft_install() {
    goodecho "[+] Installing webcopilot"
    if [ "$(uname -m)" = "riscv64" ]; then #TODO: compilation too slow for now
        criticalecho-noexit "[!] Skipping WebCopilot install on RISC-V64 (not supported)"
        return 0
    fi
    [ -d /opt/network ] || mkdir -p /opt/network
    cd /opt/network
    gitinstall "https://github.com/FlUxIuS/webcopilot.git" "webcopilot_soft_install"
    cd webcopilot
    chmod +x install.sh
    ./install.sh
}

function subenum_soft_install() {
    goodecho "[+] Installing SubEnum"
    [ -d /opt/network ] || mkdir -p /opt/network
    cd /opt/network
    gitinstall "https://github.com/FlUxIuS/SubEnum.git" "subenum_soft_install"
    cd SubEnum
    chmod +x setup.sh
	./setup.sh
	ln -s $(pwd)/subenum.sh /usr/sbin/subenum.sh
}

function mbtget_soft_install() {
    goodecho "[+] Installing mbtget"
    [ -d /opt/network ] || mkdir -p /opt/network
    cd /opt/network
    gitinstall "https://github.com/sourceperl/mbtget.git" "mbtget_soft_install"
    cd mbtget
    perl Makefile.PL
    make
	make install
}

function ettercap_soft_install() {
    goodecho "[+] Installing ettercap"
    install_dependencies "ettercap-text-only"
}

function isc_dhcp_server_soft_install() {
    goodecho "[+] Installing isc-dhcp-server"
    install_dependencies "isc-dhcp-server"
}

function lighttpd_soft_install() {
    goodecho "[+] Installing lighttpd"
    install_dependencies "lighttpd"
}

function crunch_soft_install() {
    goodecho "[+] Installing crunch"
    install_dependencies "crunch"
}

function bettercap_soft_install() {
	goodecho "[+] Installing bettercap"
	rm -rf ~/.cache/go-build #TODO: trying to solve build exit for ARM on GitHub
	export GOPROXY=direct
	install_dependencies "libnetfilter-queue-dev"
	[ -d /rftools/bluetooth ] || mkdir -p /rftools/bluetooth
	cd /rftools/bluetooth
	gitinstall "https://github.com/bettercap/bettercap.git"
	cd bettercap
	make build
	make install
	ln -s /rftools/bluetoot/bettercap/bettercap /usr/bin/bettercap
}

function sipvicious_soft_install() {
    goodecho "[+] Installing SIP Vicious"
    install_dependencies "libxml2-dev libxslt1-dev"
    [ -d /opt/network ] || mkdir -p /opt/network
    cd /opt/network
    gitinstall "https://github.com/EnableSecurity/sipvicious.git" "sipvicious_soft_install"
    cd sipvicious
    pip3install .
}

function voipire_soft_install() {
    goodecho "[+] Installing VoIPire"
    [ -d /opt/network ] || mkdir -p /opt/network
    cd /opt/network
    gitinstall "https://github.com/CR-DMcDonald/voipire.git" "voipire_soft_install"
    cd voipire
    cargo build --release
    ln -s $(pwd)/target/release/voipire /usr/bin/voipire
}

function sippts_soft_install() {
    goodecho "[+] Installing SIPPTS" #TODO: not valid yet on RISCV64
    if [[ "$ARCH" == "x86_64" ]] || [[ "$ARCH" == "amd64" ]] || [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        [ -d /opt/network ] || mkdir -p /opt/network
        cd /opt/network
        gitinstall "https://github.com/Pepelux/sippts.git" "sippts_soft_install"
        cd sippts
        pip3install .
    fi
}

function netexec_soft_install() {
    goodecho "[+] Installing NetExec"
    install_dependencies "pipx git"
    pipx ensurepath
    pipx install git+https://github.com/Pennyw0rth/NetExec
    ln -s /root/.local/bin/netexec /usr/sbin/netexec
}

function donpapi_soft_install() {
    goodecho "[+] Installing DonPAPI"
    install_dependencies "pipx git"
    pipx install git+https://github.com/FlUxIuS/DonPAPI
    ln -s /root/.local/bin/DonPAPI /usr/sbin/DonPAPI
}

function donpwner_soft_install() {
    goodecho "[+] Installing DonPwner"
    [ -d /opt/network ] || mkdir -p /opt/network
    cd /opt/network
    gitinstall "https://github.com/FlUxIuS/DonPwner.git" "donpwner_soft_install"
}

function above_soft_install() {
    goodecho "[+] Installing Above"
    install_dependencies "python3-scapy python3-colorama python3-setuptools"
    pipx install git+https://github.com/caster0x00/above.git
    ln -s  /root/.local/bin/above /usr/sbin/above
}

# Cracking tools
function hashcat_soft_install() {
	goodecho "[+] Installing hashcat"
	install_dependencies "pixiewps"
}

function hashcat_soft_install() {
    goodecho "[+] Installing hashcat"
    install_dependencies "pixiewps"
}

function seclist_soft_install() {
    goodecho "[+] Installing SecList resources"
    [ -d /opt/fuzzing ] || mkdir -p /opt/fuzzing
    cd /opt/fuzzing
    gitinstall "https://github.com/danielmiessler/SecLists.git" "seclist_soft_install"
}

function johnjumbo_soft_install() {
    goodecho "[+] Installing johnjumbo"
    [ -d /opt/crack ] || mkdir -p /opt/crack
    cd /opt/crack
    install_dependencies "libdb-dev"
    gitinstall "https://github.com/openwall/john.git" "john_soft_install"
    cd john
    cd src
    ./configure
    make -j$(nproc)
    make install
    cd ../run
    #pip3install -r requirements.txt
    cp *.py /usr/local/bin
    ln -s $(pwd)/john /usr/local/bin/JohnJumbo
}

function caido_soft_install() {
    goodecho "[+] Installing Caido Desktop"
    install_dependencies "libnss3"
    ARCH=$(uname -m)
    
    # Map architecture names to Caido's naming convention
    case "$ARCH" in
        x86_64|amd64)
            CAIDO_ARCH="x86_64"
            ;;
        aarch64|arm64)
            CAIDO_ARCH="aarch64"
            ;;
        *)
            criticalecho-noexit "[!] Error: Unsupported architecture: $ARCH"
            criticalecho-noexit "[!] Supported architectures: x86_64, aarch64/arm64"
            exit 0
            ;;
    esac
    
    goodecho "[+] Detected architecture: $ARCH -> Using Caido $CAIDO_ARCH"
    
    # Install required dependencies
    install_dependencies "curl jq tar"
    
    # Create directory structure
    [ -d /security ] || mkdir /security
    cd /security
    mkdir -p Caido
    cd Caido
    
    # Get the latest release and download appropriate desktop version
    goodecho "[+] Fetching latest Caido desktop release information..."
    CAIDO_URL=$(curl -s https://api.caido.io/releases/latest | jq -r ".links[] | select(.display == \"Linux Desktop ${CAIDO_ARCH} (tar.gz)\") | .link")
    
    if [ -z "$CAIDO_URL" ] || [ "$CAIDO_URL" = "null" ]; then
        criticalecho-noexit "[!] Error: Could not fetch Caido desktop download URL for architecture $CAIDO_ARCH"
        exit 0
    fi
    
    goodecho "[+] Downloading Caido Desktop from: $CAIDO_URL"
    curl -L "$CAIDO_URL" -o caido-desktop.tar.gz
    
    # Verify download
    if [ ! -f caido-desktop.tar.gz ] || [ ! -s caido-desktop.tar.gz ]; then
        criticalecho-noexit "[!] Error: Failed to download Caido Desktop or file is empty"
        exit 0
    fi
    
    # Extract
    goodecho "[+] Extracting Caido Desktop..."
    tar -xf caido-desktop.tar.gz
    rm caido-desktop.tar.gz
    
    # Find the caido binary and make it executable
    CAIDO_BINARY=$(find . -name "caido" -type f)
    if [ -z "$CAIDO_BINARY" ]; then
        criticalecho-noexit "[!] Error: Could not find caido binary in extracted files"
        exit 0
    fi
    
    chmod +x "$CAIDO_BINARY"
    
    # Create wrapper script with --no-sandbox flag
    goodecho "[+] Creating Caido launcher script..."
    cat > /usr/bin/caido << 'EOF'
#!/bin/bash
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
CAIDO_DIR="/security/Caido"
CAIDO_BINARY=$(find "$CAIDO_DIR" -name "caido" -type f)
exec "$CAIDO_BINARY" --no-sandbox "$@"
EOF
    
    chmod +x /usr/bin/caido
    
    goodecho "[+] Caido Desktop installed successfully"
    goodecho "[+] Usage: caido (launches with --no-sandbox automatically)"
}

function beef_soft_install() {
    colorecho "[+] Installing BeEF"
    export TERM=xterm
    
    [ -d /opt/network ] || mkdir -p /opt/network
    cd /opt/network
    # Create a wrapper script
    cat > /usr/local/bin/beef << 'EOF'
#!/bin/bash
cd /opt/network/beef
exec ./beef "$@"
EOF
    chmod +x /usr/local/bin/beef
    gitinstall "https://github.com/beefproject/beef" "beef_soft_install"
    cd beef
    yes | ./install || true  # Ignore SIGPIPE exit code
    
    colorecho "[+] BeEF installed successfully"
}

function asleap_soft_install() {
    colorecho "[+] Installing asleap dependencies"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    git clone https://github.com/besser82/libxcrypt.git
    cd libxcrypt
    ./autogen.sh
    ./configure
    make -j $(nproc)
    make install
    colorecho "[+] Installing asleap now!"
    [ -d /opt/network ] || mkdir -p /opt/network
    cd /opt/network
    gitinstall "https://github.com/FlUxIuS/asleap.git" "asleap_soft_install" "des_fix"
    cd asleap
    make
    ln -s $(pwd)/asleap /usr/local/bin/asleap
}

function trufflehog_script_install() {
    # Check architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64|amd64)
            ARCH_NORMALIZED="amd64"
            ;;
        aarch64|arm64)
            ARCH_NORMALIZED="arm64"
            ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $ARCH"
            return 0
            ;;
    esac
    
    curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh | sh -s -- -b /usr/local/bin
}

function burpsuite_community_install() { # TODO: only working well on x86_64 with the GUI :/
    local version="${1:-2026.4.3}"
    local install_dir="/opt/burpsuite"
    local arch=$(uname -m)
    
    colorecho "[+] Installing Burp Suite Community Edition v${version} for ${arch}"
    
    # Create installation directory if it doesn't exist
    if [ ! -d "$install_dir" ]; then
        sudo mkdir -p "$install_dir"
    fi
    
    # Check if already installed
    if [ -f "${install_dir}/BurpSuiteCommunity" ] || [ -f "${install_dir}/burpsuite_community.jar" ]; then
        colorecho "[!] Burp Suite Community Edition appears to be already installed at ${install_dir}"
        read -p "Do you want to reinstall? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            goodecho "[+] Skipping Burp Suite installation"
            return 0
        fi
    fi
    
    # Architecture-specific installation
    case "$arch" in
        x86_64|amd64)
            # Use official installer for x86_64
            local download_url="https://portswigger.net/burp/releases/download?product=community&version=${version}&type=Linux"
            local installer_file="/tmp/burpsuite_community_linux_v${version}.sh"
            
            colorecho "[+] Downloading Burp Suite Community Edition installer..."
            installfromnet "curl -L -o ${installer_file} ${download_url}"
            
            if [ ! -f "$installer_file" ]; then
                criticalecho "[-] Failed to download Burp Suite installer"
            fi
            
            chmod +x "$installer_file"
            
            colorecho "[+] Running Burp Suite installer (unattended mode)..."
            sudo "$installer_file" -q -dir "$install_dir" || {
                criticalecho-noexit "[-] Installation failed"
                rm -f "$installer_file"
                return 1
            }
            
            rm -f "$installer_file"
            
            if [ -f "${install_dir}/BurpSuiteCommunity" ]; then
                sudo ln -sf "${install_dir}/BurpSuiteCommunity" /usr/local/bin/burpsuite 2>/dev/null || true
            fi
            ;;
            
        aarch64|arm64)
            colorecho "[+] ARM64 detected - installing JAR with compatible JRE"
            install_burpsuite_jar "$version" "$install_dir" "arm64"
            ;;
            
        riscv64)
            colorecho "[+] RISC-V64 detected - installing JAR with compatible JRE"
            install_burpsuite_jar "$version" "$install_dir" "riscv64"
            ;;
            
        *)
            colorecho "[!] Unsupported architecture: ${arch}"
            colorecho "[+] Attempting JAR installation with system JRE..."
            install_burpsuite_jar "$version" "$install_dir" "generic"
            ;;
    esac
    
    # Log installation
    if [ ! -d "/var/lib/db/" ]; then
        sudo mkdir -p /var/lib/db/
    fi
    echo "burpsuite:${install_dir}:binary" | sudo tee -a /var/lib/db/rfswift_github.lst > /dev/null
    
    goodecho "[+] Burp Suite Community Edition v${version} installed successfully!"
    goodecho "[+] Launch with: burpsuite"
}

function install_burpsuite_jar() {
    local version="$1"
    local install_dir="$2"
    local arch_type="$3"
    local jar_url="https://portswigger-cdn.net/burp/releases/download?product=community&version=${version}&type=Jar"
    local jar_file="${install_dir}/burpsuite_community.jar"
    
    # Install appropriate JRE
    colorecho "[+] Installing Java Runtime Environment..."
    case "$arch_type" in
        arm64)
            # For ARM64 - prefer native packages
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y openjdk-17-jre-headless || \
                sudo apt-get install -y openjdk-11-jre-headless
            elif command -v apk &> /dev/null; then
                sudo apk add --no-cache openjdk17-jre || sudo apk add --no-cache openjdk11-jre
            elif command -v yum &> /dev/null; then
                sudo yum install -y java-17-openjdk-headless || sudo yum install -y java-11-openjdk-headless
            fi
            ;;
        riscv64)
            # For RISC-V64 - limited JRE options
            colorecho "[!] RISC-V64 JRE support is limited. Attempting installation..."
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y openjdk-17-jre-headless || \
                sudo apt-get install -y openjdk-11-jre-headless
            elif command -v apk &> /dev/null; then
                sudo apk add --no-cache openjdk17-jre || sudo apk add --no-cache openjdk11-jre
            fi
            ;;
        *)
            # Generic - try to install any available JRE
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y default-jre-headless
            elif command -v apk &> /dev/null; then
                sudo apk add --no-cache openjdk17-jre
            elif command -v yum &> /dev/null; then
                sudo yum install -y java-17-openjdk-headless
            fi
            ;;
    esac
    
    # Verify Java is available
    if ! command -v java &> /dev/null; then
        criticalecho "[-] Failed to install Java Runtime Environment"
    fi
    
    # Download JAR file
    colorecho "[+] Downloading Burp Suite JAR..."
    installfromnet "curl -L -o ${jar_file} ${jar_url}"
    
    if [ ! -f "$jar_file" ]; then
        criticalecho "[-] Failed to download Burp Suite JAR"
    fi
    
    # Create wrapper script
    colorecho "[+] Creating launcher script..."
    sudo tee "${install_dir}/BurpSuiteCommunity" > /dev/null <<'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec java -jar "${SCRIPT_DIR}/burpsuite_community.jar" "$@"
EOF
    
    sudo chmod +x "${install_dir}/BurpSuiteCommunity"
    sudo ln -sf "${install_dir}/BurpSuiteCommunity" /usr/local/bin/burpsuite 2>/dev/null || true
    
    # Verify installation
    if [ ! -f "$jar_file" ] || [ ! -f "${install_dir}/BurpSuiteCommunity" ]; then
        criticalecho "[-] Installation verification failed"
    fi
}

function argus_soft_install_fromsource() {
    goodecho "[+] Installing Argus - Information Gathering & Reconnaissance"
    if [ "$(uname -m)" = "riscv64" ]; then # TODO: fix that for RISC-V 64
        criticalecho-noexit "[!] Skipping Argus install on RISC-V64 (build too slow)"
        return 0
    fi
    install_dependencies "libxml2-dev libxslt1-dev"
    pipx install argus-recon
    ln -s /root/.local/bin/argus /usr/sbin/argus
}

function curlie_soft_install_fromsource() {
    goodecho "[+] Installing curlie"
    export GOSUMDB=sum.golang.org
    export GOPROXY=direct
    go install github.com/rs/curlie@latest
    ln -s /root/go/bin/curlie /usr/sbin/curlie
}

function vortix_soft_install_fromsource() {
    goodecho "[+] Installing Vortix for real-time telemetry"
    rm -rf /root/.rustup /root/.cargo
    export RUSTUP_HOME=/tmp/rustup
    export CARGO_HOME=/tmp/cargo
    export PATH="$CARGO_HOME/bin:$PATH"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    cargo install vortix
    cp "$CARGO_HOME/bin/vortix" /usr/local/bin/
    rm -rf /tmp/rustup /tmp/cargo
    sed -i '/\/tmp\/cargo\/env/d' /root/.zshenv
}

function netwatch_soft_install_fromsource() {
    goodecho "[+] Installing NetWatch"
    rm -rf /root/.rustup /root/.cargo
    export RUSTUP_HOME=/tmp/rustup
    export CARGO_HOME=/tmp/cargo
    export PATH="$CARGO_HOME/bin:$PATH"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    cargo install netwatch-tui
    cp "$CARGO_HOME/bin/netwatch" /usr/local/bin/
    rm -rf /tmp/rustup /tmp/cargo
    sed -i '/\/tmp\/cargo\/env/d' /root/.zshenv
}

function wiretapper_soft_install_fromsource() {
    goodecho "[+] Installing WireTapper"
    [ -d /opt/network ] || mkdir -p /opt/network
    cd /opt/network
    gitinstall "https://github.com/h9zdev/WireTapper.git" "wiretapper_soft_install_fromsource"
    cd WireTapper
    python3 -m venv venv
    source venv/bin/activate
    pip install -r WireTapper.txt
    deactivate
    rm -f /usr/sbin/WireTapper
    cat <<'EOF' > /usr/sbin/WireTapper
#!/bin/bash
# Usage: WireTapper [wigle_api_name] [wigle_api_token] [opencellid_key] [shodan_key]
# Or set env vars: WIGLE_API_NAME, WIGLE_API_TOKEN, OPENCELLID_API_KEY, SHODAN_API_KEY
source /opt/network/WireTapper/venv/bin/activate
cd /opt/network/WireTapper
exec python3 app-env.py
EOF
    chmod +x /usr/sbin/WireTapper
}

function snitch_soft_install() {
    goodecho "[+] Installing snitch"
    export GOSUMDB=sum.golang.org
    export GOPROXY=direct
    go install github.com/karol-broda/snitch@latest
    ln -s /root/go/bin/snitch /usr/sbin/snitch
}

function sslyze_soft_install() { # TODO: make it work with RISC-V
    goodecho "[+] Installing sslyze"
    ARCH=$(uname -m)
    if [ "$ARCH" != "riscv64" ]; then
            pipx install sslyze
            pipx ensurepath
    else
        echo "[!] Skipping sslyze: nassl not supported on riscv64"
    fi
}

function netcatopenbsd_soft_install() {
    goodecho "[+] Installing Netcat (openbsd)"
    install_dependencies "netcat-openbsd" 
}

function telnet_soft_install() {
    goodecho "[+] Installing Telnet"
    install_dependencies "telnet" 
}

function titus_soft_install() {
    goodecho "[+] Installing titus"
    [ -d /opt/network ] || mkdir -p /opt/network
    cd /opt/network
    export GOSUMDB=sum.golang.org
    export GOPROXY=direct
    gitinstall "https://github.com/praetorian-inc/titus.git" "titus_soft_install"
    cd titus

    ARCH=$(uname -m)
    if [ "$ARCH" = "riscv64" ]; then
        # libhyperscan-dev/vectorscan not available on riscv64
        # build-pure is the official fallback (slower scanning, no hyperscan dep)
        # make install-burp triggers make build internally -> vectorscan check fails
        goodecho "[+] Building titus without vectorscan (riscv64 fallback)"
        make build-pure
        make install
        ln -sf /root/.titus/titus /usr/sbin/titus
        install_dependencies "default-jre-headless"
        goodecho "[!] Skipping make install-burp on riscv64 (requires vectorscan)"
    else
        make build
        make install
        ln -sf /root/.titus/titus /usr/sbin/titus
        install_dependencies "default-jre-headless"
        make install-burp
    fi
}

function brutus_soft_install() {
    goodecho "[+] Installing brutus"
    export GOSUMDB=sum.golang.org
    export GOPROXY=direct
    go install github.com/praetorian-inc/brutus/cmd/brutus@latest
    ln -s ~/go/bin/brutus /usr/sbin/brutus
    ln -s ~/go/bin/nabuu /usr/sbin/nabuu
}

function whosthere_soft_install() {
    goodecho "[+] Installing whosthere"
    export GOSUMDB=sum.golang.org
    export GOPROXY=direct
    go install github.com/ramonvermeulen/whosthere@latest
    ln -s /root/go/bin/whosthere /usr/local/bin/whosthere
}

function nerva_soft_install() {
    goodecho "[+] Installing nerva"
    export GOSUMDB=sum.golang.org
    export GOPROXY=direct
    go install github.com/praetorian-inc/nerva/cmd/nerva@latest
    ln -s ~/go/bin/nerva /usr/bin/nerva
}

function trippy_soft_install() {
    goodecho "[+] Installing trippy"
    [ -d /opt/network ] || mkdir -p /opt/network
    cd /opt/network
    gitinstall "https://github.com/fujiapple852/trippy.git" "trippy_soft_install"
    cd trippy
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    export PATH="$HOME/.cargo/bin:$PATH"
    cargo install trippy --locked
}

function mic_soft_install() {
    goodecho "[+] Installing mic"
    [ -d /opt/network ] || mkdir -p /opt/network
    cd /opt/network
    export GOSUMDB=sum.golang.org
    export GOPROXY=direct
    gitinstall "https://github.com/djnnvx/mic.git" "mic_soft_install"
    cd mic
    go build -o mic .
    ln -s $(pwd)/mic /usr/bin/mic
}

function betterleaks_soft_install() {
    goodecho "[+] Installing betterleaks"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    export GOSUMDB=sum.golang.org
    export GOPROXY=direct
    gitinstall "https://github.com/betterleaks/betterleaks.git" "betterleaks_soft_install"
    cd betterleaks
    make build
    mkdir -p /opt/network/betterleaks
    cp betterleaks /opt/network/betterleaks
    ln -s /opt/network/betterleaks /usr/local/bin/betterleaks
}

function hexhttp_soft_install() {
    goodecho "[+] Installing HExHTTP"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    gitinstall "https://github.com/c0dejump/HExHTTP.git" "hexhttp_soft_install"
    cd HExHTTP
    pipx install .
    pipx ensurepath
}

function reconftw_soft_install() {
    goodecho "[+] Installing reconftw"
    [ -d /opt/network ] || mkdir -p /opt/network
    cd /opt/network
    export GOSUMDB=sum.golang.org
    export GOPROXY=direct
    gitinstall "https://github.com/six2dez/reconftw.git" "reconftw_soft_install"
    cd reconftw
    ./install.sh --verbose
    ln -s $(pwd)/reconftw.sh /usr/sbin/reconftw
}

function cryptocondor_soft_install() {
    goodecho "[+] Installing crypto-condor"
    pipx install crypto-condor
    pipx ensurepath
}

function nmapautomator_soft_install() {
    goodecho "[+] Installing nmapAutomator"
    [ -d /opt/network ] || mkdir -p /opt/network
    cd /opt/network
    gitinstall "https://github.com/21y4d/nmapAutomator.git" "nmapautomator_soft_install"
    ln -s $(pwd)/nmapAutomator.sh /usr/sbin/nmapAutomator
}

function install_pyGoldenGMSA() {
    goodecho "[+] Installing pyGoldenGMSA"
    [ -d /opt/network ] || mkdir -p /opt/network
    install_dependencies "libldap2-dev libsasl2-dev"
    cd /opt/network
    gitinstall "https://github.com/felixbillieres/pyGoldenGMSA.git" "install_pyGoldenGMSA"
    cd pyGoldenGMSA
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    deactivate

    # Create wrapper script
    cat <<'EOF' > /usr/local/bin/pygoldengmsa
#!/bin/bash
source /opt/network/pyGoldenGMSA/venv/bin/activate
python3 /opt/network/pyGoldenGMSA/main.py "$@"
EOF
    chmod +x /usr/local/bin/pygoldengmsa
}

function tetsuo_h3sec_soft_install() {
    goodecho "[+] Installing tetsuo-h3sec"

    # Build quictls (OpenSSL with QUIC support)
    goodecho "[+] Building quictls/openssl"
    git clone --depth 1 -b openssl-3.1.5+quic https://github.com/quictls/openssl.git /opt/quictls
    cd /opt/quictls
    ./config --prefix=/opt/quictls/install
    make -j$(nproc)
    make install_sw install_ssldirs

    # Make quictls available at runtime
    echo "/opt/quictls/install/lib64" > /etc/ld.so.conf.d/quictls.conf
    ldconfig

    [ -d /opt/network ] || mkdir -p /opt/network
    cd /opt/network
    gitinstall "https://github.com/tetsuo-ai/tetsuo-h3sec.git" "tetsuo_h3sec_soft_install"
    cd tetsuo-h3sec

    export OPENSSL_ROOT_DIR=/opt/quictls/install
    export PKG_CONFIG_PATH="/opt/quictls/install/lib64/pkgconfig:$PKG_CONFIG_PATH"

    # Build tetsuo-pulse (required dependency)
    cmake -S tetsuo-pulse -B tetsuo-pulse/build \
        -DENABLE_TLS=ON \
        -DOPENSSL_ROOT_DIR=/opt/quictls/install \
        -DOPENSSL_INCLUDE_DIR=/opt/quictls/install/include \
        -DCMAKE_C_FLAGS="-Wno-error=unused-value"
    cmake --build tetsuo-pulse/build -j$(nproc)
    # Build the scanner
    cmake -S scanner -B scanner/build \
        -DOPENSSL_ROOT_DIR=/opt/quictls/install \
        -DOPENSSL_INCLUDE_DIR=/opt/quictls/install/include \
        -DCMAKE_C_FLAGS="-Wno-error=unused-value"
    cmake --build scanner/build -j$(nproc)

    ln -s $(pwd)/scanner/build/h3sec /usr/local/bin/
}

function sstimap_soft_install() {
    goodecho "[+] Installing SSTImap"
    [ -d /opt/network ] || mkdir -p /opt/network
    cd /opt/network
    gitinstall "https://github.com/vladko312/SSTImap.git" "sstimap_soft_install"
    cd SSTImap
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    deactivate
    # Create wrapper script
    cat <<'EOF' > /usr/local/bin/sstimap
#!/bin/bash
source /opt/network/SSTImap/venv/bin/activate
python3 /opt/network/SSTImap/sstimap.py "$@"
EOF
    chmod +x /usr/local/bin/sstimap
}

function sqlmap_soft_install() {
    goodecho "[+] Installing sqlmap"
    [ -d /opt/web ] || mkdir -p /opt/web
    cd /opt/web
    gitinstall "https://github.com/sqlmapproject/sqlmap.git" "install_sqlmap"
    # Create wrapper script
    cat <<'EOF' > /usr/local/bin/sqlmap
#!/bin/bash
python3 /opt/web/sqlmap/sqlmap.py "$@"
EOF
    chmod +x /usr/local/bin/sqlmap
}
