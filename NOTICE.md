# Notices

**CleanWRT** is an independent OpenWrt-based firmware build for the Arcadyan AW1000. It is
*Powered by OpenWrt* and is **not** affiliated with or endorsed by the OpenWrt project.
OpenWrt® is a registered trademark owned by Software Freedom Conservancy (SFC) -
https://openwrt.org

This project contains only build configuration and a small rootfs overlay (licensed
GPL-2.0-only, see `LICENSE`). A CleanWRT firmware image, however, is an aggregate of many
independently licensed programs. Each keeps its own licence and copyright; nothing here
relicenses them.

## This fork

This repository is a fork of <https://github.com/Pr0Luci/cleanwrt-aw1000> by Pr0Luci. All
upstream copyright and licence notices are kept. As GPL-2.0 section 2(a) requires, the files
this fork changed or added are listed below, with the date of each change. Every other file is
upstream's, unchanged.

| Date | File | Change |
|---|---|---|
| 2026-11-14 | `.devcontainer/`, `.vscode/tasks.json` | added: dev container and `cw-dev` local build front end |
| 2026-11-14 | `tools/cw-release-build.sh` | modified: `--clean` / `--dirclean` are skipped when the tree has no `.config` |
| 2026-11-14 | `README.md`, `NOTICE.md` | modified: fork notice, change list, credits |

For an image built from this fork, the corresponding source in [Source availability](#source-availability)
is this fork at the matching tag, <https://github.com/ShanelkaPramuditha/cleanwrt-aw1000>, not
upstream.

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
| AWvoice (kernel module, phone daemon, LuCI page) | GPL-2.0-only | shipped with the release |
| `luci-app-cw-led` (this project's LED app) | GPL-2.0-only | <https://github.com/Pr0Luci/luci-app-cw-led> |
| `luci-theme-footstrap` (the theme the image selects) | Apache-2.0, from its own upstream | pinned commit in `configs/local-packages.pin` |
| `luci-theme-bootstrap` (LuCI's own, the fallback) | Apache-2.0 | LuCI feed @ pinned commit |

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

**SIP service patches.** `patches/feeds/qmodem/0004-sip-inbound-answer-delivered.patch`,
`0005-sip-dialog-bye-both-directions.patch` and `0006-sip-cancel-unanswered-lan-invite.patch` modify
one file of `qmodem-sipd` (`application/qmodem_sipd/src/sip_consumer.c`, GPL-2.0-or-later per its own
Makefile) at the pinned commit: they complete the SIP transaction the cellular side opens - the 2xx
ACK a UAC owes (RFC 3261 13.2.1), the BYE either side of the dialog (RFC 3261 15.1.2), an in-dialog
BYE that authenticates by the dialog's own identity (RFC 3261 12.2.2), and the CANCEL of a pending
LAN INVITE with its 487 recognised as the answer to that CANCEL (RFC 3261 9.2, RFC 6026 8).
`0007-sip-inbound-credentials-from-uci.patch` calls the same file's own
`qmodem_voip_sip_credentials_sync()` - defined in `sip_credentials.c` and called nowhere at the
pinned commit - before the inbound credential is read at start and again on the reload signal, so
the UCI section becomes the record and the credential file under `/var/run` becomes derived state;
it adds that file and `libuci` to the consumer's link line in the package Makefile.
`0008-sip-default-config-for-the-phone-bridge.patch` changes only the shipped
`files/etc/config/qmodem_sip`: the media socket, the inbound direction enabled on the LAN, and
`voip_enabled` off in both directions, so the consumer rather than the VoIP-engine wait wrapper is
the program that starts. No password ships. That file is a configuration file of the package, so an
upgrade keeps the router's own copy and writes the new default aside;
`0009-sip-voip-default-migration.patch` adds the `uci-defaults` script that closes that gap - it takes
`voip_enabled` to 0 when, and only when, the media socket in the config is the phone service's own, and
leaves a setup that keeps the VoIP engine's socket untouched. Each header says what it changes and why.
These are modifications of QModem's code and stay under QModem's terms, exactly as above; they are
published here, which is the source of the modified files. **AWvoice contains none of this code** - the
two programs meet over ubus and a unix socket.

**QMI driver patch.** `patches/feeds/qmodem/0010-qmi-wwan-nss-path-behind-its-own-guard.patch` restores one
preprocessor guard in `driver/quectel_QMI_WWAN/src/qmi_wwan_q.c`, so the Qualcomm NSS branch of that driver is
taken only where the kernel configures `CONFIG_RMNET_DATA`. The branch reads a symbol no module in this tree
exports, so without the guard the driver cannot be linked and the package cannot be built. It is the guard the
driver version this pin replaces carried, and a QSDK kernel that does set the symbol still gets the accelerated
path. Same terms as above: a modification of QModem's code, published here.

### Theme patches

`patches/packages/luci-theme-footstrap/0001-login-page-carries-the-image-logo.patch` changes one line of
`luci-theme-footstrap/ucode/template/themes/footstrap/sysauth.ut` at the pinned commit, so the login page
shows this project's logo instead of the router's hostname. It is a modification of Apache-2.0 code, stays
under that licence, and is published here, which is the source of the modified file. The logo itself is
`files/www/luci-static/cw-branding/login-logo.png` - this repository's own file, outside the theme's
directory, so a theme update can neither overwrite it nor collide with the patch.


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
and the source will be provided.

## Licence manifest

`tools/cw-license-manifest.sh` generates a per-package licence table for an image: it reads the
licence recorded inside each package that is really in the image, plus
`configs/license-overrides.tsv` for the few packages that record none (each override cites its
evidence). Anything still unresolved is listed as `UNKNOWN`
rather than guessed. The manifest for a release is published alongside its image.
