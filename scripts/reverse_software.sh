#!/bin/bash

function kataistruct_soft_install() {
	goodecho "[+] Installing Katai Struct"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	installfromnet "curl -LO https://github.com/kaitai-io/kaitai_struct_compiler/releases/download/0.10/kaitai-struct-compiler_0.10_all.deb"
	installfromnet "apt-fast install -y ./kaitai-struct-compiler_0.10_all.deb"
}

function unicorn_soft_install() {
	goodecho "[+] Cloning Unicorn Engine project"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then # TODO: fix arm64 install
		installfromnet "git clone https://github.com/unicorn-engine/unicorn.git"
		cd unicorn
		mkdir build; cd build
		cmake .. -DCMAKE_BUILD_TYPE=Release
		make -j$(nproc)
		make install
		goodecho "[+] Installing Python bindings"
		pip3install "unicorn"
    else
        criticalecho-noexit "[-] Unsupported architecture: $ARCH"
    fi
}

function keystone_soft_install() {
	goodecho "[+] Cloning Keystone Engine project"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then # TODO: fix arm64 install
		installfromnet "git clone https://github.com/keystone-engine/keystone.git"
		cd keystone
		mkdir build; cd build
		# Keystone's CMakeLists declares cmake_minimum_required < 3.5, which CMake 4.x
		# (Ubuntu 26.04) refuses; CMAKE_POLICY_VERSION_MINIMUM (set globally in
		# corebuild, repeated here for clarity) restores the old policy behavior.
		# Best-effort: keystone bundles an old LLVM that can still trip CMake 4.2, so
		# record and continue rather than aborting the whole reversing image.
		if cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
			&& make -j$(nproc) && make install; then
			goodecho "[+] Installing Python bindings"
			pip3install "keystone-engine"
		else
			record_build_failure "build" "keystone" "cmake/make failed on resolute (CMake 4.2 / bundled LLVM)"
		fi
    else
        criticalecho-noexit "[-] Unsupported architecture: $ARCH"
    fi
}

function radare2_soft_install() {
	# Check architecture
    ARCH=$(uname -m)
    if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "amd64" ]; then
        criticalecho-noexit "[-] Unsupported architecture: $ARCH"
        exit 0
    fi
	goodecho "[+] Installing Radare"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	installfromnet "git clone https://github.com/radareorg/radare2"
	cd radare2 ; sys/install.sh
}

function binwalkv3_soft_install() {
    goodecho "[+] Installing Binwalk v3 dependencies"
    install_dependencies "p7zip-full zstd unzip tar sleuthkit cabextract lz4 lzop device-tree-compiler unrar"
    
    # Ensure we're using rustup's cargo, not system cargo
    export PATH="/root/.cargo/bin:${PATH}"
    source $HOME/.cargo/env 2>/dev/null || true
    
    # Verify Rust version
    cargo --version
    if ! cargo --version | grep -qE "1\.(8[2-9]|9[0-9]|[0-9]{3})"; then
        goodecho "[+] Updating Rust to latest stable"
        rustup update stable
        rustup default stable
    fi
    
    [ -d /reverse ] || mkdir -p /reverse
    cd /reverse
    goodecho "[+] Installing Binwalk v3"
    gitinstall "https://github.com/ReFirmLabs/binwalk.git" "binwalkv3_soft_install"
    cd binwalk

    ARCH=$(uname -m)
    if [ "$ARCH" = "riscv64" ]; then
        # Populate cargo registry before patching
        cargo fetch 2>/dev/null || true
        # plotly_kaleido 0.13.1 build.rs only defines KALEIDO_URL for x86_64/aarch64/windows/macos
        # riscv64 falls through with an undefined symbol - patch aarch64 cfg to include riscv64
        local KALEIDO_BUILD
        KALEIDO_BUILD=$(find /root/.cargo/registry/src -name "build.rs" \
            -path "*/plotly_kaleido*" 2>/dev/null | head -1)
        if [ -n "$KALEIDO_BUILD" ]; then
            goodecho "[+] Patching plotly_kaleido build.rs for riscv64"
            sed -i \
                's|#\[cfg(all(target_arch = "aarch64", target_os = "linux"))\]|#[cfg(any(all(target_arch = "aarch64", target_os = "linux"), all(target_arch = "riscv64", target_os = "linux")))]|g' \
                "${KALEIDO_BUILD}"
        else
            goodecho "[-] Could not find plotly_kaleido build.rs, build may fail"
        fi
    fi

    # Build with explicit edition support
    cargo build --release
    ln -sf $(pwd)/target/release/binwalk /usr/bin/binwalkv3
    
    goodecho "[+] Binwalk v3 installed successfully"
}

