#!/bin/bash

function kc908_sa_device() {
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
        colorecho "[+] Architecture is $ARCH, proceeding with installation"
        colorecho "[+] Downloading bin from DEEPACE"
        [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
        cd /root/thirdparty
        installfromnet "wget" "https://github.com/PentHertz/rfswift_deepace_install/releases/download/nightly/KC908-GNURadio24.4.06.zip"
        unzip KC908-GNURadio24.4.06.zip
        rm KC908-GNURadio24.4.06.zip
        cd KC908-GNURadio/lib
        INCLUDE_DIR="/usr/local/include/kcsdr"
        LIB_DIR="/usr/local/lib"
        mkdir ${INCLUDE_DIR}
        cp ./kcsdr.h ${INCLUDE_DIR}
        cp ./libkcsdr.so ${LIB_DIR}
        chmod 666 ${INCLUDE_DIR}/kcsdr.h
        chmod 666 ${LIB_DIR}/libkcsdr.so
        rm -f /usr/lib/libftd3xx.so
        cp ./linux/ftd3xx.h /usr/include/
        cp ./linux/libftd3xx.so /usr/lib/
        cp ./linux/libftd3xx.so.0.5.21 /usr/lib/
        cp ./linux/51-ftd3xx.rules /etc/udev/rules.d/
        cd /root/thirdparty
        cd KC908-GNURadio/module3.9/gr-kc_sdr
        mkdir build \
        && cd build/ \
        && cmake -DCMAKE_INSTALL_PREFIX=/usr ../ \
        && make -j$(nproc); sudo make install
        cd /root/
        ln -s /usr/lib/python3.12/site-packages/gnuradio/kc_sdr /usr/lib/python3/dist-packages/gnuradio/ # quick fix for location
    else
        criticalecho-noexit "[!] Architecture is not amd64 or x86_64. Skipping installation."
    fi
}

function signalhound_sdk_install() {
    goodecho "[+] Installing Signal Hound SDK"
    [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    cd /root/thirdparty

    ARCH=$(uname -m)
    SDK_URL="https://signalhound.com/sigdownloads/SDK/signal_hound_sdk_09_14_26.zip"
    SDK_DIR="/opt/signalhound"

    installfromnet "wget" "-q" "${SDK_URL}" "-O" "signal_hound_sdk.zip"
    unzip -q signal_hound_sdk.zip
    rm signal_hound_sdk.zip

    sudo mkdir -p ${SDK_DIR}
    sudo cp -r signal_hound_sdk/* ${SDK_DIR}/

    # Helper: resolve arch-specific lib subdir pattern
    case "$ARCH" in
        x86_64|amd64)  LIB_PATTERN="linux_x64/Ubuntu 18.04" ;;
        aarch64|arm64) LIB_PATTERN="aarch64"    ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $ARCH"
            return 0
            ;;
    esac

    # Generic install_lib <series> <lib_prefix> - finds the real .so regardless of subdir naming
    install_sh_lib() {
        local series="$1"       # e.g. bb_series
        local prefix="$2"       # e.g. libbb_api
        local label="$3"        # e.g. BB60

        goodecho "[+] Installing ${label} API (${ARCH})"

        # Find the versioned .so under the arch-matching subdir, skip symlinks
        local LIB
        LIB=$(find "${SDK_DIR}/device_apis/${series}/lib" \
                   -path "*${LIB_PATTERN}*" \
                   -name "${prefix}.so.*" \
                   ! -type l \
                   2>/dev/null | sort -V | tail -1)

        if [ -z "$LIB" ]; then
            goodecho "[-] No ${label} library found, skipping"
            return
        fi

        local BASENAME VER MAJ
        BASENAME=$(basename "$LIB")
        VER=${BASENAME#${prefix}.so.}
        MAJ=${VER%%.*}

        sudo cp "$LIB" /usr/lib/
        sudo ln -sf /usr/lib/"${BASENAME}"        /usr/lib/${prefix}.so.${MAJ}
        sudo ln -sf /usr/lib/${prefix}.so.${MAJ}  /usr/lib/${prefix}.so
        goodecho "[+] ${label} API installed: ${BASENAME} (v${VER})"
    }

    install_sh_lib bb_series libbb_api BB60
    install_sh_lib sm_series libsm_api SM200
    install_sh_lib sp_series libsp_api SP145
    install_sh_lib vsg60_vsg200_series libvsg_api VSG60

    # FTDI driver (BB60 only, x86_64) - may ship without version suffix
    if [[ "$ARCH" == "x86_64" || "$ARCH" == "amd64" ]]; then
        FTDI_LIB=$(find "${SDK_DIR}/device_apis/bb_series/lib" \
                        -path "*${LIB_PATTERN}*" \
                        -name "libftd2xx.so*" \
                        ! -type l \
                        2>/dev/null | head -1)
        if [ -n "$FTDI_LIB" ]; then
            FTDI_BASE=$(basename "$FTDI_LIB")
            sudo cp "$FTDI_LIB" /usr/lib/
            # Only create the unversioned symlink if the file itself isn't already named libftd2xx.so
            if [ "$FTDI_BASE" != "libftd2xx.so" ]; then
                sudo ln -sf /usr/lib/"$FTDI_BASE" /usr/lib/libftd2xx.so
            fi
            goodecho "[+] FTDI driver installed: ${FTDI_BASE}"
        fi
    fi

    # Install headers
    goodecho "[+] Installing SDK headers"
    for series in bb_series sm_series sp_series vsg60_vsg200_series; do
        HEADER_DIR="${SDK_DIR}/device_apis/${series}/include"
        [ -d "$HEADER_DIR" ] && sudo cp "$HEADER_DIR"/*.h /usr/include/ 2>/dev/null
    done

    # Install udev rules
    goodecho "[+] Installing udev rules"
    RULES=$(find "${SDK_DIR}/device_apis" -name "sh_usb.rules" | head -1)
    if [ -n "$RULES" ]; then
        sudo cp "$RULES" /etc/udev/rules.d/99-signalhound.rules
        sudo udevadm control --reload-rules 2>/dev/null || true
    fi

    sudo ldconfig

    goodecho "[+] Signal Hound SDK installed:"
    ldconfig -p | grep -E "(bb_api|sm_api|sp_api|vsg_api)" || echo "  (no libraries detected in ldconfig)"
    ls -l /usr/include/bb_api.h /usr/include/sm_api.h /usr/include/sp_api.h /usr/include/vsg_api.h 2>/dev/null || echo "  (some headers missing)"

    rm -rf /root/thirdparty/signal_hound_sdk
}


function signalhound_spike_sa_device() {
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
        colorecho "[+] Architecture is $ARCH, proceeding with installation"
        colorecho "[+] Downloading Spike bin from SignalHound"
        [ -d /rftools/analysers ] || mkdir -p /rftools/analysers
        cd /rftools/analysers
        filename="Spike(Ubuntu_x64)_4_0_18"
        installfromnet "wget" "https://signalhound.com/sigdownloads/Spike/$filename.zip"
        unzip ${filename}.zip
        rm ${filename}.zip
        cd ${filename}
        chmod +x setup.sh
        sh -c ./setup.sh
        # Create the script content. BASE_DIR is derived from $filename so it
        # always matches the version that was actually downloaded/extracted (the
        # runtime $ variables are escaped so they stay literal in the wrapper).
        local script_path="/usr/local/bin/Spike"
        cat << EOF | sudo tee "$script_path" > /dev/null
#!/bin/sh

# Set the fixed path
BASE_DIR="/rftools/analysers/$filename"
APPNAME="Spike"

# Set up the environment variables
LD_LIBRARY_PATH="\$BASE_DIR/lib"
LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/MATLAB/MATLAB_Runtime/v911/runtime/glnxa64
export LD_LIBRARY_PATH
export QT_PLUGIN_PATH="\$BASE_DIR/plugins"

# Execute the binary
"\$BASE_DIR/bin/\$APPNAME" "\$@"
EOF

    # Make the script executable
    sudo chmod +x "$script_path"
    else
        criticalecho-noexit "[!] Architecture is not amd64 or x86_64. Skipping installation."
    fi
}

function signalhound_vsg60_sa_device() {
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
        colorecho "[+] Architecture is $ARCH, proceeding with installation"
        colorecho "[+] Downloading VSG software bin from SignalHound"
        [ -d /rftools/generators ] || mkdir -p /rftools/generators
        cd /rftools/generators
        filename="VSG(Ubuntu_x64)_2_0_5"
        installfromnet "wget" "https://signalhound.com/sigdownloads/VSG60/$filename.zip"
        unzip "$filename.zip"
        rm "$filename.zip"
        cd "$filename"
        chmod +x setup.sh
        sh -c ./setup.sh
        local script_path="/usr/sbin/vsg_signalhound"
    
        # Create the script content. As for Spike, BASE_DIR is derived from
        # $filename so it matches the version that was downloaded/extracted
        # (the runtime $ variables are escaped so they stay literal).
        cat << EOF | sudo tee "$script_path" > /dev/null
#!/bin/sh

# Set the fixed path
BASE_DIR="/rftools/generators/$filename"
APPNAME="vsg_signalhound"

# Set up the environment variables
LD_LIBRARY_PATH="\$BASE_DIR/lib"
export LD_LIBRARY_PATH
export QT_PLUGIN_PATH="\$BASE_DIR/plugins"

# Execute the binary
"\$BASE_DIR/bin/\$APPNAME" "\$@"
EOF

    # Make the script executable
    sudo chmod +x "$script_path"
    
    echo "VSG60 script has been created at $script_path and made executable"
    else
        criticalecho-noexit "[!] Architecture is not amd64 or x86_64. Skipping installation."
    fi
}

function harogic_sa_device() {
    goodecho "[+] Downloading SAStudio4"
    [ -d /rftools/analysers ] || mkdir -p /rftools/analysers
    cd /rftools/analysers
    arch=`uname -m`  # uname -m is reliable in containers; uname -i can return "unknown"
    prog=""
    sdkarch=""
    case "$arch" in
        x86_64|amd64)
            prog="SAStudio4_4.3.55.30_x86_64";;
        aarch64|unknown|arm64)
            prog="SAStudio4_4.3.55.30_arm64";;
        *)
            printf 'Unsupported architecture: "%s"!\n' "$arch" >&2; exit 0;;
    esac
    installfromnet "wget" "https://github.com/PentHertz/rfswift_harogic_install/releases/download/v0.55.63/$prog.zip"
    unzip "$prog.zip"
    rm "$prog.zip"
    cd "$prog"
    currentpath=$(pwd)
    mkdir -p /root/Desktop
    mkdir -p /home/root/Desktop/
    sed -i 's/actual_user=$(logname)/actual_user="root"/g' install.sh
    sed -i 's/$SUDO_USER/root/g' install.sh
    ./install.sh
    case "$arch" in
        aarch64|unknown) 
            ln -s /usr/lib/aarch64-linux-gnu/libffi.so.8 /usr/lib/libffi.so.6;;
    esac
    ln -s /usr/local/bin/sastudio/.sastudio.sh /usr/sbin/sastudio
    goodecho "[+] Installing htraapi"
    installfromnet "wget" "https://github.com/PentHertz/rfswift_harogic_install/releases/download/v0.55.63/Install_HTRA_SDK.zip"
    unzip Install_HTRA_SDK.zip
    rm Install_HTRA_SDK.zip
    cd Install_HTRA_SDK/
    cp htraapi/configs/htrausb.conf /etc/
    cp htraapi/configs/htra-cyusb.rules /etc/udev/rules.d/
    rm -rf /opt/htraapi/
    cp -r htraapi/ /opt/
    
    case "$arch" in
        x86_64|amd64)
            sdkarch="x86_64"
            ;;
        aarch64|unknown)
            sdkarch="aarch64"
            ;;
        *)
            printf 'Unsupported architecture: "%s"!\n' "$arch" >&2
            exit 0
            ;;
    esac
    
    # Extract library version from the actual architecture path
    file=$( ls htraapi/lib/${sdkarch}/libhtraapi.so.* | head -1 )
    [ -z "$file" ] && { echo "Error: libhtraapi.so not found for $sdkarch"; exit 1; }
    file=$( basename $file )
    version=${file#*so.}
    majornum=${version%%.*}
    
    # Create version symlinks in SDK directory
    case "$arch" in
        x86_64|amd64)
            ln -sf /opt/htraapi/lib/x86_64/libhtraapi.so.${version} /opt/htraapi/lib/x86_64/libhtraapi.so.${majornum}
            ln -sf /opt/htraapi/lib/x86_64/libhtraapi.so.${majornum} /opt/htraapi/lib/x86_64/libhtraapi.so
            ln -sf /opt/htraapi/lib/x86_64/libusb-1.0.so.0.2.0 /opt/htraapi/lib/x86_64/libusb-1.0.so.0
            ln -sf /opt/htraapi/lib/x86_64/libusb-1.0.so.0 /opt/htraapi/lib/x86_64/libusb-1.0.so
            ;;
        aarch64|unknown)
            ln -sf /opt/htraapi/lib/aarch64/libhtraapi.so.${version} /opt/htraapi/lib/aarch64/libhtraapi.so.${majornum}
            ln -sf /opt/htraapi/lib/aarch64/libhtraapi.so.${majornum} /opt/htraapi/lib/aarch64/libhtraapi.so
            ln -sf /opt/htraapi/lib/aarch64/libusb-1.0.so.0.2.0 /opt/htraapi/lib/aarch64/libusb-1.0.so.0
            ln -sf /opt/htraapi/lib/aarch64/libusb-1.0.so.0 /opt/htraapi/lib/aarch64/libusb-1.0.so
            ;;
    esac
    
    # Copy libraries to system paths
    cd "/opt/htraapi/lib/${sdkarch}"
    [ -f libhtraapi.so ] || { echo "Error: symlink setup failed"; exit 1; }
    cp libh* /usr/lib/
    ln -sf $(pwd)/libliquid.so /usr/lib/libliquid.so
    cp /opt/htraapi/inc/htra_api.h /usr/include
    
    # Update linker cache
    ldconfig
    
    colorecho "[+] Note: you'll have to put your calibration data after!"
    mkdir -p /rftools/analysers/${prog}/bin/CalFile
    ln -s /rftools/analysers/${prog}/bin/CalFile /usr/bin/CalFile

}

function harogic_sa_device_new() {
    goodecho "[+] Downloading SAStudio4"
    [ -d /rftools/analysers ] || mkdir -p /rftools/analysers
    cd /rftools/analysers
    arch=`uname -m`  # uname -m is reliable in containers; uname -i can return "unknown"
    prog=""
    sdkarch=""
    case "$arch" in
        x86_64|amd64)
            prog="SAStudio4_4.3.55.35_amd64";;
        aarch64|unknown|arm64)
            prog="SAStudio4_4.3.55.35_arm64";;
        *)
            printf 'Unsupported architecture: "%s"!\n' "$arch" >&2; exit 0;;
    esac
    installfromnet "wget" "https://github.com/PentHertz/rfswift_harogic_install/releases/download/v0.55.64/$prog.zip"
    unzip "$prog.zip"
    rm "$prog.zip"
    cd "$prog"
    currentpath=$(pwd)
    mkdir -p /root/Desktop
    mkdir -p /home/root/Desktop/
    sed -i 's/actual_user=$(logname)/actual_user="root"/g' install.sh
    sed -i 's/$SUDO_USER/root/g' install.sh
    ./install.sh
    case "$arch" in
        aarch64|unknown) 
            ln -s /usr/lib/aarch64-linux-gnu/libffi.so.8 /usr/lib/libffi.so.6;;
    esac
    ln -s /usr/local/bin/sastudio/.sastudio.sh /usr/sbin/sastudio
    goodecho "[+] Installing htraapi"
    installfromnet "wget" "https://github.com/PentHertz/rfswift_harogic_install/releases/download/v0.55.64/Install_HTRA_SDK.zip"
    unzip Install_HTRA_SDK.zip
    rm Install_HTRA_SDK.zip
    cd Install_HTRA_SDK/
    cp htraapi/configs/htrausb.conf /etc/
    cp htraapi/configs/htra-cyusb.rules /etc/udev/rules.d/
    rm -rf /opt/htraapi/
    cp -r htraapi/ /opt/
    
    case "$arch" in
        x86_64|amd64)
            sdkarch="x86_64"
            ;;
        aarch64|unknown)
            sdkarch="aarch64"
            ;;
        *)
            printf 'Unsupported architecture: "%s"!\n' "$arch" >&2
            exit 0
            ;;
    esac
    
    # Extract library version from the actual architecture path
    file=$( ls htraapi/lib/${sdkarch}/libhtraapi.so.* | head -1 )
    [ -z "$file" ] && { echo "Error: libhtraapi.so not found for $sdkarch"; exit 1; }
    file=$( basename $file )
    version=${file#*so.}
    majornum=${version%%.*}
    
    # Create version symlinks in SDK directory
    case "$arch" in
        x86_64|amd64)
            ln -sf /opt/htraapi/lib/x86_64/libhtraapi.so.${version} /opt/htraapi/lib/x86_64/libhtraapi.so.${majornum}
            ln -sf /opt/htraapi/lib/x86_64/libhtraapi.so.${majornum} /opt/htraapi/lib/x86_64/libhtraapi.so
            ln -sf /opt/htraapi/lib/x86_64/libusb-1.0.so.0.2.0 /opt/htraapi/lib/x86_64/libusb-1.0.so.0
            ln -sf /opt/htraapi/lib/x86_64/libusb-1.0.so.0 /opt/htraapi/lib/x86_64/libusb-1.0.so
            ;;
        aarch64|unknown)
            ln -sf /opt/htraapi/lib/aarch64/libhtraapi.so.${version} /opt/htraapi/lib/aarch64/libhtraapi.so.${majornum}
            ln -sf /opt/htraapi/lib/aarch64/libhtraapi.so.${majornum} /opt/htraapi/lib/aarch64/libhtraapi.so
            ln -sf /opt/htraapi/lib/aarch64/libusb-1.0.so.0.2.0 /opt/htraapi/lib/aarch64/libusb-1.0.so.0
            ln -sf /opt/htraapi/lib/aarch64/libusb-1.0.so.0 /opt/htraapi/lib/aarch64/libusb-1.0.so
            ;;
    esac
    
    # Copy libraries to system paths
    cd "/opt/htraapi/lib/${sdkarch}"
    [ -f libhtraapi.so ] || { echo "Error: symlink setup failed"; exit 1; }
    cp libh* /usr/lib/
    ln -sf $(pwd)/libliquid.so /usr/lib/libliquid.so
    cp /opt/htraapi/inc/htra_api.h /usr/include
    
    # Update linker cache
    ldconfig
    
    colorecho "[+] Note: you'll have to put your calibration data after!"
    mkdir -p /rftools/analysers/${prog}/bin/CalFile
    ln -s /rftools/analysers/${prog}/bin/CalFile /usr/bin/CalFile

}

function harogic_sa_device_latest() {
    goodecho "[+] Downloading SAStudio4"
    [ -d /rftools/analysers ] || mkdir -p /rftools/analysers
    cd /rftools/analysers
    arch=`uname -m`  # uname -m is reliable in containers; uname -i can return "unknown"
    local sa_version="4.4.55.64"
    local base="https://github.com/PentHertz/rfswift_harogic_install/releases/download/sa_v${sa_version}"
    prog=""
    sdkarch=""
    case "$arch" in
        x86_64|amd64)
            prog="SAStudio4_x86_64_${sa_version}"
            sdkarch="x86_64";;
        aarch64|unknown|arm64)
            prog="SAStudio4_arm64_${sa_version}"
            sdkarch="aarch64";;
        *)
            printf 'Unsupported architecture: "%s"!\n' "$arch" >&2; exit 0;;
    esac
    install_dependencies "unzip libusb-1.0-0 libgomp1 qtbase5-dev libxcb-cursor-dev"
    installfromnet "wget" "${base}/$prog.zip"
    # Since 4.4.55.64 both arches ship the same portable bundle: the zip has a
    # $prog/ root directory, no install.sh, and bin/SAStudio4 runs directly with
    # the bundled Qt + HTRA SDK libs (lib/, symlinks included) on LD_LIBRARY_PATH.
    rm -rf "/rftools/analysers/${prog}"
    unzip -q "$prog.zip"
    rm "$prog.zip"
    chmod +x /rftools/analysers/${prog}/bin/SAStudio4
    rm -f /usr/sbin/sastudio
    cat > /usr/sbin/sastudio <<EOF
#!/bin/bash
export LD_LIBRARY_PATH="/rftools/analysers/${prog}/lib:\$LD_LIBRARY_PATH"
cd /rftools/analysers/${prog}/bin
exec ./SAStudio4 "\$@"
EOF
    chmod +x /usr/sbin/sastudio

    goodecho "[+] Installing htraapi (SA_Linux_API)"
    installfromnet "wget" "${base}/SA_Linux_API.zip"
    rm -rf SA_Linux_API
    unzip -q SA_Linux_API.zip
    rm SA_Linux_API.zip
    cd SA_Linux_API/
    cp htraapi/configs/htrausb.conf /etc/
    mkdir -p /etc/udev/rules.d
    cp htraapi/configs/htra-cyusb.rules /etc/udev/rules.d/
    rm -rf /opt/htraapi/
    cp -r htraapi/ /opt/

    # Extract library version from the actual architecture path
    file=$( ls htraapi/lib/${sdkarch}/libhtraapi.so.* | head -1 )
    [ -z "$file" ] && { echo "Error: libhtraapi.so not found for $sdkarch"; exit 1; }
    file=$( basename $file )
    version=${file#*so.}
    majornum=${version%%.*}

    # Create version symlinks in SDK directory
    ln -sf /opt/htraapi/lib/${sdkarch}/libhtraapi.so.${version} /opt/htraapi/lib/${sdkarch}/libhtraapi.so.${majornum}
    ln -sf /opt/htraapi/lib/${sdkarch}/libhtraapi.so.${majornum} /opt/htraapi/lib/${sdkarch}/libhtraapi.so
    ln -sf /opt/htraapi/lib/${sdkarch}/libusb-1.0.so.0.2.0 /opt/htraapi/lib/${sdkarch}/libusb-1.0.so.0
    ln -sf /opt/htraapi/lib/${sdkarch}/libusb-1.0.so.0 /opt/htraapi/lib/${sdkarch}/libusb-1.0.so

    # Copy libraries to system paths (libusb/libgomp come from the distro packages
    # so the bundled copies don't shadow them for other SDR tools)
    cd "/opt/htraapi/lib/${sdkarch}"
    [ -f libhtraapi.so ] || { echo "Error: symlink setup failed"; exit 1; }
    rm -f /usr/lib/libhtraapi.so*   # drop older SDK versions
    cp -P libhtraapi.so* /usr/lib/
    ln -sf $(pwd)/libliquid.so /usr/lib/libliquid.so
    # New in 4.4.55.64: optional DSP helpers (demodulation, MKL/ArmRAL), dlopen'ed by the API
    for l in libDigitalSigDemod.so libmkl.so libiomp5.so libarmral.so; do
        [ -f "$l" ] && ln -sf $(pwd)/$l /usr/lib/$l
    done
    cp /opt/htraapi/inc/htra_api*.h /usr/include/

    # Update linker cache
    ldconfig
    cd /rftools/analysers
    rm -rf SA_Linux_API

    colorecho "[+] Note: you'll have to put your calibration data after!"
    mkdir -p /rftools/analysers/${prog}/bin/CalFile
    ln -sfn /rftools/analysers/${prog}/bin/CalFile /usr/bin/CalFile
}

# Harogic H2 API (SG_Linux_API): used by SGStudio and by gr-harogic_sg.
HAROGIC_SG_RELEASE="https://github.com/PentHertz/rfswift_harogic_install/releases/download/gen_v2.0.40"

function harogic_h2api_install() {
    local sdkarch
    case "$(uname -m)" in  # uname -m is reliable in containers; uname -i can return "unknown"
        x86_64|amd64) sdkarch="x86_64";;
        aarch64|unknown|arm64) sdkarch="aarch64";;
        armv7l|armv7) sdkarch="armv7";;
        *) criticalecho-noexit "[!] H2 API: unsupported architecture $(uname -m)"; return 0;;
    esac
    goodecho "[+] Installing Harogic H2 API (SG_Linux_API)"
    install_dependencies "libusb-1.0-0 libgomp1 unzip"
    local workdir
    workdir=$(mktemp -d)
    (
        cd "$workdir" || exit 1
        if ! installfromnet "wget" "${HAROGIC_SG_RELEASE}/SG_Linux_API.zip"; then
            record_build_failure "download" "h2api" "SG_Linux_API.zip"
            exit 0
        fi
        unzip -q SG_Linux_API.zip
        # Vendor installer: /opt/h2api, /etc/h2usb_enum.conf (VID:PID allow-list that
        # libh2api needs to enumerate anything over USB), udev rule, libgomp fix, ldconfig
        sh SG_Linux_API/install_h2_lib.sh \
            || record_build_failure "install" "h2api" "install_h2_lib.sh failed"
    )
    rm -rf "$workdir"
    # install_h2_lib.sh registers /opt/h2api/lib/<arch> as 00-h2api.conf, ahead of
    # the system dirs: keep its old bundled libusb out of the loader path so it
    # doesn't shadow the system libusb for every other SDR tool in the image.
    if [ -d "/opt/h2api/lib/${sdkarch}" ]; then
        mkdir -p /opt/h2api/lib/bundled_libusb
        mv /opt/h2api/lib/${sdkarch}/libusb-1.0.so* /opt/h2api/lib/bundled_libusb/ 2>/dev/null
        ldconfig
    fi
    [ -f /opt/h2api/inc/h2_api.h ] && cp /opt/h2api/inc/h2_*.h /usr/include/
    return 0
}

# libh2api loads <directory of the running program>/CalFile/<model>.ini. GNU Radio
# runs under /usr/bin/python3, so the SG calibration files must be in
# /usr/bin/CalFile (which may already be a symlink to SAStudio's CalFile: the SA
# files are .txt, so they don't collide).
function harogic_sg_install_calfiles() {
    local src="$1" dst="/usr/bin/CalFile"
    ls "$src"/*.ini > /dev/null 2>&1 || return 0
    [ -L "$dst" ] && dst="$(readlink -f "$dst")"
    mkdir -p "$dst"
    cp -f "$src"/*.ini "$dst"/
    colorecho "[+] SG calibration files copied to $dst"
}

function harogic_sg_device() {
    # Harogic H2 signal generators (e.g. 367f:0101): H2 API + SGStudio
    local version="2.7.6.1"
    local base="${HAROGIC_SG_RELEASE}"
    local arch sdkarch prog
    arch=`uname -m`  # uname -m is reliable in containers; uname -i can return "unknown"
    case "$arch" in
        x86_64|amd64) sdkarch="x86_64";;
        aarch64|unknown|arm64) sdkarch="aarch64";;
        armv7l|armv7) sdkarch="armv7";;
        *)
            printf 'Unsupported architecture: "%s"!\n' "$arch" >&2; return 0;;
    esac
    [ -d /rftools/generators ] || mkdir -p /rftools/generators
    cd /rftools/generators

    harogic_h2api_install

    case "$sdkarch" in
        x86_64)  prog="SGStudio_x86_64_${version}";;
        aarch64) prog="SGStudio_arm64_${version}";;
        *)
            criticalecho-noexit "[!] SGStudio is only published for x86_64 and arm64; skipping the GUI (H2 API installed)."
            return 0;;
    esac

    goodecho "[+] Downloading Harogic SGStudio ${version} (${sdkarch})"
    rm -rf "$prog" "$prog.tar.gz"
    if ! installfromnet "wget" "${base}/${prog}.tar.gz"; then
        record_build_failure "download" "SGStudio" "${prog}.tar.gz"
        return 0
    fi
    tar -xzf "$prog.tar.gz"   # contains a single ${prog}/ root directory
    rm "$prog.tar.gz"
    [ -f "/rftools/generators/${prog}/bin/SGStudio" ] || { record_build_failure "install" "SGStudio" "bin/SGStudio missing in ${prog}.tar.gz"; return 0; }
    chmod +x "/rftools/generators/${prog}/bin/SGStudio"
    harogic_sg_install_calfiles "/rftools/generators/${prog}/bin/CalFile"
    install_dependencies "libxcb-cursor0 libpulse0 libsndfile1 libegl1 libgl1 libdbus-1-3"

    # Fallback if the API step failed: without this file libh2api never scans USB
    if [ ! -f /etc/h2usb_enum.conf ]; then
        cat > /etc/h2usb_enum.conf <<'EOF'
# Vital Product Data : Vendor/Device IDs - one per line.
# Format - vendorID DeviceID    FriendlyName (Max 30 chars or end of line)

<VPD>
367f    0101    H2_Devices
367f    0102    H2_Devices
367f    0103    H2_Devices
367f    0104    H2_Devices
367f    0105    H2_Devices
367f    0106    H2_Devices
367f    0107    H2_Devices
367f    0108    H2_Devices
04b4    00f0    GENERICDEVICES
</VPD>
EOF
        chmod 644 /etc/h2usb_enum.conf
    fi

    # The app writes debug.log and Settings.ini inside its own tree
    mkdir -p "/rftools/generators/${prog}/bin/CalFile"
    cat > /usr/sbin/sgstudio <<EOF
#!/bin/bash
BASE_DIR="/rftools/generators/${prog}"
# X11 by default (the arm64 bundle also ships Wayland: QT_QPA_PLATFORM=wayland sgstudio)
export QT_QPA_PLATFORM="\${QT_QPA_PLATFORM:-xcb}"
export QT_PLUGIN_PATH="\$BASE_DIR/bin"
export QT_QPA_PLATFORM_PLUGIN_PATH="\$BASE_DIR/bin/platforms"
unset WAYLAND_DISPLAY QT_WAYLAND_SHELL_INTEGRATION
# RUNPATH is not inherited by transitive deps of bundled Qt libs, so expose every bundle dir
export LD_LIBRARY_PATH="\$BASE_DIR/lib:\$BASE_DIR/bin:\$BASE_DIR/plugin:\$BASE_DIR/updater\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
cd "\$BASE_DIR/bin"
exec ./SGStudio "\$@"
EOF
    chmod +x /usr/sbin/sgstudio
    colorecho "[+] SGStudio installed: run 'sgstudio'. Put calibration data in /rftools/generators/${prog}/bin/CalFile"
}
