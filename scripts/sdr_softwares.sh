#!/bin/bash

function gnuradio_soft_install() {
	goodecho "[+] Building GNU Radio from source"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	
	# Install build dependencies (log4cpp removed - not in Alpine)
	install_dependencies "cmake build-base boost-dev fftw-dev cppunit-dev swig python3-dev py3-numpy py3-mako gsl-dev gmp-dev mpir-dev alsa-lib-dev jack-dev portaudio-dev libusb-dev zeromq-dev qt5-qtbase-dev"
	
	# Build log4cpp from source
	goodecho "[+] Building log4cpp from source"
	installfromnet "wget https://downloads.sourceforge.net/project/log4cpp/log4cpp-1.1.x%20%28new%29/log4cpp-1.1/log4cpp-1.1.4.tar.gz"
	tar xzf log4cpp-1.1.4.tar.gz
	cd log4cpp
	./configure --prefix=/usr
	make -j$(nproc)
	make install
	cd ..
	
	# Install Python packages including pybind11
	pip3 install --break-system-packages click click-plugins packaging pybind11 pygccxml
	
	# Clone and build GNU Radio
	installfromnet "git clone --recursive https://github.com/gnuradio/gnuradio.git"
	cd gnuradio
	mkdir build
	cd build
	
	cmake -DCMAKE_INSTALL_PREFIX=/usr \
		  -DENABLE_PYTHON=ON \
		  -DENABLE_GR_QTGUI=ON \
		  ..
	
	make -j$(nproc)
	make install
	ldconfig 2>/dev/null || true
}

function sdrangel_soft_install() {
	goodecho "[!] Note: SDRAngel binary packages not available for Alpine"
	goodecho "[!] Use sdrangel_soft_fromsource_install instead"
	sdrangel_soft_fromsource_install
}

function sdrangel_soft_fromsource_install() {
	ARCH=$(uname -m)
	if [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]]; then
		criticalecho-noexit "[-] Unsupported architecture: $ARCH"
		exit 0
	fi
	
	goodecho "[+] Installing dependencies for SDRAngel"
	install_dependencies "cmake build-base boost-dev fftw-dev libusb-dev opencv-dev libxml2-dev bison flex ffmpeg-dev opus-dev qt5-qtbase-dev qt5-qtmultimedia-dev qt5-qtwebsockets-dev qt5-qttools-dev qt5-qtserialport-dev qt5-qtlocation-dev qt5-qtsvg-dev faad2-dev alsa-lib-dev pulseaudio-dev libsndfile-dev"
	
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	
	goodecho "[+] Building SDRAngel components"
	cmake_clone_and_build "https://github.com/srcejon/aptdec.git" "build" "libaptdec" "" "sdrangel_soft_fromsource_install" -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/aptdec
	
	cmake_clone_and_build "https://github.com/f4exb/cm256cc.git" "build" "" 6f4a51802f5f302577d6d270a9fc0cb7a1ee28ef "sdrangel_soft_fromsource_install" -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/cm256cc
	
	cmake_clone_and_build "https://github.com/srcejon/dab-cmdline" "library/build" "msvc" "" "sdrangel_soft_fromsource_install" -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/libdab
	
	cmake_clone_and_build "https://github.com/szechyjs/mbelib.git" "build" "" 9a04ed5c78176a9965f3d43f7aa1b1f5330e771f "sdrangel_soft_fromsource_install" -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/mbelib
	
	cmake_clone_and_build "https://github.com/f4exb/serialDV.git" "build" "" "v1.1.4" "sdrangel_soft_fromsource_install" -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/serialdv
	
	cmake_clone_and_build "https://github.com/f4exb/dsdcc.git" "build" "" "v1.9.5" "sdrangel_soft_fromsource_install" \
		-Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/dsdcc -DUSE_MBELIB=ON -DLIBMBE_INCLUDE_DIR=/opt/install/mbelib/include \
		-DLIBMBE_LIBRARY=/opt/install/mbelib/lib/libmbe.so -DLIBSERIALDV_INCLUDE_DIR=/opt/install/serialdv/include/serialdv \
		-DLIBSERIALDV_LIBRARY=/opt/install/serialdv/lib/libserialdv.so
	
	install_dependencies "speexdsp-dev libsamplerate-dev"
	cmake_clone_and_build "https://github.com/drowe67/codec2-dev.git" "build" "" "v1.0.3" "sdrangel_soft_fromsource_install"
	
	cmake_clone_and_build "https://github.com/dnwrnr/sgp4.git" "build" "" "" "sdrangel_soft_fromsource_install" -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/sgp4
	
	cmake_clone_and_build "https://github.com/f4exb/libsigmf.git" "build" "new-namespaces" "" "sdrangel_soft_fromsource_install" -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/libsigmf
	
	cmake_clone_and_build "https://github.com/ggerganov/ggmorse.git" "build" "" "" "sdrangel_soft_fromsource_install" -Wno-dev \
		-DCMAKE_INSTALL_PREFIX=/opt/install/ggmorse -DGGMORSE_BUILD_TESTS=OFF -DGGMORSE_BUILD_EXAMPLES=OFF
	
	goodecho "[+] Installing SDRAngel"
	cmake_clone_and_build "https://github.com/f4exb/sdrangel.git" "build" "" "" "sdrangel_soft_fromsource_install" -Wno-dev -DDEBUG_OUTPUT=ON -DRX_SAMPLE_24BIT=ON \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DAPT_DIR=/opt/install/aptdec \
		-DCM256CC_DIR=/opt/install/cm256cc \
		-DDSDCC_DIR=/opt/install/dsdcc \
		-DSERIALDV_DIR=/opt/install/serialdv \
		-DMBE_DIR=/opt/install/mbelib \
		-DCODEC2_DIR=/opt/install/codec2 \
		-DSGP4_DIR=/opt/install/sgp4 \
		-DLIBSIGMF_DIR=/opt/install/libsigmf \
		-DDAB_DIR=/opt/install/libdab \
		-DGGMORSE_DIR=/opt/install/ggmorse \
		-DCMAKE_INSTALL_PREFIX=/opt/install/sdrangel
	ln -sf /opt/install/sdrangel/bin/sdrangel /usr/bin/sdrangel
}

