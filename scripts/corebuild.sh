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
        python3 python3-dev python3-pip python3-venv tzdata wget curl sudo pulseaudio udev python3-packaging vim
        autoconf build-essential cmake libsndfile-dev scapy screen tcpdump libtool libzmq3-dev
        qt5-qmake qtbase5-dev xterm libusb-1.0-0-dev pkg-config git apt-utils python3-numpy
        libusb-1.0-0 libncurses-dev libtecla1 libtecla-dev dialog procps unzip pciutils
        texlive liblog4cpp5-dev libcurl4-gnutls-dev libpcap-dev libgtk-3-dev avahi-daemon avahi-utils dbus
        qtcreator qtcreator-data qtcreator-doc qtbase5-examples qtbase5-doc-html
        qtbase5-dev qtbase5-private-dev libqt5opengl5-dev libqt5svg5-dev python3-setuptools 
        libcanberra-gtk3-module unity-tweak-tool libhdf5-dev
        libreadline-dev automake qtdeclarative5-dev libqt5serialport5-dev libfftw3-single3 libfftw3-bin libfftw3-dev
        qt6-serialbus-dev qttools5-dev python3-matplotlib libtalloc-dev
        # lubuntu-artwork satisfies lxqt-branding so apt skips lxqt-branding-debian,
        # whose /etc/xdg/lxqt/panel.conf collides with lxqt-panel >= 2.3.2 (resolute dpkg error)
        pulseaudio-utils libasound2-dev libavahi-client-dev task-lxqt-desktop lubuntu-artwork
        language-pack-en libqwt-qt5-dev python3-click-plugins python3-zmq rsync
        iw usbutils bluetooth bluez bluez-tools rfkill avahi-daemon iproute2 iptables
        qt6-base-dev qt6-base-dev-tools qt6-tools-dev qt6-tools-dev-tools libc6-dev pipx epiphany-browser
    )

    # creating a symblink for python3 for some requirements
    ln -s /usr/bin/python3 /usr/bin/python

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
    installfromnet "apt-fast install -y python3-pip" # forcing for RISC-V
    pip3install "cython"
}

function audio_tools () {
    goodecho "[+] Installing audio tools from package manager"
    installfromnet "apt-fast install -y audacity sox"
}

function flameshot_install() {
    goodecho "[+] Installing flameshot"
    install_dependencies "flameshot"
}

function rust_tools() {
    goodecho "[+] Installing RUST tools"
    # Install system cargo as fallback/build deps only
    installfromnet "apt-fast install -y cargo"
    # Install rustup with latest stable (>= 1.85 required for edition2024)
    curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable --profile minimal
    source $HOME/.cargo/env
    # Force update to ensure we get >= 1.85
    rustup update stable
    # Make rustup cargo take precedence over apt cargo (1.75) for all subsequent layers
    export PATH="$HOME/.cargo/bin:$PATH"
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
    install_dependencies "nvidia-opencl-dev nvidia-modprobe nvidia-cuda-dev"
}

function install_firefox() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64|aarch64)
            goodecho "[+] Architecture: $ARCH - using Mozilla PPA"
            add-apt-repository ppa:mozillateam/ppa -y
            printf 'Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' \
                > /etc/apt/preferences.d/mozilla-firefox
            apt-get update -q
            install_dependencies "firefox"
            ;;
        riscv64)
            criticalecho-noexit "[-] Mozilla PPA does not support riscv64, falling back to firefox-esr"
            if apt-cache show firefox-esr &>/dev/null; then
                install_dependencies "firefox-esr"
            else
                criticalecho-noexit "[-] firefox-esr not available on this riscv64 repo - skipping"
                exit 0
            fi
            ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $ARCH"
            exit 0
            ;;
    esac
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
    install_dependencies "intel-opencl-icd ocl-icd-dev ocl-icd-opencl-dev"
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
    install_dependencies "mesa-opencl-icd"
}

function install_GPU_latest_Radeon() { # tested with GPD Pocket 4
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
    

    # Add AMD GPG key before installing dependencies. apt-key was removed in
    # modern Ubuntu (26.04), so install the key as a dearmored keyring file in
    # /etc/apt/trusted.gpg.d/ instead (globally trusted, like the old apt-key).
    goodecho "[+] Adding AMD GPG key"
    install_dependencies "gnupg ca-certificates"
    wget -qO- https://repo.radeon.com/rocm/rocm.gpg.key | gpg --dearmor -o /etc/apt/trusted.gpg.d/rocm.gpg
    
    install_dependencies "mesa-utils vulkan-tools mesa-vulkan-drivers"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    # Radeon Software for Linux 26.12 (Ubuntu 26.04 HWE)
    installfromnet "wget https://repo.radeon.com/amdgpu-install/31.30/ubuntu/resolute/amdgpu-install_31.30.313000-1_all.deb"
    dpkg -i amdgpu-install_31.30.313000-1_all.deb
    # Install the open graphics + OpenCL userspace only. --accept-eula is rejected
    # unless a usecase pulls EULA-bound proprietary packages (which we don't want),
    # and --no-dkms skips the kernel module (useless in a container, and no kernel
    # headers are present anyway).
    amdgpu-install -y --no-dkms --usecase=graphics,opencl
}

