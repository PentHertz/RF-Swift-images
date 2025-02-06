#!/bin/bash

# General monitoring tools
function kismet_soft_install() {
	goodecho "[+] Installing Kismet dependencies"
	[ -d /rftools ] || mkdir -p /rftools
	cd /rftools
	check_and_install_lib "librtlsdr-dev librtlsdr0" "librtlsdr"
	install_dependencies "libsqlite3-dev ubertooth libprelude-dev build-essential git libwebsockets-dev pkg-config zlib1g-dev libnl-3-dev libnl-genl-3-dev libcap-dev libpcap-dev libnm-dev libdw-dev libsqlite3-dev libprotobuf-dev libprotobuf-c-dev protobuf-compiler protobuf-c-compiler libsensors-dev libusb-1.0-0-dev python3 python3-setuptools python3-protobuf python3-requests python3-numpy python3-serial python3-usb python3-dev python3-websockets libubertooth-dev libbtbb-dev libmosquitto-dev"
	goodecho "[+] Installing Kismet"
	installfromnet "git clone https://www.kismetwireless.net/git/kismet.git"
	cd kismet
	./configure --enable-bladerf --enable-wifi-coconut --enable-btgeiger --enable-prelude
	make
	make -j$(nproc)
	make suidinstall
	make forceconfigs
	make install
}

# Bluetooth Classic and LE
function blueztools_soft_install() {
	goodecho "[+] Installing bluez tools"
	install_dependencies "bluez bluez-tools bluez-hcidump bluez-btsco bluez-obexd libbluetooth-dev"
}