function sdrpp_soft_fromsource_install() {
	goodecho "[+] Installing dependencies for SDR++"
	install_dependencies "cmake build-base fftw-dev glfw-dev volk-dev zstd-dev libusb-dev rtaudio-dev codec2-dev"
	
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	
	ARCH=$(uname -m)
	HAROGIC_FLAG=""
	if [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" || "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
		HAROGIC_FLAG="-DOPT_BUILD_HAROGIC_SOURCE=ON"
	fi
	
	cmake_clone_and_build "https://github.com/AlexandreRouma/SDRPlusPlus.git" "build" "" "" "sdrpp_soft_fromsource_install" \
		-DOPT_BUILD_HYDRASDR_SOURCE=ON -DOPT_BUILD_SOAPY_SOURCE=ON -DOPT_BUILD_AIRSPY_SOURCE=ON -DOPT_BUILD_AIRSPYHF_SOURCE=ON \
		-DOPT_BUILD_NETWORK_SINK=ON -DOPT_BUILD_FREQUENCY_MANAGER=ON -DOPT_BUILD_IQ_EXPORTER=ON -DOPT_BUILD_RECORDER=ON \
		-DOPT_BUILD_RIGCTL_SERVER=ON -DOPT_BUILD_METEOR_DEMODULATOR=ON $HAROGIC_FLAG -DOPT_BUILD_RADIO=ON \
		-DOPT_BUILD_USRP_SOURCE=ON -DOPT_BUILD_FILE_SOURCE=ON -DOPT_BUILD_HACKRF_SOURCE=ON -DOPT_BUILD_RTL_SDR_SOURCE=ON \
		-DOPT_BUILD_RTL_TCP_SOURCE=ON -DOPT_BUILD_SDRPP_SERVER_SOURCE=ON -DOPT_BUILD_LIMESDR_SOURCE=ON \
		-DOPT_BUILD_PLUTOSDR_SOURCE=ON -DOPT_BUILD_BLADERF_SOURCE=ON -DOPT_BUILD_AUDIO_SOURCE=ON -DOPT_BUILD_AUDIO_SINK=ON \
		-DOPT_BUILD_M17_DECODER=ON -DUSE_BUNDLE_DEFAULTS=ON -DCMAKE_BUILD_TYPE=Release
	
	mkdir -p "/root/Library/Application Support/sdrpp/"
	cp /root/config/sdrpp-config.json "/root/Library/Application Support/sdrpp/config.json" 2>/dev/null || true
}

function sdrpp_soft_install() {
	goodecho "[!] Binary packages not available for Alpine"
	goodecho "[!] Using source build instead"
	sdrpp_soft_fromsource_install
}

function sigdigger_soft_install() {
	goodecho "[+] Installing dependencies for SigDigger"
	install_dependencies "libxml2-dev fftw-dev alsa-lib-dev"
	
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	installfromnet "wget https://actinid.org/blsd"
	chmod +x blsd
	./blsd
	ln -sf /rftools/sdr/blsd-dir/SigDigger/SigDigger /usr/sbin/SigDigger
}

function cyberther_soft_install() {
	goodecho "[+] Installing Cyber Ether"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	
	cmake_clone_and_build "https://github.com/catchorg/Catch2.git" "build" "" "" "cyberther_soft_install" -DCMAKE_INSTALL_PREFIX=/usr
	
	install_dependencies "cmake build-base pkgconf meson git zenity curl spirv-cross glslang glfw-dev vulkan-loader-dev vulkan-validation-layers cargo mesa-dev gstreamer-dev gst-plugins-base-dev gst-plugins-good gst-plugins-bad py3-yaml"
	
	gitinstall "https://github.com/luigifcruz/CyberEther.git" "cyberther_soft_install"
	cd CyberEther
	meson setup -Dbuildtype=debugoptimized build && cd build
	ninja install
}

function inspectrum_soft_install() {
	goodecho "[+] Building inspectrum from source"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	
	install_dependencies "cmake build-base qt5-qtbase-dev fftw-dev liquid-dsp-dev"
	
	cmake_clone_and_build "https://github.com/miek/inspectrum.git" "build" "" "" "inspectrum_soft_install" -DCMAKE_INSTALL_PREFIX=/usr
}

function gqrx_soft_install() {
	goodecho "[+] Building GQRX from source"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	
	install_dependencies "cmake build-base qt5-qtbase-dev qt5-qtsvg-dev boost-dev pulseaudio-dev"
	
	if ! command -v gnuradio-config-info &> /dev/null; then
		gnuradio_soft_install
	fi
	
	cmake_clone_and_build "https://github.com/gqrx-sdr/gqrx.git" "build" "" "" "gqrx_soft_install" -DCMAKE_INSTALL_PREFIX=/usr
}

function multimon_ng_soft_install() {
	goodecho "[+] Building multimon-ng from source"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	
	install_dependencies "cmake build-base pulseaudio-dev libx11-dev"
	
	cmake_clone_and_build "https://github.com/EliasOenal/multimon-ng.git" "build" "" "" "multimon_ng_soft_install" -DCMAKE_INSTALL_PREFIX=/usr
}

function urh_soft_pip_install() {
	goodecho "[+] Installing URH via pip"
	if [ "$(uname -m)" = "riscv64" ]; then
		criticalecho-noexit "[!] Skipping URH on RISCV64"
		return 0
	fi
	pip3install "urh"
}

function urh_soft_install() {
	goodecho "[+] Installing URH from HydraSDR fork"
	
	if [ "$(uname -m)" = "riscv64" ]; then
		criticalecho-noexit "[!] Skipping URH on RISCV64"
		return 0
	fi
	
	URH_VENV_DIR="/opt/urh-venv"
	URH_CLONE_DIR="/opt/urh-hydrasdr"
	URH_WRAPPER="/usr/sbin/urh"
	
	install_dependencies "python3-dev build-base git libxml2-dev libxslt-dev zlib-dev py3-virtualenv"
	
	rm -rf "$URH_VENV_DIR" "$URH_CLONE_DIR" "$URH_WRAPPER"
	
	git clone https://github.com/PentHertz/urh.git "$URH_CLONE_DIR"
	python3 -m venv "$URH_VENV_DIR"
	
	cd "$URH_CLONE_DIR"
	source "$URH_VENV_DIR/bin/activate"
	
	pip install --upgrade pip setuptools wheel
	pip install cython numpy
	pip install --only-binary=all pyqt5
	pip install psutil
	
	export URH_NO_NATIVE_EXTENSIONS=1
	python3 setup.py install
	
	deactivate
	
	cat > "$URH_WRAPPER" << 'EOF'
#!/bin/bash
URH_VENV_DIR="/opt/urh-venv"
URH_PID_FILE="/tmp/urh_wrapper_$$"

cleanup() {
    if [ -f "$URH_PID_FILE" ]; then
        URH_PID=$(cat "$URH_PID_FILE" 2>/dev/null)
        if [ -n "$URH_PID" ] && kill -0 "$URH_PID" 2>/dev/null; then
            kill "$URH_PID" 2>/dev/null
        fi
        rm -f "$URH_PID_FILE"
    fi
}

trap cleanup EXIT INT TERM

if [ ! -d "$URH_VENV_DIR" ]; then
    echo "Error: URH virtual environment not found"
    exit 1
fi

source "$URH_VENV_DIR/bin/activate"
export LD_LIBRARY_PATH="/usr/lib:$LD_LIBRARY_PATH"

"$URH_VENV_DIR/bin/urh" "$@" &
URH_PID=$!
echo "$URH_PID" > "$URH_PID_FILE"
wait "$URH_PID"
URH_EXIT_CODE=$?

cleanup
deactivate 2>/dev/null
exit $URH_EXIT_CODE
EOF
	
	chmod +x "$URH_WRAPPER"
	return 0
}

function rtl_433_soft_install() {
	goodecho "[+] Building rtl_433 from source"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	
	install_dependencies "cmake build-base libusb-dev"
	
	cmake_clone_and_build "https://github.com/merbanan/rtl_433.git" "build" "" "" "rtl_433_soft_install" -DCMAKE_INSTALL_PREFIX=/usr
}

function qsstv_soft_install() {
	goodecho "[+] Installing dependencies for QSSTV"
	install_dependencies "build-base pkgconf fftw-dev qt5-qtbase-dev alsa-lib-dev pulseaudio-dev openjpeg-dev v4l-utils-dev doxygen"
	
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	gitinstall "https://github.com/ON4QZ/QSSTV.git" "qsstv_soft_install"
	cd QSSTV/
	mkdir -p src/build
	cd src/build
	qmake ..
	make -j$(nproc)
	make install
}

function ice9_bluetooth_soft_install() {
	local ARCH=$(uname -m)
	case "$ARCH" in
		x86_64|amd64|i?86)
			ice9_bluetooth_soft_install_call
			;;
		*)
			criticalecho-noexit "[-] Unsupported architecture: $ARCH"
			;;
	esac
}

