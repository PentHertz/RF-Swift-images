#!/bin/bash

# Bluetooth Classic and LE
function esp32_bluetooth_classic_sniffer_soft_install () {
	goodecho "[+] Installing esp32_bluetooth_classic_sniffer"
	[ -d /rftools/bluetooth ] || mkdir -p /rftools/bluetooth
    cd /rftools/bluetooth
    gitinstall "https://github.com/FlUxIuS/esp32_bluetooth_classic_sniffer.git" "esp32_bluetooth_classic_sniffer_soft_install"
    cd esp32_bluetooth_classic_sniffer
    ./requirements.sh
    ./build.sh
    ln -s $(pwd)/BTSnifferBREDR.py /usr/sbin/BTSnifferBREDR
}

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
    [ -d /rftools/bluetooth/firmwares ] || mkdir -p /rftools/bluetooth/firmwares
    cd /rftools/bluetooth/firmwares
    goodecho "[+] Downloading firmwares for Mirage"
    mkdir Btlejack_microbit_ble400
    cd Btlejack_microbit_ble400
    installfromnet "wget https://github.com/virtualabs/btlejack/archive/refs/tags/v2.1.1.zip"
    cd ..
    mkdir Injectable_NRF52840
    cd Injectable_NRF52840
    installfromnet "wget https://github.com/RCayre/injectable-firmware/releases/download/v1.0/pca10059.hex"
    installfromnet "wget https://github.com/RCayre/injectable-firmware/releases/download/v1.0/mdk-dongle.hex"
    cd ..
    mkdir NRFSniffer
    cd NRFSniffer
    installfromnet "wget https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/desktop-software/nrf-sniffer/sw/nrf_sniffer_for_bluetooth_le_4.1.1.zip"
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
        
        pip3 uninstall numpy -y --break-system-packages
        pip3install "numpy<2.0"
        [ -d /rftools/bluetooth/firmwares/Sniffle ] || mkdir -p /rftools/bluetooth/firmwares/Sniffle
        cd /rftools/bluetooth/firmwares/Sniffle
        goodecho "[+] Downloading firmwares for Sniffle"
        installfromnet "wget https://github.com/nccgroup/Sniffle/releases/download/v1.10.0/sniffle_cc1352p1_cc2652p1.hex"
        installfromnet "wget https://github.com/nccgroup/Sniffle/releases/download/v1.10.0/sniffle_cc1352p1_cc2652p1_1M.hex"
        installfromnet "wget https://github.com/nccgroup/Sniffle/releases/download/v1.10.0/sniffle_cc1352p7.hex"
        installfromnet "wget https://github.com/nccgroup/Sniffle/releases/download/v1.10.0/sniffle_cc1352p7_1M.hex"
        installfromnet "wget https://github.com/nccgroup/Sniffle/releases/download/v1.10.0/sniffle_cc1352r1.hex"
        installfromnet "wget https://github.com/nccgroup/Sniffle/releases/download/v1.10.0/sniffle_cc1354p10.hex"
        installfromnet "wget https://github.com/nccgroup/Sniffle/releases/download/v1.10.0/sniffle_cc2651p3.hex"
        installfromnet "wget https://github.com/nccgroup/Sniffle/releases/download/v1.10.0/sniffle_cc2652r1.hex"
        installfromnet "wget https://github.com/nccgroup/Sniffle/releases/download/v1.10.0/sniffle_cc2652r7.hex"
        installfromnet "wget https://github.com/nccgroup/Sniffle/releases/download/v1.10.0/sniffle_cc2652rb.hex"
        installfromnet "wget https://github.com/nccgroup/Sniffle/releases/download/v1.10.0/sniffle_cc2652rb_1M.hex"
    else
        goodecho "[!] Skipping Sniffle installation: unsupported architecture ($arch)"
    fi
}

