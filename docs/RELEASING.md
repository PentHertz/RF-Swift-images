# Releasing RF-Swift images

How images go from this repository to what users pull with the `rfswift` CLI.

## Registries and tag scheme

| Registry | Purpose | Tags |
|---|---|---|
| `penthertz/rfswiftdev_resolute` | **Dev** — everything CI builds lands here first | `<image>_<arch>` (fresh build), `<image>_<arch>_<version>` (incremental update) |
| `penthertz/rfswift_resolute` | **Release** — what the CLI pulls | `<image>_<version>_<arch>` (pinned) and `<image>_<arch>` ("latest") |

Note the order flip: dev incremental tags are `<image>_<arch>_<version>`, release tags are
`<image>_<version>_<arch>`.

Architectures: `amd64` (primary), `arm64`, `riscv64` (subset of images only).

## Image dependency chain

Each image builds `FROM` an earlier one (see `Dockerfiles/Makefile`):

```
corebuild
└── sdrsa_devices            (+ variants: sdrsa_devices_antsdr, sdrsa_devices_rtlsdrv4)
    ├── sdr_light
    │   ├── sdr_gnuradio4    (GNU Radio 4.0 add-on, experimental/RC)
    │   ├── sdr_full         (staged multi-stage build)
    │   └── ...GPU variants  (sdr_light_intelgpu / _nvidiagpu)
    ├── hardware, deeptempest
    └── telecom_*, wifi, bluetooth, rfid, network, automotive,
        android, osint, ad, reversing
```

An image can only be (re)built after its base exists in the dev registry.

## Path 1 — Fresh CI build (the normal path)

1. Push / merge to the **`ubuntu_resolute`** branch. `build_images_amd64.yml` and
   `build_images_arm64.yml` trigger automatically.
2. Each job runs **changed-file detection** (`git diff HEAD^ HEAD`): an image is rebuilt only
   if its `.docker` file or its install scripts changed (base-image triggers such as `config/`,
   `Dockerfiles/Makefile`, `scripts/common.sh`, `scripts/entrypoint.sh` rebuild everything
   below them). Unchanged images are skipped, jobs finish green without building.
3. To rebuild **everything** regardless of the diff, run the workflow manually
   (*Actions → Full build … → Run workflow*); the `force_all` input defaults to `true`.
4. Results are pushed to the dev registry as `<image>_<arch>`, using buildx registry cache
   (`cache_<image>_<arch>` tags in the same repo).

> **New image?** The commit that adds the workflow job usually does *not* touch the image's
> trigger files, so the job will skip on that push. Seed the first build with a manual
> `force_all` dispatch, or build locally with `./release.sh build <image>`.

Heavier amd64 jobs (`sdr_light`, `sdr_gnuradio4`, `sdr_full`, `telecom_*`, …) run on the
self-hosted `[Linux, X64]` runners; arm64 uses GitHub's `ubuntu-26.04-arm`. The riscv64
workflow builds a subset of images and runs **entirely on self-hosted `Linux` runners**:
riscv64 images build under QEMU emulation, and GitHub-hosted runners cancel those jobs
(resource limits kill them early with "The operation was canceled").
`build_images_multiarch.yml` is **deactivated** (trigger branch `deactivated`) and kept for
reference.

## Path 2 — Incremental update (patch a released image without a full rebuild)

*Actions → Incremental update (manual)* (`update_images.yml`). It runs `rfswift_update`
**inside** the latest fresh image, commits the result as **one layer**, and pushes
`<image>_<arch>_<version>` to the dev registry.

- Layering is **rebased**: the source is always the fresh-build tag (never overwritten), so a
  v1.x image never grows across updates.
- Inputs: `image`, `arch`, `mode` (`recipe` = only recipe-changed tools, `latest` = also float
  git tools, `force` = rebuild all), `sync_scripts`/`scripts_branch`, `apt_upgrade`, `push`
  (off = dry-run), `version` (required when pushing).
- Use a fresh full build instead for major bumps — commit-based images drift from the
  Dockerfile.

## Path 3 — Publish a release

Tag the repo and push the tag:

```bash
git tag v1.2.3
git push origin v1.2.3
```

`tagged_release_amd64.yml` and `tagged_release_arm64.yml` then **retag** every dev image into
the release registry with `docker buildx imagetools create` (no rebuild):

- `penthertz/rfswiftdev_resolute:<image>_<arch>` → `penthertz/rfswift_resolute:<image>_1.2.3_<arch>`
- plus the floating `penthertz/rfswift_resolute:<image>_<arch>`.

Every image named in those workflows **must already exist** in the dev registry for its arch,
or its retag job fails — make sure Path 1 has run (and succeeded) for anything new.

## Local / manual releases — `release.sh`

Same pipeline, runnable from a workstation (`docker login` to both registries first):

```bash
./release.sh build   sdr_gnuradio4 --arch amd64                       # fresh build -> dev
./release.sh update  sdr_light --arch amd64 --version 1.0.1           # rebased update -> dev
./release.sh tag     sdr_light --arch amd64 --version 1.0.1           # dev -> release registry
./release.sh release sdr_light --arch amd64 --version 1.0.1 --from build   # build|update + tag
./release.sh release all --arch all --version 1.2.3 --from build      # everything, all arches
```

`all` walks `ALL_IMAGES` in dependency order and keeps going past failures (per-arch ok/FAILED
summary at the end). `--dry-run` prints the commands without running them. Registries can be
overridden with `DEV_REGISTRY` / `RELEASE_REGISTRY` env vars.

## CI requirements

- **Repository variable** `DOCKERHUB_USERNAME` and **secret** `DOCKERHUB_TOKEN` (push rights to
  both registries).
- Secrets `BUCKET_URL` / `BUCKET_REGION` (DigitalOcean Spaces endpoint used by build-report
  steps).
- Online self-hosted `[Linux, X64]` runners for the heavy amd64 jobs.

## Checklist — adding a new image to the release pipeline

Using `sdr_gnuradio4` as the worked example:

1. **Dockerfile**: `Dockerfiles/SDR/sdr_gnuradio4.docker` (takes `BASE_IMAGE` build-arg).
2. **Makefile target**: `sdrgnuradio4` in `Dockerfiles/Makefile` (+ `.PHONY` and `help` text).
3. **Build jobs**: `sdr_gnuradio4` job in `build_images_amd64.yml` (plus its `-manifest` job)
   and `build_images_arm64.yml`, with `needs:` pointing at the base image's job and
   changed-file conditions covering the `.docker` file and its install script(s).
4. **Release jobs**: `retag-sdr_gnuradio4` in `tagged_release_amd64.yml` / `_arm64.yml`,
   `needs:` the base image's retag job.
5. **Incremental updates**: add the image to the `image` options in `update_images.yml`.
6. **`release.sh`**: add to `VALID_IMAGES` and `ALL_IMAGES` (topological order) and, if the
   Makefile target name differs from the image tag, to `make_target()`.
7. **Seed it**: manual `force_all` dispatch of the build workflows (or
   `./release.sh build <image>`) so the dev tag exists before the next version tag is pushed.
