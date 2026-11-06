---
title: "The AW1000 handset: dial tone, flash, caller id"
description: "How the AW1000's RJ11 line behaves: dialling and the pause rule, hook-flash codes, call waiting, hold, three-way, recall, caller id and the phone LED."
updated: 2026-11-06
---

# The handset

This page is the line as an ordinary telephone behaves: what you hear, what the keys do, and what
the settings behind each behaviour are. The browser's own phone is [a separate page](web-phone.md),
and what happens when nobody answers is
[the answering machine](recordings-and-machine.md#the-answering-machine).

## The states the line reports

The page's Overview tab shows one word for the line, and every other control follows from it.

| state | what it means |
|---|---|
| **Idle** | the handset is on the hook and the line is ready. A dial tone is available |
| **Handset lifted** | off hook: the line is open, dialling is accepted, nothing is connected yet |
| **Ringing** | an incoming call is announcing itself to the handset |
| **In call** | a call is up, and the audio path is carrying it |
| **No service** | the modem is not registered, so the line cannot be used until it is |
| **Phone service down** | the daemon is not running. The line chip is in reset, so the phone cannot ring |

!!! note "A dead service is a silent line, by design"
    When `awvoice-phoned` stops, the kernel module's watchdog puts the line chip back into reset
    within milliseconds. A phone that keeps ringing after its daemon dies is the failure this
    prevents. See [how it works](how-it-works.md#a-watchdog-not-a-promise).

## Tones

Dial tone while off hook and idle, ringing tone toward the caller you are dialing, busy and
congestion at the ends of a failed attempt. What you hear while waiting for a answered call is
decided by one option:

| `ringback` | what you hear before the other side answers |
|---|---|
| `auto` (default) | the router's own progress tone until the network's audio arrives, then the network's |
| `on` | the local tone, always |
| `off` | nothing until the call is answered |

Tone levels and the modem's receive gain are settings on the *Settings* tab; two of them,
`earpiece_volume` and `modem_rx_gain`, are written to the modem only when you set them, and are
unset out of the box.

## Dialling

Digits are collected while you dial and released to the network when the number ends. A number ends
on a pause: `dial_pause_s`, between 3 and 15 seconds, **6 by default**. A handset that sends digits
slowly needs the longer end of that range; a fast keypad can go shorter.

Three-digit service codes need a longer hook break than a flash. The two windows are separate on
purpose: the handset's flash window (`flash_min_ms` 80 to `flash_max_ms` 300 by default) decides
what counts as a flash, and a code typed inside the window that follows it is read as a code, not as
a digit. That is why a flash followed by `3` joins two calls and a long hook break followed by a
service code reaches the network.

A **hotline** number goes out by itself when the handset is lifted: set the number, and
`hotline_delay_s` (**10** by default) is the window in which you can still dial somewhere else.

## Hook-flash codes

Press the handset's **flash** (R) key during a call, then one digit:

| after the flash | what happens |
|---|---|
| **1** | end the current call and take the other one — the waiting call, or the held one |
| **2** | put the current call on hold and take the other; with two live calls this swaps them, with one held call it takes it back |
| **0** | refuse the waiting call, or release the held one |
| **3** | **join** the two calls into one three-way conversation. Needs two calls up **and** *3-way calling* switched on in Phone settings, which it is not as installed |

The same codes are on the browser page's [Flash button](web-phone.md), which is the handset's flash
key in the same slot.

!!! warning "Refusing a second call while it still rings"
    Giving up a ringing second call ends **every** call on the line. The modem cannot release a
    ringing leg on its own, so the network releases the dialog. Take the call first, then hang up.

## Call waiting, hold and three-way

`call_waiting` is **on** by default. A second call is announced during a call — a 500 ms tone every
five seconds — and you can hold the first call and take the second, swap between them, or refuse the
newcomer. With `call_waiting` off the second call is refused on arrival.

The **three-way join is a separate switch**: `conference`, **off as installed**. A flash and `3` with
it off does nothing but log `three-way calling is off`, so the key is not lost, it is declined. Turn
it on in *Phone settings → Features → 3-way calling* if you want it.

## Recall

Put the handset down while a call is on hold and the call is not lost: the phone **rings back**
until you lift it, which takes the call back, or the other side ends it.

This is also the rule that decides who owns a call the browser page put on hold. A lift during a
page call carries the call on at the handset — the log records the handset as the one that answered
it, and the page's microphone and speaker stop with it. A call the *page* held is **not** taken by
a lift: the lift gets the recall dial tone and the held call stays the page's.

## Caller id

The number and name are sent to the handset's display as a message on the line. Two settings decide
it, and both are visible on the *Settings* tab:

| `cid` | the signalling the handset expects |
|---|---|
| `dtmf` (default) | the DTMF variant, which most cheap handsets understand |
| `bellcore` | FSK, Bellcore framing |
| `etsi` | FSK, ETSI framing |
| `off` | nothing is sent |

| `cid_when` | where the message sits relative to the first ring |
|---|---|
| `ring1` (default) | after the first ring |
| `prering` | in the gap before it, which some handsets need and some networks ignore |

`cid_when` matters only for the two FSK modes. With `cid` on the DTMF variant the message goes out
while the phone is ringing, and the page shows the timing control **disabled**, because there is
nothing for it to decide.

A caller-id message carries **digits only**. How those digits are *displayed* — national form,
international form, with or without the name from your phone book — is decided by the numbering
plan, `region`: `auto` (**default**) follows the network the line registers on, across 43 regions,
or you can name one. The number the network sent is never rewritten; the plan decides the shape it
is shown in.

!!! tip "Nothing appears on the handset display"
    Check `cid` first: a handset that expects FSK shows nothing when the router sends the DTMF
    variant, and the other way round. Then check `cid_when`. The [Tools tab](health-and-tests.md)
    can transmit a caller-id message on demand, which tells you whether the line is sending it at
    all.

## The numbers you do not show

**Calling-line restriction** (CLIR) hides your number on the calls you place: `clir` takes
`network` (the default, which asks nothing), `hide` or `show`, and maps to `AT+CLIR=0|1|2`.
**It has no control on the page** — it is set in `/etc/config/awvoice`, and saving the page leaves
whatever is stored there untouched. The [Health tab](health-and-tests.md) reports what the network
provisioned, as `not_provisioned`, `provisioned`, `unknown`, `restricted` or `allowed`, so a
restriction that the operator will not carry is visible rather than assumed.

Network service codes are dialled as you would dial them on any phone. A prefix of `#31#` or `*31#`
on a dialled number is understood as a per-call restriction request and is stripped before any
blocking rule looks at the number.

`my_number` is a display-only setting. Whatever you put there appears on the page so you know which
number this line is; nothing is ever dialled from it.

## The phone LED

The front-panel phone LED follows the line, and one option names it: `led`, which ships as
`green:phone`. Set it to an empty value and the LED is left alone entirely.

| the line | the LED |
|---|---|
| ready | solid |
| a call is ringing | fast blink — `ring_rate_ms`, **300** by default |
| the handset is off hook | slow blink — `offhook_rate_ms`, **1000** by default |

The other five lamps on the panel belong to
[LED Management](../leds.md), which does not touch this one while AWvoice is running.

## Settings on this page

| option (`awvoice.main`) | values | default | the page calls it |
|---|---|---|---|
| `dial_pause_s` | `3`–`15` | `6` | Dial pause |
| `flash_min_ms` / `flash_max_ms` | `20`–`500` / `300`–`3000` | `80` / `300` | Flash window |
| `call_waiting` | `0` \| `1` | `1` | Call waiting |
| `conference` | `0` \| `1` | `0` | 3-way calling |
| `cid` | `dtmf` \| `bellcore` \| `etsi` \| `off` | `dtmf` | Caller id mode |
| `cid_when` | `ring1` \| `prering` | `ring1` | Caller id timing |
| `ringback` | `auto` \| `on` \| `off` | `auto` | Ringback |
| `region` | `auto` \| a region name | `auto` | Numbering plan |
| `hotline_delay_s` | seconds | `10` | Hotline delay |
| `led` | an LED name, or `''` | `green:phone` | Phone LED |
| `ring_rate_ms` | milliseconds | `300` | Ring blink rate |
| `offhook_rate_ms` | milliseconds | `1000` | Off-hook blink rate |
| `my_number` | digits | unset | My number |

`flash_max_ms` must be at least 100 ms above `flash_min_ms`; the page refuses a pair that is not.
The full option list, including the ones the page does not show, is in the
[settings reference](settings-reference.md).

## When it misbehaves

| symptom | the one check that decides it |
|---|---|
| No dial tone with the handset lifted | is the service running and the modem registered? The Overview word tells you which of the two it is |
| Digits are cut off, or the call dials early | `dial_pause_s` is too short for your handset |
| A flash does nothing | the handset's flash is shorter than `flash_min_ms` or longer than `flash_max_ms`; the [Tools tab](health-and-tests.md) reads the chip's hook state |
| Nothing on the handset display | `cid`, then `cid_when`, then the transmit test |
| The LED will not follow the line | `led` names a lamp that exists on this board; `''` means leave it alone |
| A restriction you set is not honoured | `health` reports the network's provisioning word. That is the operator, not the router |

## Questions people ask

??? question "Can I use any phone on the AW1000's RJ11 socket?"
    An ordinary analogue phone with a tone dial and an RJ11 plug. A handset with a display shows the
    caller id, if the signalling mode matches what the phone expects. Pulse-dialling phones are not
    supported.

??? question "How do I get a three-way call on the AW1000?"
    Switch on *3-way calling* in **Phone settings → Features** — it is off as installed — then take
    the second call and press the handset's flash key followed by `3`. Both calls must be up.

??? question "Why does my phone not ring back a held call?"
    Recall works when the call was put on hold by the handset. A call the browser page put on hold
    stays the page's — lifting the handset gives you the recall dial tone for the handset's own held
    call, not the page's.

??? question "Does the caller id work with the number in international form?"
    The message on the line carries digits. The numbering plan decides how they are displayed, and
    `region` set to `auto` follows the network the line registered on.
