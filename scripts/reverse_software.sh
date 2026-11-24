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
    goodecho "[+] Installing pwntools, ROPgadget, Ropper, one_gadget and checksec"
    install_dependencies "checksec ruby ruby-dev build-essential python3-dev libffi-dev libssl-dev"
    pipx_install_tool "pwntools" "pwntools" "pwn"
    local b
    for b in cyclic shellcraft asm disasm phd constgrep elfdiff elfpatch hex unhex pwnstrip; do
        [ -e "/root/.local/bin/$b" ] && ln -sf "/root/.local/bin/$b" "/usr/local/bin/$b"
    done
    pipx_install_tool "ROPgadget" "ropgadget" "ROPgadget"
    # Ropper on Python 3.13 via uv: its dependency filebytes (sdist only, 0.10.2) calls ast.Str in
    # setup.py, which Python 3.14 removed. The fix is on filebytes master but not released yet.
    # keystone-engine (needed only by `ropper --chain`) has a Linux wheel for x86_64 alone, so the
    # other architectures get Ropper without it (gadget search works, --chain does not).
    if command -v uv > /dev/null; then
        local ropper_ok=0
        if [ "$(uname -m)" = "x86_64" ]; then
            installfromnet uv tool install --force --python 3.13 --with keystone-engine ropper && ropper_ok=1
        fi
        if [ "$ropper_ok" -eq 0 ]; then
            installfromnet uv tool install --force --python 3.13 ropper && ropper_ok=1
        fi
        if [ "$ropper_ok" -eq 1 ] && [ -e "$HOME/.local/bin/ropper" ]; then
            ln -sf "$HOME/.local/bin/ropper" /usr/local/bin/ropper
        else
            record_build_failure "pip" "ropper" "uv tool install failed"
        fi
    else
        record_build_failure "toolchain" "ropper" "uv unavailable"
    fi
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
    # Known-good Detect-It-Easy is 3.21 (die_3.21_Ubuntu_26.04_amd64.deb, amd64 only). 4.0.0 is
    # used on purpose but regresses against it: diec prints nothing for a symlink (exit 0), and
    # GCC/Clang ELF binaries get a false "Compiler: TinyCC (0.9.27)". To roll back, set 3.21
    # and download that old asset name instead of the codename-based one below.
    local DIE_VERSION="4.0.0" debarch tmp deb="" codename base
    debarch=$(dpkg --print-architecture)
    case "$debarch" in
        amd64|arm64|riscv64) ;;
        *) goodecho "[!] Detect-It-Easy publishes no .deb for ${debarch}; skipping it"; return 0 ;;
    esac
    # Since 4.0 the .debs are named by Ubuntu codename (die_<V>_noble_<arch>.deb, no more
    # die_<V>_Ubuntu_26.04_amd64.deb) and none targets resolute yet. noble's depends only on
    # Qt5 + libcurl and installs and runs on resolute; resolute's is preferred once published.
    # known-good above; the newest release is used when it ships a noble .deb for this arch.
    DIE_VERSION=$(latest_release_version horsicq/DIE-engine "$DIE_VERSION" \
        "https://github.com/horsicq/DIE-engine/releases/download/@V@/die_@V@_noble_${debarch}.deb")
    base="https://github.com/horsicq/DIE-engine/releases/download/${DIE_VERSION}"
    for codename in resolute noble; do
        if url_exists "${base}/die_${DIE_VERSION}_${codename}_${debarch}.deb"; then
            deb="die_${DIE_VERSION}_${codename}_${debarch}.deb"
            break
        fi
    done
    tmp=$(mktemp -d)
    if [ -n "$deb" ] && installfromnet wget -q -O "$tmp/die.deb" "${base}/${deb}" \
        && apt-fast install -y "$tmp/die.deb"; then
        goodecho "[+] Detect-It-Easy ${DIE_VERSION} installed (die, diec, diel)"
    else
        record_build_failure "download" "Detect-It-Easy" "deb download/install failed"
    fi
    rm -rf "$tmp"
    return 0
}

# ---------------------------------------------------------------------------
# Carving and memory forensics on raw flash / RAM dumps
# ---------------------------------------------------------------------------
# bulk_extractor (Simson Garfinkel; GPL-3.0-or-later, the original NPS code is public domain): scans a
# raw dump without parsing file systems and reports what it finds: AES key schedules, email
# addresses, URLs, domains, credit card numbers, JSON and base64 blobs, network packets, plus a
# histogram per feature (`bulk_extractor -o out/ dump.bin`; -f / -F add your own regexes, e.g. for
# credentials; -e wordlist builds a cracking wordlist). Not packaged for Ubuntu 26.04, so it is
# built from the release tarball, checked against the release's SHA256SUMS, on every architecture.
# libewf adds E01 input.
BULK_EXTRACTOR_VERSION="2.2.0"   # known-good (with the SHA256 below); the build takes the newest release
BULK_EXTRACTOR_SHA256="b9e15d40d711aa43590e1bf1a25d30943e3bad8371281d7c80d3803a6f34c268"

