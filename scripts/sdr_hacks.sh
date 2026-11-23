#!/bin/bash
#
# sdr_hacks: hardware that was never meant to be an SDR, repurposed as one
# (MediaTek Wi-Fi dongles and routers, LoRa transceivers, ESP32 radios), and alternative
# firmware that turns an SDR into a dedicated tool (AntSDR E200/E310 FPV scanner).
# Built on top of sdr_light. Host-side tools are installed; device firmware is
# either prebuilt (downloaded) or kept as sources under /rftools/sdr.

# Configure + build a CMake project in $PWD. Upstreams build with -Werror and
# were not tested with GCC 15, so on failure retry once without -Werror
# (CMakeLists.txt is restored afterwards so `git pull` stays clean).
function _sdrhacks_cmake_build() {
    rm -rf build
    if cmake -S . -B build "$@" && cmake --build build -j"$(nproc)"; then
        return 0
    fi
    criticalecho-noexit "[!] strict build failed in $(pwd), retrying without -Werror"
    rm -rf build
    sed -i -E 's/[[:space:]]-Werror([[:space:])])/\1/g' CMakeLists.txt
    local rc=0
    { cmake -S . -B build "$@" && cmake --build build -j"$(nproc)"; } || rc=1
    git checkout -- CMakeLists.txt 2>/dev/null || true
    return "$rc"
}

# /usr/local/bin/<name> wrapper for a repo Python script (repo files are 0644)
function _sdrhacks_pywrap() {
    printf '#!/bin/sh\nexec python3 %s "$@"\n' "$2" > "/usr/local/bin/$1"
    chmod 755 "/usr/local/bin/$1"
}

function sdrhacks_common_tools_install() {
    goodecho "[+] Installing flashing/console tools for sdr_hacks"
    install_dependencies "python3-serial picocom tio unzip curl"
    pipx_install_tool "esptool" "esptool" "esptool"
    local b
    for b in espefuse espsecure esp_rfc2217_server esptool.py espefuse.py espsecure.py; do
        if [ -e "/root/.local/bin/$b" ]; then ln -sf "/root/.local/bin/$b" "/usr/local/bin/$b"; fi
    done
    return 0
}

function birriasdr_sdrhacks_install() {
    goodecho "[+] Installing BirriaSDR (MT7921AU/MT7961 USB Wi-Fi dongle as 40 MSps I/Q receiver)"
    install_dependencies "build-essential cmake pkg-config libusb-1.0-0-dev"
    [ -d /rftools/sdr ] || mkdir -p /rftools/sdr
    cd /rftools/sdr
    gitinstall "https://github.com/luigifcruz/BirriaSDR.git" "birriasdr_sdrhacks_install" || return 0
    cd /rftools/sdr/BirriaSDR
    # Upstream only requests c_std_11 (GCC 15 would use gnu23) and builds with -Werror.
    # The NDS32 RAM program is prebuilt in src/chips/mt7921_image.h (no toolchain needed).
    if _sdrhacks_cmake_build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
            -DCMAKE_C_STANDARD=17 -DCMAKE_INSTALL_PREFIX=/usr/local \
        && cmake --install build && ldconfig; then
        goodecho "[+] BirriaSDR installed: birria_rx, libbirriasdr, birriasdr.pc"
    else
        record_build_failure "build" "BirriaSDR" "cmake build/install failed"
    fi
    rm -rf build
    cat > /etc/udev/rules.d/99-birriasdr.rules <<'EOF'
# BirriaSDR: COMFAST MT7961 dongle and generic MediaTek MT7961 ID.
# The host must not bind mt7921u to it (modprobe -r mt7921u / blacklist, then replug).
SUBSYSTEM=="usb", ATTRS{idVendor}=="3574", ATTRS{idProduct}=="6211", MODE="0666"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0e8d", ATTRS{idProduct}=="7961", MODE="0666"
EOF
    return 0
}

