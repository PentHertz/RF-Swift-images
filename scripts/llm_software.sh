#!/bin/bash
# This file is part of the RFSwift project (llm image).
# Coding agents (Claude Code, Codex, OpenCode 2.x, Mistral Vibe, Hermes Agent), shared skill
# packs managed by llm-skills, the REA / Craft Anything analysis MCP servers, whisper.cpp
# (local speech-to-text) and Open WebUI.
# Usage notes for the image: docs/llm.md (copied to /opt/llm/README.md).

LLM_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LLM_SKILLS_ROOT="/opt/llm-skills"

# Node.js LTS from nodejs.org: REA needs ^22.23.4 || ^24.22.1, Ubuntu 26.04 ships 22.22.
LLM_NODE_VERSION="v24.22.3"  # known-good (with the SHA256s below); the build takes the newest v24.x
LLM_NODE_SHA256_X64="4f2b175a6d53a5c617a80dba2676238a0688cef28c6da4eba35c7d844e66fcfb"
LLM_NODE_SHA256_ARM64="6e51a2ada00f0011cc266f65d98922b403d7ad88f809ca2aa615a5fe1ce6e86c"

CRAFT_VERSION="0.6.1"  # known-good (with the SHA256s below); the build takes the newest release
CRAFT_SHA256_X86_64="83ec0730c9117f399122b315c63ed4c3a8d31ac55bddd74cb8b33cd2f76ef704"
CRAFT_SHA256_AARCH64="b4255ac806e2a598b9fc6dba4e8ed2190e49baafd2f68dd7e037f3294e472941"
CRAFT_SHA256_RISCV64="d82468c2daef97811f0b9b63dba523516860f238d46873ad6fbccccadedd62c1"

WHISPERCPP_VERSION="v1.9.5"  # known-good; the build takes the newest release

# Agents configured by REA and Craft Anything's own setup commands (Vibe is done by hand).
LLM_SETUP_CLIENTS=(--client claude_code --client codex --client opencode --client hermes)

# llm_fetch_verified <name> <url> <sha256> <dest>: download and check, recording failures
function llm_fetch_verified() {
    local name="$1" url="$2" sha="$3" dest="$4"
    if ! installfromnet curl -fsSL -o "$dest" "$url"; then
        record_build_failure "net" "$name" "download failed: $url"
        return 1
    fi
    if ! echo "${sha}  ${dest}" | sha256sum -c -; then
        record_build_failure "net" "$name" "checksum mismatch: $url"
        return 1
    fi
}

# llm_npm_global <name> <package> <binary>: best-effort global npm install
function llm_npm_global() {
    local name="$1" pkg="$2" bin="$3"
    if ! command -v npm > /dev/null; then
        record_build_failure "toolchain" "$name" "npm unavailable (llm_nodejs_install failed?)"
        return 0
    fi
    if ! installfromnet npm install -g --no-fund --no-audit "$pkg"; then
        record_build_failure "npm" "$name" "npm install -g $pkg failed"
        return 0
    fi
    "$bin" --version || record_build_failure "other" "$name" "$bin --version failed after install"
    return 0
}

# llm_vibe_mcp_add <name> <command> [args...]: register a stdio MCP server with Mistral Vibe
# (REA's and Craft Anything's setup commands don't know Vibe)
function llm_vibe_mcp_add() {
    local name="$1" cmd="$2" a argv=()
    shift 2
    command -v vibe > /dev/null || return 0
    for a in "$@"; do argv+=(--arg "$a"); done
    vibe mcp remove "$name" > /dev/null 2>&1 || true
    vibe mcp add "$name" --transport stdio --command "$cmd" "${argv[@]}" \
        || record_build_failure "other" "$name (Mistral Vibe)" "vibe mcp add failed"
}

