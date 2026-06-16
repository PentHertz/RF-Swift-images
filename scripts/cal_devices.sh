#!/bin/bash

function leobodnarv1_cal_device() {
	goodecho "[+] Installing dependencies for Leobodnar v1 GPSDO"
	[ -d /rftools/calibration ] || mkdir -p /rftools/calibration
	cd /rftools/calibration
	install_dependencies "libhidapi-libusb0 libhidapi-hidraw0"
	goodecho "[+] Cloning repository for Leobodnar v1 GPSDO"
	gitinstall "https://github.com/hamarituc/lbgpsdo.git"
	cd lbgpsdo
	pip3install -r requirements.txt
	cd /root/
}

function leobodnarv2_cal_device() {
	goodecho "[+] Installing Leobodnar LBE-142x GPSDO"
	[ -d /rftools/calibration ] || mkdir -p /rftools/calibration
	cd /rftools/calibration
	gitinstall "https://github.com/bvernoux/lbe-142x.git" "leobodnarv2_cal_device"
	cd lbe-142x
	mkdir build && cd build
	cmake ..
	make -j$(nproc)
	ln -s $(pwd)/lbe-142x /usr/bin/lbe-142x
	#usermod -aG plugdev $(whoami)
}

function gnsslogger_cal_device() {
	goodecho "[+] Installing gnsslogger"
	[ -d /rftools/calibration ] || mkdir -p /rftools/calibration
	cd /rftools/calibration
	gitinstall "https://github.com/bvernoux/gnsslogger.git" "gnsslogger_cal_device"
	cd gnsslogger
	mkdir build && cd build
	cmake -DBUILD_TESTS=ON ..
	cmake -DBUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release ..
	ln -s $(pwd)/gnsslogger /usr/bin/gnsslogger
}

function KCSDI_cal_device() {
   goodecho "[+] Installing dependencies for KCSDI"
   [ -d /rftools/calibration/Deepace ] || mkdir -p /rftools/calibration/Deepace
   cd /rftools/calibration/Deepace
   local ARCH=$(uname -m)
    case "$ARCH" in
        x86_64|amd64)
            image_name="KCSDI-v0.5.11-72-linux-x86_64.1.appimage"
            ;;
        aarch64)
            image_name="KCSDI-v0.5.11-72-linux-arm64.1.appimage"
            ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $ARCH. KCSDI installation is not supported on this architecture."
            return 0
            ;;
    esac
   install_dependencies "libnss3-dev libfuse-dev"
   goodecho "[+] Downloading KCSDI from penthertz repo"
   installfromnet "wget https://github.com/PentHertz/rfswift_deepace_install/releases/download/nightly/${image_name}"
   chmod +x ${image_name}
   goodecho "[+] Creating wrapper script (extraction deferred to runtime)"
   rm -f /usr/bin/KCSDI
   cat << EOF > /usr/bin/KCSDI
#!/bin/bash
APPDIR="/rftools/calibration/Deepace"
APPIMAGE="\${APPDIR}/${image_name}"
EXTRACTED="\${APPDIR}/squashfs-root"

if [ ! -d "\${EXTRACTED}" ]; then
    echo "[+] First run: extracting AppImage..."
    cd "\${APPDIR}"
    "\${APPIMAGE}" --appimage-extract > /dev/null 2>&1
fi

exec "\${EXTRACTED}/kcsdi" --no-sandbox "\$@"
EOF
   chmod +x /usr/bin/KCSDI
}

function NanoVNASaver_cal_device() {
    local ARCH=$(uname -m)

    case "$ARCH" in
        x86_64|amd64)
            NanoVNASaver_cal_device_call
            ;;
        i?86)
            NanoVNASaver_cal_device_call
            ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $ARCH. NanoVNASaver installation is not supported on this architecture."
            ;;
    esac
}

function NanoVNASaver_cal_device_call() {
    install_dependencies "libxcb-cursor0"

    # resolute's system Python is 3.14, which the latest NanoVNA-Saver release
    # (v0.7.3) does not support (requires-python "<3.13").
    if command -v uv >/dev/null 2>&1; then
        # Preferred: use uv to provision a compatible standalone Python and install
        # the stable release into a dedicated venv, then wrap it.
        goodecho "[+] Installing NanoVNASaver (stable v0.7.3) with uv on Python 3.12"
        local nvs_dir="/rftools/calibration/nanovnasaver"
        [ -d "$nvs_dir" ] || mkdir -p "$nvs_dir"
        uv python install 3.12
        uv venv --python 3.12 "$nvs_dir/.venv"
        uv pip install --python "$nvs_dir/.venv/bin/python" \
            PySide6 'git+https://github.com/NanoVNA-Saver/nanovna-saver.git@v0.7.3'
        cat > /usr/bin/NanoVNASaver <<'EOF'
#!/bin/bash
exec /rftools/calibration/nanovnasaver/.venv/bin/NanoVNASaver "$@"
EOF
        chmod +x /usr/bin/NanoVNASaver
    else
        # Fallback: no uv. main has relaxed requires-python to ">=3.10", so install
        # a 3.14-compatible commit with pipx under the system Python (pin until a
        # release >0.7.3 ships).
        goodecho "[+] Installing NanoVNASaver with pipx on the system Python"
        pip3 install --break-system-packages PySide6
        pipx install 'git+https://github.com/NanoVNA-Saver/nanovna-saver.git@3445a0ab86161f9c886c9d6f215eb57cab9b6f45'
        ln -sf /root/.local/bin/NanoVNASaver /usr/bin/NanoVNASaver
    fi
}

