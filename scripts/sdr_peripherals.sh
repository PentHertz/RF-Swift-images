#!/bin/bash

source common.sh

function ad_devices_install() {
	goodecho "[+] Installing AD libs and tools from package manager"
	install_dependencies "libad9361-dev libiio-utils libiio-dev"
}

function uhd_devices_install() {
	goodecho "[+] Installing UHD's libs and tools from package manager"
	install_dependencies "libuhd4.1.0 libuhd-dev uhd-host"
	goodecho "[+] Copying rules sets"
	cp /root/rules/uhd-usrp.rules  /etc/udev/rules.d/
	goodecho "[+] Downloading Hardware Driver firmware/FPGA"
    installfromnet "/usr/bin/uhd_images_downloader"
}

function check_neon() {
    if grep -q 'Features.*neon' /proc/cpuinfo; then
        return 0 # NEON is present
    else
        return 1 # NEON is not present
    fi
}

function uhd_devices_fromsource_install() {
	goodecho "[+] Installing UHD's dependencies"
	install_dependencies "dpdk dpdk-dev autoconf automake build-essential ccache cmake cpufrequtils doxygen ethtool g++ git inetutils-tools libboost-all-dev libncurses5 libncurses5-dev libusb-1.0-0 libusb-1.0-0-dev libusb-dev python3-dev python3-mako python3-requests python3-scipy python3-setuptools \
python3-ruamel.yaml"
	goodecho "[+] Copying rules sets"
	cp /root/rules/uhd-usrp.rules  /etc/udev/rules.d/
	goodecho "[+] Cloning and compiling UHD"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	installfromnet "git clone https://github.com/EttusResearch/uhd.git"
	cd uhd/host
	mkdir build
	cd build
	# Detect if the architecture is ARM
	ARCH=$(uname -m)

	if [[ "$ARCH" == arm* || "$ARCH" == aarch64 ]]; then
	    echo "Architecture is ARM."

	    if check_neon; then
	        echo "NEON extension is present."
	        cmake -DCMAKE_FIND_ROOT_PATH=/usr ..
	    else
	        echo "NEON extension is not present."
	        cmake -DCMAKE_FIND_ROOT_PATH=/usr -DNEON_SIMD_ENABLE=OFF ..
	    fi
	else
	    echo "Architecture is not ARM."
	    cmake -DCMAKE_FIND_ROOT_PATH=/usr ..
	fi
	make -j$(nproc)
	sudo make install
	sudo ldconfig
	goodecho "[+] Downloading Hardware Driver firmware/FPGA"
    	installfromnet "uhd_images_downloader"
}

function antsdr_uhd_devices_install() { # Is replacing original one for now
	goodecho "[+] Installing dependencies for ANTSDR UHD"
	install_dependencies "autoconf automake build-essential ccache cmake cpufrequtils doxygen ethtool libpthread-stubs0-dev"
	install_dependencies "g++ git inetutils-tools libboost-all-dev libncurses5 libncurses5-dev libusb-1.0-0 libusb-1.0-0-dev"
	install_dependencies "python3-dev python3-mako python3-numpy python3-requests python3-scipy python3-setuptools"
	install_dependencies "python3-ruamel.yaml"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	installfromnet "git clone https://github.com/MicroPhase/antsdr_uhd.git"
	cd antsdr_uhd
	cd host/
	mkdir build
	cd build
	cmake ../
	make -j$(nproc)
	make install
	ldconfig
}

function nuand_devices_install() {
	goodecho "[+] Installing Nuand's libs and tools from package manager"
	installfromnet "add-apt-repository ppa:nuandllc/bladerf"
	installfromnet "apt-fast update"
	install_dependencies "bladerf libbladerf-dev"
	goodecho "[+] Copying rules sets"
	cp /root/rules/88-nuand-bladerf1.rules.in /etc/udev/rules.d/
	cp /root/rules/88-nuand-bladerf2.rules.in /etc/udev/rules.d/
	cp /root/rules/88-nuand-bootloader.rules.in /etc/udev/rules.d/
}

function nuand_devices_fromsource_install() {
    goodecho "[+] Installing bladeRF dependencies"
	install_dependencies "libusb-1.0-0-dev libusb-1.0-0 build-essential cmake libncurses5-dev libtecla1 libtecla-dev pkg-config git wget"
    goodecho "[+] Cloning, building and installing Nuand's repository"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    cd /root/thirdparty
	installfromnet "git clone https://github.com/Nuand/bladeRF.git ./bladeRF"
	cd ./bladeRF
	mkdir build
	cd build
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DINSTALL_UDEV_RULES=ON ../
	make && sudo make install && sudo ldconfig
	goodecho "[+] Copying rules sets"
        cp /root/rules/88-nuand-bladerf1.rules.in /etc/udev/rules.d/
        cp /root/rules/88-nuand-bladerf2.rules.in /etc/udev/rules.d/
        cp /root/rules/88-nuand-bootloader.rules.in /etc/udev/rules.d/
}

