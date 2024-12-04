#!/bin/bash

function gnuradio_soft_install() {
	goodecho "[+] GNU Radio tools"
	installfromnet "apt-fast install -y gnuradio gnuradio-dev"
}

function sdrangel_soft_install() {
	goodecho "[+] Installing dependencies"
	installfromnet "apt-fast update"
	installfromnet "apt-fast install -y git cmake g++ pkg-config autoconf automake libtool libfftw3-dev libusb-1.0-0-dev libusb-dev libhidapi-dev libopengl-dev"
	installfromnet "apt-fast install -y qtbase5-dev qtchooser libqt5multimedia5-plugins qtmultimedia5-dev libqt5websockets5-dev"
	installfromnet "apt-fast install -y qttools5-dev qttools5-dev-tools libqt5opengl5-dev libqt5quick5 libqt5charts5-dev"
	installfromnet "apt-fast install -y qml-module-qtlocation  qml-module-qtpositioning qml-module-qtquick-window2"
	installfromnet "apt-fast install -y qml-module-qtquick-dialogs qml-module-qtquick-controls qml-module-qtquick-controls2 qml-module-qtquick-layouts"
	installfromnet "apt-fast install -y libqt5serialport5-dev qtdeclarative5-dev qtpositioning5-dev qtlocation5-dev libqt5texttospeech5-dev"
	installfromnet "apt-fast install -y qtwebengine5-dev qtbase5-private-dev libqt5gamepad5-dev libqt5svg5-dev"
	installfromnet "apt-fast install -y libfaad-dev zlib1g-dev libboost-all-dev libasound2-dev pulseaudio libopencv-dev libxml2-dev bison flex"
	installfromnet "apt-fast install -y ffmpeg libavcodec-dev libavformat-dev libopus-dev doxygen graphviz"
	installfromnet "apt-fast install -y libhamlib4 libgl1-mesa-glx qtspeech5-speechd-plugin gstreamer1.0-libav libairspy0"

	goodecho "[+] Downloading and unpacking SDR Angel"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	installfromnet "wget https://github.com/f4exb/sdrangel/releases/download/v7.21.3/sdrangel-2700-master.tar.gz"
	tar xvzf sdrangel-2700-master.tar.gz
	cd sdrangel-2700-master
	dpkg -i sdrangel_7.21.3-1_amd64.deb
	cd /root
}

