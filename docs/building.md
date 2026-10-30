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
| `patches/tree/` | patches applied to files the OpenWrt tree carries itself (packages, build system), with zero fuzz |
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

A job is limited to six hours by GitHub. A cold build takes roughly two hours; later builds are
shorter because of the caches.

A tag `v<version>` is built by the same workflow, and its images go straight into a **draft**
release: nothing is public and the site is not touched until that draft is published by hand.

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

`tools/cw-release-build.sh` applies the overlay, the pinned feeds and the patches (to the feeds
and to the tree), then runs the mandatory post-defconfig fixups, and it **fails** rather than ship
something stale:

- the OpenWrt tree must be exactly at `v25.12.5`;
- the version label in the seed and in the script must agree;
- every feed and every local package must match its pinned commit;
- a feed or tree patch that no longer applies cleanly fails the build, because the upstream code
  changed;
- every package the seed selects must survive `make defconfig`;
- init scripts must be executable and use procd correctly;
- the image must fit the flash layout (`UBI_PEBS ...` line) and the size gate;
- the kernel modules repository the image points at must have the vermagic of the built kernel.

## Signing

| Key | Purpose | How |
|---|---|---|
| image signing (usign) | signs every image | `tools/cw-sign-keys.sh --generate <tree>` creates `keys-release/`. **Never commit it.** The build uses it when present. |
| apk key | the key every image trusts and the one that signs the optional `cw-opt` feed | one fixed pair: the public half is committed at `files/etc/apk/keys/public-key.pem` and ships in the overlay; the private half is the repository secret `APK_PRIVATE_KEY` (and `keys-release/private-key.pem` for a local release build), never committed. The build writes it to `<tree>/private-key.pem`, and `tools/cw-check-release-keys.sh` proves the two halves match. |

A tree with no key lets OpenWrt generate one during the build, so two builds of the same source
produced different `/etc/apk/keys/public-key.pem`. Three more differences are removed by patches:
qca-ssdk stamped the build time into its module, ndisc6's version banner carried configure's build
hostname, and `apk mkpkg` stamped the build clock into every package, because a shallow clone has
no per-package git history to take the date from. With the key fixed and those three patches
applied, two builds of the same commit produce the same images.

On GitHub Actions these keys come from the repository secrets `APK_PRIVATE_KEY`,
`USIGN_KEY_BUILD` and `USIGN_KEY_BUILD_PUB`. Without them the images are unsigned and the
`cw-opt` feed stays disabled.

## Changing a patch or moving a pin

- **Move a feed pin:** change the commit after the `^` in `feeds.conf.default`, then make sure
  every patch in `patches/feeds/` still applies (the `check` workflow does this).
- **Re-port a patch:** apply it to the new upstream by hand, regenerate it with `diff -u`, and
  keep the header that says what it changes and why.
- **Add a tree patch:** put it in `patches/tree/`, with paths from the tree root
  (`package/kernel/qca-ssdk/Makefile`, `include/package-pack.mk`). `tools/cw-apply-feed-patches.sh` reverses the tree
  patches before every `feeds update` and applies them again at the start of the build.
