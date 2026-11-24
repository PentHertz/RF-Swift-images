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
| Vulnhuntr (Protect AI) | `vulnhuntr` | `protectai/vulnhuntr`, latest main (uv tool, Python 3.10) | API keys from the environment |
| CodeGraph | `codegraph` (MCP server `codegraph serve --mcp`) | npm `@colbymchenry/codegraph` | per project: `.codegraph/` |
| pentest-ai | `ptai`, `ptai-aup` (MCP server `ptai-mcp`, i.e. `ptai mcp`) | PyPI `ptai` (uv tool, Python 3.12) | `~/.pentest-ai/` |
| ARTEMIS (multi-agent red teaming, **opt-in**) | `artemis-redteam` | Stanford-Trinity/ARTEMIS @ reviewed commit (Codex fork from source, uv Python 3.12) | `~/.artemis-redteam/` |
| LangGraph (agent framework, **opt-in**) | `langgraph`, `langgraph-python` | PyPI `langgraph`, `langgraph-cli[inmem]`, `langchain-anthropic`, `langchain-openai`, `langchain-mcp-adapters` (venv `/opt/langgraph`) | per project |
| Cairn (fact-graph pentest engine, **opt-in**) | `cairn` (`cairn serve`, `cairn dispatch`) | `oritera/Cairn`, latest main, `/opt/cairn` (uv project, Python 3.13) | `~/.local/share/cairn/`, `~/.config/cairn/dispatch.yaml` |
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

Every agent reads the same skills. They come from these packs:

