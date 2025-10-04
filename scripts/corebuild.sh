#!/bin/bash

function docker_preinstall() {
    export TZ=Etc/UTC

    # Basic update
    apk update

    # Install bash and basic tools first
    apk add --no-cache bash gnupg

    # Check if gpg-agent is installed
    if ! command -v gpg-agent &> /dev/null; then
        echo "Installing gnupg-agent..."
        apk add --no-cache gnupg-agent
    fi

    # Core system packages (guaranteed to exist)
    local core_packages=(
        python3 python3-dev py3-pip tzdata wget curl sudo vim
        autoconf build-base cmake screen tcpdump libtool zeromq-dev
        xterm libusb-dev pkgconf git py3-numpy
        libusb ncurses-dev dialog procps unzip pciutils
        curl-dev libpcap-dev gtk+3.0-dev avahi avahi-tools dbus
        mesa-dev py3-setuptools readline-dev automake
        fftw-dev py3-matplotlib talloc-dev
        pulseaudio pulseaudio-utils alsa-lib-dev avahi-dev
        py3-click-plugins rsync iw wireless-tools usbutils 
        bluez bluez-deprecated iproute2 iptables util-linux
        qt6-qtbase-dev libc-dev eudev py3-packaging
    )

    # Qt5 packages (may vary by Alpine version)
    local qt5_packages=(
        qt5-qtbase-dev qt5-qtbase qt5-qtsvg-dev
        qt5-qtdeclarative-dev qt5-qtserialport-dev
        qt5-qttools-dev
    )

    # Optional packages (might not exist in all Alpine versions)
    local optional_packages=(
        libsndfile-dev libcanberra-gtk3 hdf5-dev
        texlive log4cpp-dev lxqt-about
    )

    # Creating a symlink for python3
    ln -sf /usr/bin/python3 /usr/bin/python

    # Install core packages
    goodecho "[+] Installing core packages"
    installfromnet "apk add --no-cache ${core_packages[@]}"

    # Install Qt5 packages
    goodecho "[+] Installing Qt5 packages"
    installfromnet "apk add --no-cache ${qt5_packages[@]}" || {
        criticalecho-noexit "[-] Some Qt5 packages failed to install"
    }

    # Install optional packages (don't fail if missing)
    goodecho "[+] Installing optional packages"
    for pkg in "${optional_packages[@]}"; do
        apk add --no-cache "$pkg" 2>/dev/null || {
            goodecho "[!] Package $pkg not available, skipping"
        }
    done

    # Try to install qt5-qtserialbus-dev if available
    apk add --no-cache qt5-qtserialbus-dev 2>/dev/null || {
        goodecho "[!] qt5-qtserialbus-dev not available in this Alpine version"
    }

    # Configure locale
    apk add --no-cache musl-locales musl-locales-lang 2>/dev/null || true
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    # Install Python packages not available in Alpine repos
    goodecho "[+] Installing Python packages via pip"
    pip3install "scapy"
    pip3install "pyzmq"
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
    GO_VERSION="1.23.4"
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
        grep -qxF 'export GOPROXY=direct' /root/.profile 2>/dev/null || echo 'export GOPROXY=direct' >> /root/.profile
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
    
    ldconfig /usr/local/lib 2>/dev/null || true
}

function uvpython_install() {
    goodecho "[+] Installing UV via pip (pre-built binary)"
    
    # Install uv using pip (provides pre-built binaries)
    pip3install uv
    
    # Ensure uv is in PATH
    export PATH="$HOME/.local/bin:$PATH"
    grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' /root/.bashrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> /root/.bashrc
    
    # Verify installation
    if command -v uv &> /dev/null; then
        goodecho "[+] UV $(uv --version) installed successfully"
    else
        criticalecho-noexit "[-] UV installation failed"
    fi
    
    goodecho "[+] UV installation completed"
}