function binwalk_soft_install() {
	goodecho "[+] Installing Binwalk"
	install_dependencies "binwalk"
}

function cutter_soft_install() { # TODO: fix installation
	ARCH=$(uname -m)

    case "$ARCH" in
        x86_64|amd64)
            goodecho "[+] Architecture: x86_64"
            goodecho "[+] Installing Cutter for x86_64"
            ;;
        #aarch64|arm64) # TODO: fix arm64 install
        #    goodecho "[+] Architecture: aarch64"
        #    goodecho "[+] Installing qiling for aarch64"
        #    ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $ARCH"
            exit 0
            ;;
    esac
	goodecho "[+] Installing Cutter dependencies"
	install_dependencies "ninja-build qt6-base-dev libqt6opengl6-dev cmake meson pkgconf libzip-dev zlib1g-dev qt6-base-dev qt6-tools-dev qt6-tools-dev-tools libqt6svg6-dev libqt6core5compat6-dev libqt6svgwidgets6 qt6-l10n-tools libqt6opengl6-dev"
	pip3install "meson"
	ldconfig
	goodecho "[+] Cloning Cutter"
	[ -d /reverse ] || mkdir -p /reverse
	cd /reverse
	installfromnet "git clone --recurse-submodules https://github.com/rizinorg/cutter"
	cd cutter
	mkdir build && cd build
	cmake ..
	cmake --build .
	make install
}

function ghidra_soft_install() {
	goodecho "[+] Installing Ghidra dependencies"
	install_dependencies "openjdk-21-jdk"
	goodecho "[+] Downloading Ghidra"
	[ -d /reverse ] || mkdir /reverse
	cd /reverse

    ghidra_version="12.1.2"
    ghidra_date="20260605"
	prog="ghidra_${ghidra_version}_PUBLIC_${ghidra_date}"

	installfromnet "wget https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${ghidra_version}_build/${prog}.zip"
	unzip "$prog"
	cd "ghidra_${ghidra_version}_PUBLIC"
	ln -s $(pwd)/ghidraRun /usr/sbin/ghidraRun
	cd ..
	rm "$prog.zip"
}

function qiling_soft_install() {
	ARCH=$(uname -m)

    case "$ARCH" in
        x86_64|amd64)
            goodecho "[+] Architecture: x86_64"
            goodecho "[+] Installing qiling for x86_64"
            ;;
        #aarch64|arm64) # TODO: fix arm64 install
        #    goodecho "[+] Architecture: aarch64"
        #    goodecho "[+] Installing qiling for aarch64"
        #    ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $ARCH"
            exit 0
            ;;
    esac
	goodecho "[+] Installing Qiling's dependencies"
	install_dependencies "ack antlr3 aria2 asciidoc autoconf automake autopoint binutils bison build-essential bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext gcc-multilib g++-multilib git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses-dev libncursesw6 libreadline-dev libssl-dev libtool lrzsz mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python3 python3-pip libpython3-dev qemu-utils rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev"
	goodecho "[+] Cloning and installing Qiling"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	git clone -b dev https://github.com/qilingframework/qiling.git
	cd qiling && git submodule update --init --recursive
	pip3install .
}

function emba_soft_install() {
	goodecho "[+] Cloning and installing Qiling"
	[ -d /reverse ] || mkdir /reverse
	cd /reverse
	gitinstall "https://github.com/e-m-b-a/emba.git" "emba_soft_install"
	cd emba
	sudo ./installer.sh -d
}


