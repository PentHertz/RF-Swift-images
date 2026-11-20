# ARTEX (RF Swift)

[ARTEX](https://github.com/BaaRai/ARTEX) is an autonomous, agent-driven web-security
testing platform: a Go backend with an embedded Next.js UI, a recording MITM proxy, and
a bundled recon toolchain (nmap, nuclei, httpx, katana, ffuf, dalfox, sqlmap, bbot,
Playwright). It drives an LLM to explore, exploit and report against a target. You use it
through a browser on `http://localhost:8787`, not from a container terminal.

ARTEX **requires PostgreSQL** (there is no SQLite mode), so it is not a pure single-binary
tool. There are two ways to run it here:

- **Single image** (`make artex`) — PostgreSQL ships inside the ARTEX image; you start it
  and ARTEX by hand from the container shell, the way RF Swift brings up Open5GS. One
  container, launched with the `rfswift` tool like any other RF Swift image.
- **Compose stack** (`docker-compose.yml`) — ARTEX and PostgreSQL as two containers, the
  way upstream ships it. Use this when you want the database in its own container.

Either way the ARTEX image is built straight from the upstream repository (its own
Dockerfile), **tracking the latest `main`** by default — set `ARTEX_REF` to a tag or commit
to pin it. This folder stays a thin wrapper rather than a vendored copy of their build.

Because ARTEX tracks upstream rather than this repo's image chain, it is **left out of the
full-build CI workflows**. It has its own manual workflow instead
(`.github/workflows/build_artex.yml`): run it from the Actions tab (`Build ARTEX (manual)`),
optionally pinning the ref via the `artex_ref` input, and it builds + publishes `:artex` for
amd64/arm64. Pushes that touch `Dockerfiles/artex.docker` or `extras/artex/**` also rebuild
it; upstream-`main` drift does not, so rebuild by hand when you want a newer ARTEX.

## Single image

Build (amd64/arm64):

```sh
cd RF-Swift-images/Dockerfiles
make artex                      # builds the upstream ARTEX base, then adds PostgreSQL
# make artex ARTEX_REF=v0.6.0   # pin to a release instead of latest main
```

Run it, then start the services from the shell:

```sh
# a volume on /var/lib/postgresql/data keeps the database across restarts
docker run -it --rm -p 127.0.0.1:8787:8787 \
  -v artex-db:/var/lib/postgresql/data \
  -v "$PWD/artex-data:/app/data" -v "$PWD/artex-keys:/app/keys" \
  penthertz/rfswiftdev_resolute:artex_amd64

# inside the container:
artex-postgres                  # init (first time) + start the database
artex-start                     # launch ARTEX; prints the setup token
# open http://localhost:8787/setup
```

Defaults: `POSTGRES_USER=artex`, `POSTGRES_PASSWORD=artex`, `POSTGRES_DB=artex`
(override with `-e`). Give ARTEX its LLM with `-e ANTHROPIC_API_KEY=...` (or configure it
in the UI). `artex-postgres stop|status` manage the database.

## Compose stack

```sh
cd RF-Swift-images/extras/artex
cp .env.example .env            # set POSTGRES_PASSWORD, optionally an LLM key
docker compose up -d --build    # first build clones + compiles ARTEX; it takes a while
docker compose logs artex | grep "Setup token"
```

Open `http://localhost:8787/setup` and paste the one-time setup token.

## How it relates to the `llm` image

ARTEX is its **own** agent platform with its own LLM configuration — it is not wired into
RF Swift's `llm` image. ARTEX exposes an HTTP API and web UI on `:8787` (and a recording
proxy on `:8788`); it is an MCP *client* (it can reach *out* to remote HTTP/SSE MCP servers
from its System → Settings) and does **not** expose an MCP server for other agents to
connect to. So an `llm`-image agent (Claude Code, Codex, OpenCode…) interacts with ARTEX
through its web UI / HTTP API, not over MCP. (If you later want ARTEX to use tools that run
in the `llm` image, expose those as an HTTP/SSE MCP endpoint and add it in ARTEX's settings.)

## Authorized use only

ARTEX is licensed **AGPL-3.0** with **additional usage restrictions from its maintainers**:
it is an offensive-security tool, to be run only against systems you own or are explicitly
authorized to test (your lab, your organization's assets, or an in-scope bug-bounty / VDP
target). Running it against anything else violates its terms. It is an English-translation
continuation of the original ARTEX by Autumn-27. See the upstream README and LICENSE.
