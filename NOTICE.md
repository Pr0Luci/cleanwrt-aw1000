# Notices

**CleanWRT** is an independent OpenWrt-based firmware build for the Arcadyan AW1000. It is
*Powered by OpenWrt* and is **not** affiliated with or endorsed by the OpenWrt project.
OpenWrt® is a registered trademark owned by Software Freedom Conservancy (SFC) -
https://openwrt.org

This project contains only build configuration and a small rootfs overlay (licensed
GPL-2.0-only, see `LICENSE`). A CleanWRT firmware image, however, is an aggregate of many
independently licensed programs. Each keeps its own licence and copyright; nothing here
relicenses them.

## Principal components

| Component | Licence | Where that was verified |
|---|---|---|
| OpenWrt base system | GPL-2.0-only (individual packages carry their own licences) | `COPYING` / `README.md` of openwrt v25.12.5 |
| LuCI | Apache-2.0 | `LICENSE` of luci (openwrt-25.12) |
| Passwall2 (`luci-app-passwall2`) | GPL-3.0 | `LICENSE` + package Makefile @ pinned commit |
| 3ginfo-lite (`luci-app-3ginfo-lite`) | GPL-3.0 | package Makefile @ pinned commit |
| QModem | MPL-2.0 **plus an added non-commercial clause** - see below | `LICENSE` of FUjr/QModem @ pinned commit |
| Vendor `qmi_wwan_{q,f,s}` kernel modules (from QModem) | GPL (`MODULE_LICENSE("GPL")`) | driver sources @ pinned commit |
| ath11k firmware | Qualcomm Atheros firmware licence (`LICENSE.qca_firmware`) | OpenWrt package Makefile |
| `luci-app-cw-led` (our LED app) | GPL-2.0-only | <https://github.com/Pr0Luci/luci-app-cw-led> |
| `luci-theme-apex` (our LuCI theme; bundled fonts are SIL OFL 1.1) | GPL-2.0-only | <https://github.com/Pr0Luci/luci-theme-apex> |

Every other package's licence is listed, per package, in the generated
[licence manifest](#licence-manifest).

### QModem - read this if you will use the firmware commercially

The `LICENSE` file of the QModem project is the Mozilla Public License 2.0 with an additional
restriction that prohibits commercial use (defined there as use intended for, or directly resulting
in, monetary gain or profit). QModem's own package Makefiles, on the other hand, declare GPLv3 - the
project is inconsistent, and the more restrictive text is the one reproduced here. CleanWRT is
distributed **free of charge and is not sold**, but **you are responsible for your own use**: if you
deploy this firmware in a commercial setting (a business, an ISP, a paid service), check QModem's
`LICENSE` first. Source: <https://github.com/FUjr/QModem>.

**Our patch to QModem.** `patches/feeds/qmodem/0001-status-modem-info-widgets-apex-theme.patch`
modifies one QModem file (`luci/luci-app-qmodem/htdocs/luci-static/resources/view/status/include/11_modem.js`,
the Status -> Modem Info card). It is a modification of QModem's code and stays under QModem's
terms (the same text and restriction as above); the patch header states what was changed and the
patch is published in this repository, which is the source for the modified file.

### 3ginfo-lite feed patches

`patches/feeds/3ginfo/` modifies the upstream 3ginfo-lite package (© Cezary Jackiewicz,
© Rafał Wabik / IceG; GPL-3.0) at build time, applied zero-fuzz to the pinned commit (the
build fails rather than shipping a stale patch): it marks `3ginfo.sh` executable and shortens
one menu title. The patches modify GPL-3.0 files and stay under **GPL-3.0**.

### Passwall packages feed patch

`patches/feeds/passwall_packages/0001-dns2socks-naiveproxy-sources.patch` brings two package
definitions of the pinned Passwall packages feed (`dns2socks`, `naiveproxy`) to the state of
Openwrt-Passwall/openwrt-passwall-packages main, because the files the pinned definitions
download were deleted upstream. It is upstream's own change, unmodified, and stays under the
licences of those files (see their headers).

## Source availability

The complete corresponding source of a CleanWRT image is the combination of the following, all of
which are version-pinned so the same inputs always rebuild the same firmware:

1. **This repository at the release tag** - `configs/arcadyan_aw1000.seed` (package selection),
   `files/` (rootfs overlay), `feeds.conf.default` (every feed pinned to a commit),
   `configs/local-packages.pin` (out-of-feed packages pinned to a commit), `tools/cw-release-build.sh`.
   Out-of-feed packages are pinned to their public repositories (e.g.
   <https://github.com/Pr0Luci/luci-app-cw-led>), which are also the GPL source offer.
2. **OpenWrt at the tag named in `tools/cw-release-build.sh`** (`OPENWRT_TAG`) -
   <https://git.openwrt.org/openwrt/openwrt.git>.
3. **The feeds and packages** at the commits pinned in `feeds.conf.default` and
   `configs/local-packages.pin`.

The README describes how to rebuild. If any pinned source becomes unreachable, open an issue
and we will provide it.

## Licence manifest

`tools/cw-license-manifest.sh` generates a per-package licence table for an image: it reads the
licence recorded inside each package that is really in the image, plus
`configs/license-overrides.tsv` for the few packages that record none (each override cites its
evidence). Anything still unresolved is listed as `UNKNOWN`
rather than guessed. The manifest for a release is published alongside its image.