function bulk_extractor_soft_install() {
    goodecho "[+] Installing bulk_extractor"
    install_dependencies "build-essential pkg-config flex libre2-dev libabsl-dev libexpat1-dev libssl-dev libgcrypt20-dev zlib1g-dev libsqlite3-dev libewf-dev"
    local ver sha new_sha tmp src
    sha="$BULK_EXTRACTOR_SHA256"
    ver=$(latest_release_version simsong/bulk_extractor "$BULK_EXTRACTOR_VERSION" \
        "https://github.com/simsong/bulk_extractor/releases/download/v@V@/bulk_extractor-@V@.tar.gz")
    if [ "$ver" != "$BULK_EXTRACTOR_VERSION" ]; then
        new_sha=$(curl -fsSL --max-time 30 \
            "https://github.com/simsong/bulk_extractor/releases/download/v${ver}/SHA256SUMS" 2>/dev/null \
            | awk -v f="bulk_extractor-${ver}.tar.gz" '$2 == f {print $1}' || true)
        if [ -n "$new_sha" ]; then
            sha="$new_sha"
        else
            note_version_fallback simsong/bulk_extractor "no SHA256SUMS entry for ${ver}" "$BULK_EXTRACTOR_VERSION"
            ver="$BULK_EXTRACTOR_VERSION"
        fi
    fi
    tmp=$(mktemp -d)
    if ! installfromnet curl -fsSL -o "$tmp/bulk_extractor.tar.gz" \
            "https://github.com/simsong/bulk_extractor/releases/download/v${ver}/bulk_extractor-${ver}.tar.gz"; then
        record_build_failure "net" "bulk_extractor" "download failed (${ver})"
        rm -rf "$tmp"; return 0
    fi
    if ! echo "${sha}  $tmp/bulk_extractor.tar.gz" | sha256sum -c - > /dev/null; then
        record_build_failure "net" "bulk_extractor" "checksum mismatch (${ver})"
        rm -rf "$tmp"; return 0
    fi
    src="$tmp/bulk_extractor-${ver}"
    # configure adds -Werror whenever the compiler accepts it, and GCC 15 (resolute) warns where
    # upstream's CI compilers do not: keep warnings as warnings
    if tar -xzf "$tmp/bulk_extractor.tar.gz" -C "$tmp" --no-same-owner \
        && sed -i 's/^CXX_WARNINGS_TO_TEST="-Wall -Werror /CXX_WARNINGS_TO_TEST="-Wall /' "$src/configure" \
        && (cd "$src" && ./configure --enable-silent-rules && make -j"$(nproc)" && make install); then
        bulk_extractor -V || record_build_failure "other" "bulk_extractor" "bulk_extractor -V failed after install"
    else
        record_build_failure "build" "bulk_extractor" "${ver} configure/make failed"
    fi
    rm -rf "$tmp"
    return 0
}

# scalpel (GPL-2.0+) and foremost (public domain): header/footer file carving from raw dumps.
# scalpel's /etc/scalpel/scalpel.conf ships with every file type commented out: uncomment the types
# you want, or pass your own with -c. foremost has built-in types (-t jpg,zip,exe,...) and
# /etc/foremost.conf.
function scalpel_soft_install() {
    goodecho "[+] Installing scalpel"
    install_dependencies "scalpel"
}

function foremost_soft_install() {
    goodecho "[+] Installing foremost"
    install_dependencies "foremost"
}