function sdrangel_soft_fromsource_install() {
	# Check architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]]; then
        criticalecho-noexit "[-] Unsupported architecture: $ARCH"
        exit 0
    fi
    
	goodecho "[+] Installing dependencies"
	installfromnet "apt-fast update"
	installfromnet "apt-fast install -y libsndfile-dev git cmake g++ pkg-config autoconf automake libtool libfftw3-dev libusb-1.0-0-dev libusb-dev libhidapi-dev libopengl-dev qtbase5-dev qtchooser libqt5multimedia5-plugins qtmultimedia5-dev libqt5websockets5-dev qttools5-dev qttools5-dev-tools libqt5opengl5-dev libqt5quick5 libqt5charts5-dev qml-module-qtlocation qml-module-qtpositioning qml-module-qtquick-window2 qml-module-qtquick-dialogs qml-module-qtquick-controls qml-module-qtquick-controls2 qml-module-qtquick-layouts libqt5serialport5-dev qtdeclarative5-dev qtpositioning5-dev qtlocation5-dev libqt5texttospeech5-dev qtwebengine5-dev qtbase5-private-dev libqt5gamepad5-dev libqt5svg5-dev libfaad-dev zlib1g-dev libboost-all-dev libasound2-dev pulseaudio libopencv-dev libxml2-dev bison flex ffmpeg libavcodec-dev libavformat-dev libopus-dev doxygen graphviz"
	goodecho "[+] APT"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/srcejon/aptdec.git" "build" "libaptdec" "" "sdrangel_soft_fromsource_install" -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/aptdec

	goodecho "[+] CM265cc"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/f4exb/cm256cc.git" "build" "" 6f4a51802f5f302577d6d270a9fc0cb7a1ee28ef "sdrangel_soft_fromsource_install" -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/cm256cc

	goodecho "[+] LibDAB"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/srcejon/dab-cmdline" "library/build" "msvc" "" "sdrangel_soft_fromsource_install" -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/libdab

	goodecho "[+] MBElib"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/szechyjs/mbelib.git" "build" "" 9a04ed5c78176a9965f3d43f7aa1b1f5330e771f "sdrangel_soft_fromsource_install" -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/mbelib

	goodecho "[+] serialdv"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/f4exb/serialDV.git" "build" "" "v1.1.4" "sdrangel_soft_fromsource_install" -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/serialdv

	goodecho "[+] DSDcc"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/f4exb/dsdcc.git" "build" "" "v1.9.5" "sdrangel_soft_fromsource_install" \
		-Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/dsdcc -DUSE_MBELIB=ON -DLIBMBE_INCLUDE_DIR=/opt/install/mbelib/include \
		-DLIBMBE_LIBRARY=/opt/install/mbelib/lib/libmbe.so -DLIBSERIALDV_INCLUDE_DIR=/opt/install/serialdv/include/serialdv \
		-DLIBSERIALDV_LIBRARY=/opt/install/serialdv/lib/libserialdv.so

	goodecho "[+] Codec2"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	installfromnet "apt-fast -y install libspeexdsp-dev libsamplerate0-dev"
	cmake_clone_and_build "https://github.com/drowe67/codec2-dev.git" "build" "" "v1.0.3" "sdrangel_soft_fromsource_install"

	goodecho "[+] SGP4"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/dnwrnr/sgp4.git" "build" "" ""  "sdrangel_soft_fromsource_install"-Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/sgp4

	goodecho "[+] libsigmf"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/f4exb/libsigmf.git" "build" "new-namespaces" ""  "sdrangel_soft_fromsource_install"-Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/libsigmf

	goodecho "[+] ggmorse"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/ggerganov/ggmorse.git" "build" "" ""  "sdrangel_soft_fromsource_install"-Wno-dev \
		-DCMAKE_INSTALL_PREFIX=/opt/install/ggmorse -DGGMORSE_BUILD_TESTS=OFF -DGGMORSE_BUILD_EXAMPLES=OFF

	goodecho "[+] Installing SDR Angel"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
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
	ln -s /opt/install/sdrangel/bin/sdrangel /usr/bin/sdrangel
}