function llm_nodejs_install() {
    local arch sha ver latest new_sha
    case "$(uname -m)" in
        x86_64|amd64) arch="x64"; sha="$LLM_NODE_SHA256_X64" ;;
        aarch64|arm64) arch="arm64"; sha="$LLM_NODE_SHA256_ARM64" ;;
        *) record_build_failure "toolchain" "nodejs" "no official Node.js build for $(uname -m)"; return 0 ;;
    esac
    install_dependencies "xz-utils ca-certificates curl"
    # Newest v24.x (the LTS line REA needs), verified against that release's SHASUMS256.txt.
    # LLM_NODE_VERSION and its pinned SHA256 stay the known-good fallback.
    latest=$(curl -fsSL --max-time 30 https://nodejs.org/dist/index.json 2>/dev/null \
        | grep -oE '"version":"v24\.[0-9]+\.[0-9]+"' | head -n1 | cut -d'"' -f4 || true)
    ver="v$(pick_version nodejs "${latest#v}" "${LLM_NODE_VERSION#v}")"
    if [ "$ver" != "$LLM_NODE_VERSION" ]; then
        new_sha=$(curl -fsSL --max-time 30 "https://nodejs.org/dist/${ver}/SHASUMS256.txt" 2>/dev/null \
            | awk -v f="node-${ver}-linux-${arch}.tar.xz" '$2 == f {print $1}' || true)
        if [ -n "$new_sha" ]; then
            sha="$new_sha"
        else
            note_version_fallback nodejs "no SHASUMS256.txt entry for ${ver}" "$LLM_NODE_VERSION"
            ver="$LLM_NODE_VERSION"
        fi
    fi
    goodecho "[+] Installing Node.js ${ver} (official LTS build)"
    local dir="node-${ver}-linux-${arch}" tmp
    tmp=$(mktemp -d)
    if llm_fetch_verified "nodejs" "https://nodejs.org/dist/${ver}/${dir}.tar.xz" "$sha" "$tmp/node.tar.xz"; then
        tar -xJf "$tmp/node.tar.xz" -C /usr/local --strip-components=1 \
            --exclude="${dir}/CHANGELOG.md" --exclude="${dir}/README.md" --exclude="${dir}/LICENSE"
        node --version
        npm --version
    fi
    rm -rf "$tmp"
}

function claudecode_soft_install() {
    goodecho "[+] Installing Claude Code"
    llm_npm_global "claude-code" "@anthropic-ai/claude-code" claude
}

function codex_soft_install() {
    goodecho "[+] Installing OpenAI Codex CLI"
    llm_npm_global "codex" "@openai/codex" codex
}

