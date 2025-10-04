#!/bin/bash

function docker_preinstall() {
    export TZ=Etc/UTC

    # Basic update
    apk update

    # Install necessary tools (Alpine equivalents)
    apk add --no-cache bash gnupg

    # Check if gpg-agent is installed
    if ! command -v gpg-agent &> /dev/null; then
        echo "Installing gnupg-agent..."
        apk add --no-cache gnupg-agent
    fi

    local packages=(
        python3 python3-dev py3-pip tzdata wget curl sudo pulseaudio eudev py3-packaging vim
        autoconf build-base cmake libsndfile-dev py3-scapy screen tcpdump libtool zeromq-dev
        qt5-qtbase-dev xterm libusb-dev pkgconf git py3-numpy
        libusb ncurses-dev libtecla libtecla-dev dialog procps unzip pciutils
        texlive log4cpp-dev curl-dev libpcap-dev gtk+3.0-dev avahi avahi-tools dbus
        qt5-qtbase qt5-qtbase-dev mesa-dev qt5-qtsvg-dev py3-setuptools 
        libcanberra-gtk3 hdf5-dev
        readline-dev automake qt5-qtdeclarative-dev qt5-qtserialport-dev fftw-dev
        qt5-qtserialbus-dev qt5-qttools-dev py3-matplotlib talloc-dev
        pulseaudio-utils alsa-lib-dev avahi-dev lxqt-about
        py3-click-plugins py3-zmq rsync
        iw wireless-tools usbutils bluez bluez-deprecated rfkill iproute2 iptables
        qt6-qtbase-dev libc-dev py3-pipx
    )

    # Creating a symlink for python3
    ln -sf /usr/bin/python3 /usr/bin/python

    # Install all packages with apk
    installfromnet "apk add --no-cache ${packages[@]}"

    # Configure locale (Alpine handles this differently with musl)
    apk add --no-cache musl-locales musl-locales-lang
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    # Installing Cython
    pip3install "cython"
}

function audio_tools () {
    goodecho "[+] Installing audio tools from package manager"
    installfromnet "apk add --no-cache audacity sox"
}

function rust_tools () {
    goodecho "[+] Installing RUST tools"
    installfromnet "apk add --no-cache cargo rust"
    curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh -s -- -y
    source $HOME/.cargo/env
    [[ "$SHELL" =~ "zsh" ]] && { grep -qxF '. "$HOME/.cargo/env"' ~/.zshrc || echo '. "$HOME/.cargo/env"' >> ~/.zshrc; } || { grep -qxF '. "$HOME/.cargo/env"' ~/.bashrc || echo '. "$HOME/.cargo/env"' >> ~/.bashrc; }
}

function install_GPU_nvidia () {
    ARCH=$(uname -m)

    case "$ARCH" in
        x86_64|amd64)
            goodecho "[+] Architecture: x86_64"
            goodecho "[+] Installing Nvidia libs and drivers"
            ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $ARCH"
            exit 0
            ;;
    esac
    
    goodecho "[!] Note: Installing Mesa as NVIDIA proprietary drivers have limited Alpine support"
    install_dependencies "mesa-dev mesa-dri-gallium"
    goodecho "[!] For full NVIDIA support, consider using nvidia-docker runtime or Ubuntu-based image"
}

function install_GPU_Intel() {
    ARCH=$(uname -m)

    case "$ARCH" in
        x86_64|amd64)
            goodecho "[+] Architecture: x86_64"
            goodecho "[+] Installing Intel GPU libs and drivers"
            ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $ARCH"
            exit 0
            ;;
    esac
    install_dependencies "mesa-dev mesa-dri-gallium intel-media-driver"
}

function install_GPU_Radeon_until5000() {
    ARCH=$(uname -m)

    case "$ARCH" in
        x86_64|amd64)
            goodecho "[+] Installing Radeon old GPU libs and drivers"
            ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $ARCH"
            exit 0
            ;;
    esac
    install_dependencies "mesa-dev mesa-dri-gallium"
}

function install_GPU_latest_Radeon() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64|amd64)
            goodecho "[+] Installing Radeon latest GPU libs and drivers"
            ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $ARCH"
            exit 0
            ;;
    esac
    
    # Alpine doesn't support AMD ROCm packages directly
    goodecho "[!] Note: AMD ROCm is not available for Alpine Linux"
    goodecho "[!] Installing Mesa Vulkan drivers as alternative"
    
    install_dependencies "mesa-utils mesa-vulkan-ati mesa-dri-gallium vulkan-tools"
    
    goodecho "[!] For full AMD ROCm support, consider using Ubuntu-based image"
    goodecho "[!] You can use gcompat for some glibc compatibility if needed"
}

install_go() {
    # Detect system architecture
    ARCH=$(uname -m)
    
    # Define URL and version
    GO_VERSION="1.23.4" # Using a stable version known to work well
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
            install_dependencies "go"
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
        # Extract and move Go to /usr
        tar -C /usr --strip-components=1 -xzf /tmp/$GO_TAR go/bin go/pkg go/src
        rm /tmp/$GO_TAR
        echo "Go $GO_VERSION installed successfully in /usr/bin."
        echo 'export GOPROXY=direct' >> /root/.bashrc
        
        # Also add to .profile for better compatibility
        grep -qxF 'export GOPROXY=direct' /root/.profile || echo 'export GOPROXY=direct' >> /root/.profile
    else
        echo "Download failed. Falling back to package manager."
        install_dependencies "go"
    fi
}

function install_mpir() {
    goodecho "[+] Installing MPIR"
    [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    cd /root/thirdparty
    
    # Install build dependencies
    install_dependencies "gmp-dev yasm m4 texinfo fftw-dev libsndfile-dev git"
    
    git clone https://github.com/wbhart/mpir.git
    cd mpir
    autoreconf -vis
    ./configure --enable-cxx
    make -j$(nproc)
    make install
    
    # Update library cache (Alpine uses ldconfig differently)
    ldconfig /usr/local/lib || true
}

function uvpython_install() {
    goodecho "[+] Installing UV for fast Python install"
    [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    cd /root/thirdparty
    
    # Ensure rust/cargo is installed
    if ! command -v cargo &> /dev/null; then
        goodecho "[+] Installing Rust for UV compilation"
        apk add --no-cache cargo rust
    fi
    
    gitinstall "https://github.com/astral-sh/uv.git" "uvpython_install"
    cd uv
    
    # Ensure cargo is in PATH
    export PATH="$HOME/.cargo/bin:$PATH"
    
    # Install rustup if not already installed
    if ! command -v rustup &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source $HOME/.cargo/env
    fi
    
    rustup update
    cargo build --release
    
    # Copy binaries
    cp $(pwd)/target/release/uv /usr/bin/ 2>/dev/null || true
    cp $(pwd)/target/release/uvx /usr/bin/ 2>/dev/null || true
    
    goodecho "[+] UV installation completed"
}