#!/bin/bash

function dsview_install() {
    goodecho "[+] Installing DSView"
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  DEB_ARCH="amd64" ;;
        aarch64) DEB_ARCH="arm64" ;;
        riscv64) DEB_ARCH="riscv64" ;;
        *)
            criticalecho-noexit "[-] DSView: unsupported architecture $ARCH, skipping"
            return 0
            ;;
    esac
    DSVIEW_VERSION="1.3.2"
    DEB_NAME="dsview_${DSVIEW_VERSION}-1_${DEB_ARCH}.deb"
    DEB_URL="https://github.com/PentHertz/DSView/releases/download/v${DSVIEW_VERSION}/${DEB_NAME}"
    [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    cd /root/thirdparty
    installfromnet "wget ${DEB_URL}"
    dpkg -i "${DEB_NAME}" || apt-get install -f -y
    rm -f "${DEB_NAME}"
}

function dsview_install_fromsources() {
    goodecho "[+] Installing DSView for DSLogic"
    install_dependencies "libfftw3-dev"
    ldconfig
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    installfromnet "git clone https://github.com/DreamSourceLab/DSView.git"
    cd DSView
    mkdir build
    cd build
    cmake ..
    make -j$(nproc)
    make install
}

function avrdude_install() {
	goodecho "[+] Installing AVRDude"
	install_dependencies "avrdude avrdude-doc"
}

function dfu_util_install() {
    goodecho "[+] Installing dfu-util"
    install_dependencies "dfu-util"
}

function flashrom_install() {
    goodecho "[+] Installing flashrom"
    install_dependencies "meson pciutils usbutils libpci-dev libusb-dev libftdi1 libftdi-dev zlib1g-dev subversion libusb-1.0-0-dev"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    installfromnet "git clone https://github.com/flashrom/flashrom.git"
    cd flashrom
    meson setup builddir
    meson compile -C builddir
    meson install -C builddir
}

function pulseview_install_fromsources() {
    goodecho "[+] Installing Sigrok pulseview"
    install_dependencies "sdcc libzip-dev libglibmm-2.4-dev libieee1284-3-dev libnettle8"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    git clone https://github.com/FlUxIuS/sigrok-util.git
    cd sigrok-util/cross-compile/linux
    
    # Patch to skip libsigrokdecode tests on ARM64 (known issue)
    if [ "$(uname -m)" = "aarch64" ]; then
        goodecho "[*] Patching libsigrokdecode build for ARM64"
        # Find and replace the make check line specifically in the libsigrokdecode section
        sed -i '/libsigrokdecode/,/^[[:space:]]*$/s/make check/make check || true/' sigrok-cross-linux
    fi
    
    ./sigrok-cross-linux
}

function pulseview_install() {
    goodecho "[+] Installing PulseView (sigrok stack)"
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  DEB_ARCH="amd64" ;;
        aarch64) DEB_ARCH="arm64" ;;
        riscv64) DEB_ARCH="riscv64" ;;
        *)
            criticalecho-noexit "[-] PulseView: unsupported architecture $ARCH, skipping"
            return 0
            ;;
    esac
    PULSEVIEW_VERSION="0.4.2"
    DEB_NAME="sigrok-pulseview_${PULSEVIEW_VERSION}-1_${DEB_ARCH}.deb"
    DEB_URL="https://github.com/PentHertz/pulseview/releases/download/v${PULSEVIEW_VERSION}/${DEB_NAME}"
    [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    cd /root/thirdparty
    installfromnet "wget ${DEB_URL}"
    dpkg -i "${DEB_NAME}" || apt-get install -f -y
    udevadm control --reload-rules && udevadm trigger
    rm -f "${DEB_NAME}"
}

function openocd_install() {
    goodecho "[+] Installing Sigrok OpenOCD"
    install_dependencies "libjaylink-dev libgpiod-dev libhidapi-dev libjim-dev"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    git clone https://github.com/openocd-org/openocd.git
    cd openocd
    ./bootstrap
    ./configure \
      --enable-maintainer-mode \
      --enable-parport \
      --enable-parport-ppdev \
      --enable-parport-giveio \
      --enable-jtag_vpi \
      --enable-usb_blaster_libftdi \
      --enable-amtjtagaccel \
      --enable-ft2232_libftdi \
      --enable-ft2232_ftd2xx \
      --enable-ftdi \
      --enable-stlink \
      --enable-ti-icdi \
      --enable-ulink \
      --enable-osbdm \
      --enable-opendous \
      --enable-aice \
      --enable-usbprog \
      --enable-rlink \
      --enable-armjtagew \
      --enable-cmsis-dap \
      --enable-cmsis-dap-v2 \
      --enable-kitprog \
      --enable-usb-blaster-2 \
      --enable-presto_libftdi \
      --enable-openjtag_ftdi \
      --enable-jlink \
      --enable-buspirate \
      --enable-remote-bitbang \
      --enable-sysfsgpio \
      --enable-bcm2835gpio \
      --enable-imx_gpio \
      --enable-esp-usb-jtag \
      --enable-xlnx-pcie-xvc \
      --enable-linuxgpiod \
      --enable-dmem-adv \
      --enable-boundary-scan \
      --disable-werror
    make -j$(nproc)
    make install
}

