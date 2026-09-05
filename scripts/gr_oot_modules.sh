#!/bin/bash

function common_sources_and_sinks() {
    # PentHertz/gr-osmosdr_resolute is the Boost 1.90 / Ubuntu 26.04 adapted fork.
    # One issue remains outside the fork's committed fixes: gr-osmosdr's CMakeLists
    # still does find_package(Boost ... system), but on Boost 1.90 boost::system is
    # header-only and ships no boost_systemConfig.cmake, so the component cannot be
    # resolved and configure fails. boost::system is pulled in transitively by
    # chrono/thread, so drop the obsolete "system" component before building
    # (CMP0167=NEW selects modern BoostConfig). If the fork drops "system" from its
    # find_package(Boost) line, this can go back to a plain grclone_and_build.
    # python3-six is still required by gr-osmosdr's doxygen docstring scraper
    # (docs/doxygen/doxyxml/.../compoundsuper.py imports six); it is no longer a
    # transitive dep on resolute's Python 3.14, so install it explicitly.
    install_dependencies "libboost-all-dev python3-six"
    [ -d /rftools/sdr/oot ] || mkdir -p /rftools/sdr/oot
    cd /rftools/sdr/oot || exit
    gitinstall "https://github.com/PentHertz/gr-osmosdr_resolute.git" "common_sources_and_sinks" ""
    cd gr-osmosdr_resolute || exit
    # Remove the unresolvable Boost "system" component from the find_package call.
    sed -i '/find_package(Boost/s/ system//' CMakeLists.txt
    mkdir -p build && cd build
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_POLICY_DEFAULT_CMP0167=NEW ../
    make -j$(nproc)
    sudo make install
    cd .. && rm -rf build/
}

function grgsm_grmod_install() {
    install_dependencies "build-essential libtool libtalloc-dev libsctp-dev shtool autoconf automake git-core pkg-config make gcc gnutls-dev libusb-1.0-0-dev libmnl-dev libosmocore libosmocore-dev"
    # PentHertz/gr-gsm_resolute carries the Boost >= 1.87 migration (io_context /
    # host+service resolve()) committed upstream, so no in-place patching is needed.
    grclone_and_build "https://github.com/PentHertz/gr-gsm_resolute.git" "" "grgsm_grmod_install"
}

function grbladerf_grmod_install() {
    grclone_and_build "https://github.com/Nuand/gr-bladeRF.git" "" "grbladerf_grmod_install"
}

function grlora_grmod_install() {
    install_dependencies "libliquid-dev libliquid1"
    grclone_and_build "https://github.com/rpp0/gr-lora.git" "" "grlora_grmod_install"
}

function grlorasdr_grmod_install() {
    grclone_and_build "https://github.com/tapparelj/gr-lora_sdr.git" "" "grlorasdr_grmod_install"
}

function grinspector_grmod_install() {
    install_dependencies "libqwt-qt5-dev libspdlog-dev"
    grclone_and_build "https://github.com/gnuradio/gr-inspector.git" "" "grinspector_grmod_install"
}

function griridium_grmod_install() {
    # Check the architecture and install MPIR only if not x86_64/amd64
    if [ "$(uname -m)" != "x86_64" ] && [ "$(dpkg --print-architecture 2>/dev/null)" != "amd64" ]; then
        goodecho "Non-x86_64/amd64 architecture detected: $(uname -m). Installing MPIR..."
        install_mpir
    else
        goodecho "x86_64/amd64 architecture detected. Skipping MPIR installation."
    fi

    # Work around GCC 13 LTO ICE (flags_from_decl_or_type, calls.cc:861)
    # when linking the pybind11 iridium_python module. Disable LTO locally.
    local _saved_cxx="$CXXFLAGS" _saved_c="$CFLAGS" _saved_ld="$LDFLAGS"
    export CXXFLAGS="${CXXFLAGS} -fno-lto"
    export CFLAGS="${CFLAGS} -fno-lto"
    export LDFLAGS="${LDFLAGS} -fno-lto"

    # Clone and build gr-iridium
    grclone_and_build "https://github.com/muccc/gr-iridium.git" "" "griridium_grmod_install"

    # Restore so the next OOT module build isn't affected
    export CXXFLAGS="$_saved_cxx"
    export CFLAGS="$_saved_c"
    export LDFLAGS="$_saved_ld"
}

