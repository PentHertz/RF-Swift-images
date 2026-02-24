#!/bin/bash

function gnuradio_soft_install() {
	goodecho "[+] GNU Radio tools"
	install_dependencies "gnuradio gnuradio-dev"
}

function sdrangel_soft_install() {
	goodecho "[+] Installing dependencies"
	installfromnet "apt-fast update"
	install_dependencies "git cmake g++ pkg-config autoconf automake libtool libfftw3-dev libusb-1.0-0-dev libusb-dev libhidapi-dev libopengl-dev"
	install_dependencies "qtbase5-dev qtchooser libqt5multimedia5-plugins qtmultimedia5-dev libqt5websockets5-dev"
	install_dependencies "qttools5-dev qttools5-dev-tools libqt5opengl5-dev libqt5quick5 libqt5charts5-dev"
	install_dependencies "qml-module-qtlocation  qml-module-qtpositioning qml-module-qtquick-window2"
	install_dependencies "qml-module-qtquick-dialogs qml-module-qtquick-controls qml-module-qtquick-controls2 qml-module-qtquick-layouts"
	install_dependencies "libqt5serialport5-dev qtdeclarative5-dev qtpositioning5-dev qtlocation5-dev libqt5texttospeech5-dev"
	install_dependencies "qtwebengine5-dev qtbase5-private-dev libqt5gamepad5-dev libqt5svg5-dev"
	install_dependencies "libfaad-dev zlib1g-dev libboost-all-dev libasound2-dev pulseaudio libopencv-dev libxml2-dev bison flex"
	install_dependencies "ffmpeg libavcodec-dev libavformat-dev libopus-dev doxygen graphviz"
	install_dependencies "libhamlib4 libgl1-mesa-glx qtspeech5-speechd-plugin gstreamer1.0-libav libairspy0"

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
	install_dependencies "libsndfile-dev git cmake g++ pkg-config autoconf automake libtool libfftw3-dev libusb-1.0-0-dev libusb-dev libhidapi-dev libopengl-dev qtbase5-dev qtchooser libqt5multimedia5-plugins qtmultimedia5-dev libqt5websockets5-dev qttools5-dev qttools5-dev-tools libqt5opengl5-dev libqt5quick5 libqt5charts5-dev qml-module-qtlocation qml-module-qtpositioning qml-module-qtquick-window2 qml-module-qtquick-dialogs qml-module-qtquick-controls qml-module-qtquick-controls2 qml-module-qtquick-layouts libqt5serialport5-dev qtdeclarative5-dev qtpositioning5-dev qtlocation5-dev libqt5texttospeech5-dev qtwebengine5-dev qtbase5-private-dev libqt5gamepad5-dev libqt5svg5-dev libfaad-dev zlib1g-dev libboost-all-dev libasound2-dev pulseaudio libopencv-dev libxml2-dev bison flex ffmpeg libavcodec-dev libavformat-dev libopus-dev doxygen graphviz"
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
	install_dependencies "libspeexdsp-dev libsamplerate0-dev"
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
    install_dependencies "libfftw3-dev libglfw3-dev libvolk-dev libzstd-dev libairspyhf-dev libiio-dev libad9361-dev librtaudio-dev libhackrf-dev portaudio19-dev libcodec2-dev -y"
    
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
    
    cmake_clone_and_build "https://github.com/hydrasdr/SDRPlusPlus.git" "build" "" ""  "sdrpp_soft_fromsource_install" -DOPT_BUILD_HYDRASDR_SOURCE=ON -DOPT_BUILD_SOAPY_SOURCE=ON -DOPT_BUILD_AIRSPY_SOURCE=ON -DOPT_BUILD_AIRSPYHF_SOURCE=ON -DOPT_BUILD_NETWORK_SINK=ON \
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
	install_dependencies "libfftw3-dev libglfw3-dev libvolk2-dev libzstd-dev libairspyhf-dev libiio-dev libad9361-dev librtaudio-dev libhackrf-dev -y"
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
	install_dependencies "libxml2-dev libxml2-utils libfftw3-dev libasound-dev"
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
	install_dependencies "git build-essential cmake pkg-config ninja-build meson git zenity curl"
	goodecho "[CyberEther][+] Installing graphical dependencies"
	install_dependencies "spirv-cross glslang-tools libglfw3-dev"
	goodecho "[CyberEther][+] Installing backend dependencies"
	install_dependencies "mesa-vulkan-drivers libvulkan-dev vulkan-validationlayers cargo"
	goodecho "[CyberEther][+] Installing remote caps"
	install_dependencies "gstreamer1.0-plugins-base libgstreamer-plugins-bad1.0-dev"
	install_dependencies "libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev"
	install_dependencies "gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly"
	install_dependencies "python3-yaml"
	goodecho "[CyberEther][+] Cloning GitHub repository"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
    #gitinstall "https://github.com/FlUxIuS/CyberEther.git" "cyberther_soft_install" // TODO: broken for now check later
    installfromnet "wget https://github.com/luigifcruz/CyberEther/archive/refs/tags/v1.0.0-alpha5.zip"
    unzip v1.0.0-alpha5.zip
	cd CyberEther-1.0.0-alpha5/
	meson setup -Dbuildtype=debugoptimized build && cd build
	ninja install
}

