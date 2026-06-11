#!/bin/bash

function canutils_soft_install() {
	goodecho "[+] Installing can-utils"
	installfromnet "apt-fast -y install can-utils"
}

function cantact_soft_install() {
	goodecho "[+] Installing cantact dependencies"
	installfromnet "apt-fast -y install cargo"
	goodecho "[+] Installing cantact"
	installfromnet "cargo install cantact"
}

function caringcaribou_soft_install() {
	goodecho "[+] Cloning and installing caringcaribou"
	[ -d /root/thirdparty ] || mkdir /root/thirdparty
	cd /root/thirdparty
	installfromnet "git clone https://github.com/CaringCaribou/caringcaribou.git"
	cd caringcaribou
	python3 setup.py install
}

function savvycan_soft_install() {
	goodecho "[+] Cloning and installing SavvyCAN"
	# Qt5 serialbus is gone in Ubuntu 26.04 — SavvyCAN now builds against Qt6
	install_dependencies "qmake6 qt6-base-dev qt6-declarative-dev qt6-serialport-dev qt6-serialbus-dev qt6-tools-dev libqt6serialbus6-plugins"
	[ -d /automotive ] || mkdir /automotive
	cd /automotive
	installfromnet "git clone https://github.com/collin80/SavvyCAN.git"
	cd SavvyCAN
	# Qt 6.10 removed QSerialPort::{Parity,Framing,BreakCondition}Error and QChar(uchar);
	# upstream master still uses them (PR removing the enums was closed unmerged)
	sed -i '/case QSerialPort::ParityError:/,/break;/d; /case QSerialPort::FramingError:/,/break;/d; /case QSerialPort::BreakConditionError:/,/break;/d' connections/lawicel_serial.cpp
	sed -i 's/mBuildLine.append(c);/mBuildLine.append(QChar(c));/' connections/lawicel_serial.cpp
	sed -i 's/std::min(frame.payload().length(), 8)/std::min<qsizetype>(frame.payload().length(), 8)/' canframemodel.cpp
	sed -i -e 's/#include <QRegExp>/#include <QRegularExpression>/' \
		-e 's/QRegExp re(/QRegularExpression re(/' \
		-e 's/if (re.indexIn(file) != -1) {/QRegularExpressionMatch rem = re.match(file);\n        if (rem.hasMatch()) {/' \
		-e 's/codes << re.cap(1);/codes << rem.captured(1);/' mainsettingsdialog.cpp
	sed -i 's/maxCount = std::max(maxCount, graph.x.count());/maxCount = std::max<qsizetype>(maxCount, graph.x.count());/' re/graphingwindow.cpp
	qmake6 -makefile
	make -j$(nproc)
	ln -s SavvyCAN /usr/bin/SavvyCAN
}

function gallia_soft_install() { #TODO: not valid yet on RISCV64
	goodecho "[+] Installing Gallia"
	if [[ "$ARCH" == "x86_64" ]] || [[ "$ARCH" == "amd64" ]] || [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
		pip3install "gallia"
	fi
}

function v2ginjector_soft_install() {
	goodecho "[+] Installing V2G Injector"
	[ -d /automotive ] || mkdir /automotive
	cd /automotive
	installfromnet "git clone https://github.com/FlUxIuS/V2GInjector.git"
	cd V2GInjector
	chmod +x install.sh
	./install.sh
}

### TODO: more More!