function gruaslink_grmod_install() { 
    grclone_and_build "https://github.com/FlUxIuS/gr-uaslink.git" "" "gruaslink_grmod_install"
}

function grX10_grmod_install() {
    grclone_and_build "https://github.com/cpoore1/gr-X10.git" "" "grX10_grmod_install"
}

function grgfdm_grmod_install() {
    grclone_and_build "https://github.com/bkerler/gr-gfdm.git" "" "grgfdm_grmod_install"
}

function graaronia_rtsa_grmod_install() {
    install_dependencies "rapidjson-dev"
    goodecho "[+] Cloning and installing libspectranstream"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    cmake_clone_and_build "https://github.com/hb9fxq/libspectranstream.git" "build" "" "" "graaronia_rtsa_grmod_install"
    cd /root/thirdparty
    grclone_and_build "https://github.com/hb9fxq/gr-aaronia_rtsa.git" "" "graaronia_rtsa_grmod_install"
}

function grccsds_move_rtsa_grmod_install() {
    install_dependencies "rapidjson-dev"
    grclone_and_build "https://github.com/bkerler/gr-ccsds_move.git" "" "grccsds_move_rtsa_grmod_install"
}

function grais_grmod_install() {
    grclone_and_build "https://github.com/bkerler/gr-ais.git" "" "grais_grmod_install"
}

function graistx_grmod_install() {
    grclone_and_build "https://github.com/bkerler/ais.git" "gr-aistx" "graistx_grmod_install"
}

function grairmodes_grmod_install() {
    grclone_and_build "https://github.com/bistromath/gr-air-modes.git" "" "grairmodes_grmod_install" -b "gr3.9"
}

function grj2497_grmod_install() {
    grclone_and_build "https://github.com/ainfosec/gr-j2497.git" "" "grj2497_grmod_install"
}

function grzwavepoore_grmod_install() {
    grclone_and_build "https://github.com/cpoore1/gr-zwave_poore.git" "" "grzwavepoore_grmod_install"
}

function grmixalot_grmod_install() {
    install_dependencies "libitpp-dev"
    grclone_and_build "https://github.com/unsynchronized/gr-mixalot.git" "" "grmixalot_grmod_install"
}

function grreveng_grmod_install() {
    grclone_and_build "https://github.com/paulgclark/gr-reveng.git" "" "grreveng_grmod_install"
}

function grpdu_utils_grmod_install() {
    grclone_and_build "https://github.com/PentHertz/gr-pdu_utils_resolute.git" "" "grpdu_utils_grmod_install"
}

function grsandia_utils_grmod_install() {
    grclone_and_build "https://github.com/PentHertz/gr-sandia_utils_resolute.git" "" "grsandia_utils_grmod_install"
}

function grdvbs2_grmod_install() {
    # PentHertz/gr-dvbs2_resolute carries the Boost >= 1.87 migration (io_context /
    # host+service resolve()) committed upstream, so no in-place patching is needed.
    grclone_and_build "https://github.com/PentHertz/gr-dvbs2_resolute.git" "" "grdvbs2_grmod_install"
}

function grtempest_grmod_install() { 
    grclone_and_build "https://github.com/nash-pillai/gr-tempest.git" "" "grtempest_grmod_install"
    cd examples
    grcc FFT_autocorrelate.grc
    grcc FFT_crosscorrelate.grc
    grcc Keep_1_in_N_frames.grc
    mkdir -p /root/.grc_gnuradio
    cp *.block.yml /root/.grc_gnuradio
}

