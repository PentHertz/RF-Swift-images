#!/bin/bash

function gnuradio_soft_install() {
	goodecho "[+] GNU Radio tools"
	install_dependencies "gnuradio gnuradio-dev"
}

function sdrangel_soft_install() {
	goodecho "[+] Installing dependencies"
	installfromnet "apt-fast" "update"
	install_dependencies "git cmake g++ pkg-config autoconf automake libtool libfftw3-dev libusb-1.0-0-dev libusb-dev libhidapi-dev libopengl-dev"
	install_dependencies "qtbase5-dev qtchooser libqt5multimedia5-plugins qtmultimedia5-dev libqt5websockets5-dev"
	install_dependencies "qttools5-dev qttools5-dev-tools libqt5opengl5-dev libqt5quick5 libqt5charts5-dev"
	install_dependencies "qml-module-qtlocation  qml-module-qtpositioning qml-module-qtquick-window2"
	install_dependencies "qml-module-qtquick-dialogs qml-module-qtquick-controls qml-module-qtquick-controls2 qml-module-qtquick-layouts"
	install_dependencies "libqt5serialport5-dev qtdeclarative5-dev qtpositioning5-dev qtlocation5-dev libqt5texttospeech5-dev"
	install_dependencies "qtwebengine5-dev qtbase5-private-dev libqt5gamepad5-dev libqt5svg5-dev"
	install_dependencies "libfaad-dev zlib1g-dev libboost-all-dev libasound2-dev pulseaudio libopencv-dev libxml2-dev bison flex"
	install_dependencies "ffmpeg libavcodec-dev libavformat-dev libopus-dev doxygen graphviz"
	install_dependencies "libhamlib4 libgl1 libglx-mesa0 qtspeech5-speechd-plugin gstreamer1.0-libav libairspy0"

	goodecho "[+] Downloading and unpacking SDR Angel"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	# v8+ ships per-Ubuntu .debs directly (the old v7 sdrangel-<build>-master.tar.gz is gone)
	local SDRANGEL_VERSION="8.2.0"  # known-good; the build takes the newest release
	SDRANGEL_VERSION=$(latest_release_version f4exb/sdrangel "$SDRANGEL_VERSION" \
		"https://github.com/f4exb/sdrangel/releases/download/v@V@/sdrangel_@V@_ubuntu-26.04_amd64.deb")
	local deb="sdrangel_${SDRANGEL_VERSION}_ubuntu-26.04_amd64.deb"
	installfromnet "wget" "https://github.com/f4exb/sdrangel/releases/download/v${SDRANGEL_VERSION}/${deb}"
	apt-fast install -y "./${deb}"
	rm -f "${deb}"
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
	installfromnet "apt-fast" "update"
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
	# v3.0 renamed the public API (e.g. CoordTopocentric::range_rate -> rangeRate) and breaks SDRangel
	cmake_clone_and_build "https://github.com/dnwrnr/sgp4.git" "build" "" "v2.0" "sdrangel_soft_fromsource_install" -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/sgp4

	goodecho "[+] libsigmf"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/f4exb/libsigmf.git" "build" "new-namespaces" "" "sdrangel_soft_fromsource_install" -Wno-dev -DCMAKE_INSTALL_PREFIX=/opt/install/libsigmf

	goodecho "[+] ggmorse"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/ggerganov/ggmorse.git" "build" "" "" "sdrangel_soft_fromsource_install" -Wno-dev \
		-DCMAKE_INSTALL_PREFIX=/opt/install/ggmorse -DGGMORSE_BUILD_TESTS=OFF -DGGMORSE_BUILD_EXAMPLES=OFF

	goodecho "[+] Installing SDR Angel"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/PentHertz/sdrangel.git" "build" "" "" "sdrangel_soft_fromsource_install" -Wno-dev -DDEBUG_OUTPUT=ON -DRX_SAMPLE_24BIT=ON \
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

function sdrpp_soft_install () {
	goodecho "[+] Installing dependencies"
	install_dependencies "libfftw3-dev libglfw3-dev libvolk-dev libzstd-dev libairspyhf-dev libiio-dev libad9361-dev librtaudio-dev libhackrf-dev -y"
	goodecho "[+] Installing SDR++"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	arch=`uname -m`  # uname -m is reliable in containers; uname -i can return "unknown"
	prog=""
	case "$arch" in
  		x86_64|amd64)
    		prog="sdrpp_ubuntu_resolute_amd64.deb";;
  		aarch64|arm64)
    		prog="sdrpp_ubuntu_resolute_aarch64.deb";;
  		arm*) # For Raspberry Pi for now
    		prog="sdrpp_raspios_bullseye_armhf.deb";;
  		*)
    		printf 'Unsupported architecture: "%s" -> use sdrpp_soft_fromsource_install instead\n' "$arch" >&2; exit 2;;
	esac
	installfromnet "wget" "https://github.com/AlexandreRouma/SDRPlusPlus/releases/download/nightly/$prog"
	dpkg -i $prog
	cd /root
}

# SigDigger needs sigutils, suscan (DSP core + suscli) and SuWidgets, all from source:
# Ubuntu packages none of them. Upstream's actinid.org/blsd build script is gone (404);
# this follows its replacement, Scripts/dist-common.sh (all four on master, Qt 6, cmake/qmake).
function sigdigger_soft_install() {
    goodecho "[+] Installing SigDigger (sigutils, suscan, SuWidgets, SigDigger)"
    install_dependencies "build-essential cmake git pkg-config qt6-base-dev qt6-base-dev-tools qt6-l10n-tools libqt6opengl6-dev \
        libsndfile1-dev libxml2-dev libfftw3-dev libsoapysdr-dev libvolk-dev libjson-c-dev zlib1g-dev \
        libcurl4-openssl-dev libasound2-dev portaudio19-dev"
    local src=/rftools/sdr/sigdigger repo qmake
    qmake=$(command -v qmake6 || echo /usr/lib/qt6/bin/qmake)
    mkdir -p "$src"
    # replaces the old blsd tree and its /usr/sbin link
    rm -rf /rftools/sdr/blsd-dir /rftools/sdr/blsd
    rm -f /usr/sbin/SigDigger
    for repo in sigutils suscan SuWidgets SigDigger; do
        rm -rf "${src:?}/$repo"
        if ! installfromnet git clone --recurse-submodules "https://github.com/BatchDrake/$repo.git" "$src/$repo"; then
            record_build_failure "git" "SigDigger" "clone of $repo failed"
            return 0
        fi
    done
    for repo in sigutils suscan; do
        if ! { cmake -S "$src/$repo" -B "$src/$repo/build" -DCMAKE_BUILD_TYPE=Release \
                && cmake --build "$src/$repo/build" -j"$(nproc)" \
                && cmake --install "$src/$repo/build"; }; then
            record_build_failure "build" "SigDigger" "$repo build failed"
            return 0
        fi
        ldconfig
    done
    # qmake runs in the source dir: SigDigger.pro reads files relative to it
    if ! (cd "$src/SuWidgets" && "$qmake" SuWidgetsLib.pro "CONFIG += release" PREFIX=/usr/local \
            && make -j"$(nproc)" && make install); then
        record_build_failure "build" "SigDigger" "SuWidgets build failed"
        return 0
    fi
    ldconfig
    if ! (cd "$src/SigDigger" && "$qmake" SigDigger.pro "CONFIG += release" PREFIX=/usr/local SUWIDGETS_PREFIX=/usr/local \
            && make -j"$(nproc)" && make install); then
        record_build_failure "build" "SigDigger" "SigDigger build failed"
        return 0
    fi
    ldconfig
    # sources stay for rebuilds; drop the build trees
    rm -rf "$src"/sigutils/build "$src"/suscan/build
    (cd "$src/SuWidgets" && make distclean > /dev/null 2>&1) || true
    (cd "$src/SigDigger" && make distclean > /dev/null 2>&1) || true
    command -v SigDigger > /dev/null || record_build_failure "build" "SigDigger" "SigDigger missing from PATH after install"
}

