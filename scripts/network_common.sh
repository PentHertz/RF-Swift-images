#!/bin/bash

function nmap_soft_install() {
	goodecho "[+] Installing Nmap from package manager"
	install_dependencies "nmap"
}

function wireshark_soft_install() {
	goodecho "[+] Installing Wireshark from package manager"
	install_dependencies "wireshark"
}

function metasploit_soft_install() {
	goodecho "[+] Installing Metasploit from package manager"
	install_dependencies "metasploit"
}

function tshark_soft_install() {
	goodecho "[+] Installing TShark from package manager"
	install_dependencies "metasploit"
}

function tshark_soft_install() {
	goodecho "[+] Installing Impacket from package manager"
	install_dependencies "python3-impacket"
}

function autorecon_soft_install() {
	goodecho "[+] Installing Autorecon from GitHub with PIP"
	pip3install git+https://github.com/Tib3rius/AutoRecon.git
}

function responder_soft_install() {
	goodecho "[+] Installing Autorecon from GitHub"
	[ -d /opt/network ] || mkdir -p /opt/network
	cd /opt/network
	gitinstall "https://github.com/lgandx/Responder.git" "responder_soft_install"
	cd Sniffle/python_cli
	pip3install -r requirements.txt
}

function kismet_soft_install() {
	goodecho "[+] Installing Kismet dependencies"
	[ -d /rftools ] || mkdir -p /rftools
	cd /rftools
	check_and_install_lib "librtlsdr-dev librtlsdr0" "librtlsdr"
	install_dependencies "libsqlite3-dev ubertooth libprelude-dev build-essential git libwebsockets-dev pkg-config zlib1g-dev libnl-3-dev libnl-genl-3-dev libcap-dev libpcap-dev libnm-dev libdw-dev libsqlite3-dev libprotobuf-dev libprotobuf-c-dev protobuf-compiler protobuf-c-compiler libsensors-dev libusb-1.0-0-dev python3 python3-setuptools python3-protobuf python3-requests python3-numpy python3-serial python3-usb python3-dev python3-websockets libubertooth-dev libbtbb-dev libmosquitto-dev"
	goodecho "[+] Installing Kismet"
	installfromnet "git clone https://www.kismetwireless.net/git/kismet.git"
	cd kismet
	./configure --enable-bladerf --enable-wifi-coconut --enable-btgeiger --enable-prelude --enable-python-tools
	make
	make -j$(nproc)
	make suidinstall
	make forceconfigs
	make install
}

function bettercap_soft_install() {
	goodecho "[+] Installing bettercap"
	rm -rf ~/.cache/go-build #TODO: trying to solve build exit for ARM on GitHub
	export GOPROXY=direct
	install_dependencies "libnetfilter-queue-dev"
	[ -d /rftools/bluetooth ] || mkdir -p /rftools/bluetooth
	cd /rftools/bluetooth
	gitinstall "https://github.com/bettercap/bettercap.git"
	cd bettercap
	make build
	make install
	ln -s /rftools/bluetoot/bettercap/bettercap /usr/bin/bettercap
}