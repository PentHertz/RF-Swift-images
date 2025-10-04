#!/bin/bash

source common.sh

function ad_devices_install() {
	goodecho "[+] Installing libiio for PlutoSDR support"
	
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	
	# Install dependencies
	install_dependencies "libxml2 libxml2-dev bison flex cmake git libaio-dev boost-dev libusb-dev avahi-dev"
	
	# Build libiio from source
	goodecho "[+] Building libiio from source"
	installfromnet "git clone https://github.com/analogdevicesinc/libiio.git"
	cd libiio
	cmake -DCMAKE_INSTALL_PREFIX=/usr .
	make -j$(nproc)
	make install
	cd ..
	
	ldconfig 2>/dev/null || true
	
	goodecho "[+] libiio installed successfully"
	goodecho "[!] Note: libad9361-iio skipped - not required for basic PlutoSDR operation"
	goodecho "[!] Install gr-iio separately for GNU Radio integration"
}

function uhd_devices_install() {
	goodecho "[+] Installing UHD's libs and tools from package manager"
	install_dependencies "uhd uhd-dev uhd-tools"
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
	install_dependencies "dpdk dpdk-dev autoconf automake build-base cmake ccache doxygen ethtool boost-dev ncurses-dev libusb-dev python3-dev py3-mako py3-requests py3-scipy py3-setuptools py3-ruamel.yaml"
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
	make install
	ldconfig /usr/local/lib 2>/dev/null || true
	goodecho "[+] Downloading Hardware Driver firmware/FPGA"
	installfromnet "uhd_images_downloader"
}

function antsdr_uhd_devices_install() {
	goodecho "[+] Installing dependencies for ANTSDR UHD"
	install_dependencies "autoconf automake build-base cmake ccache doxygen ethtool libpthread-stubs"
	install_dependencies "boost-dev ncurses ncurses-dev libusb libusb-dev"
	install_dependencies "python3-dev py3-mako py3-numpy py3-requests py3-scipy py3-setuptools"
	install_dependencies "py3-ruamel.yaml"
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
	ldconfig /usr/local/lib 2>/dev/null || true
}

function nuand_devices_install() {
	goodecho "[+] Installing Nuand's libs and tools from package manager"
	install_dependencies "bladerf bladerf-dev"
	goodecho "[+] Copying rules sets"
	cp /root/rules/88-nuand-bladerf1.rules.in /etc/udev/rules.d/
	cp /root/rules/88-nuand-bladerf2.rules.in /etc/udev/rules.d/
	cp /root/rules/88-nuand-bootloader.rules.in /etc/udev/rules.d/

	# Installing Python bindings
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	git clone https://github.com/Nuand/bladeRF.git
	cd bladeRF/host/libraries/libbladeRF_bindings/python
	python3 setup.py install
}

function nuand_devices_fromsource_install() {
	goodecho "[+] Installing bladeRF dependencies"
	install_dependencies "libusb-dev libusb build-base cmake ncurses-dev pkgconf git wget"
	
	goodecho "[!] Note: libtecla not available in Alpine, building bladeRF without it"
	
	goodecho "[+] Cloning, building and installing Nuand's repository"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	installfromnet "git clone https://github.com/Nuand/bladeRF.git ./bladeRF"
	cd ./bladeRF/host
	mkdir build
	cd build
	
	# Build without libtecla - it's optional for interactive CLI features
	cmake -DCMAKE_BUILD_TYPE=Release \
		  -DCMAKE_INSTALL_PREFIX=/usr/local \
		  -DINSTALL_UDEV_RULES=ON \
		  -DENABLE_LIBTECLA=OFF \
		  ../
	
	make && make install
	ldconfig /usr/local/lib 2>/dev/null || true
}

function hackrf_devices_install() {
	goodecho "[+] Installing hackRF's libs and tools from package manager"
	install_dependencies "hackrf hackrf-dev"
}

function airspy_devices_install() {
	goodecho "[+] Installing airspy from package manager"
	install_dependencies "airspy airspy-dev"
}

function limesdr_devices_install() {
	goodecho "[+] Installing LimeSDR's libs and tools from package manager"
	install_dependencies "soapysdr limesuite limesuite-dev"
}

function install_soapy_modules() {
	goodecho "[+] Installing Soapy extra modules"
	install_dependencies "soapysdr-dev soapysdr-module-rtlsdr soapysdr-module-hackrf soapysdr-module-uhd soapysdr-module-airspy"
	# Note: Some modules may not be available in Alpine repos
	goodecho "[!] Note: Some SoapySDR modules may need to be compiled from source on Alpine"
}

function install_soapyPlutoSDR_modules() {
	set +e # TODO: debug that function
	set +o pipefail
	goodecho "[+] Installing Soapy PlutoSDR module"
	install_dependencies "ad9361 libiio libiio-dev"
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
	make install
	set -e
	set -o pipefail
}

function rtlsdr_devices_install() {
	goodecho "[+] Installing RTL-SDR's libs and tools from package manager"
	install_dependencies "rtl-sdr rtl-sdr-dev"
}