# Volatility 3 (Volatility Foundation, Volatility Software License 1.0): memory forensics on RAM dumps,
# `vol -f dump.raw linux.pslist`, `volshell`. Newest PyPI release in its own uv tool venv (Python 3.13).
# Optional plugin dependencies: amd64 takes volatility3[full]; arm64 the yara-python, capstone and
# pycryptodome part of it (pillow and leechcorepyc, for LeechCore live acquisition, are left out:
# leechcorepyc has x86_64 wheels only); riscv64 has no wheels for them and gets the base package,
# without the plugins that need them (yarascan, the Windows hash/LSA dumps, ...).
# Linux and macOS dumps need a symbol table (ISF) for the exact kernel: dwarf2json, installed with
# it, builds one from a vmlinux with debug info (`dwarf2json linux --elf vmlinux > kernel.json`;
# then `vol -s <dir with kernel.json> ...`). Windows symbols are fetched from Microsoft on first use.
function volatility3_soft_install() {
    goodecho "[+] Installing Volatility 3 and dwarf2json"
    if ! command -v uv > /dev/null; then
        record_build_failure "toolchain" "volatility3" "uv unavailable"
        return 0
    fi
    local ok=0 b
    case "$(uname -m)" in
        x86_64)
            installfromnet uv tool install --force --python 3.13 "volatility3[full]" && ok=1
            ;;
        aarch64)
            # the same version bounds as volatility3[full]
            installfromnet uv tool install --force --python 3.13 --with "yara-python>=4.5.1,<5" \
                --with "capstone>=5.0.3,<6" --with "pycryptodome>=3.21.0,<4" volatility3 && ok=1
            ;;
    esac
    if [ "$ok" -eq 0 ]; then
        case "$(uname -m)" in
            x86_64|aarch64) record_build_failure "pip" "volatility3 extras" "optional plugin dependencies failed; installing the base package" ;;
        esac
        installfromnet uv tool install --force --python 3.13 volatility3 && ok=1
    fi
    if [ "$ok" -eq 0 ]; then
        record_build_failure "pip" "volatility3" "uv tool install failed"
    else
        for b in vol volshell; do
            [ -e "$HOME/.local/bin/$b" ] && ln -sf "$HOME/.local/bin/$b" "/usr/local/bin/$b"
        done
        vol -h > /dev/null || record_build_failure "other" "volatility3" "vol -h failed after install"
    fi
    # Go toolchain from corebuild's install_go
    if command -v go > /dev/null; then
        installfromnet env GOBIN=/usr/local/bin GOPROXY=https://proxy.golang.org,direct \
            go install github.com/volatilityfoundation/dwarf2json@latest \
            || record_build_failure "build" "dwarf2json" "go install failed"
    else
        record_build_failure "toolchain" "dwarf2json" "go unavailable"
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Crypto analysis
# ---------------------------------------------------------------------------
# bkcrack (kimci86, Zlib): known-plaintext attack on legacy ZipCrypto archives, common for
# encrypted firmware ZIPs. Built from the newest release's source, so every architecture gets it.
BKCRACK_VERSION="1.8.1"   # known-good; the build takes the newest release

function bkcrack_soft_install() {
    goodecho "[+] Installing bkcrack"
    install_dependencies "cmake g++ git"
    local ver dir
    ver=$(latest_release_version kimci86/bkcrack "$BKCRACK_VERSION" \
        "https://github.com/kimci86/bkcrack/archive/refs/tags/v@V@.tar.gz")
    dir=$(mktemp -d)
    if installfromnet git clone --depth 1 -b "v${ver}" https://github.com/kimci86/bkcrack.git "$dir/bkcrack" \
        && cmake -S "$dir/bkcrack" -B "$dir/build" -DCMAKE_BUILD_TYPE=Release \
        && cmake --build "$dir/build" -j"$(nproc)" \
        && rm -rf /opt/bkcrack && cmake --install "$dir/build" --prefix /opt/bkcrack; then
        ln -sf /opt/bkcrack/bkcrack /usr/local/bin/bkcrack
        # Helpers from the release: decompress a deciphered entry / compress a guessed plaintext
        printf '#!/bin/sh\nexec python3 /opt/bkcrack/tools/inflate.py "$@"\n' > /usr/local/bin/bkcrack-inflate
        printf '#!/bin/sh\nexec python3 /opt/bkcrack/tools/deflate.py "$@"\n' > /usr/local/bin/bkcrack-deflate
        chmod 755 /usr/local/bin/bkcrack-inflate /usr/local/bin/bkcrack-deflate
    else
        record_build_failure "build" "bkcrack" "v${ver} build failed"
    fi
    rm -rf "$dir"
    return 0
}

# fplll / fpylll: lattice reduction (LLL, BKZ) for lattice attacks on RSA, ECDSA nonces, knapsacks.
# Ubuntu packages both: the `fplll` / `latticegen` CLIs and the Python module for python3.
function fpylll_soft_install() {
    goodecho "[+] Installing fplll and fpylll"
    install_dependencies "fplll-tools python3-fpylll"
    python3 -c 'import fpylll' || record_build_failure "apt" "fpylll" "python3 cannot import fpylll"
    return 0
}

