# RF Swift `llm` image

Coding agents, shared skill packs, agent-side reverse-engineering tools, local speech-to-text
(whisper.cpp) and a web chat UI (Open WebUI), on top of `corebuild`. Built for amd64 and arm64
(Claude Code, Codex and OpenCode ship no riscv64 build). In the image this file is `/opt/llm/README.md`.

| Tool | Command | Installed from | Its own config |
|---|---|---|---|
| Claude Code | `claude` | npm `@anthropic-ai/claude-code` | `~/.claude/`, `~/.claude.json` |
| OpenAI Codex | `codex` | npm `@openai/codex` | `~/.codex/` |
| OpenCode 2.x | `opencode` | npm `@opencode/cli` | `~/.config/opencode/` |
| Mistral Vibe | `vibe` | PyPI `mistral-vibe` (uv tool) | `~/.vibe/` |
| Hermes Agent (Nous Research) | `hermes` | official installer | `~/.hermes/` |
| REA, Reverse Engineer Anything | `rea` (MCP server `rea mcp`) | npm `rea-agents` | registered in each agent |
| Craft Anything | `craft-anything`, `craft-anything-cli` (MCP server `craft-anything-cli mcp`) | GitHub release, `/opt/craft-anything` | `craft-anything-cli ai list` |
| Skill packs | `llm-skills` | git, `/opt/llm-skills/src` | `~/.agents/skills`, `~/.claude/skills` |
| whisper.cpp | `whisper-cli`, `whisper-server`, `whisper-stream`, `whisper-download-model` | source, `/opt/whisper.cpp` | models in `/opt/whisper.cpp/models` |
| Open WebUI | `open-webui serve` | PyPI `open-webui` (uv tool, Python 3.11) | `~/.open-webui/` (`$DATA_DIR`) |
| NodeTerm (Server Edition) | `nodeterm-server` | source, `/opt/nodeterm` | `~/.nodeterm-server/` |
| Strix (AI pentest agent) | `strix` | PyPI `strix-agent` (uv tool, Python 3.12) | `~/.strix/` |
| Semgrep | `semgrep` | PyPI `semgrep` | `~/.semgrep/` |

