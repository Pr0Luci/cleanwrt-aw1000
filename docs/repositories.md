---
title: "CleanWRT repositories and how they fit together"
description: "The CleanWRT firmware, AWvoice, the LED app and the Apex theme: what each repository is, how they are pinned together, and where to report issues."
---

# Repositories

CleanWRT is built from a few small repositories, all on GitHub under
[Pr0Luci](https://github.com/Pr0Luci). The firmware repository pins the others to an exact commit.

| Repository | What it is | Documentation |
|---|---|---|
| [cleanwrt-aw1000](https://github.com/Pr0Luci/cleanwrt-aw1000) | the firmware: build configuration, patches, rootfs overlay, workflows and this documentation | [Build from source](building.md), [Contributing](contributing.md) |
| [openwrt-aw1000-voice-awvoice](https://github.com/Pr0Luci/openwrt-aw1000-voice-awvoice) | AWvoice: the kernel module, the phone daemon and the LuCI page for the RJ11 port | [AWvoice](awvoice.md) |
| [luci-app-cw-led](https://github.com/Pr0Luci/luci-app-cw-led) | the front-panel LED daemon and its LuCI page | [Front-panel LEDs](leds.md) |
| [luci-theme-apex](https://github.com/Pr0Luci/luci-theme-apex) | the Apex LuCI theme | [The Apex theme](theme.md) |

## How they fit together

```text
cleanwrt-aw1000  (feeds.conf.default, configs/local-packages.pin, patches/)
   ├── pins  luci-app-cw-led      → LED daemon and page
   ├── pins  luci-theme-apex      → default theme
   ├── pins  AWvoice              → phone port
   └── pins  OpenWrt, LuCI, QModem, Passwall, 3ginfo-lite, ... (upstream feeds)
```

A change in one of the smaller repositories reaches the firmware only when the firmware repository
moves its pin to the new commit. That is a pull request of its own, so every release is built from
commits you can read.

## Where to report things

- A problem with the firmware, a package or these docs: an issue in
  [cleanwrt-aw1000](https://github.com/Pr0Luci/cleanwrt-aw1000/issues).
- A problem that is clearly inside one of the other parts: an issue in that repository.
- A mistake on a docs page: *Edit this page* (the pencil at the top of every page) opens it on
  GitHub, and a pull request fixes it.