function cyberther_soft_install() {
	goodecho "[+] Installing Cyber Ether"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	cmake_clone_and_build "https://github.com/catchorg/Catch2.git" "build" "" "" "cyberther_soft_install"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	goodecho "[CyberEther][+] Installing core dependencies"
	install_dependencies "python3-numpy python3-pip"
	pip3install mapbox_earcut
	install_dependencies "git build-essential cmake pkg-config ninja-build meson git zenity curl"
	goodecho "[CyberEther][+] Installing graphical dependencies"
	install_dependencies "spirv-cross glslang-tools libglfw3-dev"
	goodecho "[CyberEther][+] Installing backend dependencies"
	install_dependencies "mesa-vulkan-drivers libvulkan-dev vulkan-validationlayers cargo"
	goodecho "[CyberEther][+] Installing remote caps"
	install_dependencies "gstreamer1.0-plugins-base libgstreamer-plugins-bad1.0-dev"
	install_dependencies "libgstreamer-plugins-base1.0-dev"
	install_dependencies "gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly"
	install_dependencies "python3-yaml"
	install_dependencies "libsoapysdr-dev soapysdr-module-rtlsdr libgstreamer1.0-dev gstreamer1.0-libav"
	goodecho "[CyberEther][+] Cloning GitHub repository"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	local CYBERETHER_VERSION="1.20.1"  # known-good; the build takes the newest release
	CYBERETHER_VERSION=$(latest_release_version luigifcruz/CyberEther "$CYBERETHER_VERSION" \
		"https://github.com/luigifcruz/CyberEther/archive/refs/tags/v@V@.tar.gz")
	git clone --depth=1 --branch "v${CYBERETHER_VERSION}" https://github.com/luigifcruz/CyberEther.git CyberEther
	cd CyberEther
	goodecho "[CyberEther][+] Configuring build options for architecture"
	BUILDTYPE="debugoptimized"
	NINJA_JOBS=$(nproc)
	case "$(uname -m)" in
	    aarch64|arm64)
	        goodecho "[CyberEther][+] ARM64 detected: using release build with limited parallelism"
	        BUILDTYPE="release"
	        NINJA_JOBS=3
	        ;;
	    riscv64)
	        goodecho "[CyberEther][+] RISC-V 64 detected: using release build with limited parallelism"
	        BUILDTYPE="release"
	        NINJA_JOBS=2
	        ;;
	    *)
	        goodecho "[CyberEther][+] x86_64 detected: using full build"
	        ;;
	esac
	goodecho "[CyberEther][+] Upgrading meson (Noble ships 1.3.2, CyberEther >= 1.4.1 requires >= 1.11.0)"
	pip3 install --break-system-packages --upgrade meson
	# CyberEther bundles airspyone_host (libairspy) as a meson subproject; its
	# airspy.c does "typedef int bool;", which is illegal now that bool is a C23
	# keyword (GCC 15 defaults to gnu23). Force gnu17 for C sources so the bundled
	# C subprojects (libairspy, libusb, glfw, zlib) keep compiling; CyberEther's
	# own C++ uses cpp_std and is unaffected. meson applies env CFLAGS to
	# subprojects too, which -Dc_std would not reliably do.
	export CFLAGS="${CFLAGS:-} -std=gnu17"
	# CyberEther generates resources/geodata/geodata.hh by having parser.py download
	# ~20 Natural Earth GeoJSON files from raw.githubusercontent.com at build time.
	# parser.py makes a single attempt and aborts on GitHub HTTP 429 rate-limiting,
	# so pre-fetch them here (installfromnet retries) into the dir parser.py scans;
	# it then finds them present and skips the flaky download. The list is read from
	# the module's own meson.build so it tracks the upstream version.
	goodecho "[CyberEther][+] Pre-fetching Natural Earth geodata (avoids build-time 429s)"
	_ne_url="https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson"
	for _ne_f in $(grep -oE "ne_10m_[A-Za-z0-9_]+\.geojson" resources/geodata/meson.build | sort -u); do
	    [ -s "resources/geodata/$_ne_f" ] || installfromnet "wget" "-q" "-O" "resources/geodata/$_ne_f" "$_ne_url/$_ne_f"
	done
	# v1.20+ replaced that with one precompiled archive from cdn.cyberether.org, named in
	# resources/geodata/manifest.json. fetch.py also tries it only once, and skips the download
	# when .cache/geodata/<sha256>.bin is present and matches, so fetch it there with retries.
	if [ -f resources/geodata/manifest.json ]; then
	    local _gd_url _gd_sha _gd_bin
	    read -r _gd_url _gd_sha < <(python3 -c 'import json,sys; m=json.load(open(sys.argv[1])); print(m["url"], m["sha256"])' resources/geodata/manifest.json)
	    _gd_bin=".cache/geodata/${_gd_sha}.bin"
	    mkdir -p .cache/geodata
	    if ! echo "${_gd_sha}  ${_gd_bin}" | sha256sum -c --status - 2>/dev/null; then
	        installfromnet "wget" "-q" "-O" "${_gd_bin}" "${_gd_url}?sha256=${_gd_sha}" \
	            && echo "${_gd_sha}  ${_gd_bin}" | sha256sum -c --status - \
	            || { rm -f "${_gd_bin}"; criticalecho-noexit "[CyberEther][!] geodata pre-fetch failed, meson will retry it once"; }
	    fi
	fi
	# v1.14.0's Soapy module keeps a std::atomic<std::optional<Range>> (~32 bytes,
	# not lock-free), so GCC emits __atomic_load/__atomic_store calls into
	# libatomic, which upstream never links. With meson's --no-undefined the
	# libjetstream.so link then fails.
	meson setup -Dbuildtype=${BUILDTYPE} -Dcpp_link_args=-latomic build && cd build
	ninja -j${NINJA_JOBS}
	# v1.14.0 vendors ~40 subprojects (glib, openssl, gstreamer, libusb, SDR libs,
	# and a minimum=true libxml2 with XPath compiled out). All are linked
	# statically, but `ninja install` also puts their headers, .pc files and tools
	# under /usr/local, ahead of the system copies: later builds then pick them up
	# (telive got the XPath-less libxml2 via /usr/local/bin/xml2-config). Install
	# only CyberEther itself, plus fmt, whose headers its public headers include.
	_ce_skip=$(meson introspect --projectinfo . | python3 -c 'import json,sys; print(",".join(s["name"] for s in json.load(sys.stdin)["subprojects"] if s["name"] != "fmt"))')
	meson install --no-rebuild --skip-subprojects "$_ce_skip"
}

