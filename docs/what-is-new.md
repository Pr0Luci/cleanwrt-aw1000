---
title: "What is new in each CleanWRT release"
description: "Each CleanWRT release for the Arcadyan AW1000 read the other way: what arrived, what changes if you come from the release before, and the page that explains it."
updated: 2026-11-11
---

# What is new

The [changelog](changelog.md) is the record of what shipped. This page is the same history read the
other way round: what changes for you if you are on the release before.

!!! note "Which release am I on?"
    ```sh
    cat /etc/openwrt_release
    ```
    The LuCI login footer shows the same string. The version is also the first line of the
    [Health tab](awvoice/health-and-tests.md)'s log view.

## 25.12.5-R2.3

This release takes the extra themes out of the image.

| if you are on | you gain |
|---|---|
| `R2.2` | the image stops carrying Argon and Alpha: Footstrap is the design, Bootstrap is the fallback, and an upgrade removes the entries the design selector would otherwise keep offering |
| `R2.1` | the same, plus the rebuilt modem page |
| older | the same, plus everything the releases between changed |

If you had picked Argon or Alpha, the web interface opens on Footstrap after the upgrade. Choosing
Bootstrap under *System → System → Language and Style → Design* still works; the removed themes are
no longer offered, because their files are not in the image any more.

## 25.12.5-R2.2

This release rebuilds the modem page as one page.

| if you are on | you gain |
|---|---|
| `R2.1` | the rebuilt *Modem → 3gInfo-lite* page: one scrolling page of cards instead of tabs, serving cells per carrier, a neighbour table that scans itself, five-second defaults for both the refresh and the scan, and the collection duration and last error in the diagnostics card |
| `R2` | the same, plus the ASU fixes and the version label R2.1 added |
| `R1` | the same, plus everything between R1 and R2.1 |

The menu name does not change. The data behind the page comes from one collector, so the cards
cannot disagree with each other about when the reading was taken.

## 25.12.5-R2.1

The second stable release. The line is quieter, and the update notice works from the first boot.

| if you are on | you gain |
|---|---|
| `R1` | AWvoice 1.1.5: a refused call no longer holds the line busy, and an idle line costs nothing. The update notice is on as installed, your answer is kept, and the Attended Sysupgrade pages are gone |
| `rc2.1` or earlier | everything in the R1 row below, then this |

Nothing else moves: the theme, the modem packages and every other pin are R1's. The notice is the
one on *Status → Overview*, and it never installs anything
([the notice](releases.md#the-new-version-notice)).

## 25.12.5-R1

The first stable release of the OpenWrt 25.12.5 base. It carries everything `25.12.5-rc2.1` shipped.

| if you are on | you gain |
|---|---|
| `rc2.1` | one packaging fix: `sha256sums.cw` can now be run against the provenance bundle, because the bundle is packed under the name its own checksums use, and the build verifies that before uploading anything |
| `rc2` | everything in the rc2.1 row below, plus the same packaging fix |
| `rc1` | everything in both rows |

Nothing about the phone port, the theme or the modem changes between rc2.1 and R1: the package pins
are the same commits. The documentation pages moved, though — the phone port now has
[its own section](awvoice.md), and the image's first-boot behaviour is written down in
[first-boot defaults](reference/uci-defaults.md).

## 25.12.5-rc2.1

The one release where the phone port became a system rather than a feature.

| what arrived | what it means for you | the page |
|---|---|---|
| **AWvoice 1.1.3** | rc2 shipped 1.1.2. The line gains a network side | [network phones](awvoice/network-phones.md) |
| **the SIP switch** | a soft phone on your own LAN can ring and dial through the SIM's line, beside the handset. The switch starts and stops the service that does it, and waits for a call in progress to end before it moves | the same |
| **the web phone** | the Overview tab is a telephone: keypad, call rail, flash key with its codes, mute, two level meters. It works with the RJ11 socket empty | [the web phone](awvoice/web-phone.md) |
| **a code a phone can scan** | Linphone builds its own account from a URL the page serves for ten minutes | [the code a phone scans](awvoice/network-phones.md#the-code-a-phone-scans) |
| **quiet hours** | windows of the day when the handset, the machine and the network phones do not ring, three modes, ring-through numbers, `*78` / `*79` / `#` | [quiet hours](awvoice/quiet-hours.md) |
| **HD voice that follows the hardware** | the setting is a wish; the modem's own answer decides the rate, and the line is only brought up at it while nobody is using it | [how it works](awvoice/how-it-works.md#hd-voice-is-a-wish-and-the-modem-decides) |
| **caller id and ring supervision corrected** | the message framing and the ring trip behave as documented rather than as the chip happens to | [caller id](awvoice/handset.md#caller-id) |
| **six patches to the SIP service** | the 2xx ACK, the in-dialog BYE from either side, the CANCEL of an unanswered LAN INVITE, the credential record, the bridge defaults, a configuration migration | [what this build changes upstream](building.md#what-this-build-changes-upstream) |
| **Footstrap as the default look** | the theme that shipped before it is out of the image, along with the five feed patches written for it. Argon and Alpha stay for comparison, and an installed theme is offered rather than selected | [the theme](theme.md) |
| **the vendor VoIP engine off the boot path** | the fix for "the soft phone registers but no call goes through" | [the 5G modem](modem.md#the-sip-service-that-arrives-with-this-feed) |
| **a plain HTTP listener for provisioning** | port 8080, LAN only, document root holding nothing else | [files and ports](reference/files-and-ports.md) |

## 25.12.5-rc2

The phone port's first release as a full feature set.

| what arrived | the page |
|---|---|
| **call recordings** — stereo WAV, the caller and the handset on separate channels, off by default, with a size budget | [recordings](awvoice/recordings-and-machine.md#call-recordings) |
| **the answering machine** — your greeting after a delay, a message kept with the call, take-over by lifting the handset | [the machine](awvoice/recordings-and-machine.md#the-answering-machine) |
| **caller id framed and transmitted** from on-hook between ring bursts, with the national display form | [caller id](awvoice/handset.md#caller-id) |
| **an upgrade keeps the line** — the module loads from the installed package and the daemon checks its interface before it drives the line | [how it works](awvoice/how-it-works.md) |

## 25.12.5-rc1

The first public build: OpenWrt 25.12.5 for the AW1000 with the 5G stack working, the theme, the LED
daemon, the opt-in app set and the release machinery — checksums, provenance, and a build that fails
rather than ship something stale.

## What never changed

| | |
|---|---|
| the device | Arcadyan AW1000 only, and only with the expanded flash layout |
| the base | OpenWrt 25.12.5 throughout this series |
| the first-login model | `192.168.1.1` over Ethernet, no root password, HTTPS with a self-signed certificate |
| the opt-in rule | nothing that listens starts until you enable it. The one exception worth naming is the phone line, which is **on** as installed because a phone that does not ring is the failure people notice first |
| how releases are made | a tag builds a draft, the images are checked, and publication is a separate deliberate step |

## Next

| | |
|---|---|
| The record as shipped | [changelog](changelog.md) |
| Downloading and verifying | [releases](releases.md) |
| Everything the phone port does | [AWvoice](awvoice.md) |