function lr2021sdr_sdrhacks_install() {
    goodecho "[+] Installing LR2021-SDR host library/tools and ESP32-P4 capture firmware"
    install_dependencies "build-essential cmake python3-numpy python3-matplotlib python3-serial picocom tio unzip curl"
    [ -d /rftools/sdr ] || mkdir -p /rftools/sdr
    cd /rftools/sdr
    gitinstall "https://github.com/SAMS0N1TE/lr2021-sdr.git" "lr2021sdr_sdrhacks_install" || return 0
    cd /rftools/sdr/lr2021-sdr
    # research/ is ~88 MB of sample captures: keep it out of the image checkout
    git sparse-checkout set --no-cone '/*' '!/research/' 2>/dev/null || true
    if _sdrhacks_cmake_build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX=/usr/local \
        && cmake --install build; then
        goodecho "[+] LR2021-SDR installed: lriq_tool, lr2021_lab, liblriq, liblr2021_iq"
    else
        record_build_failure "build" "lr2021-sdr" "cmake build/install failed"
    fi
    rm -rf build
    local t
    for t in lr2021_make_p25 lr2021_make_temperature lr2021_make_apsk lr2021_tx_upload \
             lr2021_decode_p25_capture lr2021_decode_temperature_capture; do
        _sdrhacks_pywrap "$t" "/rftools/sdr/lr2021-sdr/tools/$t.py"
    done
    # Prebuilt ESP32-P4 firmware (GitHub pre-release). Flash with:
    # esptool --chip esp32p4 --port /dev/ttyACM0 write-flash 0x2000 bootloader.bin \
    #   0x8000 partition-table.bin 0x10000 lr2021_capture.bin
    local fwver="v0.3.0" fwdir=/rftools/sdr/lr2021-sdr-firmware
    mkdir -p "$fwdir/$fwver"
    if installfromnet curl -fsSL -o "$fwdir/lr2021-sdr-esp32p4-$fwver.zip" \
        "https://github.com/SAMS0N1TE/lr2021-sdr/releases/download/$fwver/lr2021-sdr-esp32p4.zip"; then
        unzip -oq "$fwdir/lr2021-sdr-esp32p4-$fwver.zip" -d "$fwdir/$fwver" \
            || record_build_failure "other" "lr2021-sdr firmware" "unzip $fwver failed"
    else
        record_build_failure "net" "lr2021-sdr firmware" "download $fwver failed"
    fi
    return 0
}