function inspectrum_soft_install () {
	goodecho "[+] Installing inspectrum"
	install_dependencies "inspectrum"
}

function gqrx_soft_install () {
	goodecho "[+] Installing GQRX"
	install_dependencies "gqrx-sdr"
}

function multimon_ng_soft_install () {
	goodecho "[+] Installing multimon-ng"
	install_dependencies "multimon-ng"
}

function urh_soft_pip_install() {
    goodecho "[+] Installing URH"
    # Check if architecture is riscv64 and skip if it is
    if [ "$(uname -m)" = "riscv64" ]; then
        criticalecho-noexit "[!] Skipping URH installation on RISCV64 architecture"
        return 0
    fi
    apt remove libhackrf-dev -y # remove temporarly this for URH compilation TODO: find another clean way
   	pip3install urh
   	install_dependencies "libhackrf-dev"
}


function urh_soft_install() {
    goodecho "[+] Installing URH from HydraSDR fork"
    [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    cd /root/thirdparty
    install_dependencies "qt6-base-dev libgl1-mesa-dev libxkbcommon-x11-0 libegl1 libxcb-cursor0 python3-pyqt6 python3-pyqt6.sip python3-pyqt6.qtsvg pyqt6-dev-tools"
    ARCH=$(uname -m)
    VERSION_URH="2.10.0"
    GITBUILD="git20260206.3909e27"
    case "$ARCH" in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        riscv64) 
            ARCH="riscv64"
            ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $ARCH"
            return 0
            ;;
    esac
    # Use curly braces to properly delimit variable names
    FILENAME="urh-penthertz_${ARCH}_${VERSION_URH}+${GITBUILD}.deb"
    installfromnet "wget https://github.com/PentHertz/urh-2/releases/download/v$VERSION_URH/$FILENAME"
    dpkg -i $FILENAME
}

function urh_soft_install_2_9_8() {
    goodecho "[+] Installing URH from HydraSDR fork"
    [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    cd /root/thirdparty
    ARCH=$(uname -m)
    VERSION_URH="2.9.8"
    GITBUILD="git20260119.d528343"
    case "$ARCH" in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        riscv64)
            ARCH="riscv64"
            ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $ARCH"
            return 0
            ;;
    esac
    # Use curly braces to properly delimit variable names
    FILENAME="urh-penthertz_${ARCH}_${VERSION_URH}+${GITBUILD}.deb"
    installfromnet "wget https://github.com/PentHertz/urh/releases/download/v$VERSION_URH/$FILENAME"
    dpkg -i $FILENAME
}

