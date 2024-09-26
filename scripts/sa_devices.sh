#!/bin/bash

function kc908_sa_device() {
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
        colorecho "[+] Architecture is $ARCH, proceeding with installation"
        colorecho "[+] Downloading bin from DEEPACE"
        [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
        cd /root/thirdparty
        installfromnet "wget https://deepace.net/wp-content/uploads/2024/04/KC908-GNURadio24.4.06.zip"
        unzip KC908-GNURadio24.4.06.zip
        rm KC908-GNURadio24.4.06.zip
        cd KC908-GNURadio/lib
        INCLUDE_DIR="/usr/local/include/kcsdr"
        LIB_DIR="/usr/local/lib"
        mkdir ${INCLUDE_DIR}
        cp ./kcsdr.h ${INCLUDE_DIR}
        cp ./libkcsdr.so ${LIB_DIR}
        chmod 666 ${INCLUDE_DIR}/kcsdr.h
        chmod 666 ${LIB_DIR}/libkcsdr.so
        rm -f /usr/lib/libftd3xx.so
        cp ./linux/libftd3xx.so /usr/lib/
        cp ./linux/libftd3xx.so.0.5.21 /usr/lib/
        cp ./linux/51-ftd3xx.rules /etc/udev/rules.d/
        cd /root/thirdparty
        cd KC908-GNURadio/module3.9/gr-kc_sdr
        mkdir build \
        && cd build/ \
        && cmake -DCMAKE_INSTALL_PREFIX=/usr ../ \
        && make -j$(nproc); sudo make install
        cd /root/
    else
        criticalecho-noexit "[!] Architecture is not amd64 or x86_64. Skipping installation."
    fi
}

function signalhound_sa_device() {
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
        colorecho "[+] Architecture is $ARCH, proceeding with installation"
        colorecho "[+] Downloading bin from SignalHound"
        [ -d /rftools/analysers ] || mkdir -p /rftools/analysers
        cd /rftools/analysers
        installfromnet "wget https://signalhound.com/sigdownloads/Spike/Spike(Ubuntu22.04x64)_3_9_7.zip"
        unzip Spike\(Ubuntu22.04x64\)_3_9_7.zip
        rm Spike\(Ubuntu22.04x64\)_3_9_7.zip
        cd Spike\(Ubuntu22.04x64\)_3_9_7/
        chmod +x setup.sh
        sh -c ./setup.sh
        ln -s Spike /usr/bin/Spike
    else
        criticalecho-noexit "[!] Architecture is not amd64 or x86_64. Skipping installation."
    fi
}

function harogic_sa_device() {
	goodecho "[+] Downloading SAStudio4"
	[ -d /rftools/analysers ] || mkdir -p /rftools/analysers
	cd /rftools/analysers
	arch=`uname -i`
	prog=""
    sdkarch=""
	case "$arch" in
  		x86_64|amd64)
    		prog="SAStudio4_x86_64_05_23_17_06";;
  		aarch64|unknown) # We asume unknwon would be RPi 5 for now...?
    		prog="SAStudio4_aarch64_05_22_17_41";;
  		*)
    		printf 'Unsupported architecture: "%s"!\n' "$arch" >&2; exit 0;;
	esac
	installfromnet "wget https://github.com/PentHertz/rfswift_harogic_install/releases/download/v05.23.17/$prog.zip"
	unzip "$prog"
	rm "$prog.zip"
	cd "$prog"
	currentpath=$(pwd)
	sh -c ./install.sh
	case "$arch" in # quick fix for aarch64
  		aarch64|unknown) 
    		ln -s /usr/lib/aarch64-linux-gnu/libffi.so.8 /usr/lib/libffi.so.6;;
	esac
	ln -s /usr/local/bin/sastudio/.sastudio.sh /usr/sbin/sastudio
	goodecho "[+] Installing htraapi"
	installfromnet "wget https://github.com/PentHertz/rfswift_harogic_install/releases/download/v05.23.17/Install_HTRA_SDK.zip"
    unzip Install_HTRA_SDK.zip
    rm Install_HTRA_SDK.zip
    cd Install_HTRA_SDK/
    cp htraapi/configs/htrausb.conf /etc/
    cp htraapi/configs/htra-cyusb.rules /etc/udev/rules.d/
    rm -rf /opt/htraapi/
    cp -r htraapi/ /opt/
    file=$( ls htraapi/lib/x86_64/libhtraapi.so.* )
    file=$( basename $file )
    version=${file#*so.}
    majornum=${version%%.*}
    case "$arch" in
        x86_64|amd64)
            sdkarch="x86_64"
            ln -sf /opt/htraapi/lib/x86_64/libhtraapi.so.${version} /opt/htraapi/lib/x86_64/libhtraapi.so.${majornum}
            ln -sf /opt/htraapi/lib/x86_64/libhtraapi.so.${majornum} /opt/htraapi/lib/x86_64/libhtraapi.so
            ln -sf /opt/htraapi/lib/x86_64/libusb-1.0.so.0.2.0 /opt/htraapi/lib/x86_64/libusb-1.0.so.0
            ln -sf /opt/htraapi/lib/x86_64/libusb-1.0.so.0 /opt/htraapi/lib/x86_64/libusb-1.0.so
            ;;
        aarch64|unknown) # We assume unknown would be RPi 5 for now...?
            sdkarch="aarch64"
            ln -sf /opt/htraapi/lib/aarch64/libhtraapi.so.${version} /opt/htraapi/lib/aarch64/libhtraapi.so.${majornum}
            ln -sf /opt/htraapi/lib/aarch64/libhtraapi.so.${majornum} /opt/htraapi/lib/aarch64/libhtraapi.so
            ln -sf /opt/htraapi/lib/aarch64/libusb-1.0.so.0.2.0 /opt/htraapi/lib/aarch64/libusb-1.0.so.0
            ln -sf /opt/htraapi/lib/aarch64/libusb-1.0.so.0 /opt/htraapi/lib/aarch64/libusb-1.0.so
            ;;
        *)
            printf 'Unsupported architecture: "%s"!\n' "$arch" >&2
            exit 0
            ;;
    esac
    cd "/opt/htraapi/lib/$sdkarch"
    ln -sf $(pwd)/libhtraapi.so.${version} /usr/lib/libhtraapi.so.${version}
    ln -sf $(pwd)/libhtraapi.so.${majornum} /usr/lib/libhtraapi.so.${majornum}
    ln -sf $(pwd)/libliquid.so /usr/lib/libliquid.so
	colorecho "[+] Note: you'll have to put your calibration data after!"
}