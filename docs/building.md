---
title: "Build OpenWrt for the AW1000 on GitHub Actions"
description: "Build CleanWRT for the Arcadyan AW1000 from source on GitHub Actions or locally with Docker: pinned feeds, checks, signing and the repository layout."
---

# Build from source

Anyone can rebuild a release. The repository holds only build configuration, patches and the
rootfs overlay: no firmware binaries and no package source. Packages are fetched from their
upstream feeds at build time, every one pinned to a commit.

## Repository layout

The firmware repository pins several smaller repositories, listed with their documentation on the
[Repositories](repositories.md) page. This is the layout of the firmware repository itself:

| Path | What it is |
|---|---|
| `configs/arcadyan_aw1000.seed` | the package selection and image identity |
| `configs/local-packages.pin` | out-of-feed packages, pinned to a commit |
| `configs/license-overrides.tsv` | licences for packages that record none |
| `feeds.conf.default` | every feed, pinned to a commit |
| `feeds-src/cwfeed/` | the vendored feed (qBittorrent stack, AdGuard Home app, Syncthing app) |
| `files/` | the rootfs overlay (first-boot scripts, defaults, banner) |
| `patches/feeds/` | patches applied to the pinned feeds, with zero fuzz |
| `tools/` | the build script and its helpers |
| `docker/Dockerfile` | the pinned build environment |
| `.github/workflows/` | the checks and the build |

## On GitHub Actions

The build needs nothing but the repository.

| Workflow | When | What it does |
|---|---|---|
| `check` | every push and pull request | shell syntax, the version label, that the pins resolve, and a **config check**: feeds, patches, pins, defconfig and the seed checks, without compiling |
| `build` | by hand (*Actions → build → Run workflow*) or when a tag `v<version>` is pushed | builds the image in the Docker environment, with a download cache and a compiler cache |

The inputs of a manual run:

| Input | Default | Meaning |
|---|---|---|
| `clean` | off | rebuild every package |
| `opt_artifacts` | off | also compile and verify the optional `cw-opt` feed |
| `artifacts` | off | upload the images as a workflow artifact (public for a public repository) |
| `publish` | off | create a GitHub release and update the project site |

A job is limited to six hours by GitHub. A cold build takes roughly two hours; later builds are
shorter because of the caches.

## Locally

You need a Linux machine (or a Linux VM) and Docker.

```sh
git clone --depth 1 --branch v25.12.5 https://github.com/openwrt/openwrt.git openwrt
docker build -t cleanwrt-builder docker/
docker run --rm \
  -v "$PWD/openwrt":/build -v "$PWD/cleanwrt-aw1000":/cleanwrt \
  cleanwrt-builder /cleanwrt/tools/cw-release-build.sh /build --clean
```

The sysupgrade image and a provenance bundle land in `openwrt/bin/targets/qualcommax/ipq807x/`.

!!! tip "Check first, compile later"
    `CW_CHECK_ONLY=1` runs the feed, patch, pin, defconfig and seed checks and stops before
    compiling. Pass it with `-e CW_CHECK_ONLY=1` to `docker run`. It takes a few minutes and
    catches almost every configuration mistake.

## What the build script guarantees

`tools/cw-release-build.sh` applies the overlay, the pinned feeds and the feed patches, then
runs the mandatory post-defconfig fixups, and it **fails** rather than ship something stale:

- the OpenWrt tree must be exactly at `v25.12.5`;
- the version label in the seed and in the script must agree;
- every feed and every local package must match its pinned commit;
- a feed patch that no longer applies cleanly fails the build, because the upstream code changed;
- every package the seed selects must survive `make defconfig`;
- init scripts must be executable and use procd correctly;
- the image must fit the flash layout (`UBI_PEBS ...` line) and the size gate;
- the kernel modules repository the image points at must have the vermagic of the built kernel.

## Signing

| Key | Purpose | How |
|---|---|---|
| image signing (usign) | signs every image | `tools/cw-sign-keys.sh --generate <tree>` creates `keys-release/`. **Never commit it.** The build uses it when present. |
| apk feed key | signs the optional `cw-opt` feed | created by the build tree on first build (`private-key.pem`). `tools/cw-check-release-keys.sh` proves a tree uses the key the devices trust. |

On GitHub Actions these keys come from the repository secrets `APK_PRIVATE_KEY`,
`USIGN_KEY_BUILD` and `USIGN_KEY_BUILD_PUB`. Without them the images are unsigned and the
`cw-opt` feed stays disabled.

## Changing a patch or moving a pin

- **Move a feed pin:** change the commit after the `^` in `feeds.conf.default`, then make sure
  every patch in `patches/feeds/` still applies (the `check` workflow does this).
- **Re-port a patch:** apply it to the new upstream by hand, regenerate it with `diff -u`, and
  keep the header that says what it changes and why.