function ice9_bluetooth_soft_install_call() {
	goodecho "[+] Installing dependencies for ice9_bluetooth"
	install_dependencies "liquid-dsp-dev fftw-dev"
	
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/mikeryan/ice9-bluetooth-sniffer.git" "build" "" "" "ice9_bluetooth_soft_install" -DCMAKE_INSTALL_PREFIX=/usr
}

function nfclaboratory_soft_install() {
	goodecho "[+] Installing dependencies for nfc-laboratory"
	install_dependencies "libusb-dev cmake build-base"
	
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	gitinstall "https://github.com/josevcm/nfc-laboratory.git" "nfclaboratory_soft_install"
	cmake -DCMAKE_BUILD_TYPE=Release -S nfc-laboratory -B build
	cmake --build build --target nfc-lab -- -j$(nproc)
	cp -r nfc-laboratory/dat/firmware build/src/nfc-app/app-qt/
	
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	mkdir -p /rftools/sdr/nfc-lab
	cp -r /root/thirdparty/build/src/nfc-app/app-qt/ /rftools/sdr/nfc-lab/
	cp -r /root/thirdparty/nfc-laboratory/wav /rftools/sdr/nfc-lab/
	ln -sf /rftools/sdr/nfc-lab/app-qt/nfc-lab /usr/bin/nfc-lab
}

