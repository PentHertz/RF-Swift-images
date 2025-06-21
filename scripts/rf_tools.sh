#!/bin/bash

# Bluetooth Classic and LE
function blueztools_soft_install() {
	goodecho "[+] Installing bluez tools"
	install_dependencies "bluez bluez-tools bluez-hcidump bluez-btsco bluez-obexd libbluetooth-dev"
}

function mirage_soft_install() {
    goodecho "[+] Installing mirage dependencies"
    echo apt-fast keyboard-configuration/variant string "English (US)" | debconf-set-selections
    echo apt-fast keyboard-configuration/layout string "English (US)" | debconf-set-selections
    echo apt-fast console-setup/codeset47 string "Guess optimal character set" | debconf-set-selections
    echo apt-fast console-setup/charmap47 string "UTF-8" | debconf-set-selections
    install_dependencies "libpcsclite-dev pcsc-tools kmod kbd python3-pip python3-build"
    pip3install "keyboard"
    pip3install "pycryptodomex"
    goodecho "[+] Installing Mirage"
    [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    cd /root/thirdparty
    python3.10 -m venv /opt/mirage-env
    source /opt/mirage-env/bin/activate
    installfromnet "git clone https://github.com/RCayre/mirage"
    cd mirage/
    pip install .
    pip install scapy==2.5.0
    deactivate
    
    goodecho "[+] Creating mirage wrapper script"
    cat > /usr/sbin/mirage << 'EOF'
#!/bin/bash

# Mirage wrapper script
# This script activates the mirage virtual environment, runs mirage with all passed arguments,
# then deactivates the environment when finished

# Check if the virtual environment exists
if [ ! -d "/opt/mirage-env" ]; then
    echo "Error: Mirage virtual environment not found at /opt/mirage-env"
    echo "Please run the mirage installation script first."
    exit 1
fi

# Activate the virtual environment
source /opt/mirage-env/bin/activate

# Check if mirage is installed and run it with all passed arguments
if [ -f "/opt/mirage-env/bin/mirage" ]; then
    # Try direct executable first
    /opt/mirage-env/bin/mirage "$@"
    exit_code=$?
elif command -v mirage >/dev/null 2>&1; then
    # Try mirage command (should be available after activating venv)
    mirage "$@"
    exit_code=$?
else
    # Fall back to running as Python module
    /opt/mirage-env/bin/python -m mirage "$@"
    exit_code=$?
fi

# Deactivate the virtual environment
deactivate

# Exit with the same code as mirage
exit $exit_code
EOF

    # Make the wrapper script executable
    chmod +x /usr/sbin/mirage
    
    goodecho "[+] Mirage installation completed successfully"
    goodecho "[+] You can now run 'mirage' from anywhere on the system"
}

function sniffle_soft_install() {
    # Get current architecture
    local arch=$(uname -m)
    
    # Only proceed if architecture is x86_64, amd64, arm64, or aarch64
    if [[ "$arch" == "x86_64" ]] || [[ "$arch" == "amd64" ]] || [[ "$arch" == "arm64" ]] || [[ "$arch" == "aarch64" ]]; then
        goodecho "[+] Installing Sniffle with OpenDroneID decoder/encoder"
        [ -d /rftools/bluetooth ] || mkdir -p /rftools/bluetooth
        cd /rftools/bluetooth
        install_dependencies "gfortran"
        installfromnet "git clone https://github.com/bkerler/Sniffle.git"
        cd Sniffle/python_cli
        pip3install -r requirements.txt
        pip3install "numpy<2"
    else
        goodecho "[!] Skipping Sniffle installation: unsupported architecture ($arch)"
    fi
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
        install_dependencies "python3.10 python3.10-venv python3.10-dev"
    fi

    install_dependencies "libgirepository1.0-dev libgirepository-2.0-dev libbluetooth-dev"

     [ -d /rftools/bluetooth/bluing ] || mkdir -p /rftools/bluetooth/bluing
    cd /rftools/bluetooth/bluing
    python3.10 -m venv bluing
    source bluing/bin/activate
    python3.10 -m pip install dbus-python==1.2.18
    python3.10 -m pip install --no-dependencies bluing PyGObject docopt btsm btatt bluepy configobj btl2cap pkginfo xpycommon halo pyserial bthci btgatt log_symbols colorama spinners six termcolor
   
    # Define the name of the script to create
	SCRIPT_FILE="bluing_run"

	# Create the script with execution permissions
	cat > $SCRIPT_FILE << 'EOF'
#!/bin/bash

# Activate the bluing environment
/rftools/bluetooth/bluing/bluing/bin/activate

# Print a message to confirm activation
echo "Bluing environment has been activated inside a Python environment"
EOF

	# Make the script executable
	chmod +x $SCRIPT_FILE

	echo "Created $SCRIPT_FILE with execution permissions"
	echo "You can run it with: ./$SCRIPT_FILE"
}


function bdaddr_soft_install() {
	goodecho "[+] Installing bdaddr"
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
	ln -s $(pwd)/pm3 /usr/sbin/pm3
	ln -s $(pwd)/proxmark3 /usr/bin/proxmark3
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

function Pyrit_soft_install() { #TODO: tofix for total Python3 support
	goodecho "[+] Installing Pyrit"
	[ -d /rftools/wifi ] || mkdir -p /rftools/wifi
	cd /rftools/wifi
	pip3install "psycopg2-binary"
	install_dependencies "scapy"
	gitinstall "https://github.com/JPaulMora/Pyrit.git" "Pyrit_soft_install"
	cd Pyrit
	pip3install .
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
	install_dependencies " pyqt5chart-dev python3-pip gpsd gpsd-clients python3-tk python3-setuptools qt5-qmake qtbase5-dev python3-pyqt5 python3-pyqt5.qsci python3-pyqt5.qtsvg python3-sip-dev pyqt5-dev pyqt5-dev-tools"
	pip3install "gps3 dronekit manuf python-dateutil matplotlib"
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

function rfquak_soft_install () { # TODO: Fix on Ubuntu Noble
	goodecho "[+] Installing RFQuack from PIP"
	[ -d /rftools ] || mkdir -p /rftools
	cd /rftools
	git clone --recursive https://github.com/rfquack/RFQuack
	cd RFQuack
	pip3install -r requirements.pip
	make clean build
}

function artemis_soft_install () {
    # Check system architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" && "$ARCH" != "amd64" && "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
        echo "[-] Unsupported architecture: $ARCH"
        exit 0
    fi

    install_dependencies "libxcb-cursor-dev"

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