function sdrpp_soft_fromsource_install () {
    # Beta test, but should work on almost all platforms
    goodecho "[+] Installing dependencies"
    installfromnet "apt-fast install libfftw3-dev libglfw3-dev libvolk2-dev libzstd-dev libairspyhf-dev libiio-dev libad9361-dev librtaudio-dev libhackrf-dev portaudio19-dev libcodec2-dev -y"
    
    goodecho "[+] Installing SDR++"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    goodecho "[+] Cloning and installing SDR++ project"
    
    # Detect architecture
    ARCH=$(uname -m)
    HAROGIC_FLAG=""
    if [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" || "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
        HAROGIC_FLAG="-DOPT_BUILD_HAROGIC_SOURCE=ON"
    fi
    
    cmake_clone_and_build "https://github.com/AlexandreRouma/SDRPlusPlus.git" "build" "" ""  "sdrpp_soft_fromsource_install" -DOPT_BUILD_SOAPY_SOURCE=ON -DOPT_BUILD_AIRSPY_SOURCE=ON -DOPT_BUILD_AIRSPYHF_SOURCE=ON -DOPT_BUILD_NETWORK_SINK=ON \
        -DOPT_BUILD_FREQUENCY_MANAGER=ON -DOPT_BUILD_IQ_EXPORTER=ON -DOPT_BUILD_RECORDER=ON -DOPT_BUILD_RIGCTL_SERVER=ON -DOPT_BUILD_METEOR_DEMODULATOR=ON $HAROGIC_FLAG \
        -DOPT_BUILD_RADIO=ON -DOPT_BUILD_USRP_SOURCE=ON -DOPT_BUILD_FILE_SOURCE=ON -DOPT_BUILD_HACKRF_SOURCE=ON -DOPT_BUILD_RTL_SDR_SOURCE=ON -DOPT_BUILD_RTL_TCP_SOURCE=ON \
        -DOPT_BUILD_SDRPP_SERVER_SOURCE=ON -DOPT_BUILD_SOAPY_SOURCE=ON -DOPT_BUILD_SPECTRAN_SOURCE=OFF -DOPT_BUILD_SPECTRAN_HTTP_SOURCE=OFF -DOPT_BUILD_LIMESDR_SOURCE=ON \
        -DOPT_BUILD_PLUTOSDR_SOURCE=ON -DOPT_BUILD_BLADERF_SOURCE=ON -DOPT_BUILD_AUDIO_SOURCE=ON -DOPT_BUILD_AUDIO_SINK=ON -DOPT_BUILD_PORTAUDIO_SINK=OFF \
        -DOPT_BUILD_NEW_PORTAUDIO_SINK=OFF -DOPT_BUILD_M17_DECODER=ON -DUSE_BUNDLE_DEFAULTS=ON -DCMAKE_BUILD_TYPE=Release
    
    mkdir -p "/root/Library/Application Support/sdrpp/"
    cp /root/config/sdrpp-config.json "/root/Library/Application Support/sdrpp/config.json"
}

function sdrpp_soft_install () { # Working but not compatible with aarch64
	goodecho "[+] Installing dependencies"
	installfromnet "apt-fast install libfftw3-dev libglfw3-dev libvolk2-dev libzstd-dev libairspyhf-dev libiio-dev libad9361-dev librtaudio-dev libhackrf-dev -y"
	goodecho "[+] Installing SDR++"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	arch=`uname -i`
	prog=""
	case "$arch" in
  		x86_64|amd64)
    		prog="sdrpp_ubuntu_jammy_amd64.deb";;
  		arm*) # For Raspberry Pi for now
    		prog="sdrpp_raspios_bullseye_armhf.deb";;
  		*)
    		printf 'Unsupported architecture: "%s" -> use sdrpp_soft_fromsource_install instead\n' "$arch" >&2; exit 2;;
	esac
	installfromnet "wget https://github.com/AlexandreRouma/SDRPlusPlus/releases/download/nightly/$prog"
	dpkg -i $prog
	cd /root
}

function sigdigger_soft_install () {
	goodecho "[+] Installing dependencies"
	installfromnet "apt-fast install -y libxml2-dev libxml2-utils libfftw3-dev libasound-dev"
	goodecho "[+] Downloading and launching auto-script"
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	installfromnet "wget https://actinid.org/blsd"
	chmod +x blsd
	./blsd
	cd /root
	ln -s /rftools/sdr/blsd-dir/SigDigger/SigDigger /usr/sbin/SigDigger
}

function cyberther_soft_install() {
	goodecho "[+] Installing Cyber Ether"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/catchorg/Catch2.git" "build" "" "" "cyberther_soft_install"

	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	goodecho "[CyberEther][+] Installing core dependencies"
	installfromnet "apt-fast install -y git build-essential cmake pkg-config ninja-build meson git zenity curl"
	goodecho "[CyberEther][+] Installing graphical dependencies"
	installfromnet "apt-fast install -y spirv-cross glslang-tools libglfw3-dev"
	goodecho "[CyberEther][+] Installing backend dependencies"
	installfromnet "apt-fast install -y mesa-vulkan-drivers libvulkan-dev vulkan-validationlayers cargo"
	goodecho "[CyberEther][+] Installing remote caps"
	installfromnet "apt-fast install -y gstreamer1.0-plugins-base libgstreamer-plugins-bad1.0-dev"
	installfromnet "apt-fast install -y libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev"
	installfromnet "apt-fast install -y gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly"
	installfromnet "apt-fast install -y python3-yaml"
	goodecho "[CyberEther][+] Cloning GitHub repository"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
    gitinstall "https://github.com/luigifcruz/CyberEther.git" "cyberther_soft_install"
	cd CyberEther
	meson setup -Dbuildtype=debugoptimized build && cd build
	ninja install
}

function inspectrum_soft_install () {
	goodecho "[+] Installing inspectrum"
	installfromnet "apt-fast install -y inspectrum"
}