# SageMath through passagemath (pip packages of Sage, prebuilt for Python 3.14 on x86_64 and aarch64;
# none for riscv64). OPT-IN: about 1.3 GB of wheels, roughly 4 to 5 GB installed, so reversing.docker
# leaves it commented. Install in a running container: cd /root/scripts && ./entrypoint.sh sage_soft_install
# Own venv in /opt/sage (it also carries fpylll for `sage-python`); `sage` and `sage-python` on PATH.
function sage_soft_install() {
    goodecho "[+] Installing SageMath (passagemath)"
    case "$(uname -m)" in
        x86_64|aarch64) ;;
        *)
            criticalecho-noexit "[-] SageMath: no passagemath wheels for $(uname -m), skipping"
            return 0
            ;;
    esac
    if ! command -v uv > /dev/null; then
        record_build_failure "toolchain" "sage" "uv unavailable"
        return 0
    fi
    rm -rf /opt/sage
    # --no-cache: a cache would keep a second copy of the wheels in the image
    if ! uv venv --python 3.14 /opt/sage \
        || ! installfromnet uv pip install --no-cache --python /opt/sage/bin/python passagemath-standard; then
        record_build_failure "pip" "sage" "passagemath-standard install failed"
        return 0
    fi
    local b
    for b in sage sage-python; do
        printf '#!/bin/sh\nexec /opt/sage/bin/%s "$@"\n' "$b" > "/usr/local/bin/$b"
        chmod 755 "/usr/local/bin/$b"
    done
    sage -c 'assert factor(2^64 + 1) == 274177 * 67280421310721' \
        || record_build_failure "other" "sage" "sage -c smoke test failed"
    return 0
}

# OFRAK (Red Balloon Security): unpack, analyse, modify and repack firmware, with a web GUI.
# OPT-IN, never pre-installed: the free OFRAK Community License covers academic and personal
# non-commercial use only (work use needs an OFRAK Pro licence) and gives no right to redistribute
# OFRAK, so published images must not carry it. Installing OFRAK counts as accepting Red Balloon's
# licence (https://ofrak.com/license), so the installer only runs when you say so:
#   cd /root/scripts && OFRAK_ACCEPT_LICENSE=yes ./entrypoint.sh ofrak_soft_install
# Then register before the first analysis: `ofrak license --community` (asks you to type "I agree")
# or `ofrak license -l <OFRAK Pro licence file>`. The check is local: a signed license.json.
# PyPI only has Linux wheels for x86_64 and Python 3.9 to 3.13: amd64 only, Python 3.13 through uv.
# UEFIExtract and yaffs2utils (built from old sources upstream) are not included.
function ofrak_soft_install() {
    goodecho "[+] Installing OFRAK (Red Balloon Security)"
    if [ "$(uname -m)" != "x86_64" ]; then
        criticalecho-noexit "[-] OFRAK: PyPI has no Linux build for $(uname -m), skipping"
        return 0
    fi
    if [ "${OFRAK_ACCEPT_LICENSE:-}" != "yes" ]; then
        criticalecho-noexit "[!] OFRAK is licensed by Red Balloon Security. The free Community License covers academic and personal non-commercial use only; work use needs an OFRAK Pro licence. Installing OFRAK means accepting https://ofrak.com/license. To install: OFRAK_ACCEPT_LICENSE=yes ./entrypoint.sh ofrak_soft_install"
        return 0
    fi
    if ! command -v uv > /dev/null; then
        record_build_failure "toolchain" "ofrak" "uv unavailable"
        return 0
    fi
    # External tools its unpackers and packers call (`ofrak deps` lists them)
    install_dependencies "build-essential liblzo2-dev libmagic1t64 7zip aapt apktool binutils cpio e2fsprogs genisoimage lzop mtd-utils pigz squashfs-tools unar unzip util-linux-extra zip zstd"
    rm -rf /opt/ofrak
    # binwalk 2.3.4 is the Python module OFRAK's binwalk analyzer imports (requirements-non-pypi.txt)
    if ! uv venv --python 3.13 /opt/ofrak \
        || ! installfromnet uv pip install --no-cache --python /opt/ofrak/bin/python \
            ofrak ofrak-capstone ofrak-angr python-lzo \
            "binwalk @ git+https://github.com/ReFirmLabs/binwalk.git@v2.3.4"; then
        record_build_failure "pip" "ofrak" "install failed"
        return 0
    fi
    local name target
    for name in ofrak ofrak-python; do
        target=/opt/ofrak/bin/ofrak
        [ "$name" = "ofrak-python" ] && target=/opt/ofrak/bin/python
        cat > "/usr/local/bin/$name" << EOF
#!/bin/sh
# OFRAK (opt-in install, /opt/ofrak). Its own tools (binwalk 2.3.4, jefferson) come first on PATH,
# for OFRAK only. Register a licence first: ofrak license --community, or ofrak license -l <file>.
PATH="/opt/ofrak/bin:\$PATH" exec $target "\$@"
EOF
        chmod 755 "/usr/local/bin/$name"
    done
    # Lists missing external tools; needs no licence (that is checked when an analysis starts)
    ofrak deps --missing-only || record_build_failure "other" "ofrak" "ofrak deps failed after install"
    goodecho "[i] OFRAK installed. Before the first analysis, register a licence: ofrak license --community (academic or personal non-commercial use) or ofrak license -l <OFRAK Pro licence file>"
    return 0
}
