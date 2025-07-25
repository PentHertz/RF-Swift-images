#!/bin/bash

function yatebts_blade2_soft_install() { # TODO: make few tests with new Nuand libs, if unstable: fetch 3a411c87c2416dc68030d5823d73ebf3f797a145 
	set +e # TODO: debug that function
    set +o pipefail
	goodecho "[+] Feching YateBTS from Nuand for firwmares"
	install_dependencies "qtmultimedia5-dev libqt5multimediawidgets5 libqt5multimedia5-plugins libqt5multimedia5 qttools5-dev qttools5-dev-tools"
	[ -d /telecom/2G ] || mkdir -p /telecom/2G
	cd /telecom/2G
	goodecho "[+] Fetching Yate"
	installfromnet "git clone https://github.com/svedm/yate.git" # TODO: maybe needs to be updated to rc3? 
	cd yate
	./autogen.sh
	./configure --prefix=/usr/local
	make -j$(nproc)
	make install
	ldconfig
	cd ..
	#goodecho "[+] Feching YateBTS"
	#installfromnet "git clone https://github.com/yatevoip/yatebts.git"
	gitinstall "https://github.com/PentHertz/yatebts-rc3-nonoff.git" "yatebts_blade2_soft_install"
	cd yatebts-rc3-nonoff
	rm -R yate
	cd yatebts
	./autogen.sh
	./configure --prefix=/usr/local
	make -j$(nproc)
	make install
	ldconfig
	goodecho "[+] Creating some confs"
	touch /usr/local/etc/yate/snmp_data.conf /usr/local/etc/yate/tmsidata.conf
	# chown root:yate /usr/local/etc/yate/*.conf # TODO: next when dropping root privs
	chmod g+w /usr/local/etc/yate/*.conf
	colorecho "[+] Now it's time for you to configure ;)"
	set -e
    set -o pipefail
}

# TODO: move to QT5
function yatebts_blade2_soft_install_toreview() { # TODO: make few tests with new Nuand libs, if unstable: fetch 3a411c87c2416dc68030d5823d73ebf3f797a145 
	goodecho "[+] Feching YateBTS from Nuand"
	[ -d /root/thirdparty ] || mkdir -p /root/thirdparty
	cd /root/thirdparty
	installfromnet "wget https://nuand.com/downloads/yate-rc-3.tar.gz"
	goodecho "[+] Installing Yate"
	cd yate
	./autogen.sh
	./configure --prefix=/usr/local
	make -j$(nproc)
	make install
	ldconfig
	cd ..
	goodecho "[+] Installing YateBTS"
	cd yatebts
	./autogen.sh
	./configure --prefix=/usr/local
	make -j$(nproc)
	make install
	ldconfig
	goodecho "[+] Creating some confs"
	touch /usr/local/etc/yate/snmp_data.conf /usr/local/etc/yate/tmsidata.conf
	# chown root:yate /usr/local/etc/yate/*.conf # TODO: next when dropping root privs
	chmod g+w /usr/local/etc/yate/*.conf
	colorecho "[+] Now it's time for you to configure ;)"
}

function openbts_uhd_soft_install() {
	# Check architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" ]]; then
        criticalecho-noexit "[-] Unsupported architecture: $ARCH"
        exit 0
    fi
    install_dependencies "libzmq3-dev libsqlite3-dev"
	goodecho "[+] Feching OpenBTS from penthertz"
	[ -d /telecom/2G ] || mkdir -p /telecom/2G
	cd /telecom/2G
	goodecho "[+] Cloninig OpenBTS"
	installfromnet "git clone https://github.com/PentHertz/OpenBTS.git"
	cd OpenBTS
	./preinstall.sh
	./autogen.sh
	./configure --with-uhd
	make -j$(nproc)
	make install
	ldconfig
	ln -s Transceiver52M/transceiver .
}

function openbts_umts_soft_install() {
    local ARCH=$(uname -m)

    case "$ARCH" in
        x86_64|amd64)
            openbts_umts_soft_install_call
            ;;
        i?86)
            openbts_umts_soft_install_call
            ;;
        *)
            criticalecho-noexit "[-] Unsupported architecture: $ARCH. OpenBTS UMTS installation is not supported on this architecture."
            ;;
    esac
}

function openbts_umts_soft_install_call() {
	goodecho "[+] Feching OpenBTS UMTS from penthertz"
	[ -d /telecom/3G ] || mkdir -p /telecom/3G
	cd /telecom/3G
	goodecho "[+] Cloninig OpenBTS UMTS"
	installfromnet "git clone https://github.com/PentHertz/OpenBTS-UMTS.git"
	cd OpenBTS-UMTS
	git submodule init
	git submodule update
	./install_dependences.sh
	./autogen.sh
	./configure
	make
	sudo make install
}

function srsran4G_5GNSA_soft_install() {
	set +e # TODO: debug that function
    set +o pipefail
	goodecho "[+] Installing srsRAN_4G dependencies"
	install_dependencies "build-essential cmake libfftw3-dev libmbedtls-dev libboost-program-options-dev libconfig++-dev libsctp-dev"
	goodecho "[+] Feching srsRAN_4G"
	[ -d /telecom/4G ] || mkdir -p /telecom/4G
	cd /telecom/4G
	goodecho "[+] Cloninig and installing srsRAN 4G"
	installfromnet "git clone https://github.com/srsran/srsRAN_4G.git"
	cd srsRAN_4G
	mkdir build
	cd build
	cmake ../
	make -j$(nproc)
	make install
	#make test
	set -e
    set -o pipefail
}

function srsran5GSA_soft_install() {
	set +e # TODO: debug that function
    set +o pipefail
	goodecho "[+] Installing srsran_project dependencies"
	install_dependencies "cmake make gcc g++ pkg-config libfftw3-dev libmbedtls-dev libsctp-dev libyaml-cpp-dev libgtest-dev"
	goodecho "[+] Feching srsran_project"
	[ -d /telecom/5G ] || mkdir -p /telecom/5G
	cd /telecom/5G
	goodecho "[+] Cloninig and installing srsran_project"
	installfromnet "git clone https://github.com/srsRAN/srsRAN_Project.git"
	cd srsRAN_Project
	mkdir build
	cd build
	cmake ../
	make -j $(nproc)
	make install
	#make test -j $(nproc)
	set -e
    set -o pipefail
}

function Open5GS_soft_install() {
	goodecho "[+] Installing Open5GS dependencies"
	install_dependencies "ca-certificates curl gnupg"
	install_dependencies "meson libmongoc-1.0-0 libmongoc-dev"
	install_dependencies "python3-pip python3-setuptools python3-wheel ninja-build build-essential flex bison git cmake libsctp-dev libgnutls28-dev libgcrypt-dev libssl-dev libidn11-dev libmongoc-dev libbson-dev libyaml-dev libnghttp2-dev libmicrohttpd-dev libcurl4-gnutls-dev libnghttp2-dev libtins-dev libtalloc-dev meson"
	ldconfig
	curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
	echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
	installfromnet "apt-fast -y update"
	install_dependencies "mongodb-org python3-pip python3-setuptools python3-wheel ninja-build build-essential flex bison git cmake libsctp-dev libgnutls28-dev libgcrypt-dev libssl-dev libidn11-dev libmongoc-dev libbson-dev libyaml-dev libnghttp2-dev libmicrohttpd-dev libcurl4-gnutls-dev libnghttp2-dev libtins-dev libtalloc-dev meson"
	goodecho "[+] Feching Open5GS"
	[ -d /telecom/5G ] || mkdir -p /telecom/5G
	cd /telecom/5G
	goodecho "[+] Cloninig and installing Open5GS"
	installfromnet "git clone https://github.com/open5gs/open5gs"
	cd open5gs
	meson build --prefix=`pwd`/install
	ninja -C build
	ln -s $(pwd)/build/tests/app/5gc /usr/bin/Open5Gs_deployall # Making a quick command
	mkdir -p /data/db # making directory for MongoDB
	goodecho "[+] Building Web GUI"
	mkdir -p /etc/apt/keyrings
	curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
	NODE_MAJOR=20
	echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
	installfromnet "apt-fast update"
	install_dependencies "nodejs"
	cd webui
	npm ci
}

function pycrate_soft_install() {
	[ -d /telecom ] || mkdir -p /telecom
	cd /telecom
	goodecho "[+] Cloninig and installing pycrate"
	installfromnet "git clone https://github.com/pycrate-org/pycrate.git"
	cd pycrate
	python3 setup.py install
	goodecho "[+] Installing pycrate further dependencies"
	install_dependencies "libxml2-dev libxslt1-dev"
	pip3install "lxml crc32c crcmod"
}

function cryptomobile_soft_install() {
	[ -d /telecom ] || mkdir -p /telecom
	cd /telecom
	goodecho "[+] Installing cryptomobile's dependencies"
	pip3install "pycryptodome"
	goodecho "[+] Cloninig and installing cryptomobile"
	installfromnet "git clone https://github.com/mitshell/CryptoMobile.git"
	cd CryptoMobile
	pip3install .
}

function pysctp_soft_install() {
	[ -d /telecom ] || mkdir -p /telecom
	cd /telecom
	export DISTUTILS_USE_SDK=0
	goodecho "[+] Cloninig and installing pysctp"
	installfromnet "git clone https://github.com/FlUxIuS/pysctp.git"
	cd pysctp
	install_dependencies "libsctp-dev"
	pip3install .
}

function osmobts_suite_soft_install() {
	set -e
    goodecho "[+] Installing OsmoBTS suite dependencies"
    install_dependencies "libmnl-dev libpcsclite-dev liburing-dev libtool libgnutls28-dev libtalloc-dev libsctp-dev lksctp-tools libortp-dev dahdi-source libopenr2-dev libc-ares-dev libtonezone-dev libsqlite3-dev"

    install_lib() {
        local repo_url=$1
        local repo_dir=$2
        local configure_opts=$3

        goodecho "[+] Cloning and installing $repo_dir"
        cd $osmo_src
        installfromnet "git clone $repo_url" || { echo "Failed to clone $repo_dir"; exit 1; }
        cd $repo_dir
        autoreconf -fi || { echo "autoreconf failed for $repo_dir"; exit 1; }
        ./configure $configure_opts || { echo "configure failed for $repo_dir"; exit 1; }
        make -j$(nproc) || { echo "make failed for $repo_dir"; exit 1; }
        #make check || { echo "make check failed for $repo_dir"; exit 1; }
        make install || { echo "make install failed for $repo_dir"; exit 1; }
        sudo ldconfig || { echo "ldconfig failed for $repo_dir"; exit 1; }
    }

    [ -d /telecom/2G/osmocom ] || mkdir -p /telecom/2G/osmocom
    cd /telecom/2G/osmocom
    mkdir -p tmp/osmo/src
    osmo_src=$(pwd)/tmp/osmo/src

    install_lib "https://gitea.osmocom.org/osmocom/libosmocore.git" "libosmocore"
    install_lib "https://gitea.osmocom.org/osmocom/libosmo-netif.git" "libosmo-netif"
    install_lib "https://gitea.osmocom.org/osmocom/libosmo-abis.git" "libosmo-abis"
    install_lib "https://gitea.osmocom.org/osmocom/libosmo-sccp.git" "libosmo-sccp"
    install_lib "https://gitea.osmocom.org/osmocom/libosmo-sigtran.git" "libosmo-sigtran"
    install_lib "https://gitea.osmocom.org/cellular-infrastructure/libsmpp34.git" "libsmpp34"
    install_lib "https://gitea.osmocom.org/cellular-infrastructure/osmo-mgw.git" "osmo-mgw"
    install_lib "https://gitea.osmocom.org/cellular-infrastructure/libasn1c.git" "libasn1c"
    install_lib "https://gitea.osmocom.org/cellular-infrastructure/osmo-iuh.git" "osmo-iuh"
    install_lib "https://gitea.osmocom.org/cellular-infrastructure/osmo-hlr.git" "osmo-hlr"
    install_lib "https://gitea.osmocom.org/cellular-infrastructure/osmo-msc.git" "osmo-msc" "--enable-iu"
    install_lib "https://gitea.osmocom.org/cellular-infrastructure/osmo-ggsn.git" "osmo-ggsn"
    install_lib "https://gitea.osmocom.org/cellular-infrastructure/osmo-sgsn.git" "osmo-sgsn" "--enable-iu"

    # cleaning
    cd /telecom/2G/osmocom
    rm -R tmp
    cp /root/config/osmobts/nitb/* .
}

function UERANSIM_soft_install() {
	install_dependencies "libsctp-dev lksctp-tools iproute2"
	[ -d /telecom/5G ] || mkdir -p /telecom/5G
	cd /telecom/5G
	goodecho "[+] Cloninig and installing UERANSIM"
	gitinstall "https://github.com/aligungr/UERANSIM" "UERANSIM"
	cd UERANSIM
	make
}

function pysim_soft_install() {
	install_dependencies "pcscd libpcsclite-dev python3-setuptools python3-pycryptodome python3-pyscard python3-pip python3-cryptography pcsc-tools"
	[ -d /telecom/SIM ] || mkdir -p /telecom/SIM
	cd /telecom/SIM
	goodecho "[+] Cloninig and installing PySIM"
	gitinstall "https://github.com/osmocom/pysim.git" "pysim"
	cd pysim
	sed -i '/pyscard/d' requirements.txt
	sed -i '/cryptography/d' requirements.txt
	pip3install -r requirements.txt
}

function sysmoUSIM_soft_install() {
	install_dependencies "python3-pyscard pcscd systemctl pcscd pcsc-tools"
	[ -d /telecom/SIM ] || mkdir -p /telecom/SIM
	cd /telecom/SIM
	goodecho "[+] Cloninig and installing sysmo-usim-tool"
	gitinstall "https://github.com/sysmocom/sysmo-usim-tool.git" "sysmo-usim-tool"
}

function jss7_soft_install() {
    # Check if the architecture is amd64 or x86_64
    arch=$(uname -m)
    if [[ "$arch" == "amd64" || "$arch" == "x86_64" ]]; then
        install_dependencies "maven"
        [ -d /telecom/2G ] || mkdir -p /telecom/2G
        cd /telecom/2G
        goodecho "[+] Cloning and installing jSS7"
        gitinstall "https://github.com/PentHertz/jss7.git" "jss7"
        cd jss7
        mvn install
    else
        goodecho "[!] Unsupported architecture: $arch. jSS7 installation aborted."
    fi
}

function SCAT_soft_install() {
    [ -d /telecom ] || mkdir -p /telecom
    cd /telecom
    goodecho "[+] Installing SCAT"
    pip3install signalcat[fastcrc]@git+https://github.com/fgsect/scat
}

function SigPloit_soft_install() {
	[ -d /telecom/2G ] || mkdir -p /telecom/2G
	cd /telecom/2G
	goodecho "[+] Cloninig and installing SigPloit"
	gitinstall "https://github.com/FlUxIuS/SigPloit.git" "SigPloit"
	cd SigPloit
	pip3install -r requirements.txt
}

function srsran5GSA_bladerf_soft_install() {
	set +e # TODO: debug that function
    set +o pipefail
	goodecho "[+] Installing srsran_project dependencies"
	install_dependencies "cmake make gcc g++ pkg-config libfftw3-dev libmbedtls-dev libsctp-dev libyaml-cpp-dev libgtest-dev"
	goodecho "[+] Feching srsran_project"
	[ -d /telecom/5G ] || mkdir -p /telecom/5G
	cd /telecom/5G
	goodecho "[+] Cloninig and installing srsran_project"
	installfromnet "git clone https://github.com/FlUxIuS/srsRAN_Project_bladerf.git"
	cd srsRAN_Project_bladerf
	mkdir build
	cd build
	cmake ../
	make -j $(nproc)
	make install
	#make test -j $(nproc)
	set -e
    set -o pipefail
}
### TODO: more More!
