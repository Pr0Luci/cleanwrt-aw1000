---
title: "Phone book, speed dial, blocking, alarms"
description: "The Rules tab on the AW1000: contacts with three numbers and two-digit speed dial, blocking by direction, number or prefix, alarm calls, and emergency numbers."
updated: 2026-11-06
---

# Rules and the phone book

**Rules** is four panes behind one row of chips: *Phone book*, *Call blocking*, *Alarm call* and
*Quiet hours*. The last has [its own page](quiet-hours.md); this page is the other three.

## The phone book

| limit | value |
|---|---|
| contacts | 100 |
| numbers per contact | 3 |
| name length | 32 characters |
| a speed-dial code | exactly **2 digits**, and unique across the book |

| control | what it does |
|---|---|
| **Add contact** | opens the editor: *Name*, *Numbers (up to 3)*, *Add number* — which disappears at three — *Speed dial code*, and *Ring through quiet hours* |
| a row's tags | `Speed 27` when the contact has a code, `Rings through quiet hours` when it carries the flag |
| **Edit** / **Delete** | per contact |

A number may be stored with a label — `+94771234567:mobile`, `:home`, `:work` — and the label is
what the display shows beside the number.

### Speed dial

Two digits, then the send key. `27#` dials the contact whose code is `27`, and the same two digits
dialled alone are an ordinary number after the pause ends it. The page's dialler and the handset's
keypad behave the same way.

!!! info "An emergency number is never replaced"
    A speed-dial entry cannot stand in for an emergency number, and a dialled emergency number is
    never rewritten by anything in the phone book. That is a property of the design, not a guarantee
    of service.

A stored number longer than the dial buffer (20 digits) is refused with a line in the log rather than
silently truncated.

### Matching a caller

The name shown in the [call log](calls.md) and on the handset's display comes from matching the
digits the network sent, in **international form**, against the book. That is why a contact can be
recognised however the network happened to write the number — local or with the country code — and
why the same match drives the ring-through flag in quiet hours.

## Call blocking

| control | what it does |
|---|---|
| **Anonymous calls** — *Block calls without caller ID* | releases a call that arrives with no number |
| **Incoming numbers** | a list of 50 numbers that never ring this line |
| **Incoming prefixes** | a list of 50 prefixes — the usual way to silence a whole range |
| **Outgoing numbers** | numbers this line will not dial |
| **Outgoing prefixes** | prefixes it will not dial |

Each list has its own **Edit** button and each save is applied immediately, without a page-wide
save.

What the rules do, exactly:

| | |
|---|---|
| when they are applied | incoming rules **before the line rings at all**; outgoing rules at the moment the digits are about to go out |
| what a blocked outgoing dial looks like | nothing is sent to the network. You hear the congestion tone, and the call is logged with outcome `blocked` and cause 34 |
| how numbers are compared | in international form, so a prefix written one way matches a call written another |
| per-call restriction prefixes | a dialled `#31#` or `*31#` is understood as a CLIR request and stripped **before** any rule looks at the number |
| emergency numbers | never blocked. A rule that would match one does not |

!!! warning "Blocking is not screening"
    A blocked call is released quietly. The caller is not told they were blocked, and nothing about
    the rule is visible to them. There is no announcement, no record on their side, and no way to
    recover a call a rule released — which is why the lists are limited to 50 entries each and the
    page shows them plainly.

## Alarm calls

A wake-up call rings the line at a time you set. Up to **20** alarms, each with a label of up to 32
characters, a time in 24-hour form, a set of weekdays, and its own enable switch.

| | |
|---|---|
| how it is checked | every 30 seconds |
| what happens | the line **rings**, for up to 60 seconds. There is no caller id on it |
| how often | one ring per minute, whatever the number of alarms that came due |
| when it is skipped | the line is busy, or the handset is off hook, or the clock is not trusted |
| the clock | trusted when the router's own year has reached 2026. An untrusted clock skips the alarm once and says so |

The editor shows the router's clock beside your browser's and warns when they differ by more than
five minutes, because an alarm is a promise about time.

## Forwarding, and why there is no pane for it

Call forwarding is a network service: the router asks the operator to divert your calls, and the
operator's answer is what decides whether anything happens. This build **reads** it — the
`forwarding_get` reply carries whether the network has it on, to what number, with what delay, and
what error came back — but the Rules tab does not offer a forwarding editor. A forwarding rule stored
in `/etc/config/awvoice` is still read by the daemon.

If you need forwarding, set it on the network with the service code your operator publishes; the
[handset page](handset.md#the-numbers-you-do-not-show) explains how codes are dialled.

## When a rule does not act

| symptom | what it means |
|---|---|
| A number you blocked still rings | the stored form does not match what the network sent. Compare in international form, or use a prefix |
| An outgoing call you expected to be blocked went through | the rule list is on the **outgoing** side and the number matched an incoming list, or a `#31#` prefix changed the digits before matching |
| A speed dial does nothing | the two digits need the send key, and the code must be unique |
| The alarm did not fire | the line was busy, the handset was off hook, or the clock was not trusted. All three are logged |
| The alarm fired at the wrong time | the router's clock or the time zone. The editor's warning compares it with your browser |
| *Block calls without caller ID* does nothing | the network delivered a number after all. Check the log row: a withheld caller is shown as **Withheld** |

## Questions people ask

??? question "Can I stop certain numbers from ringing my AW1000?"
    Yes. **Rules → Call blocking** takes 50 incoming numbers and 50 incoming prefixes, the same for
    outgoing, and a switch for anonymous callers. Incoming rules act before the line ever rings, and
    the call is logged as `blocked`.

??? question "Can the AW1000 wake me up with a phone call?"
    Yes, with alarm calls: up to 20, each with a time and the days it should fire. The line rings for
    up to a minute. It trusts the router's clock, so set your time zone first.

??? question "How does speed dial work on this phone?"
    Two digits per contact, unique across the book, dialled followed by the send key — on the handset
    and in the page's dialler. The same two digits alone are an ordinary number.

??? question "Can I block an emergency number by mistake?"
    No. Nothing on this router blocks an emergency number, and a dialled emergency number is never
    replaced by a speed-dial entry.
