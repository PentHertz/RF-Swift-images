#!/bin/bash

function docker_preinstall() {
    # Set noninteractive and timezone
    export DEBIAN_FRONTEND=noninteractive
    export TZ=Etc/UTC

    # Basic update
    apt-get update -y

    # Install necessary tools and repositories
    apt-get install -y software-properties-common gnupg2

    # Check if gpg-agent is installed and running
    if ! command -v gpg-agent &> /dev/null; then
        echo "Installing gnupg and gpg-agent..."
        apt-get install -y gpg-agent
    fi

    # Add apt-fast repository and update
    apt-add-repository ppa:apt-fast/stable -y
    apt-get update -y
    echo apt-fast apt-fast/maxdownloads string 10 | debconf-set-selections
    echo apt-fast apt-fast/dlflag boolean true | debconf-set-selections
    echo apt-fast apt-fast/aptmanager string apt-get | debconf-set-selections

    # List of all packages
    local packages=(
        python3 python3-dev python3-pip tzdata wget curl sudo pulseaudio udev python3-packaging vim
        autoconf build-essential cmake libsndfile-dev scapy screen tcpdump libtool
        qt5-qmake qtbase5-dev xterm libusb-1.0-0-dev pkg-config git apt-utils
        libusb-1.0-0 libncurses5-dev libtecla1 libtecla-dev dialog procps unzip
        texlive liblog4cpp5-dev libcurl4-gnutls-dev libpcap-dev libgtk-3-dev
        qtcreator qtcreator-data qtcreator-doc qtbase5-examples qtbase5-doc-html
        qtbase5-dev qtbase5-private-dev libqt5opengl5-dev libqt5svg5-dev
        libcanberra-gtk-module libcanberra-gtk3-module unity-tweak-tool libhdf5-dev
        libreadline-dev automake qtdeclarative5-dev libqt5serialport5-dev
        libqt5serialbus5-dev qttools5-dev python3-matplotlib libtalloc-dev
        pulseaudio-utils libasound2-dev libavahi-client-dev task-lxqt-desktop
        language-pack-en libqwt-qt5-dev python3-click-plugins python3-zmq rsync
        iw wireless-tools usbutils bluetooth bluez bluez-tools rfkill avahi-daemon
    )

    # Install apt-fast and all other packages with apt-fast
    installfromnet "apt-get -y install apt-fast"
    installfromnet "apt-fast update"
    installfromnet "apt-fast install -y ${packages[@]} --no-install-recommends"

    # Configure keyboard and locale settings
    echo apt-fast keyboard-configuration/layout string "English (US)" | debconf-set-selections
    echo apt-fast keyboard-configuration/variant string "English (US)" | debconf-set-selections
    apt-fast -y install task-lxqt-desktop language-pack-en
    update-locale

    # Installing Cython
    installfromnet "pip3 install cython"
}

function audio_tools () {
    goodecho "[+] Installing audio tools from package manager"
    installfromnet "apt-fast install -y audacity sox"
}

function rust_tools () {
    goodecho "[+] Installing RUST tools"
    installfromnet "apt-fast install -y cargo"
    curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh -s -- -y
    source $HOME/.cargo/env
    [[ "$SHELL" =~ "zsh" ]] && { grep -qxF '. "$HOME/.cargo/env"' ~/.zshrc || echo '. "$HOME/.cargo/env"' >> ~/.zshrc; } || { grep -qxF '. "$HOME/.cargo/env"' ~/.bashrc || echo '. "$HOME/.cargo/env"' >> ~/.bashrc; }
}

function install_GPU_nvidia () {
    goodecho "[+] Installing Nvidia libs and drivers"
    install_dependencies "nvidia-opencl-dev nvidia-modprobe"
}

function install_GPU_Intel() {
    goodecho "[+] Installing Intel GPU libs and drivers"
    install_dependencies "intel-opencl-icd ocl-icd-dev ocl-icd-opencl-dev"
}

function install_GPU_Radeon_until5000() {
    goodecho "[+] Installing Intel GPU libs and drivers"
    install_dependencies "mesa-opencl-icd"
}

install_go() {
    # Detect system architecture
    ARCH=$(uname -m)
    
    # Define URL and version
    GO_VERSION="1.22.8" # Replace with the latest version if needed
    BASE_URL="https://golang.org/dl/"

    case "$ARCH" in
        "x86_64"|"amd64")
            ARCH_DL="amd64"
            ;;
        "aarch64"|"arm64")
            ARCH_DL="arm64"
            ;;
        "riscv64")
            ARCH_DL="riscv64"
            ;;
        *)
            echo "Architecture $ARCH is not recognized. Using package manager to install Go."
            install_dependencies "golang-go"
            return
            ;;
    esac

    # Construct the download URL
    GO_TAR="go${GO_VERSION}.linux-${ARCH_DL}.tar.gz"
    GO_URL="${BASE_URL}${GO_TAR}"

    # Download and install Go
    echo "Downloading Go $GO_VERSION for $ARCH..."
    wget $GO_URL -O /tmp/$GO_TAR

    if [ $? -eq 0 ]; then
        # Extract and move Go to /usr/bin/go
        sudo tar -C /usr --strip-components=1 -xzf /tmp/$GO_TAR go/bin go/pkg go/src
        rm /tmp/$GO_TAR
        echo "Go $GO_VERSION installed successfully in /usr/bin."
        echo 'export GOPROXY=direct' >> /root/.bashrc
    else
        echo "Download failed. Falling back to package manager."
        install_dependencies "golang-go"
    fi
}