install_go() {
    # Detect system architecture
    ARCH=$(uname -m)
    
    # Define URL and version
    GO_VERSION="1.26.5" # Replace with the latest version if needed
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
        echo 'export GOPROXY=https://proxy.golang.org,direct' >> /root/.bashrc
    else
        echo "Download failed. Falling back to package manager."
        install_dependencies "golang-go"
    fi
}

function install_mpir() {
    goodecho "[+] Installing MPIR"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    install_dependencies "libgmp-dev yasm m4 texinfo libfftw3-dev libsndfile1-dev"
    git clone https://github.com/wbhart/mpir.git
    cd mpir
    autoreconf -vis
    ./configure --enable-cxx
    make -j$(nproc)
    make install
    ldconfig
}

function uvpython_install_fromsources() {
    goodecho "[+] Installing UV for fast Python install"
    install_dependencies "clang libclang-dev llvm-dev build-essential"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    gitinstall "https://github.com/astral-sh/uv.git" "uvpython_install"
    cd uv
    export PATH="$HOME/.cargo/bin:$PATH"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    rustup update
    cargo build --release
    cp $(pwd)/target/release/{uv,uv-build,uv-globfilter,uvx} /usr/bin/
}

function uvpython_install() { # Avoid terrible long builds
    goodecho "[+] Installing UV for fast Python install"
    install_dependencies "clang libclang-dev llvm-dev build-essential"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    UV_VERSION="0.12.0"
    installfromnet "wget https://github.com/astral-sh/uv/releases/download/$UV_VERSION/uv-installer.sh"
    chmod +x uv-installer.sh
    ./uv-installer.sh
    ln -s /root/.local/bin/uv /usr/local/bin/uv
    echo 'export PATH="/root/.local/bin:$PATH"' >> ~/.zshrc
    echo 'export PATH="/root/.local/bin:$PATH"' >> ~/.bashrc
}

function littlesnitch_soft_install() {
    local arch
    local version="1.1.0"
    arch="$(uname -m)"
    case "$arch" in
        x86_64|amd64)
            local pkg="littlesnitch_${version}_amd64.deb"
            ;;
        aarch64|arm64)
            local pkg="littlesnitch_${version}_arm64.deb"
            ;;
        riscv64)
            local pkg="littlesnitch_${version}_riscv64.deb"
            ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $arch"
            return 1
            ;;
    esac

    goodecho "[+] Installing Little Snitch for Linux ${version} ($arch)"
    [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    cd /root/thirdparty
    installfromnet "wget -q https://obdev.at/downloads/littlesnitch-linux/${pkg}"
    dpkg-deb -x "${pkg}" /tmp/littlesnitch_extracted
    cp -r /tmp/littlesnitch_extracted/* /
    rm -rf /tmp/littlesnitch_extracted "${pkg}"

    goodecho "[+] Installing littlesnitch wrapper"
    cat > /usr/local/bin/littlesnitch << 'EOF'
#!/bin/bash
if ! mountpoint -q /sys/kernel/tracing; then
    mkdir -p /sys/kernel/tracing
    mount -t tracefs tracefs /sys/kernel/tracing
fi
exec /usr/bin/littlesnitch "$@"
EOF
    chmod +x /usr/local/bin/littlesnitch

    goodecho "[+] Little Snitch ${version} installed successfully"
    goodecho "[!] Note: container must be run with --cap-add SYS_ADMIN --cap-add DAC_READ_SEARCH"
}

function rfswift_shell_setup() {
    goodecho "[+] Setting up RF Swift shell integration"
    # Recording indicator - must be at the very end of zshrc/bashrc
    # so it runs after the prompt theme is fully loaded
    cat >> ~/.zshrc << 'RFEOF'

# RF Swift recording indicator
if [ -n "$RFSWIFT_RECORDING" ]; then
    PROMPT="%F{red} REC%f $PROMPT"
fi
RFEOF
    cat >> ~/.bashrc << 'RFEOF'

# RF Swift recording indicator
if [ -n "$RFSWIFT_RECORDING" ]; then
    PS1="\[\e[31m\] REC\[\e[0m\] $PS1"
fi
RFEOF
}