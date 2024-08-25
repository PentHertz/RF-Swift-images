#!/bin/bash

function common_sources_and_sinks() {
    grclone_and_build "https://github.com/osmocom/gr-osmosdr.git" "" "common_sources_and_sinks"
}

function grgsm_grmod_install() {
    install_dependencies "build-essential libtool libtalloc-dev libsctp-dev shtool autoconf automake git-core pkg-config make gcc gnutls-dev libusb-1.0-0-dev libmnl-dev libosmocore libosmocore-dev"
    grclone_and_build "https://github.com/bkerler/gr-gsm.git" "" "grgsm_grmod_install"
}

function grlora_grmod_install() {
    install_dependencies "libliquid-dev libliquid2d"
    grclone_and_build "https://github.com/rpp0/gr-lora.git" "" "grlora_grmod_install"
}

function grlorasdr_grmod_install() {
    grclone_and_build "https://github.com/tapparelj/gr-lora_sdr.git" "" "grlorasdr_grmod_install"
}

function grinspector_grmod_install() {
    install_dependencies "libqwt-qt5-dev"
    grclone_and_build "https://github.com/gnuradio/gr-inspector.git" "" "grinspector_grmod_install"
}

function griridium_grmod_install() {
    grclone_and_build "https://github.com/muccc/gr-iridium.git" "" "griridium_grmod_install"
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
    grclone_and_build "https://github.com/sandialabs/gr-pdu_utils.git" "" "grpdu_utils_grmod_install"
}

function grsandia_utils_grmod_install() {
    grclone_and_build "https://github.com/bkerler/gr-sandia_utils.git" "" "grsandia_utils_grmod_install"
}

function grdvbs2_grmod_install() {
    grclone_and_build "https://github.com/bkerler/gr-dvbs2.git" "" "grdvbs2_grmod_install"
}

function grtempest_grmod_install() { 
    grclone_and_build "https://github.com/nash-pillai/gr-tempest.git" "" "grtempest_grmod_install"
}

function deeptempest_grmod_install() {
    grclone_and_build "https://github.com/PentHertz/deep-tempest.git" "gr-tempest" "deeptempest_grmod_install"
    cd deep-tempest/examples
    grcc *.grc
    mkdir -p /root/.grc_gnuradio
    cp *.block.yml /root/.grc_gnuradio
    cd ../..
    goodecho "[+] Installing requirements for deep-tempest"
    cd end-to-end/
    installfromnet "pip3 install -r requirement.txt"
}

function grfhss_utils_grmod_install() {
    grclone_and_build "https://github.com/sandialabs/gr-fhss_utils.git" "" "grfhss_utils_grmod_install"
}

function grtiming_utils_grmod_install() {
    grclone_and_build "https://github.com/sandialabs/gr-timing_utils.git" "" "grtiming_utils_grmod_install"
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

function grieee802154_grmod_install() {
    grclone_and_build "https://github.com/bastibl/gr-ieee802-15-4.git" "" "grieee802154_grmod_install"
}

function grrds_grmod_install() {
    install_dependencies "libboost-all-dev"
    grclone_and_build "https://github.com/bastibl/gr-rds.git" "" "grrds_grmod_install"
}

function grfosphor_grmod_install() {
    install_dependencies "cmake xorg-dev libglu1-mesa-dev opencl-headers libwayland-dev libxkbcommon-dev"
    goodecho "[+] Cloning and building GLFW3"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    cmake_clone_and_build "https://github.com/glfw/glfw" "build" "" "" "grfosphor_grmod_install" -DBUILD_SHARED_LIBS=true
    cd /root/thirdparty
    grclone_and_build "https://github.com/osmocom/gr-fosphor.git" "" "grfosphor_grmod_install"
}

function grdroineid_grmod_install() {
    goodecho "[+] Cloning turbofec"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    gitinstall "https://github.com/zlinwei/turbofec.git"
    cd turbofec 
    autoreconf -i
    ./configure
    make -j$(nproc); sudo make install
    cd /root/thirdparty
    goodecho "[+] Cloning CRCpp"
    cmake_clone_and_build "https://github.com/d-bahr/CRCpp.git" "build" "" "" "grdroineid_grmod_install"
    cd /root/thirdparty
    goodecho "[+] Cloning dji_droneid"
    grclone_and_build "https://github.com/proto17/dji_droneid.git" "gnuradio/gr-droneid" "grdroineid_grmod_install" -b "gr-droneid"
}

function grsatellites_grmod_install() {
    install_dependencies "liborc-0.4-dev"
    installfromnet "pip3 install --user --upgrade construct requests"
    grclone_and_build "https://github.com/daniestevez/gr-satellites.git" "" "grsatellites_grmod_install"
}

function gradsb_grmod_install() {
    installfromnet "pip3 install zmq flask flask-socketio gevent gevent-websocket"
    grclone_and_build "https://github.com/mhostetter/gr-adsb" "" "gradsb_grmod_install"
}

function grkeyfob_grmod_install() {
    grclone_and_build "https://github.com/bastibl/gr-keyfob.git" "" "grkeyfob_grmod_install"
}

function grradar_grmod_install() {
    grclone_and_build "https://github.com/radioconda/gr-radar.git" "" "grradar_grmod_install"
}

function grnordic_grmod_install() {
    grclone_and_build "https://github.com/bkerler/gr-nordic.git" "" "grnordic_grmod_install"
}

function grpaint_grmod_install() {
    grclone_and_build "https://github.com/drmpeg/gr-paint.git" "" "grpaint_grmod_install"
}

function gr_DCF77_Receiver_grmod_install() {
    [ -d /rftools/sdr/oot ] || mkdir -p /rftools/sdr/oot
    cd /rftools/sdr/oot || exit
    gitinstall "https://github.com/henningM1r/gr_DCF77_Receiver.git" "gr_DCF77_Receiver_grmod_install"
}

function grbb60_Receiver_grmod_install() {
    install_dependencies "libusb-1.0-0"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    installfromnet "wget https://ftdichip.com/wp-content/uploads/2022/07/libftd2xx-x86_64-1.4.27.tgz"
    tar xvfz libftd2xx-x86_64-1.4.27.tgz
    cd release/build
    cp libftd2xx.* /usr/local/lib
    chmod 0755 /usr/local/lib/libftd2xx.so.1.4.27
    ln -sf /usr/local/lib/libftd2xx.so.1.4.27 /usr/local/lib/libftd2xx.so
    cd ..
    cp ftd2xx.h  /usr/local/include
    cp WinTypes.h  /usr/local/include
    ldconfig -v
    installfromnet "wget https://signalhound.com/sigdownloads/SDK/signal_hound_sdk_06_24_24.zip"
    unzip signal_hound_sdk_06_24_24.zip
    cd "signal_hound_sdk/device_apis/bb_series/lib/linux/Ubuntu 18.04"
    cp libbb_api.* /usr/local/lib
    ldconfig -v -n /usr/local/lib
    ln -sf /usr/local/lib/libbb_api.so.5 /usr/local/lib/libbb_api.so
    grclone_and_build "https://github.com/SignalHound/gr-bb60.git" "" "grbb60_Receiver_grmod_install"
}