#!/bin/bash

function leobodnarv1_cal_device() {
	goodecho "[+] Installing dependencies for Leobodnar v1 GPSDO"
	[ -d /rftools/calibration ] || mkdir -p /rftools/calibration
	cd /rftools/calibration
	installfromnet "apt-fast install -y libhidapi-libusb0 libhidapi-hidraw0"
	goodecho "[+] Cloning repository for Leobodnar v1 GPSDO"
	gitinstall "https://github.com/hamarituc/lbgpsdo.git"
	cd /root/
}

function leobodnarv2_cal_device() {
	goodecho "[+] Installing Leobodnar LBE-142x GPSDO"
	[ -d /rftools/calibration ] || mkdir -p /rftools/calibration
	cd /rftools/calibration
	gitinstall "https://github.com/bvernoux/lbe-142x.git" "leobodnarv2_cal_device"
	cd lbe-142x
	mkdir build && cd build
	cmake ..
	ln -s $(pwd)/lbe-142x /usr/bin/lbe-142x
	#usermod -aG plugdev $(whoami)
}

function gnsslogger_cal_device() {
	goodecho "[+] Installing dependencies for gnsslogger"
	[ -d /rftools/calibration ] || mkdir -p /rftools/calibration
	cd /rftools/calibration
	gitinstall "https://github.com/bvernoux/gnsslogger.git" "gnsslogger_cal_device"
	cd gnsslogger
	mkdir build && cd build
	cmake -DBUILD_TESTS=ON ..
	cmake -DBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release ..
	ln -s $(pwd)/gnsslogger /usr/bin/gnsslogger
}

function KCSDI_cal_device() {
	goodecho "[+] Installing dependencies for KCSDI"
	[ -d /rftools/calibration ] || mkdir -p /rftools/calibration
	cd /rftools/calibration
	mkdir Deepace
	cd Deepace
	installfromnet "apt-fast install -y libnss3-dev libfuse-dev"
	goodecho "[+] Downloading KCSDI from penthertz repo"
	installfromnet "wget https://github.com/PentHertz/rfswift_deepace_install/releases/download/nightly/KCSDI-v0.4.5-45-linux-x86_64.AppImage"
	chmod +x KCSDI-v0.4.5-45-linux-x86_64.AppImage
	ln -s KCSDI-v0.4.5-45-linux-x86_64.AppImage /usr/bin/KCSDI
}

function NanoVNASaver_cal_device() {
    local ARCH=$(uname -m)

    case "$ARCH" in
        x86_64|amd64)
            NanoVNASaver_cal_device_call
            ;;
        i?86)
            NanoVNASaver_cal_device_call
            ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $ARCH. NanoVNASaver installation is not supported on this architecture."
            ;;
    esac
}

function NanoVNASaver_cal_device_call() {
	set +e # TODO: debug that function
    set +o pipefail
	goodecho "[+] Installing dependencies for NanoVNASaver"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	installfromnet "apt-fast install -y libxcb-cursor0 xcb"
	goodecho "[+] Cloning and installing NanoVNASaver"
	gitinstall "https://github.com/NanoVNA-Saver/nanovna-saver.git"
	cd nanovna-saver
	installfromnet "pip3 install -U setuptools setuptools_scm wheel"
	sed -i 's/numpy==2.1.3/numpy<2/' requirements.txt
	installfromnet "pip3 install -r requirements.txt"
	python3 setup.py install
	set -e
    set -o pipefail
}

function NanoVNA_QT_cal_device() {
	goodecho "[+] Installing dependencies for NanoVNA-QT"
	[ -d /rftools/calibration ] || mkdir -p /rftools/calibration
	cd /rftools/calibration
	installfromnet "apt-fast install -y automake libtool make g++ libeigen3-dev libfftw3-dev libqt5charts5-dev"
	goodecho "[+] Cloning and installing NanoVNA-QT"
	gitinstall "https://github.com/nanovna-v2/NanoVNA-QT.git"
	cd NanoVNA-QT
	autoreconf --install
	./configure
	make -j$(nproc)
	cd libxavna/xavna_mock_ui/
	qmake
 	make -j$(nproc)
 	cd ../..
 	cd vna_qt
	qmake
	make -j$(nproc)
}

function pocketvna_sa_device() {
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
        colorecho "[+] Architecture is $ARCH, proceeding with installation"
        colorecho "[+] Downloading lastest pocketVNA install script from GitHub"
        [ -d /rftools/calibration ] || mkdir -p /rftools/calibration
		cd /rftools/calibration
        mkdir pocketVNA
        cd pocketVNA
        installfromnet "wget https://github.com/PentHertz/rfswift_unofficial_pocketvna/releases/download/latest/pocketVna1.m96-New_x86_64.run.2.tar.gz"
        tar xvzf pocketVna1.m96-New_x86_64.run.2.tar.gz
        rm pocketVna1.m96-New_x86_64.run.2.tar.gz
        chmod +x pocketVna1.m96-New_x86_64.run
        ln -s $(pwd)/pocketVna1.m96-New_x86_64.run /usr/sbin/pocketVNA
    else
        criticalecho-noexit "[!] Architecture is not amd64 or x86_64. Skipping installation."
    fi
}