function dsl2sigrok_install() {
    goodecho "[+] Installing dsl2sigrok"
    install_dependencies "libzip-dev"
    [ -d /hardware ] || mkdir /hardware
    cd /hardware
    git clone https://github.com/FlUxIuS/dsl2sigrok.git
    cd dsl2sigrok
    gcc -Wall -Wextra -Werror -O3 -o dsl2sigrok main.c zip_helper.c -lm -lzip
    ln -s "$(pwd)/dsl2sigrok" /usr/bin/dsl2sigrok
}

function hydranfc_trace_plugin_install() {
    goodecho "[+] Installing dsl2sigrok"
    [ -d /hardware ] || mkdir /hardware
    cd /hardware
    git clone https://github.com/hydrabus/hydranfc_v2_sniffer_decoder.git
    ln -s "$(pwd)/hydranfc_v2_sniffer_decoder" /usr/share/libsigrokdecode4DSL/decoders/ # installing for DSView
    ln -s "$(pwd)/hydranfc_v2_sniffer_decoder" /usr/share/libsigrokdecode/decoders/
}

function arduino_ide_install() {
    ARCH=$(uname -m)
    if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "amd64" ]; then
        criticalecho-noexit "[!] Error: This script only supports x86_64/amd64 architecture."
        criticalecho-noexit "[!] Current architecture: $ARCH"
        exit 0
    fi
    
    goodecho "[+] Installing Arduino IDE for x86_64 with AppImage"
    IDE_VERSION="2.3.10"
    avrdude_install
    [ -d /hardware ] || mkdir /hardware
    cd /hardware
    mkdir -p Arduino
    cd Arduino
    install_dependencies "openjdk-11-jre libfuse2 libnss3 libsecret-1-0"
    wget "https://downloads.arduino.cc/arduino-ide/arduino-ide_${IDE_VERSION}_Linux_64bit.AppImage"
    chmod +x "arduino-ide_${IDE_VERSION}_Linux_64bit.AppImage"
    
    # Create launcher script in /usr/sbin/
    goodecho "[+] Creating launcher script at /usr/sbin/arduino"
    cat > /usr/sbin/arduino << EOL
#!/bin/bash
/hardware/Arduino/arduino-ide_${IDE_VERSION}_Linux_64bit.AppImage --no-sandbox "\$@"
EOL
    chmod +x /usr/sbin/arduino
    goodecho "[+] Installation complete. You can now run Arduino IDE with 'arduino' command."
}

function logic2_saleae_install() {
    goodecho "[+] Installing Logic 2 for Saleae"
    ARCH=$(uname -m)
    if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "amd64" ]; then
        criticalecho-noexit "[!] Error: This script only supports x86_64/amd64 architecture."
        criticalecho-noexit "[!] Current architecture: $ARCH"
        exit 0
    fi
    LOGIC_VERSION="2.4.44"
    install_dependencies "libfftw3-dev"
    [ -d /hardware ] || mkdir /hardware
    cd /hardware
    mkdir -p Saleae
    cd Saleae
    
    # Download the AppImage
    wget "https://downloads2.saleae.com/logic2/Logic-${LOGIC_VERSION}-linux-x64.AppImage"
    chmod +x "Logic-${LOGIC_VERSION}-linux-x64.AppImage"
    
    # Extract the AppImage to avoid needing FUSE in containers
    goodecho "[+] Extracting AppImage (avoiding FUSE requirement)..."
    ./Logic-${LOGIC_VERSION}-linux-x64.AppImage --appimage-extract
    
    # Create symlink to the extracted Logic binary with --no-sandbox
    # This creates an alias that always runs with --no-sandbox
    cat > /usr/local/bin/Logic << 'EOF'
#!/bin/bash
exec /hardware/Saleae/squashfs-root/Logic --no-sandbox "$@"
EOF
    chmod +x /usr/local/bin/Logic
    
    # Also create the original symlink for compatibility
    ln -sf /hardware/Saleae/squashfs-root/Logic /usr/local/bin/Logic-2-Saleae
    
    # Optional: Create additional convenience aliases
    ln -sf /usr/local/bin/Logic /usr/local/bin/logic
    ln -sf /usr/local/bin/Logic /usr/local/bin/logic2
    
    goodecho "[+] Logic 2 installed successfully!"
    goodecho "[+] You can now run it with: Logic (or logic, logic2)"
    goodecho "[+] The --no-sandbox flag is automatically applied"
}