function hackrf_devices_install() {
	goodecho "[+] Installing hackRF's libs and tools from package manager"
	install_dependencies "hackrf libhackrf-dev"
}

function airspy_devices_install() {
	goodecho "[+] Installing airspy from package manager"
	install_dependencies "airspy libairspy-dev airspyhf libairspyhf-dev"
}

function limesdr_devices_install() {
	goodecho "[+] Installing LimeSDR's libs and tools from package manager"
	install_dependencies "soapysdr-module-lms7 libsoapysdr-dev liblimesuite-dev limesuite limesuite-udev"
}

function install_soapy_modules() {
	goodecho "[+] Installing Soapy extra modules"
	install_dependencies "libsoapysdr-dev soapysdr-module-osmosdr soapysdr-module-rtlsdr soapysdr-module-bladerf soapysdr-module-hackrf soapysdr-module-uhd soapysdr-module-mirisdr soapysdr-module-rfspace soapysdr-module-airspy"
}

function install_soapyPlutoSDR_modules() {
	set +e # TODO: debug that function
    set +o pipefail
	goodecho "[+] Installing Soapy PlutoSDR module"
	install_dependencies "libad9361-dev libiio-utils libiio-dev"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	installfromnet "git clone https://github.com/pothosware/SoapyPlutoSDR"
	cd SoapyPlutoSDR
	mkdir build
	cd build
	find /usr -name "libiio.so*"
	pkg-config --list-all | grep iio
pkg-config --libs libiio
	cmake -DCMAKE_INSTALL_PREFIX=/usr ../
	make
	sudo make install
	set -e
    set -o pipefail
}

function rtlsdr_devices_install() {
	goodecho "[+] Installing RTL-SDR's libs and tools from package manager"
	install_dependencies "librtlsdr-dev librtlsdr0 rtl-sdr"
}

function rtlsdrv4_devices_install() {
	goodecho "[+] Installing RTL-SDR v4's libs and tools from package manager"
	apt purge -y ^librtlsdr
	rm -rvf /usr/lib/librtlsdr* /usr/include/rtl-sdr* /usr/local/lib/librtlsdr* /usr/local/include/rtl-sdr* /usr/local/include/rtl_* /usr/local/bin/rtl_*
	install_dependencies "libusb-1.0-0-dev git cmake pkg-config libpthread-stubs0-dev"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	installfromnet "git clone https://github.com/rtlsdrblog/rtl-sdr-blog"
	cd rtl-sdr-blog
	mkdir build
	cd build
	cmake ../ -DINSTALL_UDEV_RULES=ON
	make
	sudo make install
	sudo cp ../rtl-sdr.rules /etc/udev/rules.d/
	sudo ldconfig
	cd /root
	rm -R /root/thirdparty
}

function osmofl2k_devices_install() {
	goodecho "[+] Installing osmo-fl2k dependencies"
	install_dependencies "libusb-1.0-0-dev sox pv"
	goodecho "[+] Cloning and Installing osmo-fl2k"
	apt purge -y ^librtlsdr
	rm -rvf /usr/lib/librtlsdr* /usr/include/rtl-sdr* /usr/local/lib/librtlsdr* /usr/local/include/rtl-sdr* /usr/local/include/rtl_* /usr/local/bin/rtl_*
	install_dependencies "libusb-1.0-0-dev git cmake pkg-config"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	installfromnet "git clone https://gitea.osmocom.org/sdr/osmo-fl2k"
	mkdir osmo-fl2k/build
	cd osmo-fl2k/build
	cmake ../ -DINSTALL_UDEV_RULES=ON
	make -j 3
	sudo make install
	sudo ldconfig
	cd /root
	rm -R /root/thirdparty
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	goodecho "[+] Cloning a few examples"
	installfromnet "git clone https://github.com/steve-m/fl2k-examples.git"
}

function xtrx_devices_install() {
	goodecho "[+] Installing xtrx from package manager"
	install_dependencies "libusb-1.0-0-dev cmake dkms python3 python3-pip gpsd gpsd-clients pps-tools libboost-all-dev git qtbase5-dev libqcustomplot-dev libqt5printsupport5 doxygen swig"
	pip3install "cheetah3"
	install_dependencies "soapysdr-module-xtrx xtrx-dkms xtrx-fft libxtrxll0 libxtrxll-dev libxtrxll-dev libxtrx-dev libxtrxdsp-dev"
}

function funcube_devices_install() {
	goodecho "[+] Installing funcube from package manager"
	install_dependencies "gr-funcube libgnuradio-funcube1.0.0 qthid-fcd-controller"
}

function rfnm_devices_install() {
	install_dependencies "libspdlog-dev"
	goodecho "[+] Installing RFNM libs"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
	cmake_clone_and_build "https://github.com/rfnm/librfnm.git" "build" "" "" "rfnm_devices_install" "-DCMAKE_INSTALL_PREFIX=/usr"
}