function decsat_soft_install() {
	# DecSAT (ex-DecDVB): Rust satellite receiver - DVB-S2/S2X with ACM (GSE->IP
	# PCAP, MPEG-TS), DVB-S, SCPC modems, DVB-CID; SDR++-style egui GUI + CLI.
	# Live input is HackRF One only, via a pure-Rust USB driver (no libhackrf);
	# other SDRs through IQ captures. Not on crates.io and upstream only ships
	# Windows builds, so build from git with corebuild's rustup toolchain
	# (GUI needs Rust >= 1.95). libopus/libxaac are git submodules built by build.rs.
	goodecho "[+] Installing DecSAT (DVB-S2/S2X receiver)"
	if ! command -v cargo >/dev/null 2>&1; then
		record_build_failure "build" "decsat" "cargo toolchain unavailable"
		return 0
	fi
	# cmake: libopus; pkg-config + libasound2-dev: cpal -> alsa-sys. X11/Wayland/GL
	# are dlopen'ed by winit/glutin; ffmpeg (TV player) and curl (radar map) are
	# spawned at runtime.
	install_dependencies "build-essential cmake pkg-config git libasound2-dev"
	install_dependencies "libxkbcommon-x11-0 libegl1 libgl1 libxcursor1 libxi6 libxrandr2 ffmpeg curl"

	local repo="https://github.com/CasualArclamp/DecSAT.git" pkgs="decsat-cli decsat-gui" jobs pkg tdir
	jobs=$(nproc)
	if [ "$(uname -m)" = "riscv64" ]; then
		# egui + thin LTO under riscv64 emulation would take hours: CLI only
		pkgs="decsat-cli"
		jobs=2
	fi
	# Shared target dir so the GUI reuses the workspace crates built for the CLI
	tdir=$(mktemp -d)
	for pkg in $pkgs; do
		CARGO_TARGET_DIR="$tdir" cargo install --git "$repo" --root /usr/local --locked -j "$jobs" "$pkg" \
			|| CARGO_TARGET_DIR="$tdir" cargo install --git "$repo" --root /usr/local -j "$jobs" "$pkg" \
			|| record_build_failure "build" "$pkg" "cargo install --git failed"
	done
	rm -rf "$tdir"
	# Drop cargo's git checkout (with the libopus/libxaac submodules) to keep the layer small
	find "${CARGO_HOME:-$HOME/.cargo}/git" -mindepth 2 -maxdepth 2 -iname 'decsat-*' -exec rm -rf {} + 2>/dev/null || true
	return 0
}

function sdrmm_soft_install() {
	# SDRmm: modular client-server SDR in Rust (AM/FM/SSB, digital voice, ADS-B,
	# AIS, pagers, weather sats, DAB/DRM/DVB, recording, scanning, DF, REST/MCP).
	# Installs the headless `sdrmm` server, which embeds its web UI. Upstream ships
	# portable Linux builds for x86_64 and aarch64 only; anything else (riscv64)
	# builds the same tag from the release source tarball, which already carries
	# the built web UI, so node/pnpm are not needed. SDRMM_FROM_SOURCE=1 forces
	# the source build on any arch.
	goodecho "[+] Installing SDRmm"
	# Latest stable tag, read from the /releases/latest redirect (no API rate limit,
	# skips the "nightly" pre-release). Falls back to the last version tested here.
	# One request, redirect not followed, and never fatal: under `set -eo pipefail`
	# a failed lookup (an HTTP error from github.com, curl exit 22) used to abort the
	# whole RUN before the fallback below could apply.
	local version
	version=$(curl -fsS --max-time 30 -o /dev/null -w '%{redirect_url}' https://github.com/Newspicel/sdrmm/releases/latest 2>/dev/null \
		| sed -n 's#.*/tag/v\([0-9][0-9.]*\)$#\1#p' || true)
	version="${version:-2.4.3}"
	colorecho "[SDRmm] Using release v${version}"
	local url="https://github.com/Newspicel/sdrmm/releases/download/v${version}"
	local triple="" tarball tmp dir stage lib
	case "$(uname -m)" in
		x86_64|amd64) triple="x86_64-unknown-linux-gnu" ;;
		aarch64|arm64) triple="aarch64-unknown-linux-gnu" ;;
	esac
	[ "${SDRMM_FROM_SOURCE:-0}" = "1" ] && triple=""
	if [ -n "$triple" ]; then
		tarball="sdrmm-${version}-${triple}.tar.gz"
	else
		tarball="sdrmm-${version}-src.tar.gz"
	fi

	tmp=$(mktemp -d)
	if ! installfromnet curl -fsSL -o "$tmp/$tarball" "$url/$tarball" \
		|| ! installfromnet curl -fsSL -o "$tmp/SHA256SUMS" "$url/SHA256SUMS"; then
		record_build_failure "net" "sdrmm" "download failed: $url/$tarball"
		rm -rf "$tmp"
		return 0
	fi
	if ! (cd "$tmp" && grep " ${tarball}\$" SHA256SUMS | sha256sum -c -); then
		record_build_failure "net" "sdrmm" "checksum mismatch: $tarball"
		rm -rf "$tmp"
		return 0
	fi
	tar -xzf "$tmp/$tarball" -C "$tmp"
	dir="$tmp/${tarball%.tar.gz}"
	stage="$dir"

	if [ -z "$triple" ]; then
		# Same toolchain as upstream's Dockerfile: cmake + cc for the vendored libopus
		# and aws-lc, clang/libclang for bindgen, python3 + nasm for the minimal FFmpeg.
		# SoapySDR is dlopen'ed at runtime, so nothing SDR-related is linked here.
		install_dependencies "build-essential cmake pkg-config python3 clang libclang-dev nasm curl"
		if ! command -v rustup >/dev/null 2>&1; then
			record_build_failure "build" "sdrmm" "rustup toolchain unavailable"
			rm -rf "$tmp"
			return 0
		fi
		if [ ! -f "$dir/web/dist/index.html" ]; then
			record_build_failure "build" "sdrmm" "source tarball has no prebuilt web/dist"
			rm -rf "$tmp"
			return 0
		fi
		# Feature set of upstream's release builds (xtask/release/src/dist.rs).
		local features="soapy,sdrplay,aaronia,rtlsdr,hackrf,airspy,airspyhf,funcube,espsdr,ad936x,net-client,gpu-fft"
		local chan profile="release" jobs media="$tmp/media"
		jobs=$(nproc)
		chan=$(sed -n 's/^channel *= *"\(.*\)"/\1/p' "$dir/rust-toolchain.toml")
		if [ "$(uname -m)" = "riscv64" ]; then
			# `ci` is upstream's release profile without LTO: thin LTO under riscv64
			# emulation would take hours.
			profile="ci"
			jobs=2
		fi
		# build-media.py maps every non-arm machine to x86_64, so name the target
		# explicitly. Its "cross" mode then just uses the native <arch>-linux-gnu-*
		# tools, and FFmpeg gets the right --arch.
		# RUSTUP_TOOLCHAIN overrides rust-toolchain.toml, which would also pull
		# clippy, rustfmt, llvm-tools and a wasm32 std that this build never uses.
		# A private CARGO_HOME keeps the crate registry out of the image layer.
		if python3 "$dir/scripts/build-media.py" --target "$(uname -m)-unknown-linux-gnu" --prefix "$media" \
			&& rustup toolchain install "$chan" --profile minimal \
			&& (cd "$dir" && RUSTUP_TOOLCHAIN="$chan" CARGO_HOME="$tmp/cargo" FFMPEG_DIR="$media" \
				cargo build --profile "$profile" --locked -j "$jobs" -p sdrmm \
				--no-default-features --features "$features"); then
			stage="$tmp/stage"
			install -Dm755 "$dir/target/$profile/sdrmm" "$stage/sdrmm"
			cp "$dir/LICENSE" "$dir/THIRD_PARTY_NOTICES.md" "$stage/"
			# Only the SONAME names (libavutil.so.61, ...) the binary links against
			for lib in "$media"/lib/lib*.so.*; do
				if [[ "$lib" =~ \.so\.[0-9]+$ ]]; then install -m755 "$lib" "$stage/"; fi
			done
		else
			record_build_failure "build" "sdrmm" "source build failed (FFmpeg or cargo)"
		fi
		rustup toolchain uninstall "$chan" > /dev/null 2>&1 || true
	fi

	# The binary's rpath ($ORIGIN/../lib/sdrmm) finds its private FFmpeg build here,
	# so it never clashes with the system FFmpeg and needs no ldconfig.
	if [ -f "$stage/sdrmm" ]; then
		install -Dm755 "$stage/sdrmm" /usr/local/bin/sdrmm
		rm -rf /usr/local/lib/sdrmm
		install -Dm755 -t /usr/local/lib/sdrmm "$stage"/lib*.so.*
		install -Dm644 -t /usr/share/doc/sdrmm "$stage/LICENSE" "$stage/THIRD_PARTY_NOTICES.md"
		goodecho "[+] SDRmm ${version} installed: run 'sdrmm' and open the URL it prints"
	elif [ -n "$triple" ]; then
		record_build_failure "other" "sdrmm" "no sdrmm binary in $tarball"
	fi
	rm -rf "$tmp"
	return 0
}