function seergdb_install() {
    goodecho "[+] Installing SeerGDB GUI"
    install_dependencies "libqt6opengl6-dev libqt6charts6-dev libqt6svg6-dev libqt6opengl6-dev libqt6charts6-dev libqt6svg6-dev"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    git clone https://github.com/epasveer/seer.git
    cd seer/src
    cd build
    cmake -DQTVERSION=QT6 ..
    make -j$(nproc) seergdb
    make install
    ln -s /usr/local/bin/seergdb /usr/bin/seergdb
}

function openFPGALoader_install() {
    goodecho "[+] Installing openFPGALoader"
    install_dependencies "libftdi1-dev"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    cmake_clone_and_build "https://github.com/trabucayre/openFPGALoader.git" "build" "" "" "openFPGALoader_install"
}

function mtkclient_install() {
    ARCH=$(uname -m)

    case "$ARCH" in
        x86_64|amd64)
            goodecho "[+] Architecture: x86_64"
            goodecho "[+] Installing mtkclient for x86_64"
            ;;
        aarch64|arm64)
            goodecho "[+] Architecture: aarch64"
            goodecho "[+] Installing mtkclient for aarch64"
            ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $ARCH"
            atuin_soft_fromsource_install
            exit 0
            ;;
    esac
    goodecho "[+] Installing mtkclient"
    install_dependencies "python3 git libusb-1.0-0 python3-pip libfuse2"
    [ -d /hardware ] || mkdir /hardware
    cd /hardware
    gitinstall "https://github.com/bkerler/mtkclient.git" "mtkclient_install"
    cd mtkclient
    pip3install -r requirements.txt
    pip3install .
}

function esptool_install() {
    goodecho "[+] Installing ESP tool"
    pipx install esptool
    ln -s /root/.local/bin/esp_rfc2217_server.py /usr/sbin/esp_rfc2217_server.py
    ln -s /root/.local/bin/espefuse.py /usr/sbin/espefuse.py
    ln -s /root/.local/bin/espsecure.py /usr/sbin/espsecure.py
    ln -s /root/.local/bin/esptool.py /usr/sbin/esptool.py
}

function ngscopeclient_install() {
    goodecho "[+] Installing ngscopeclient"
    [ -d /hardware ] || mkdir /hardware
    cd /hardware
    install_dependencies "build-essential git cmake pkgconf libgtk-3-dev libsigc++-2.0-dev libyaml-cpp-dev catch2 libglfw3-dev curl xzip libhidapi-dev"
    install_dependencies "libvulkan-dev glslang-dev glslang-tools spirv-tools glslc"
    install_dependencies "liblxi-dev libtirpc-dev"
    install_dependencies "texlive texlive-fonts-extra texlive-extra-utils"
    installfromnet "git clone --recursive https://github.com/ngscopeclient/scopehal-apps.git"
    cd scopehal-apps
    mkdir -p build
    cd build
    # RISC-V GCC doesn't support -mtune=native / -march=native
    export CXXFLAGS="${CXXFLAGS//-mtune=native/}"
    export CFLAGS="${CFLAGS//-mtune=native/}"
    cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
        -DCMAKE_C_FLAGS_RELEASE="-O2 -DNDEBUG" \
        -DCMAKE_CXX_FLAGS_RELEASE="-O2 -DNDEBUG"
    make -j$(nproc) || {
        criticalecho-noexit "[-] ngscopeclient build failed (known issue on RISC-V), skipping"
        return 0
    }
    ln -s /hardware/scopehal-apps/build/src/ngscopeclient/ngscopeclient /usr/bin/ngscopeclient
}

function pyhydrabus_install() {
    goodecho "[+] Installing Python3 module for HydraBus"
    pip3install pyHydrabus
}

function spitkey_install() {
    goodecho "[+] Installing Python3 module for HydraBus"
    [ -d /hardware ] || mkdir /hardware
    cd /hardware
    gitinstall "https://github.com/en4rab/SPITkey.git" "spitkey_install"
    cd SPITkey
    pip3install -r requirements.txt
}

function spitpm_trace_plugin_install() {
    goodecho "[+] Installing SPITPM Trace plugin"
    [ -d /hardware ] || mkdir /hardware
    cd /hardware
    gitinstall "https://github.com/ghecko/libsigrokdecoder_spi-tpm.git" "spitpm_trace_plugin_install"
    ln -s "$(pwd)/libsigrokdecoder_spi-tpm" /usr/share/libsigrokdecode4DSL/decoders/ # installing for DSView
    ln -s "$(pwd)/libsigrokdecoder_spi-tpm" /usr/share/libsigrokdecode/decoders/
}

