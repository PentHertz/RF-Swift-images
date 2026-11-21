#!/bin/bash

function kataistruct_soft_install() {
	goodecho "[+] Installing Katai Struct"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	installfromnet "curl" "-LO" "https://github.com/kaitai-io/kaitai_struct_compiler/releases/download/0.10/kaitai-struct-compiler_0.10_all.deb"
	installfromnet "apt-fast" "install" "-y" "./kaitai-struct-compiler_0.10_all.deb"
}

function unicorn_soft_install() {
	goodecho "[+] Cloning Unicorn Engine project"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then # TODO: fix arm64 install
		installfromnet "git" "clone" "https://github.com/unicorn-engine/unicorn.git"
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
		installfromnet "git" "clone" "https://github.com/keystone-engine/keystone.git"
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
	installfromnet "git" "clone" "https://github.com/radareorg/radare2"
	cd radare2 ; sys/install.sh
}

KALEIDO_VERSION="v0.2.1"
KALEIDO_SHA256_X64="3eaa3efd41a00db05dd71add7f54ad4e9d4259552e3f7470ac4c1a8594cea214"
KALEIDO_SHA256_ARM64="a6040fa4d95692b7047d3880391f539ea7af9353b0c7b0558ea7b8e280013703"
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

    # plotly_kaleido's build.rs fetches Kaleido (the PNG export of `binwalk -E`) by installing and
    # running `ruget`, which now fails ("Error when executing client") and leaves build.rs
    # panicking on the missing zip. It skips the download when ~/.config/kaleido/bin/kaleido
    # already exists (where binwalk also looks for it at run time), so provide it ourselves.
    local kdir="$HOME/.config/kaleido" kzip="" ksha="" ktmp
    case "$ARCH" in
        x86_64) kzip="kaleido_linux_x64.zip"; ksha="$KALEIDO_SHA256_X64" ;;
        aarch64) kzip="kaleido_linux_arm64.zip"; ksha="$KALEIDO_SHA256_ARM64" ;;
    esac
    if [ ! -x "$kdir/bin/kaleido" ] && [ -n "$kzip" ]; then
        ktmp=$(mktemp -d)
        if installfromnet curl -fsSL -o "$ktmp/kaleido.zip" "https://github.com/plotly/Kaleido/releases/download/${KALEIDO_VERSION}/${kzip}" \
            && echo "${ksha}  $ktmp/kaleido.zip" | sha256sum -c -; then
            mkdir -p "$kdir"
            unzip -q -o "$ktmp/kaleido.zip" -d "$kdir"
        else
            record_build_failure "net" "kaleido (binwalk v3)" "download or checksum failed: ${kzip}"
        fi
        rm -rf "$ktmp"
    fi
    if [ ! -x "$kdir/bin/kaleido" ]; then
        # no Kaleido build for this arch (riscv64) or the download failed: a stub stops build.rs
        # from trying; only `binwalk -E` PNG export is unavailable
        mkdir -p "$kdir/bin"
        printf '#!/bin/sh\necho "Kaleido (binwalk -E PNG export) is not available on %s" >&2\nexit 1\n' "$ARCH" > "$kdir/bin/kaleido"
        chmod 0755 "$kdir/bin/kaleido"
    fi

    if cargo build --release; then
        ln -sf "$(pwd)/target/release/binwalk" /usr/bin/binwalkv3
        goodecho "[+] Binwalk v3 installed successfully"
    else
        record_build_failure "build" "binwalk v3" "cargo build failed"
    fi
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
	installfromnet "git" "clone" "--recurse-submodules" "https://github.com/rizinorg/cutter"
	cd cutter
	mkdir build && cd build
	cmake ..
	cmake --build .
	make install
}

