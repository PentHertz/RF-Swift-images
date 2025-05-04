#!/bin/bash

function fzf_soft_install() {
	goodecho "[+] Installing fzf"
	installfromnet "apt-fast -y install fzf"
}

function zsh_tools_install() {
	goodecho "[+] Installing zsh"
	installfromnet "apt-fast -y install zsh"
	chsh -s /bin/zsh 
	goodecho "[+] Installing oh-my-zsh"
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	goodecho "[+] Installing pluggins"
	git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
}

function arsenal_soft_install() {
	goodecho "[+] Installing arsenal"
	cd /opt
	installfromnet "git clone https://github.com/Orange-Cyberdefense/arsenal.git"
	cd arsenal
	pip3install -r requirements.txt
	#./addalias.sh
	echo "alias a='/opt/arsenal/run'" >> ~/.zshrc
	echo "alias a='/opt/arsenal/run'" >> ~/.bashrc
}

function atuin_soft_fromsource_install() {
	goodecho "[+] Proceeding with atuin installation from source instead"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    rustup update
	cd /root/thirdparty
	gitinstall "https://github.com/atuinsh/atuin.git" "atuin_soft_fromsource_install"
	cd atuin
	cargo build --release --bin atuin
	cp target/release/atuin /usr/bin/
    echo 'eval "$(atuin init zsh)"' >> ~/.zshrc
    goodecho "[+] atuin installed and initialized in zshrc"
}


function atuin_soft_install() {
    ARCH=$(uname -m)

    case "$ARCH" in
        x86_64|amd64)
            goodecho "[+] Architecture: x86_64"
            goodecho "[+] Installing atuin for x86_64"
            ;;
        aarch64|arm64)
            goodecho "[+] Architecture: aarch64"
            goodecho "[+] Installing atuin for aarch64"
            ;;
        *)
            criticalecho-noexit "[-] Officially unsupported architecture: $ARCH"
            atuin_soft_fromsource_install
            exit 0
            ;;
    esac

    goodecho "[+] Proceeding with atuin installation"
    cd /opt || exit  # Fail the script if /opt is inaccessible
    curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
    echo 'source $HOME/.atuin/bin/env' >> ~/.zshrc
    echo 'eval "$(atuin init zsh)"' >> ~/.zshrc
    goodecho "[+] atuin installed and initialized in zshrc"
}
