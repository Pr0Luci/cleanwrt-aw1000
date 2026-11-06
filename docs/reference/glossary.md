---
title: "CleanWRT glossary of telephone terms"
description: "Plain definitions of the telephone, radio, router and OpenWrt words this documentation uses, each with the page where you meet it on the router."
updated: 2026-11-06
---

# Glossary

Words the rest of this site uses without stopping to define them. Each entry says where you meet it
on the router.

## Telephone

| term | meaning | where it appears |
|---|---|---|
| **FXS** | the Foreign Exchange Station side: the port that *supplies* line power and ringing to a telephone, which is what an RJ11 socket on a router is | the kernel module's name, `kmod-awvoice-fxs` |
| **SLIC** | Subscriber Line Interface Circuit — the chip that creates the line: its voltage, its ringing, its loop current, and the hook state it reports | [the handset](../awvoice/handset.md), the [line test](../awvoice/health-and-tests.md#the-tests) |
| **loop current** | the direct current that flows through a handset's microphone loop while it is off hook. Its absence means no phone is connected | Health → Line |
| **hook** | on hook = the handset is down; off hook = it is lifted. Everything else follows from that | the line's states |
| **hook flash** | a very short break in the loop, made by the handset's **R** key. Between the two configured windows it counts as a flash rather than as hanging up | [hook-flash codes](../awvoice/handset.md#hook-flash-codes) |
| **DTMF** | the dual-tone keypad signals: the beeps a touch-tone phone sends | dialling, and the caller-id variant named after it |
| **FSK** | the frequency-shift signalling most European and many modern handsets use to receive a caller-id message | `cid` |
| **caller id** | the number (and, here, only the number) sent to the handset's display between or after ring bursts | [caller id](../awvoice/handset.md#caller-id) |
| **CLIR** | Calling Line Identification Restriction: asking the network not to show your number | [the numbers you do not show](../awvoice/handset.md#the-numbers-you-do-not-show) |
| **ring cadence** | the on/off pattern of the ringing voltage. Here 2000 ms on, 4000 ms off | the [ring test](../awvoice/health-and-tests.md#the-tests) |
| **ring trip** | the chip's detector for an actual lift during ringing. A phone whose ringer draws too much can fire it before anyone lifts | the log line `the chip's ring trip fired before any lift` |
| **recall** | the network offering a held call back to you when you hang up. Lift the handset and the call is yours again | [Recall](../awvoice/handset.md#recall) |
| **three-way join** | two calls and this line in one conversation, made with a flash and `3` | `conference` |
| **PCM** | Pulse Code Modulation — the digital audio path between the modem and the line chip, organised into time slots | [how it works](../awvoice/how-it-works.md) |
| **PCM slave mode** | the modem's audio timing driven by the bus rather than generating it. The phone port needs it and reports whether it is set | Health → Modem |
| **HD voice** | wideband audio, 16 kHz instead of 8 kHz | `hd`, and the three health fields that show wish, answer and layout |

## Cellular

| term | meaning | where it appears |
|---|---|---|
| **VoLTE** | Voice over LTE: the call carried as data on the 4G/5G network. Without it there is no voice on this line | what you need for the phone port |
| **IMS** | the IP Multimedia Subsystem — the part of the network that carries VoLTE. Its registration is what the page shows as *VoLTE registered* | Health |
| **RAT** | Radio Access Technology: which radio the modem is actually on — `sa`, `nsa`, `lte`, `3g` | the [5G lamp](../leds.md#how-the-5g-type-is-read) |
| **SA / NSA** | 5G Standalone (its own core) and Non-Standalone (5G radio anchored on LTE). Solid blue and solid green on the panel | the 5G lamp |
| **RSRP** | Reference Signal Received Power, in dBm — the honest signal measure | the signal lamp, the page's signal bars |
| **CSQ** | the older, coarser signal quality number, 0–31. Used only when RSRP is missing | the signal thresholds |
| **CEREG** | the AT command that answers whether the modem is registered. Its `stat` values decide the signal lamp's flashing red | the LED daemon |
| **CGNAT** | Carrier-Grade NAT: your operator shares one public address among many customers, so nothing can reach your router from outside | [remote access](../features/remote-access.md) |
| **APN** | Access Point Name: the network name your SIM dials to get data | QModem |
| **TTL** | Time To Live, the hop counter in every packet. This image can rewrite forwarded packets to a fixed 64 | [the 5G modem](../modem.md) |

## SIP and the network phone

| term | meaning | where it appears |
|---|---|---|
| **SIP** | the signalling protocol that sets up a VoIP call. It carries no voice itself — RTP does | [network phones](../awvoice/network-phones.md) |
| **UAC / UAS** | User Client / User Server: which side of a dialog sent the request. A BYE has to be built by the right one, which is why a hang-up needed fixing | the SIP patches |
| **INVITE, ACK, BYE, CANCEL** | the four requests a call is made of: propose, confirm, end, give up | [what this build changes upstream](../building.md#what-this-build-changes-upstream) |
| **487** | the answer that means "your CANCEL arrived in time" | the same |
| **dialog** | an established call relationship between two endpoints, identified by tags | the in-dialog authentication note |
| **realm** | the name a SIP challenge is issued under, which the phone uses with its password to compute a hash | the account card |
| **RTP** | the media stream: the actual voice packets, in a port range | `rtp_start`, `rtp_end` |
| **registration** | a phone telling the server where it is, refreshed every interval | the outbound card |
| **provisioning** | a phone fetching a file that configures it. Here: one URL in a QR code | [the code a phone scans](../awvoice/network-phones.md#the-code-a-phone-scans) |
| **WebSocket** | a long-lived, full-duplex conversation over one HTTP upgrade. The browser phone's audio travels on one | [the web phone](../awvoice/web-phone.md) |
| **front end** | whatever holds the line's audio at a moment: the handset, the greeting, a network phone, or the browser page | [how it works](../awvoice/how-it-works.md) |
| **DND / quiet hours** | not ringing for a call that arrived. Here it is a schedule with three modes | [quiet hours](../awvoice/quiet-hours.md) |

## Router and OpenWrt

| term | meaning | where it appears |
|---|---|---|
| **OpenWrt** | the Linux distribution this firmware is built from | everywhere |
| **LuCI** | OpenWrt's web interface, which the AWvoice and LED pages are part of | the pages |
| **uci** | the configuration layer: files in `/etc/config/`, read and written with `uci` | [UCI options](options.md) |
| **ubus** | the local message bus services use to answer questions and take orders | [the API](ubus-and-acl.md) |
| **rpcd** | the ubus service that provides `uci`, `file`, `session` — and the plugins this site's pages call | the same |
| **ACL (rpcd)** | the grant that says which ubus methods and which config packages a logged-in user may touch. Snapshotted at login | the permissions table |
| **procd** | the init system that starts services, restarts them on failure, and reloads them on a config trigger | [files and ports](files-and-ports.md#services-and-boot-order) |
| **uci-defaults** | first-boot scripts that write defaults once and delete themselves | [first-boot defaults](uci-defaults.md) |
| **sysupgrade** | the flash-the-whole-image command. With `-v` it keeps settings, with `-n` it does not | [installation](../installation.md) |
| **keep.d** | a package's list of paths that a keep-settings sysupgrade must carry across | [files and ports](files-and-ports.md#the-phone-ports-data) |
| **conffile** | a configuration file owned by a package, kept on upgrade | [first-boot defaults](uci-defaults.md) |
| **apk** | the package manager in OpenWrt 25.12, which is what installs and upgrades packages here | [updating](../updating.md) |
| **feed** | a package source. This build pins five of them to exact commits | [building](../building.md) |
| **MTD / PEB** | the flash partitions, and the erase blocks they are made of. The image must fit the layout | [MTD layout](../mtd-layout.md) |
| **UBI** | the layer that turns erase blocks into volumes. Its arithmetic is what the release gate checks | the same |
| **initramfs** | an image that runs entirely in memory, used for the first install from stock firmware | [installation](../installation.md) |
| **UART / serial console** | the four wires that get you into the bootloader when nothing else works | [UART guide](../uart.md) |
| **TFTP** | the trivial file protocol the bootloader can fetch an image from | [recovery](../recovery.md) |
| **failsafe mode** | a boot state with a fixed IP and no configuration, reached from the bootloader | the same |
| **nftables / fw4** | the firewall. Rules here are installed as `/etc/nftables.d/` fragments | [security](../features/security.md) |
| **SQM / bufferbloat** | queue management that keeps latency down when the link is full | [VPN and proxies](../features/vpn-proxy.md) |
| **mDNS** | the local name advertisement a printer or a share announces itself with | [storage and NAS](../features/storage.md) |
| **captive portal** | a network that intercepts your first request with a login page. The internet probe is designed to detect it | [LEDs](../leds.md#how-the-internet-led-is-decided) |
