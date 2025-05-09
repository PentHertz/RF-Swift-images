#!/bin/bash

function dsview_install() {
	goodecho "[+] Installing DSView for DSLogic"
	install_dependencies "libfftw3-dev"
    ldconfig
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	git clone https://github.com/DreamSourceLab/DSView.git
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

function flashrom_install() {
    goodecho "[+] Installing flashrom"
    install_dependencies "meson pciutils usbutils libpci-dev libusb-dev libftdi1 libftdi-dev zlib1g-dev subversion libusb-1.0-0-dev"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    git clone https://github.com/flashrom/flashrom.git
    cd flashrom
    meson setup builddir
    meson compile -C builddir
    meson install -C builddir
}

function pulseview_install() {
    goodecho "[+] Installing Sigrok pulseview"
    install_dependencies "sdcc libzip-dev libglibmm-2.4-dev libieee1284-3-dev libnettle8"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    git clone https://github.com/FlUxIuS/sigrok-util.git
    cd sigrok-util/cross-compile/linux
    ./sigrok-cross-linux
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
      --enable-boundary-scan
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
    ln -s "$(pwd)/hydranfc_v2_sniffer_decoder" /usr/local/share/libsigrokdecode4DSL/decoders/ # installing for DSView
    ln -s "$(pwd)/hydranfc_v2_sniffer_decoder" /usr/share/libsigrokdecode/decoders/
}

function arduino_ide_install() {
    ARCH=$(uname -m)
    if [ "$ARCH" != "x86_64" ]; then
        criticalecho-noexit "[!] Error: This script only supports x86_64/amd64 architecture."
        criticalecho-noexit "[!] Current architecture: $ARCH"
        exit 0
    fi
    
    goodecho "[+] Installing Arduino IDE for x86_64 with AppImage"
    IDE_VERSION="2.3.4"
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
    if [ "$ARCH" != "x86_64" ]; then
        criticalecho-noexit "[!] Error: This script only supports x86_64/amd64 architecture."
        criticalecho-noexit "[!] Current architecture: $ARCH"
        exit 0
    fi
    LOGIC_VERSION="2.4.22"
    install_dependencies "libfftw3-dev"
    [ -d /hardware ] || mkdir /hardware
    cd /hardware
    mkdir -p Saleae
    cd Saleae
    wget "https://downloads2.saleae.com/logic2/Logic-${LOGIC_VERSION}-linux-x64.AppImage"
    chmod +x "Logic-${LOGIC_VERSION}-linux-x64.AppImage"
    ln -s "$(pwd)/Logic-${LOGIC_VERSION}-linux-x64.AppImage" /usr/bin/Logic-2-Saleae
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