function slogic_pulseview_install_fromsources() {
    goodecho "[+] Installing Sipeed SLogic PulseView (prefix-isolated in /opt/slogic)"
    SLOGIC_PREFIX="/opt/slogic"
    SLOGIC_PKG="$SLOGIC_PREFIX/lib/pkgconfig"
    SLOGIC_PYPATH="$SLOGIC_PREFIX/lib/python3/dist-packages"

    install_dependencies "sdcc libzip-dev libglibmm-2.4-dev libieee1284-3-dev nettle-dev \
        libglib2.0-dev libusb-1.0-0-dev libftdi1-dev libtool automake autoconf \
        libboost-all-dev libqt5svg5-dev qtbase5-dev qttools5-dev \
        swig python3-dev check doxygen"

    mkdir -p "$SLOGIC_PREFIX" "$SLOGIC_PYPATH"
    [ -d /root/thirdparty/slogic-build ] && rm -rf /root/thirdparty/slogic-build
    mkdir -p /root/thirdparty/slogic-build
    cd /root/thirdparty/slogic-build

    # Build Sipeed's forked libsigrok (slogic-dev branch)
    goodecho "[+] Building Sipeed libsigrok (slogic-dev)"
    installfromnet "git clone --depth=1 -b slogic-dev https://github.com/sipeed/libsigrok.git"
    cd libsigrok
    ./autogen.sh
    mkdir -p build && cd build
    PKG_CONFIG_PATH="$SLOGIC_PKG" ../configure --prefix="$SLOGIC_PREFIX"
    make -j$(nproc)
    PYTHONPATH="$SLOGIC_PYPATH" make install
    cd /root/thirdparty/slogic-build

    # Build libsigrokdecode
    goodecho "[+] Building libsigrokdecode for SLogic"
    installfromnet "git clone --depth=1 https://github.com/sigrokproject/libsigrokdecode.git"
    cd libsigrokdecode
    ./autogen.sh
    mkdir -p build && cd build
    PKG_CONFIG_PATH="$SLOGIC_PKG" ../configure --prefix="$SLOGIC_PREFIX"
    make -j$(nproc)
    make install
    cd /root/thirdparty/slogic-build

    # Build PulseView linked against Sipeed's libsigrok
    goodecho "[+] Building PulseView for SLogic"
    installfromnet "git clone --depth=1 https://github.com/sigrokproject/pulseview.git"
    cd pulseview
    mkdir -p build && cd build
    PKG_CONFIG_PATH="$SLOGIC_PKG" cmake \
        -DCMAKE_INSTALL_PREFIX:PATH="$SLOGIC_PREFIX" \
        -DCMAKE_PREFIX_PATH="$SLOGIC_PREFIX" \
        -DDISABLE_WERROR=y \
        ..
    make -j$(nproc)
    make install
    cd /root/thirdparty/slogic-build

    # Create wrapper script
    goodecho "[+] Creating slogic-pulseview launcher"
    cat > /usr/local/bin/slogic-pulseview << 'WRAPPER'
#!/bin/bash
export LD_LIBRARY_PATH="/opt/slogic/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export XDG_DATA_DIRS="/opt/slogic/share${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
exec /opt/slogic/bin/pulseview "$@"
WRAPPER
    chmod +x /usr/local/bin/slogic-pulseview

    # Create sigrok-cli wrapper too
    if [ -f "$SLOGIC_PREFIX/bin/sigrok-cli" ]; then
        cat > /usr/local/bin/slogic-cli << 'WRAPPER'
#!/bin/bash
export LD_LIBRARY_PATH="/opt/slogic/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export XDG_DATA_DIRS="/opt/slogic/share${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
exec /opt/slogic/bin/sigrok-cli "$@"
WRAPPER
        chmod +x /usr/local/bin/slogic-cli
    fi

    # Cleanup build sources
    rm -rf /root/thirdparty/slogic-build
    goodecho "[+] SLogic PulseView installed. Use 'slogic-pulseview' to launch."
}

function pythonfindus_install() {
    goodecho "[+] Installing Python3 module for PicoGlitcher"
    ARCH=$(uname -m)
    if [ "$ARCH" = "riscv64" ]; then
        # scipy (findus dep) requires gfortran + BLAS/LAPACK to build from source
        # pandas/scipy/numpy from apt avoids hours-long QEMU source compilation
        install_dependencies "gfortran libopenblas-dev liblapack-dev python3-numpy python3-pandas python3-scipy python3-matplotlib"
        pip3install --no-deps findus
        pip3install adafruit-ampy pyserial plotly dash dash_bootstrap_components dash_ag_grid setuptools
    else
        pip3install "findus"
    fi
}

function pythonrd6006_install() {
    goodecho "[+] Installing Python3 module for rd6006"
    pip3install rd6006
}