function libresdr_b2x0_devices_install() {
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
    cd /rftools/sdr
    mkdir -p libresdr
    cd libresdr
	goodecho "[+] Downloading LibreSDR B2x0 FPGA firmwares"
	installfromnet "wget https://github.com/FlUxIuS/libresdr-b2xx/releases/download/2024.1/libresdr_b210.bin"
	installfromnet "wget https://github.com/FlUxIuS/libresdr-b2xx/releases/download/2024.1/libresdr_b220.bin"
}

function litexm2sdr_devices_install() {
	install_dependencies "libsoapysdr-dev soapysdr-tools"
	goodecho "[+] Installing LiteX M2SDR"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    gitinstall "https://github.com/FlUxIuS/litex_m2sdr.git" "litexm2sdr_devices_install" "main"
    cd litex_m2sdr/litex_m2sdr/software
    ./build.py
}

function soapybladerf_srsran_install() {
    install_dependencies "uhd-soapysdr libsoapysdr-dev soapysdr-tools"
    goodecho "[+] Installing SoapySDR bladeRF for srsRAN"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    cmake_clone_and_build "https://github.com/FlUxIuS/SoapyBladeRF_srsran.git" "build" "" "" "soapybladerf_srsran_install" "-DCMAKE_INSTALL_PREFIX=/usr"
    ldconfig
}

function hydrasdr_rfone_install() {
	goodecho "[+] Installing HydraSDR bins and libs"
	gitinstall "https://github.com/hydrasdr/rfone_host.git" "hydrasdr_rfone_bin_install" "main"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
	cmake_clone_and_build "https://github.com/hydrasdr/rfone_host.git" "build" "" "" "hydrasdr_rfone_bin_install" -DCMAKE_INSTALL_PREFIX=/usr
}

function hydrasdr_rfone_bin_install() {
	goodecho "[+] Installing HydraSDR bins and libs"
    # TODO: temporary install before official release
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    mkdir -p hydrasdr
    cd hydrasdr
    # Detect current architecture
    local current_arch
    case "$(uname -m)" in
        x86_64)
            current_arch="amd64"
            ;;
        aarch64)
            current_arch="arm64"
            ;;
        riscv64)
            current_arch="riscv64"
            ;;
        *)
            criticalecho-noexit "Error: Unsupported architecture $(uname -m)"
            criticalecho-noexit "Supported architectures: x86_64 (amd64), aarch64 (arm64), riscv64"
            ;;
    esac
    
    colorecho "Detected architecture: $(uname -m) -> using ${current_arch} binaries"
    
    # Download architecture-specific files
    if ! wget "https://github.com/PentHertz/rfone/releases/download/rcbins/${current_arch}-rfone_host-bins.tar.gz"; then
        criticalecho-noexit "Error: Failed to download ${current_arch} binaries"
    fi
    
    if ! wget "https://github.com/PentHertz/rfone/releases/download/rcbins/${current_arch}-rfone_host-libs.tar.gz"; then
        criticalecho-noexit "Error: Failed to download ${current_arch} libraries"
    fi
    
    # Extract files
    if ! tar xvzf "${current_arch}-rfone_host-bins.tar.gz"; then
        criticalecho-noexit "Error: Failed to extract binaries"
    fi
    
    if ! tar xvzf "${current_arch}-rfone_host-libs.tar.gz"; then
        criticalecho-noexit "Error: Failed to extract libraries"
    fi
    
    # Install files
    if ! mv hydrasdr* /usr/bin/; then
        criticalecho-noexit "Error: Failed to move binaries to /usr/bin (check permissions)"
    fi
    
    if ! mv libhydrasdr.* /usr/lib/; then
        criticalecho-noexit "Error: Failed to move libraries to /usr/lib (check permissions)"
    fi

    wget https://github.com/PentHertz/rfone/releases/download/rcbins/libhydrasdr-headers.zip
    unzip libhydrasdr-headers.zip
    cp -R libhydrasdr /usr/include/
    
    goodecho "HydraSDR RFOne installation completed successfully for ${current_arch}"
}

function hydrasdr_rfone_soapy_install() {
	goodecho "[+] Installing HydraSDR Soapy lib"
    # Detect current architecture
    case "$(uname -m)" in
        x86_64)
            current_arch="amd64"
            ;;
        aarch64)
            current_arch="arm64"
            ;;
        riscv64)
            current_arch="riscv64"
            ;;
        *)
            criticalecho-noexit "Error: Unsupported architecture $(uname -m)"
            return 1
            ;;
    esac
    
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    mkdir -p hydrasdr
    cd hydrasdr
    wget https://github.com/PentHertz/rfone/releases/download/rcbins/${current_arch}-libhydraSoapy.tar.gz
    tar xzf ${current_arch}-libhydraSoapy.tar.gz
    soapy_path=$(SoapySDRUtil --info 2>/dev/null | grep -o '/[^[:space:]]*SoapySDR/modules[^[:space:]]*' | head -1)
    mv libhydrasdrSupport.so ${soapy_path}/
}