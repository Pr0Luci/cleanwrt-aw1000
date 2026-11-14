---
title: "CleanWRT UCI options reference"
description: "The configuration options CleanWRT sets out of the box, package by package: the shipped value, what it changes, and the page that explains the feature."
updated: 2026-11-06
---

# UCI options

OpenWrt keeps its configuration in UCI files under `/etc/config/`, one file per package, and LuCI
writes the same files the shell does. This is the index of the options this image cares about.

Read a value with `uci show <package>`; change one with `uci set`, then `uci commit <package>`.

!!! warning "Committing by hand does not restart anything"
    `uci commit` writes the file. It does not reload the service, and it does not tell LuCI's page —
    which reloads only when you press its save button. After a hand edit, either restart the
    service named in the row below, or use the page.

## `awvoice` — the phone line

The full reference, including the options the page hides and the quiet-hours and contact sections,
is on the phone port's own page: [settings reference](../awvoice/settings-reference.md). The short
form:

| option | shipped | what it decides |
|---|---|---|
| `main.enabled` | `1` | the whole line. Off means the chip is in reset and the phone is silent |
| `main.channel` | `1` | which of the chip's two channels is this line |
| `main.board` | `/etc/awvoice/board.bin` | the board file: the chip's operating values |
| `main.at_interface` | `2` | the modem USB interface holding the voice AT port |
| `main.cid` / `main.cid_when` | `dtmf` / `ring1` | caller-id signalling, and where it sits relative to the first ring |
| `main.hd` | `0` | HD voice wanted. The modem's own answer decides what is used |
| `main.region` | `auto` | the numbering plan that decides display form |
| `main.ringback` | `auto` | local progress tone, or the network's audio |
| `main.call_waiting` | `1` | the second call, and with it the three-way join |
| `main.flash_min_ms` / `main.flash_max_ms` | `80` / `300` | the hook-flash window |
| `main.dial_pause_s` | `6` | how long a pause between digits ends the number |
| `main.led` | `green:phone` | the indicator lamp, or `''` to leave it alone |
| `main.ring_rate_ms` / `main.offhook_rate_ms` | `300` / `1000` | the LED's blink rates |
| `main.hotline_delay_s` | `10` | the window before a hotline number goes out |
| `main.record_enabled` / `record_path` / `record_max_mb` | `0` / `/etc/awvoice/recordings` / `50` | call recordings |
| `main.machine_enabled` / `machine_delay` / `machine_max_s` / `machine_max_mb` / `machine_path` | `0` / `10` / `120` / `50` / `/etc/awvoice/messages` | the answering machine |
| `main.web_port` / `web_iface` / `web_cert` / `web_key` | `7443` / `lan` / `/etc/uhttpd.crt` / `/etc/uhttpd.key` | the browser phone's encrypted audio stream |
| `main.my_number` | unset | display only; nothing is dialled from it |
| `main.earpiece_volume` / `main.modem_rx_gain` | unset | written to the modem only when set |
| `sip.mode` | `web` | whether a phone on your own network may join the line, and it starts or stops that service when saved |
| `dnd.<name>` | none shipped | one section per quiet-hours window |
| `contact.<name>` | none shipped | phone-book entries, with `ring_through` |

## `cw-led` — the front panel