function ghidra_soft_install() {
	goodecho "[+] Installing Ghidra dependencies"
	install_dependencies "openjdk-25-jdk"
	goodecho "[+] Downloading Ghidra"
	[ -d /reverse ] || mkdir /reverse
	cd /reverse

    ghidra_version="12.2"   # known-good (with its build date); the build takes the newest release
    ghidra_date="20261016"
    # The zip name embeds a build date, so read it from the newest release's asset list
    # (the expanded_assets page, no API call). Known-good if anything is missing.
    local gh_latest gh_zip
    gh_latest=$(version_from_tag "$(github_latest_tag NationalSecurityAgency/ghidra)")
    if [ -z "$gh_latest" ]; then
        note_version_fallback NationalSecurityAgency/ghidra "newest release lookup failed" "$ghidra_version"
    elif version_gt "$gh_latest" "$ghidra_version"; then
        gh_zip=$(curl -fsSL --max-time 30 \
            "https://github.com/NationalSecurityAgency/ghidra/releases/expanded_assets/Ghidra_${gh_latest}_build" 2>/dev/null \
            | grep -oE "ghidra_${gh_latest//./\\.}_PUBLIC_[0-9]{8}\.zip" | head -n1 || true)
        if [ -n "$gh_zip" ]; then
            ghidra_version="$gh_latest"
            ghidra_date="${gh_zip##*_PUBLIC_}"
            ghidra_date="${ghidra_date%.zip}"
        else
            note_version_fallback NationalSecurityAgency/ghidra "no ghidra_${gh_latest}_PUBLIC_<date>.zip asset" "$ghidra_version"
        fi
    fi
	prog="ghidra_${ghidra_version}_PUBLIC_${ghidra_date}"

	# Always write to the exact name (-O) and drop leftovers from earlier runs: otherwise
	# wget saves as "$prog.zip.1", ".2", ... and unzip opens a stale or truncated copy.
	rm -f "$prog.zip" "$prog.zip."*
	if ! installfromnet wget -O "$prog.zip" "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${ghidra_version}_build/${prog}.zip" \
		|| ! unzip -tq "$prog.zip" > /dev/null; then
		rm -f "$prog.zip"
		criticalecho-noexit "[-] Ghidra ${ghidra_version} download failed or archive is corrupt"
		return 1
	fi
	unzip -oq "$prog.zip"
	rm -f "$prog.zip"
	ln -sf "/reverse/ghidra_${ghidra_version}_PUBLIC/ghidraRun" /usr/sbin/ghidraRun
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
    IMH_VERSION="1.38.1"  # known-good; the build takes the newest release

    # AppImage on every arch: there is no Ubuntu 26.04 deb, and the 25.04 one
    # declares libmbedtls14, which does not exist on resolute.
    local imh_arch
    case "$ARCH" in
        x86_64|amd64)  imh_arch="x86_64" ;;
        aarch64|arm64) imh_arch="arm64" ;;
        *) criticalecho-noexit "[-] Unsupported architecture: $ARCH"; return 1 ;;
    esac
    IMH_VERSION=$(latest_release_version WerWolv/ImHex "$IMH_VERSION" \
        "https://github.com/WerWolv/ImHex/releases/download/v@V@/imhex-@V@-${imh_arch}.AppImage")
    IMH_APPIMAGE="imhex-$IMH_VERSION-${imh_arch}.AppImage"

    goodecho "[+] Installing ImHex for $ARCH (AppImage)"
    install_dependencies "libglfw3-dev libfuse2"

    installfromnet "wget" "https://github.com/WerWolv/ImHex/releases/download/v$IMH_VERSION/$IMH_APPIMAGE"
    chmod +x "$IMH_APPIMAGE"

    # Extract so it runs without FUSE inside the container
    rm -rf squashfs-root
    if ! ./"$IMH_APPIMAGE" --appimage-extract >/dev/null 2>&1; then
        goodecho "[!] AppImage extraction failed, trying unsquashfs at the embedded offset..."
        offset=$(./"$IMH_APPIMAGE" --appimage-offset 2>/dev/null || echo "")
        if [ -z "$offset" ] || ! { install_dependencies "squashfs-tools" && unsquashfs -o "$offset" -d squashfs-root "$IMH_APPIMAGE"; }; then
            criticalecho-noexit "[-] Could not extract ImHex AppImage, skipping..."
            rm -f "$IMH_APPIMAGE"
            return 1
        fi
    fi

    rm -rf /opt/imhex
    cp -r squashfs-root /opt/imhex
    ln -sf /opt/imhex/AppRun /usr/local/bin/imhex

    rm -f "$IMH_APPIMAGE"
    rm -rf squashfs-root
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
	installfromnet "sh" "-c" "./dist/get_deps_debian.sh"
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
    if CGO_ENABLED=0 go build -ldflags="-w -s" -tags netgo -o ByteCaster; then
        chmod +x ByteCaster
        ln -sf /reverse/ByteCaster/ByteCaster /usr/bin/ByteCaster
        goodecho "[+] ByteCaster installed at /usr/bin/ByteCaster"
    else
        record_build_failure "build" "ByteCaster" "go build failed"
    fi
    return 0
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
    # unblob's rust-toolchain.toml pins an exact Rust release, which makes the
    # rustup proxy auto-install a second toolchain in the middle of the pip
    # build: image bloat, and flaky (a partial install fails the next attempt
    # with "detected conflict: bin/cargo-clippy"). Its MSRV is well below
    # stable, so build with the stable toolchain from corebuild's rust_tools.
    RUSTUP_TOOLCHAIN=stable pipx install .
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

