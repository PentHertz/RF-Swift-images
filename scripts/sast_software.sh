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

        installfromnet "wget -c https://apt.llvm.org/llvm.sh"

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
    curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo -H gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/scalasbt-release.gpg --import
    sudo chmod 644 /etc/apt/trusted.gpg.d/scalasbt-release.gpg
    sudo apt-get update
    install_dependencies "sbt"


    [ -d /sast ] || mkdir -p /sast
    cd /sast

    gitinstall "https://github.com/FlUxIuS/joern.git"
    cd joern
    sbt stage
    ln -sf $(pwd)/joern /usr/local/bin/joern
    ln -sf $(pwd)/joern-cli /usr/local/bin/joern-cli
    ln -sf $(pwd)/joern-export /usr/local/bin/joern-export
    ln -sf $(pwd)/joern-flow /usr/local/bin/joern-flow
    ln -sf $(pwd)/joern-parse /usr/local/bin/joern-parse
    ln -sf $(pwd)/joern-scan /usr/local/bin/joern-scan
    ln -sf $(pwd)/joern-slice /usr/local/bin/joern-slice
    ln -sf $(pwd)/joern-vectors /usr/local/bin/joern-vectors
    ln -sf $(pwd)/c2cpg.sh /usr/local/bin/c2cpg.sh
    ln -sf $(pwd)/c2cpg.sh /usr/local/bin/c2cpg 
}
