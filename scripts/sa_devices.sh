#!/bin/bash

function kc908_sa_device() {
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
        colorecho "[+] Architecture is $ARCH, proceeding with installation"
        colorecho "[+] Downloading bin from DEEPACE"
        [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
        cd /root/thirdparty
        installfromnet "wget https://github.com/PentHertz/rfswift_deepace_install/releases/download/nightly/KC908-GNURadio24.4.06.zip"
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

function signalhound_spike_sa_device() {
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
        colorecho "[+] Architecture is $ARCH, proceeding with installation"
        colorecho "[+] Downloading Spike bin from SignalHound"
        [ -d /rftools/analysers ] || mkdir -p /rftools/analysers
        cd /rftools/analysers
        filename="Spike(Ubuntu22.04x64)_4_0_12"
        installfromnet "wget https://signalhound.com/sigdownloads/Spike/$filename.zip"
        unzip ${filename}.zip
        rm ${filename}.zip
        cd ${filename}
        chmod +x setup.sh
        sh -c ./setup.sh
        # Create the script content
        local script_path="/usr/local/bin/Spike"
        cat << 'EOF' | sudo tee "$script_path" > /dev/null
#!/bin/sh

# Set the fixed path
BASE_DIR="/rftools/analysers/Spike(Ubuntu22.04x64)_4_0_12"
APPNAME="Spike"

# Set up the environment variables
LD_LIBRARY_PATH="$BASE_DIR/lib"
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/MATLAB/MATLAB_Runtime/v911/runtime/glnxa64
export LD_LIBRARY_PATH
export QT_PLUGIN_PATH="$BASE_DIR/plugins"

# Execute the binary
"$BASE_DIR/bin/$APPNAME" "$@"
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
        colorecho "[+] Downloading VSG60 bin from SignalHound"
        [ -d /rftools/generators ] || mkdir -p /rftools/generators
        cd /rftools/generators
        filename="VSG60(Ubuntu22.04x64)_1_0_19"
        installfromnet "wget https://signalhound.com/sigdownloads/VSG60/$filename.zip"
        unzip "VSG60(Ubuntu22.04x64)_1_0_19.zip"
        rm "VSG60(Ubuntu22.04x64)_1_0_19.zip"
        cd "VSG60(Ubuntu22.04x64)_1_0_19"
        chmod +x setup.sh
        sh -c ./setup.sh
        local script_path="/usr/sbin/vsg60"
    
        # Create the script content
        cat << 'EOF' | sudo tee "$script_path" > /dev/null
#!/bin/sh

# Set the fixed path
BASE_DIR="/rftools/generators/VSG60(Ubuntu22.04x64)_1_0_19"
APPNAME="vsg60"

# Set up the environment variables
LD_LIBRARY_PATH="$BASE_DIR/lib"
export LD_LIBRARY_PATH
export QT_PLUGIN_PATH="$BASE_DIR/plugins"

# Execute the binary
"$BASE_DIR/bin/$APPNAME" "$@"
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
    arch=`uname -i`
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
    installfromnet "wget https://github.com/PentHertz/rfswift_harogic_install/releases/download/v0.55.64/$prog.zip"
    unzip "$prog.zip"
    rm "$prog.zip"
    cd "$prog"
    currentpath=$(pwd)
    mkdir -p /root/Desktop
    mkdir -p /home/root/Desktop/
    sed -i 's/actual_user=$(logname)/actual_user="root"/g' install.sh
    sed -i 's/$SUDO_USER/root/g' install.sh
    ./install.sh
    cp SAStudio4.desktop /root/Desktop/
    case "$arch" in
        aarch64|unknown) 
            ln -s /usr/lib/aarch64-linux-gnu/libffi.so.8 /usr/lib/libffi.so.6;;
    esac
    ln -s /usr/local/bin/sastudio/.sastudio.sh /usr/sbin/sastudio
    goodecho "[+] Installing htraapi"
    installfromnet "wget https://github.com/PentHertz/rfswift_harogic_install/releases/download/v0.55.64/Install_HTRA_SDK.zip"
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