function NanoVNA_QT_cal_device() {
	goodecho "[+] Installing dependencies for NanoVNA-QT"
	[ -d /rftools/calibration ] || mkdir -p /rftools/calibration
	cd /rftools/calibration
	install_dependencies "automake libtool make g++ libeigen3-dev libfftw3-dev libqt6charts6-dev"
	goodecho "[+] Cloning and installing NanoVNA-QT"
	gitinstall "https://github.com/FlUxIuS/NanoVNA-QT.git"
	cd NanoVNA-QT
	cmake .
	make -j$(nproc)
	ln -s $(pwd)/vna_qt/vna_qt /usr/bin/vna_qt
}

function pocketvna_sa_device() {
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
        colorecho "[+] Architecture is $ARCH, proceeding with installation"
        colorecho "[+] Downloading lastest pocketVNA install script from GitHub"
        [ -d /rftools/calibration ] || mkdir -p /rftools/calibration
		cd /rftools/calibration
        mkdir pocketVNA
        cd pocketVNA
        installfromnet "wget https://github.com/PentHertz/rfswift_unofficial_pocketvna/releases/download/latest/pocketVna1.m96-New_x86_64.run.2.tar.gz"
        tar xvzf pocketVna1.m96-New_x86_64.run.2.tar.gz
        rm pocketVna1.m96-New_x86_64.run.2.tar.gz
        chmod +x pocketVna1.m96-New_x86_64.run
        ln -s $(pwd)/pocketVna1.m96-New_x86_64.run /usr/sbin/pocketVNA
    else
        criticalecho-noexit "[!] Architecture is not amd64 or x86_64. Skipping installation."
    fi
}

function librevna_cal_device() {
	goodecho "[+] Installing dependencies for LibreVNA"
  install_dependencies "qt6-base-dev libqt6svg6 libusb-1.0-0-dev qt6-svg-dev"
	[ -d /rftools/calibration ] || mkdir -p /rftools/calibration
	cd /rftools/calibration
	gitinstall "https://github.com/jankae/LibreVNA.git" "librevna_cal_device"
	cd LibreVNA
	cd Software/PC_Application/LibreVNA-GUI
	qmake6 LibreVNA-GUI.pro
	make -j$(nproc)
	ln -s "$(pwd)/LibreVNA-GUI" /usr/bin/LibreVNA-GUI
}

function librecala_cal_device() {
	goodecho "[+] Installing dependencies for LibreCAL A"
	install_dependencies "qt6-base-dev libqt6svg6-dev libusb-1.0-0-dev libqt6charts6-dev libqt6opengl6-dev"
	[ -d /rftools/calibration ] || mkdir -p /rftools/calibration
	cd /rftools/calibration
	gitinstall "https://github.com/jankae/LibreCAL.git" "librecala_cal_device"
	cd LibreCAL/Software/LibreCAL-GUI
	qmake6 LibreCAL-GUI.pro
	make -j$(nproc)
	make install
	ln -s "/opt/LibreCAL-GUI/bin/LibreCAL-GUI" /usr/bin/LibreCAL-GUI
}

function librevna_cal_device_buildx() {
    # Check architecture using uname
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        librevna_cal_device
    else
        goodecho "[!] Skipping LibreVNA build for $ARCH architecture as Qmake fails to get context with buildx"
    fi
}

function xnec2c_cal_device() {
	goodecho "[+] Installing dependencies for xnec2c"
	install_dependencies "gettext autopoint"
	[ -d /rftools/calibration ] || mkdir -p /rftools/calibration
	cd /rftools/calibration
	gitinstall "https://github.com/KJ7LNW/xnec2c.git" "xnec2c_cal_device"
	cd xnec2c
	./autogen.sh
	./configure
	make && make install
}

function lotus_budc_tune_device() {
	goodecho "[+] Installing dependencies for lotus_budc"
	install_dependencies "libserialport-dev"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    cd /root/thirdparty
	cmake_clone_and_build "https://github.com/PentHertz/lotus_budc_controler.git" "build" "" "" "lotus_budc_tune_device"
}

function kalibrate_hydrasdr_device() {
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    cd /root/thirdparty
	cmake_clone_and_build "https://github.com/hydrasdr/kalibrate-hydrasdr.git" "build" "" "" "kalibrate_hydrasdr_device"
}