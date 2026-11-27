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
    installfromnet "apt-get" "-y" "install" "apt-fast"
    installfromnet "apt-fast" "update"
    installfromnet "apt-fast" "install" "-y" "${packages[@]}" "--no-install-recommends"

    # Configure keyboard and locale settings
    echo apt-fast keyboard-configuration/layout string "English (US)" | debconf-set-selections
    echo apt-fast keyboard-configuration/variant string "English (US)" | debconf-set-selections
    apt-fast -y install task-lxqt-desktop language-pack-en
    update-locale

    # Installing Cython
    installfromnet "apt-fast" "install" "-y" "python3-pip" # forcing for RISC-V
    pip3install "cython"
}

function audio_tools () {
    goodecho "[+] Installing audio tools from package manager"
    installfromnet "apt-fast" "install" "-y" "audacity" "sox"
}

function flameshot_install() {
    goodecho "[+] Installing flameshot"
    install_dependencies "flameshot"
}

function common_utils_install() {
    goodecho "[+] Installing common CLI/GUI utilities"
    # diff/compare, hex & binary viewers, text/data processing
    install_dependencies "colordiff meld git-delta xxd hexyl bsdextrautils file jq yq ripgrep fd-find bat dos2unix moreutils less nano"
    # terminal & system monitoring, archives, process debugging
    install_dependencies "tmux mc tree ncdu htop btop pv bc tealdeer 7zip zip xz-utils zstd lsof strace ltrace"
    # basic networking clients and X11 clipboard helpers
    install_dependencies "openssh-client net-tools iputils-ping bind9-dnsutils traceroute xclip xsel"
    # Recoll full-text desktop search (GUI + recollindex/recollq) with filters for PDF, Office and RTF documents
    install_dependencies "recoll poppler-utils antiword unrtf python3-chardet python3-lxml"
    # Debian/Ubuntu ship fd and bat as fdfind/batcat: expose the upstream names
    [ -x /usr/bin/fdfind ] && ln -sf /usr/bin/fdfind /usr/local/bin/fd
    [ -x /usr/bin/batcat ] && ln -sf /usr/bin/batcat /usr/local/bin/bat
    return 0
}

