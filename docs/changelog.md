---
title: "CleanWRT changelog"
description: "What is new in each CleanWRT release for the Arcadyan AW1000."
---

# Changelog

## 25.12.5-R2.2

The radio page, *Modem → 3gInfo-lite*, is rebuilt, and one collector now answers every card on it.

- **One page, no tabs.** Signal health, serving cells, network, neighbour cells, diagnostics and
  identity are cards down a single page. The summary at the top names the registration state, the
  operator, the mode — LTE, 5G NSA with its LTE anchor, or 5G SA — and whether carrier aggregation
  is active, with the age of the reading beside it.
- **Serving cells per carrier.** Each component carrier has its own card with band, EARFCN or NR
  ARFCN, PCI, RSRP, RSRQ and SINR, and the 5G leg of an EN-DC connection is shown beside its LTE
  anchor rather than replacing it. The neighbour table keeps its signal filter, search and sort,
  and says how old the scan is.
- **Five seconds by default.** The snapshot refresh and the neighbour scan both offer 5, 15 and 30
  seconds, 1 and 5 minutes, and start at five seconds. Neighbours scan themselves while the page is
  open; the manual *Scan now* button stays. The collector enforces the same floor, so a page left
  open cannot turn into a stream of AT commands.
- **A duration, and a last error.** The diagnostics card reports how long a collection took and what
  the last one failed with, so a page that stops updating says why instead of going quiet.
- **The theme draws the boxes.** The cards are the theme's own section container, so the wallpaper
  and glass modes, the dark scheme and any installed theme apply to them as they do everywhere else
  in LuCI.

Behind the page is `radiodata.sh`, one script behind a lock with a short cache. It reads QModem over
`ubus` when the daemon answers, falls back to the package's own `3ginfo.sh` when it does not, and
keeps the per-carrier `AT+QCAINFO` output as a table. The page presents what it returns and reads no
modem itself.

## 25.12.5-R2.1

The second stable release of the OpenWrt 25.12.5 base. The line is quieter, and the new-firmware
notice works from the first boot:

- **AWvoice 1.1.5** (R1 shipped 1.1.3). A refused call no longer leaves the line busy: the audio
  path stands by again instead of running for silence, which showed on the Health card and in the
  load average. The step before it made an idle line cost nothing, set a factory modem in PCM
  master mode to slave by itself, let a call go out on either voice domain, kept the page's send
  level under its ceiling, and put the serving cell and one signal line on the Health card.
- **the new-firmware notice is on out of the box.** Its answer is written by
  `files/etc/uci-defaults/52-cw-upgrade-check`; *Stop showing upgrade alerts* stays the way off.
- **that answer is written after the package's own defaults**, so a fresh flash keeps it and an
  answer you gave is not asked again.
- **the Attended Sysupgrade pages are out of the menu**, with the two pages under them.

## 25.12.5-R1

The first stable release of the OpenWrt 25.12.5 base. It carries everything `25.12.5-rc2.1`
shipped — AWvoice 1.1.3 with the LAN SIP side, the web phone, the code a phone scans and quiet
hours, Footstrap as the default look, Alpha and Argon alongside it, the phone bridge's working
defaults and the vendor VoIP engine kept off the boot path — and adds two changes:

- **the provenance bundle is verifiable**. `sha256sums.cw` names the bundle's files under
  `cw-release-provenance/`, while the release step packed them as `provenance/`, so the checksums
  could not be run against the bundle. The bundle now keeps the name the checksums use, and the
  build unpacks it again and verifies those lines before anything is uploaded.
- The LED Management picture in the documentation is the page as the released package draws it:
  the live status strip takes its surface from the active theme and the form is LuCI's own.

## 25.12.5-rc2.1

- **AWvoice 1.1.3** (rc2 shipped 1.1.2). The phone port gains its **SIP side**. A switch on the new
  SIP tab starts and stops the LAN SIP service this image now carries, so a soft phone on your own
  network rings and dials through the SIM's line beside the handset on the RJ11 port; the tab shows
  the accounts and passwords it uses and what it reports while a call is up. The page also carries a
  **web phone** - the handset's audio in the browser - and a **code a phone can scan**, which writes
  the account a soft phone fetches into a directory of its own. Wideband voice follows what the modem
  answers, the caller-id message and the ring supervision were corrected, and the front end now
  behaves the same in every mode. The same version also carries **quiet hours**: windows of the day
  that hold the handset, the answering machine and the network phones off a ringing call, contacts
  marked to ring through one, and the `*78`, `*79` and `#` codes on the handset and the page. The
  vendor's VoIP engine is kept off the boot path (`files/etc/uci-defaults/51-cw-awvoice-voipd-off`)
  so the phone daemon itself serves the SIP side.