function bluing_soft_install() {
    echo "[+] Installing bluing"
    
    install_dependencies "software-properties-common libgirepository1.0-dev libgirepository-2.0-dev libcairo2-dev libdbus-1-dev libbluetooth-dev pkg-config python3-dev"
    
    if [ "$(uname -m)" = "riscv64" ]; then
        [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
        cd /root/thirdparty
        sudo apt-get update
        install_dependencies "build-essential libssl-dev zlib1g-dev libncurses-dev libreadline-dev libsqlite3-dev libgdbm-dev libdb5.3-dev libbz2-dev libexpat1-dev liblzma-dev libffi-dev"
        wget https://www.python.org/ftp/python/3.10.13/Python-3.10.13.tgz
        tar xzf Python-3.10.13.tgz
        cd Python-3.10.13
        export LDFLAGS="-lm -lpthread -ldl -lutil" # TODO: for RISC-V but need to check if good for ARM and x86
        ./configure --enable-optimizations
        make -j $(nproc)
        sudo make altinstall
        cd ..
        rm -rf Python-3.10.13*
    else
        add-apt-repository -y ppa:deadsnakes/ppa
        sudo apt-get update
        install_dependencies "python3.10 python3.10-venv python3.10-dev"
    fi
    
    [ -d /rftools/bluetooth/bluing ] || mkdir -p /rftools/bluetooth/bluing
    cd /rftools/bluetooth/bluing
    python3.10 -m venv bluing
    source bluing/bin/activate
    
    pip install --upgrade pip
    
    # Install ALL quarantined dependencies with --no-deps first (they depend on each other)
    echo "[+] Installing quarantined dependencies from direct URLs..."
    pip install --no-deps https://files.pythonhosted.org/packages/80/47/a9e2dfc8acb8a134fed62b0ef28282229728c99f63ae957b4bad20b907a7/xpycommon-0.0.25-py3-none-any.whl
    pip install --no-deps https://files.pythonhosted.org/packages/c5/6b/ecc4a62772fd2af49b0c5245b0beef9fe7b01f1ea642c2a69c859783ace1/bthci-0.0.44-py3-none-any.whl
    pip install --no-deps https://files.pythonhosted.org/packages/e0/b8/4339dfd7b98360510f0efb1d8f1b475a4e289f1f4a3e7ffd50ddeb0bd030/btl2cap-0.0.11-py3-none-any.whl
    pip install --no-deps https://files.pythonhosted.org/packages/8d/38/77e3f4f3eae7cb5950d0993a5ead81993f86e45b97691177df44b4586056/btatt-0.0.19-py3-none-any.whl
    pip install --no-deps https://files.pythonhosted.org/packages/bd/19/a8f9bd80e40654bf5f170a60cc98e00a64bfc3f8d3fc40804a23a50b7651/btgatt-0.0.22-py3-none-any.whl
    pip install --no-deps https://files.pythonhosted.org/packages/3a/3d/2467113e463f903cf9fe12f621744c1fab634d9f95e654fa3ad05c793281/btsm-0.0.16-py3-none-any.whl
    
    # Now install their non-quarantined dependencies
    echo "[+] Installing remaining dependencies..."
    pip install configobj ntplib pkginfo dbus-python PyGObject
    
    # Install bluing from GitHub (quarantined deps already satisfied)
    pip install --no-deps git+https://github.com/fO-000/bluing.git
    
    # Install bluing's other dependencies
    pip install docopt bluepy halo pyserial
    
    deactivate
    
    # Create wrapper script to run bluing directly
    cat > /usr/local/bin/bluing << 'EOF'
#!/bin/bash
source /rftools/bluetooth/bluing/bluing/bin/activate
exec bluing "$@"
EOF
    chmod +x /usr/local/bin/bluing
    
    echo "[+] Bluing installed - run 'bluing' directly"
}

function bdaddr_soft_install() {
	goodecho "[+] Installing bdaddr"
	[ -d /rftools/bluetooth ] || mkdir /rftools/bluetooth
	cd /rftools/bluetooth
	installfromnet "git clone https://github.com/thxomas/bdaddr"
	cd bdaddr
	make
	ln -s $(pwd)/bdaddr /usr/bin/bdaddr
}

function bluekit_soft_install() {
	goodecho "[+] Installing BlueKit"
	[ -d /rftools/bluetooth ] || mkdir /rftools/bluetooth
	cd /rftools/bluetooth
	installfromnet "git clone https://github.com/sgxgsx/BlueToolkit.git"
	cd BlueToolkit
	chmod +x ./install.sh
	./install.sh
}

### Bluetooth Exploits
function CVE_2025_36911_whisperpair_install() {
    goodecho "[+] Installing WhisperPair cli"
    [ -d /rftools/bluetooth/exploits ] || mkdir /rftools/bluetooth/exploits
    cd /rftools/bluetooth/exploits
    gitinstall "https://github.com/PentHertz/CVE-2025-36911-exploit.git" "CVE_2025_36911_whisperpair_install"
    cd CVE-2025-36911-exploit
    pip3install bleak cryptography
}

function race_toolkit_exploit_install() {
    goodecho "[+] Installing race-toolkit for CVE-2025-20700, CVE-2025-20701, and CVE-2025-20702"
    [ -d /rftools/bluetooth/exploits ] || mkdir /rftools/bluetooth/exploits
    cd /rftools/bluetooth/exploits
    gitinstall "https://github.com/auracast-research/race-toolkit.git" "race_toolkit_exploit_install"
    cd race-toolkit
    pip3install -r requirements.txt
}

function pybluez_soft_install() {
    goodecho "[+] Installing pybluez "
    [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    cd /root/thirdparty
    install_dependencies "bluez-tools bluez-hcidump libbluetooth-dev git gcc python3-pip python3-setuptools python3-pydbus"
    gitinstall "https://github.com/pybluez/pybluez.git" "pybluez_soft_install"
    cd pybluez
    pip3install .
}

function blueducky_soft_install() {
    goodecho "[+] Installing BlueDucky"
    [ -d /rftools/bluetooth/exploits ] || mkdir -p /rftools/bluetooth/exploits
    cd /rftools/bluetooth/exploits
    gitinstall "https://github.com/pentestfunctions/BlueDucky.git" "blueducky_soft_install"
    cd BlueDucky
    python3 -m venv venv
    source venv/bin/activate
    sed -i '/PyBluez/d' requirements.txt
    sed -i '/pybluez/d' requirements.txt
    sed -i '/pyobjc/d' requirements.txt
    sed -i '/setuptools/d' requirements.txt
    pip3 install -r requirements.txt
    deactivate
    cat << 'EOF' > /usr/sbin/BlueDucky
#!/bin/bash
cd /rftools/bluetooth/exploits/BlueDucky
source venv/bin/activate
python3 BlueDucky.py "$@"
EOF
    chmod +x /usr/sbin/BlueDucky
}

function breaktooth_soft_install() {
    goodecho "[+] Installing Breaktooth"
    [ -d /rftools/bluetooth/exploits ] || mkdir /rftools/bluetooth/exploits
    cd /rftools/bluetooth/exploits
    gitinstall "https://github.com/FlUxIuS/breaktooth-unofficial.git" "breaktooth_soft_install"
}


function blerp_soft_install() {
    goodecho "[+] Installing BLERP - BLE Re-Pairing Attacks PoC (NDSS 26')"
    install_dependencies "tio bluez"
    [ -d /rftools/bluetooth/exploits ] || mkdir -p /rftools/bluetooth/exploits
    cd /rftools/bluetooth/exploits
    gitinstall "https://github.com/FlUxIuS/blerp.git" "blerp_soft_install"
    cd blerp
    # Download pre-built firmware from release
    local BLERP_VER="v1.0.0"
    local RELEASE_URL="https://github.com/FlUxIuS/blerp/releases/download/${BLERP_VER}"
    mkdir -p firmware
    goodecho "[+] Downloading pre-built firmware ${BLERP_VER}"
    for f in bleshell-${BLERP_VER}.elf bleshell-${BLERP_VER}.hex bleshell-${BLERP_VER}.img \
             blehci-${BLERP_VER}.elf blehci-${BLERP_VER}.hex blehci-${BLERP_VER}.img; do
        installfromnet "wget -q -O firmware/$f ${RELEASE_URL}/$f"
    done
    goodecho "[+] Firmware downloaded to $(pwd)/firmware/"
    # Python venv to avoid conflicts with system Scapy (BLERP uses a custom Scapy fork)
    goodecho "[+] Creating isolated Python venv for BLERP"
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip setuptools wheel
    pip install -r python-host/requirements.txt
    deactivate
    # Convenience wrapper for MitM attack
    cat > /usr/local/bin/blerp-mitm <<'EOF'
#!/bin/bash
BLERP_DIR="/rftools/bluetooth/exploits/blerp"
exec "${BLERP_DIR}/.venv/bin/python" "${BLERP_DIR}/python-host/mitm.py" "$@"
EOF
    chmod +x /usr/local/bin/blerp-mitm
    goodecho "[+] BLERP installed:"
    goodecho "    Firmware: $(pwd)/firmware/"
    goodecho "    Flash:    nrfjprog --program firmware/bleshell-${BLERP_VER}.hex --sectorerase --snr <SERIAL>"
    goodecho "    MitM:     sudo blerp-mitm --help"
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

function libfreeware_soft_install() {
    goodecho "[+] Installing libfreeware"
    install_dependencies "libfreefare-bin libfreefare-dev"
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
	#[ -f craptev1-v1.1.tar.xz ] || installfromnet "wget https://web.archive.org/web/20190221140220if_/https://www2.vaneay.fr/mifare/craptev1-v1.1.tar.xz"
	#[ -f crapto1-v3.3.tar.xz ] || installfromnet "wget https://web.archive.org/web/20190221140255if_/https://www2.vaneay.fr/mifare/crapto1-v3.3.tar.xz"
	[ -f crapto1-v3.3.tar.xz ] || installfromnet "wget https://github.com/PentHertz/rfid-proj/releases/download/v0/crapto1-v3.3.tar.xz"
	[ -f craptev1-v1.1.tar.xz ] || installfromnet "wget https://github.com/PentHertz/rfid-proj/releases/download/v0/craptev1-v1.1.tar.xz"
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

function nfcpy_soft_install() {
    goodecho "[+] Installing nfcpy"
    pip3install nfcpy
}

function chameleon_ultra_soft_install() {
    goodecho "[+] Installing ChameleonUltra CLI"
    [ -d /rftools/nfc ] || mkdir -p /rftools/nfc
    cd /rftools/nfc
    gitinstall "https://github.com/RfidResearchGroup/ChameleonUltra.git" "chameleon_ultra_soft_install"
    cd ChameleonUltra/software
    uv sync
    cd src
    mkdir -p build && cd build
    cmake ..
    make
    make install
    cd /rftools/nfc/ChameleonUltra/software
    cat << 'EOF' > /usr/sbin/chameleon_cli
#!/bin/bash
cd /rftools/nfc/ChameleonUltra/software/script
uv run chameleon_cli_main.py "$@"
EOF
    chmod +x /usr/sbin/chameleon_cli
}

function chameleon_ultra_soft_install() {
    goodecho "[+] Installing ChameleonUltra"
    pip3install nfcpy
}


# Wi-Fi Package
function common_nettools() {
	install_dependencies "iproute2 hostapd dnsmasq"
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

function wifipumpkin3_soft_install() {
	goodecho "[+] Installing wifipumpkin3"
	[ -d /rftools/wifi ] || mkdir -p /rftools/wifi
	cd /rftools/wifi
	install_dependencies "python3-dev libssl-dev libffi-dev build-essential python3"
	gitinstall "https://github.com/P0cL4bs/wifipumpkin3.git" "wifipumpkin3_soft_install"
	cd wifipumpkin3
	pipx install .
	ln -s /usr/local/bin/captiveflask /usr/sbin/captiveflask
	ln -s /usr/local/bin/evilqr3 /usr/sbin/evilqr3
	ln -s /usr/local/bin/phishkin3 /usr/sbin/phishkin3
	ln -s /usr/local/bin/sslstrip3 /usr/sbin/sslstrip3
	ln -s /usr/local/bin/wifipumpkin3 /usr/sbin/wifipumpkin3
}

function pixiewps_soft_install() {
	goodecho "[+] Installing pixiewps"
	install_dependencies "pixiewps"
}

function hcxdumptool_soft_install() {
	goodecho "[+] Installing hcxdumptool"
	install_dependencies "hcxdumptool"
}

function hcxdumptool_soft_install() {
	goodecho "[+] Installing hcxdumptool"
	install_dependencies "hcxdumptool"
}

function hcxtools_soft_install() {
	goodecho "[+] Installing hcxtools"
	[ -d /rftools/wifi ] || mkdir -p /rftools/wifi
	cd /rftools/wifi
	gitinstall "https://github.com/ZerBea/hcxtools.git" "hcxtools_soft_install"
	cd hcxtools
	make -j$(nproc)
	make install
	ln -s /usr/bin/hcxpcapngtool /usr/bin/hcxpcaptool
}

function mdk3_soft_install() {
	goodecho "[+] Installing mdk3"
	install_dependencies "mdk3"
}

function wpa3_dragonslayer_soft_install() {
	goodecho "[+] Installing dragonslayer"
	[ -d /rftools/wifi/wpa3 ] || mkdir -p /rftools/wifi/wpa3
	cd /rftools/wifi/wpa3
	install_dependencies "libnl-3-dev libnl-genl-3-dev pkg-config libssl-dev net-tools git libdbus-1-dev"
	gitinstall "https://github.com/vanhoefm/dragonslayer.git" "wpa3_dragonslayer_soft_install"
	cd dragonslayer
	cd dragonslayer
	./build.sh
}

function wpa3_dragonforce_soft_install() {
	goodecho "[+] Installing dragonforce"
	[ -d /rftools/wifi/wpa3 ] || mkdir -p /rftools/wifi/wpa3
	cd /rftools/wifi/wpa3
	gitinstall "https://github.com/FlUxIuS/dragonforce.git" "wpa3_dragonforce_soft_install"
	cd dragonforce
	./build.sh
}

function wpa3_dragondrain_and_time_soft_install() {
	goodecho "[+] Installing dragondrain-and-time"
	[ -d /rftools/wifi/wpa3 ] || mkdir -p /rftools/wifi/wpa3
	cd /rftools/wifi/wpa3
	install_dependencies "autoconf automake libtool shtool libssl-dev pkg-config"
	gitinstall "https://github.com/vanhoefm/dragondrain-and-time.git" "wpa3_dragondrain_and_time_soft_install"
	cd dragondrain-and-time
	autoreconf -i
	CFLAGS="$CFLAGS -fcommon" ./configure
	make -j$(nproc)
}

function wpa3_wacker_soft_install() {
	goodecho "[+] Installing Wacker WPA3"
	[ -d /rftools/wifi/wpa3 ] || mkdir -p /rftools/wifi/wpa3
	cd /rftools/wifi/wpa3
	gitinstall "https://github.com/blunderbuss-wctf/wacker.git" "wpa3_wacker_soft_install"
	cd wacker
	install_dependencies "pkg-config libnl-3-dev gcc libssl-dev libnl-genl-3-dev"
	cp defconfig wpa_supplicant-2.10/wpa_supplicant/.config
	git apply wpa_supplicant.patch
	cd wpa_supplicant-2.10/wpa_supplicant
	make -j$(nproc)
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
	gitinstall "https://github.com/s0lst1c3/eaphammer.git" "eaphammer_soft_install"
	cd eaphammer/
	./ubuntu-unattended-setup
	pip3install -r pip.req
}

function airgeddon_soft_install() { # TODO: still hostapd-wpe missing
	goodecho "[+] Installing airgeddon"
	[ -d /rftools/wifi ] || mkdir -p /rftools/wifi
	cd /rftools/wifi
	gitinstall "https://github.com/v1s1t0r1sh3r3/airgeddon.git" "airgeddon_soft_install"
	cd airgeddon/
	install_dependencies "crunch mdk4 isc-dhcp-server hostapd lighttpd hashcat ettercap-text-only john"
	goodecho "[+] Installing pluggins for airgeddon"
	# Create a wrapper script
	cat > /usr/local/sbin/airgeddon << 'EOF'
#!/bin/bash
cd /rftools/wifi/airgeddon
exec ./airgeddon.sh "$@"
EOF
	gitinstall "https://github.com/OscarAkaElvis/airgeddon-plugins.git" "airgeddon_soft_install"
	cp -R airgeddon-plugins/wpa3_online_attack/* plugins/
	cp -R airgeddon-plugins/allchars_captiveportal/* plugins/
	cp -R airgeddon-plugins/realtek_chipset_fixer/* plugins/
}

function wifite2_soft_install () {
	goodecho "[+] Installing wifite2"
	[ -d /rftools/wifi ] || mkdir -p /rftools/wifi
	cd /rftools/wifi
	installfromnet "git clone https://github.com/derv82/wifite2.git"
	cd wifite2/
	pipx install .
	pipx ensurepath
}

function roguehostapd_soft_install () {
	goodecho "[+] Installing roguehostapd"
	[ -d /rftools/wifi ] || mkdir -p /rftools/wifi
	cd /rftools/wifi
	gitinstall "https://github.com/FlUxIuS/roguehostapd.git" "roguehostapd_soft_install"
	cd roguehostapd
	python3 setup.py install
}

function wifiphisher_soft_install () {
	goodecho "[+] Installing wifiphisher"
	[ -d /rftools/wifi ] || mkdir -p /rftools/wifi
	cd /rftools/wifi
	gitinstall "https://github.com/wifiphisher/wifiphisher.git" "wifiphisher_soft_install"
	cd wifiphisher
	python3 setup.py install
	pip3install "pyric tornado"
}

function hostapdmana_soft_install () {
	goodecho "[+] Installing hostapd-mana"
	install_dependencies "build-essential git libnl-genl-3-dev libssl-dev"
	[ -d /rftools/wifi ] || mkdir -p /rftools/wifi
	cd /rftools/wifi
	gitinstall "https://github.com/FlUxIuS/hostapd-mana.git" "hostapdmana_soft_install"
	cd hostapd-mana
	make -C hostapd
	ln -s $(pwd)/hostapd/hostapd /usr/local/bin/hostapd-mana
}

function sparrowwifi_sdr_soft_install () { # TODO: to debug
	[ -d /rftools/wifi ] || mkdir -p /rftools/wifi
	cd /rftools/wifi
	goodecho "[+] Cloning and installing sparrow-wifi"
	gitinstall "https://github.com/ghostop14/sparrow-wifi.git" "sparrowwifi"
	cd sparrow-wifi
	install_dependencies "pyqt5chart-dev python3-pip gpsd gpsd-clients python3-tk python3-setuptools qt5-qmake qtbase5-dev python3-pyqt5 python3-pyqt5.qsci python3-pyqt5.qtsvg python3-sip-dev pyqt5-dev pyqt5-dev-tools"
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

function fernwificracker_soft_install() {
	goodecho "[+] Installing Fern WiFi Cracker"
	install_dependencies "aircrack-ng"
	gitinstall "https://github.com/savio-code/fern-wifi-cracker.git" "fernwificracker_soft_install"
	cd fern-wifi-cracker
	cd Fern-Wifi-Cracker
	
	# Create wrapper script
	cat > /usr/sbin/Fern-Wifi-Cracker << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FERN_DIR="/root/thirdparty/fern-wifi-cracker/Fern-Wifi-Cracker"

# Change to the Fern directory and execute
cd "$FERN_DIR"
exec python3 execute.py "$@"
EOF
	
	# Make wrapper executable
	chmod +x /usr/sbin/Fern-Wifi-Cracker
	goodecho "[+] Fern WiFi Cracker wrapper installed"
}

function airgorah_soft_install() {
    goodecho "[+] Installing airgorah"
    [ -d /rftools/wifi ] || mkdir -p /rftools/wifi
    cd /rftools/wifi
    install_dependencies "libgtk-4-1 dbus-x11 wireshark-common iproute2 mdk4 crunch"
    install_dependencies "dbus build-essential libgtk-4-dev libglib2.0-dev macchanger"
    gitinstall "https://github.com/martin-olivier/airgorah.git" "airgorah_soft_install ruby ruby-dev rubygems rpm zstd libarchive-tools"
    gem install fpm
    if ! command -v rustup &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        . "/root/.cargo/env"
    fi
    rustup component add clippy
    rustup component add rustfmt
    cd airgorah
    cargo install airgorah
}

## Other softs

function whad_soft_install () {
	goodecho "[+] Installing WHAD from PIP"
	pipx install "whad"
    pipx ensurepath
}

function rfquak_soft_install () {
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

function airsnitch_soft_install() {
    goodecho "[+] Installing AirSnitch"
    [ -d /rftools/wifi ] || mkdir -p /rftools/wifi
    cd /rftools/wifi
    install_dependencies "libnl-3-dev libnl-genl-3-dev libnl-route-3-dev libssl-dev libdbus-1-dev pkg-config build-essential net-tools python3-venv aircrack-ng rfkill git dnsmasq tcpreplay macchanger"
    gitinstall "https://github.com/vanhoefm/airsnitch.git" "airsnitch_soft_install"
    cd airsnitch
    # Compile modified hostap
    bash setup.sh
    cd airsnitch/research
    bash build.sh
    bash pysetup.sh
    goodecho "[+] AirSnitch installed. Use 'airsnitch' wrapper to run."
}