function opencode_soft_install() {
    # OpenCode 2.x: npm's opencode-ai package and the curl installer still ship 1.x, whose
    # `run` lacks --standalone (needed by Craft Anything's OpenCode backend).
    goodecho "[+] Installing OpenCode 2.x"
    llm_npm_global "opencode" "@opencode/cli" opencode
    # npm installs every libc/CPU-level variant (~250 MB each, their packages declare no libc);
    # postinstall hardlinks the one it picked to bin/opencode.exe, so drop the others.
    local pkg used variant
    pkg="$(npm root -g)/@opencode/cli"
    [ -f "$pkg/bin/opencode.exe" ] || return 0
    used=$(find "$pkg/node_modules/@opencode" -samefile "$pkg/bin/opencode.exe" 2>/dev/null | head -n1)
    [ -n "$used" ] || return 0
    for variant in "$pkg"/node_modules/@opencode/cli-*; do
        case "$used" in "$variant"/*) ;; *) rm -rf "$variant" ;; esac
    done
    opencode --version || record_build_failure "other" "opencode" "opencode broken after pruning platform variants"
}

function mistralvibe_soft_install() {
    goodecho "[+] Installing Mistral Vibe"
    if ! command -v uv > /dev/null; then
        record_build_failure "toolchain" "mistral-vibe" "uv unavailable"
        return 0
    fi
    if ! installfromnet uv tool install --force mistral-vibe; then
        record_build_failure "pip" "mistral-vibe" "uv tool install failed"
        return 0
    fi
    local bin
    for bin in vibe vibe-acp; do
        [ -e "$HOME/.local/bin/$bin" ] && ln -sf "$HOME/.local/bin/$bin" "/usr/local/bin/$bin"
    done
    vibe --version || record_build_failure "other" "mistral-vibe" "vibe --version failed after install"
}

function hermes_agent_soft_install() {
    # The official installer pins its own uv and Python and lives in ~/.hermes/hermes-agent.
    # Browser (Chromium) and computer-use extras stay off; `hermes pm install` adds them later.
    goodecho "[+] Installing Hermes Agent (Nous Research)"
    [ -d /root/thirdparty ] || mkdir -p /root/thirdparty
    local script=/root/thirdparty/hermes-install.sh
    if ! installfromnet curl -fsSL -o "$script" "https://hermes-agent.nousresearch.com/install.sh"; then
        record_build_failure "net" "hermes-agent" "install.sh download failed"
        return 0
    fi
    if ! bash "$script" --non-interactive --skip-browser --skip-computer-use; then
        record_build_failure "build" "hermes-agent" "install.sh failed"
        return 0
    fi
    [ -e "$HOME/.local/bin/hermes" ] && ln -sf "$HOME/.local/bin/hermes" /usr/local/bin/hermes
    hermes --version || record_build_failure "other" "hermes-agent" "hermes --version failed after install"
}

function llm_skills_install() {
    # Skill packs shared by every agent. All of them are rendered; the default set is enabled
    # (Trail of Bits, farmage, Floorplan, Cloudflare's security-audit, Strix, ARTEX and one index
    # skill standing for the 818 cybersecurity skills, whose descriptions alone would add ~80K
    # tokens to every turn).
    goodecho "[+] Installing agent skill packs"
    install_dependencies "git python3"
    mkdir -p "$LLM_SKILLS_ROOT/src"
    local spec name url
    for spec in \
        "trailofbits https://github.com/trailofbits/skills.git" \
        "farmage https://github.com/farmage/opencode-skills.git" \
        "floorplan https://github.com/haydenschmitty/floorplan.git" \
        "cybersecurity https://github.com/mukul975/Anthropic-Cybersecurity-Skills.git" \
        "cloudflare https://github.com/cloudflare/security-audit-skill.git" \
        "strix https://github.com/usestrix/strix.git" \
        "artex https://github.com/BaaRai/ARTEX.git"; do
        name="${spec%% *}"
        url="${spec#* }"
        if [ -d "$LLM_SKILLS_ROOT/src/$name/.git" ]; then
            git -C "$LLM_SKILLS_ROOT/src/$name" pull --ff-only \
                || criticalecho-noexit "[!] $name skills: git pull failed, keeping the current checkout"
        elif ! installfromnet git clone --depth 1 "$url" "$LLM_SKILLS_ROOT/src/$name"; then
            record_build_failure "git" "$name skills" "clone failed: $url"
        fi
    done

    install -m 0755 "$LLM_SCRIPTS_DIR/llm/llm-skills" /usr/local/bin/llm-skills
    if ! llm-skills render; then
        record_build_failure "other" "llm-skills" "render failed"
        return 0
    fi
    llm-skills enable trailofbits farmage floorplan cybersecurity-skills cloudflare strix artex \
        || record_build_failure "other" "llm-skills" "enabling the default skill set failed"

    # farmage's OpenCode workflow commands (/common-ground, /planning/..., as its installer does)
    if [ -d "$LLM_SKILLS_ROOT/src/farmage/.opencode/commands" ]; then
        mkdir -p "$HOME/.config/opencode/commands"
        cp -r "$LLM_SKILLS_ROOT/src/farmage/.opencode/commands/." "$HOME/.config/opencode/commands/"
    fi

    # Hermes keeps its own ~/.hermes/skills; point it at the shared folder as well
    if command -v hermes > /dev/null; then
        hermes config set skills.external_dirs '["~/.agents/skills"]' \
            || record_build_failure "other" "hermes skills" "could not set skills.external_dirs"
    fi

    # Trail of Bits is also a plugin marketplace (commands, agents, hooks on top of the skills):
    # registered, not enabled, so `/plugin install <name>@trailofbits` is one step away.
    if command -v claude > /dev/null; then
        claude plugin marketplace add "$LLM_SKILLS_ROOT/src/trailofbits" \
            || record_build_failure "other" "trailofbits marketplace (Claude Code)" "claude plugin marketplace add failed"
    fi
    if command -v codex > /dev/null; then
        codex plugin marketplace add "$LLM_SKILLS_ROOT/src/trailofbits" \
            || record_build_failure "other" "trailofbits marketplace (Codex)" "codex plugin marketplace add failed"
    fi
}

function strix_soft_install() {
    # Strix: autonomous AI pentest agent (PyPI strix-agent). Each scan runs in a sandbox
    # container, so it needs a reachable Docker daemon (mount /var/run/docker.sock) and an
    # LLM (STRIX_LLM + LLM_API_KEY). Its agent skills come with the `strix` llm-skills pack.
    goodecho "[+] Installing Strix"
    if ! command -v uv > /dev/null; then
        record_build_failure "toolchain" "strix" "uv unavailable"
        return 0
    fi
    if ! installfromnet uv tool install --force --python 3.12 strix-agent; then
        record_build_failure "pip" "strix" "uv tool install strix-agent failed"
        return 0
    fi
    [ -e "$HOME/.local/bin/strix" ] && ln -sf "$HOME/.local/bin/strix" /usr/local/bin/strix
    strix --version || record_build_failure "other" "strix" "strix --version failed after install"
    return 0
}

# ARTEMIS (Stanford Trinity): autonomous multi-agent red teaming. A Python supervisor runs
# parallel sub-agents built on its own fork of the Codex CLI. Installed as `artemis-redteam`
# so it is not confused with AresValley's Artemis signal-identification app in the SDR images
# (`Artemis`). Opt-in: not in the default llm build (slow Rust build).
# Upstream has no releases, so it is pinned to the reviewed commit; re-review before bumping.
ARTEMIS_REDTEAM_COMMIT="f309242d2a74493cd41aa3f8b02cec4d3fdd479d"   # reviewed 2026-11-21

# One clone attempt into a clean destination (retries would otherwise hit "already exists").
function _artemis_redteam_clone() {
    rm -rf "$2"
    git clone -q "$1" "$2"
}

function artemis_redteam_soft_install() {
    # Authorized testing only: its sub-agents run commands inside this container.
    # Needs OPENROUTER_API_KEY or OPENAI_API_KEY plus SUBAGENT_MODEL at run time (docs/llm.md).
    goodecho "[+] Installing ARTEMIS (Stanford Trinity) as artemis-redteam"
    local dir=/opt/artemis-redteam tc bin
    if ! command -v uv > /dev/null || ! command -v cargo > /dev/null; then
        record_build_failure "toolchain" "artemis-redteam" "uv or cargo unavailable"
        return 0
    fi
    install_dependencies "build-essential pkg-config libssl-dev git"
    if ! installfromnet _artemis_redteam_clone https://github.com/Stanford-Trinity/ARTEMIS.git "$dir"; then
        record_build_failure "git" "artemis-redteam" "clone failed"
        return 0
    fi
    if ! git -C "$dir" checkout -q "$ARTEMIS_REDTEAM_COMMIT"; then
        record_build_failure "git" "artemis-redteam" "reviewed commit $ARTEMIS_REDTEAM_COMMIT not found upstream"
        rm -rf "$dir"
        return 0
    fi

    # Build only the fork's `codex` binary. Its rust-toolchain.toml pins a Rust version that
    # rustup fetches for this build; the build tree and that toolchain are dropped afterwards.
    tc=$(sed -n 's/^channel *= *"\(.*\)"/\1/p' "$dir/codex-rs/rust-toolchain.toml" 2>/dev/null || true)
    if ! (cd "$dir/codex-rs" && cargo build --release -p codex-cli --bin codex); then
        record_build_failure "build" "artemis-redteam" "cargo build of the Codex fork failed"
        rm -rf "$dir"
        return 0
    fi
    bin=$(mktemp)
    cp "$dir/codex-rs/target/release/codex" "$bin"
    rm -rf "$dir/codex-rs/target"
    install -Dm755 "$bin" "$dir/codex-rs/target/release/codex"   # upstream's default path
    rm -f "$bin"
    if [ -n "$tc" ] && [ "$tc" != "stable" ]; then
        rustup toolchain uninstall "$tc" > /dev/null 2>&1 || true
    fi

    # Python supervisor: uv-managed Python 3.12 (uv.lock requires >= 3.12), locked deps.
    if ! uv python install 3.12 || ! (cd "$dir" && uv sync --frozen --no-dev --python 3.12); then
        record_build_failure "pip" "artemis-redteam" "uv sync of the supervisor failed"
        return 0
    fi

    # The fork is deliberately NOT on PATH (it would shadow the real Codex CLI) and gets its
    # own CODEX_HOME so it never touches ~/.codex, where the real Codex keeps its config and
    # the MCP servers REA/Craft register. Logs go to ./logs under the current directory.
    cat > /usr/local/bin/artemis-redteam << 'EOF'
#!/bin/bash
# ARTEMIS (Stanford Trinity) autonomous red teaming. Authorized testing only.
# Not AresValley's Artemis signal app (`Artemis` in the SDR images).
# Keys: export OPENROUTER_API_KEY (or OPENAI_API_KEY) and SUBAGENT_MODEL, or put them in
# /opt/artemis-redteam/.env. Example configs: /opt/artemis-redteam/configs/
export CODEX_HOME="${ARTEMIS_CODEX_HOME:-/root/.artemis-redteam/codex}"
mkdir -p "$CODEX_HOME"
exec /opt/artemis-redteam/.venv/bin/codex-supervisor \
    --codex-binary /opt/artemis-redteam/codex-rs/target/release/codex "$@"
EOF
    chmod +x /usr/local/bin/artemis-redteam
    artemis-redteam --help > /dev/null 2>&1 \
        || record_build_failure "other" "artemis-redteam" "codex-supervisor --help failed"
    return 0
}

function rea_soft_install() {
    # REA (Reverse Engineer Anything): MCP server + workflow skill for native binaries,
    # JavaScript/Electron, .NET and websites. Native analysis uses Ghidra, Hopper, IDA or
    # Kuna when present; static JS/Electron analysis needs none. Linux needs procps' ps.
    goodecho "[+] Installing REA (rea-agents)"
    install_dependencies "procps"
    llm_npm_global "rea" "rea-agents" rea
    command -v rea > /dev/null || return 0
    rea setup --yes "${LLM_SETUP_CLIENTS[@]}" \
        || record_build_failure "other" "rea setup" "MCP registration failed for one or more agents"
    llm_vibe_mcp_add rea "$(command -v rea)" mcp
}

function craftanything_soft_install() {
    # Craft Anything: study a website/app/game and have a coding agent rebuild it. Its CLI is an
    # MCP server (progressive toolsets) and `setup` registers it with the agents.
    goodecho "[+] Installing Craft Anything"
    local arch sha
    case "$(uname -m)" in
        x86_64|amd64) arch="x86_64"; sha="$CRAFT_SHA256_X86_64" ;;
        aarch64|arm64) arch="aarch64"; sha="$CRAFT_SHA256_AARCH64" ;;
        riscv64) arch="riscv64"; sha="$CRAFT_SHA256_RISCV64" ;;
        *) record_build_failure "other" "craft-anything" "no release for $(uname -m)"; return 0 ;;
    esac
    # Newest release, verified against its SHA256SUMS.txt; CRAFT_VERSION and the pinned
    # SHA256s stay the known-good fallback.
    local ver new_sha
    ver=$(latest_release_version storytold/craft-anything "$CRAFT_VERSION" \
        "https://github.com/storytold/craft-anything/releases/download/v@V@/craft-anything-@V@-linux-${arch}.tar.gz")
    if [ "$ver" != "$CRAFT_VERSION" ]; then
        new_sha=$(curl -fsSL --max-time 30 \
            "https://github.com/storytold/craft-anything/releases/download/v${ver}/SHA256SUMS.txt" 2>/dev/null \
            | awk -v f="craft-anything-${ver}-linux-${arch}.tar.gz" '$2 == f {print $1}' || true)
        if [ -n "$new_sha" ]; then
            sha="$new_sha"
        else
            note_version_fallback storytold/craft-anything "no SHA256SUMS.txt entry for ${ver}" "$CRAFT_VERSION"
            ver="$CRAFT_VERSION"
        fi
    fi
    # desktop app runtime (egui on X11/Wayland, GTK file dialogs)
    install_dependencies "libxkbcommon-x11-0 libwayland-client0 libx11-6 libxrandr2 libxi6 libgl1 libgtk-3-0t64"
    local tmp
    tmp=$(mktemp -d)
    if ! llm_fetch_verified "craft-anything" \
        "https://github.com/storytold/craft-anything/releases/download/v${ver}/craft-anything-${ver}-linux-${arch}.tar.gz" \
        "$sha" "$tmp/craft.tar.gz"; then
        rm -rf "$tmp"
        return 0
    fi
    rm -rf /opt/craft-anything
    mkdir -p /opt/craft-anything
    tar -xzf "$tmp/craft.tar.gz" -C /opt/craft-anything --strip-components=1
    rm -rf "$tmp"
    ln -sf /opt/craft-anything/bin/craft-anything /usr/local/bin/craft-anything
    ln -sf /opt/craft-anything/bin/craft-anything-cli /usr/local/bin/craft-anything-cli
    install -Dm644 /opt/craft-anything/share/applications/ai.storyteller.craft-anything.desktop \
        /usr/share/applications/ai.storyteller.craft-anything.desktop
    craft-anything-cli --version || record_build_failure "other" "craft-anything" "craft-anything-cli does not run"

    craft-anything-cli setup --yes "${LLM_SETUP_CLIENTS[@]}" \
        || record_build_failure "other" "craft-anything setup" "MCP registration failed for one or more agents"
    llm_vibe_mcp_add craft-anything /usr/local/bin/craft-anything-cli mcp
    # OpenCode as an extra builder backend (Claude Code stays the default one)
    craft-anything-cli ai add OpenCode --kind agent_cli --model opencode \
        || record_build_failure "other" "craft-anything OpenCode backend" "ai add failed"
}

function nodeterm_server_soft_install() {
    # NodeTerm Server Edition (https://nodeterm.dev): a headless server that serves NodeTerm's
    # browser canvas over HTTP/WebSocket, managing terminals and coding agents in tmux sessions.
    # Built from source with the image's Node (the prebuilt desktop app is x86_64-only; this
    # builds on amd64 and arm64). node-pty is rebuilt against Node's ABI, since the server runs
    # under node, not electron. Run it with `nodeterm-server`. Data (auth, sessions, scrollback)
    # lives in ~/.nodeterm-server. Licensed BUSL-1.1 (converts to MIT 4 years after each release;
    # internal, non-compete use permitted).
    goodecho "[+] Installing NodeTerm Server Edition"
    if ! command -v node > /dev/null || ! command -v npm > /dev/null; then
        record_build_failure "toolchain" "nodeterm" "node/npm unavailable (llm_nodejs_install failed?)"
        return 0
    fi
    # tmux: terminal session continuity; git: the Source Control panel; build-essential + python3:
    # node-pty's native build.
    install_dependencies "tmux git curl build-essential python3"
    local src=/opt/nodeterm
    rm -rf "$src"
    if ! installfromnet git clone --depth 1 https://github.com/eneskirca/nodeterm.git "$src"; then
        record_build_failure "git" "nodeterm" "clone failed"
        return 0
    fi
    cd "$src" || { record_build_failure "other" "nodeterm" "cd $src failed"; return 0; }
    # --ignore-scripts skips the electron-rebuild postinstall and electron's binary download,
    # neither of which the server needs (devDependencies are required to build the bundle).
    if ! installfromnet npm ci --ignore-scripts; then
        record_build_failure "npm" "nodeterm" "npm ci failed"
        return 0
    fi
    if ! npm run build || ! npm run server:build; then
        record_build_failure "build" "nodeterm" "renderer/server build failed"
        return 0
    fi
    # Drop dev dependencies, then compile node-pty against Node's ABI (the server runs under node).
    npm prune --omit=dev || true
    npm rebuild node-pty || record_build_failure "build" "nodeterm" "node-pty rebuild failed"
    if [ ! -f "$src/out/server/main.cjs" ]; then
        record_build_failure "build" "nodeterm" "out/server/main.cjs missing after build"
        return 0
    fi
    cat > /usr/local/bin/nodeterm-server << 'EOS'
#!/bin/sh
# NodeTerm Server Edition. First run prints a one-time setup URL (open it, choose a password),
# or seed it headlessly with NODETERM_SERVER_PASSWORD. Binds 127.0.0.1:8443 by default; publish
# or forward that port to reach it from the host. To bind a non-loopback interface, set
# NODETERM_HOST=0.0.0.0 and pass --insecure-http (intended behind a TLS-terminating proxy).
# Data (auth, sessions, scrollback): ~/.nodeterm-server, or set NODETERM_DATA_DIR.
cd /opt/nodeterm || exit 1
exec node out/server/main.cjs "$@"
EOS
    chmod 0755 /usr/local/bin/nodeterm-server
}

function whispercpp_soft_install() {
    # whisper.cpp: local speech-to-text (whisper-cli, whisper-server with an OpenAI-compatible
    # endpoint, whisper-stream for the microphone). Models are not in the image:
    # `whisper-download-model base.en` puts one in /opt/whisper.cpp/models.
    local wver
    wver=$(latest_release_version ggml-org/whisper.cpp "${WHISPERCPP_VERSION#v}" \
        "https://github.com/ggml-org/whisper.cpp/archive/refs/tags/v@V@.tar.gz")
    WHISPERCPP_VERSION="v${wver}"
    goodecho "[+] Installing whisper.cpp ${WHISPERCPP_VERSION}"
    # SDL2: microphone examples (whisper-stream, whisper-command); ffmpeg: whisper-server --convert
    install_dependencies "build-essential cmake git libsdl2-dev ffmpeg"
    local src=/opt/whisper.cpp
    rm -rf "$src"
    if ! installfromnet git clone --depth 1 -b "$WHISPERCPP_VERSION" https://github.com/ggml-org/whisper.cpp.git "$src"; then
        record_build_failure "git" "whisper.cpp" "clone failed (${WHISPERCPP_VERSION})"
        return 0
    fi
    # GGML_NATIVE=OFF: a portable build (AVX2/FMA baseline on x86_64) instead of one tuned
    # for, and possibly crashing off, the CPU of the machine that built the image
    if cmake -S "$src" -B "$src/build" -DCMAKE_BUILD_TYPE=Release -DGGML_NATIVE=OFF -DWHISPER_SDL2=ON \
            -DWHISPER_BUILD_TESTS=OFF \
        && cmake --build "$src/build" -j"$(nproc)" \
        && cmake --install "$src/build"; then
        ldconfig
    else
        record_build_failure "build" "whisper.cpp" "cmake build failed"
    fi
    rm -rf "$src/build"
    cat > /usr/local/bin/whisper-download-model << 'EOS'
#!/bin/sh
# whisper-download-model <model> [dir]: fetch a ggml Whisper model from Hugging Face
# (tiny, base.en, small, medium, large-v3-turbo, ...; -q5_0/-q8_0 for quantized ones).
# Default dir: /opt/whisper.cpp/models. Run without arguments for the full list.
exec /opt/whisper.cpp/models/download-ggml-model.sh "$@"
EOS
    chmod 0755 /usr/local/bin/whisper-download-model
    whisper-cli --help > /dev/null 2>&1 || record_build_failure "build" "whisper.cpp" "whisper-cli does not run"
}

function openwebui_soft_install() {
    # Open WebUI supports Python 3.11-3.12 only (Ubuntu 26.04 ships 3.14): uv brings its own 3.11.
    # PyTorch, used for local RAG embeddings and reranking, comes CPU-only: the default CUDA
    # wheels would add ~4 GB. Data goes to $DATA_DIR (set to ~/.open-webui by llm.docker).
    goodecho "[+] Installing Open WebUI"
    if ! command -v uv > /dev/null; then
        record_build_failure "toolchain" "open-webui" "uv unavailable"
        return 0
    fi
    install_dependencies "ffmpeg"   # pydub, for speech-to-text uploads
    if ! installfromnet uv tool install --force --no-cache --python 3.11 --torch-backend cpu open-webui; then
        record_build_failure "pip" "open-webui" "uv tool install failed"
        return 0
    fi
    [ -e "$HOME/.local/bin/open-webui" ] && ln -sf "$HOME/.local/bin/open-webui" /usr/local/bin/open-webui
    open-webui --help > /dev/null || record_build_failure "other" "open-webui" "open-webui does not run after install"
}
