---
title: "CleanWRT first-boot defaults"
description: "Every first-boot script in the CleanWRT image: what it writes, the exact option and value, when it leaves your settings alone, and how to undo each one."
updated: 2026-11-06
---

# First-boot defaults

OpenWrt runs the scripts in `/etc/uci-defaults/` in name order on a clean boot. A script that exits
`0` is deleted, so it runs once; one that exits non-zero stays and is retried at the next boot.
This page is the complete list of what this image writes, and what it deliberately does not touch.

Everything here is in the repository under `files/etc/uci-defaults/`, so a router that has already
booted can be checked against the source.

!!! tip "These scripts run before you log in"
    The first boot is when the defaults below are written. A setting you change afterwards is not
    overwritten by a later `sysupgrade` that keeps settings — with the two exceptions noted in their
    rows.

## The image's own scripts

| script | what it writes | when it leaves things alone |
|---|---|---|
| `45-cw-strip-stock-leds` | removes the LuCI menu node `admin/system/leds` from `luci-mod-system.json` and deletes the stock `view/system/leds.js`, then clears the LuCI caches. The [LED Management](../leds.md) daemon owns those lamps | it writes the menu file back only if the System menu is still intact and the LEDs node really went; the `led` sections in `/etc/config/system` are **not** removed, nor the WAN port lamp |
| `46-cw-uhttpd-https` | `uhttpd.main.redirect_https='1'`, so plain HTTP becomes HTTPS | exits quietly if `/etc/config/uhttpd` is missing |
| `47-cw-awvoice-at-port` | deletes the `ubus-at-daemon` port section, which frees `/dev/ttyUSB2` for the [phone port](../awvoice.md). QModem keeps `ttyUSB3` | only if that config file exists. To undo: re-add the port section with its `at_port` set to `/dev/ttyUSB2` |
| `48-cw-strip-asu-ui` | removes the Attended Sysupgrade menu node and deletes its views, turns the Status page's newer-version check **on** (`attendedsysupgrade.client.login_check_for_upgrades='1'`) — those views are the only switch that ever turned it on, so the notice is on out of the box and its own button is the way off — then clears the caches. `attendedsysupgrade-common` stays | it writes the menu back unless the node is gone, and skips the option where the config has no `client` section. See [releases](../releases.md#the-new-version-notice) for what the notice does |
| `49-cw-awvoice-provision-port` | adds a second uhttpd instance, `uhttpd.awvoice_provision`: `listen_http='0.0.0.0:8080'`, `home='/www/awvoice-provision'`, `redirect_https='0'`, `no_dirlists='1'`, `rfc1918_filter='1'`, and creates that directory. This is the plain-HTTP listener a [scanned provisioning code](../awvoice/network-phones.md#the-code-a-phone-scans) points a soft phone at | exits if `/etc/config/uhttpd` is missing. To undo: delete the section, remove the directory, restart uhttpd |
| `50-cw-footstrap-look` | writes the image's look into `/etc/config/footstrap` — 27 options: `layout='top'`, `darkmode='dark'`, `palette='footstrap'`, `wallpaper='file'`, `material='frosted'`, `blur='30'`, `rounding='12'`, `card_opacity='55'`, `bar_opacity='55'`, `photo_dim='15'`, `pattern_size='440'`, `pattern_strength='20'`, `pattern_ink='theme'`, `content_width='1280'`, `density='normal'`, `autocollapse='off'`, colour tints at `0`, plus `login_bg` and `pattern` set to the **checksums of the two files the image installs**, and `cw_look='rc2.1'` | three reasons to do nothing: the router already carries the look this script names; the current `login_bg` is a photo that is not one of the image's two files; or either installed file's checksum cannot be read. Your own saved look always outranks the image's. See [theme](../theme.md#the-look-a-new-router-starts-with) |
| `51-cw-awvoice-voipd-off` | stops the vendor VoIP engine `qmodem_voip` and takes it off the boot path, so the phone daemon can answer the front-end name itself and the [network phone](../awvoice/network-phones.md) carries audio | exits if the init script is not executable. It **fails** — and retries next boot — if any boot link for that engine survives other than the SIP service's own. This is the fix for a soft phone that registers and never sets up media |
| `96-cw-apk-world-pin` | rewrites `/etc/apk/world` from the installed package database: every package that came from the LuCI feed, plus `base-files`, `kernel` and any `kmod-*`, is pinned to its exact version; everything else is written as a bare name and stays upgradable | it runs on **every** boot, so the pins always match the running image. The reason is recorded in the script: one `apk upgrade` once replaced patched LuCI packages with stock ones |
| `96-cw-default-theme` | `luci.themes.Footstrap=/luci-static/footstrap` and `luci.main.mediaurlbase=/luci-static/footstrap`, and deletes a dead marker section an older image left | only if `/www/luci-static/footstrap` exists **and** the current base is empty, still the stock bootstrap, or names a directory that no longer exists. If you chose another theme, your choice stands |
| `97-cw-adguard-enable-bridge` | hands off to `/usr/libexec/cw-adguard-enable-bridge`, which wires AdGuard Home's local upstream so the router's own DNS still resolves when the filter is enabled | a non-zero exit keeps the script for a retry at the next boot |
| `97-cw-net-tuning` | `network.globals.packet_steering='1'`, spreading receive and transmit work over the four cores | unconditional |
| `98-cw-modem-fix` | `/etc/init.d/cw-modem-fix enable`, which puts the modem registration fix on the boot path | unconditional. See [the 5G modem](../modem.md) |
| `99-aw1000-defaults` | `system.@system[0].hostname='CleanWRT'`, `.timezone='UTC'`, `.log_size='64'`; `dropbear` password authentication and root password authentication `on`; for each radio: enabled, `ssid='CleanWRT-2.4G'` / `'CleanWRT-5G'` / `'CleanWRT-6G'` by band, `encryption='psk2'`, `key='CleanWRT#40'` | the Wi-Fi **key is written only if no key is set yet**, so a keep-settings upgrade never regenerates it. The regulatory domain is deliberately not hardcoded — it follows the network the modem registers on. The root password is left unset on purpose. `psk2` rather than `sae-mixed` because some clients failed to associate otherwise |

## Scripts that arrive with packages

Three more first-boot scripts matter to this image even though they belong to other packages:

| script | where it comes from | what it does |
|---|---|---|
| `90-cw-led` | [`luci-app-cw-led`](https://github.com/Pr0Luci/luci-app-cw-led) | removes from `/etc/config/system` every `led` section whose sysfs node is one the LED daemon owns (`blue:5g`, `green:5g`, `red:5g`, `blue:signal`, `green:signal`, `red:signal`, `green:internet`), reseeds the daemon's own `global` section only if it is missing, enables the service and reloads rpcd. `green:power`, `green:wifi` and the WAN lamp keep their kernel triggers |
| `89-qmodem-sip-migrate`, `90-qmodem-sip-firewall`, `91-qmodem-sip-voip-off` | the QModem feed's SIP service, the last one added by this build's patch `patches/feeds/qmodem/0009-sip-voip-default-migration.patch` | migrate a configuration that still pointed at the vendor engine, add the service's firewall include, and set both directions' `voip_enabled` to `0` **only when** the media socket path is the phone daemon's — which is how an upgrade from an older image ends up with working audio |
| `30_luci-theme-argon` | Argon, with one line removed by `patches/packages/luci-theme-argon/0001-argon-registers-itself-and-leaves-the-default.patch` | registers the theme but no longer makes it the default design. An installed theme is offered, not selected |

## What the image ships as configuration

The scripts above change things; these files are simply there from the start. Full option lists are
in [UCI options](options.md).

| file | state on a new router |
|---|---|
| `adblock` | `adb_enabled='0'`. Off until you tick the checkbox on its page |
| `fstab` | USB drives are auto-mounted under `/mnt`; no anonymous swap, no filesystem check at boot |
| `irqbalance` | enabled |
| `minidlna` | `enabled='0'`; when on, port 8200 on the LAN, media from `/mnt`, name `CleanWRT` |
| `p910nd` | `enabled='0'`; when on, `/dev/usb/lp0` with an mDNS advertisement labelled `CleanWRT USB printer` |
| `qmodem_ttl` | **enabled**, TTL of forwarded packets rewritten to `64` |
| `samba4` | the daemon starts, with one share (`USB` → `/mnt`, writable) and `guest_ok='no'`, so nothing is reachable until you add users |
| `syncthing` | `enabled='0'`; when on, its own interface on `0.0.0.0:8384` and its config in `/etc/syncthing` |
| `watchcat` | **comment lines only, no sections.** The package default is an active "ping, reboot after 6 failures" rule; this file replaces it so the router never reboots itself unless you add a rule |
| `cw-led`, `awvoice`, `footstrap`, `qmodem_sip` | shipped by their own packages, not here, so an upgrade keeps what you changed |

## Reading it on your router

Nothing here is hidden. On a flashed router:

```sh
ls /etc/uci-defaults/          # what is still waiting to run
logread -e cw-firstboot        # what the image's own scripts said
uci show footstrap             # the look the image applied
uci show awvoice               # the line, the network side, the quiet-hours windows
```

A script that already ran is gone from that directory, which is why the log and the config — not
the leftovers — are the evidence of what happened.