function deeptempest_grmod_install() {
    grclone_and_build "https://github.com/PentHertz/deep-tempest.git" "gr-tempest" "deeptempest_grmod_install"
    cd examples
    # Pre-compile the example flowgraphs to .py (convenience only). Best-effort:
    # some upstream examples (e.g. binary_serializer.grc) fail to evaluate under
    # GRC 3.10.12 ("gr.GR_LSB_FIRST" -> name 'gr' is not defined) and must not
    # abort the whole image build.
    for f in FFT_autocorrelate.grc FFT_crosscorrelate.grc Keep_1_in_N_frames.grc binary_serializer.grc; do
        grcc "$f" || record_build_failure "grcc" "deep-tempest/$f" "GRC example failed to compile (GNU Radio 3.10)"
    done
    mkdir -p /root/.grc_gnuradio
    cp *.block.yml /root/.grc_gnuradio
    cd ../..
    goodecho "[+] Installing requirements for deep-tempest"
    cd end-to-end/
    # deep-tempest's ML pipeline is PyTorch (torch/torchvision/timm/einops), NOT
    # TensorFlow. On Python 3.14 the whole stack installs: torch 2.13 & torchvision
    # 0.28 ship cp314 wheels, opencv-python 5.x is a forward-compatible cp37-abi3
    # wheel, scikit-image/lmdb have cp314, the rest are pure-python. Best-effort in
    # case a transient/dep hiccup occurs (pip3install already records a build-report
    # entry on failure) so gr-tempest (built above) and the image survive.
    pip3install -r requirement.txt || \
        criticalecho-noexit "[-] deep-tempest ML deps incomplete on this Python (see build report); gr-tempest SDR module is still installed"
    # Dropped the old `numpy<2.0` force: it was the actual blocker on py3.14 -- numpy
    # 1.26 has no cp314 wheel (slow, fragile source build) and would break torch /
    # scikit-image / scipy, which require numpy 2.x here. The only numpy-2.0-removed
    # API the code used is np.alltrue (an alias of np.all, deleted in numpy 2.0);
    # patch it in the persisted clone so the deblur runtime path works on numpy 2.x.
    [ -f utils/utils_deblur.py ] && sed -i 's/np\.alltrue(/np.all(/g' utils/utils_deblur.py
}

function grfhss_utils_grmod_install() {
    grclone_and_build "https://github.com/PentHertz/gr-fhss_utils_resolute.git" "" "grfhss_utils_grmod_install"
}

function grtiming_utils_grmod_install() {
    # PentHertz/gr-timing_utils_resolute carries the Boost >= 1.87 migration
    # (io_context / executor_work_guard / free dispatch()) committed upstream, so no
    # in-place patching is needed.
    grclone_and_build "https://github.com/PentHertz/gr-timing_utils_resolute.git" "" "grtiming_utils_grmod_install"
}

function grdab_grmod_install() {
    install_dependencies "libfaad-dev"
    grclone_and_build "https://github.com/bkerler/gr-dab.git" "" "grdab_grmod_install"
}

function grdect2_grmod_install() {
    grclone_and_build "https://github.com/pavelyazev/gr-dect2.git" "" "grdect2_grmod_install"
}

function grfoo_grmod_install() {
    grclone_and_build "https://github.com/bastibl/gr-foo.git" "" "grfoo_grmod_install"
}

function grieee802-11_grmod_install() {
    grclone_and_build "https://github.com/bastibl/gr-ieee802-11.git" "" "grieee802-11_grmod_install"
}

function grieee802-11ah_grmod_install() {
    grclone_and_build "https://github.com/irongiant33/gr-ieee802-11ah.git" "" "grieee802-11ah_grmod_install"
}

function grieee80211-grwifi_grmod_install() { # gr-WiFi project
    grclone_and_build "https://github.com/cloud9477/gr-ieee80211.git" "" "grieee80211-grwifi_grmod_install"
}

function grieee802154_grmod_install() {
    grclone_and_build "https://github.com/bastibl/gr-ieee802-15-4.git" "" "grieee802154_grmod_install"
    cd /rftools/sdr/oot/gr-ieee802-15-4/examples
    grcc ieee802_15_4_*.grc
    mkdir -p /root/.grc_gnuradio
    cp *.yml /root/.grc_gnuradio/
    cp *.py /root/.grc_gnuradio/
}

function grrds_grmod_install() {
    install_dependencies "libboost-all-dev"
    grclone_and_build "https://github.com/bastibl/gr-rds.git" "" "grrds_grmod_install"
}

