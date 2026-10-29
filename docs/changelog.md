---
title: "CleanWRT changelog"
description: "What is new in each CleanWRT release for the Arcadyan AW1000."
---

# Changelog

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
- Apex theme with dark and light mode and card-style status widgets.
- Front-panel LED daemon (power, Wi-Fi, 5G type, signal, internet) with a night mode.
- Proxy and VPN tools installed and disabled: Passwall, Passwall 2, HomeProxy, WireGuard,
  OpenVPN, Tailscale, Cloudflare Tunnel.
- Opt-in apps installed and disabled: file sharing, DLNA, printer server, Syncthing, AdGuard Home,
  qBittorrent, Adblock, Disk Manager.
- Built on GitHub Actions in a pinned Docker environment from pinned sources, with checksums
  and a provenance bundle.