Every option, its range and whether the page shows it, is in the
[LED settings table](../leds.md#settings). The ones that surprise people:

| option | shipped | note |
|---|---|---|
| `global.enabled` | `1` | the daemon runs from the first boot |
| `global.tick` | `5` | not on the page. Every interval below is counted in ticks |
| `modem.port` | `/dev/ttyUSB2` | the port freed for the LED daemon by `47-cw-awvoice-at-port` |
| `night.exempt` | all five lamps | nothing is switched off at night until you remove one |
| `internet.mode` | `http204` | the active probe; `interface` and `ping` are the alternatives |
| `internet.probe_down_fail` | `2` | two failed probes are needed to extinguish the lamp |

## `qmodem_sip` — the service a network phone uses

This file belongs to the SIP service in the QModem feed, and the AWvoice page treats it as another
program's settings — it reads them back and never stores a secret. The values this image ships,
after its [patch](../building.md#what-this-build-changes-upstream):

| option | shipped | what it means here |
|---|---|---|
| `sipd.main.media_socket_path` | `/var/run/awvoice-phoned/media.sock` | where the service hands audio. This is the setting that makes a soft phone audible on a fresh router |
| `sipd.main.rtp_start` / `rtp_end` | `40000` / `40031` | the media port range |
| `direction.inbound.enabled` | `1` | a phone on your LAN may call in |
| `direction.inbound.interface` / `listen_port` / `transport` | `lan` / `5060` / `udp_tcp` | where it listens |
| `direction.inbound.username` | `awvoice` | the account name a soft phone signs in with |
| `direction.inbound.password` | `CleanWRT#40` | the same secret as the default Wi-Fi key, so a router has one pair to remember. Change it on the AWvoice page |
| `direction.inbound.voip_enabled` | `0` | the vendor VoIP engine is not used; the phone daemon carries the front end |
| `direction.inbound.sms_enabled` | `0` | SMS stays with QModem |
| `direction.outbound.realm` / `password` | unset | the outbound direction, which reaches a server outside the house, ships no secret |
| `direction.outbound.register_interval` | `300` | seconds between registration attempts |
| `direction.outbound.voip_enabled` | `0` | as above |

Nothing in this file is *started* by the image. The service runs when the AWvoice page's switch
starts it, and no SIP port is open until then.

## `footstrap` — the look

The image writes 27 options on first boot, listed option by option in
[first-boot defaults](uci-defaults.md) and explained in [the theme](../theme.md). The two that
behave differently from the rest:

| option | what it holds |
|---|---|
| `settings.login_bg` | the **checksum** of the photo file, not a path. It is how the first-boot script recognises its own default |
| `settings.cw_look` | the name of the look the image applied. A router that already carries it is left alone |

## `uhttpd` — the web server

| option | shipped | why |
|---|---|---|
| `main.redirect_https` | `1` | plain HTTP becomes HTTPS. See [security](../features/security.md) |
| `awvoice_provision.listen_http` | `0.0.0.0:8080` | the plain listener that serves a scanned provisioning file, with directory listings off and the private-network filter on |
| `awvoice_provision.home` | `/www/awvoice-provision` | a directory that holds nothing else |

## `wireless`, `system`, `network`, `dropbear`

| option | shipped | note |
|---|---|---|
| `wireless.<radio>.ssid` | `CleanWRT-2.4G`, `CleanWRT-5G`, `CleanWRT-6G` | by band |
| `wireless.<iface>.encryption` / `key` | `psk2` / `CleanWRT#40` | the key is written only when none is set |
| `system.@system[0].hostname` | `CleanWRT` | |
| `system.@system[0].timezone` | `UTC` | set yours; alarm calls and quiet hours trust the clock |
| `system.@system[0].log_size` | `64` | the log buffer in KiB |
| `network.globals.packet_steering` | `1` | receive work spread over the four cores |
| `dropbear.@dropbear[0].PasswordAuth` / `RootPasswordAuth` | `on` / `on` | with no root password set, so the first login is over Ethernet |

## The rest of the shipped files

`fstab`, `irqbalance`, `minidlna`, `p910nd`, `qmodem_ttl`, `samba4`, `syncthing` and
`watchcat` — every value and what it means in behaviour, in
[first-boot defaults](uci-defaults.md#what-the-image-ships-as-configuration).

## Where to go next

| | |
|---|---|
| What each file and port is | [files and ports](files-and-ports.md) |
| What the phone daemon answers over `ubus` | [the API and who may call it](ubus-and-acl.md) |
| What the image writes at first boot | [first-boot defaults](uci-defaults.md) |