function rtlsdrv4_devices_install() {
	goodecho "[+] Installing RTL-SDR v4's libs and tools from source"
	# Alpine doesn't use apt purge
	apk del librtlsdr rtl-sdr 2>/dev/null || true
	rm -rvf /usr/lib/librtlsdr* /usr/include/rtl-sdr* /usr/local/lib/librtlsdr* /usr/local/include/rtl-sdr* /usr/local/include/rtl_* /usr/local/bin/rtl_*
	install_dependencies "libusb-dev git cmake pkgconf libpthread-stubs"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	installfromnet "git clone https://github.com/rtlsdrblog/rtl-sdr-blog"
	cd rtl-sdr-blog
	mkdir build
	cd build
	cmake ../ -DINSTALL_UDEV_RULES=ON
	make
	make install
	cp ../rtl-sdr.rules /etc/udev/rules.d/
	ldconfig /usr/local/lib 2>/dev/null || true
	cd /root
	rm -R /root/thirdparty
}

function osmofl2k_devices_install() {
	goodecho "[+] Installing osmo-fl2k dependencies"
	install_dependencies "libusb-dev sox pv"
	goodecho "[+] Cloning and Installing osmo-fl2k"
	apk del librtlsdr rtl-sdr 2>/dev/null || true
	rm -rvf /usr/lib/librtlsdr* /usr/include/rtl-sdr* /usr/local/lib/librtlsdr* /usr/local/include/rtl-sdr* /usr/local/include/rtl_* /usr/local/bin/rtl_*
	install_dependencies "libusb-dev git cmake pkgconf"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	installfromnet "git clone https://gitea.osmocom.org/sdr/osmo-fl2k"
	mkdir osmo-fl2k/build
	cd osmo-fl2k/build
	cmake ../ -DINSTALL_UDEV_RULES=ON
	make -j 3
	make install
	ldconfig /usr/local/lib 2>/dev/null || true
	cd /root
	rm -R /root/thirdparty
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	goodecho "[+] Cloning a few examples"
	installfromnet "git clone https://github.com/steve-m/fl2k-examples.git"
}

function xtrx_devices_install() {
	goodecho "[+] Installing xtrx from package manager"
	install_dependencies "libusb-dev cmake python3 py3-pip gpsd pps-tools boost-dev git qt5-qtbase-dev doxygen swig"
	pip3 install --break-system-packages cheetah3
	# Note: xtrx packages may not be available in Alpine main repos
	goodecho "[!] Note: XTRX may need to be compiled from source on Alpine"
}

function funcube_devices_install() {
	goodecho "[+] Installing funcube from package manager"
	# Note: funcube packages may not be available in Alpine
	goodecho "[!] Note: Funcube packages may not be available in Alpine repositories"
	goodecho "[!] You may need to compile from source"
}

function rfnm_devices_install() {
	install_dependencies "spdlog-dev"
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
	install_dependencies "soapysdr-dev soapysdr"
	goodecho "[+] Installing LiteX M2SDR"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	gitinstall "https://github.com/FlUxIuS/litex_m2sdr.git" "litexm2sdr_devices_install" "main"
	cd litex_m2sdr/litex_m2sdr/software
	./build.py
}

function soapybladerf_srsran_install() {
	install_dependencies "soapysdr-dev soapysdr"
	goodecho "[+] Installing SoapySDR bladeRF for srsRAN"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/FlUxIuS/SoapyBladeRF_srsran.git" "build" "" "" "soapybladerf_srsran_install" "-DCMAKE_INSTALL_PREFIX=/usr"
	ldconfig /usr/local/lib 2>/dev/null || true
}

function hydrasdr_rfone_install() {
	goodecho "[+] Installing HydraSDR bins and libs"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/hydrasdr/rfone_host.git" "build" "" "" "hydrasdr_rfone_install" -DCMAKE_INSTALL_PREFIX=/usr
	ln -sf /usr/include/libhydrasdr/hydrasdr.h /usr/include/hydrasdr.h
	ln -sf /usr/include/libhydrasdr/hydrasdr_commands.h /usr/include/hydrasdr_commands.h
}

function hydrasdr_rfone_bin_install() {
	goodecho "[+] Installing HydraSDR bins and libs"
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

function hydrasdr_rfone_soapy_bins_install() {
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

function sdrpp_extramodules_install() {
	goodecho "[+] Installing SDR++ extra modules"
	# Detect current architecture
	case "$(uname -m)" in
		x86_64)
			current_arch="amd64"
			;;
		aarch64)
			current_arch="arm64"
			criticalecho-noexit "Error: Unsupported architecture $(uname -m)"
			return 1
			;;
		riscv64)
			current_arch="riscv64"
			criticalecho-noexit "Error: Unsupported architecture $(uname -m)"
			return 1
			;;
		*)
			criticalecho-noexit "Error: Unsupported architecture $(uname -m)"
			return 1
			;;
	esac
	
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	mkdir -p signalhoundsdrpp
	cd signalhoundsdrpp
	wget -O /usr/lib/sdrpp/plugins/signalhound_bb_source.so https://github.com/PentHertz/SDRPlusPlus/releases/download/SignalHound/signalhound_bb_source-amd64.so
	wget -O /usr/lib/sdrpp/plugins/kcsdr_source-amd64.so https://github.com/PentHertz/SDRPlusPlus/releases/download/KC908/kcsdr_source-amd64.so
}

function usdr_lib_install() {
	goodecho "[+] Installing u/xSDR tools and libs"
	# Alpine doesn't support add-apt-repository, build from source or use available packages
	goodecho "[!] Note: USDR packages may not be available in Alpine repositories"
	goodecho "[!] You may need to compile from source"
}