---
title: "How the AW1000 phone port works"
description: "The architecture behind AWvoice: the line chip, the PCM bridge, the 20 ms frame, the front-end socket, the ring watchdog, HD voice and the board file."
updated: 2026-11-06
---

# How it works

The call is carried by the router's **5G modem** over VoLTE, which the phone daemon controls
through the modem's AT port. The router drives the line-interface chip of the RJ11 socket and
bridges the two in the kernel, so an ordinary phone behaves like an ordinary phone. There is no
Asterisk and no PBX: the cellular network is the exchange, and the SIM's own number is the line's
number.

## The three packages

| package | licence | what it owns |
|---|---|---|
| `kmod-awvoice-fxs` | GPL-2.0-only | the line chip's register bus, the PCM block, the audio bridge between modem and chip, the capture tap that feeds the recordings and messages, the playback ring that carries a greeting and the page's voice to the caller, and the hardware ring watchdog |
| `awvoice-phoned` | see [licence](../licence.md) | the hook, the tones, dialling, ringing, caller id, the call log, the recordings, the answering machine, quiet hours, the browser audio stream, the front end a network phone speaks through, and the `ubus` service `awvoice` |
| `luci-app-awvoice` | as above | the LuCI page |

The module is built for one exact kernel build, which is why `apk` refuses it on any other kernel
rather than installing something that cannot load.

## A watchdog, not a promise

A thin kernel module owns the register bus, the PCM block and a **hardware ring watchdog**: if the
phone service ever stops, the chip is back in reset within milliseconds. A line cannot be left
ringing, and a line cannot be left live with nothing behind it.

That is the whole safety argument for running the daemon as an ordinary service: the failure mode is
a silent line, not a screaming one.

## The 20 ms frame is the unit everywhere

The kernel bridge hands out one frame per 125 µs slot: **160 samples at 8 kHz**, two time samples
per slot at 16 kHz. The capture side and the playback side are the only two places that convert it,
and nothing else counts slots.

| path | what it carries |
|---|---|
| the caller's voice inward | a lock-free **capture ring** to the daemon, which is also where the recording's channels come from |
| a greeting or the page's voice outward | a matching **playback ring** into the bridge |
| an empty ring | silence, with a counted underrun — **never** a stale frame from an earlier call. Both rings are reset when the bridges stop and start |

This is why the browser stream, the recording file and the kernel all speak in the same 20 ms unit:
there is one number to get right, and one place that converts it.

## The front end's socket

Between the daemon and the front end that carries a network phone: one message per 20 ms frame over
a **unix seqpacket** socket — a stream at the same path would be refused by the kernel. It is
non-blocking throughout, with no threads and no clock of its own.

| | |
|---|---|
| header | twelve little-endian bytes: magic `0x514d534b`, version, type, payload length |
| payload | 160 samples of 16-bit linear audio. The interface carries **8 kHz only**, so any other count is refused with an error frame and the peer closed |
| heartbeat | carries nothing, answers nothing, and refreshes the binding it belongs to |
| bindings | eight live at once |

The two programs meet here and over `ubus`. The phone port contains none of the SIP service's code,
and the SIP service contains none of the phone port's.

## One gate for every action

Answer, dial, hang up, DTMF and route each carry the **call revision** the asker saw, and a refusal
never changes the call.

| case | the rule |
|---|---|
| a hang-up for a call that has already ended | **accepted**. The intent is satisfied, and two people ending a call at the same moment is not an error |
| answering a call that is not ringing | refused, rather than answered early |
| a front end asking for more than the call carries | refused. It may take less, never more |
| a revision that is absent | refused. A revision is never `0` |

## HD voice is a wish, and the modem decides

The chip's band, the PCM slots and the audio bridge are **one layout**, and the slots can only
change while the bus is down.

1. The service asks the modem, read-only, which rate it actually puts on the bus.
2. The line is brought up at that rate **only if the modem answered with the rate that was asked
   for**, and only while nobody is using the line.
3. A change that comes while the handset is up waits for the line to clear.
4. Changing the rate does restart the modem, so mobile data drops for about half a minute.
5. A modem that keeps answering with the other rate is asked a bounded number of times, and the line
   then keeps working at the rate it has, with the reason in the log.

The health reply carries the setting, the modem's answer and the layout the path came up at as
**three separate facts**, which is what makes a refused wish visible instead of mysterious.

## The board file, and the chip's firmware

The line chip needs this board's own values — line voltages, ringing, tones, impedances, the init
sequence — in a board file.

| | |
|---|---|
| where it comes from | a ready board file ships with `awvoice-phoned`, and the first service start installs it at `/etc/awvoice/board.bin`. A file already there is never overwritten |
| why it is in this repository | its contents are **operating parameters** — functional values the hardware requires — not the chip maker's executable code. The values were read from the board's own stock firmware |
| deriving your own | `tools/provision/awvoice-board-extract.py` with the section map `tools/provision/aw1000.map` produce the same format from your router's original firmware |
| the chip's firmware | it runs on the firmware built into the chip. This port uses **no DSP patch file**: none is needed and none ships |
| if a chip does not come ready | the service stops with that cause in the log, instead of leaving a silent dead line |

## The 5 ms clock

All the line logic sits in one daemon on a single **5 ms clock**. The hook is sampled on it, the
tones are stepped on it, and the counters on the Health tab are about it: a hook gap over 20 ms is
the number that explains a choppy flash, and the longest gap is its worst case.

The same core that runs on that clock builds and runs on an ordinary computer with no hardware
attached, which is how the call logic is tested at all: the state machine is handed a synthetic hook
and a synthetic modem, and the assertions are about what it tells the line to do.

## Where to read the code

| part | repository |
|---|---|
| all three packages | [Pr0Luci/openwrt-aw1000-voice-awvoice](https://github.com/Pr0Luci/openwrt-aw1000-voice-awvoice) |
| the SIP service the network phone uses | the QModem feed, pinned in `configs/local-packages.pin` and changed by six patches in `patches/feeds/qmodem/` |
| how the image wires them together | [first-boot defaults](../reference/uci-defaults.md) and [what this build changes upstream](../building.md#what-this-build-changes-upstream) |

## Questions people ask

??? question "Does the phone port need a PBX or an Asterisk?"
    No. The cellular network is the exchange and the SIM's number is the line's number. The router
    drives the line chip and bridges the audio in the kernel, and the daemon holds the call logic.

??? question "Why is the audio path in the kernel rather than in the daemon?"
    Because 20 ms frames have to land in the right slot, and the same frames have to reach the
    recording mirror and the playback ring without a copy through user space. The daemon gets the
    frames; the kernel counts the slots.

??? question "What happens if the phone daemon crashes during a call?"
    The watchdog resets the line chip within milliseconds, so the phone stops ringing and the line
    goes quiet. The service is restarted by the init system, and the call is gone with the modem
    session that carried it.