function retrogram_soapysdr_soft_install() {
	goodecho "[+] Installing dependencies for retrogram"
	install_dependencies "ncurses-dev boost-dev"
	
	if ! command -v SoapySDRUtil &> /dev/null; then
		ensure_soapysdr_installed
	fi
	
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://github.com/r4d10n/retrogram-soapysdr.git" "retrogram_soapysdr_soft_install"
	cd retrogram-soapysdr
	make -j$(nproc)
	ln -sf /rftools/sdr/retrogram-soapysdr/retrogram-soapysdr /usr/bin/retrogram-soapysdr
}

function gps_sdr_sim_soft_install() {
	goodecho "[+] Installing gps-sdr-sim"
	install_dependencies "build-base"
	
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://github.com/osqzss/gps-sdr-sim.git" "gps_sdr_sim_soft_install"
	cd gps-sdr-sim
	gcc gpssim.c -lm -O3 -o gps-sdr-sim
	ln -sf /rftools/sdr/gps-sdr-sim/gps-sdr-sim /usr/bin/gps-sdr-sim
	ln -sf /rftools/sdr/gps-sdr-sim/gps-sdr-sim-uhd.py /usr/bin/gps-sdr-sim-uhd.py
}

function acarsdec_soft_install() {
	goodecho "[+] Installing acarsdec dependencies"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	
	install_dependencies "zlib-dev jansson-dev libxml2-dev cmake build-base"
	
	cmake_clone_and_build "https://github.com/szpajder/libacars.git" "build" "" "" "acarsdec_soft_install" -DCMAKE_INSTALL_PREFIX=/usr
	ldconfig 2>/dev/null || true
	
	cmake_clone_and_build "https://github.com/TLeconte/acarsdec.git" "build" "" "" "acarsdec_soft_install" -Drtl=ON -Dairspy=ON -Dsoapy=ON -DCMAKE_INSTALL_PREFIX=/usr
}