function gqrx_soft_install () {
	goodecho "[+] Installing GQRX"
	installfromnet "apt-fast install -y gqrx-sdr"
}

function multimon_ng_soft_install () {
	goodecho "[+] Installing multimon-ng"
	installfromnet "apt-fast install -y multimon-ng"
}

function urh_soft_install () {
	goodecho "[+] Installing URH"
	installfromnet "pip3 install urh"
}

function rtl_433_soft_install () {
	goodecho "[+] Installing rtl_433 tools"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/merbanan/rtl_433.git" "build" "" "" "inspection_decoding_tools"
}

function qsstv_soft_install () {
	goodecho "[+] Installing dependencies for qsstv_soft_install"
	installfromnet "apt-fast install -y pkg-config g++ libfftw3-dev qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools libhamlib++-dev libasound2-dev libpulse-dev libopenjp2-7 libopenjp2-7-dev libv4l-dev build-essential doxygen libqwt-qt5-dev"
	goodecho "[+] Cloning QSSTV"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	gitinstall "https://github.com/ON4QZ/QSSTV.git" "qsstv_soft_install"
	cd QSSTV/
	mkdir src/build
	cd src/build
	qmake ..
	make -j$(nproc)
	sudo make install
}

function ice9_bluetooth_soft_install() {
    local ARCH=$(uname -m)

    case "$ARCH" in
        x86_64|amd64)
            ice9_bluetooth_soft_install_call
            ;;
        i?86)
            ice9_bluetooth_soft_install_call
            ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $ARCH. ice9_bluetooth installation is not supported on this architecture."
            ;;
    esac
}

function ice9_bluetooth_soft_install_call () {
	goodecho "[+] Installing dependencies for ice9_bluetooth"
	installfromnet "apt-fast install -y libliquid-dev libhackrf-dev libbladerf-dev libuhd-dev libfftw3-dev"
	goodecho "[+] Cloning ice9-bluetooth-sniffer"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/mikeryan/ice9-bluetooth-sniffer.git" "build" "" "" "inspection_decoding_tools"
}

function nfclaboratory_soft_install () {
	goodecho "[+] Installing dependencies for nfc-laboratory"
	installfromnet "apt-fast install -y libusb-1.0-0"
	goodecho "[+] Installing nfc-laboratory"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	gitinstall "https://github.com/josevcm/nfc-laboratory.git" "nfclaboratory_soft_install"
	cmake -DCMAKE_BUILD_TYPE=Release -S nfc-laboratory -B build
	cmake --build build --target nfc-spy -- -j$(nproc)
	cp -r nfc-laboratory/dat/firmware build/src/nfc-app/app-qt/
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	mkdir nfc-lab
	cd nfc-lab
	cp -r /root/thirdparty/build/src/nfc-app/app-qt/ .
	ln -s /rftools/sdr/nfc-lab/app-qt/nfc-spy /usr/bin/nfc-spy
}

function retrogram_soapysdr_soft_install () {
	goodecho "[+] Installing dependencies for retrogram"
	installfromnet "apt-fast install -y libsoapysdr-dev libncurses5-dev libboost-program-options-dev"
	goodecho "[+] Installing retrogram_soapysdr"
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://github.com/r4d10n/retrogram-soapysdr.git" "retrogram_soapysdr_soft_install"
	cd retrogram-soapysdr
	make -j$(nproc)
	ln -s /rftool/sdr/retrogram-soapysdr/retrogram-soapysdr /usr/bin/retrogram-soapysdr
}

function gps_sdr_sim_soft_install () {
	goodecho "[+] Installing gps-sdr-sim"
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://github.com/osqzss/gps-sdr-sim.git" "gps_sdr_sim_soft_install"
	cd gps-sdr-sim
	gcc gpssim.c -lm -O3 -o gps-sdr-sim
	ln -s /rftool/sdr/gps-sdr-sim/gps-sdr-sim /usr/bin/gps-sdr-sim
}

function acarsdec_soft_install () {
	goodecho "[+] Installing acarsdec dependencies"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	installfromnet "apt-fast install -y zlib1g-dev libjansson-dev libxml2-dev"
	cmake_clone_and_build "https://github.com/szpajder/libacars.git" "build"
	ldconfig

	goodecho "[+] Installing acarsdec"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/TLeconte/acarsdec.git" "build" "" "" "acarsdec_soft_install" -Drtl=ON -Dairspy=ON -Dsoapy=ON
}

