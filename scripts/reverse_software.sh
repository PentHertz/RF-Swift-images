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
	installfromnet "git clone https://github.com/unicorn-engine/unicorn.git"
	cd unicorn
	mkdir build; cd build
	cmake .. -DCMAKE_BUILD_TYPE=Release
	make -j$(nproc)
	make install
	goodecho "[+] Installing Python bindings"
	pip3install "unicorn"
}

function keystone_soft_install() {
	goodecho "[+] Cloning Keystone Engine project"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	installfromnet "git clone https://github.com/keystone-engine/keystone.git"
	cd keystone
	mkdir build; cd build
	cmake .. -DCMAKE_BUILD_TYPE=Release
	make -j$(nproc)
	make install
	goodecho "[+] Installing Python bindings"
	pip3install "keystone-engine"
}

function radare2_soft_install() {
	# Check architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" ]]; then
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
	[ -d /reverse ] || mkdir -p /reverse
	cd /reverse
	goodecho "[+] Installing Binwalk v3"
	gitinstall "https://github.com/ReFirmLabs/binwalk.git" "binwalkv3_soft_install" "binwalkv3"
	cd binwalk
	cargo build --release
	ln -s $(pwd)/target/release/binwalk /usr/bin/binwalkv3
}

function binwalk_soft_install() {
	goodecho "[+] Installing Binwalk"
	install_dependencies "binwalk"
}

function cutter_soft_install() { # TODO: fix installation
	goodecho "[+] Installing Cutter dependencies"
	install_dependencies "ninja-build qt6-base-dev qt6-svg-dev qt6-opengl-dev libqt6opengl6-dev cmake meson pkgconf libzip-dev zlib1g-dev qt6-base-dev qt6-tools-dev qt6-tools-dev-tools libqt6svg6-dev libqt6core5compat6-dev libqt6svgwidgets6 qt6-l10n-tools libqt6opengl6-dev"
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

    ghidra_version="11.3"
    ghidra_date="20250205"
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
        aarch64|arm64)
            goodecho "[+] Architecture: aarch64"
            goodecho "[+] Installing qiling for aarch64"
            ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $ARCH"
            exit 0
            ;;
    esac
	goodecho "[+] Installing Qiling's dependencies"
	install_dependencies "ack antlr3 aria2 asciidoc autoconf automake autopoint binutils bison build-essential bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext gcc-multilib g++-multilib git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libreadline-dev libssl-dev libtool lrzsz mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python2.7 python3 python3-pip libpython3-dev qemu-utils rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev"
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
	goodecho "[+] Cloning and installing ImHex"
	[ -d /reverse ] || mkdir /reverse
	cd /reverse
	gitinstall "https://github.com/WerWolv/ImHex.git" "imhex_soft_install" "releases/v1.36.X"
	cd ImHex
	chmod +x dist/get_deps_debian.sh
	sed -i -e 's/g++-14/g++-12/g' -e 's/gcc-14/gcc-12/g' dist/get_deps_debian.sh
	goodecho "[+] Installing ImHex dependencies"
	installfromnet "sh -c ./dist/get_deps_debian.sh"
	mkdir -p build
	cd build
	CC=gcc-12 CXX=g++-12                          \
	cmake -G "Ninja"                              \
	    -DCMAKE_BUILD_TYPE=Release                \
	    -DCMAKE_INSTALL_PREFIX="/usr"             \
	    ..
	ninja install
}

### TODO: more More!