function meshtastic_sdr_soft_install() {
	goodecho "[+] Installing Meshtastic_SDR"
	pip3install "meshtastic"
	
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://gitlab.com/crankylinuxuser/meshtastic_sdr.git" "meshtastic_sdr_soft_install"
}

function gpredict_sdr_soft_install() {
	goodecho "[+] Installing GPredict dependencies"
	install_dependencies "libtool intltool autoconf automake curl-dev pkgconf glib-dev gtk+3.0-dev"
	
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	gitinstall "https://github.com/csete/gpredict.git" "gpredict_sdr_soft_install"
	cd gpredict
	./autogen.sh
	./configure
	make -j$(nproc)
	make install
}

function v2verifier_sdr_soft_install() {
	goodecho "[+] Installing v2verifier dependencies"
	install_dependencies "swig gmp-dev python3-dev py3-pip py3-tkinter py3-pillow openssl-dev"
	
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://github.com/FlUxIuS/v2verifier.git" "v2verifier_sdr_soft_install"
	cd v2verifier
	mkdir build
	cd build
	cmake ../
	make -j$(nproc)
}

function wavingz_sdr_soft_install() {
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	
	install_dependencies "cmake build-base"
	
	gitinstall "https://github.com/baol/waving-z.git" "wavingz_sdr_soft_install"
	cd waving-z
	mkdir build
	cd build
	cmake .. -DCMAKE_BUILD_TYPE=Release
	cmake --build .
}

function gqrxscanner_sdr_soft_install() {
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	
	install_dependencies "cmake build-base"
	
	cmake_clone_and_build "https://github.com/neural75/gqrx-scanner.git" "build" "" "" "gqrxscanner_sdr_soft_install" -DCMAKE_INSTALL_PREFIX=/usr
}