function espsdr_sdrhacks_install() {
    goodecho "[+] Installing ESP-SDR sources, prebuilt firmware set and esp-sdr-bridge"
    install_dependencies "python3-numpy python3-serial curl"
    [ -d /rftools/sdr ] || mkdir -p /rftools/sdr
    cd /rftools/sdr
    # ESP-IDF project pinned to IDF master commits (firmware-targets.json): users
    # build it with espressif/idf; the image ships the official prebuilt set below.
    gitinstall "https://github.com/ESPARGOS/esp-sdr.git" "espsdr_sdrhacks_install" || true
    local fw=/rftools/sdr/esp-sdr-firmware
    mkdir -p "$fw"
    cat > "$fw/fetch_firmware.py" <<'EOF'
#!/usr/bin/env python3
"""Mirror the ESP-SDR prebuilt firmware (official web flasher) and write esptool flash scripts.
Usage: fetch_firmware.py OUTDIR   (re-run to refresh; base URL via ESPSDR_FW_BASE)"""
import hashlib, json, os, sys, urllib.request
BASE = os.environ.get("ESPSDR_FW_BASE", "https://espargos.net/espsdr/app/firmware")
out = sys.argv[1] if len(sys.argv) > 1 else "."
def get(url):
    # espargos.net answers 403 to Python's default User-Agent
    req = urllib.request.Request(url, headers={"User-Agent": "rfswift-espsdr-fetch/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read()
manifest = json.loads(get(BASE + "/manifest.json"))
for vid, v in manifest["variants"].items():
    d = os.path.join(out, vid)
    os.makedirs(d, exist_ok=True)
    args = []
    for p in v["parts"]:
        data = get(f"{BASE}/{vid}/{p['name']}")
        if hashlib.sha256(data).hexdigest() != p["sha256"]:
            raise SystemExit(f"sha256 mismatch: {vid}/{p['name']}")
        with open(os.path.join(d, p["name"]), "wb") as f:
            f.write(data)
        args += [hex(p["offset"]), p["name"]]
    fs, ea = v["flash_settings"], v["esptool_args"]
    script = os.path.join(d, "flash.sh")
    with open(script, "w") as f:
        f.write("#!/bin/sh\n# " + v.get("label", vid) + "\n# usage: ./flash.sh [/dev/ttyACM0]\n"
                'cd "$(dirname "$0")"\n'
                f'exec esptool --chip {ea["chip"]} --port "${{1:-/dev/ttyACM0}}" '
                f'--before {ea["before"]} --after {ea["after"]} write-flash '
                f'-fm {fs["flash_mode"]} -fs {fs["flash_size"]} -ff {fs["flash_freq"]} '
                + " ".join(args) + "\n")
    os.chmod(script, 0o755)
    print(f"{vid}: {v.get('label')} @ {v.get('version', '?')[:12]}")
with open(os.path.join(out, "manifest.json"), "w") as f:
    json.dump(manifest, f, indent=1)
EOF
    python3 -I "$fw/fetch_firmware.py" "$fw" \
        || record_build_failure "net" "esp-sdr firmware" "prebuilt firmware mirror failed"
    # esp-sdr-bridge (linked from the esp-sdr docs): SpyServer (5555) / rtl_tcp (1234)
    # server for the ESP32-S3 continuous IQ stream, plus its matching S3 firmware
    pipx_install_tool "esp-sdr-bridge" "git+https://github.com/z2labs/esp-sdr-bridge.git@v0.1.0" "esp-sdr-bridge"
    installfromnet curl -fsSL -o "$fw/esp-sdr-s3-iq-stream-bridge-v0.1.0.bin" \
        "https://github.com/z2labs/esp-sdr-bridge/releases/download/v0.1.0/esp-sdr-s3-iq-stream.bin" \
        || record_build_failure "net" "esp-sdr-bridge firmware" "download failed"
    if [ -d /rftools/sdr/esp-sdr/tools ]; then
        _sdrhacks_pywrap espsdr_s3_ring /rftools/sdr/esp-sdr/tools/s3_ring.py
        _sdrhacks_pywrap espsdr_check_spectrum /rftools/sdr/esp-sdr/tools/check_spectrum.py
    fi
    return 0
}

function soapyespsdr_sdrhacks_install() {
    goodecho "[+] Installing SoapyESPSDR (ESP32-S31 streaming firmware as a SoapySDR device)"
    # libcurl4-gnutls-dev (corebuild) satisfies find_package(CURL); upstream's
    # libcurl4-openssl-dev would conflict with it.
    install_dependencies "build-essential cmake pkg-config libsoapysdr-dev soapysdr-tools libcurl4-gnutls-dev libjsoncpp-dev libusb-1.0-0-dev"
    [ -d /rftools/sdr/oot ] || mkdir -p /rftools/sdr/oot
    cd /rftools/sdr/oot
    gitinstall "https://github.com/ESPARGOS/SoapyESPSDR.git" "soapyespsdr_sdrhacks_install" || return 0
    cd /rftools/sdr/oot/SoapyESPSDR
    rm -rf build
    if cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX=/usr/local \
        && cmake --build build -j"$(nproc)" && cmake --install build; then
        goodecho "[+] SoapyESPSDR installed (driver=espsdr, espsdr_loss_monitor)"
    else
        record_build_failure "build" "SoapyESPSDR" "cmake build/install failed"
    fi
    rm -rf build
    cat > /etc/udev/rules.d/70-espsdr.rules <<'EOF'
SUBSYSTEM=="usb", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="4531", MODE="0660", TAG+="uaccess"
EOF
    return 0
}

function w1700ksdr_sdrhacks_install() {
    goodecho "[+] Installing W1700K SDR host tools and MT7996 firmware (Gemtek W1700K router)"
    install_dependencies "build-essential libfftw3-dev zlib1g-dev openssl clang lld llvm openssh-client python3-serial"
    [ -d /rftools/sdr ] || mkdir -p /rftools/sdr
    cd /rftools/sdr
    gitinstall "https://github.com/h0m3us3r/w1700k-sdr.git" "w1700ksdr_sdrhacks_install" || return 0
    cd /rftools/sdr/w1700k-sdr
    # Portable build (upstream suggests -march=native) and no -Werror for GCC 15
    local d
    for d in stream spectrum recv; do
        if make -C "host/$d" clean && make -C "host/$d" -j"$(nproc)" WARNINGS="-Wall -Wextra" \
            && make -C "host/$d" install PREFIX=/usr/local WARNINGS="-Wall -Wextra"; then
            goodecho "[+] w1700k host/$d installed"
        else
            record_build_failure "build" "w1700k-sdr host/$d" "make failed"
        fi
    done
    # The MT7996 firmware build calls unversioned ld.lld / llvm-objcopy / llvm-readobj
    local t b
    for t in ld.lld llvm-objcopy llvm-readobj; do
        if ! command -v "$t" > /dev/null 2>&1; then
            b=$(ls -1 /usr/lib/llvm-*/bin/"$t" 2>/dev/null | sort -V | tail -n1)
            if [ -n "$b" ]; then ln -sf "$b" "/usr/local/bin/$t"; fi
        fi
    done
    # The host CLI reads firmware/build/firmware.json, so build the firmware here
    if make -C firmware clean && make -C firmware; then
        goodecho "[+] MT7996 firmware built in /rftools/sdr/w1700k-sdr/firmware/build"
    else
        record_build_failure "build" "w1700k-sdr firmware" "make -C firmware failed (clang/lld/llvm/openssl)"
    fi
    # Host CLI (stdlib Python, drives the router over ssh). The router OS itself
    # (root `make`: Buildroot/Linux/U-Boot, ~500 MB of downloads) is not built here.
    _sdrhacks_pywrap w1700k /rftools/sdr/w1700k-sdr/host/bin/w1700k
    return 0
}

function mtk79icap_sdrhacks_install() {
    goodecho "[+] Installing Mtk79ICAP (MT7921AU/MT7961 USB Wi-Fi stick as SoapySDR I/Q source)"
    install_dependencies "build-essential cmake libsoapysdr-dev soapysdr-tools python3 zstd iw iproute2"
    [ -d /rftools/sdr ] || mkdir -p /rftools/sdr
    cd /rftools/sdr
    gitinstall "https://github.com/MtkWifiRev/Mtk79ICAP.git" "mtk79icap_sdrhacks_install" || return 0
    cd /rftools/sdr/Mtk79ICAP
    # Userspace only: libmt7921iq + mt7921iq_rx + SoapySDR module (driver=mt7921).
    # libmt7921iq includes driver/mt7921/iqstream_ioctl.h, so keep the full checkout.
    # The kernel modules (driver/) and the patched firmware must be built on the HOST.
    rm -rf build-soapy
    if cmake -S userspace/SoapyMT7921 -B build-soapy -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local \
        && cmake --build build-soapy -j"$(nproc)" \
        && cmake --install build-soapy && ldconfig; then
        goodecho "[+] SoapyMT7921 module and mt7921iq_rx installed"
    else
        record_build_failure "build" "Mtk79ICAP" "SoapyMT7921/libmt7921iq cmake build failed"
    fi
    rm -rf build-soapy
    cat > /usr/local/bin/mt7961-iq-fw-v65 <<'EOF'
#!/bin/sh
# Builds the patched WIFI_RAM_CODE_MT7961_1.bin from the stock linux-firmware
# build 20260224110949; install the output on the HOST in /lib/firmware/mediatek/.
exec python3 /rftools/sdr/Mtk79ICAP/firmware/mt7961-iq-fw-v65.py "$@"
EOF
    cat > /usr/local/bin/mt7921iq-setup <<'EOF'
#!/bin/sh
# Needs root, the host network namespace and the fork driver loaded on the host.
exec sh /rftools/sdr/Mtk79ICAP/userspace/mt7921iq-setup.sh "$@"
EOF
    chmod +x /usr/local/bin/mt7961-iq-fw-v65 /usr/local/bin/mt7921iq-setup
    if [ -f userspace/udev/99-mt7921-iq.rules ]; then
        cp userspace/udev/99-mt7921-iq.rules /etc/udev/rules.d/ || true
    fi
    return 0
}

# fpv_capture (black-pigeon): analog FPV scanner firmware for the AntSDR E200 and E310. The board
# scans for PAL/NTSC video, shows it in its own web UI (http://192.168.1.10) and streams frames to
# the host. Building the firmware needs Vivado/Vitis 2022.2, which the image does not ship, so the
# image stages the release boot files for the SD card and installs the host tools:
#   fpv-receive        records the board's frame stream (BMP + JSON metadata) per frequency
#   u220-fpv-tx        PAL/NTSC test transmitter for a MicroPhase U220 (UHD); --dry-run by default
#   u220-fpv-gui       Tk front end for it; u220-fpv-generate makes the test signals
# Host tools track master; FPVCAPTURE_REVIEWED_COMMIT is the last commit reviewed, and a newer one
# adds a "review" entry to the build report. The boot files are pinned to a release by SHA-256.
# Upstream has no licence file yet (only the kernel driver carries GPL-2.0).
FPVCAPTURE_REVIEWED_COMMIT="5b0318bc99cdda4a1cf5314b3dd3d33f43c477aa"   # reviewed 2026-11-23
FPVCAPTURE_RELEASE="v0.1"
FPVCAPTURE_BOOTFILES=(
    "e200 e200-fpv-spectrum-ui-20261120-bootfiles.tar.gz 45d88a8dc51883e38eb4b19caaf664d006819aebeb47a50e5ea51284bc226e59"
    "e310 e310-fpv-spectrum-ui-20261120-bootfiles.tar.gz c343133c982d74c72f2c5b4a13541beb8544e03c80ae9c2bb84cf4b45b35761b"
)

function fpvcapture_sdrhacks_install() {
    goodecho "[+] Installing fpv_capture (AntSDR E200/E310 FPV scanner): boot files and host tools"
    install_dependencies "python3-numpy python3-pil python3-tk fonts-dejavu-core libssl-dev pkg-config g++ curl"
    local top="${FPVCAPTURE_DIR:-/rftools/sdr/fpv_capture}" bindir="${FPVCAPTURE_BIN_DIR:-/usr/local/bin}"
    local head spec board file sum latest tmp
    mkdir -p "$(dirname "$top")"
    cd "$(dirname "$top")"
    gitinstall "https://github.com/black-pigeon/fpv_capture.git" "fpvcapture_sdrhacks_install" || true
    if [ ! -f "$top/tools/fpv_receiver/receive.py" ]; then
        record_build_failure "git" "fpv_capture" "clone failed"
        return 0
    fi
    head=$(git -C "$top" rev-parse HEAD 2>/dev/null || true)
    if [ -n "$head" ] && [ "$head" != "$FPVCAPTURE_REVIEWED_COMMIT" ]; then
        record_build_failure "review" "fpv_capture" "built master at ${head:0:12}; last reviewed commit is ${FPVCAPTURE_REVIEWED_COMMIT:0:12}" || true
    fi

    # Boot files, one directory per board: copy its contents to the SD card's FAT32 boot partition.
    # They sit in the checkout, excluded locally so `git status` and pulls stay clean.
    grep -qx '/bootfiles/' "$top/.git/info/exclude" 2>/dev/null || echo '/bootfiles/' >> "$top/.git/info/exclude"
    for spec in "${FPVCAPTURE_BOOTFILES[@]}"; do
        read -r board file sum <<< "$spec"
        tmp=$(mktemp -d)
        rm -rf "$top/bootfiles/$board"
        mkdir -p "$top/bootfiles/$board"
        if installfromnet curl -fsSL -o "$tmp/$file" \
                "https://github.com/black-pigeon/fpv_capture/releases/download/${FPVCAPTURE_RELEASE}/${file}" \
            && echo "$sum  $tmp/$file" | sha256sum -c --quiet - \
            && tar -xzf "$tmp/$file" -C "$top/bootfiles/$board" --no-same-owner \
            && (cd "$top/bootfiles/$board" && sha256sum -c --quiet SHA256SUMS); then
            goodecho "[+] fpv_capture ${FPVCAPTURE_RELEASE} boot files for ${board}: $top/bootfiles/$board"
        else
            rm -rf "$top/bootfiles/$board"
            record_build_failure "net" "fpv_capture boot files" "${board}: download or SHA-256 check failed"
        fi
        rm -rf "$tmp"
    done
    latest=$(github_latest_tag black-pigeon/fpv_capture)
    if [ -n "$latest" ] && [ "$latest" != "$FPVCAPTURE_RELEASE" ]; then
        record_build_failure "review" "fpv_capture boot files" "release ${latest} is out; the image stages ${FPVCAPTURE_RELEASE}" || true
    fi

    # Host receiver: Python standard library only
    mkdir -p "$bindir"
    printf '#!/bin/sh\nexec python3 %s "$@"\n' "$top/tools/fpv_receiver/receive.py" > "$bindir/fpv-receive"
    chmod 755 "$bindir/fpv-receive"

    # U220 test transmitter. build.sh compiles it against UHD, runs its unit tests and --help;
    # it opens no radio. Upstream builds with -Werror: on failure, retry once without it.
    local out="$top/build/u220-fpv-source" src="$top/tools/u220_fpv_tx"
    if ! bash "$src/build.sh" "$out"; then
        criticalecho-noexit "[!] u220_fpv_tx strict build failed, retrying without -Werror"
        sed -i 's/ -Werror//g' "$src/build.sh"
        bash "$src/build.sh" "$out" || record_build_failure "build" "u220_fpv_tx" "build.sh failed"
        git -C "$top" checkout -- tools/u220_fpv_tx/build.sh 2>/dev/null || true
    fi
    if [ -x "$out/u220_fpv_tx" ]; then
        ln -sf "$out/u220_fpv_tx" "$bindir/u220-fpv-tx"
    fi
    printf '#!/bin/sh\nexec python3 %s "$@"\n' "$src/gui.py" > "$bindir/u220-fpv-gui"
    printf '#!/bin/sh\nexec python3 %s "$@"\n' "$src/generate_fpv.py" > "$bindir/u220-fpv-generate"
    chmod 755 "$bindir/u220-fpv-gui" "$bindir/u220-fpv-generate"
    return 0
}