function imhex_soft_install() {
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
    
    ARCH=$(uname -m)
    IMH_VERSION="1.38.1"
    
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
        goodecho "[+] Installing ImHex for x86_64"
        install_dependencies "libmbedtls21 libmbedx509-7 libglfw3-dev"
        # No Ubuntu 26.04 build published yet; the 25.04 deb links against the same library sonames
        installfromnet "wget https://github.com/WerWolv/ImHex/releases/download/v$IMH_VERSION/imhex-$IMH_VERSION-Ubuntu-25.04-x86_64.deb"
        dpkg -i imhex-$IMH_VERSION-Ubuntu-25.04-x86_64.deb
        
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        goodecho "[+] Installing ImHex for arm64"
        install_dependencies "libmbedtls21 libmbedx509-7 libglfw3-dev libfuse2"
        
        # Download the AppImage
        installfromnet "wget https://github.com/WerWolv/ImHex/releases/download/v$IMH_VERSION/imhex-$IMH_VERSION-arm64.AppImage"
        chmod +x imhex-$IMH_VERSION-arm64.AppImage
        
        # Try extraction with better error handling
        if ! ./imhex-$IMH_VERSION-arm64.AppImage --appimage-extract 2>/dev/null; then
            goodecho "[!] AppImage extraction failed, trying manual extraction..."
            
            # Fallback: manual extraction using offset
            # AppImages are ISO9660 filesystems at a specific offset
            offset=$(./imhex-$IMH_VERSION-arm64.AppImage --appimage-offset 2>/dev/null || echo "")
            
            if [ -n "$offset" ]; then
                dd if=imhex-$IMH_VERSION-arm64.AppImage of=imhex.iso bs=1 skip=$offset
                mkdir -p squashfs-root
                mount -o loop imhex.iso squashfs-root
                cp -r squashfs-root /opt/imhex
                umount squashfs-root
            else
                criticalecho-noexit "[-] Could not extract ImHex AppImage, skipping..."
                return 1
            fi
        else
            # Normal extraction succeeded
            cp -r squashfs-root /opt/imhex
        fi
        
        # Create symlink in /usr/local/bin
        ln -sf /opt/imhex/AppRun /usr/local/bin/imhex
        
        # Clean up
        rm -f imhex-$IMH_VERSION-arm64.AppImage imhex.iso
        rm -rf squashfs-root
        
    else
        criticalecho-noexit "[-] Unsupported architecture: $ARCH"
    fi
}

function imhex_soft_install_fromsource() {
	goodecho "[+] Cloning and installing ImHex"
	[ -d /reverse ] || mkdir /reverse
	cd /reverse
	gitinstall "https://github.com/WerWolv/ImHex.git" "imhex_soft_install" "releases/v1.37.X"
	cd ImHex
	chmod +x dist/get_deps_debian.sh
	#sed -i -e 's/g++-14/g++-12/g' -e 's/gcc-14/gcc-12/g' dist/get_deps_debian.sh
	goodecho "[+] Installing ImHex dependencies"
	installfromnet "sh -c ./dist/get_deps_debian.sh"
	mkdir -p build
	cd build
	CC=gcc-14 CXX=g++-14                          \
	cmake -G "Ninja"                              \
	    -DCMAKE_BUILD_TYPE=Release                \
	    -DCMAKE_INSTALL_PREFIX="/usr"             \
	    ..
	ninja install
}

function appledb_rs_soft_install() {
	goodecho "[+] Cloning and installing appledb_rs"
	install_dependencies "yarnpkg"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
	gitinstall "https://github.com/FlUxIuS/appledb_rs.git" "appledb_rs"
	cd appledb_rs
	cargo build --release
	chmod +x ./build_web.sh
	ln -s ./target/release/appledb_cli /usr/local/bin/appledb_cli
	ln -s ./target/release/appledb_server /usr/local/bin/appledb_server
}

