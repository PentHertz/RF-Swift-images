#!/bin/bash

function docker_preinstall() {
    local packages=(
        python3 wget curl sudo software-properties-common gpg-agent pulseaudio udev
        python3-packaging vim autoconf build-essential cmake python3-pip libsndfile-dev
        scapy screen tcpdump qt5-qmake qtbase5-dev xterm libusb-1.0-0-dev pkg-config
        git apt-utils libusb-1.0-0 libncurses5-dev libtecla1 libtecla-dev dialog
        procps unzip texlive liblog4cpp5-dev libcurl4-gnutls-dev libpcap-dev libgtk-3-dev
        qtcreator qtcreator-data qtcreator-doc qtbase5-examples qtbase5-doc-html
        qtbase5-dev qtbase5-private-dev libqt5opengl5-dev libqt5svg5-dev
        libcanberra-gtk-module libcanberra-gtk3-module unity-tweak-tool libhdf5-dev
        libreadline-dev automake qtdeclarative5-dev libqt5serialport5-dev
        libqt5serialbus5-dev qttools5-dev golang-go python3-matplotlib
        pulseaudio-utils libasound2-dev libavahi-client-dev task-lxqt-desktop
        language-pack-en tzdata
    )

    local apt_fast_packages=(
        apt-fast
    )

    local desktop_features=(
        task-lxqt-desktop language-pack-en
    )

    local audio_packages=(
        pulseaudio-utils pulseaudio libasound2-dev libavahi-client-dev
    )

    # Set noninteractive and timezone
    export DEBIAN_FRONTEND=noninteractive
    export TZ=Etc/UTC

    # Add apt-fast repository and update
    apt-add-repository ppa:apt-fast/stable -y
    apt-get update
    echo apt-fast apt-fast/maxdownloads string 10 | debconf-set-selections
    echo apt-fast apt-fast/dlflag boolean true | debconf-set-selections
    echo apt-fast apt-fast/aptmanager string apt-get | debconf-set-selections

    # Install apt-fast and matplotlib with apt-fast
    apt-get -y install "${apt_fast_packages[@]}"

    # Use apt-fast to install packages
    apt-fast install -y "${packages[@]}" --no-install-recommends

    # Configure keyboard and locale settings
    echo apt-fast keyboard-configuration/layout string "English (US)" | debconf-set-selections
    echo apt-fast keyboard-configuration/variant string "English (US)" | debconf-set-selections
    apt-fast -y install "${desktop_features[@]}"
    update-locale
}