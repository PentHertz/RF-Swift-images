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
    gitinstall "https://github.com/luigifcruz/CyberEther.git" "cyberther_soft_install"
	cd CyberEther
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

# URH Wrapper Script - Auto-activates venv and handles cleanup
URH_VENV_DIR="/opt/urh-venv"
URH_PID_FILE="/tmp/urh_wrapper_$$"

# Function to cleanup on exit
cleanup() {
    # Kill any remaining URH processes started by this wrapper
    if [ -f "$URH_PID_FILE" ]; then
        URH_PID=$(cat "$URH_PID_FILE" 2>/dev/null)
        if [ -n "$URH_PID" ] && kill -0 "$URH_PID" 2>/dev/null; then
            kill "$URH_PID" 2>/dev/null
        fi
        rm -f "$URH_PID_FILE"
    fi
}

# Set up signal handlers for cleanup
trap cleanup EXIT INT TERM

# Check if virtual environment exists
if [ ! -d "$URH_VENV_DIR" ]; then
    echo "Error: URH virtual environment not found at $URH_VENV_DIR"
    echo "Please reinstall URH or run the installation script again."
    exit 1
fi

# Check if URH is installed in the venv
if [ ! -f "$URH_VENV_DIR/bin/urh" ]; then
    echo "Error: URH not found in virtual environment"
    echo "Please reinstall URH or run the installation script again."
    exit 1
fi

# Activate the virtual environment
source "$URH_VENV_DIR/bin/activate"

# Add HydraSDR library path if it exists
if [ -d "/usr/lib" ]; then
    export LD_LIBRARY_PATH="/usr/lib:$LD_LIBRARY_PATH"
fi
if [ -d "/lib" ]; then
    export LD_LIBRARY_PATH="/lib:$LD_LIBRARY_PATH"
fi

# Run URH with all passed arguments
echo "Starting URH (HydraSDR fork) in virtual environment..."
"$URH_VENV_DIR/bin/urh" "$@" &
URH_PID=$!

# Store PID for cleanup
echo "$URH_PID" > "$URH_PID_FILE"

# Wait for URH to finish
wait "$URH_PID"
URH_EXIT_CODE=$?

# Cleanup
cleanup

# Deactivate virtual environment (though it should happen automatically)
deactivate 2>/dev/null

echo "URH exited with code $URH_EXIT_CODE"
exit $URH_EXIT_CODE
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
	[ -d /rftools/sdr ] || mkdir -p /rftools/sdr
	cd /rftools/sdr
	goodecho "[+] Cloning and installing luaradio"
	gitinstall "https://github.com/hydrasdr/luaradio.git" "luaradio"
	goodecho "[+] Installing Luaradio dependencies"
	install_dependencies "luajit libliquid-dev libvolk2-dev libfftw3-dev libluajit-5.1-dev pkg-config"
	goodecho "[+] Compiing Luaradio apps"
	cd luaradio/embed
	sudo make install-lmod
}