function enable_apt_components() {
    local components="main restricted universe multiverse"
    if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
        sed -i -E "s/^Components:.*/Components: ${components}/" \
            /etc/apt/sources.list.d/ubuntu.sources
    fi
    if [ -s /etc/apt/sources.list ]; then
        sed -i -E "s/^deb(-src)?[[:space:]]+([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+.*/deb\1 \2 \3 ${components}/" \
            /etc/apt/sources.list
    fi
    grep -hE '^(Components:|deb )' /etc/apt/sources.list.d/*.sources /etc/apt/sources.list 2>/dev/null
}

function rust_tools() {
    goodecho "[+] Installing RUST tools"
    # Install system cargo as fallback/build deps only
    installfromnet "apt-fast" "install" "-y" "cargo"
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
    installfromnet "wget" "https://repo.radeon.com/amdgpu-install/31.30/ubuntu/resolute/amdgpu-install_31.30.313000-1_all.deb"
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
    GO_VERSION="1.27.4" # known-good; the build takes the newest stable release from go.dev
    BASE_URL="https://go.dev/dl/"

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

    # Newest stable Go and its sha256 from go.dev's release list; known-good if the lookup
    # fails. The archive is checked whenever go.dev lists a sha256 for it.
    local go_json go_latest go_sha
    go_json=$(curl -fsSL --max-time 30 'https://go.dev/dl/?mode=json' 2>/dev/null || true)
    go_latest=$(printf '%s\n' "$go_json" | grep -m1 -oE '"version": *"go[0-9]+(\.[0-9]+)+"' \
        | grep -oE '[0-9]+(\.[0-9]+)+' || true)
    GO_VERSION=$(pick_version go "$go_latest" "$GO_VERSION")
    GO_TAR="go${GO_VERSION}.linux-${ARCH_DL}.tar.gz"
    GO_URL="${BASE_URL}${GO_TAR}"
    go_sha=$(printf '%s\n' "$go_json" | grep -A4 "\"filename\": *\"${GO_TAR//./\\.}\"" \
        | grep -m1 -oE '[0-9a-f]{64}' || true)

    # Download and install Go
    echo "Downloading Go $GO_VERSION for $ARCH..."
    if wget "$GO_URL" -O "/tmp/$GO_TAR" \
        && { [ -z "$go_sha" ] || echo "${go_sha}  /tmp/$GO_TAR" | sha256sum -c -; }; then
        # Extract and move Go to /usr/bin/go
        # go.env holds Go's defaults (GOPROXY, GOSUMDB, GOTOOLCHAIN): without it GOPROXY is
        # empty and no module can be downloaded
        sudo tar -C /usr --strip-components=1 -xzf /tmp/$GO_TAR go/bin go/pkg go/src go/go.env
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
    UV_VERSION="0.13.9"  # known-good; the build takes the newest release
    UV_VERSION=$(latest_release_version astral-sh/uv "$UV_VERSION" \
        "https://github.com/astral-sh/uv/releases/download/@V@/uv-installer.sh")
    installfromnet "wget" "https://github.com/astral-sh/uv/releases/download/$UV_VERSION/uv-installer.sh"
    chmod +x uv-installer.sh
    ./uv-installer.sh
    ln -s /root/.local/bin/uv /usr/local/bin/uv
    echo 'export PATH="/root/.local/bin:$PATH"' >> ~/.zshrc
    echo 'export PATH="/root/.local/bin:$PATH"' >> ~/.bashrc
}

function littlesnitch_soft_install() {
    local arch
    local version="1.1.1"
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
    installfromnet "wget" "-q" "https://obdev.at/downloads/littlesnitch-linux/${pkg}"
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

# See (wibus-wee/see, https://see.wibus.ren): native desktop source-code reader for extracted
# firmware, tool sources and scripts. File tree, tabs, fuzzy file/symbol search, workspace
# search (ripgrep), Git status/diff/blame/history, terminal, Markdown and hex preview, and
# language servers (gopls, clangd, TypeScript) when they are installed.
#   see [file-or-folder]   see --diff <a> <b>   some-command | see -
# The Linux tarball, not the .deb: the binary loads GTK 3 and its usual libraries at run time
# (corebuild has them) and never WebKitGTK, which the .deb declares anyway.
# The newest release is taken at build time and checked like See's own updater does: the
# ed25519 signature of the tarball's SHA-256, from update-linux-<arch>.json, against See's
# update public key (mygo.json in the repo). SEE_VERSION is the known-good fallback.
# Automatic update checks start off (updater.json, like the other tools' update checks);
# Settings > Updates turns them back on.
SEE_VERSION="0.3.9"
SEE_UPDATE_PUBKEY="zqudRNfvgRsHbNMYIlH4FywgyKmPrAl4w64zAbhFhFk="

# see_verify ARCHIVE SIGNATURE_BASE64: ed25519 signature of the archive's SHA-256 digest.
function see_verify() {
    local tmp rc=0
    tmp=$(mktemp -d)
    { printf '\x30\x2a\x30\x05\x06\x03\x2b\x65\x70\x03\x21\x00'; printf '%s' "$SEE_UPDATE_PUBKEY" | base64 -d; } > "$tmp/pub.der"
    if ! printf '%s' "$2" | base64 -d > "$tmp/sig" 2> /dev/null \
        || ! openssl pkey -pubin -inform DER -in "$tmp/pub.der" -out "$tmp/pub.pem" 2> /dev/null \
        || ! openssl dgst -sha256 -binary -out "$tmp/digest" "$1" \
        || ! openssl pkeyutl -verify -pubin -inkey "$tmp/pub.pem" -rawin -in "$tmp/digest" -sigfile "$tmp/sig" > /dev/null; then
        rc=1
    fi
    rm -rf "$tmp"
    return "$rc"
}

function see_soft_install() {
    goodecho "[+] Installing See (source-code reader)"
    local arch
    case "$(uname -m)" in
        x86_64|amd64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *) criticalecho-noexit "[-] See: no Linux release for $(uname -m), skipping"; return 0 ;;
    esac
    install_dependencies "openssl jq libgtk-3-0t64 libepoxy0 libsecret-1-0"
    local base="https://github.com/wibus-wee/see/releases/download" ver tmp sig
    ver=$(latest_release_version wibus-wee/see "$SEE_VERSION" \
        "$base/v@V@/see-@V@-linux-${arch}.tar.gz" "$base/v@V@/update-linux-${arch}.json")
    tmp=$(mktemp -d)
    if ! installfromnet curl -fsSL --max-time 300 -o "$tmp/see.tar.gz" "$base/v${ver}/see-${ver}-linux-${arch}.tar.gz" \
        || ! installfromnet curl -fsSL --max-time 60 -o "$tmp/update.json" "$base/v${ver}/update-linux-${arch}.json"; then
        rm -rf "$tmp"
        record_build_failure "net" "see" "download of ${ver} failed"
        return 0
    fi
    sig=$(jq -r --arg f "see-${ver}-linux-${arch}.tar.gz" 'select(.url | endswith("/" + $f)) | .signature // empty' "$tmp/update.json" 2> /dev/null || true)
    if [ -z "$sig" ] || ! see_verify "$tmp/see.tar.gz" "$sig"; then
        rm -rf "$tmp"
        record_build_failure "verify" "see" "${ver} tarball does not match the signature in update-linux-${arch}.json"
        return 0
    fi
    rm -rf /opt/see
    mkdir -p /opt/see
    tar -xzf "$tmp/see.tar.gz" -C /opt/see --no-same-owner
    rm -rf "$tmp"
    # The `see` shell command is a symlink to the binary (See tells a shell call from a launch
    # that way); the menu entry starts the binary itself, which opens See's welcome window.
    ln -sf /opt/see/see /usr/local/bin/see
    install -Dm644 /opt/see/see.png /usr/share/pixmaps/see.png
    cat > /usr/share/applications/see.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=See
Comment=Read source code: tree, search, Git history, hex and Markdown preview
Exec=/opt/see/see
Icon=see
Categories=Development;Utility;
Terminal=false
StartupWMClass=see
EOF
    mkdir -p /root/.config/See
    [ -s /root/.config/See/updater.json ] || printf '{"automaticChecks":false}\n' > /root/.config/See/updater.json
    see --help > /dev/null 2>&1 || record_build_failure "other" "see" "see --help does not run"
    goodecho "[+] See ${ver} installed: see [file-or-folder], see --diff <a> <b>"
    return 0
}

# ---------------------------------------------------------------------------
# CRC and checksum reverse engineering, for radio frames (rtl_433, URH, inspectrum captures)
# and firmware images and headers. All three are checked with a known answer at build time.
#  - CRC RevEng (Greg Cook, https://reveng.sourceforge.io): finds a CRC's width, polynomial,
#    init, reflection and xorout from message+CRC samples (`reveng -w 16 -s <hex> <hex> ...`;
#    give 4 or more), computes any of its 113 catalogue presets (`reveng -m CRC-16/MODBUS -c <hex>`,
#    `reveng -D` lists them) and reverses a CRC (the bits that give a wanted value). It prints a
#    CRC in the byte order it has in the message (little-endian for reflected CRCs).
#  - delsum (8051Enthusiast): CRCs, modular sums and Fletcher checksums. `delsum reverse` finds the
#    algorithm from files and their checksums, `delsum part` finds which byte range of a file a
#    known checksum covers (a header CRC over an unknown span), `delsum check` computes one.
#  - CRC Beagle (Colin O'Flynn): the CRC differential technique, for protocols whose frames share
#    a length. It recovers an equivalent CRC even with a non-standard init or xorout, spots plain
#    sums and XOR checksums, and prints Python code that reproduces the CRC.
# ---------------------------------------------------------------------------

# Not packaged for Ubuntu: built from the SourceForge release, checked against the SHA-256 from
# that release's SHA256SUMS. Upstream releases rarely (3.0.6: August 2024), so this is a pin.
REVENG_VERSION="3.0.6"
REVENG_SHA256="a552b908d4e7eff713122a4c11deb6eb93f7a5e2defaac1267621fc3778f0365"   # reveng-3.0.6.tar.xz

function reveng_soft_install() {
    goodecho "[+] Installing CRC RevEng"
    install_dependencies "build-essential xz-utils"
    local tmp src bits
    tmp=$(mktemp -d)
    if ! installfromnet curl -fsSL --max-time 120 -o "$tmp/reveng.tar.xz" \
            "https://downloads.sourceforge.net/project/reveng/${REVENG_VERSION}/reveng-${REVENG_VERSION}.tar.xz"; then
        record_build_failure "net" "reveng" "download failed (${REVENG_VERSION})"
        rm -rf "$tmp"; return 0
    fi
    if ! echo "${REVENG_SHA256}  $tmp/reveng.tar.xz" | sha256sum -c - > /dev/null; then
        record_build_failure "net" "reveng" "checksum mismatch (${REVENG_VERSION})"
        rm -rf "$tmp"; return 0
    fi
    src="$tmp/reveng-${REVENG_VERSION}"
    # The presets are compiled in (-DPRESETS), and they need config.h's BMP_BIT to be the width
    # of unsigned long and BMP_SUB half of it. config.h ships 32/16, so on amd64, arm64 and
    # riscv64 (64-bit longs) the build's own bmptst step fails until they are set to 64/32.
    bits=$(getconf LONG_BIT)
    if tar -xJf "$tmp/reveng.tar.xz" -C "$tmp" --no-same-owner \
        && sed -i -e "s/^#define BMP_BIT   32\$/#define BMP_BIT   ${bits}/" \
            -e "s/^#define BMP_SUB   16\$/#define BMP_SUB   $((bits / 2))/" "$src/config.h" \
        && make -C "$src" && make -C "$src" pretst \
        && install -m 755 "$src/reveng" /usr/local/bin/reveng; then
        # CRC-16/XMODEM of "123456789" is 0x31C3 (the catalogue's check value)
        [ "$(reveng -m CRC-16/XMODEM -c 313233343536373839)" = "31c3" ] \
            || record_build_failure "other" "reveng" "wrong CRC-16/XMODEM check value"
    else
        record_build_failure "build" "reveng" "${REVENG_VERSION} build failed"
    fi
    rm -rf "$tmp"
    return 0
}

# Built with cargo from crates.io (with its Cargo.lock; cargo checks the crate's checksum against
# the index). It links libgf2x. Upstream's release profile keeps debug info: left out here.
DELSUM_VERSION="1.0.0"

function delsum_soft_install() {
    goodecho "[+] Installing delsum"
    install_dependencies "build-essential libgf2x-dev"
    [ -x "$HOME/.cargo/bin/cargo" ] && export PATH="$HOME/.cargo/bin:$PATH"
    if ! command -v cargo > /dev/null; then
        record_build_failure "toolchain" "delsum" "cargo unavailable"
        return 0
    fi
    local tdir
    tdir=$(mktemp -d)
    if CARGO_TARGET_DIR="$tdir" CARGO_PROFILE_RELEASE_DEBUG=false CARGO_PROFILE_RELEASE_STRIP=symbols \
        cargo install --locked --force --root /usr/local delsum --version "$DELSUM_VERSION"; then
        # CRC-16/XMODEM of "123456789" is 0x31C3
        printf '123456789' > "$tdir/check.bin"
        [ "$(delsum check -m 'crc width=16 poly=0x1021 init=0x0 xorout=0x0 refin=false refout=false' "$tdir/check.bin")" = "31c3" ] \
            || record_build_failure "other" "delsum" "wrong CRC-16/XMODEM check value"
    else
        record_build_failure "build" "delsum" "cargo install of ${DELSUM_VERSION} failed"
    fi
    rm -rf "$tdir"
    return 0
}

# Upstream is a Python library with no packaging, no releases and no command line, unchanged
# since 2021: pinned to its last commit, in its own venv (/opt/crcbeagle, with crccheck) and with
# a `crcbeagle` command written here. The clone stays in /opt/crcbeagle/src (README, demo.py).
CRCBEAGLE_COMMIT="86e54fbc63c1bca5ba13b8231f7cf4902c21f9e6"

function crcbeagle_soft_install() {
    goodecho "[+] Installing CRC Beagle"
    if ! command -v uv > /dev/null; then
        record_build_failure "toolchain" "crcbeagle" "uv unavailable"
        return 0
    fi
    # Pure Python: the venv uses the system Python, so no extra interpreter goes into every image
    install_dependencies "python3 git"
    local site
    rm -rf /opt/crcbeagle
    if ! uv venv --python /usr/bin/python3 /opt/crcbeagle \
        || ! installfromnet uv pip install --no-cache --python /opt/crcbeagle/bin/python "crccheck>=1.3,<2"; then
        record_build_failure "pip" "crcbeagle" "venv or crccheck install failed"
        rm -rf /opt/crcbeagle; return 0
    fi
    if ! git_clone_at https://github.com/colinoflynn/crcbeagle.git /opt/crcbeagle/src "$CRCBEAGLE_COMMIT"; then
        record_build_failure "net" "crcbeagle" "clone of ${CRCBEAGLE_COMMIT} failed"
        rm -rf /opt/crcbeagle; return 0
    fi
    site=$(/opt/crcbeagle/bin/python -c 'import sysconfig; print(sysconfig.get_paths()["purelib"])')
    cp -r /opt/crcbeagle/src/crcbeagle "$site/"
    cat > /usr/local/bin/crcbeagle << 'EOF'
#!/opt/crcbeagle/bin/python
"""Command-line front end for CRC Beagle (colinoflynn/crcbeagle), added by RF Swift.

Give two or more captured frames in hex, each with its CRC. The CRC is the last WIDTH/8
bytes of a frame (the first with --crc-first); write MESSAGE/CRC to split a frame yourself,
e.g. to leave a preamble or sync word out, and the CRC's length then sets the width.
Spaces, ':' and '-' inside a frame are ignored. Frames of the same length are compared with
each other (the CRC differential technique), so give at least two of each length.

examples:
  crcbeagle a5100207...fd0e a5100207...5a26 a5100207...f8ec
  crcbeagle -w 8 -f frames.txt          one frame per line, '#' starts a comment
  ... | crcbeagle -w 16 -f -           frames on stdin

As a library: /opt/crcbeagle/bin/python -c 'from crcbeagle import crcbeagle'
"""
import argparse
import re
import sys

from crcbeagle import crcbeagle


def unhex(text):
    digits = re.sub(r"[\s:\-]", "", text)
    if digits[:2].lower() == "0x":
        digits = digits[2:]
    if not digits or len(digits) % 2 or not re.fullmatch(r"[0-9a-fA-F]+", digits):
        raise ValueError("not an even number of hex digits: %r" % text)
    return list(bytes.fromhex(digits))


def split_frame(frame, nbytes, crc_first):
    if "/" in frame:
        message, crc = frame.split("/", 1)
        return unhex(message), unhex(crc)
    data = unhex(frame)
    if len(data) <= nbytes:
        raise ValueError("frame is not longer than its %d-byte CRC: %r" % (nbytes, frame))
    if crc_first:
        return data[nbytes:], data[:nbytes]
    return data[:-nbytes], data[-nbytes:]


def main():
    parser = argparse.ArgumentParser(prog="crcbeagle", description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("frames", nargs="*", metavar="FRAME", help="hex frame, or MESSAGE/CRC")
    parser.add_argument("-w", "--width", type=int, choices=(8, 16, 32), default=16,
                        help="CRC width in bits when it is split off a frame (default 16)")
    parser.add_argument("--crc-first", action="store_true", help="the CRC starts the frame")
    parser.add_argument("-f", "--file", help="read frames from FILE, one per line ('-' = stdin)")
    parser.add_argument("--no-example", action="store_true", help="do not print example code")
    args = parser.parse_args()

    frames = list(args.frames)
    if args.file:
        stream = sys.stdin if args.file == "-" else open(args.file)
        with stream:
            frames += [line.split("#", 1)[0].strip() for line in stream]
    frames = [f for f in frames if f]
    try:
        pairs = [split_frame(f, args.width // 8, args.crc_first) for f in frames]
        if len(pairs) < 2:
            raise ValueError("give at least two frames")
        if any(len(crc) not in (1, 2, 4) for _, crc in pairs):
            raise ValueError("CRC Beagle handles 8-, 16- and 32-bit CRCs only")
        crcbeagle.CRCBeagle().search([m for m, _ in pairs], [c for _, c in pairs],
                                     print_examples=not args.no_example)
    except (ValueError, TypeError) as err:
        parser.exit(2, "crcbeagle: %s\n" % err)


if __name__ == "__main__":
    main()
EOF
    chmod 755 /usr/local/bin/crcbeagle
    # The README's example: three 20-byte frames, CRC-16 poly 0x1021 with xorout 0xCACA
    local out
    out=$(crcbeagle --no-example a510020755a3d17215838f9034bbb78eb427a94cfd0e \
        a51002078c27f2cab5d1dcf89c704280ecbb23b05a26 a510020771691e76a4602bc654aa7b4c6be185c2f8ec \
        2> /dev/null || true)
    grep -q 'XOR-out value for len = 20: 0xCACA' <<< "$out" \
        || record_build_failure "other" "crcbeagle" "the README example is not solved"
    return 0
}

# crchack (resilar): forges a CRC instead of finding it. It changes the bits you allow so that
# a modified frame or firmware image gets the CRC you want, e.g. to keep a patched image's CRC-32
# valid: `crchack -o 4 patched.bin 1234abcd > forged.bin` (bytes 4-7 change), or
# `crchack patched.bin 1234abcd` to append 4 bytes instead. Any CRC: -w/-p/-i/-x/-r/-R (the
# parameters reveng finds); default CRC-32. Upstream has no releases: pinned to a commit, and
# its own test suite runs at build.
CRCHACK_COMMIT="0f40f3e16d25a8ca63f478dc7c4473a4c9d61f75"

function crchack_soft_install() {
    goodecho "[+] Installing crchack"
    install_dependencies "build-essential git"
    local tmp out
    tmp=$(mktemp -d)
    if ! git_clone_at https://github.com/resilar/crchack.git "$tmp/crchack" "$CRCHACK_COMMIT"; then
        record_build_failure "net" "crchack" "clone of ${CRCHACK_COMMIT} failed"
        rm -rf "$tmp"; return 0
    fi
    if make -C "$tmp/crchack" && install -m 755 "$tmp/crchack/crchack" /usr/local/bin/crchack; then
        # check.sh prints OK or FAIL per case and always exits 0
        out=$(sh "$tmp/crchack/check.sh" /usr/local/bin/crchack 2>&1 || true)
        if grep -q FAIL <<< "$out" || ! grep -q OK <<< "$out"; then
            record_build_failure "other" "crchack" "its test suite (check.sh) reports failures"
        fi
    else
        record_build_failure "build" "crchack" "make failed"
    fi
    rm -rf "$tmp"
    return 0
}

# pycrc: writes C code (or computes values) for a CRC from its parameters, for a frame
# generator or a patcher once reveng has found the CRC:
# `pycrc --model crc-16-modbus --check-string 123456789`,
# `pycrc --width 16 --poly 0x8005 --reflect-in true --xor-in 0xffff --reflect-out true
#  --xor-out 0 --algorithm table-driven --generate c -o crc.c` (and `--generate h` for the header).
function pycrc_soft_install() {
    goodecho "[+] Installing pycrc"
    install_dependencies "pycrc"
}

# ent: entropy, chi-square, mean, Monte Carlo pi and serial correlation of a file (`ent fw.bin`,
# `ent -t` for CSV). Close to 8 bits per byte means compressed or encrypted data; chi-square
# helps tell the two apart (encrypted data looks uniformly random, compressed data less so).
function ent_soft_install() {
    goodecho "[+] Installing ent"
    install_dependencies "ent"
}

# fq (wader): jq for binary formats. Decodes a hundred or so formats (ELF, PE, Mach-O, pcap and
# pcapng, TLS, DNS, protobuf, CBOR, MessagePack, ZIP, gzip, tar, PNG, MP4, ...) into a tree you
# query with jq: `fq . file`, `fq -d msgpack . blob`, `fq -d bytes` for raw data, `fq -i` for an
# interactive REPL. amd64 and arm64 take the newest release, checked against its checksums.txt;
# riscv64 (no release build) and a failed download get Ubuntu's older fq package.
FQ_VERSION="0.18.0"   # known-good; the build takes the newest release

function fq_soft_install() {
    goodecho "[+] Installing fq"
    local arch ver tmp sha base="https://github.com/wader/fq/releases/download"
    case "$(uname -m)" in
        x86_64|amd64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *) install_dependencies "fq"; return 0 ;;
    esac
    ver=$(latest_release_version wader/fq "$FQ_VERSION" \
        "$base/v@V@/fq_@V@_linux_${arch}.tar.gz" "$base/v@V@/checksums.txt")
    tmp=$(mktemp -d)
    if ! installfromnet curl -fsSL --max-time 120 -o "$tmp/fq.tar.gz" "$base/v${ver}/fq_${ver}_linux_${arch}.tar.gz" \
        || ! installfromnet curl -fsSL --max-time 30 -o "$tmp/checksums.txt" "$base/v${ver}/checksums.txt"; then
        record_build_failure "net" "fq" "download of ${ver} failed; installed Ubuntu's fq instead"
        rm -rf "$tmp"; install_dependencies "fq"; return 0
    fi
    sha=$(awk -v f="fq_${ver}_linux_${arch}.tar.gz" '$2 == f {print $1}' "$tmp/checksums.txt")
    if [ -z "$sha" ] || ! echo "${sha}  $tmp/fq.tar.gz" | sha256sum -c - > /dev/null \
        || ! tar -xzf "$tmp/fq.tar.gz" -C "$tmp" --no-same-owner fq \
        || ! install -m 755 "$tmp/fq" /usr/local/bin/fq; then
        record_build_failure "verify" "fq" "${ver} does not match its checksums.txt; installed Ubuntu's fq instead"
        rm -rf "$tmp"; install_dependencies "fq"; return 0
    fi
    rm -rf "$tmp"
    # MessagePack [1, "hi"]
    [ "$(printf '\x92\x01\xa2hi' | fq -r -d msgpack '.elements[1].value | tovalue')" = "hi" ] \
        || record_build_failure "other" "fq" "${ver} does not decode a MessagePack sample"
    return 0
}

# xortool (hellman): key length and key of XOR-obfuscated data (firmware, configs, payloads):
# `xortool -c 00 fw.bin` for binaries (0x00 the most frequent plaintext byte), `-c 20` for text,
# `-l LEN` to fix the key length; it writes the candidate plaintexts to ./xortool_out/.
# `xortool-xor` XORs data with a key. In its own uv tool venv on the system Python.
function xortool_soft_install() {
    goodecho "[+] Installing xortool"
    if ! command -v uv > /dev/null; then
        record_build_failure "toolchain" "xortool" "uv unavailable"
        return 0
    fi
    install_dependencies "python3"
    if ! UV_TOOL_BIN_DIR=/usr/local/bin installfromnet uv tool install --force --python /usr/bin/python3 xortool; then
        record_build_failure "pip" "xortool" "uv tool install failed"
        return 0
    fi
    # Text XORed with the 4-byte key "rfsw"
    local tmp
    tmp=$(mktemp -d)
    python3 -c 'import sys; k=b"rfsw"; t=b"The quick brown fox jumps over the lazy dog. " * 60; open(sys.argv[1], "wb").write(bytes(c ^ k[i % 4] for i, c in enumerate(t)))' "$tmp/sample.bin"
    (cd "$tmp" && xortool -c 20 sample.bin > out.txt 2>&1) || true
    grep -qx 'rfsw' "$tmp/out.txt" || record_build_failure "other" "xortool" "the key of a test sample is not found"
    rm -rf "$tmp"
    return 0
}

function x11_egl_shim_install() {
    # Mesa's GLX client cannot create a context on XQuartz (macOS hosts, Docker
    # Desktop / Podman / Lima alike): the server exposes no fbconfig that the
    # software rasterizer accepts ("No matching fbConfigs or visuals found",
    # "glx: failed to create drisw screen"), so every GLX-based tool dies at
    # window creation (SDR++: "OpenGL 3.0 was not supported", then an assert
    # in glfwSetWindowIcon). EGL on the very same X11 display works and gives
    # OpenGL 4.5 through llvmpipe. Qt (QT_XCB_GL_INTEGRATION) and SDL
    # (SDL_VIDEO_X11_FORCE_EGL) switch to EGL from the environment; GLFW
    # (SDR++, SatDump, CyberEther, ...) has no such switch, so this shim,
    # preloaded only when RF Swift asks for EGL (see rfswift_shell_setup),
    # sets GLFW_CONTEXT_CREATION_API=GLFW_EGL_CONTEXT_API before every
    # glfwCreateWindow. It resolves the GLFW symbols at call time and
    # references none directly, so preloading it into a program that never
    # uses GLFW is a no-op (no undefined-symbol errors under BIND_NOW).
    goodecho "[+] Building the GLFW EGL shim (OpenGL over XQuartz and other X servers without usable GLX)"
    install_dependencies "gcc libc6-dev"
    mkdir -p /usr/lib/rfswift
    cat > /tmp/rfswift-glfw-egl.c <<'EOF'
/* RF Swift: make GLFW create its OpenGL context through EGL instead of GLX.
 * Preloaded (LD_PRELOAD) only when RFSWIFT_GL_PLATFORM=egl; see
 * /root/.zshrc and RF-Swift-images/scripts/corebuild.sh. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stddef.h>

#define RF_GLFW_CONTEXT_CREATION_API 0x0002200B /* GLFW_CONTEXT_CREATION_API */
#define RF_GLFW_EGL_CONTEXT_API      0x00036002 /* GLFW_EGL_CONTEXT_API */

typedef void *(*rf_create_fn)(int, int, const char *, void *, void *);
typedef void (*rf_hint_fn)(int, int);

void *glfwCreateWindow(int width, int height, const char *title, void *monitor, void *share)
{
    rf_create_fn real = (rf_create_fn)dlsym(RTLD_NEXT, "glfwCreateWindow");
    rf_hint_fn hint = (rf_hint_fn)dlsym(RTLD_DEFAULT, "glfwWindowHint");
    if (!real)
        return NULL;
    if (hint)
        hint(RF_GLFW_CONTEXT_CREATION_API, RF_GLFW_EGL_CONTEXT_API);
    return real(width, height, title, monitor, share);
}
EOF
    if gcc -shared -fPIC -O2 -Wall -o /usr/lib/rfswift/libglfw-egl.so /tmp/rfswift-glfw-egl.c; then
        goodecho "[+] GLFW EGL shim installed at /usr/lib/rfswift/libglfw-egl.so"
    else
        criticalecho-noexit "[-] GLFW EGL shim build failed; GLFW tools will not render over XQuartz"
    fi
    rm -f /tmp/rfswift-glfw-egl.c
}

