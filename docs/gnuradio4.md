# GNU Radio 4 (GR4) and GR4 Studio — `sdr_gnuradio4` image

The `sdr_gnuradio4` image (`make sdrgnuradio4`, built on top of `sdr_light`) adds **GNU Radio
4.0** next to the apt **GNU Radio 3.10**. GR 3.10 stays the default: `gnuradio-companion`,
`grcc` and the 3.10 Python modules are unchanged. GR4 is a separate C++23 code base with its
own headers, prefix and tools, so the two do not conflict.

## What is installed

| | |
|---|---|
| Source | [`gnuradio/gnuradio4`](https://github.com/gnuradio/gnuradio4), the GNU Radio project's own repository. `fair-acc/gnuradio4` is the FAIR prototype GR4 grew out of, not the release line |
| Version | The **newest release tag** at image build time (currently **4.0.0-RC3**, a release candidate). Each tag pins the commit of every component in its `modules.cmake`, so a build is reproducible |
| Components | `gnuradio4-core`, `gnuradio4-library`, `gnuradio4-blocks` (with the **SDR** (SoapySDR), **Audio** (libsoundio) and **ZeroMQ** block families), `gnuradio4-control-plane` (`gr4cp_server`, `gr4cp-cli`), **GR4 Studio** (desktop and browser) |
| Install prefix | `/opt/gnuradio4/install` (sources stay in `/opt/gnuradio4`; the build tree is removed to keep the image small) |
| Studio | amd64 and arm64 only (it bundles an Electron runtime, and Electron has no riscv64 build) |

## Environment

Login shells load GR4's environment from `/etc/profile.d/gnuradio4.sh`. In any other shell,
load it yourself:

```sh
. /opt/gnuradio4/env.sh
```

It sets `GR4_PREFIX`, and puts the prefix on `PATH`, `CMAKE_PREFIX_PATH`, `PKG_CONFIG_PATH`,
`LD_LIBRARY_PATH` and `GNURADIO4_PLUGIN_DIRECTORIES` (where GR4 loads block plugins from).
The `gr4-studio` and `gr4-studio-web` commands load it on their own.

## Check that it works

The image build runs upstream's own checks against the **installed** GR4:

- **`oot-smoke`** builds and runs a small out-of-tree program against the installed SDK.
- **`control-plane-smoke`** starts the installed `gr4cp_server` and checks that it lists the
  GR4 block catalog.

If either fails, it is listed in the image's build report under category `test`. Read the report
with `make report IMG=sdr_gnuradio4` on the build host, or with
`cd /root/scripts && ./entrypoint.sh print_build_report` in the container. You can also check
by hand:

```sh
. /opt/gnuradio4/env.sh
grinfo version                             # framework, plugin directories and what each held
ls "$GR4_PREFIX/lib/gnuradio-4/plugins"    # block plugins: Basic, Filter, Sdr, ...
```

## Command-line tools

Besides Studio, GR4 installs three command-line tools:

| Command | What it does |
|---|---|
| `grinfo` | Report the GR4 framework, its plugins and its blocks (`grinfo version`, `grinfo --help`) |
| `rungraph --graph <file>` | Run a flowgraph saved in GR4's GRC YAML dialect (for example from Studio). Use `-` to read it from standard input |
| `graphdoc <graph.yaml>` | Describe a flowgraph as Markdown or HTML (`--format md\|html`) |

## GR4 Studio in the browser (recommended in a container)

```sh
gr4-studio-web
# then open http://localhost:8080 on the host
```

This starts `gr4cp_server` (the control plane that runs flowgraphs) and nginx, which serves the
Studio web app and forwards `/api` to the control plane. Upstream's
`ghcr.io/gnuradio/gnuradio4-studio` image uses the same layout.

- **Address:** by default it listens on **`127.0.0.1:8080`**. RF Swift containers use host
  networking by default, so that address is reachable from the host's browser and from
  nowhere else.
- **Options:** `GR4_STUDIO_WEB_PORT` changes the port. `GR4_STUDIO_WEB_BIND` changes the
  listen address.
- **Bridge/NAT container:** set `GR4_STUDIO_WEB_BIND=0.0.0.0` inside the container and publish
  the port on the host's loopback only, for example `-p 127.0.0.1:8080:8080`.
- **Backend:** `gr4cp_server` always runs on a random **loopback** port behind nginx. It is
  never exposed directly. Given a fixed port, it would listen on all interfaces.

> **Security:** Studio has no authentication, and it can start flowgraphs, including ones that
> **transmit** with an attached SDR. Keep it on localhost, or on machines and networks you trust.

## GR4 Studio desktop app

The desktop app is an Electron window. It needs a display, so start the container with X11
or Wayland forwarding (RF Swift's display options).

```sh
gr4-studio                                   # local backend (starts its own gr4cp_server)
gr4-studio --remote=http://host.example:8080 # use a control plane running elsewhere
```

Two container-specific details are handled for you:

- **Root and the sandbox.** Electron refuses to run as root unless its Chromium sandbox is
  turned off. The image points `GR4_STUDIO_ELECTRON_BIN` at a small wrapper that adds
  `--no-sandbox`.
- **`gr4-studio-sandbox-setup` is not needed.** Upstream's launcher asks for it on Ubuntu
  hosts that restrict unprivileged user namespaces. That setup installs an AppArmor profile on
  the **host**, which a container cannot do, and it is unnecessary once the sandbox is off.

## SDR hardware

GR4's SDR blocks go through **SoapySDR**, using the Soapy driver modules that `sdr_light`
already ships. Pass the device to the container as usual, then check that Soapy sees it:

```sh
SoapySDRUtil --find
```

## Build your own GR4 code

An out-of-tree project finds the installed SDK with CMake. This is the same project the
image's `oot-smoke` check builds:

```cmake
cmake_minimum_required(VERSION 3.27)
project(my_gr4_app LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(gnuradio4 CONFIG REQUIRED)
find_package(gnuradio4Library CONFIG REQUIRED)
find_package(gnuradio4Blocks CONFIG REQUIRED)

add_executable(my_gr4_app main.cpp)
target_link_libraries(my_gr4_app PRIVATE
    gnuradio4::gnuradio-core gnuradio4::gnuradio-algorithm gnuradio4::gr-math)
```

```sh
. /opt/gnuradio4/env.sh
cmake -S . -B build -G Ninja && cmake --build build
```

## Rebuild, or pick another GR4 version

The installer stays in the image. To rebuild in a running container (it needs network access,
because components and dependencies are fetched, and it takes a long time):

```sh
cd /root/scripts
./entrypoint.sh gnuradio4_soft_install                       # newest release tag again
GR4_REF=4.0.0-RC3 ./entrypoint.sh gnuradio4_soft_install     # a specific tag
```

How the image builds it, following upstream's own Ubuntu 26.04 recipe
(`containers/ubuntu-26.04/Dockerfile` in the GR4 repository):

- **Preset:** `cmake --preset full`, with `CMAKE_BUILD_TYPE=Release`, `GR4_BUILD_TESTING=OFF`
  (the test suite is the slowest and most memory-hungry part) and `GR4_WARNINGS_AS_ERRORS=OFF`.
- **Parallelism:** `GR4_BUILD_PARALLEL_LEVEL` is sized from available RAM, at about 3 GB per
  compiler job, or 6 GB on arm64. This setting is what limits the nested component builds;
  `-j` does not.
- **No precompiled headers:** `GR4_EXTRA_CMAKE_ARGS=-DCMAKE_DISABLE_PRECOMPILE_HEADERS=ON`. Each
  block family's precompiled header is 400–600 MB, and they would fill a CI runner's disk. On
  Ubuntu 26.04 with GCC 15, the core + library + blocks build peaked at about 1.5 GB without
  them, against 5.9 GB after only 4 % of the blocks with them. On 24 cores it took about 31 minutes.
- **Audio blocks:** the Audio family needs `libsoundio-dev`, which the installer adds. Upstream's
  26.04 package list does not include it, so without it the family would be skipped.
- **Older tags:** tags up to 4.0.0-RC2 used a single-repository layout without Studio. The
  installer still builds them when selected with `GR4_REF`.
