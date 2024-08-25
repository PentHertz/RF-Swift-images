#!/bin/bash

function common_sources_and_sinks() {
    grclone_and_build "https://github.com/osmocom/gr-osmosdr.git"
}

function grgsm_grmod_install() {
    install_dependencies "build-essential libtool libtalloc-dev libsctp-dev shtool autoconf automake git-core pkg-config make gcc gnutls-dev libusb-1.0-0-dev libmnl-dev libosmocore libosmocore-dev"
    grclone_and_build "https://github.com/bkerler/gr-gsm.git"
}

function grlora_grmod_install() {
    install_dependencies "libliquid-dev libliquid2d"
    grclone_and_build "https://github.com/rpp0/gr-lora.git"
}

function grlorasdr_grmod_install() {
    grclone_and_build "https://github.com/tapparelj/gr-lora_sdr.git"
}

function grinspector_grmod_install() {
    install_dependencies "libqwt-qt5-dev"
    grclone_and_build "https://github.com/gnuradio/gr-inspector.git"
}

function griridium_grmod_install() {
    grclone_and_build "https://github.com/muccc/gr-iridium.git"
}

function gruaslink_grmod_install() { 
    grclone_and_build "https://github.com/bkerler/gr-uaslink.git"
}

function grX10_grmod_install() {
    grclone_and_build "https://github.com/cpoore1/gr-X10.git"
}

function grgfdm_grmod_install() {
    grclone_and_build "https://github.com/bkerler/gr-gfdm.git"
}

function graaronia_rtsa_grmod_install() {
    install_dependencies "rapidjson-dev"
    goodecho "[+] Cloning and installing libspectranstream"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    cmake_clone_and_build " https://github.com/hb9fxq/libspectranstream.git" "build"
    cd /root/thirdparty
    grclone_and_build "https://github.com/hb9fxq/gr-aaronia_rtsa.git"
}

function grccsds_move_rtsa_grmod_install() {
    install_dependencies "rapidjson-dev"
    grclone_and_build "https://github.com/bkerler/gr-ccsds_move.git"
}

function grais_grmod_install() {
    grclone_and_build "https://github.com/bkerler/gr-ais.git"
}

function graistx_grmod_install() {
    grclone_and_build "https://github.com/bkerler/ais.git" "ais/gr-aistx"
}

function grairmodes_grmod_install() {
    grclone_and_build "https://github.com/bistromath/gr-air-modes.git"
}

function grj2497_grmod_install() {
    grclone_and_build "https://github.com/ainfosec/gr-j2497.git"
}

function grzwavepoore_grmod_install() {
    grclone_and_build "https://github.com/cpoore1/gr-zwave_poore.git"
}

function grmixalot_grmod_install() {
    grclone_and_build "https://github.com/unsynchronized/gr-mixalot.git"
}

function grreveng_grmod_install() {
    grclone_and_build "https://github.com/paulgclark/gr-reveng.git"
}

function grpdu_utils_grmod_install() {
    grclone_and_build "https://github.com/sandialabs/gr-pdu_utils.git"
}

function grsandia_utils_grmod_install() {
    grclone_and_build "https://github.com/bkerler/gr-sandia_utils.git"
}

function grdvbs2_grmod_install() {
    grclone_and_build "https://github.com/bkerler/gr-dvbs2.git"
}

function grtempest_grmod_install() { 
    grclone_and_build "https://github.com/nash-pillai/gr-tempest.git"
}

function deeptempest_grmod_install() {
    grclone_and_build "https://github.com/PentHertz/deep-tempest.git" "deep-tempest/gr-tempest"
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
    grclone_and_build "https://github.com/sandialabs/gr-fhss_utils.git"
}

function grtiming_utils_grmod_install() {
    grclone_and_build "https://github.com/sandialabs/gr-timing_utils.git"
}

function grdab_grmod_install() {
    install_dependencies "libfaad-dev"
    grclone_and_build "https://github.com/bkerler/gr-dab.git"
}

function grdect2_grmod_install() {
    grclone_and_build "https://github.com/pavelyazev/gr-dect2.git"
}

function grfoo_grmod_install() {
    grclone_and_build "https://github.com/bastibl/gr-foo.git"
}

function grieee802-11_grmod_install() {
    grclone_and_build "https://github.com/bastibl/gr-ieee802-11.git"
}

function grieee802154_grmod_install() {
    grclone_and_build "https://github.com/bastibl/gr-ieee802-15-4.git"
}

function grrds_grmod_install() {
    install_dependencies "libboost-all-dev"
    grclone_and_build "https://github.com/bastibl/gr-rds.git"
}

function grfosphor_grmod_install() {
    install_dependencies "cmake xorg-dev libglu1-mesa-dev opencl-headers libwayland-dev libxkbcommon-dev"
    goodecho "[+] Cloning and building GLFW3"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    cmake_clone_and_build "https://github.com/glfw/glfw" "build" -DBUILD_SHARED_LIBS=true
    cd /root/thirdparty
    grclone_and_build "https://github.com/osmocom/gr-fosphor.git"
}

function grdroineid_grmod_install() {
    goodecho "[+] Cloning turbofec"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    cmake_clone_and_build "https://github.com/zlinwei/turbofec.git" "build"
    cd /root/thirdparty
    cmake_clone_and_build "https://github.com/d-bahr/CRCpp.git" "build"
    grclone_and_build "https://github.com/proto17/dji_droneid.git" "dji_droneid/gnuradio/gr-droneid" -b "gr-droneid"
}

function grsatellites_grmod_install() {
    install_dependencies "liborc-0.4-dev"
    installfromnet "pip3 install --user --upgrade construct requests"
    grclone_and_build "https://github.com/daniestevez/gr-satellites.git"
}

function gradsb_grmod_install() {
    installfromnet "pip3 install zmq flask flask-socketio gevent gevent-websocket"
    grclone_and_build "https://github.com/mhostetter/gr-adsb"
}

function grkeyfob_grmod_install() {
    grclone_and_build "https://github.com/bastibl/gr-keyfob.git"
}

function grradar_grmod_install() {
    grclone_and_build "https://github.com/radioconda/gr-radar.git"
}

function grnordic_grmod_install() {
    grclone_and_build "https://github.com/bkerler/gr-nordic.git"
}

function grpaint_grmod_install() {
    grclone_and_build "https://github.com/drmpeg/gr-paint.git"
}

function gr_DCF77_Receiver_grmod_install() {
    grclone_and_build "https://github.com/henningM1r/gr_DCF77_Receiver.git"
}

function grbb60_Receiver_grmod_install() {
    install_dependencies "libusb-1.0-0"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    installfromnet "wget https://ftdichip.com/wp-content/uploads/2022/07/libftd2xx-x86_64-1.4.27.tgz"
    cd tar xvfz libftd2xx-x86_64-1.4.27.tgz
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
    grclone_and_build "https://github.com/SignalHound/gr-bb60.git"
}