function urh_soft_install_fromsource() {
    goodecho "[+] Installing URH from HydraSDR fork"

    # Check if architecture is riscv64 and skip if it is
    if [ "$(uname -m)" = "riscv64" ]; then
        criticalecho-noexit "[!] Skipping URH installation on RISCV64 architecture"
        return 0
    fi

    # Define paths
    URH_VENV_DIR="/opt/urh-venv"
    URH_CLONE_DIR="/opt/urh-hydrasdr"
    URH_WRAPPER="/usr/sbin/urh"

    # Install system dependencies
    apt update
    apt remove libhackrf-dev -y # remove temporarily for URH compilation
    install_dependencies "python3-venv python3-dev build-essential git cython3 libxml2-dev libxslt1-dev zlib1g-dev"

    # Clean up any existing installation
    rm -rf "$URH_VENV_DIR" "$URH_CLONE_DIR" "$URH_WRAPPER"

    # Clone HydraSDR URH fork
    goodecho "[+] Cloning HydraSDR/Penthertz URH fork"
    git clone https://github.com/PentHertz/urh.git "$URH_CLONE_DIR"
    if [ $? -ne 0 ]; then
        criticalecho "[!] Failed to clone URH repository"
        return 1
    fi

    # Create virtual environment
    goodecho "[+] Creating Python virtual environment"
    python3 -m venv "$URH_VENV_DIR"
    if [ $? -ne 0 ]; then
        criticalecho "[!] Failed to create virtual environment"
        return 1
    fi

    # Install URH in the virtual environment
    goodecho "[+] Installing URH dependencies and building"
    cd "$URH_CLONE_DIR"

    # Activate venv and install
    source "$URH_VENV_DIR/bin/activate"

    # Upgrade pip and install build dependencies
    pip install --upgrade pip setuptools wheel
    pip install "cython" "numpy"
    pip install --only-binary=all pyqt5
    pip install "psutil"
    # Try to install URH
    python3 setup.py install
    URH_INSTALL_STATUS=$?

    # If Cython build fails, try without native extensions
    if [ $URH_INSTALL_STATUS -ne 0 ]; then
        goodecho "[+] Cython build failed, trying without native extensions"
        export URH_NO_NATIVE_EXTENSIONS=1
        python3 setup.py install
        URH_INSTALL_STATUS=$?
    fi

    deactivate

    if [ $URH_INSTALL_STATUS -ne 0 ]; then
        criticalecho "[!] Failed to install URH"
        return 1
    fi

    # Create wrapper script
    goodecho "[+] Creating URH wrapper script"
    cat > "$URH_WRAPPER" << 'EOF'
#!/bin/bash
# URH Wrapper Script - Auto-activates venv

URH_VENV_DIR="/opt/urh-venv"

# Check if virtual environment exists
if [ ! -d "$URH_VENV_DIR" ]; then
    echo "Error: URH virtual environment not found at $URH_VENV_DIR"
    exit 1
fi

# Check if URH is installed in the venv
if [ ! -f "$URH_VENV_DIR/bin/urh" ]; then
    echo "Error: URH not found in virtual environment"
    exit 1
fi

# Fix XDG_RUNTIME_DIR warning if not set
if [ -z "$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR="/tmp/runtime-$(whoami)"
    mkdir -p "$XDG_RUNTIME_DIR"
    chmod 700 "$XDG_RUNTIME_DIR"
fi

# Activate venv and run URH
source "$URH_VENV_DIR/bin/activate"
echo "Starting URH (HydraSDR fork)..."
exec "$URH_VENV_DIR/bin/urh" "$@"
EOF

    # Make wrapper executable
    chmod +x "$URH_WRAPPER"

    # Set proper ownership
    chown root:root "$URH_WRAPPER"
    chown -R root:root "$URH_VENV_DIR" "$URH_CLONE_DIR"

    # Restore libhackrf-dev
    install_dependencies "libhackrf-dev"

    return 0
}

function rtl_433_soft_install () {
	goodecho "[+] Installing rtl_433 tools"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/merbanan/rtl_433.git" "build" "" "" "inspection_decoding_tools"
}

function qsstv_soft_install () {
	goodecho "[+] Installing dependencies for qsstv_soft_install"
	install_dependencies "pkg-config g++ libfftw3-dev qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools libhamlib++-dev libasound2-dev libpulse-dev libopenjp2-7 libopenjp2-7-dev libv4l-dev build-essential doxygen libqwt-qt5-dev"
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
	install_dependencies "libliquid-dev libhackrf-dev libbladerf-dev libuhd-dev libfftw3-dev xxd"
	goodecho "[+] Cloning ice9-bluetooth-sniffer"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/mikeryan/ice9-bluetooth-sniffer.git" "build" "" "" "inspection_decoding_tools"
}

function nfclaboratory_soft_install () {
	goodecho "[+] Installing dependencies for nfc-laboratory"
	install_dependencies "libusb-1.0-0"
	goodecho "[+] Installing nfc-laboratory"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	gitinstall "https://github.com/josevcm/nfc-laboratory.git" "nfclaboratory_soft_install"
	cmake -DCMAKE_BUILD_TYPE=Release -S nfc-laboratory -B build
	cmake --build build --target nfc-lab -- -j$(nproc)
	cp -r nfc-laboratory/dat/firmware build/src/nfc-app/app-qt/
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	mkdir nfc-lab
	cd nfc-lab
	cp -r /root/thirdparty/build/src/nfc-app/app-qt/ .
	cp -r /root/thirdparty/nfc-laboratory/wav .
	ln -s /rftools/sdr/nfc-lab/app-qt/nfc-lab /usr/bin/nfc-lab
}

function retrogram_soapysdr_soft_install () {
	goodecho "[+] Installing dependencies for retrogram"
	install_dependencies "libsoapysdr-dev libncurses5-dev libboost-program-options-dev"
	goodecho "[+] Installing retrogram_soapysdr"
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://github.com/r4d10n/retrogram-soapysdr.git" "retrogram_soapysdr_soft_install"
	cd retrogram-soapysdr
	make -j$(nproc)
	ln -s /rftools/sdr/retrogram-soapysdr/retrogram-soapysdr /usr/bin/retrogram-soapysdr
}

function gps_sdr_sim_soft_install () {
	goodecho "[+] Installing gps-sdr-sim"
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://github.com/osqzss/gps-sdr-sim.git" "gps_sdr_sim_soft_install"
	cd gps-sdr-sim
	gcc gpssim.c -lm -O3 -o gps-sdr-sim
	ln -s /rftools/sdr/gps-sdr-sim/gps-sdr-sim /usr/bin/gps-sdr-sim
	ln -s /rftools/sdr/gps-sdr-sim/gps-sdr-sim-uhd.py /usr/bin/gps-sdr-sim-uhd.py
}

function acarsdec_soft_install () {
	goodecho "[+] Installing acarsdec dependencies"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	install_dependencies "zlib1g-dev libjansson-dev libxml2-dev"
	cmake_clone_and_build "https://github.com/szpajder/libacars.git" "build"
	ldconfig

	goodecho "[+] Installing acarsdec"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/TLeconte/acarsdec.git" "build" "" "" "acarsdec_soft_install" -Drtl=ON -Dairspy=ON -Dsoapy=ON
}

function meshtastic_sdr_soft_install () {
	goodecho "[+] Installing Meshtastic_SDR dependencies"
	pip3install "meshtastic"
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	goodecho "[+] Cloning Meshtastic_SDR"
	gitinstall "https://gitlab.com/crankylinuxuser/meshtastic_sdr.git" "meshtastic_sdr_soft_install"
}

function gpredict_sdr_soft_install () {
	goodecho "[+] Installing GPredict dependencies"
	install_dependencies "libtool intltool autoconf automake libcurl4-openssl-dev pkg-config libglib2.0-dev libgtk-3-dev libgoocanvas-2.0-dev"
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
	install_dependencies "swig libgmp3-dev python3-pip python3-tk python3-pil libssl-dev python3-pil.imagetk"
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
	install_dependencies "libvolk2-dev libmbedtls-dev git build-essential cmake g++ pkgconf libfftw3-dev libpng-dev libtiff-dev libcurl4-openssl-dev libglfw3-dev zenity portaudio19-dev libhdf5-dev libomp-dev ocl-icd-opencl-dev"
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

	cmake_clone_and_build "https://github.com/nanomsg/nng.git" "build" "v1.9.0" "" "satdump_sdr_soft_install" -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=/usr
	goodecho "[+] Cloning and installing SatDump"
	gitinstall "https://github.com/PentHertz/SatDump.git" "SatDump"
	cd SatDump
	mkdir build && cd build
	cmake -DCMAKE_BUILD_TYPE=Release -DPLUGIN_HAROGIC_SDR_SUPPORT=ON -DCMAKE_INSTALL_PREFIX=/usr ..
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
	pip3install "pyrtlsdr"
	pip3install "sounddevice"
}

function luaradio_sdr_soft_install () {
	if [[ "$ARCH" == "x86_64" ]] || [[ "$ARCH" == "amd64" ]] || [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
		[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
		cd /rftools/sdr
		goodecho "[+] Cloning and installing luaradio"
		gitinstall "https://github.com/hydrasdr/luaradio.git" "luaradio"
		goodecho "[+] Installing Luaradio dependencies"
		install_dependencies "luajit libliquid-dev libvolk-dev libfftw3-dev libluajit-5.1-dev pkg-config gnuplot"
		goodecho "[+] Compiing Luaradio apps"
		cd luaradio/embed
		sudo make install-lmod
	fi
}

function gnss_sdr_soft_install () {
	goodecho "[+] Installing GNSS-SDR tools"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	install_dependencies "pkg-config libboost-dev libboost-date-time-dev"
    install_dependencies "libboost-system-dev libboost-filesystem-dev libboost-thread-dev libboost-chrono-dev"
    install_dependencies "libboost-serialization-dev liblog4cpp5-dev"
    install_dependencies "libblas-dev liblapack-dev libarmadillo-dev libgflags-dev libgoogle-glog-dev"
    install_dependencies "libssl-dev libpcap-dev libmatio-dev libpugixml-dev libgtest-dev"
    install_dependencies "libprotobuf-dev libcpu-features-dev protobuf-compiler python3-mako"
	cmake_clone_and_build "https://github.com/gnss-sdr/gnss-sdr.git" "build" "" "" "gnss_sdr_soft_install"
}

function dumpvdl2_soft_install () {
	goodecho "[+] Installing dumpvdl2 tools"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/szpajder/libacars.git" "build" "" "" "install_libacars"
	cmake_clone_and_build "https://github.com/szpajder/dumpvdl2.git" "build" "" "" "dumpvdl2_soft_install"
}

function readsb_soft_install () {
	goodecho "[+] Installing readsb software"
	[ -d /rftools/sdr ] || mkdir /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://github.com/wiedehopf/readsb.git" "readsb"
	cd readsb
	make -j$(nproc)
	ln -s readsb /usr/bin/readsb
}

function dump1090_soft_install () {
	goodecho "[+] Installing dump1090 software"
	[ -d /rftools/sdr ] || mkdir /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://github.com/antirez/dump1090.git" "dump1090"
	cd dump1090
	make -j$(nproc)
	ln -s dump1090 /usr/bin/dump1090
}

function dumphfdl_soft_install () {
	goodecho "[+] Installing dumphfdl tools"
	install_dependencies "build-essential cmake pkg-config libglib2.0-dev libconfig++-dev libliquid-dev libfftw3-dev libsqlite3-dev libzmq3-dev"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/szpajder/dumphfdl.git" "build" "" "" "dumphfdl_soft_install"
}

function qradiolink_soft_install () {
	goodecho "[+] Installing qradiolink"
	install_dependencies "libftdi1-dev libftdi-dev libusb-1.0-0-dev libzmq3-dev cppzmq-dev"
	install_dependencies "qtmultimedia5-dev libqt5multimedia5-plugins"
	install_dependencies "libspeex-dev libspeexdsp-dev libcodec2-dev libopus-dev libpulse-dev libasound2-dev portaudio19-dev libsndfile1-dev libvorbis-dev libflac-dev libftdi1-dev gnuradio-dev gr-osmosdr libvolk-dev libboost-all-dev libconfig++-dev libprotobuf-dev protobuf-compiler libsamplerate0-dev libjpeg-dev"
	[ -d /rftools/sdr ] || mkdir /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://codeberg.org/qradiolink/qradiolink" "qradiolink_soft_install"
	cd qradiolink
	sh ./build_debian.sh
	ln -s $(pwd)/build/qradiolink /usr/local/bin/qradiolink
}

function AIScatcher_soft_install () {
	goodecho "[+] Installing AIS Catcher"
	[ -d /rftools/sdr ] || mkdir /rftools/sdr
	cd /rftools/sdr
	cmake_clone_and_build "https://github.com/jvde-github/AIS-catcher.git" "build" "" "" "AIScatcher_soft_install"
}

function tetrakit_soft_install () {
	goodecho "[+] Installing tetra-kit"
	[ -d /rftools/sdr ] || mkdir /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://gitlab.com/larryth/tetra-kit.git" "tetrakit_soft_install"
	cd tetra-kit
	install_dependencies "rapidjson-dev"
	./build.sh 
	ln -s $(pwd)/decoder/decoder /usr/local/bin/tetra-kit-decoder
	ln -s $(pwd)/decoder/recorder /usr/local/bin/tetra-kit-recorder
}

function tetrakitplayer_soft_install () {
	goodecho "[+] Installing tetra-kit-player"
	[ -d /rftools/sdr ] || mkdir /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://github.com/sonictruth/tetra-kit-player.git" "tetrakitplayer_soft_install"
}

function tetra_suite_install () {
    goodecho "[+] Installing Complete TETRA Suite"
    
    # Install all dependencies in one go
    local deps="git build-essential cmake libtool autoconf automake pkg-config \
                libtalloc-dev libpcsclite-dev libsctp-dev libusb-1.0-0-dev \
                libncurses5-dev libsqlite3-dev libglib2.0-dev rtl-sdr librtlsdr-dev \
                sox python3 python3-pip libosmocore-dev"
    install_dependencies "$deps"
    
    [ -d /rftools/sdr ] || mkdir -p /rftools/sdr
    
    # Install libosmo-dsp
    goodecho "[+] Installing libosmo-dsp"
    cd /tmp
    if [ ! -f "/usr/local/lib/libosmosdr.so" ]; then
        installfromnet "git clone --depth 1 https://github.com/osmocom/libosmo-dsp.git"
        cd libosmo-dsp
        autoreconf -fi
        ./configure --prefix=/usr/local
        make -j$(nproc)
        sudo make install
        sudo ldconfig
        cd /tmp
        rm -rf libosmo-dsp
    fi
    
    # Install osmo-tetra (sq5bpf fork with telive integration, SDS parsing, UDP streaming, AFC)
    goodecho "[+] Installing osmo-tetra (sq5bpf fork)"
    cd /rftools/sdr
    gitinstall "https://github.com/sq5bpf/osmo-tetra-sq5bpf.git" "tetra_suite_install"
    cd osmo-tetra-sq5bpf/src
    make -j$(nproc)
    cd ../..
    
    # Install telive
    goodecho "[+] Installing telive"
    cd /rftools/sdr
    gitinstall "https://github.com/sq5bpf/telive.git" "tetra_suite_install"
    cd telive
    make -j$(nproc)
    
    # Clone ACELP codec installer (not built — user runs it manually due to ETSI licensing)
    goodecho "[+] Cloning TETRA ACELP codec installer (run 'install-tetra-codec' to enable voice decoding)"
    cd /rftools/sdr
    gitinstall "https://github.com/sq5bpf/install-tetra-codec.git" "tetra_suite_install"
    
    # Create symlinks
    sudo mkdir -p /usr/local/bin /usr/local/share/doc
    sudo ln -sf /rftools/sdr/osmo-tetra-sq5bpf/src/tetra-rx /usr/local/bin/tetra-rx
    sudo ln -sf /rftools/sdr/osmo-tetra-sq5bpf/src/float_to_bits /usr/local/bin/float_to_bits
    sudo ln -sf /rftools/sdr/telive/telive /usr/local/bin/telive
    sudo ln -sf /rftools/sdr/telive/telive_doc.txt /usr/local/share/doc/telive.txt
    sudo ln -sf /rftools/sdr/install-tetra-codec/install.sh /usr/local/bin/install-tetra-codec
    
    goodecho "[+] TETRA Suite installation complete (voice codec not included, run 'install-tetra-codec' to enable)"
}

function op25_soft_install () {
	goodecho "[+] Installing op25"
	[ -d /rftools/sdr ] || mkdir /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://github.com/boatbod/op25.git" "op25_soft_install"
	cd op25
	yes | ./install || true
}

function trunkrecorder_soft_install () {
	goodecho "[+] Installing trunk-recorder"
	[ -d /rftools/sdr ] || mkdir /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://github.com/TrunkRecorder/trunk-recorder.git" "trunkrecorder_soft_install"
	cd trunk-recorder
	yes | ./install || true
}

function trunkrecorder_soft_install () {
	goodecho "[+] Installing trunk-recorder"
	[ -d /rftools/sdr ] || mkdir /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://github.com/TrunkRecorder/trunk-recorder.git" "trunkrecorder_soft_install"
	cd trunk-recorder
	yes | ./install || true
}

function intercept_soft_install () {
	goodecho "[+] Installing intercept"
	[ -d /rftools/sdr ] || mkdir /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://github.com/smittix/intercept.git" "intercept_soft_install"
	cd intercept
	./setup.sh
}

function web_spectrum_soft_install () {
	goodecho "[+] Installing web-spectrum"
	install_dependencies "nodejs nodejs"
	[ -d /rftools/sdr ] || mkdir /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://github.com/meshuga/web-spectrum.git" "web_spectrum_soft_install"
	cd web-spectrum
	npm install
	pip3install -r requirements.txt
}


function hydrasdr433_soft_install() {
	goodecho "[+] Installing hydrasdr_433"
	cmake_clone_and_build "https://github.com/hydrasdr/hydrasdr_433.git" "build" "" "" "hydrasdr433_soft__install" || true
}