function meshtastic_sdr_soft_install () {
	goodecho "[+] Installing Meshtastic_SDR dependencies"
	installfromnet "pip3 install meshtastic"
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	goodecho "[+] Cloning Meshtastic_SDR"
	gitinstall "https://gitlab.com/crankylinuxuser/meshtastic_sdr.git" "meshtastic_sdr_soft_install"
}

function gpredict_sdr_soft_install () {
	goodecho "[+] Installing GPredict dependencies"
	installfromnet "apt-fast install -y libtool intltool autoconf automake libcurl4-openssl-dev pkg-config libglib2.0-dev libgtk-3-dev libgoocanvas-2.0-dev"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	goodecho "[+] Cloning Meshtastic_SDR"
	gitinstall "https://github.com/csete/gpredict.git" "gpredict_sdr_soft_install"
	cd gpredict
	./autogen.sh
	./configure
	make -j$(nproc)
	make install
}

function v2verifier_sdr_soft_install () {
	goodecho "[+] Installing v2verifier dependencies"
	installfromnet "apt-fast install -y swig libgmp3-dev python3-pip python3-tk python3-pil libssl-dev python3-pil.imagetk"
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	goodecho "[+] Cloning v2verifier"
	gitinstall "https://github.com/FlUxIuS/v2verifier.git" "v2verifier_sdr_soft_install"
	cd v2verifier
	mkdir build
	cd build
	cmake ../
	make -j$(nproc)
}

function wavingz_sdr_soft_install () {
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	goodecho "[+] Cloning waving-z"
	gitinstall "https://github.com/baol/waving-z.git" "wavingz_sdr_soft_install"
	cd waving-z
	mkdir build
	cd build
	cmake .. -DCMAKE_BUILD_TYPE=Release
	cmake --build .
}

function gqrxscanner_sdr_soft_install () {
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	goodecho "[+] Cloning and installing gqrx-scanner"
	cmake_clone_and_build "https://github.com/neural75/gqrx-scanner.git" "build" "" "" "gqrxscanner_sdr_soft_install"
}

function satdump_sdr_soft_install () {
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	goodecho "[+] installing dependencies for SatDump"
	install_dependencies "libvolk2-dev git build-essential cmake g++ pkgconf libfftw3-dev libpng-dev libtiff-dev libcurl4-openssl-dev libglfw3-dev zenity portaudio19-dev libhdf5-dev libomp-dev ocl-icd-opencl-dev"
	# Check system architecture
	ARCH=$(uname -m)

	if [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
	    goodecho "Architecture is $ARCH. Installing jemalloc from package manager..."
	    install_dependencies "libjemalloc-dev"
	else
	    goodecho "Architecture is $ARCH. Installing jemalloc from source..."
	    # Clone and build jemalloc
	    git clone https://github.com/jemalloc/jemalloc.git
	    cd jemalloc
	    ./autogen.sh
	    ./configure --prefix=/usr
	    make
	    sudo make install
	    # Clean up
	    cd ..
	    rm -rf jemalloc
	    goodecho "[+] jemalloc installed from source."
	fi

	cmake_clone_and_build "https://github.com/nanomsg/nng.git" "build" "" "" "satdump_sdr_soft_install" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=/usr
	goodecho "[+] Cloning and installing SatDump"
	gitinstall "https://github.com/SatDump/SatDump.git" "SatDump"
	cd SatDump
	mkdir build && cd build
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr ..
	make -j`nproc`
	ln -s ../pipelines .
	ln -s ../resources .
	ln -s ../satdump_cfg.json .
	make install
}

function pyspecsdr_sdr_soft_install () {
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	goodecho "[+] Cloning and installing PySpecSDR"
	gitinstall "https://github.com/xqtr/PySpecSDR.git" "PySpecSDR"
	goodecho "[+] Installing Python dependencies"
	installfromnet "pip3 install pyrtlsdr"
	installfromnet "pip3 install sounddevice"
}