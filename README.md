# CleanWRT - Arcadyan AW1000 5G router

CleanWRT is an OpenWrt 25.12.5 based firmware build for the **Arcadyan AW1000** 5G router
(Qualcomm IPQ8074, kernel 6.12.94, target `qualcommax/ipq807x`).
Versioning: `CleanWRT <openwrt-base>-<stage>`, e.g. `25.12.5-rc1`, then `25.12.5-r1` at
stable. The running version shows in the login banner and the LuCI footer.

> CleanWRT is an independent community rebuild, *Powered by OpenWrt*. It is not affiliated
> with or endorsed by the OpenWrt project. OpenWrt(R) is a registered trademark of Software
> Freedom Conservancy (SFC) - https://openwrt.org

OpenWrt plus a curated set of community packages:

| Package | Source | Purpose |
|---|---|---|
| Passwall / Passwall2 | [Openwrt-Passwall](https://github.com/Openwrt-Passwall/openwrt-passwall2) | Proxy / routing |
| QModem | [FUjr/QModem](https://github.com/FUjr/QModem) | 5G modem management UI |
| 3ginfo-lite | [4IceG/luci-app-3ginfo-lite](https://github.com/4IceG/luci-app-3ginfo-lite) | Mobile connection info |
| [luci-app-cw-led](https://github.com/Pr0Luci/luci-app-cw-led) | this project | Front-panel LED daemon + LuCI page |
| [luci-theme-apex](https://github.com/Pr0Luci/luci-theme-apex) | this project | Default LuCI theme |

This repository holds only build configuration, patches and the rootfs overlay: no firmware
binaries and no package source. The packages are pulled from their upstream feeds at build time.

> **Licence notice - QModem:** the bundled QModem stack (`qmodem`, `luci-app-qmodem`, ...) is
> MPL-2.0 **with a non-commercial clause** in its upstream licence. Free/community use is
> fine; **commercial deployment of this firmware is not permitted by that component.** See
> `NOTICE.md`.

## Build

`tools/cw-release-build.sh` is the one build command. It applies the overlay, the pinned
feeds, the feed patches (zero fuzz, the build fails on upstream drift) and the mandatory
post-defconfig fixups, then verifies the result. It needs a Linux host with the OpenWrt build
prerequisites (or `docker/Dockerfile`).

```sh
git clone --branch v25.12.5 https://git.openwrt.org/openwrt/openwrt.git
/path/to/cleanwrt-aw1000/tools/cw-release-build.sh ./openwrt --clean
```

The sysupgrade image and a provenance bundle land in `openwrt/bin/targets/qualcommax/ipq807x/`.

### On GitHub Actions

The build runs on GitHub-hosted runners, nothing else is needed:

- `check` runs on every push and pull request: shell syntax, the version label, the pins and
  `CW_CHECK_ONLY=1` (feeds, feed patches, pins, defconfig and seed checks, no compile).
- `build` is started by hand (Actions > build > Run workflow) or by pushing a tag `v<version>`
  (the tag must equal `CW_VERSION`). It builds the image with a compiler cache and a download
  cache, uploads the image, checksums and provenance, and with `publish` (or on a tag) creates
  the GitHub release and updates the site on the `gh-pages` branch: `.versions.json` and the
  `profiles.json` that the LuCI upgrade check reads.
- A job is limited to six hours by GitHub. If a cold build does not finish, run it again: the
  caches saved at the end of the failed run make the next one shorter.
- Optional repository secrets: `APK_PRIVATE_KEY` (the apk feed signing key),
  `USIGN_KEY_BUILD` and `USIGN_KEY_BUILD_PUB` (image signing). Without them the images are
  unsigned and the `cw-opt` feed stays disabled.

Every feed is pinned to a commit in `feeds.conf.default`, and `configs/local-packages.pin`
pins the out-of-feed packages (`luci-app-cw-led`, `luci-theme-apex`, `luci-app-homeproxy`);
the build fails if a checkout does not match its pin. `CW_CHECK_ONLY=1` runs the feed,
patch, pin, defconfig and seed checks and stops before compiling.

### Release signing

- Images: `tools/cw-sign-keys.sh --generate <tree>` creates a usign keypair in `keys-release/`
  (never commit it). With the keys present, the build signs every image.
- The optional `cw-opt` apk feed (qBittorrent, AdGuard Home, OpenClash): see
  `files/etc/apk/repositories.d/cw-opt.list.disabled` for the four steps that enable it.
  `tools/cw-publish-feed.sh` verifies the feed and writes it to a directory for hosting.

## Hardware and flashing

Supported hardware: **Arcadyan AW1000 (Telstra variant) only, with the expanded MTD layout**
(the `rootfs` partition must be at least 128 MiB: check `cat /proc/mtd`; the image needs 410+
UBI blocks and does not fit the 100 MiB stock partition). The first install from the stock
firmware requires serial (UART) access.

From an existing OpenWrt install:

```sh
scp *-arcadyan_aw1000-squashfs-sysupgrade.bin root@192.168.1.1:/tmp/
ssh root@192.168.1.1 "sysupgrade -v /tmp/*-sysupgrade.bin"
```

## First boot

- Hostname `CleanWRT`, timezone UTC (set yours in LuCI).
- No root password, as in stock OpenWrt: connect over **Ethernet**, open
  `http://192.168.1.1` and LuCI asks you to set one. Wi-Fi (`CleanWRT-2.4G` / `CleanWRT-5G`,
  WPA2-PSK) is on with the default key **`CleanWRT#40`**: change it on first login
  (LuCI > Network > Wireless).
- 5G modem: configure it from the **QModem** page in LuCI (Network menu).
- NAS services (SMB, Syncthing, miniDLNA, printer share) are installed but **disabled**;
  enable only what you use.

## Licence

GPL-2.0-only, see `LICENSE`. It covers the build configuration, patches and rootfs overlay
scripts of this repository. The OpenWrt base and each bundled package keep their own upstream
licences, see `NOTICE.md`.
