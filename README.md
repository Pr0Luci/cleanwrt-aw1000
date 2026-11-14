<p align="center">
  <img src="docs/assets/img/banner.svg" alt="CleanWRT for the Arcadyan AW1000" width="100%">
</p>

<p align="center">
  <a href="https://pr0luci.github.io/cleanwrt-aw1000/docs/"><img alt="Documentation" src="https://img.shields.io/badge/docs-online-14b8a6?style=for-the-badge"></a>
  <a href="https://github.com/Pr0Luci/cleanwrt-aw1000/releases"><img alt="Version" src="https://img.shields.io/badge/CleanWRT-25.12.5--R2.1-14b8a6?style=for-the-badge"></a>
  <a href="LICENSE"><img alt="Licence" src="https://img.shields.io/github/license/Pr0Luci/cleanwrt-aw1000?style=for-the-badge&color=14b8a6"></a>
  <a href="https://github.com/Pr0Luci/cleanwrt-aw1000/actions/workflows/check.yml"><img alt="Checks" src="https://img.shields.io/github/actions/workflow/status/Pr0Luci/cleanwrt-aw1000/check.yml?style=for-the-badge&label=checks"></a>
</p>

# CleanWRT: OpenWrt for the Arcadyan AW1000

> [!NOTE]
> **This is a fork.** CleanWRT was created and is maintained by
> [Pr0Luci](https://github.com/Pr0Luci) at
> [Pr0Luci/cleanwrt-aw1000](https://github.com/Pr0Luci/cleanwrt-aw1000). This fork,
> [ShanelkaPramuditha/cleanwrt-aw1000](https://github.com/ShanelkaPramuditha/cleanwrt-aw1000),
> follows upstream and adds a few changes of its own, listed under
> [Changes in this fork](#changes-in-this-fork). The fork is not affiliated with or endorsed by
> the upstream project.
>
> The documentation, release and issue links below point to upstream and describe the upstream
> build. Report problems with an image built from this fork in
> [this fork's issues](https://github.com/ShanelkaPramuditha/cleanwrt-aw1000/issues), not upstream.

CleanWRT is an independent build of **OpenWrt 25.12.5** for the **Arcadyan AW1000** 5G router
(Qualcomm IPQ8072, Quectel RG500Q-EA modem). It is made for people who want the router to simply
work: a phone on the RJ11 socket, a 5G modem that dials and recovers by itself, a modern interface,
and the usual power tools, all switched off until you ask for them.

The whole image is built in the open on GitHub from pinned sources, and every release comes with
checksums and a provenance bundle.

> CleanWRT is *Powered by OpenWrt* and is not affiliated with or endorsed by the OpenWrt project.
> OpenWrt® is a registered trademark of Software Freedom Conservancy (SFC) - https://openwrt.org

<p align="center">
  <a href="docs/assets/img/overview-dark.jpg"><img src="docs/assets/img/overview-dark.jpg" alt="The Status overview of CleanWRT in dark mode" width="92%"></a>
</p>

## Highlights

| | |
|---|---|
| **AWvoice, a phone on the router** | Plug an ordinary desk phone into the RJ11 socket and make and take calls over your SIM. Caller id, call waiting, hold, a three-way join, recall of a held call, a call log, call recordings, an answering machine, speed dial, call blocking and alarm calls. No extra box, no PBX, no SIP account. |
| **5G that just works** | QModem, auto-dial and auto-recovery, dual-stack IPv4/IPv6, SMS, TTL control, per-interface data usage, and a registration fix for data-only SIMs. |
| **A modern interface** | Footstrap: dark or light mode, a top bar or a sidebar, five palettes, an accent colour you choose, frosted surfaces, and a photo or pattern behind the pages. |
| **LEDs that mean something** | The 5G LED shows SA or NSA, the signal LED shows quality, the internet LED runs a real connectivity check, and night mode switches them off at bedtime. |
| **Tools, but off by default** | HomeProxy, WireGuard, OpenVPN, Tailscale, Cloudflare Tunnel, Syncthing, qBittorrent, DLNA, file sharing and a printer server. Nothing listens until you tick **Enable**. |
| **Careful defaults** | HTTPS for the admin UI, no hidden remote access, BBR congestion control, pinned LuCI so an `apk upgrade` cannot undo the build. |
| **Verifiable builds** | Built on GitHub Actions in a pinned Docker environment from commits you can read, with checksums and a provenance bundle for each release. |

## Screenshots

<table>
  <tr>
    <td align="center" width="50%"><a href="docs/assets/img/leds-dark-status.jpg"><img src="docs/assets/img/leds-dark-status.jpg" alt="LED Management with the live status card"></a><br><sub>LED Management: live state of the panel LEDs</sub></td>
    <td align="center" width="50%"><a href="docs/assets/img/overview-light.jpg"><img src="docs/assets/img/overview-light.jpg" alt="The Status overview in light mode"></a><br><sub>Light mode follows your system, or the toggle</sub></td>
  </tr>
  <tr>
    <td align="center"><a href="docs/assets/img/login-dark.jpg"><img src="docs/assets/img/login-dark.jpg" alt="The login page"></a><br><sub>The login page</sub></td>
    <td align="center"><a href="docs/assets/img/overview-mobile.jpg"><img src="docs/assets/img/overview-mobile.jpg" alt="The Status overview on a phone" width="34%"></a><br><sub>Made to be used from a phone</sub></td>
  </tr>
</table>

<sub>The screenshots come from a development preview of the interface with a simulated modem. Values such as the kernel, memory and storage differ on a real router.</sub>

## Before you flash

> [!CAUTION]
> **Supported hardware: the Arcadyan AW1000 only, with the expanded flash layout.** The image does
> not fit the stock layout, and flashing it there can leave the router unbootable. Check first:
>
> ```sh
> cat /proc/mtd
> ```
>
> The `rootfs` partition must be **at least `0x08000000`** (128 MiB). If it shows up as `rootfs_bak`
> instead, stop. Read the [MTD layout page](https://pr0luci.github.io/cleanwrt-aw1000/docs/mtd-layout/).

> [!IMPORTANT]
> The very first install from the stock firmware needs a **serial console (UART)** and a TFTP
> server. Read [Installation](https://pr0luci.github.io/cleanwrt-aw1000/docs/installation/) and
> [Recovery](https://pr0luci.github.io/cleanwrt-aw1000/docs/recovery/) before you start.

## Quick install

If the router already runs OpenWrt, and `cat /proc/mtd` is fine:

1. Download the `*-squashfs-sysupgrade.bin` from the
   [Releases page](https://github.com/Pr0Luci/cleanwrt-aw1000/releases) and check it:

   ```sh
   sha256sum -c sha256sums.cw --ignore-missing
   ```

2. Copy it to the router:

   ```sh
   scp cleanwrt-*-sysupgrade.bin root@192.168.1.1:/tmp/
   ```

3. Flash it. Use `-n` (a clean install) when you come from another firmware, because the theme and
   some settings change names:

   ```sh
   ssh root@192.168.1.1 "sysupgrade -n -v /tmp/cleanwrt-*-sysupgrade.bin"
   ```

## First boot

| | |
|---|---|
| Address | `http://192.168.1.1` (over Ethernet) |
| Root password | none: LuCI asks you to set one |
| Wi-Fi | `CleanWRT-5G`, `CleanWRT-2.4G`, WPA2-PSK, default key `CleanWRT#40` |
| Hostname, time zone | `CleanWRT`, UTC |

> [!WARNING]
> Change the root password and the Wi-Fi key on the first login.

## Documentation

Everything is on the documentation site: **https://pr0luci.github.io/cleanwrt-aw1000/docs/**

| Page | What is in it |
|---|---|
| [Installation](https://pr0luci.github.io/cleanwrt-aw1000/docs/installation/) | UART + TFTP for the first install, `sysupgrade` afterwards |
| [MTD layout](https://pr0luci.github.io/cleanwrt-aw1000/docs/mtd-layout/) | what must fit, and how to check your router |
| [Recovery](https://pr0luci.github.io/cleanwrt-aw1000/docs/recovery/) | failsafe, bootloader recovery, the way back |
| [AWvoice](https://pr0luci.github.io/cleanwrt-aw1000/docs/awvoice/) | the phone port, flash codes, safety |
| [The 5G modem](https://pr0luci.github.io/cleanwrt-aw1000/docs/modem/) | QModem, signal, SMS, TTL, modem firmware |
| [Front-panel LEDs](https://pr0luci.github.io/cleanwrt-aw1000/docs/leds/) | what every LED shows, night mode, settings |
| [What is included](https://pr0luci.github.io/cleanwrt-aw1000/docs/included/) | every app, where to find it, its default state |
| [Build from source](https://pr0luci.github.io/cleanwrt-aw1000/docs/building/) | GitHub Actions, Docker, pins, signing |
| [FAQ](https://pr0luci.github.io/cleanwrt-aw1000/docs/faq/) | known limits and common questions |

## How it is built

The repository holds only build configuration, patches and the rootfs overlay. The build runs on
GitHub Actions inside a pinned Docker image, applies the overlay and the patches to a clean OpenWrt
`v25.12.5` tree, and **fails** rather than ship something stale: every feed and every package is
pinned to a commit, a patch that no longer applies stops the build, and the image must fit the
flash layout.

```sh
git clone --depth 1 --branch v25.12.5 https://github.com/openwrt/openwrt.git openwrt
docker build -t cleanwrt-builder docker/
docker run --rm -v "$PWD/openwrt":/build -v "$PWD":/cleanwrt \
  cleanwrt-builder /cleanwrt/tools/cw-release-build.sh /build --clean
```

`CW_CHECK_ONLY=1` runs every check and stops before compiling. See the
[build page](https://pr0luci.github.io/cleanwrt-aw1000/docs/building/) for signing and the optional
package feed.

## The parts

| Repository | What it is |
|---|---|
| [cleanwrt-aw1000](https://github.com/Pr0Luci/cleanwrt-aw1000) | this repository: configuration, patches, overlay, workflows, documentation |
| [AWvoice](https://github.com/Pr0Luci/openwrt-aw1000-voice-awvoice) | the phone port: kernel module, daemon and LuCI page |
| [luci-app-cw-led](https://github.com/Pr0Luci/luci-app-cw-led) | the front-panel LED daemon and its page |
| [luci-theme-footstrap](https://github.com/VizzleTF/luci-theme-footstrap) | the web interface: the theme the image selects |

## Help and contributions

- A bug or a question: open an [issue](https://github.com/Pr0Luci/cleanwrt-aw1000/issues) and fill in
  the form. Please never paste passwords, keys or full IMEI/IMSI numbers.
- A fix or an improvement: open a pull request. `main` is protected, the checks must pass, and
  changes are squash-merged. See [Contributing](https://pr0luci.github.io/cleanwrt-aw1000/docs/contributing/).
- A mistake in the docs: every page has an *Edit this page* button.

## Changes in this fork

| Change | Files |
|---|---|
| A VS Code dev container and the `cw-dev` front end for local builds | `.devcontainer/`, `.vscode/tasks.json` |
| `--clean` / `--dirclean` are skipped on a fresh tree with no `.config`, where OpenWrt would otherwise open an interactive menuconfig and fail in CI | `tools/cw-release-build.sh` |
| Faster builds: the cross gdb (never in the image) is no longer built, and CI falls back to the last download and compiler cache of the same OpenWrt tag when the seed or feed pins change | `configs/arcadyan_aw1000.seed`, `.github/workflows/build.yml` |
| Passwall, Passwall 2, AdGuard Home and Adblock removed: their feeds, packages, vendored LuCI app, first-boot files, patch and docs. HomeProxy on sing-box (official packages feed) is the one proxy app | `feeds.conf.default`, `configs/`, `feeds-src/cwfeed/`, `files/`, `patches/feeds/`, `tools/`, `docs/` |

Everything else is upstream's work, unchanged. The fork offers these changes back upstream where
they fit.

## Thanks

This fork is built on [CleanWRT](https://github.com/Pr0Luci/cleanwrt-aw1000) by
[Pr0Luci](https://github.com/Pr0Luci), who wrote the build, the overlay, the patches, the
documentation and the companion repositories listed above. Thanks for publishing it as free
software.

Thanks also to [XT-Martinez](https://github.com/XT-Martinez) for
[aw1000-feed](https://github.com/XT-Martinez/aw1000-feed), an AW1000 package feed for the
`ppe-nss` OpenWrt tree. This fork's dev container has it alongside as a reference for
comparison. None of its code is in this repository or in the image.

CleanWRT stands on the work of others: the [OpenWrt](https://openwrt.org) project and its
contributors, [QModem](https://github.com/FUjr/QModem),
[HomeProxy](https://github.com/immortalwrt/homeproxy),
[3ginfo-lite](https://github.com/4IceG/luci-app-3ginfo-lite),
[luci-app-diskman](https://github.com/lisaac/luci-app-diskman), and the ImmortalWrt packages that
carry qBittorrent to LuCI. Each keeps its own licence, see
[NOTICE.md](NOTICE.md).

## Licence

GPL-2.0-only, see [LICENSE](LICENSE). It covers the build configuration, patches and rootfs overlay
scripts of this repository. Upstream's code stays © Pr0Luci and its contributors. This fork's
changes are released under the same licence. The OpenWrt base and each bundled package keep their own upstream
licences.

> [!NOTE]
> **QModem** carries an added non-commercial clause. CleanWRT is free of charge and is not sold,
> but if you deploy it in a business, for an ISP or in a paid service, read QModem's licence first.
> See [Licence and notices](https://pr0luci.github.io/cleanwrt-aw1000/docs/licence/).