function satdump_sdr_soft_install() {
	goodecho "[+] Installing SatDump dependencies"
	install_dependencies "cmake build-base volk-dev fftw-dev libpng-dev tiff-dev curl-dev glfw-dev zenity portaudio-dev hdf5-dev"
	
	ARCH=$(uname -m)
	if [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
		install_dependencies "jemalloc-dev"
	else
		goodecho "[+] Building jemalloc from source for $ARCH"
		[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
		cd /root/thirdparty
		git clone https://github.com/jemalloc/jemalloc.git
		cd jemalloc
		./autogen.sh
		./configure --prefix=/usr
		make
		make install
	fi
	
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	
	cmake_clone_and_build "https://github.com/nanomsg/nng.git" "build" "v1.9.0" "" "satdump_sdr_soft_install" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=/usr
	
	gitinstall "https://github.com/PentHertz/SatDump.git" "satdump_sdr_soft_install"
	cd SatDump
	mkdir build && cd build
	cmake -DCMAKE_BUILD_TYPE=Release -DPLUGIN_HAROGIC_SDR_SUPPORT=ON -DCMAKE_INSTALL_PREFIX=/usr ..
	make -j$(nproc)
	ln -sf ../pipelines .
	ln -sf ../resources .
	ln -sf ../satdump_cfg.json .
	make install
}

function pyspecsdr_sdr_soft_install() {
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	
	gitinstall "https://github.com/xqtr/PySpecSDR.git" "pyspecsdr_sdr_soft_install"
	
	pip3install "pyrtlsdr sounddevice"
}

function luaradio_sdr_soft_install() {
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	
	install_dependencies "luajit liquid-dsp volk-dev fftw-dev pkgconf gnuplot"
	
	gitinstall "https://github.com/hydrasdr/luaradio.git" "luaradio_sdr_soft_install"
	cd luaradio/embed
	make install-lmod
}

function gnss_sdr_soft_install() {
	goodecho "[+] Installing GNSS-SDR tools"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	
	install_dependencies "cmake build-base boost-dev blas-dev lapack-dev armadillo-dev gflags-dev glog-dev openssl-dev libpcap-dev protobuf-dev python3-dev py3-mako"
	
	cmake_clone_and_build "https://github.com/gnss-sdr/gnss-sdr.git" "build" "" "" "gnss_sdr_soft_install" -DCMAKE_INSTALL_PREFIX=/usr
}

function dumpvdl2_soft_install() {
	goodecho "[+] Installing dumpvdl2 tools"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	
	install_dependencies "cmake build-base libxml2-dev jansson-dev zlib-dev"
	
	cmake_clone_and_build "https://github.com/szpajder/libacars.git" "build" "" "" "dumpvdl2_soft_install" -DCMAKE_INSTALL_PREFIX=/usr
	ldconfig 2>/dev/null || true
	
	cmake_clone_and_build "https://github.com/szpajder/dumpvdl2.git" "build" "" "" "dumpvdl2_soft_install" -DCMAKE_INSTALL_PREFIX=/usr
}

function readsb_soft_install() {
	goodecho "[+] Installing readsb software"
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	
	install_dependencies "build-base libusb-dev ncurses-dev zlib-dev"
	
	gitinstall "https://github.com/wiedehopf/readsb.git" "readsb_soft_install"
	cd readsb
	make -j$(nproc)
	ln -sf /rftools/sdr/readsb/readsb /usr/bin/readsb
}

function dump1090_soft_install() {
	goodecho "[+] Installing dump1090 software"
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	
	install_dependencies "build-base libusb-dev"
	
	gitinstall "https://github.com/antirez/dump1090.git" "dump1090_soft_install"
	cd dump1090
	make -j$(nproc)
	ln -sf /rftools/sdr/dump1090/dump1090 /usr/bin/dump1090
}

function ensure_soapysdr_installed() {
	if ! command -v SoapySDRUtil &> /dev/null; then
		goodecho "[+] Building SoapySDR from source"
		
		[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
		cd /root/thirdparty
		
		install_dependencies "cmake build-base"
		
		installfromnet "git clone https://github.com/pothosware/SoapySDR.git"
		cd SoapySDR
		mkdir build
		cd build
		cmake -DCMAKE_INSTALL_PREFIX=/usr ../
		make -j$(nproc)
		make install
		ldconfig 2>/dev/null || true
	fi
}