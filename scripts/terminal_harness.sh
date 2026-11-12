#!/bin/bash

function fzf_soft_install() {
	goodecho "[+] Installing fzf"
	installfromnet "apt-fast" "-y" "install" "fzf"
}

function zsh_tools_install() {
	goodecho "[+] Installing zsh"
	installfromnet "apt-fast" "-y" "install" "zsh"
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
	gitinstall "https://github.com/PentHertz/arsenal.git" "arsenal_soft_install"
	cd arsenal
	pip3install -r requirements.txt
	#./addalias.sh
	echo "alias a='/opt/arsenal/run'" >> ~/.zshrc
	echo "alias a='/opt/arsenal/run'" >> ~/.bashrc
}

function grimoire_soft_install() {
	goodecho "[+] Installing grimoire"
	cd /opt
	gitinstall "https://github.com/PentHertz/grimoire.git" "grimoire_soft_install"
	cd grimoire
	pip3install -r requirements.txt
	chmod +x grimoire.py
	# Docs are fetched at runtime ('grimoire all'), not baked in: the sources are
	# 20+ repos and this is the base image every other one builds on.
	ln -sf /opt/grimoire/grimoire.py /usr/local/bin/grimoire
	echo "alias grim='/usr/local/bin/grimoire'" >> ~/.zshrc
	echo "alias grim='/usr/local/bin/grimoire'" >> ~/.bashrc
}

function atuin_soft_fromsource_install() {
        goodecho "[+] Proceeding with atuin installation from source instead"
    [ -d /root/thirdparty ] || mkdir /root/thirdparty
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    export PATH="$HOME/.cargo/bin:$PATH"
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

    local triple
    case "$ARCH" in
        x86_64|amd64) triple="x86_64-unknown-linux-gnu" ;;
        aarch64|arm64) triple="aarch64-unknown-linux-gnu" ;;
        *)
            criticalecho-noexit "[-] Officially unsupported architecture: $ARCH"
            atuin_soft_fromsource_install
            exit 0
            ;;
    esac

    # Fetch the release tarball straight from GitHub, with retries and its
    # checksum. setup.atuin.sh is a wrapper with two more unretried hops (it
    # fetches the GitHub installer, which fetches this tarball) and a 502 there
    # used to abort the whole corebuild layer.
    goodecho "[+] Installing atuin for $ARCH"
    local name="atuin-${triple}.tar.gz"
    local url="https://github.com/atuinsh/atuin/releases/latest/download/${name}"
    local tmp
    tmp=$(mktemp -d)
    if installfromnet curl --proto '=https' --tlsv1.2 -fsSL -o "$tmp/$name" "$url" \
        && installfromnet curl --proto '=https' --tlsv1.2 -fsSL -o "$tmp/$name.sha256" "$url.sha256" \
        && (cd "$tmp" && sha256sum -c "$name.sha256") \
        && tar -xzf "$tmp/$name" -C "$tmp" \
        && install -m755 "$tmp/atuin-${triple}/atuin" /usr/local/bin/atuin; then
        # Only hook the shells once the binary is there, or every new shell
        # would print "atuin: command not found".
        grep -qF 'atuin init zsh' ~/.zshrc 2>/dev/null || echo 'eval "$(atuin init zsh)"' >> ~/.zshrc
        grep -qF 'atuin init bash' ~/.bashrc 2>/dev/null || echo 'eval "$(atuin init bash)"' >> ~/.bashrc
        goodecho "[+] atuin $(atuin --version | cut -d' ' -f2) installed and initialized in zshrc/bashrc"
    else
        record_build_failure "net" "atuin" "release download/verify failed: $url"
    fi
    rm -rf "$tmp"
    return 0
}