function mirage_soft_install() {
    goodecho "[+] Installing bettercap dependencies"
    echo apt-fast keyboard-configuration/variant string "English (US)" | debconf-set-selections
    echo apt-fast keyboard-configuration/layout string "English (US)" | debconf-set-selections
    echo apt-fast console-setup/codeset47 string "Guess optimal character set" | debconf-set-selections
    echo apt-fast console-setup/charmap47 string "UTF-8" | debconf-set-selections
    install_dependencies "libpcsclite-dev pcsc-tools kmod kbd python3-pip python3-build"
    pip3install "keyboard"
    goodecho "[+] Installing Mirage"
    [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    cd /root/thirdparty
    installfromnet "git clone https://github.com/RCayre/mirage"
    cd mirage/
    python3 -m pip install --upgrade pip build
    python3 -m build
    pip3install dist/*.whl
}

function bettercap_soft_install() {
	goodecho "[+] Installing bettercap"
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


function sniffle_soft_install() {
	goodecho "[+] Installing Sniffle with OpenDroneID decoder/encoder"
	[ -d /rftools/bluetooth ] || mkdir -p /rftools/bluetooth
	cd /rftools/bluetooth
	installfromnet "git clone https://github.com/bkerler/Sniffle.git"
	cd Sniffle/python_cli
	pip3install -r requirements.txt
}

function bluing_soft_install() {
    echo "[+] Installing necessary packages"
    
    if [ "$(uname -m)" = "riscv64" ]; then # TODO: Keep until supported on RISC-V repos
    	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
		cd /root/thirdparty
        # RISC-V: Build Python 3.10 from source
        sudo apt-get update
        install_dependencies "build-essential libssl-dev zlib1g-dev libncurses5-dev libncursesw5-dev libreadline-dev libsqlite3-dev libgdbm-dev libdb5.3-dev libbz2-dev libexpat1-dev liblzma-dev libffi-dev libgirepository1.0-dev libbluetooth-dev"
        wget https://www.python.org/ftp/python/3.10.13/Python-3.10.13.tgz
        tar xzf Python-3.10.13.tgz
        cd Python-3.10.13
        ./configure --enable-optimizations
        make -j $(nproc)
        sudo make altinstall
        cd ..
        rm -rf Python-3.10.13*
    else
        # x86/ARM: Use package manager
        add-apt-repository ppa:deadsnakes/ppa
        sudo apt-get update
        install_dependencies "python3.10 python3.10-venv python3.10-dev libgirepository1.0-dev libbluetooth-dev"
    fi

    [ -d /rftools/bluetooth/bluing ] || mkdir -p /rftools/bluetooth/bluing
    cd /rftools/bluetooth/bluing
    python3.10 -m venv bluing
    source bluing/bin/activate
    python3.10 -m pip install dbus-python==1.2.18
    python3.10 -m pip install --no-dependencies bluing PyGObject docopt btsm btatt bluepy configobj btl2cap pkginfo xpycommon halo pyserial bthci btgatt log_symbols colorama spinners six termcolor
}

function bdaddr_soft_install() {
	goodecho "[+] Installing bluing"
	[ -d /rftools/bluetooth ] || mkdir /rftools/bluetooth
	cd /rftools/bluetooth
	installfromnet "git clone https://github.com/thxomas/bdaddr"
	cd bdaddr
	make
}

# RFID package
function proxmark3_soft_install() {
	set +e # TODO: debug that function
    set +o pipefail
	goodecho "[+] Installing proxmark3 dependencies"
	install_dependencies "git ca-certificates build-essential pkg-config libreadline-dev"
	install_dependencies "gcc-arm-none-eabi libnewlib-dev qtbase5-dev libbz2-dev liblz4-dev libbluetooth-dev libpython3-dev libssl-dev libgd-dev"
	goodecho "[+] Installing proxmark3"
	[ -d /rftools/rfid ] || mkdir -p /rftools/rfid
	cd /rftools/rfid
	installfromnet "git clone https://github.com/RfidResearchGroup/proxmark3.git"
	cd proxmark3/
	make clean && make -j$(nproc)
	ln -s pm3 /usr/sbin/pm3
	set -e
    set -o pipefail
}

function libnfc_soft_install() {
	goodecho "[+] Installing libnfc dependencies"
	install_dependencies "autoconf libtool libusb-dev libpcsclite-dev build-essential pcsc-tools"
	goodecho "[+] Installing libnfc"
	install_dependencies "libnfc-dev libnfc-bin"
}

function mfoc_soft_install() {
	goodecho "[+] Installing mfoc"
	install_dependencies "mfoc"
}

function mfcuk_soft_install() {
	goodecho "[+] Installing mfcuk"
	install_dependencies "mfcuk"
}

function mfread_soft_install() {
	goodecho "[+] Installing mfread dependencies"
	pip3install "bitstring"
	install_dependencies "gcc-arm-none-eabi libnewlib-dev qtbase5-dev libbz2-dev liblz4-dev libbluetooth-dev libpython3-dev libssl-dev libgd-dev"
	goodecho "[+] Installing mfdread"
	[ -d /rftools/rfid ] || mkdir -p /rftools/rfid
	cd /rftools/rfid
	installfromnet "git clone https://github.com/zhovner/mfdread.git"
}

function rfidler_soft_install() {
    # Check if architecture is x86_64 or amd64
    if [[ "$(uname -m)" == "x86_64" || "$(uname -m)" == "amd64" ]]; then
        echo "[+] Installing rfidler dependencies"
        
        cd /tmp
        gitinstall "https://github.com/AdamLaurie/mphidflash.git" "mphidflash"
        
        cd mphidflash
        sudo make install64
        
        [ -d /rftools/rfid ] || mkdir -p /rftools/rfid
        
        cd /rftools/rfid
        gitinstall "https://github.com/AdamLaurie/RFIDler.git" "RFIDler"
    else
        echo "This function is only supported on x86_64/amd64 architectures. Skipping installation."
    fi
}

function miLazyCracker_soft_install() {
	install_dependencies "mfoc"
	[ -d /rftools/rfid ] || mkdir -p /rftools/rfid
	cd /rftools/rfid
	goodecho "[+] Cloning miLazyCracker repo"
	gitinstall "https://github.com/nfc-tools/miLazyCracker.git" "miLazyCracker"
	cd miLazyCracker
	[ -f craptev1-v1.1.tar.xz ] || installfromnet "wget https://web.archive.org/web/20190221140220if_/https://www2.vaneay.fr/mifare/craptev1-v1.1.tar.xz"
	[ -f crapto1-v3.3.tar.xz ] || installfromnet "wget https://web.archive.org/web/20190221140255if_/https://www2.vaneay.fr/mifare/crapto1-v3.3.tar.xz"
	goodecho "[+] Installing crypto1_bs for miLazyCracker"
	gitinstall "https://github.com/aczid/crypto1_bs" "crypto1_bs"
	cd crypto1_bs
	git reset --hard
    git clean -dfx
    # patch initially done against commit 89de1ba5:
    if patch -p1 < ../crypto1_bs.diff; then
    echo "Patch applied successfully."
	else
	    echo "Patch failed? Continuing with the script..."
	    # Optionally, log more details about the failure or handle it specifically
	fi
    tar Jxvf ../craptev1-v1.1.tar.xz
    mkdir crapto1-v3.3
    tar Jxvf ../crapto1-v3.3.tar.xz -C crapto1-v3.3
    # Replace the original CFLAGS line with conditional statements for different architectures
	sed -i '/^CFLAGS =/c\
	ifeq ($(shell uname -m), riscv64)\n\
	    CFLAGS = -std=gnu99 -O3 -march=rv64gc\n\
	else ifeq ($(shell uname -m), aarch64)\n\
	    CFLAGS = -std=gnu99 -O3 -march=armv8-a\n\
	else\n\
	    CFLAGS = -std=gnu99 -O3 -march=native\n\
	endif' Makefile
    make
    sudo cp -a libnfc_crypto1_crack /usr/local/bin
}

# Wi-Fi Package
function common_nettools() {
	install_dependencies "iproute2"
	echo apt-fast macchanger/automatically_run  boolean false | debconf-set-selections
	installfromnet "apt-fast install -y -q macchanger"
	echo apt-fast wireshark-common/install-setuid boolean true | debconf-set-selections
	installfromnet "apt-fast install -y -q tshark"
}

function aircrack_soft_install() {
	goodecho "[+] Installing aircrack-ng"
	install_dependencies "aircrack-ng"
}

function reaver_soft_install() {
	goodecho "[+] Installing reaver"
	install_dependencies "reaver"
}

function bully_soft_install() {
	goodecho "[+] Installing bully"
	install_dependencies "bully"
}

function pixiewps_soft_install() {
	goodecho "[+] Installing pixiewps"
	install_dependencies "pixiewps"
}

function Pyrit_soft_install() {
    goodecho "[+] Installing Pyrit"
    
    # Create virtual environment
    python3 -m venv pyrit_venv
    
    # Activate virtual environment (with error handling)
    if [ -f "pyrit_venv/bin/activate" ]; then
        source pyrit_venv/bin/activate
    elif [ -f "pyrit_venv/Scripts/activate" ]; then
        source pyrit_venv/Scripts/activate
    else
        goodecho "[-] Failed to create virtual environment"
        return 1
    fi
    
    # Upgrade pip
    pip3 install --upgrade pip
    
    # Install dependencies first
    pip3 install azure-cognitiveservices-speech>=1.36.0
    
    # Install Pyrit
    if pip3 install pyrit; then
        goodecho "[+] Pyrit installed successfully"
        deactivate
        return 0
    else
        goodecho "[-] Failed to install Pyrit"
        deactivate
        return 1
    fi
}

function eaphammer_soft_install() {
	goodecho "[+] Installing eaphammer"
	[ -d /rftools/wifi ] || mkdir -p /rftools/wifi
	cd /rftools/wifi
	installfromnet "git clone https://github.com/s0lst1c3/eaphammer.git"
	cd eaphammer/
	./ubuntu-unattended-setup
}

function airgeddon_soft_install() { # TODO: install all dependencies
	goodecho "[+] Installing airgeddon"
	[ -d /rftools/wifi ] || mkdir -p /rftools/wifi
	cd /rftools/wifi
	installfromnet "git clone https://github.com/v1s1t0r1sh3r3/airgeddon.git"
	cd airgeddon/
}

function wifite2_soft_install () {
	goodecho "[+] Installing wifite2"
	[ -d /rftools/wifi ] || mkdir -p /rftools/wifi
	cd /rftools/wifi
	installfromnet "git clone https://github.com/derv82/wifite2.git"
	cd wifite2/
}

function sparrowwifi_sdr_soft_install () { # TODO: to debug
	[ -d /rftools/wifi ] || mkdir -p /rftools/wifi
	cd /rftools/wifi
	goodecho "[+] Cloning and installing sparrow-wifi"
	gitinstall "https://github.com/ghostop14/sparrow-wifi.git" "sparrowwifi"
	cd sparrow-wifi
	install_dependencies "python3-pip gpsd gpsd-clients python3-tk python3-setuptools"
	pip3install "QScintilla PyQtChart gps3 dronekit manuf python-dateutil numpy matplotlib"
	pip3install --upgrade manuf
}

function krackattacks_script_soft_install () {
	[ -d /rftools/wifi ] || mkdir -p /rftools/wifi
	cd /rftools/wifi
	install_dependencies "libnl-3-dev libnl-genl-3-dev pkg-config libssl-dev net-tools git sysfsutils python3-venv iw"
	goodecho "[+] Cloning and installing krackattacks-scripts"
	gitinstall "https://github.com/vanhoefm/krackattacks-scripts.git" "krackattacks-scripts.git"
	cd krackattacks-scripts/krackattack
	./build.sh
	./pysetup.sh
}

## Other softs

function whad_soft_install () {
	goodecho "[+] Installing WHAD from PIP"
	pip3install "whad"
}

function artemis_soft_install () {
    # Check system architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" && "$ARCH" != "amd64" && "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
        echo "[-] Unsupported architecture: $ARCH"
        exit 0
    fi

    goodecho "[+] Installing Artemis"
    [ -d /rftools/docs ] || mkdir -p /rftools/docs
    cd /rftools/docs
    gitinstall "https://github.com/AresValley/Artemis.git" "artemis_soft_install"
    cd Artemis
    pip3install -r requirements.txt
    sed -i '1s|^|#!/bin/env python3\n|' app.py
    chmod +x app.py
    ln -s $(pwd)/app.py /usr/sbin/Artemis
}