function grfosphor_grmod_install() {
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
        install_dependencies "cmake xorg-dev libglu1-mesa-dev opencl-headers libwayland-dev libxkbcommon-dev"
        goodecho "[+] Cloning and building GLFW3"
        [ -d /root/thirdparty ] || mkdir /root/thirdparty
        cd /root/thirdparty
        cmake_clone_and_build "https://github.com/glfw/glfw" "build" "" "" "grfosphor_grmod_install" -DBUILD_SHARED_LIBS=true
        cd /root/thirdparty
        # PentHertz/gr-fosphor_resolute drops the header-only Boost "system" component
        # from find_package(Boost): on Boost 1.90 boost::system ships no
        # boost_systemConfig.cmake, so osmocom's find_package(Boost ... system) fails
        # in config mode ("Boost required to compile gr-fosphor"). system is pulled in
        # transitively via chrono/thread, so dropping it is safe.
        grclone_and_build "https://github.com/PentHertz/gr-fosphor_resolute.git" "" "grfosphor_grmod_install"
    fi
}

function grdroineid_grmod_install() { # TODO: for turbofec RISCV64:  gcc: error: '-march=native': ISA string must begin with rv32 or rv64 
    install_dependencies "libtool"
    # Check the system architecture
    ARCH=$(uname -m)

    echo "[+] Cloning turbofec"
    [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    cd /root/thirdparty
    installfromnet "git" "clone" "https://github.com/zlinwei/turbofec.git"
    cd turbofec

    autoreconf -i
    if [ "$ARCH" = "riscv64" ]; then
        colorecho "[!] Note: RISCV64 may have compilation issues with '-march=native'"
        ./configure CFLAGS="-march=rv64" || { criticalecho-noexit "[!] Failed to configure turbofec"; return 0; }
    else
        ./configure || { criticalecho-noexit "[!] Failed to configure turbofec"; return 0; }
    fi

    make -j$(nproc) || { criticalecho "[!] Failed to build turbofec"; }
    sudo make install || { criticalecho "[!] Failed to install turbofec"; }

    cd /root/thirdparty
    echo "[+] Cloning CRCpp"
    installfromnet "git" "clone" "https://github.com/d-bahr/CRCpp.git"
    install -d /usr/local/include
    install -m 644 CRCpp/inc/CRC.h /usr/local/include/ \
        || { criticalecho-noexit "[!] Failed to install CRCpp header"; return 0; }

    cd /root/thirdparty
    echo "[+] Cloning dji_droneid"
    grclone_and_build "https://github.com/PentHertz/dji_droneid_rfswift.git" "gnuradio/gr-droneid" "grdroineid_grmod_install" -b "gr-droneid-update-3.10"
}

function grsatellites_grmod_install() {
    install_dependencies "liborc-0.4-dev"
    pip3install "construct requests"
    grclone_and_build "https://github.com/daniestevez/gr-satellites.git" "" "grsatellites_grmod_install"
}

function gradsb_grmod_install() {
    pip3install "zmq flask flask-socketio gevent gevent-websocket"
    grclone_and_build "https://github.com/mhostetter/gr-adsb" "" "gradsb_grmod_install"
}

function grkeyfob_grmod_install() {
    grclone_and_build "https://github.com/bastibl/gr-keyfob.git" "" "grkeyfob_grmod_install"
}

function grradar_grmod_install() {
    grclone_and_build "https://github.com/radioconda/gr-radar.git" "" "grradar_grmod_install"
}

function grnordic_grmod_install() {
    # PentHertz/gr-nordic_resolute carries the Boost >= 1.87 migration (io_context /
    # resolve()) committed upstream, so no in-place patching is needed.
    grclone_and_build "https://github.com/PentHertz/gr-nordic_resolute.git" "" "grnordic_grmod_install"
}

function grpaint_grmod_install() {
    grclone_and_build "https://github.com/drmpeg/gr-paint.git" "" "grpaint_grmod_install"
}

function gr_DCF77_Receiver_grmod_install() {
    [ -d /rftools/sdr/oot ] || mkdir -p /rftools/sdr/oot
    cd /rftools/sdr/oot || exit
    gitinstall "https://github.com/henningM1r/gr_DCF77_Receiver.git" "gr_DCF77_Receiver_grmod_install"
}

function grsignalhound_Receiver_grmod_install() {
    # Check if the system architecture is supported
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" && "$ARCH" != "amd64" && "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
        criticalecho-noexit "[!] Signal Hound is unsupported on architecture $ARCH."
        return 0
    fi

    # Normalize architecture names
    if [[ "$ARCH" == "amd64" ]]; then
        ARCH="x86_64"
    elif [[ "$ARCH" == "arm64" ]]; then
        ARCH="aarch64"
    fi

    # Install the necessary dependencies
    install_dependencies "libusb-1.0-0 libspdlog-dev clang-format"

    # Create third-party directory if it doesn't exist
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty

    # Download and install the FTDI library based on architecture
    if [[ "$ARCH" == "x86_64" ]]; then
        installfromnet "wget" "https://github.com/PentHertz/rfswift_ftdi/releases/download/v1.4.34/libftd2xx-linux-x86_64-1.4.34.tgz"
        tar xvfz libftd2xx-linux-x86_64-1.4.34.tgz
        cd linux-x86_64
        cp libftd2xx.* /usr/local/lib
        chmod 0755 /usr/local/lib/libftd2xx.so.1.4.34
        # cp dereferences the tarball's libftd2xx.so symlink into a regular
        # file, which makes every later ldconfig warn "is not a symbolic link"
        ln -sf libftd2xx.so.1.4.34 /usr/local/lib/libftd2xx.so
        cp ftd2xx.h /usr/local/include
        cp WinTypes.h /usr/local/include
        ldconfig -v
        cd /root/thirdparty
    elif [[ "$ARCH" == "aarch64" ]]; then
        installfromnet "wget" "https://github.com/PentHertz/rfswift_ftdi/releases/download/v1.4.34/libftd2xx-linux-arm-v8-1.4.34.tgz"
        tar xvfz libftd2xx-linux-arm-v8-1.4.34.tgz
        cd linux-arm-v8
        cp libftd2xx.* /usr/local/lib
        chmod 0755 /usr/local/lib/libftd2xx.so.1.4.34
        # cp dereferences the tarball's libftd2xx.so symlink into a regular
        # file, which makes every later ldconfig warn "is not a symbolic link"
        ln -sf libftd2xx.so.1.4.34 /usr/local/lib/libftd2xx.so
        cp ftd2xx.h /usr/local/include
        cp WinTypes.h /usr/local/include
        ldconfig -v
        cd /root/thirdparty
    fi

    # Download and install the Signal Hound SDK
    installfromnet "wget" "https://signalhound.com/sigdownloads/SDK/signal_hound_sdk_08_26_26.zip"
    unzip -q signal_hound_sdk_08_26_26.zip
    INIT_PATH=$(pwd)

    # Select libraries by architecture and discover their versions from the
    # SDK. Signal Hound changes both version numbers and directory names.
    if [[ "$ARCH" == "x86_64" ]]; then
        SH_LIB_PATTERN="linux_x64/Ubuntu 18.04"
    else
        SH_LIB_PATTERN="aarch64"
    fi

    install_signalhound_api() {
        local series="$1" prefix="$2" library base version major
        library=$(find "$INIT_PATH/signal_hound_sdk/device_apis/$series/lib" \
            -path "*/$SH_LIB_PATTERN/*" -type f -name "$prefix.so.*" \
            2>/dev/null | sort -V | tail -1)
        if [[ -z "$library" ]]; then
            criticalecho-noexit "[!] No $prefix library for $ARCH; skipping $series"
            return 0
        fi
        base=$(basename "$library")
        version=${base#*.so.}
        major=${version%%.*}
        cp "$library" /usr/local/lib/
        chmod 0755 "/usr/local/lib/$base"
        ln -sf "$base" "/usr/local/lib/$prefix.so.$major"
        ln -sf "$prefix.so.$major" "/usr/local/lib/$prefix.so"
    }

    install_signalhound_api bb_series libbb_api
    install_signalhound_api vsg60_vsg200_series libvsg_api
    install_signalhound_api sm_series libsm_api
    install_signalhound_api sp_series libsp_api
    for series in bb_series vsg60_vsg200_series sm_series sp_series; do
        include_dir="$INIT_PATH/signal_hound_sdk/device_apis/$series/include"
        [[ -d "$include_dir" ]] && cp "$include_dir"/*.h /usr/local/include/ 2>/dev/null || true
    done
    # SP keeps its public header alongside each architecture's library.
    sp_include=$(find "$INIT_PATH/signal_hound_sdk/device_apis/sp_series/lib" \
        -path "*/$SH_LIB_PATTERN/include" -type d 2>/dev/null | head -1)
    [[ -n "$sp_include" ]] && cp "$sp_include"/*.h /usr/local/include/ 2>/dev/null || true
    ldconfig -v

    # Install tg_series library (x86_64 only based on tree output)
    if [[ "$ARCH" == "x86_64" ]]; then
        cd "$INIT_PATH/signal_hound_sdk/device_apis/tg_series/lib/linux"
        cp libtg_api.so.1.1.0 /usr/local/lib/
        chmod 0755 /usr/local/lib/libtg_api.so.1.1.0
        ln -sf /usr/local/lib/libtg_api.so.1.1.0 /usr/local/lib/libtg_api.so
        ln -sf /usr/local/lib/libtg_api.so.1.1.0 /usr/lib/libtg_api.so
        # Copy FTDI library if needed
        if [[ -f libftd2xx.so && ! -f /usr/local/lib/libftd2xx.so ]]; then
            cp libftd2xx.so /usr/local/lib/
            chmod 0755 /usr/local/lib/libftd2xx.so
        fi
        ldconfig -v
    fi

    # Return to init path
    cd "$INIT_PATH"

    # Clone and build the gr-signal-hound repository
    grclone_and_build "https://github.com/PentHertz/gr-signal-hound.git" "" "grsignalhound_Receiver_grmod_install"

    echo "[+] Signal Hound installation completed for $ARCH architecture"
}

function grm17_grmod_install() {
    grclone_and_build "https://github.com/M17-Project/gr-m17.git" "" "grm17_grmod_install"
}

function grgrnet_grmod_install() {
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ] || [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
        install_dependencies "libpthread-stubs0-dev"
        # PentHertz/gr-grnet_resolute carries the Boost >= 1.87 migration (io_context
        # / resolve() / restart()) committed upstream, so no in-place patching is needed.
        grclone_and_build "https://github.com/PentHertz/gr-grnet_resolute.git" "" "grgrnet_grmod_install"
    fi
}

function graoa_grmod_install() {
    install_dependencies "libeigen3-dev"
    grclone_and_build "https://github.com/MarcinWachowiak/gr-aoa.git" "" "graoa_grmod_install"
}

function grcorrectiq_grmod_install() {
    grclone_and_build "https://github.com/ghostop14/gr-correctiq.git" "" "grcorrectiq_grmod_install"
}

function grdsd_grmod_install() {
    install_dependencies "libitpp-dev"
    grclone_and_build "https://github.com/argilo/gr-dsd.git" "" "grdsd_grmod_install"
}

function grnrsc5_grmod_install() {
    install_dependencies  "libgsl-dev"
    grclone_and_build "https://github.com/argilo/gr-nrsc5.git" "" "grnrsc5_grmod_install"
}

function grntscrc_grmod_install() {
    grclone_and_build "https://github.com/FlUxIuS/gr-ntsc-rc.git" "" "grntscrc_grmod_install"
}

function grnfc_grmod_install() {
    grclone_and_build "https://github.com/FlUxIuS/gr-nfc.git" "" "grnfc_grmod_install"
}

function soapyrfnm_grmod_install() {
    install_dependencies "libsoapysdr-dev"
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
        grclone_and_build "https://github.com/rfnm/soapy-rfnm.git" "" "soapyrfnm_grmod_install"
    elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
        # ARM64 specific flags to avoid compiler segmentation faults
        export MAKEFLAGS="-j1"  # Single-threaded compilation
        grclone_and_build "https://github.com/rfnm/soapy-rfnm.git" "" "soapyrfnm_grmod_install" \
            -DCMAKE_CXX_FLAGS="-fno-lto -O1 -fno-strict-aliasing" \
            -DCMAKE_C_FLAGS="-fno-lto -O1 -fno-strict-aliasing"
        unset MAKEFLAGS
    fi
}

function soapyharogic_grmod_install() {
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ] || [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
        grclone_and_build "https://github.com/PentHertz/SoapyHarogic.git" "" "soapyharogic_grmod_install"
    fi
}

function hydrasdr_rfone_soapy_install() {
    grclone_and_build "https://github.com/PentHertz/SoapyHydraSDR.git" "" "hydrasdr_rfone_soapy_install"
    if [ -f /usr/lib/x86_64-linux-gnu/SoapySDR/modules0.8/libSoapyHydraSDR.so ]; then
        rm /usr/lib/x86_64-linux-gnu/SoapySDR/modules0.8/libSoapyHydraSDR.so
        echo "Removed libSoapyHydraSDR.so"
    fi
}

function grhydrasdr_grmod_install() {
    # GNU Radio OOT source block for HydraSDR (PentHertz/gr-hydrasdr). Requires
    # libhydrasdr, installed by hydrasdr_rfone_install (from hydrasdr/rfone_host) in
    # the base image; the module ships its own FindLibHYDRASDR.cmake to locate it.
    # The published repo currently carries a stale build/ dir (CMakeCache.txt pinned
    # to another absolute path), which makes cmake refuse to configure. Wipe build/
    # and configure out-of-tree. Once the fork drops the committed build/ dir this
    # can go back to a plain grclone_and_build.
    [ -d /rftools/sdr/oot ] || mkdir -p /rftools/sdr/oot
    cd /rftools/sdr/oot || exit
    gitinstall "https://github.com/PentHertz/gr-hydrasdr.git" "grhydrasdr_grmod_install" ""
    cd gr-hydrasdr || exit
    rm -rf build
    mkdir -p build && cd build
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local ../
    make -j$(nproc)
    sudo make install
    cd .. && rm -rf build/
}

function grmer_grmod_install() {
    grclone_and_build "https://github.com/git-artes/gr-mer.git" "" "grmer_grmod_install"
}

function grclenabled_grmod_install() {
    install_dependencies "libclfft-dev opencl-headers"
    ldconfig
    grclone_and_build "https://github.com/ghostop14/gr-clenabled.git" "" "grclenabled_grmod_install"
}

function grflarm_grmod_install() {
    grclone_and_build "https://github.com/argilo/gr-flarm.git" "" "grflarm_grmod_install"
}

function grguiextra_grmod_install() {
    grclone_and_build "https://github.com/ghostop14/gr-guiextra.git" "" "grguiextra_grmod_install"
}

function grrftap_grmod_install() {
    grclone_and_build "https://github.com/FlUxIuS/gr-rftap.git" "" "grrftap_grmod_install"
}

function grcessb_grmod_install() {
    grclone_and_build "https://github.com/drmpeg/gr-cessb.git" "" "grcessb_grmod_install"
}

function grhtra_grmod_install() {
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
        grclone_and_build "https://github.com/HAROGIC-Technologies/gr-htra.git" "" "grhtra_grmod_install"
    #elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
        # ARM64 specific flags to avoid LTO segmentation fault
        #grclone_and_build "https://github.com/HAROGIC-Technologies/gr-htra.git" "" "grhtra_grmod_install" \
        #    -DCMAKE_CXX_FLAGS="-fno-lto -O2" \
        #    -DCMAKE_C_FLAGS="-fno-lto -O2" // TODO: support ARM64 
    fi
}

function grradioastro_grmod_install() {
    install_dependencies "python3-ephem git cmake liborc-0.4-dev"
    grclone_and_build "https://github.com/WVURAIL/gr-radio_astro.git" "" "grradioastro_grmod_install"
}