Node.js 24 LTS is in `/usr/local` (Ubuntu's 22.22 is too old for REA).

## Keep your sign-ins

Credentials live in the container's home directory. Mount them from the host, or they are gone
with the container:

```sh
docker run -it --rm \
  -v ~/.rfswift-llm/claude:/root/.claude -v ~/.rfswift-llm/codex:/root/.codex \
  -v ~/.rfswift-llm/opencode-data:/root/.local/share/opencode \
  -v ~/.rfswift-llm/vibe:/root/.vibe -v ~/.rfswift-llm/hermes:/root/.hermes \
  -v ~/.rfswift-llm/open-webui:/root/.open-webui -v ~/.rfswift-llm/hf-cache:/root/.cache/huggingface \
  -v ~/.rfswift-llm/nodeterm:/root/.nodeterm-server \
  -v ~/.rfswift-llm/whisper-models:/root/whisper-models \
  -v "$PWD:/work" -w /work \
  penthertz/rfswift_resolute:llm_amd64
```

Mounting a directory over `~/.claude`, `~/.vibe` or `~/.hermes` hides what the image put there
(enabled skills, MCP registrations). Start from a copy instead (`docker cp` the directory out of
a fresh container once), or rerun the setup steps below after the first start.

## First run: sign in

| Agent | Sign in | API key instead |
|---|---|---|
| Claude Code | `claude`, then `/login` | `ANTHROPIC_API_KEY` |
| Codex | `codex login` | `OPENAI_API_KEY` |
| OpenCode | `opencode auth login` (any provider: Anthropic, OpenAI, Mistral, OpenRouter, local...) | provider variables |
| Mistral Vibe | `vibe --setup` | `MISTRAL_API_KEY` |
| Hermes | `hermes setup` (the build skipped it) | asked by `hermes setup` |

## Skills

Every agent reads the same skills. They come from six packs:

| Pack | Skills | Enabled by default |
|---|---:|---|
| `trailofbits` ([trailofbits/skills](https://github.com/trailofbits/skills)): audits, static analysis, fuzzing, crypto, smart contracts | 96 | yes |
| `farmage` ([farmage/opencode-skills](https://github.com/farmage/opencode-skills)): language/framework experts, code review, testing | 67 | yes |
| `floorplan` ([haydenschmitty/floorplan](https://github.com/haydenschmitty/floorplan)): interactive architecture map of a codebase | 1 | yes |
| `cybersecurity` ([mukul975/Anthropic-Cybersecurity-Skills](https://github.com/mukul975/Anthropic-Cybersecurity-Skills), the skills-hub.ai "Cybersecurity Skills" source): pentest, red team, DFIR, malware, threat intel, cloud/AD/ICS | 818 | through one index skill |
| `cloudflare` ([cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill)): source-first security audit workflow with findings/coverage validators (Node.js) | 1 | yes |
| `strix` ([usestrix/strix](https://github.com/usestrix/strix)): drive the `strix` CLI for web/API/code pentests, OWASP Top 10, CI scans | 9 | yes |
| `artex` ([BaaRai/ARTEX](https://github.com/BaaRai/ARTEX)): web/API recon and audit playbooks (api-recon, api-security, codeaudit, patch-diff, php2shell, edr-bypass-re, bbot-recon, playwright-cli, rea, scopesentry) | 10 | yes |

Some `artex` skills drive tools that ship in the separate ARTEX image rather than here
(`bbot-recon` needs bbot/subfinder/httpx, `playwright-cli` needs the Playwright browsers,
`scopesentry` needs the ScopeSentry MCP), and `rea` overlaps the REA MCP server already
installed in this image; the recon/audit playbooks (`api-recon`, `api-security`, `codeaudit`,
`patch-diff`, `php2shell`, `edr-bypass-re`) are the ones that stand on their own here.

Agents send the name and description of every enabled skill to the model on each turn. The
default set costs about 20K tokens; all 818 cybersecurity skills would add about 80K. So that
pack is represented by a single `cybersecurity-skills` index skill: the agent runs
`llm-skills search <words>` and reads the matching `SKILL.md`. Register the ones you use
natively when you want them offered automatically:

```sh
llm-skills status                                   # what is enabled, and its cost per turn
llm-skills list                                     # packs and counts
llm-skills list cybersecurity                       # ids and subdomains of one pack
llm-skills search kerberos delegation               # search every pack, enabled or not
llm-skills enable cybersecurity:web-application-security   # a subdomain, tag or id fragment
llm-skills enable --project cybersecurity:forensics # only for the project in the current folder
llm-skills disable farmage                          # a whole pack
llm-skills update                                   # git pull every pack and re-render
```

Where they land:

- `~/.agents/skills/<id>`: read by OpenCode, Codex, Mistral Vibe and Hermes
  (`skills.external_dirs` in `~/.hermes/config.yaml`).
- `~/.claude/skills/<id>`: read by Claude Code. OpenCode reads it too and keeps one copy per id.
- `--project` uses `./.agents/skills` and `./.claude/skills` instead.

REA and Craft Anything install their own skill next to these (`reverse-engineer-anything`,
`craft-anything`, real folders that `llm-skills` leaves alone; `rea setup` and
`craft-anything-cli setup` refresh them).

Each entry is a symlink to `/opt/llm-skills/rendered/<id>`, a copy of the skill whose
Claude-only placeholders (`{baseDir}`, `${CLAUDE_SKILL_DIR}`, `${CLAUDE_PLUGIN_ROOT}`) are
replaced by absolute paths, so scripts and references resolve in every agent. A skill of your
own with the same name is never overwritten. New skills show up in a new session.

Trail of Bits is also registered as a plugin marketplace in Claude Code and Codex, for the
commands, agents and hooks some plugins add on top of their skills:
`/plugin install <name>@trailofbits` in Claude Code, `codex plugin add <name>@trailofbits`.
The plugin's skills then appear twice (`<plugin>:<skill>` and the plain one); disable the plain
one with `llm-skills disable <id>` if that bothers you.

## Strix

Strix starts one sandbox container per scan, so it needs a Docker daemon: run the image with
`-v /var/run/docker.sock:/var/run/docker.sock` (this gives the container control of the host's
Docker). Point it at a model, then a target you are authorized to test:

```sh
export STRIX_LLM="anthropic/claude-sonnet-5-5" LLM_API_KEY=...
strix --target ./app                 # a local codebase
strix --target https://staging.example.test
```

The `strix` skills let any agent above run and triage Strix scans for you.

## OpenCode

### Skills

Nothing to configure: OpenCode 2 finds every enabled skill in `~/.agents/skills` and
`~/.claude/skills`, lists them to the model, and the model loads one with its `skill` tool when
a request matches its description. To force one, mention it in the prompt: `@semgrep`,
`@floorplan`, `@cybersecurity-skills`. Skills from a project's `.opencode/skills`,
`.agents/skills` or `.claude/skills` are added on top and win on a name clash.

farmage's workflow commands are installed in `~/.config/opencode/commands`: `/common-ground`,
`/discovery/create`, `/planning/epic-plan`, `/execution/execute-ticket`... They expect the
Atlassian MCP server (Jira, Confluence), which you add yourself.

### MCP servers (REA, Craft Anything)

The build registered both in `~/.config/opencode/opencode.json`. Check them with:

```sh
opencode mcp list
```

It asks OpenCode's background server, which starts the servers on first use: right after a
fresh start it can print `No MCP servers configured`. Run it again after ~20 s and both show
`✓ connected`.

MCP tools cost context on every turn too. Turn one off for a while with `"disabled": true` on
its entry (V2 format, under `mcp.servers.<name>`) or in the `/mcps` menu.

### REA from OpenCode

Ask in plain words; OpenCode calls REA's tools:

> Using REA, explain how the update check works in /work/app.AppImage and show the evidence.

> Analyze the Electron app in /work/notes.asar: how does it store the vault key?

Static JavaScript/Electron/website analysis works out of the box. For native binaries REA needs
an engine: Ghidra (`reversing` image, or install it here), Hopper (`rea setup --yes --install-hopper`),
IDA or Kuna. `rea doctor` says what is missing.

### Craft Anything from OpenCode

Two directions:

1. **OpenCode uses Craft's tools** (MCP server `craft-anything`): "study https://example.com
   with craft-anything and list its pages and components". Craft starts with a small toolset and
   enables more (`enable_toolset`) when the model needs them.
2. **Craft uses OpenCode as its builder.** The build added an `OpenCode` backend next to the
   default Claude Code one. Pick a model, then rebuild:

   ```sh
   craft-anything-cli ai model OpenCode                       # list the models OpenCode offers
   craft-anything-cli ai model OpenCode <provider>/<model> --thinking high   # an id from that list
   craft-anything-cli rebuild https://example.com "Recreate this website"
   ```

   Make it the builder with `craft-anything-cli ai builder OpenCode` (or Settings → AI in the app;
   `craft-anything-cli ai builder` alone goes back to automatic). Don't open another OpenCode session while a build runs:
   OpenCode's shared service would resume the build's session. The desktop app (`craft-anything`)
   needs the X11 display of the RF Swift container.

### Floorplan from OpenCode

Floorplan is a skill, so in OpenCode just ask:

> Make me a floorplan of this app.

OpenCode loads the `floorplan` skill; the scripts scan the code, the model writes the
descriptions, and the map is written to `floorplan/index.html` and served at
http://127.0.0.1:4378 (open it with Firefox in the container, or publish the port).
"Update the floorplan" re-reads only what changed. "Here's my PRD, make me a floorplan of what
we'd need to build" draws a blueprint.

The map's **Ask bar** answers through the Claude Code or Codex CLI only (it runs
`claude -p` or `codex exec` on your sign-in). Both are in the image: sign one of them in and the
Ask bar works; force one with `node floorplan/serve.mjs --engine codex`. Without either, ask
OpenCode itself: it can query the map with `node floorplan/query.mjs` and read the code.

## whisper.cpp (speech-to-text)

A CPU build of [whisper.cpp](https://github.com/ggml-org/whisper.cpp) (portable: AVX2 baseline on
amd64). The image holds no model; fetch one first:

```sh
whisper-download-model base.en                   # into /opt/whisper.cpp/models
whisper-download-model small /root/whisper-models   # or a mounted folder (see above)
whisper-download-model                           # list: tiny, base, small, medium, large-v3-turbo, -q5_0...
```

`.en` models are English-only and better at it; the others do 99 languages (`-l auto` or `-l fr`).

```sh
whisper-cli -m /opt/whisper.cpp/models/ggml-base.en.bin -f recording.wav        # wav, mp3, flac, ogg
whisper-cli -m /opt/whisper.cpp/models/ggml-base.en.bin -f recording.wav -osrt  # + subtitles file
whisper-stream -m /opt/whisper.cpp/models/ggml-base.en.bin                       # live, from the microphone
```

`whisper-stream` needs the container's audio (RF Swift's PulseAudio sharing). For audio coming out
of an SDR app, record it to a file first, or let an agent do it: "transcribe the voice in
/work/capture.wav with whisper-cli" works in any of the agents.

`whisper-server` serves the same model over HTTP. With these options it speaks OpenAI's
transcription API (Open WebUI and other clients can use it) and accepts any format ffmpeg reads:

```sh
whisper-server -m /opt/whisper.cpp/models/ggml-base.en.bin --port 8178 \
  --inference-path /v1/audio/transcriptions --convert
curl -F file=@recording.wav -F model=whisper-1 http://127.0.0.1:8178/v1/audio/transcriptions
```

## Open WebUI

[Open WebUI](https://openwebui.com) is a ChatGPT-style web interface for any model API. It runs on
its own Python 3.11 (Open WebUI does not support Ubuntu's 3.14), installed with
`uv tool install --python 3.11 open-webui`; PyTorch, used for document search, is the CPU build.

```sh
open-webui serve                 # http://127.0.0.1:8080, `--port` to change it
```

The first account you create is the administrator. Chats, users and settings go to
`~/.open-webui` (`DATA_DIR`); mount it to keep them (see above).

The first start downloads Open WebUI's document-search embedding model from Hugging Face
(`all-MiniLM-L6-v2`, about 1 GB with all its formats) into `~/.cache/huggingface`; mount that
folder too, or it is downloaded again in every new container. `OFFLINE_MODE=true open-webui serve`
skips the download and starts in seconds; chats and speech-to-text work, document search does
not.

The image runs no model itself. Add one under **Admin Panel → Settings → Connections**:

- **OpenAI API**: OpenAI, or any OpenAI-compatible endpoint with its key, such as Mistral
  (`https://api.mistral.ai/v1`), OpenRouter (`https://openrouter.ai/api/v1`) or a llama.cpp/vLLM
  server.
- **Ollama**: an Ollama running on the host, `http://<host-ip>:11434` (or `http://127.0.0.1:11434`
  with host networking).

The same can be set for the first start only with environment variables (`OPENAI_API_BASE_URL`,
`OPENAI_API_KEY`, `OLLAMA_BASE_URL`); after that the admin settings win.

### Speech-to-text through whisper.cpp

The microphone button in a chat uses Open WebUI's own Whisper unless told otherwise. To use
whisper.cpp instead, start `whisper-server` as above, then in **Admin Panel → Settings → Audio**
set Speech-to-Text engine **OpenAI**, API base URL `http://127.0.0.1:8178/v1`, any key, model
`whisper-1`. Or on the first start:

```sh
AUDIO_STT_ENGINE=openai AUDIO_STT_OPENAI_API_BASE_URL=http://127.0.0.1:8178/v1 \
AUDIO_STT_OPENAI_API_KEY=none AUDIO_STT_MODEL=whisper-1 open-webui serve
```

The browser only gives the microphone to `http://127.0.0.1`/`localhost` or HTTPS pages.

## NodeTerm (Server Edition)

[NodeTerm](https://nodeterm.dev) is a node-based terminal manager for coding agents: terminals and
agents sit as draggable nodes on an infinite canvas, each in a persistent tmux session. The desktop
app is x86_64-only, so the image installs the **Server Edition** — the same canvas served in a
browser by a headless Node server — which builds on amd64 and arm64.

```sh
nodeterm-server                  # http://127.0.0.1:8443
```

The first run prints a one-time setup URL on stdout; open it and choose a password (min 8 chars).
For an unattended start, seed it instead:

```sh
NODETERM_SERVER_PASSWORD='choose-a-strong-one' nodeterm-server
```

It binds `127.0.0.1:8443` by default — publish or forward that port to reach it from the host
(`-p 127.0.0.1:8443:8443`). To bind a non-loopback interface, set `NODETERM_HOST=0.0.0.0` and pass
`--insecure-http` (plain HTTP is refused off loopback otherwise; the intended public setup is behind
a TLS-terminating reverse proxy). Auth, sessions, workspace and scrollback live in
`~/.nodeterm-server` (`NODETERM_DATA_DIR`); mount it to keep them (see above). The tmux server runs
inside the container, so a container restart ends the live sessions; scrollback and resumable agents
are restored from the data directory on the next attach.

> Licensed BUSL-1.1 (each release converts to MIT four years after publication): internal and
> non-competing use is permitted; offering it as a competing hosted product/service is not.

## Updating

```sh
npm update -g @anthropic-ai/claude-code @openai/codex @opencode/cli rea-agents
uv tool upgrade mistral-vibe
uv tool install --force --python 3.11 --torch-backend cpu open-webui
hermes update
llm-skills update
```

Open WebUI is reinstalled rather than upgraded: uv does not save `--torch-backend cpu`, so
`uv tool upgrade open-webui` could swap in the CUDA build of PyTorch (about 4 GB more).

Craft Anything and whisper.cpp are pinned (`CRAFT_VERSION`, `WHISPERCPP_VERSION` in
`scripts/llm_software.sh`); the image rebuild picks up a new release once that is bumped.
