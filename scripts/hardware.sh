#!/bin/bash

function dsview_install() {
	goodecho "[+] Installing DSView for DSLogic"
	install_dependencies "libfftw3-dev"
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
    install_dependencies "sdcc libzip-dev libglibmm-2.4-dev"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    git clone https://github.com/FlUxIuS/sigrok-util.git
    cd sigrok-util/cross-compile/linux
    ./sigrok-cross-linux
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