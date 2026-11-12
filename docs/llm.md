# RF Swift `llm` image

Coding agents, shared skill packs and agent-side reverse-engineering tools, on top of
`corebuild`. Built for amd64 and arm64 (Claude Code, Codex and OpenCode ship no riscv64 build).
In the image this file is `/opt/llm/README.md`.

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

Node.js 24 LTS is in `/usr/local` (Ubuntu's 22.22 is too old for REA).

## Keep your sign-ins

Credentials live in the container's home directory. Mount them from the host, or they are gone
with the container:

```sh
docker run -it --rm \
  -v ~/.rfswift-llm/claude:/root/.claude -v ~/.rfswift-llm/codex:/root/.codex \
  -v ~/.rfswift-llm/opencode-data:/root/.local/share/opencode \
  -v ~/.rfswift-llm/vibe:/root/.vibe -v ~/.rfswift-llm/hermes:/root/.hermes \
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

Every agent reads the same skills. They come from four packs:

| Pack | Skills | Enabled by default |
|---|---:|---|
| `trailofbits` ([trailofbits/skills](https://github.com/trailofbits/skills)): audits, static analysis, fuzzing, crypto, smart contracts | 96 | yes |
| `farmage` ([farmage/opencode-skills](https://github.com/farmage/opencode-skills)): language/framework experts, code review, testing | 67 | yes |
| `floorplan` ([haydenschmitty/floorplan](https://github.com/haydenschmitty/floorplan)): interactive architecture map of a codebase | 1 | yes |
| `cybersecurity` ([mukul975/Anthropic-Cybersecurity-Skills](https://github.com/mukul975/Anthropic-Cybersecurity-Skills), the skills-hub.ai "Cybersecurity Skills" source): pentest, red team, DFIR, malware, threat intel, cloud/AD/ICS | 818 | through one index skill |

Agents send the name and description of every enabled skill to the model on each turn. The
default set costs about 16K tokens; all 818 cybersecurity skills would add about 80K. So that
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

## Updating

```sh
npm update -g @anthropic-ai/claude-code @openai/codex @opencode/cli rea-agents
uv tool upgrade mistral-vibe
hermes update
llm-skills update
```

Craft Anything is pinned (`CRAFT_VERSION` in `scripts/llm_software.sh`); the image rebuild
picks up a new release once that is bumped.
