---
title: "CleanWRT licence and third-party notices"
description: "CleanWRT is GPL-2.0-only. The principal components and their licences, including the QModem non-commercial clause, and where the source is."
---

# Licence and notices

## This project

The build configuration, patches and rootfs overlay in the
[repository](https://github.com/Pr0Luci/cleanwrt-aw1000) (all repositories: [Repositories](repositories.md)) are licensed **GPL-2.0-only**. The LED
app ([`luci-app-cw-led`](https://github.com/Pr0Luci/luci-app-cw-led)) and the Apex theme
([`luci-theme-apex`](https://github.com/Pr0Luci/luci-theme-apex)) are GPL-2.0-only too; the
theme bundles two fonts under the SIL Open Font License 1.1.

A CleanWRT image is an **aggregate** of many independently licensed programs. Each keeps its own
licence and copyright; nothing here relicenses them.

## Principal components

| Component | Licence |
|---|---|
| OpenWrt base system | GPL-2.0-only (individual packages carry their own licences) |
| LuCI | Apache-2.0 |
| Passwall, Passwall 2 | GPL-3.0 |
| 3ginfo-lite | GPL-3.0 |
| QModem | MPL-2.0 **plus an added non-commercial clause** |
| Vendor QMI kernel modules (from QModem) | GPL |
| ath11k firmware | Qualcomm Atheros firmware licence |
| luci-app-diskman | AGPL-3.0 |
| luci-app-cw-led, luci-theme-apex | GPL-2.0-only |
| AWvoice (kernel module, phone daemon, LuCI page) | GPL-2.0-only |
| libubox / libubus / libuci (used by the AWvoice daemon) | ISC / LGPL-2.1 / LGPL-2.1, linked dynamically |

Every other package's licence is listed per package in the licence manifest published with a
release.

## QModem: read this if you will use the firmware commercially { #qmodem }

QModem's licence is the Mozilla Public License 2.0 with an added restriction that prohibits
commercial use (use intended for, or resulting in, monetary gain or profit). QModem's own
package files declare GPL-3.0, so the project is inconsistent; the more restrictive text is the
one to follow.

CleanWRT is distributed **free of charge and is not sold**, but **you are responsible for your own
use**. If you deploy this firmware in a commercial setting (a business, an ISP, a paid service),
check QModem's licence first: <https://github.com/FUjr/QModem>.

## Patches to third-party code

The patches in `patches/feeds/` modify third-party files at build time and stay under the licence
of the file they modify:

- the QModem patch (the modem widgets on the overview page) stays under QModem's terms;
- the 3ginfo-lite patches stay under GPL-3.0.

The patches are published in the repository, which is the source for the modified files.

## Source availability

The complete corresponding source of an image is the combination of: this repository at the release
tag; OpenWrt at the tag named in the build script; and the feeds and packages at the commits pinned
in `feeds.conf.default` and `configs/local-packages.pin`. If a pinned source becomes unreachable,
open an issue and it will be provided.

## Trademark

OpenWrt® is a registered trademark of Software Freedom Conservancy (SFC) — <https://openwrt.org>.
CleanWRT is not affiliated with or endorsed by the OpenWrt project.