function x11_nomitshm_shim_install() {
    # MIT-SHM does not work across the container boundary: an X client creates
    # a SysV shared memory segment in the container's IPC namespace and asks
    # the host X server to attach it by id, but the server resolves the id in
    # the host's namespace. When the host has a segment with the same id
    # (small ids are common after a reboot), the toolkit's probe succeeds on
    # the wrong segment and the next MIT-SHM request kills the program (GRC:
    # "BadAccess (attempt to access private resource denied)", request_code
    # 130). This shim reports MIT-SHM as absent to Xlib clients (GTK, cairo,
    # Mesa), which then draw with plain X requests. Qt goes through xcb and
    # skips MIT-SHM with QT_X11_NO_MITSHM=1, set in the image and by rfswift.
    # It is loaded from /etc/ld.so.preload so shells, console commands and
    # launchers all get it, and it references no symbol, so programs that do
    # not use X11 are unaffected.
    goodecho "[+] Building the MIT-SHM shim (X11 GUIs on the host display)"
    install_dependencies "gcc libc6-dev"
    cat > /tmp/rfswift-nomitshm.c <<'EOF'
/* RF Swift: report MIT-SHM as unavailable to Xlib clients.
 * Loaded from /etc/ld.so.preload; see RF-Swift-images/scripts/corebuild.sh. */
typedef int Bool;
typedef struct _XDisplay Display;

Bool XShmQueryExtension(Display *dpy)
{
    (void)dpy;
    return 0;
}

Bool XShmQueryVersion(Display *dpy, int *major, int *minor, Bool *pixmaps)
{
    (void)dpy;
    (void)major;
    (void)minor;
    (void)pixmaps;
    return 0;
}
EOF
    local multiarch
    multiarch=$(gcc -print-multiarch)
    mkdir -p "/usr/lib/${multiarch}/rfswift"
    if ! gcc -shared -fPIC -O2 -Wall -o "/usr/lib/${multiarch}/rfswift/libnomitshm.so" /tmp/rfswift-nomitshm.c; then
        criticalecho-noexit "[-] MIT-SHM shim build failed; GTK tools may crash on the host display"
        rm -f /tmp/rfswift-nomitshm.c
        return
    fi
    # 32-bit programs resolve $LIB to their own directory (lib32 with
    # gcc-multilib, lib/i386-linux-gnu with multiarch i386 libraries): build
    # that variant when a 32-bit toolchain is present.
    if [ "$multiarch" = "x86_64-linux-gnu" ] && echo 'int main(void){return 0;}' | gcc -m32 -x c -o /dev/null - 2>/dev/null; then
        mkdir -p /usr/lib32/rfswift /usr/lib/i386-linux-gnu/rfswift
        if gcc -m32 -shared -fPIC -O2 -Wall -o /usr/lib32/rfswift/libnomitshm.so /tmp/rfswift-nomitshm.c; then
            cp /usr/lib32/rfswift/libnomitshm.so /usr/lib/i386-linux-gnu/rfswift/
        fi
    fi
    rm -f /tmp/rfswift-nomitshm.c
    if ! grep -qs 'rfswift/libnomitshm.so' /etc/ld.so.preload; then
        echo '/usr/$LIB/rfswift/libnomitshm.so' >> /etc/ld.so.preload
    fi
    goodecho "[+] MIT-SHM shim installed at /usr/lib/${multiarch}/rfswift/libnomitshm.so"
}

function rfswift_shell_setup() {
    goodecho "[+] Setting up RF Swift shell integration"
    # EGL switch for hosts whose X server has no usable GLX (see
    # x11_egl_shim_install). Same POSIX block for both shells.
    for rc in ~/.zshrc ~/.bashrc; do
        cat >> "$rc" << 'RFEOF'

# RF Swift: OpenGL through EGL when the host X server has no usable GLX
# (XQuartz on macOS). rfswift sets RFSWIFT_GL_PLATFORM=egl on such hosts.
if [ "$RFSWIFT_GL_PLATFORM" = "egl" ]; then
    export QT_XCB_GL_INTEGRATION=xcb_egl
    export SDL_VIDEO_X11_FORCE_EGL=1
    export SDL_VIDEO_FORCE_EGL=1
    if [ -r /usr/lib/rfswift/libglfw-egl.so ]; then
        case ":${LD_PRELOAD:-}:" in
            *:/usr/lib/rfswift/libglfw-egl.so:*) ;;
            *) export LD_PRELOAD="/usr/lib/rfswift/libglfw-egl.so${LD_PRELOAD:+:$LD_PRELOAD}" ;;
        esac
    fi
fi
RFEOF
    done
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