# ---------------------------------------------------------------------------
# Exploit development
# ---------------------------------------------------------------------------
function pwndbg_soft_install() {
    goodecho "[+] Installing pwndbg (loaded by gdb through ~/.gdbinit)"
    install_dependencies "gdb gdbserver python3-dev python3-venv git curl"
    [ -d /reverse ] || mkdir /reverse
    cd /reverse
    gitinstall "https://github.com/pwndbg/pwndbg.git" "pwndbg_soft_install" || true
    if [ -d pwndbg ] && ( cd pwndbg && ./setup.sh ); then
        goodecho "[+] pwndbg installed"
    else
        record_build_failure "build" "pwndbg" "setup.sh failed"
    fi
    return 0
}

function gef_soft_install() {
    goodecho "[+] Installing GEF (run 'gef' instead of 'gdb' to use it instead of pwndbg)"
    install_dependencies "gdb"
    [ -d /reverse/gef ] || mkdir -p /reverse/gef
    if installfromnet wget -q -O /reverse/gef/gef.py "https://raw.githubusercontent.com/hugsy/gef/main/gef.py"; then
        cat > /usr/local/bin/gef <<'WRAP'
#!/bin/bash
exec gdb -nx -ex "source /reverse/gef/gef.py" "$@"
WRAP
        chmod +x /usr/local/bin/gef
    else
        record_build_failure "download" "gef" "gef.py download failed"
    fi
    return 0
}

function exploitdev_tools_soft_install() {
    goodecho "[+] Installing pwntools, ROPgadget, one_gadget and checksec"
    install_dependencies "checksec ruby ruby-dev build-essential python3-dev libffi-dev libssl-dev"
    pipx_install_tool "pwntools" "pwntools" "pwn"
    local b
    for b in cyclic shellcraft asm disasm phd constgrep elfdiff elfpatch hex unhex pwnstrip; do
        [ -e "/root/.local/bin/$b" ] && ln -sf "/root/.local/bin/$b" "/usr/local/bin/$b"
    done
    pipx_install_tool "ROPgadget" "ropgadget" "ROPgadget"
    gem install one_gadget || record_build_failure "build" "one_gadget" "gem install failed"
    return 0
}

# ---------------------------------------------------------------------------
# Binary triage
# ---------------------------------------------------------------------------
function binary_triage_tools_soft_install() {
    goodecho "[+] Installing capa, FLOSS, YARA and Detect-It-Easy"
    install_dependencies "yara python3-yara"
    pipx_install_tool "capa" "flare-capa" "capa"
    pipx_install_tool "floss" "flare-floss" "floss"
    local DIE_VERSION="3.21" tmp
    if [ "$(uname -m)" != "x86_64" ]; then
        goodecho "[!] Detect-It-Easy only publishes amd64 .deb packages; skipping it on $(uname -m)"
        return 0
    fi
    # known-good above; the newest release is used only when it ships an Ubuntu 26.04 .deb
    DIE_VERSION=$(latest_release_version horsicq/DIE-engine "$DIE_VERSION" \
        "https://github.com/horsicq/DIE-engine/releases/download/@V@/die_@V@_Ubuntu_26.04_amd64.deb")
    tmp=$(mktemp -d)
    if installfromnet wget -q -O "$tmp/die.deb" "https://github.com/horsicq/DIE-engine/releases/download/${DIE_VERSION}/die_${DIE_VERSION}_Ubuntu_26.04_amd64.deb" \
        && apt-fast install -y "$tmp/die.deb"; then
        goodecho "[+] Detect-It-Easy ${DIE_VERSION} installed (die, diec, diel)"
    else
        record_build_failure "download" "Detect-It-Easy" "deb download/install failed"
    fi
    rm -rf "$tmp"
    return 0
}