function bytecaster_install() {
    goodecho "[+] Installing ByteCaster"
    
    [ -d /reverse ] || mkdir /reverse
    cd /reverse && git clone https://github.com/FlUxIuS/ByteCaster.git
    cd ByteCaster
    
    # Compile for current architecture (Go auto-detects in Docker)
    CGO_ENABLED=0 go build -ldflags="-w -s" -tags netgo -o ByteCaster
    chmod +x ByteCaster
    
    # Create symlink
    ln -sf /reverse/ByteCaster/ByteCaster /usr/bin/ByteCaster
    
    goodecho "[+] ByteCaster installed at /usr/bin/ByteCaster"
}

function sasquatch_soft_install() {
	goodecho "[+] Installing sasquatch"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
    cd /root/thirdparty
	gitinstall "https://github.com/FlUxIuS/sasquatch.git" "sasquatch_soft_install"
	cd sasquatch
	install_dependencies "build-essential liblzma-dev liblzo2-dev zlib1g-dev"
	# GCC 14/15 (Ubuntu 26.04) promotes -Wincompatible-pointer-types and other
	# K&R-isms to hard errors, which the bundled squashfs-tools predates and the
	# Makefile's -Wno-error does not cover. build.sh just runs `make` with no
	# CFLAGS handling, so inject the relaxing flags via a temporary cc/gcc shim
	# that the Makefile's hardcoded `cc` recipe picks up.
	local shim; shim=$(mktemp -d)
	local c
	for c in cc gcc; do
		cat > "$shim/$c" <<EOF
#!/bin/sh
exec /usr/bin/$c -fcommon -Wno-incompatible-pointer-types -Wno-implicit-function-declaration -Wno-int-conversion "\$@"
EOF
		chmod +x "$shim/$c"
	done
	PATH="$shim:$PATH" ./build.sh || record_build_failure "build" "sasquatch" "squashfs-tools build failed"
	rm -rf "$shim"
}

function qnx6extractor_soft_install() {
	goodecho "[+] Installing qnx6-extractor"
	[ -d /reverse ] || mkdir /reverse
    cd /reverse
	gitinstall "https://github.com/ReFirmLabs/qnx6-extractor.git" "qnx6extractor_soft_install"
	cd qnx6-extractor/qnx6_extractor
	chmod +x main.py
	ln -s $(pwd)/main.py /usr/local/sbin/qnx6-extractor
}

function unblob_soft_install() {
    goodecho "[+] Installing unblob"
    ARCH=$(uname -m)

    if [ "$ARCH" = "riscv64" ]; then
        goodecho "[!] Skipping unblob on riscv64: hyperscan/vectorscan do not support RISC-V64 (upstream limitation)"
        return 0
    fi

    if [ "$ARCH" = "aarch64" ]; then
        install_dependencies "android-sdk-libsparse-utils e2fsprogs p7zip-full unar \
            zlib1g-dev liblzo2-dev lzop lziprecover libhyperscan-dev \
            zstd lz4 build-essential curl"
    else
        install_dependencies "android-sdk-libsparse-utils e2fsprogs p7zip-full unar \
            zlib1g-dev liblzo2-dev lzop lziprecover libhyperscan-dev \
            zstd lz4 build-essential curl"
    fi

    # Install Rust if not present
    if ! command -v cargo &> /dev/null; then
        goodecho "[+] Installing Rust toolchain (required for unblob)"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
        export PATH="/root/.cargo/bin:${PATH}"
        source $HOME/.cargo/env
    else
        goodecho "[+] Rust already installed"
        export PATH="/root/.cargo/bin:${PATH}"
    fi

    cargo --version || { goodecho "[-] Rust installation failed"; return 1; }

    [ -d /reverse ] || mkdir /reverse
    cd /reverse
    gitinstall "https://github.com/onekey-sec/unblob.git" "unblob_soft_install"
    cd unblob
    pipx install .
}

function angr_soft_install() {
	goodecho "[+] Installing angrop"
	pip3install "angr"
}

function angrop_soft_install() {
	goodecho "[+] Installing angrop"
	pipx install git+https://github.com/angr/angrop.git
}




### TODO: more More!
