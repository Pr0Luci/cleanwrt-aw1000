---
title: "AWvoice troubleshooting for the AW1000"
description: "No dial tone, one-way audio, no caller id, a machine that will not answer, a soft phone with no sound: each symptom and the one check that decides it."
updated: 2026-11-06
---

# Troubleshooting

One table per area, and each row names **the one check that decides it**. Start at the
[Health tab](health-and-tests.md) before you change anything: it is the page that reports facts
rather than a conclusion.

!!! tip "Before anything else"
    ```sh
    /etc/init.d/awvoice status              # is the service up
    logread -e awvoice-phoned | tail -30    # what it said, and why
    ls -l /etc/awvoice/                     # the board file, the greeting, the folders
    ```

## No dial tone, or a dead line

| check | if | then |
|---|---|---|
| the service | not running | start it from **Health → Service**, or `/etc/init.d/awvoice start`. If `enabled` is `0` it refuses to start — that is the switch, not a failure |
| the kernel module | not loaded | the module and the daemon are a matched pair. Install both from one release and reboot; a loaded module stays loaded until then |
| the chip | *Line chip: Not answering* on Health | the board file is missing or the chip did not come ready. The service stops with that cause in the log rather than leave a silent line |
| the phone | line healthy, no tone | another phone on the same pair, a long extension cable, or a handset that is not an ordinary analogue tone phone |
| the hook | *Hook* says off hook with the handset down | the handset is not sitting properly, or `flash_max_ms` is too high so a long hook break is read as off hook |

## Audio problems

| symptom | the one check | what it means |
|---|---|---|
| **One-way audio on a network phone** | `/etc/config/qmodem_sip` → `main.media_socket_path` | it must be `/var/run/awvoice-phoned/media.sock`. This is the classic case: the call is fine, the audio path is not |
| No audio from the browser page | the **Browser audio** chip | `idle` means no session: press *Use this computer's microphone and speaker*. `starting` forever usually means the certificate step was never done in this browser |
| Garbled or stretched speech on a wideband call | **Audio mode** on Health: `audioRate` and `voiceLayout` | the two must agree. A rate that came up one way and is played the other is the bug this pair of fields exists to show |
| Audio breaks up, or the line goes quiet mid-call | **System** counters: *Resyncs*, *Frames skipped*, *Longest gap* | the bridge is losing step. Look for something else holding the modem's audio |
| The caller hears an echo of themselves | the handset | a handset with a loud sidetone on a long cable. Nothing on the router can be echoed back to the caller |

## Registration and network

| symptom | the one check | what it means |
|---|---|---|
| *No service* on the banner | **Modem, SIM and VoLTE** → *Network registration* | the modem is not registered at all. This is a [modem](../modem.md) question, not a phone question |
| Registered, but calls fail | *VoLTE registration* | IMS is not up. A modem restart clears the case where registration does not come up after a cold boot |
| Calls work, no HD voice | *Audio mode*: `hdVoice` and the modem's answer | the wish was refused by the modem. The line keeps working at the rate it has, and the reason is in the log |
| `+CME ERROR: 30` in the log | the operator | the SIM does not carry the supplementary service you asked for — usually CLIR or call waiting |

## Caller id

| symptom | the one check | what it means |
|---|---|---|
| Nothing on the handset display | `cid` | the signalling mode does not match the phone. Try the DTMF variant, then FSK Bellcore, then FSK ETSI |
| It appears only sometimes | `cid_when`, and your operator | the message sits in the gap before the first ring or after it, and some networks will not send it early |
| The name is wrong or missing | the phone book | names come from your own contacts, matched in international form. The network's name field is not used |
| The number looks strange | `region` | the plan decides the display form. `auto` follows the network the line registered on |
| A caller shows as **Withheld** | nothing is wrong | the caller restricted their number. The page hides the block buttons for such a row, because there is no number to block |

## Recordings and the answering machine

| symptom | the one check | what it means |
|---|---|---|
| The machine never answers | the greeting card's status line | there is no readable greeting, or `machine_enabled` is off. The machine will not answer with noise |
| The card says the greeting cannot be used | **Play** it | it is not 16-bit PCM, or not 8/16 kHz, or over 2 MB. Play works on a file the machine refuses, which is how you find out |
| No recordings for calls I answered | `record_enabled` | off as installed. It records from the moment it is switched on, not before |
| Old recordings vanished | the *Storage budget* | the folder passed its megabyte budget and the oldest went |
| The flash is filling | `du -sh /etc/awvoice/recordings /etc/awvoice/messages` | both live on flash. This is the usual reason a phone router's storage grows |
| A call the machine answered has no message | the message cap | `machine_max_s` ended the recording, or the caller said nothing after the tone |

## Network phones

| symptom | the one check | what it means |
|---|---|---|
| The switch says `absent` | **SIP → Diagnostics** | there is no SIP service installed on this router |
| The switch says `denied` | your login's permissions | starting and stopping that service is a separate grant. See [the API and who may call it](../reference/ubus-and-acl.md) |
| The switch says `waiting` | the call | a call is in progress and will not be cut. The service moves when it ends |
| The phone registers, cannot set up media | **Who holds the name (`qmodem_voip`)** | if it says `voipd`, the vendor engine got there first. This image takes it off the boot path on first boot |
| The phone registers, inbound calls do not ring it | the inbound direction, and the account name and password in the app | the port is `5060` on the LAN interface, and the password is not shown on the page — type it, or create a new one |
| Outbound through a provider fails | the outbound card | the direction ships with no server, no realm and no password. It has to be configured before it can work |
| The QR code will not appear | the card's words | it names the reason: switch off, no account name, the stored password cannot be read back, no address on the network yet, or no plain listener to serve it |

## Quiet hours

| symptom | the one check | what it means |
|---|---|---|
| The phone rings inside a window | the window order | the **first** window covering the moment decides. An earlier window that matches wins |
| The phone never rings | `all_day`, or a window that wraps into itself | a window covering 24 hours is a permanent quiet |
| The caller hears nothing | the window's mode | *Answering machine* with the machine switched off leaves the caller in silence until the network gives up |
| A ring-through number is still held | the stored form | matching is in international form. Write it the way the network sends it, or mark the contact instead |
| Nothing is honoured at all | the router's clock | an untrusted clock never quiets the line from a schedule. A hand-asked quiet (`*78`) needs no clock |

## Log strings you will actually see

| the log says | what it means |
|---|---|
| `the handset takes the front end's call` | a lift during a browser or network-phone call. The call continued at the phone |
| `three-way calling is off` | a flash and `3` with `conference` unset. The key was declined, not lost |
| `the chip's ring trip fired before any lift` | the handset's ringer drew more than the chip's detector allows. The burst was cut on purpose |
| `no modem port yet (USB interface N)` | the modem's interface is not enumerated yet. The line works without calls until it appears |
| `the chip did not come ready` | the service stopped rather than leave a silent dead line |
| `machine_greeting is no longer used` | an option left by an older release. It is ignored |

## Still stuck

1. Take the **Health** tab's screenshot or `ubus call awvoice health` output.
2. Grab the log: `logread -e awvoice-phoned`, and read it before you paste it — the shell version is
   not masked.
3. Say which release you are on (`cat /etc/openwrt_release`) and which of the three front ends you
   were using: handset, browser page, or network phone.
4. Open an issue on [GitHub](https://github.com/Pr0Luci/cleanwrt-aw1000/issues). Never paste a
   password, a key or a full IMEI.
