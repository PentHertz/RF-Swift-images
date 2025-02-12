#!/bin/bash

function leobodnarv1_cal_device() {
	goodecho "[+] Installing dependencies for Leobodnar v1 GPSDO"
	[ -d /rftools/calibration ] || mkdir -p /rftools/calibration
	cd /rftools/calibration
	install_dependencies "libhidapi-libusb0 libhidapi-hidraw0"
	goodecho "[+] Cloning repository for Leobodnar v1 GPSDO"
	gitinstall "https://github.com/hamarituc/lbgpsdo.git"
	cd lbgpsdo
	pip3 install -r requirements.txt
	cd /root/
}

function leobodnarv2_cal_device() {
	goodecho "[+] Installing Leobodnar LBE-142x GPSDO"
	[ -d /rftools/calibration ] || mkdir -p /rftools/calibration
	cd /rftools/calibration
	gitinstall "https://github.com/FlUxIuS/lbe-142x.git" "leobodnarv2_cal_device"
	cd lbe-142x
	mkdir build && cd build
	cmake ..
	ln -s $(pwd)/lbe-142x /usr/bin/lbe-142x
	#usermod -aG plugdev $(whoami)
}

function gnsslogger_cal_device() {
	goodecho "[+] Installing gnsslogger"
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
   [ -d /rftools/calibration/Deepace ] || mkdir -p /rftools/calibration/Deepace 
   cd /rftools/calibration/Deepace

   # Set image name based on architecture
   if [ "$(uname -m)" = "aarch64" ]; then
       image_name="KCSDI-v0.4.8-49-linux-arm64.appimage"
   else
       image_name="KCSDI-v0.4.8-49-linux-x86_64.appimage"
   fi

   install_dependencies "libnss3-dev libfuse-dev"
   goodecho "[+] Downloading KCSDI from penthertz repo"
   installfromnet "wget https://github.com/PentHertz/rfswift_deepace_install/releases/download/nightly/${image_name}"
   chmod +x ${image_name}
   ln -s ${image_name} /usr/bin/KCSDI
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
	install_dependencies "libxcb-cursor0 xcb"
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
	install_dependencies "automake libtool make g++ libeigen3-dev libfftw3-dev libqt5charts5-dev"
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

function librevna_cal_device() {
	goodecho "[+] Installing dependencies for LibreVNA"
	install_dependencies "qt6-base-dev libqt6svg6 libusb-1.0-0-dev"
	[ -d /rftools/calibration ] || mkdir -p /rftools/calibration
	cd /rftools/calibration
	gitinstall "https://github.com/jankae/LibreVNA.git" "librevna_cal_device"
	cd LibreVNA
	cd Software/PC_Application/LibreVNA-GUI
	qmake6 LibreVNA-GUI.pro
	make -j$(nproc)
	ln -s "$(pwd)/LibreVNA-GUI" /usr/bin/LibreVNA-GUI
}

function librecala_cal_device() {
	goodecho "[+] Installing dependencies for LibreCAL A"
	install_dependencies "qt6-base-dev libqt6svg6-dev libusb-1.0-0-dev libqt6charts6-dev libqt6opengl6-dev"
	[ -d /rftools/calibration ] || mkdir -p /rftools/calibration
	cd /rftools/calibration
	gitinstall "https://github.com/jankae/LibreCAL.git" "librecala_cal_device"
	cd LibreCAL
	cd LibreCAL/Software/LibreCAL-GUI
	qmake6 LibreCAL-GUI.pro
	make -j$(nproc)
	make install
	ln -s "/opt/LibreCAL-GUI/bin/LibreCAL-GUI" /usr/bin/LibreCAL-GUI
}

function librevna_cal_device_buildx() {
    # Check architecture using uname
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        librevna_cal_device
    else
        goodecho "[!] Skipping LibreVNA build for $ARCH architecture as Qmake fails to get context with buildx"
    fi
}

function xnec2c_cal_device() {
	goodecho "[+] Installing dependencies for xnec2c"
	install_dependencies "gettext autopoint"
	[ -d /rftools/calibration ] || mkdir -p /rftools/calibration
	cd /rftools/calibration
	gitinstall "https://github.com/KJ7LNW/xnec2c.git" "xnec2c_cal_device"
	cd xnec2c
	./autogen.sh
	./configure
	make && make install
}