function inspectrum_soft_install () {
	goodecho "[+] Installing inspectrum"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    cd /root/thirdparty
	install_dependencies "cmake g++ pkg-config libfftw3-dev libliquid-dev libgl1-mesa-dev qtbase5-dev"
	gitinstall "https://github.com/hydrasdr/inspectrum.git" "inspectrum_soft_install"
	cd inspectrum
	mkdir build 
	cd build
	cmake ../
	make -j$(nproc)
	make install
}

function inspectrum_soft_install_old () {
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

# minimodem: audio FSK modems (Bell 103 `300`, Bell 202 `1200`, RTTY `rtty`, TDD `tdd`, NOAA
# SAME `same`, caller ID, UIC-751-3 train radio `uic-train`/`uic-ground`, or any baud rate and
# mark/space tones you set), for data sent as audio tones over a radio voice channel.
# `minimodem --rx 1200 -f audio.wav` decodes a recording (demodulated audio from gqrx, SDR++ or
# GNU Radio); without -f it listens to the sound card or PulseAudio. `--tx` makes test signals.
function minimodem_soft_install () {
	goodecho "[+] Installing minimodem"
	install_dependencies "minimodem"
	local tmp
	tmp=$(mktemp -d)
	echo "RFSWIFT 1200 BAUD TEST" | minimodem --tx 1200 -f "$tmp/bell202.wav" > /dev/null 2>&1 || true
	[ "$(minimodem --rx 1200 -q -f "$tmp/bell202.wav" 2> /dev/null)" = "RFSWIFT 1200 BAUD TEST" ] \
		|| record_build_failure "other" "minimodem" "a Bell 202 test signal does not decode"
	rm -rf "$tmp"
	return 0
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
    VERSION_URH="0.0.2"
    GITBUILD="git20260710.0a6fe54"
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
    # v0.0.2 ships a per-Ubuntu-base .deb: its bundled /opt/urh-venv is built
    # against that base's Python (noble -> 3.12, resolute -> 3.14). The .deb must
    # match the image, otherwise the venv's site-packages sit under the wrong
    # lib/pythonX.Y and `urh` dies with "PackageNotFoundError: ... urh-ng". Pick
    # the variant for the image being built; default to resolute.
    BASE_CODENAME=$(. /etc/os-release 2>/dev/null; echo "${VERSION_CODENAME:-resolute}")
    # Use curly braces to properly delimit variable names
    FILENAME="urh-penthertz_${ARCH}_${VERSION_URH}+${GITBUILD}.${BASE_CODENAME}.deb"
    BASEURL="https://github.com/PentHertz/urh-ng/releases/download/v${VERSION_URH}"
    installfromnet "wget" "${BASEURL}/${FILENAME}"
    installfromnet "wget" "${BASEURL}/SHA256SUMS"
    if [ -f "$FILENAME" ]; then
        # Verify by SHA-256. The SHA256SUMS entries use '~' where GitHub serves
        # '.', so match on the digest rather than the file name.
        if [ -s SHA256SUMS ]; then
            URH_HASH=$(sha256sum "$FILENAME" | cut -d' ' -f1)
            if grep -qi "^${URH_HASH}[[:space:]]" SHA256SUMS; then
                goodecho "[+] URH .deb SHA-256 verified"
            else
                criticalecho-noexit "[!] URH .deb SHA-256 mismatch -- refusing to install"
                record_build_failure "download" "urh (${FILENAME})" "SHA-256 mismatch"
                rm -f "$FILENAME"
                return 1
            fi
        else
            criticalecho-noexit "[!] SHA256SUMS unavailable -- installing URH unverified"
        fi
        dpkg -i "$FILENAME"
    else
        record_build_failure "download" "urh (${FILENAME})" "download failed"
        return 1
    fi
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
    installfromnet "wget" "https://github.com/PentHertz/urh/releases/download/v$VERSION_URH/$FILENAME"
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
	cmake_clone_and_build "https://github.com/szpajder/libacars.git" "build" "" "" "acarsdec_soft_install" 
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
	# autopoint (gettext): autogen.sh runs `autopoint --force` since upstream e68e4b3e (2026-11-01)
	install_dependencies "libtool intltool autoconf automake autopoint gettext libcurl4-openssl-dev pkg-config libglib2.0-dev libgtk-3-dev libgoocanvas-2.0-dev"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	goodecho "[+] Cloning GPredict"
	gitinstall "https://github.com/csete/gpredict.git" "gpredict_sdr_soft_install"
	if [ ! -d gpredict ]; then record_build_failure "git" "gpredict" "clone failed"; return 0; fi
	cd gpredict
	# autogen.sh ends by running ./configure itself
	if ./autogen.sh && make -j"$(nproc)" && make install; then
		goodecho "[+] GPredict installed"
	else
		record_build_failure "build" "gpredict" "autogen/configure/make failed"
	fi
	cd /root
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
	install_dependencies "libvolk-dev libmbedtls-dev git build-essential cmake g++ pkgconf libfftw3-dev libpng-dev libtiff-dev libcurl4-openssl-dev libglfw3-dev zenity portaudio19-dev libhdf5-dev libomp-dev ocl-icd-opencl-dev"
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
	install_dependencies "libudev-dev"
	[ -d /rftools/sdr ] || mkdir /rftools/sdr
	cd /rftools/sdr
	export LDFLAGS="-Wl,--no-as-needed -ludev"
	cmake_clone_and_build "https://github.com/jvde-github/AIS-catcher.git" "build" "" "" "AIScatcher_soft_install"
	unset LDFLAGS
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
        installfromnet "git" "clone" "--depth" "1" "https://github.com/osmocom/libosmo-dsp.git"
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
    # osmo-tetra (sq5bpf) is old C: it has implicit function declarations (tun_alloc,
    # decode_chan_alloc) and implicit-int returns (show_ascii_strings), which GCC 14+
    # promotes to hard errors by default. Override CC to downgrade them (the Makefile
    # keeps its own CFLAGS incl. -fcommon and pkg-config) so the fork still builds.
    make -j$(nproc) CC="gcc -Wno-implicit-function-declaration -Wno-implicit-int -Wno-int-conversion -Wno-incompatible-pointer-types"
    cd ../..
    
    # Install telive
    goodecho "[+] Installing telive"
    cd /rftools/sdr
    gitinstall "https://github.com/sq5bpf/telive.git" "tetra_suite_install"
    cd telive
    # telive_receiver.h uses time_t but never includes <time.h>; newer glibc no
    # longer pulls it in transitively, so add the missing include before building.
    grep -q '#include <time.h>' telive_receiver.h || \
        sed -i 's|#include <stdint.h>|#include <stdint.h>\n#include <time.h>|' telive_receiver.h
    # telive is old sq5bpf C too; same GCC 14+ strictness (implicit-int /
    # implicit-function-declaration) would break it, so apply the same downgrade.
    # Also force -std=gnu17: GCC 15 defaults to gnu23, where an empty parameter
    # list means (void), so telive's `void timeout_receivers()` called as
    # timeout_receivers(grxml_url) becomes a hard "too many arguments" error.
    make -j$(nproc) CC="gcc -std=gnu17 -Wno-implicit-function-declaration -Wno-implicit-int -Wno-int-conversion -Wno-incompatible-pointer-types"
    
    # Clone ACELP codec installer (not built - user runs it manually due to ETSI licensing)
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
	# This used to run `./install`, copied from op25: trunk-recorder has no such script,
	# so the call failed behind `|| true` and nothing was installed (and the function
	# was defined twice). Upstream's install.sh apt-installs Debian's GNU Radio with
	# sudo, which would replace the image's own build, so build it with CMake against
	# the GNU Radio, gr-osmosdr, UHD and HackRF already in the image.
	goodecho "[+] Installing trunk-recorder"
	install_dependencies "libboost-all-dev libgmp-dev libssl-dev libcurl4-openssl-dev liborc-0.4-dev libusb-1.0-0-dev pkg-config fdkaac sox"
	[ -d /rftools/sdr ] || mkdir /rftools/sdr
	cd /rftools/sdr
	gitinstall "https://github.com/TrunkRecorder/trunk-recorder.git" "trunkrecorder_soft_install"
	cd trunk-recorder
	rm -rf build && mkdir build && cd build
	if ! { cmake .. && make -j"$(nproc)" && make install; }; then
		record_build_failure "build" "trunk-recorder" "cmake/make failed"
		return 0
	fi
	ldconfig
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
    [ -d /rftools/sdr ] || mkdir /rftools/sdr
    cd /rftools/sdr
    gitinstall "https://github.com/hydrasdr/hydrasdr_433.git" "hydrasdr433_soft_install"
    cd hydrasdr_433
    mkdir build
    cd build
    cmake ../
    make -j$(nproc)
    mkdir -p $(pwd)/../man
    make install
}

function hydrasdradsb_soft_install() {
    # Mode S / ADS-B 1090 MHz decoder for HydraSDR (hydrasdr/hydrasdr_adsb).
    # Live input needs libhydrasdr >= 1.1.4; against an older one CMake quietly
    # builds a recordings-only binary. The sdrsa_devices base can carry 1.1.3,
    # so refresh libhydrasdr from hydrasdr-host first when needed (SOVERSION is
    # unchanged, so gr-hydrasdr and SoapyHydraSDR keep working).
    # Upstream has no install() rule on Linux: the binary is copied by hand.
    goodecho "[+] Installing hydrasdr_adsb"
    local hdr=/usr/include/libhydrasdr/hydrasdr.h ver="" p
    if [ -f "$hdr" ]; then
        for p in MAJOR MINOR REVISION; do
            ver="${ver:+$ver.}$(sed -n "s/^#define HYDRASDR_VER_${p}[[:space:]]\+\([0-9]\+\).*/\1/p" "$hdr")"
        done
    fi
    if ! dpkg --compare-versions "${ver:-0}" ge 1.1.4; then
        goodecho "[+] libhydrasdr ${ver:-not found} is older than 1.1.4, updating it"
        hydrasdr_rfone_install || true   # its trailing ln -s fails on existing links
        ldconfig
    fi
    [ -d /rftools/sdr ] || mkdir -p /rftools/sdr
    cd /rftools/sdr
    gitinstall "https://github.com/hydrasdr/hydrasdr_adsb.git" "hydrasdradsb_soft_install"
    if [ ! -d hydrasdr_adsb ]; then
        record_build_failure "git" "hydrasdr_adsb" "clone failed"
        return 0
    fi
    cd hydrasdr_adsb
    rm -rf build
    if cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j"$(nproc)"; then
        install -m 0755 build/hydrasdr_adsb /usr/local/bin/hydrasdr_adsb
        # no grep -q: with pipefail an early grep exit can SIGPIPE readelf
        readelf -d /usr/local/bin/hydrasdr_adsb | grep 'NEEDED.*libhydrasdr' > /dev/null \
            || record_build_failure "build" "hydrasdr_adsb" "built without libhydrasdr: recordings only, no live input"
    else
        record_build_failure "build" "hydrasdr_adsb" "cmake build failed"
    fi
    rm -rf build
}

FISSURE_DIR="/rftools/sdr/FISSURE"
FISSURE_VENV="${FISSURE_DIR}/venv"

function fissure_soft_install() {
    # FISSURE (AInfoSec RF framework), installed so it reuses the GNU Radio /
    # SoapySDR / SDR driver stack already present in sdr_light.
    #
    # FISSURE's own installer pip-installs a large, version-pinned set
    # (numpy/protobuf/opencv/tensorflow/...) into the SYSTEM Python, which would
    # perturb GNU Radio's system bindings. To avoid that we DON'T use that path:
    # FISSURE's Python deps go into a dedicated venv created with
    # --system-site-packages (so it still sees the system GNU Radio / PyQt5
    # bindings), and the `fissure` command is a wrapper that runs from that venv.
    # The system Python is left untouched. 26.04 isn't an upstream-supported
    # FISSURE OS; we mirror its Ubuntu 24.04 dependency set.
    goodecho "[+] Installing FISSURE (isolated venv, reusing existing SDR stack)"
    [ -d /rftools/sdr ] || mkdir -p /rftools/sdr
    cd /rftools/sdr
    gitinstall "https://github.com/ainfosec/FISSURE.git" "fissure_soft_install" "Python3"
    if [ ! -d FISSURE ]; then
        record_build_failure "git" "FISSURE" "clone failed"
        return 1
    fi
    cd "$FISSURE_DIR"

    # 1) System apt deps FISSURE needs (GUI toolkit + helpers). apt-managed Python
    #    modules (PyQt5, tk) are fine system-wide and are visible to the venv via
    #    --system-site-packages; only the version-pinned pip deps are isolated.
    #    cppzmq-dev: gr-ainfosec includes <zmq.hpp>, which 26.04's libzmq3-dev no
    #    longer ships. python3-pyproj: fissure/utils/geo.py (upstream takes it from apt).
    install_dependencies "qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools python3-pyqt5 python3-tk libosmocore-dev liborc-0.4-dev cppzmq-dev expect wireshark-common tshark gpsd python3-venv python3-pyproj"

    # 2) Dedicated venv holding FISSURE's pip deps (mirrors FISSURE's
    #    Installer/OS/ubuntu24_04 "Misc. Dependencies" and Meshtastic lists).
    #    pycrypto -> the maintained pycryptodome (same `Crypto` module, builds on
    #    modern Python). fissure.utils imports pytak and fissure.comms imports
    #    meshtastic when they load, so generate_certificates.py needs both;
    #    meshtastic is unpinned because upstream's 2.6.4 requires Python < 3.14.
    #    The Dashboard's TSI tab imports pandas, seaborn and yellowbrick on load.
    python3 -m venv --system-site-packages "$FISSURE_VENV"
    "$FISSURE_VENV/bin/python3" -m pip install --upgrade pip > /dev/null 2>&1 || true
    local FISSURE_PIP="PyYAML bitarray crcmod pycryptodome pyzmq psutil pyserial gpsd-py3 geopy sounddevice qasync pydotplus netron ipython scikit-learn opencv-python-headless pyzipper mgrs watchdog aiohttp paho-mqtt msgpack eventlet psycopg2-binary python-dotenv pytak meshtastic pandas seaborn yellowbrick"
    "$FISSURE_VENV/bin/python3" -m pip install $FISSURE_PIP \
        || record_build_failure "pip" "FISSURE venv deps" "venv pip install reported errors"
    # tensorflow is only for the optional ML classifier; heavy, install best-effort.
    "$FISSURE_VENV/bin/python3" -m pip install tensorflow-cpu > /dev/null 2>&1 \
        || record_build_failure "pip" "tensorflow-cpu (FISSURE classifier)" "optional ML dep skipped"

    # 3) Build the core FISSURE GNU Radio OOT block against the system GNU Radio
    #    (C++/cmake, system install -- no Python pollution). CMake 4.x policy flag
    #    for the same reason as Keystone on resolute.
    local GRA="$FISSURE_DIR/Custom_Blocks/maint-3.10/gr-ainfosec"
    if [ -d "$GRA" ]; then
        ( cd "$GRA" && mkdir -p build && cd build && \
          cmake .. -DCMAKE_POLICY_VERSION_MINIMUM=3.5 && make -j"$(nproc)" && make install && ldconfig ) \
          || record_build_failure "build" "gr-ainfosec" "FISSURE OOT block build failed"
    fi

    # 4) Generate FISSURE's ZMQ certificates using the venv python.
    if [ -f "$FISSURE_DIR/fissure/generate_certificates.py" ]; then
        ( cd "$FISSURE_DIR" && PYTHONPATH="$FISSURE_DIR" "$FISSURE_VENV/bin/python3" fissure/generate_certificates.py ) \
          || record_build_failure "build" "FISSURE certificates" "generate_certificates.py failed"
    fi

    # 5) Wrapper: always launch FISSURE from its venv so its isolated deps are used.
    cat > /usr/local/bin/fissure <<EOF
#!/bin/bash
# RF-Swift launcher: run the FISSURE Dashboard from its isolated venv.
export PYTHONPATH="${FISSURE_DIR}\${PYTHONPATH:+:\$PYTHONPATH}"
cd "${FISSURE_DIR}" || exit 1
exec "${FISSURE_VENV}/bin/python3" fissure/Dashboard/__main__.py "\$@"
EOF
    chmod +x /usr/local/bin/fissure
    goodecho "[+] FISSURE installed (venv: ${FISSURE_VENV}). Launch with: fissure"
    cd /rftools/sdr
}

GNURADIO4_HOME="/opt/gnuradio4"

function gnuradio4_soft_install() {
    # GNU Radio 4.0 (GR4, github.com/gnuradio/gnuradio4 -- the GNU Radio project's own repo;
    # fair-acc/gnuradio4 is the FAIR prototype it grew out of) built from source ALONGSIDE the
    # apt GNU Radio 3.10. GR4 is a separate C++23 codebase with its own headers/namespace/prefix,
    # so it does not conflict with 3.10. Installed under /opt/gnuradio4/install; the shell
    # environment comes from /opt/gnuradio4/env.sh (sourced by /etc/profile.d/gnuradio4.sh).
    #
    # Since 4.0.0-RC3, gnuradio/gnuradio4 is a super-repo: CMake presets clone the components
    # (core, library, blocks, control-plane, Studio) at commits pinned in modules.cmake. We
    # follow upstream's own Ubuntu 26.04 recipe (containers/ubuntu-26.04/Dockerfile) with the
    # `full` preset, so GR4 Studio is included:
    #   - gnuradio4-control-plane (gr4cp_server) + Studio blocks + the Node/Vite Studio app
    #   - desktop Studio (Electron, `gr4-studio`) and browser Studio (`gr4-studio-web`, :8080)
    # Studio needs Node.js 22 + npm and an Electron build for the arch (amd64/arm64); elsewhere
    # only the base modules are built. Usage: docs/gnuradio4.md. Set GR4_REF to pick a tag.
    goodecho "[+] Installing GNU Radio 4.0 (GR4) + GR4 Studio in parallel to 3.10 -- heavy build"

    # Upstream's Ubuntu 26.04 dependency set (containers/ubuntu-26.04/Dockerfile)
    install_dependencies "build-essential ca-certificates cmake ninja-build git pkg-config \
        libboost-dev libbrotli-dev libcli11-dev libcpp-httplib-dev cppzmq-dev libcurl4-openssl-dev \
        libgtest-dev libncurses-dev nlohmann-json3-dev libsoapysdr-dev libssl-dev libtbb-dev \
        librtaudio-dev python3 python3-dev python3-numpy zlib1g-dev"
    # The Audio block family is built only when libsoundio is found (gnuradio4-blocks looks for
    # soundio/soundio.h); upstream's 26.04 list lacks it, so without it audio is silently skipped.
    install_dependencies "libsoundio-dev"

    # Upstream requires CMake >= 3.27 and GCC >= 14 for C++23. Check up front: a toolchain miss
    # otherwise shows up as a wall of template errors 40 minutes in.
    local CMAKE_VER GCC_VER
    CMAKE_VER=$(cmake --version 2>/dev/null | awk 'NR==1{print $3}' || true)
    GCC_VER=$(g++ -dumpfullversion -dumpversion 2>/dev/null | cut -d. -f1 || true)
    if [ -z "$CMAKE_VER" ] || ! [ "$(printf '%s\n3.27\n' "$CMAKE_VER" | sort -V | head -1)" = "3.27" ]; then
        record_build_failure "toolchain" "gnuradio4" "cmake >= 3.27 required (found: ${CMAKE_VER:-none})"
        return 1
    fi
    if [ -z "$GCC_VER" ] || [ "$GCC_VER" -lt 14 ]; then
        record_build_failure "toolchain" "gnuradio4" "g++ >= 14 required (found: ${GCC_VER:-none})"
        return 1
    fi

    # GR4 Studio: Node.js 22 + npm (Ubuntu 26.04 ships Node 22), nginx for the browser app,
    # and the runtime libraries of the Electron build that the desktop app bundles.
    local GR4_STUDIO=0 node_major
    case "$(uname -m)" in
        x86_64|aarch64)
            install_dependencies "nodejs npm nginx-light curl"
            install_dependencies "libnss3 libgtk-3-0t64 libasound2t64 libgbm1 libxss1 libxtst6 \
                libatk-bridge2.0-0t64 libcups2t64 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 \
                libxrandr2 libsecret-1-0 libnotify4 xdg-utils"
            node_major=$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)
            if [ "${node_major:-0}" -ge 22 ] && command -v npm > /dev/null 2>&1; then
                GR4_STUDIO=1
            else
                record_build_failure "toolchain" "gr4-studio" "Node.js >= 22 + npm required (found: node ${node_major:-none}); building GR4 without Studio"
            fi
            ;;
        *)
            goodecho "[!] GR4 Studio needs an Electron build, none for $(uname -m): building GR4 without Studio"
            ;;
    esac

    [ -d /opt ] || mkdir -p /opt
    cd /opt

    # Newest upstream tag (4.0.0-RC3 at the time of writing) rather than a hard pin; the tag pins
    # every component commit in modules.cmake. versionsort.suffix=- makes any dashed suffix a
    # *pre*-release, so 4.0.0 will outrank 4.0.0-RC3 once it ships (git's default does the opposite).
    local GR4_URL="https://github.com/gnuradio/gnuradio4.git"
    local GR4_TAG="${GR4_REF:-}"
    if [ -z "$GR4_TAG" ]; then
        GR4_TAG=$(git -c 'versionsort.suffix=-' ls-remote --tags --refs \
                      --sort=-v:refname "$GR4_URL" 2>/dev/null \
                  | awk -F/ 'NR==1 {print $NF}' || true)
    fi
    if [ -z "$GR4_TAG" ]; then
        GR4_TAG="main"
        goodecho "[+] Could not resolve the latest GR4 tag -- falling back to main"
    else
        goodecho "[+] Latest GR4 tag resolved: $GR4_TAG"
    fi

    gitinstall "$GR4_URL" "gnuradio4_soft_install" "$GR4_TAG"
    if [ ! -d gnuradio4 ]; then
        record_build_failure "git" "gnuradio4" "clone failed (ref: $GR4_TAG)"
        return 1
    fi
    cd "$GNURADIO4_HOME"

    # GR4's template-heavy translation units peak at several GB RSS each. Reserve 6 GB per
    # compiler job on ARM64 (generated Converter/DataSink units got BuildKit SIGTERMed at less)
    # and 3 GB elsewhere. GR4_BUILD_PARALLEL_LEVEL is what limits the nested component builds;
    # -j on the outer build does not.
    local MEMKB MEM_PER_JOB_KB GR4JOBS
    MEMKB=$(awk '/MemAvailable/{print $2}' /proc/meminfo 2>/dev/null || echo 0)
    MEM_PER_JOB_KB=$((3 * 1024 * 1024))
    [ "$(uname -m)" = "aarch64" ] && MEM_PER_JOB_KB=$((6 * 1024 * 1024))
    GR4JOBS=$(( MEMKB / MEM_PER_JOB_KB ))
    [ "$GR4JOBS" -lt 1 ] && GR4JOBS=1
    [ "$GR4JOBS" -gt "$(nproc)" ] && GR4JOBS="$(nproc)"

    local GR4_PREFIX="$GNURADIO4_HOME/install"
    local GR4_BUILD_DIR GR4_BUILT=0

    if [ -f CMakePresets.json ] && cmake --list-presets 2>/dev/null | grep -q '"full"'; then
        # Super-repo (4.0.0-RC3+). The `full` preset adds ZeroMQ/SDR/Audio blocks, control-plane
        # and Studio; we override what an image build should not carry: tests (the slowest and
        # most memory-hungry part), warnings-as-errors (any new GCC warning would fail the build)
        # and the RelWithAssert build type. The preset owns the generator and binary dir.
        # Precompiled headers are off for every component (GR4_EXTRA_CMAKE_ARGS reaches them all):
        # each block family's PCH is 400-600 MB, and on Ubuntu 26.04 / GCC 15 the blocks build had
        # used 5.9 GB of disk after 25 of 614 objects with PCH, against a ~1.5 GB peak for the
        # whole core + library + blocks build without it.
        # Configure + build clone the pinned components and fetch deps: needs git/npm egress.
        local groups="base;full"
        [ "$GR4_STUDIO" -eq 1 ] || groups="base"
        GR4_BUILD_DIR="$GNURADIO4_HOME/build/full"
        goodecho "[+] GR4 super-repo ($GR4_TAG), preset 'full' (modules: $groups), ${GR4JOBS} jobs ($(nproc) cores, ~$((MEMKB / 1024 / 1024)) GB RAM available)"
        if cmake --preset full \
                -DCMAKE_BUILD_TYPE=Release \
                -DGR4_BUILD_TESTING=OFF \
                -DGR4_WARNINGS_AS_ERRORS=OFF \
                -DGR4_MODULE_GROUPS="$groups" \
                -DGR4_BUILD_PARALLEL_LEVEL="$GR4JOBS" \
                -DGR4_EXTRA_CMAKE_ARGS=-DCMAKE_DISABLE_PRECOMPILE_HEADERS=ON \
                -DCMAKE_INSTALL_PREFIX="$GR4_PREFIX" \
           && cmake --build --preset full; then
            GR4_BUILT=1
        fi

        if [ "$GR4_BUILT" -eq 1 ]; then
            # "Does it work": upstream's own checks, run against the *installed* prefix.
            # oot-smoke builds and runs an out-of-tree consumer of the installed SDK;
            # control-plane-smoke starts the installed gr4cp_server and checks its block catalog.
            cmake --build --preset full --target oot-smoke \
                || record_build_failure "test" "gnuradio4" "oot-smoke failed: installed GR4 SDK unusable"
            if [ "$GR4_STUDIO" -eq 1 ]; then
                cmake --build --preset full --target control-plane-smoke \
                    || record_build_failure "test" "gr4-studio" "control-plane-smoke failed: gr4cp_server/plugin catalog"
                # Browser Studio bundle (upstream's studio-web image does the same after the superbuild)
                if (cd "$GNURADIO4_HOME/src/gnuradio4-studio" && npm run build:web) \
                   && [ -f "$GNURADIO4_HOME/src/gnuradio4-studio/dist/index.html" ]; then
                    rm -rf "$GR4_PREFIX/share/gr4-studio-web"
                    mkdir -p "$GR4_PREFIX/share"
                    cp -r "$GNURADIO4_HOME/src/gnuradio4-studio/dist" "$GR4_PREFIX/share/gr4-studio-web"
                else
                    record_build_failure "build" "gr4-studio-web" "npm run build:web failed; browser Studio unavailable"
                fi
            fi
        fi
    else
        # Pre-restructure monorepo (tags <= 4.0.0-RC2, only via GR4_REF). Deps (vir-simd,
        # magic_enum, ExprTk, ...) auto-resolve via system-or-fetch; no Studio in that layout.
        GR4_STUDIO=0
        GR4_BUILD_DIR="$GNURADIO4_HOME/build"
        if grep -q '^add_subdirectory(bench)' CMakeLists.txt; then
            sed -i 's/^add_subdirectory(bench).*/add_subdirectory(bench EXCLUDE_FROM_ALL) # RF-Swift: optional microbenchmarks/' CMakeLists.txt
        fi
        goodecho "[+] GR4 pre-restructure layout ($GR4_TAG) -- classic configure, -j${GR4JOBS}"
        if cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
                -DWARNINGS_AS_ERRORS=OFF -DENABLE_EXAMPLES=OFF -DENABLE_TESTING=OFF \
                -DGR_ENABLE_BLOCK_REGISTRY=ON -DCMAKE_INSTALL_PREFIX="$GR4_PREFIX" \
           && cmake --build build -j"$GR4JOBS" \
           && cmake --install build; then
            GR4_BUILT=1
        fi
    fi

    if [ "$GR4_BUILT" -ne 1 ]; then
        record_build_failure "build" "gnuradio4" "GR4 source build failed (ref: $GR4_TAG)"
        cd /opt
        return 0
    fi

    gnuradio4_write_env "$GR4_PREFIX" "$GR4_TAG" "$GR4_STUDIO"

    # Keep the installed prefix and the sources (a rebuild re-runs `cmake --preset full`);
    # drop the multi-GB build trees, Studio's node_modules and npm's cache.
    rm -rf "$GNURADIO4_HOME/build" "$GNURADIO4_HOME/src/gnuradio4-studio/node_modules"
    npm cache clean --force > /dev/null 2>&1 || true

    goodecho "[+] GNU Radio 4.0 installed at $GR4_PREFIX (ref: $GR4_TAG; Studio: $([ "$GR4_STUDIO" -eq 1 ] && echo yes || echo no)). apt GNU Radio 3.10 remains the default. See docs/gnuradio4.md."
    cd /opt
}

