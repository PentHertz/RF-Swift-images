#!/bin/env bash

# Adapted from (tested on ubuntu 22.04):
# https://github.com/20urc3/Talks/tree/main/leHack

# set -euo pipefail // -> some scripts fails to install properly, and binaries are normally working. TODO: Need see why some install processes are failing with it.


function LLVM_install() { # expects llvm version TODO: not available on RISCV64 yet
    if [[ "$ARCH" == "x86_64" ]] || [[ "$ARCH" == "amd64" ]] || [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        LLVM_VERSION=17

        goodecho "[+] installing LLVM ${LLVM_VERSION}"

        [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
        cd /root/thirdparty

        installfromnet "wget" "-c" "https://apt.llvm.org/llvm.sh"

        chmod +x llvm.sh
        ./llvm.sh ${LLVM_VERSION}

        export LLVM_CONFIG=llvm-config-${LLVM_VERSION}
        echo "Defaults env_keep += \"${LLVM_CONFIG}\"" | sudo EDITOR='tee -a' visudo
    fi
}

function semgrep_install() {
    goodecho "[+] installing AFL deps"
    pip3install "semgrep"
}

function cppcheck_install() {
    goodecho "[+] installing cppcheck"
    install_dependencies "cppcheck"
}

function AFL_install() {
    goodecho "[+] installing AFL++"
    install_dependencies "clang build-essential afl++"
}

function honggfuzz_install() {
    goodecho "[+] Checking system architecture..."
    ARCH=$(uname -m)
    if [ "$ARCH" = "riscv64" ]; then
        criticalecho-noexit "[-] honggfuzz: -mtune=native unsupported under QEMU RISC-V64, skipping"
        return 0
    fi
    if [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]]; then
        criticalecho-noexit "[-] Unsupported architecture: $ARCH"
        criticalecho-noexit "    Honggfuzz installation is supported only on arm64/aarch64 or amd64."
        return 0
    fi
    goodecho "[+] Architecture $ARCH supported. Proceeding with installation."
    goodecho "[+] Installing honggfuzz"
    install_dependencies "binutils-dev libunwind-dev libblocksruntime-dev git"
    [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    cd /root/thirdparty
    git clone https://github.com/google/honggfuzz
    cd honggfuzz && make && make install
}

function clang_static_analyzer_install() {
    echo "[+] installing clang-static-analyzer"
    install_dependencies "clang clang-tools"
}

function joernsast_install() {
    echo "[+] Installing Joern"
    install_dependencies "apt-transport-https curl gnupg"
    echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo tee /etc/apt/sources.list.d/sbt.list
    echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt_old.list

    # Fetch ASCII-armored key, dearmor to binary, write directly to trusted keyring
    curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" \
        | gpg --dearmor \
        | sudo tee /etc/apt/trusted.gpg.d/scalasbt-release.gpg > /dev/null
    sudo chmod 644 /etc/apt/trusted.gpg.d/scalasbt-release.gpg

    sudo apt-get update
    install_dependencies "sbt"
    [ -d /sast ] || mkdir -p /sast
    cd /sast
    gitinstall "https://github.com/FlUxIuS/joern.git"
    cd joern
    sbt stage
    for bin in joern joern-cli joern-export joern-flow joern-parse joern-scan joern-slice joern-vectors c2cpg.sh; do
        ln -sf $(pwd)/${bin} /usr/local/bin/${bin}
    done
    ln -sf $(pwd)/c2cpg.sh /usr/local/bin/c2cpg
}

function trivy_install() {
    # Trivy: vulnerability / misconfig / secret / SBOM scanner for container
    # images, filesystems and repos -- used here to triage extracted firmware
    # and dependency trees during reversing.
    goodecho "[+] Installing Trivy"

    local arch asset
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)  asset="Linux-64bit" ;;
        aarch64|arm64) asset="Linux-ARM64" ;;
        *)             asset="" ;;
    esac

    # Prefer the upstream install script (fetches the prebuilt release binary for
    # the detected arch into /usr/local/bin, tracking the latest release).
    if [ -n "$asset" ]; then
        installfromnet "curl" "-sfL" "https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh" "-o" "/tmp/trivy-install.sh"
        if [ -s /tmp/trivy-install.sh ]; then
            sh /tmp/trivy-install.sh -b /usr/local/bin
            rm -f /tmp/trivy-install.sh
        fi
        if command -v trivy >/dev/null 2>&1; then
            goodecho "[+] Trivy installed: $(command -v trivy)"
            return 0
        fi
        record_build_failure "download" "trivy" "install script failed; falling back to go install"
    fi

    # No prebuilt binary for this arch (e.g. riscv64) or the download failed:
    # build from source with the Go toolchain from corebuild's install_go.
    if command -v go >/dev/null 2>&1; then
        GOBIN=/usr/local/bin go install github.com/aquasecurity/trivy/cmd/trivy@latest \
            || record_build_failure "build" "trivy" "go install failed"
    else
        record_build_failure "build" "trivy" "no prebuilt binary for $arch and go unavailable"
    fi
}

function sighthound_install() {
    # Sighthound: tree-sitter based static vulnerability scanner (pattern +
    # source->sink taint flow) over Python/JS/TS/Java/PHP/C#/Go/Ruby, with
    # text/JSON/CSV/SARIF output. Complements semgrep in the reversing SAST set.
    # Not published on crates.io and ships no release binaries -> build from git
    # with the rustup toolchain from corebuild's rust_tools (needs Rust 1.85+).
    goodecho "[+] Installing Sighthound"
    if ! command -v cargo >/dev/null 2>&1; then
        record_build_failure "build" "sighthound" "cargo toolchain unavailable"
        return 0
    fi
    local repo="https://github.com/Corgea/Sighthound.git"
    # Prefer the pinned Cargo.lock for a reproducible build; retry unlocked if the
    # lockfile can't resolve against the installed toolchain.
    cargo install --git "$repo" --bin sighthound --root /usr/local --locked \
        || cargo install --git "$repo" --bin sighthound --root /usr/local \
        || record_build_failure "build" "sighthound" "cargo install --git failed"
}
