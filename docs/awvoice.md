---
title: "AW1000 RJ11 phone port: VoLTE calls with AWvoice"
description: "AWvoice turns the Arcadyan AW1000's RJ11 socket into a phone line. Use an ordinary desk phone for VoLTE calls over the SIM: caller id, hold, three-way calls and more."
---

# AWvoice: an RJ11 phone port with VoLTE calls on the AW1000

**AWvoice** turns the AW1000's RJ11 socket into a working phone line. Plug an ordinary desk
phone into the router and make and take calls over the SIM card, with no extra box, no PBX and no
SIP account. It is the headline feature of CleanWRT, and it ships with the `25.12.5-rc1`
release, in the same way QModem is the 5G modem app.

!!! info "Pre-release documentation"
    This page describes the current state of AWvoice. Details, especially the setup steps, can
    change before `25.12.5-rc1` is published.

## What it does

| | |
|---|---|
| **Calls** | incoming and outgoing calls with clear speech both ways |
| **Tones** | dial tone, ringing tone, busy and congestion tones |
| **In a call** | DTMF, caller id on the handset display (FSK, Bellcore or ETSI, or the DTMF variant, sent before or after the first ring), hook flash |
| **Call waiting** | a second call is announced during a call; hold it, swap between the two, or refuse it |
| **Three-way join** | join two calls into one conversation: **hook flash, then 3** (can be switched off in Settings) |
| **Recall** | put the handset down with a call on hold and the phone **rings back**; lift it to take the call back |
| **Call log** | incoming, outgoing and missed calls, with the names from your phone book |
| **Phone book** | contacts with speed dial |
| **Call blocking** | by direction (incoming or outgoing), by number or by prefix |
| **Hotline** | dial a number automatically when the handset is lifted |
| **Calling-line restriction** | hide your number, and the network's service codes |
| **Phone LED** | solid while the line is ready, a fast blink while a call rings, a slow blink while the handset is off hook (the rates can be set) |
| **Alarm calls** | wake-up calls at a time you choose |
| **Line test** | check the line from the web page |
| **A web page** | *Services → AWvoice(RJ11)* with live status, calls, rules, settings, health and tests |

## Hook flash codes

During a call, press the handset's **flash** (R) key, then one digit. These are the standard
network codes:

| After the flash press | What happens |
|---|---|
| **1** | end the current call and take the other one (the waiting or the held call) |
| **2** | put the current call on hold and take the other one; with two calls it swaps them, and with one held call it takes that call back |
| **0** | refuse the waiting call, or release the held call |
| **3** | **join** the two calls into a three-way conversation (needs two calls, and *three-way calling* switched on in Settings) |

Set the flash key's timing in Settings, if your handset's flash key is longer or shorter than the
default.

## Recall

If you hang up while a call is on hold, the call is not lost. The phone **rings back** until you lift
the handset, which takes the call back, or the other side ends it.

## How it works

The call itself is carried by the router's **5G modem** (VoLTE), which AWvoice controls over its AT
port. The router drives the line-interface chip of the RJ11 port and bridges the audio in the
kernel, so the phone behaves like a normal one. No Asterisk, no SIP.

AWvoice has three parts: a kernel module for the line chip (GPL-2.0-only), the phone daemon, and
the LuCI page.

A watchdog in the kernel puts the line chip back in reset whenever the phone service stops, so the
line is never left ringing.

## Safety

!!! danger "Read this before you use it"
    - About **46 V DC** is present on the RJ11 contacts, and up to about **100 V while the phone is
      ringing**. Do not touch the contacts.
    - **Not for emergency use.** The line works only while the router has power, the modem is
      registered for VoLTE and the operator carries the call. There is no emergency-call
      certification and no battery backup. Keep a mobile phone at hand for emergencies.
    - The block list never blocks your country's national emergency numbers, and a dialled
      emergency number is never replaced by a speed-dial entry.

## What you need

- A SIM and an operator that provide **VoLTE** (voice over LTE).
- The modem in **PCM slave mode**. AWvoice warns in the log if it is not, and does not change
  it by itself.
- Nothing else for the line chip: its **board file ships with AWvoice** and is installed on the
  first start.
- An ordinary **analogue phone** with an RJ11 plug.

AWvoice reads the modem's audio mode and its VoLTE (IMS) state and shows them on the Health area
of the page. It does not change them itself.

## Turn it on

AWvoice is installed with CleanWRT but the phone service starts only when you enable it, so the
line is never left ringing by accident:

```sh
uci set awvoice.main.enabled=1
uci commit awvoice
/etc/init.d/awvoice start
```

The defaults fit the AW1000. The settings the page does not show (the modem's AT interface number,
the LED name) are in `/etc/config/awvoice`.

## The web page

*Services → AWvoice(RJ11)* is one page for everything:

- **live status:** the line (idle, off hook, ringing, in a call), the current call, the voice
  network and the signal;
- **calls:** the call log, with names from the phone book;
- **phone book and speed dial;**
- **rules:** call blocking, forwarding and alarm calls;
- **settings:** caller id mode, hook-flash timing, tones, audio levels, call waiting, hotline and
  the line LED;
- **health and tests:** the AT port, the line, the modem, counters and the log, with ring, line and
  loopback tests.

## Frequently asked questions

??? question "How do I make phone calls on the Arcadyan AW1000?"
    Install CleanWRT, which includes AWvoice, plug an ordinary analogue desk phone into the RJ11
    socket, enable the phone service and lift the handset. Calls go out over the router's 5G modem
    with your SIM's number.

??? question "Which phones work on the RJ11 port?"
    An ordinary analogue (tone dial) phone with an RJ11 plug. A handset with a display also shows
    the caller id.

??? question "Does AWvoice need Asterisk, SIP or a second phone number?"
    No. There is no PBX and no SIP account. The cellular network is the exchange and the SIM's
    number is the line's number.

??? question "Does the AW1000 need VoLTE for voice calls?"
    Yes. The call is carried by the modem over VoLTE, so you need a SIM and an operator that
    provide VoLTE. The modem must also be in PCM slave mode, which AWvoice checks and reports.

??? question "Can I use it for emergency calls?"
    No. The line works only while the router has power, the modem is registered for VoLTE and the
    operator carries the call, and there is no battery backup. Keep a mobile phone at hand.

## Known limits

- Hide my number (CLIR) and call forwarding can be refused by the operator's network when the
  phone registers (`+CME ERROR: 30`). The page hides both while that is the case.
- Giving up a second call while it still rings ends every call: the modem cannot release a
  ringing leg on its own.
- The modem's IMS registration may not come up after a cold boot, rarely. The page then shows
  "Not registered", and a modem restart clears it.
- Alarm calls trust the router's clock, which must be set. A wrong but plausible clock rings them
  at the wrong time.
- **Not for emergency calls**, see the safety box.

## Source code

AWvoice is developed in its own repository,
[Pr0Luci/openwrt-aw1000-voice-awvoice](https://github.com/Pr0Luci/openwrt-aw1000-voice-awvoice),
which has the standard feed layout (see [Build from source](building.md)). All three parts are
GPL-2.0-only; see [Licence and notices](licence.md).