# Environment + launchers for the installed GR4 prefix (called by gnuradio4_soft_install).
function gnuradio4_write_env() {
    local prefix="$1" ref="$2" studio="$3" libdir py electron
    libdir="$prefix/lib"
    [ -d "$prefix/lib64" ] && [ ! -d "$prefix/lib/gnuradio-4" ] && libdir="$prefix/lib64"

    # POSIX env file mirroring upstream's activate.sh, with paths resolved now so it also works
    # in sh and zsh (no globs or bashisms at source time).
    {
        echo "# GNU Radio 4.0 (GR4) environment - ref $ref. apt GNU Radio 3.10 stays the default."
        echo "export GNURADIO4_HOME=\"$GNURADIO4_HOME\""
        echo "export GR4_PREFIX=\"$prefix\""
        echo "export PATH=\"$prefix/bin\${PATH:+:\$PATH}\""
        echo "export CMAKE_PREFIX_PATH=\"$prefix\${CMAKE_PREFIX_PATH:+:\$CMAKE_PREFIX_PATH}\""
        echo "export PKG_CONFIG_PATH=\"$libdir/pkgconfig:$prefix/share/pkgconfig\${PKG_CONFIG_PATH:+:\$PKG_CONFIG_PATH}\""
        echo "export LD_LIBRARY_PATH=\"$libdir\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}\""
        echo "export GNURADIO4_PLUGIN_DIRECTORIES=\"$libdir/gnuradio-4/plugins:$libdir\${GNURADIO4_PLUGIN_DIRECTORIES:+:\$GNURADIO4_PLUGIN_DIRECTORIES}\""
        for py in "$libdir"/python*/site-packages "$libdir"/python*/dist-packages; do
            [ -d "$py" ] && echo "export PYTHONPATH=\"$py\${PYTHONPATH:+:\$PYTHONPATH}\""
        done
    } > "$GNURADIO4_HOME/env.sh"

    if [ "$studio" -eq 1 ]; then
        # Desktop Studio in a container: Electron runs as root, which needs --no-sandbox, and the
        # upstream launcher refuses to start when the *host* kernel restricts unprivileged user
        # namespaces (Ubuntu 24.04+ default) unless an AppArmor profile was installed on the host.
        # Pointing GR4_STUDIO_ELECTRON_BIN at a no-sandbox shim covers both.
        electron=$(find "$prefix/libexec/gr4-studio/electron" -maxdepth 1 -type f -name electron 2>/dev/null | head -n1 || true)
        if [ -n "$electron" ]; then
            mkdir -p "$GNURADIO4_HOME/libexec"
            cat > "$GNURADIO4_HOME/libexec/electron-no-sandbox" << EOF
#!/bin/sh
# RF Swift: bundled Electron for GR4 Studio, without the Chromium sandbox (root in a container).
exec "$electron" --no-sandbox "\$@"
EOF
            chmod 0755 "$GNURADIO4_HOME/libexec/electron-no-sandbox"
            echo "export GR4_STUDIO_ELECTRON_BIN=\"$GNURADIO4_HOME/libexec/electron-no-sandbox\"" >> "$GNURADIO4_HOME/env.sh"
        else
            record_build_failure "build" "gr4-studio" "bundled Electron runtime not found under $prefix/libexec/gr4-studio"
        fi

        # Desktop Studio from any shell (loads the GR4 env first)
        cat > /usr/local/bin/gr4-studio << EOF
#!/bin/sh
# GNU Radio 4 Studio, desktop (Electron): needs a display (X11/Wayland forwarding).
# Remote backend: gr4-studio --remote=http://host:8080   (see docs/gnuradio4.md)
. "$GNURADIO4_HOME/env.sh"
exec "$prefix/bin/gr4-studio" "\$@"
EOF
        chmod 0755 /usr/local/bin/gr4-studio

        # Browser Studio: nginx serves the web bundle and proxies /api to gr4cp_server -- the
        # layout of upstream's ghcr.io/gnuradio/gnuradio4-studio image, with two changes for RF
        # Swift's default host networking: the backend uses GR4CP_PORT=0 (a fixed port would make
        # gr4cp_server listen on 0.0.0.0; port 0 binds a free 127.0.0.1 port and writes it to
        # GR4CP_PORT_FILE), and nginx binds 127.0.0.1 unless GR4_STUDIO_WEB_BIND says otherwise.
        if [ -f "$prefix/share/gr4-studio-web/index.html" ]; then
            cat > /usr/local/bin/gr4-studio-web << EOF
#!/bin/sh
# GNU Radio 4 Studio in the browser: http://localhost:\${GR4_STUDIO_WEB_PORT:-8080}
# Binds 127.0.0.1 by default (RF Swift containers use host networking, so this is reachable
# from the host's browser). In a bridge/NAT container, set GR4_STUDIO_WEB_BIND=0.0.0.0 and
# publish the port (-p 127.0.0.1:8080:8080). The gr4cp_server backend always stays on a
# random loopback port behind nginx. Studio can start flowgraphs, including SDR transmit:
# do not expose it beyond machines you trust.
set -eu
. "$GNURADIO4_HOME/env.sh"
WEB_PORT="\${GR4_STUDIO_WEB_PORT:-8080}"
WEB_BIND="\${GR4_STUDIO_WEB_BIND:-127.0.0.1}"
run=\$(mktemp -d /tmp/gr4-studio-web.XXXXXX)
mkdir -p "\$run/client_body" "\$run/fastcgi" "\$run/proxy" "\$run/scgi" "\$run/uwsgi"
backend=""
nginx_pid=""
cleanup() {
  [ -n "\$nginx_pid" ] && kill "\$nginx_pid" 2>/dev/null || true
  [ -n "\$backend" ] && kill "\$backend" 2>/dev/null || true
  rm -rf "\$run"
}
trap cleanup EXIT INT TERM
GR4CP_PORT=0 GR4CP_PORT_FILE="\$run/backend.port" gr4cp_server &
backend=\$!
n=0
until [ -s "\$run/backend.port" ] && curl -fsS -o /dev/null "http://127.0.0.1:\$(cat "\$run/backend.port")/healthz"; do
  kill -0 "\$backend" 2>/dev/null || { echo "gr4cp_server exited before becoming ready" >&2; exit 1; }
  n=\$((n + 1)); [ "\$n" -ge 30 ] && { echo "gr4cp_server not ready after 30 s" >&2; exit 1; }
  sleep 1
done
BACKEND_PORT=\$(cat "\$run/backend.port")
cat > "\$run/nginx.conf" << NGINX
worker_processes auto;
pid \$run/nginx.pid;
error_log /dev/stderr info;
events { worker_connections 1024; }
http {
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
  access_log /dev/stdout;
  sendfile on;
  client_body_temp_path \$run/client_body;
  fastcgi_temp_path \$run/fastcgi;
  proxy_temp_path \$run/proxy;
  scgi_temp_path \$run/scgi;
  uwsgi_temp_path \$run/uwsgi;
  map \\\$http_upgrade \\\$connection_upgrade { default upgrade; '' close; }
  server {
    listen \$WEB_BIND:\$WEB_PORT;
    server_name _;
    root $prefix/share/gr4-studio-web;
    index index.html;
    location = /api { proxy_pass http://127.0.0.1:\$BACKEND_PORT/; }
    location /api/ {
      proxy_pass http://127.0.0.1:\$BACKEND_PORT/;
      proxy_http_version 1.1;
      proxy_set_header Host \\\$host;
      proxy_set_header X-Real-IP \\\$remote_addr;
      proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto \\\$scheme;
      proxy_set_header Upgrade \\\$http_upgrade;
      proxy_set_header Connection \\\$connection_upgrade;
    }
    location / { try_files \\\$uri \\\$uri/ /index.html; }
  }
}
NGINX
echo "GR4 Studio: http://\$WEB_BIND:\$WEB_PORT  (backend gr4cp_server on 127.0.0.1:\$BACKEND_PORT)"
nginx -c "\$run/nginx.conf" -g 'daemon off;' &
nginx_pid=\$!
wait "\$nginx_pid"
EOF
            chmod 0755 /usr/local/bin/gr4-studio-web
        fi
    fi

    echo ". \"$GNURADIO4_HOME/env.sh\"" > /etc/profile.d/gnuradio4.sh
}

function rfcat_soft_install() {
    goodecho "[+] Installing rfcat (YARD Stick One and other CC1111 dongles)"
    install_dependencies "libusb-1.0-0 python3-usb python3-dev"
    pip3install rfcat || true
    return 0
}

function killerbee_soft_install() {
    goodecho "[+] Installing KillerBee (IEEE 802.15.4 / Zigbee)"
    install_dependencies "libgcrypt20-dev libusb-1.0-0-dev python3-dev build-essential python3-usb python3-serial"
    # KillerBee's setup.py still requires pycrypto, which no longer builds (abandoned, no Python 3.14
    # support). KillerBee only uses it for `from Crypto.Cipher import AES` (dot154decode), which
    # pycryptodome provides under the same `Crypto` name: install the dependencies with pycryptodome
    # in its place, then KillerBee itself without its declared ones.
    pip3install pyserial pyusb pycryptodome rangeparser scapy || true
    pip3install --no-deps "git+https://github.com/riverloopsec/killerbee" || true
    python3 -c 'import killerbee, killerbee.dot154decode, zigbee_crypt' > /dev/null 2>&1 \
        || record_build_failure "other" "killerbee" "import check failed after install"
    return 0
}
