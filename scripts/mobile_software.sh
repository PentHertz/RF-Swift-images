#!/bin/bash
#
# Mobile / Android tooling for RF-Swift.
# Uses RF-Swift helpers (install_dependencies / pip3install / gitinstall) with
# best-effort build reporting. Reliable sources are chosen where upstreams have
# gone dead (e.g. the BitBucket smali jar; the Ubuntu `smali` package is used).

MOBILE_DIR="/mobile"

function mobile_apt_tools_install() {
    goodecho "[+] Installing Android/mobile APT tooling"
    # adb/fastboot, APK (un)packers + signers, smali/baksmali, scrcpy, and a JRE
    # for the jar-based tools (dex2jar, apktool).
    install_dependencies "android-tools-adb android-tools-fastboot apktool apksigner zipalign dexdump smali scrcpy default-jre unzip"
}

function dex2jar_soft_install() {
    goodecho "[+] Installing dex2jar"
    [ -d "$MOBILE_DIR" ] || mkdir -p "$MOBILE_DIR"
    cd "$MOBILE_DIR"
    installfromnet "wget" "-O" "dex-tools.zip" "https://github.com/pxb1988/dex2jar/releases/download/v2.4/dex-tools-v2.4.zip"
    if [ -f dex-tools.zip ]; then
        unzip -o dex-tools.zip && rm -f dex-tools.zip
        chmod +x "$MOBILE_DIR"/dex-tools-v2.4/*.sh 2>/dev/null
        for f in "$MOBILE_DIR"/dex-tools-v2.4/*.sh; do
            [ -f "$f" ] && ln -sf "$f" "/usr/local/bin/$(basename "$f" .sh)"
        done
    else
        record_build_failure "download" "dex2jar" "release zip download failed"
    fi
}

function frida_soft_install() {
    goodecho "[+] Installing frida-tools"
    pip3install "frida-tools"
}

function objection_soft_install() {
    goodecho "[+] Installing objection"
    pip3install "git+https://github.com/sensepost/objection"
}

function androguard_soft_install() {
    goodecho "[+] Installing androguard"
    pip3install "git+https://github.com/androguard/androguard"
}

function drozer_soft_install() {
    # drozer (ReversecLabs) Android security assessment framework.
    goodecho "[+] Installing drozer"
    pip3install "drozer"
}

function mobsf_soft_install() {
    goodecho "[+] Installing Mobile Security Framework (MobSF)"
    # On resolute libxmlsec1 was renamed (libxmlsec1-1 + the openssl engine).
    install_dependencies "libxmlsec1-1 libxmlsec1-openssl1 libxmlsec1-dev"
    # wkhtmltopdf was removed from Ubuntu; install the upstream static build
    # best-effort (used only for MobSF PDF report export; MobSF runs without it).
    local _wk_arch
    case "$(dpkg --print-architecture)" in
        amd64) _wk_arch="amd64" ;;
        arm64) _wk_arch="arm64" ;;
        *)     _wk_arch="" ;;
    esac
    if [ -n "$_wk_arch" ]; then
        installfromnet "wget" "-O" "/tmp/wkhtmltox.deb" "https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_${_wk_arch}.deb"
        if [ -f /tmp/wkhtmltox.deb ]; then
            apt-get install -y /tmp/wkhtmltox.deb \
                || record_build_failure "apt" "wkhtmltox" "upstream deb install failed (PDF export unavailable)"
            rm -f /tmp/wkhtmltox.deb
        else
            record_build_failure "download" "wkhtmltox" "download failed (PDF export unavailable)"
        fi
    else
        record_build_failure "apt" "wkhtmltopdf" "removed from Ubuntu; no upstream deb for this arch (PDF export unavailable)"
    fi
    [ -d "$MOBILE_DIR" ] || mkdir -p "$MOBILE_DIR"
    cd "$MOBILE_DIR"
    gitinstall "https://github.com/MobSF/Mobile-Security-Framework-MobSF.git" "mobsf_soft_install"
    if [ ! -d Mobile-Security-Framework-MobSF ]; then
        record_build_failure "git" "MobSF" "clone failed"
        return 1
    fi
    cd Mobile-Security-Framework-MobSF
    # MobSF only supports Python 3.12-3.13 (setup.sh hard-fails on anything
    # else) and drives install + runtime through `python3 -m poetry`, so expose
    # a uv-provisioned 3.12 as `python3` for both.
    if ! command -v uv >/dev/null 2>&1; then
        record_build_failure "build" "MobSF" "uv not available to provision Python 3.12"
        return 1
    fi
    uv python install 3.12
    local mobsf_py
    mobsf_py="$(uv python find 3.12)"
    if [ -z "$mobsf_py" ]; then
        record_build_failure "build" "MobSF" "uv could not provision Python 3.12"
        return 1
    fi
    mkdir -p "$MOBILE_DIR/.mobsf-python"
    ln -sf "$mobsf_py" "$MOBILE_DIR/.mobsf-python/python3"
    ln -sf "$mobsf_py" "$MOBILE_DIR/.mobsf-python/python"
    if [ -f ./setup.sh ]; then
        PATH="$MOBILE_DIR/.mobsf-python:$PATH" bash ./setup.sh \
            || record_build_failure "build" "MobSF" "setup.sh reported errors"
        cat > /usr/bin/mobsf <<EOF
#!/bin/bash
export PATH="$MOBILE_DIR/.mobsf-python:\$PATH"
cd "$MOBILE_DIR/Mobile-Security-Framework-MobSF"
exec bash ./run.sh "\$@"
EOF
        chmod +x /usr/bin/mobsf
    else
        record_build_failure "build" "MobSF" "setup.sh not found"
    fi
}