| Pack | Skills | Enabled by default |
|---|---:|---|
| `trailofbits` ([trailofbits/skills](https://github.com/trailofbits/skills)): audits, static analysis, fuzzing, crypto, smart contracts | 96 | yes |
| `farmage` ([farmage/opencode-skills](https://github.com/farmage/opencode-skills)): language/framework experts, code review, testing | 67 | yes |
| `floorplan` ([haydenschmitty/floorplan](https://github.com/haydenschmitty/floorplan)): interactive architecture map of a codebase | 1 | yes |
| `cybersecurity` ([mukul975/Anthropic-Cybersecurity-Skills](https://github.com/mukul975/Anthropic-Cybersecurity-Skills), the skills-hub.ai "Cybersecurity Skills" source): pentest, red team, DFIR, malware, threat intel, cloud/AD/ICS | 818 | through one index skill |
| `cloudflare` ([cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill)): source-first security audit workflow with findings/coverage validators (Node.js) | 1 | yes |
| `strix` ([usestrix/strix](https://github.com/usestrix/strix)): drive the `strix` CLI for web/API/code pentests, OWASP Top 10, CI scans | 9 | yes |
| `artex` ([BaaRai/ARTEX](https://github.com/BaaRai/ARTEX)): web/API recon and audit playbooks (api-recon, api-security, codeaudit, patch-diff, php2shell, edr-bypass-re, bbot-recon, playwright-cli, rea, scopesentry) | 10 | yes |
| `ponytail` ([DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)): write only what the task needs (reuse what exists, never cut validation, error handling or security), plus `/ponytail-review` and `/ponytail-audit` | 6 | no |
| `caveman` ([JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)): terser answers (`/caveman`, `/ultracave`) and focused workflow skills (review, commit, surgical-patch, safe-refactor, verify-and-stop...) | 16 | no |
| `decepticon` ([BitterSecurity/Decepticon](https://github.com/BitterSecurity/Decepticon), formerly PurpleAILAB): offensive playbooks by category (IoT and sub-GHz/BLE/Zigbee/Z-Wave/LoRaWAN, Wi-Fi, ICS/OT protocols, web/API, AD, cloud, post-exploitation and C2, reversing, mobile, smart contracts, phishing, LLM red teaming, APT emulation) | 297 | IoT, wireless and ICS/OT (34), the rest through one index skill |

Some `artex` skills drive tools that ship in the separate ARTEX image rather than here
(`bbot-recon` needs bbot/subfinder/httpx, `playwright-cli` needs the Playwright browsers,
`scopesentry` needs the ScopeSentry MCP), and `rea` overlaps the REA MCP server already
installed in this image; the recon/audit playbooks (`api-recon`, `api-security`, `codeaudit`,
`patch-diff`, `php2shell`, `edr-bypass-re`) are the ones that stand on their own here.

`ponytail` and `caveman` are **opt-in**: `llm-skills enable ponytail` or `llm-skills enable caveman`.
They change how every agent answers or writes code, and add their descriptions to every turn.
Only caveman's skills are included. Its CLI, local proxy and browser extension are not installed,
and the skills that drive the Caveman Cloud service (`caveman-setup`, which reroutes an
application's LLM calls through the Caveman gateway, `-discover`, `-evidence-review`, `-manage`,
`-optimize` and `-learn`) are left out of the pack.

Agents send the name and description of every enabled skill to the model on each turn. The
default set costs about 20K tokens; all 818 cybersecurity skills would add about 80K. So that
pack is represented by a single `cybersecurity-skills` index skill (Decepticon likewise by
`decepticon-skills`): the agent runs `llm-skills search <words>` and reads the matching
`SKILL.md`. Register the ones you use natively when you want them offered automatically:

```sh
llm-skills status                                   # what is enabled, and its cost per turn
llm-skills list                                     # packs and counts
llm-skills list cybersecurity                       # ids and subdomains of one pack
llm-skills search kerberos delegation               # search every pack, enabled or not
llm-skills enable cybersecurity:web-application-security   # a subdomain, tag or id fragment
llm-skills enable --project cybersecurity:forensics # only for the project in the current folder
llm-skills search --pack decepticon flipper         # one pack; keywords and tags count too
llm-skills enable decepticon:active-directory       # a Decepticon category
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

### Decepticon

Only Decepticon's skills tree is fetched: a sparse, blobless checkout of
`packages/decepticon/decepticon/skills` (about 14 MB instead of the 90 MB repository), which
`llm-skills update` pulls like the other packs. Decepticon itself (its agents, sandbox and web UI)
is not installed. Of its 329 skills, 297 are kept. Left out as platform-internal: the CTF benchmark
marker, the role prompts of its vulnerability-research pipeline (`plugins/scanner`, `detector`,
`verifier`, `patcher`, `exploiter`, `vulnresearch`), its orchestrator skills (`standard/decepticon`),
its planning agent's templates (`standard/soundwave`), its finding workflow (`finding-protocol`,
`finding_reporter`) and the reference catalogue its tools serve (`shared/references`).

- **What is enabled.** The IoT, wireless and ICS/OT skills are enabled
  (`decepticon:iot`, `decepticon:wireless`, `decepticon:ics-ot` and `ics-overview`: 34 skills,
  about 2K tokens per turn). The other ~260 (about 14K tokens if all were enabled) are reached
  through the `decepticon-skills` index skill, which lists each category and its overview skill,
  and through `llm-skills search --pack decepticon <words>`. Enable a category with
  `llm-skills enable decepticon:<keyword>`.
- **Ids and links.** A skill's id is its frontmatter `name`. Upstream keeps names unique, and
  several directory names repeat (`specialist-methods` sixteen times). A name already used by an
  earlier pack is renamed `decepticon-<name>`, with its `name` rewritten to match; `render` prints
  each rename. There is no clash today. Decepticon's in-sandbox paths (`/skills/standard/...`) are
  rewritten to the local copies, so category overviews link to the rendered skills. A category's
  sub-skills are not linked inside its folder, so an agent never sees them twice.
- **Platform note.** Many skills call Decepticon's own tools: its knowledge graph (`kg_add_node`,
  `kg_query`...), its sandbox shell (`bash(command=..., session=...)`), finding validators,
  `load_skill`, and the hosted run's C2, Ghidra and REA bridges. Those tools do not exist here. In
  the skills that reference one (88 at the current upstream commit), `render` inserts a short note
  after the frontmatter. The note names the tools and says what to do instead: run the commands
  directly, use tmux for persistent sessions, and record results with your own notes and findings
  tools (for example the RF Swift Workbench MCP tools `write_note`, `save_finding` and
  `save_secret` when they are connected). Apart from that note, the rewritten paths and a renamed
  `name`, upstream's text is unchanged.
- The sub-GHz playbook expects radio hardware (HackRF, Flipper Zero, RTL-SDR, YARD Stick One) and
  tools (`rfcat`, URH, `rtl_433`, `inspectrum`) that are in the RF Swift SDR images (`sdr_light`
  and up), not in `llm`.

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

## CodeGraph

[CodeGraph](https://github.com/colbymchenry/codegraph) keeps a pre-indexed knowledge graph
of a code base: symbols, calls and imports. The agents query it over MCP instead of reading files
one by one, which means fewer tokens and fewer tool calls. The image already registers it with
Claude Code, Codex, OpenCode and Hermes (Mistral Vibe is not supported). Index each project once:

```sh
cd /work/my-project
codegraph init        # builds .codegraph/ for this project; the agents then use it
codegraph status      # index state
```

Things to know:

- **Telemetry and update check are off.** The image sets `CODEGRAPH_TELEMETRY=0` and
  `CODEGRAPH_NO_UPDATE_CHECK=1`, and the build also stores the telemetry opt-out. Set
  `CODEGRAPH_TELEMETRY=1` to opt in; `codegraph telemetry status` shows the state.
- **Nothing is downloaded at run time.** Its platform build (`@colbymchenry/codegraph-linux-<arch>`,
  about 300 MB with its own Node runtime) is installed by npm with the package.
  `CODEGRAPH_NO_DOWNLOAD=1` stops its fallback that would fetch a bundle from GitHub.
- **Version:** builds take the newest release. `CODEGRAPH_REVIEWED_VERSION` in
  `scripts/llm_software.sh` is the last version that was reviewed, and a newer build adds a
  `review` entry to the build report.
- **Instructions file:** `codegraph install` adds a marked CodeGraph section to each agent's
  instructions file (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, ...). `codegraph uninstall --yes`
  removes it, along with the MCP entries.

## Vulnhuntr

[Vulnhuntr](https://github.com/protectai/vulnhuntr) (Protect AI, AGPL-3.0) uses an LLM to find
remotely exploitable vulnerabilities in **Python** projects. It follows call chains from user
input to dangerous sinks (RCE, SQLi, SSRF, XSS, LFI, AFO, IDOR) and reports each finding with a
proof-of-concept. Point it at a project, or narrow it to the files that handle user input:

```sh
export ANTHROPIC_API_KEY=...
vulnhuntr -r /path/to/project                 # the whole project
vulnhuntr -r /path/to/project -a server.py    # one file or subdirectory
vulnhuntr -r /path/to/project -l gpt          # OpenAI instead (OPENAI_API_KEY, OPENAI_MODEL)
```

Things to know:

- **Model:** the `vulnhuntr` command defaults to `ANTHROPIC_MODEL=claude-opus-4-5`.
  - Vulnhuntr pre-fills the start of Claude's reply on every call. Current Claude models (4.6
    and later) reject that with a 400.
  - Its own default, `claude-3-5-sonnet-latest`, is retired.
  - Claude Opus 4.5 is the newest model that accepts prefill. Set `ANTHROPIC_MODEL` to change it,
    but keep to a model that accepts prefill (for example `claude-haiku-4-5`).
- **Source:** it is installed from `github.com/protectai/vulnhuntr` itself. The PyPI project named
  `vulnhuntr` is a third-party fork, not Protect AI's.
- **Version:** builds take the latest upstream commit. `VULNHUNTR_REVIEWED_COMMIT` in
  `scripts/llm_software.sh` records the last commit that was reviewed. A build on a newer commit
  adds a `review` entry to the build report.
- **Packaging fix:** the install adds `requests`, which upstream imports but does not declare.

## pentest-ai

[pentest-ai](https://github.com/0xSteph/pentest-ai) (0xSteph; PyPI `ptai`) is an
offensive-security MCP server: wrapped scanners, specialist agents, and probes that re-run each
exploit before reporting a finding. The image installs it with uv on Python 3.12 (upstream suggests
pipx) and registers it, as `pentest-ai`, with Claude Code, Codex, OpenCode, Mistral Vibe and Hermes.

**Accept its Acceptable Use Policy first.** The image does not accept it for you. Run this once,
as the operator, in a terminal:

```sh
ptai-aup          # pentest-ai's own prompt: you have written authorization for every target, and accept the AUP and Terms
```

Answering `yes` writes `~/.pentest-ai/aup-consent.txt`. Mount `~/.pentest-ai` to keep it, along
with pentest-ai's findings database. `rm ~/.pentest-ai/aup-consent.txt` revokes it. Upstream asks
only in `ptai start`; its MCP tools never ask. So the agents start the server through `ptai-mcp`,
which runs upstream's `ptai mcp` (stdio) only once that file exists. Until then an agent shows the
server as failed, and you restart the agent after accepting. `PENTEST_AI_AUP_ACCEPTED=1` is
pentest-ai's own switch for scripts. Set it only if you accept the AUP that way; the image never
sets it.

Then ask an agent, for an authorized target: "with pentest-ai, start an engagement against
https://staging.example.test, scope web". Or use the CLI directly:

```sh
ptai doctor                       # what it finds on this machine
ptai setup --list                 # external tools it can drive, installed or missing
ptai start https://staging.example.test --scope web
ptai setup --mcp --dry-run        # what upstream's own MCP setup would write (the build did it already)
```

Things to know:

- **MCP entry:** `ptai-mcp` everywhere. It is the command `ptai setup --mcp` registers
  (`claude mcp add --scope user --transport stdio pentest-ai -- ptai mcp`, the same with
  `codex mcp add`), behind the AUP check. OpenCode gets `mcp.servers.pentest-ai` in
  `~/.config/opencode/opencode.json` and Hermes `mcp_servers.pentest-ai` in `~/.hermes/config.yaml`.
  Upstream's setup knows neither of them.
- **Nothing goes home.** Upstream telemetry is opt-in, and the image also sets
  `PENTEST_AI_TELEMETRY=0`. The PyPI "update available" check of `ptai start` / `ptai doctor` is off
  (`PTAI_SKIP_VERSION_CHECK=1`). Scan traffic carries a `pentest-ai/<version> (rv:<install id>)`
  User-Agent; the id is generated per container, never at build time.
- **Version:** builds take the newest PyPI release. `PENTESTAI_REVIEWED_VERSION` in
  `scripts/llm_software.sh` is the last one read for this install, and a newer build adds a `review`
  entry to the build report.

## ARTEMIS (opt-in)

[ARTEMIS](https://github.com/Stanford-Trinity/ARTEMIS) (Stanford Trinity, Apache-2.0) is an
autonomous multi-agent red-teaming engine. A Python supervisor runs several sub-agents in
parallel over a long engagement and triages what they find. The sub-agents are its own fork
of the Codex CLI. It is installed as **`artemis-redteam`**. This is not the AresValley
**Artemis** signal-identification app in the SDR images, which stays `Artemis`.

It is **not in the default build**, because the Codex fork takes a long Rust build. Enable it
by uncommenting `artemis_redteam_soft_install` in `Dockerfiles/llm.docker`, or install it in
a running container:

```sh
cd /root/scripts && ./entrypoint.sh artemis_redteam_soft_install
```

Give it a model through OpenRouter (or OpenAI), then try upstream's 10-minute smoke test
against its bundled easy CTF:

```sh
export OPENROUTER_API_KEY=... SUBAGENT_MODEL="anthropic/claude-sonnet-5-5"
cd /opt/artemis-redteam
artemis-redteam --config-file configs/tests/ctf_easy.yaml --benchmark-mode --duration 10 --skip-todos
```

Things to know:

- **Authorized targets only.** Its sub-agents run commands **inside this container**. Unlike
  Strix, there is no separate sandbox container.
- **Logs and keys:** logs go to `./logs` under the directory you run it from. Keys can also
  go in `/opt/artemis-redteam/.env`. Exported variables take precedence.
- **Isolated from the real Codex:** the fork is not on `PATH` (it would shadow the real Codex
  CLI) and uses its own `CODEX_HOME` (`/root/.artemis-redteam/codex`, override with
  `ARTEMIS_CODEX_HOME`). It never reads or changes `~/.codex`.
- **Pinned commit:** upstream publishes no releases, so the install is pinned to a reviewed
  commit (`ARTEMIS_REDTEAM_COMMIT` in `scripts/llm_software.sh`). Re-review the diff before
  bumping it, using the checklist in `docs/network-exploit-pocs.md`.
- `test_files/` contains upstream's CTF challenge samples. Some are deliberately malicious
  scripts for the agent to *analyze* (one adds a cron job if run). Nothing executes them at
  install. Don't run them by hand outside a throwaway container.

## LangGraph (opt-in)

[LangGraph](https://github.com/langchain-ai/langgraph) (LangChain) is a library for writing
**your own** agents. You describe a workflow as a graph of LLM calls and tools, with saved state
and points where a human approves the next step. Unlike the agents above, it does nothing until
you write code with it, so it is not built by default. Install it in a running container:

```sh
cd /root/scripts && ./entrypoint.sh langgraph_soft_install    # about 190 MB, /opt/langgraph
```

That gives you `langgraph-python` (the environment's Python) and `langgraph` (the CLI with a local
API server). The environment has `langgraph`, `langchain-anthropic`, `langchain-openai` and
`langchain-mcp-adapters`, so a graph can use the MCP servers this image ships as tools.

**Nothing goes to LangChain by default.** Upstream turns on three calls home; this image turns
them off in `llm.docker`, and the wrappers set the same values when they are not already set:

| What | Upstream default | Here | To opt in |
|------|------------------|------|-----------|
| CLI usage analytics (every `langgraph` command, to LangChain's Supabase) | on | `LANGGRAPH_CLI_NO_ANALYTICS=1` | `LANGGRAPH_CLI_NO_ANALYTICS=0` |
| Dev server version check | on | `LANGGRAPH_NO_VERSION_CHECK=true` | unset it |
| LangSmith tracing (uploads every prompt and tool result) | on once a LangSmith key is set | `LANGSMITH_TRACING=false` | `LANGSMITH_TRACING=true` plus `LANGSMITH_API_KEY` |

A minimal agent with one local tool. Claude calls `file_type` until it can answer:

```python
# triage.py: a minimal LangGraph agent with one local tool.
# Run with: langgraph-python triage.py   (needs ANTHROPIC_API_KEY)
import subprocess

from langchain_anthropic import ChatAnthropic
from langchain_core.tools import tool
from langgraph.graph import START, MessagesState, StateGraph
from langgraph.prebuilt import ToolNode, tools_condition


@tool
def file_type(path: str) -> str:
    """Identify a file's type with the `file` command (following symlinks)."""
    return subprocess.run(["file", "-bL", path], capture_output=True, text=True).stdout


tools = [file_type]
model = ChatAnthropic(model="claude-opus-5-5").bind_tools(tools)


def agent(state: MessagesState):
    return {"messages": [model.invoke(state["messages"])]}


graph = StateGraph(MessagesState)
graph.add_node("agent", agent)
graph.add_node("tools", ToolNode(tools))
graph.add_edge(START, "agent")
graph.add_conditional_edges("agent", tools_condition)  # a tool call goes to "tools", otherwise end
graph.add_edge("tools", "agent")
app = graph.compile()

if __name__ == "__main__":
    out = app.invoke({"messages": [("user", "What kind of file is /bin/ls?")]})
    print(out["messages"][-1].content)
```

```sh
export ANTHROPIC_API_KEY=...
langgraph-python triage.py
```

Use the image's MCP servers as tools. For example, CodeGraph, from a project you indexed with
`codegraph init`:

```python
import asyncio
from langchain_mcp_adapters.client import MultiServerMCPClient

async def main():
    client = MultiServerMCPClient({
        "codegraph": {"command": "codegraph", "args": ["serve", "--mcp"], "transport": "stdio"},
    })
    tools = await client.get_tools()   # LangChain tools: pass them to bind_tools() and ToolNode()
    print([t.name for t in tools])

asyncio.run(main())
```

**Local API server.** Put a `langgraph.json` next to your graph (the `__main__` guard above keeps the
server from running the example when it loads the file), for example
`{"dependencies": ["."], "graphs": {"triage": "./triage.py:app"}}`, then:

```sh
langgraph dev --no-browser          # API on http://127.0.0.1:2024 (POST /runs/wait, /threads, ...)
```

The "Studio UI" link it prints is a page on smith.langchain.com that your browser loads and points
at the local server. The page comes from LangChain and your graph's data passes through it in the
browser. Leave it closed and use the REST API if that matters for the engagement.

## Cairn (opt-in)

[Cairn](https://github.com/oritera/Cairn) (oritera) solves a problem by searching
from an origin (a target) to a goal (a shell, a flag). A server keeps the graph of confirmed facts
and planned intents, and a dispatcher runs agent CLIs that read the whole graph, decide what to
explore next and write back what they found. You can add hints at any time. Its authors validated
it on AI penetration testing. It is **not in the default build**; install it in a running
container:

```sh
cd /root/scripts && ./entrypoint.sh cairn_soft_install
```

It is cloned from upstream into `/opt/cairn` (latest `main`) and set up as its own uv project.
Nothing of Cairn is copied into RF Swift. Its dependencies are the exact versions and SHA-256 hashes
of upstream's `uv.lock`. That lock points at a PyPI mirror (`mirrors.aliyun.com`), so the same
files are fetched from PyPI and checked against those hashes.

The image uses Cairn's **local mode**: the workers are this image's `claude` and `codex` CLIs,
run as processes of the container with your sign-ins (`claude` then `/login`, `codex login`). No
Docker and no API keys go in the config. Run the server and the dispatcher in two terminals:

```sh
cairn serve       # API and web UI on http://127.0.0.1:8000; facts in ~/.local/share/cairn/cairn.db
cairn dispatch    # runs the workers; each project works in ~/cairn-runs/<project>/
```

Create a project (origin, goal) in the web UI, watch the graph grow, and add hints.

Things to know:

- **Loopback only.** `cairn serve` binds `127.0.0.1:8000` (its own default, which the wrapper
  passes explicitly unless you give `--host`). The server has **no authentication**: anyone who
  reaches it can start projects that the dispatcher hands to the agents. Don't publish port 8000.
  With host networking, the container's loopback is the host's, and the host's browser reaches it
  as it is. Otherwise forward it over SSH. Or publish it on the host's loopback only
  (`-p 127.0.0.1:8000:8000`) and run `cairn serve --host 0.0.0.0`, which also opens it to other
  containers on that Docker network.
- **The agents run without permission prompts.** Cairn starts `claude --dangerously-skip-permissions -p`
  and `codex exec --dangerously-bypass-approvals-and-sandbox`, as root, inside this container. The
  container is their only sandbox. Claude Code refuses that flag as root unless `IS_SANDBOX=1`, so
  the config sets it for the Claude worker only. Authorized targets only.
- **Config:** `/opt/cairn/dispatch.yaml`, written from upstream's `dispatch.local.example.yaml`.
  Claude Code takes every task type and Codex takes explore tasks. One project and two workers run
  at a time. To change it, copy it to `~/.config/cairn/dispatch.yaml` (used first) and edit the
  copy, for example to drop the Codex worker if Codex is not signed in. `cairn dispatch --config FILE`
  takes any other file. Reinstalling rewrites `/opt/cairn`.
- **Version:** builds take the latest `main`. `CAIRN_REVIEWED_COMMIT` in `scripts/llm_software.sh`
  is the last commit read for this install, and a build on a newer one adds a `review` entry to the
  build report.

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

### MCP servers (REA, Craft Anything, CodeGraph, pentest-ai)

The build registered them in `~/.config/opencode/opencode.json`. Check them with:

```sh
opencode mcp list
```

It asks OpenCode's background server, which starts the servers on first use: right after a
fresh start it can print `No MCP servers configured`. Run it again after ~20 s and they show
`✓ connected`. pentest-ai shows as failed until its Acceptable Use Policy is accepted with
`ptai-aup` (see [pentest-ai](#pentest-ai)).

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

## Design decisions

Choices made when the Decepticon pack, pentest-ai and Cairn were added, and why.

- **Decepticon is fetched from `BitterSecurity/Decepticon`.** `PurpleAILAB/Decepticon` now
  redirects there. Following a redirect would keep working only as long as nobody re-registers
  the old name, so the build names the current repository.
- **Only Decepticon's skills, and only some of them enabled.** The pack is a sparse, blobless
  checkout of `packages/decepticon/decepticon/skills` (14 MB instead of 90 MB); Decepticon's
  agents, sandbox and web UI are not installed. Skills that only make sense inside its platform
  are left out ([Decepticon](#decepticon)). Every enabled skill costs context on every turn, so
  only the IoT, wireless and ICS/OT skills are enabled; the rest are one `llm-skills enable` or
  `search` away.
- **A note instead of edited skills.** Skills that call Decepticon-only tools keep upstream's
  text; `render` inserts a short note naming those tools and what to do instead. A rewrite would
  drift from upstream at every `llm-skills update`.
- **Frontmatter is read more completely, for every pack.** `subdomain`, `tags` and `when_to_use`
  are read from under `metadata:` too, and tags written as a comma-separated string or `[a, b]`
  are split. Before, those tags were ignored. The side effect is wider matches for existing packs
  in `llm-skills search` and `enable <pack>:<keyword>`; check with `llm-skills list <pack>` before
  enabling a broad keyword.
- **pentest-ai's consent is enforced in front of its MCP server.** Upstream asks for its
  acceptable-use consent only in `ptai start`; its MCP tools do not check it, so agents could use
  it without anyone having accepted. The agents are registered with `ptai-mcp`, which starts
  `ptai mcp` only once `ptai-aup` recorded the operator's acceptance (or
  `PENTEST_AI_AUP_ACCEPTED` is set). The image never accepts it on anyone's behalf: build state in
  `~/.pentest-ai` is removed and the variable is never set. Until then the agents show the server
  as failed.
- **Reviewed versions are recorded, not pinned silently.** `PENTESTAI_REVIEWED_VERSION` and
  `CAIRN_REVIEWED_COMMIT` mark the release or commit whose launch command, consent, telemetry,
  bind address and configuration were read. They are not a full code audit; a newer upstream
  appears in the build report as unreviewed.
- **Cairn is opt-in and runs its agents without prompts.** Cairn drives `claude` and `codex`
  non-interactively (`--dangerously-skip-permissions`, `--dangerously-bypass-approvals-and-sandbox`)
  as root, so the container is their only sandbox. Claude Code refuses that flag as root unless
  `IS_SANDBOX=1`; it is set only in Cairn's Claude worker environment, never image-wide. Cairn's
  API has no authentication, so `cairn serve` binds to 127.0.0.1. Only build it for an
  isolated, authorized target. See [Cairn](#cairn-opt-in).
- **Cairn's dependencies come from PyPI, checked against its lock.** Upstream's `uv.lock` points
  at a PyPI mirror (`mirrors.aliyun.com`). The exact versions and SHA-256 hashes of that lock are
  installed from PyPI with hash checking; all 26 hashes match the files PyPI publishes.
- **The RF Swift Workbench skills are not in this image.** They drive radios and probes through the
  Workbench's mission tools, and this image has neither; the Workbench installs them in each
  mission's agent workspace.

## Updating

```sh
npm update -g @anthropic-ai/claude-code @openai/codex @opencode/cli rea-agents
uv tool upgrade mistral-vibe ptai
uv tool install --force --python 3.11 --torch-backend cpu open-webui
hermes update
llm-skills update
```

Open WebUI is reinstalled rather than upgraded: uv does not save `--torch-backend cpu`, so
`uv tool upgrade open-webui` could swap in the CUDA build of PyTorch (about 4 GB more).

Node.js (v24 line), Craft Anything and whisper.cpp take their newest release on every image
build. `LLM_NODE_VERSION`, `CRAFT_VERSION` and `WHISPERCPP_VERSION` in
`scripts/llm_software.sh` are the known-good fallbacks. Node and Craft Anything downloads are
verified against the checksum file each release publishes, or against the pinned SHA256 when
the build falls back. See `docs/maintaining-tool-versions.md`.