- **Six patches to that SIP service.** Three complete the transaction the cellular side opens: the
  2xx ACK a UAC owes, the BYE from either side of a dialog with the in-dialog authentication an
  in-dialog BYE needs, and the CANCEL of an unanswered LAN INVITE with its 487 recognised. One makes
  the UCI section the record of the inbound credential, one sets the defaults the phone bridge needs,
  and one migrates a configuration that kept the VoIP engine's socket ([AWvoice](awvoice.md)).
- **The web interface is Footstrap**, an upstream Apache-2.0 LuCI theme pinned to one commit and
  changed by one line of it - the login page now carries the CleanWRT logo where the theme prints the
  router's hostname. The LuCI feed now carries a copy of this theme too, at an older commit and under
  the same package name; the image ships the pinned one, and the build says on every run which
  package it took out of the feed to do that. The theme that shipped before it is out of the image, with the five feed
  patches written for it - four that drew card-style status widgets and one that read a CPU counter.
  The stock Bootstrap theme stays as the fallback and Argon and Alpha ship beside it for comparison, with
  the one line of Argon's first-boot script that claimed the default removed - an installed theme is
  offered, not selected. Alpha keeps the Lua template layout it was written for, so its pages are the one
  thing in this image that may not render as intended on 25.12; choosing it changes nothing else.
  A new router starts at the look
  `files/etc/uci-defaults/50-cw-footstrap-look` writes, with the photo and the pattern that go with
  it ([theme](theme.md)).
- `files/etc/uci-defaults/49-cw-awvoice-provision-port` opens the plain HTTP listener that serves the
  scanned account file, on the LAN only, from a directory that holds nothing else.
- The QModem feed pin moves to the commit that first carries that SIP service.
- Terminal moves from the Tools menu to System, and Tools sits where its own order says.

## 25.12.5-rc2

- **AWvoice 1.1.2** (rc1 shipped 1.0.0). The phone port gains **call recordings**: a call you
  answer is kept as a stereo WAV, the caller and the handset on separate channels, played, saved
  or deleted from the call's card. Off by default, with a size budget that removes the oldest.
- **The answering machine**: after a delay you set, an unanswered call hears your greeting and
  leaves a message, played, saved or deleted from the call's card. Off until a greeting is on the
  router; picking up the handset takes the call over and keeps the part of the message already
  recorded.
- **Caller id**: the message goes out framed, from on-hook transmission between the ring bursts,
  and the handset shows the national number with the name from your phone book.
- An upgrade keeps the line: the module loads from the installed package and the daemon checks
  its interface before it drives the line, instead of running against whatever module the boot
  had loaded.
- The three AWvoice packages share one version, 1.1.2.

## 25.12.5-rc1

First release candidate.

- OpenWrt 25.12.5 base for the Arcadyan AW1000 (`qualcommax/ipq807x`, kernel 6.12.94).
- AWvoice: an ordinary desk phone on the RJ11 port makes and takes calls over the SIM, with caller
  id, call waiting, hold, three-way join (flash + 3), recall of a held call, call log, speed dial,
  call blocking, hotline and alarm calls.
- 5G stack: QModem, vendor QMI dialer, 3ginfo-lite with a registration fix for data-only SIMs,
  SMS, TTL, vnStat.
- A dark interface theme with dark and light mode, a sidebar and card-style status widgets.
- Front-panel LED daemon (power, Wi-Fi, 5G type, signal, internet) with a night mode.
- Proxy and VPN tools installed and disabled: Passwall, Passwall 2, HomeProxy, WireGuard,
  OpenVPN, Tailscale, Cloudflare Tunnel.
- Opt-in apps installed and disabled: file sharing, DLNA, printer server, Syncthing, AdGuard Home,
  qBittorrent, Adblock, Disk Manager.
- Built on GitHub Actions in a pinned Docker environment from pinned sources, with checksums
  and a provenance bundle.
