#!/bin/bash

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
	pipx install git+https://github.com/Tib3rius/AutoRecon.git
}

function responder_soft_install() {
	goodecho "[+] Installing Autorecon from GitHub"
	[ -d /opt/network ] || mkdir -p /opt/network
	cd /opt/network
	gitinstall "https://github.com/lgandx/Responder.git" "responder_soft_install"
	cd Responder
	pip3install -r requirements.txt
}

function kismet_soft_install() {
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
    goodecho "[+] Installing webcopilot"
    export GOPROXY=https://proxy.golang.org,direct
    export GOSUMDB=sum.golang.org
    go install github.com/sensepost/gowitness@latest
}

function webcopilot_soft_install() {
    goodecho "[+] Installing gowitness"
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
    goodecho "[+] Installing SIPPTS"
    [ -d /opt/network ] || mkdir -p /opt/network
    cd /opt/network
    gitinstall "https://github.com/Pepelux/sippts.git" "sippts_soft_install"
    cd sippts
    pip3install .
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

function john_soft_install() {
    goodecho "[+] Installing SIPPTS"
    [ -d /opt/crack ] || mkdir -p /opt/crack
    cd /opt/crack
    gitinstall "https://github.com/openwall/john.git" "john_soft_install"
    cd john
    cd src
    ./configure
    make -j$(nproc)
    make install
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