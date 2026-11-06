---
title: "AWvoice configuration reference"
description: "Every option in awvoice.main and awvoice.sip with its values and shipped default, the quiet-hours, contact and blocking sections, and the settings hidden."
updated: 2026-11-06
---

# Settings reference

Everything is in one file, `/etc/config/awvoice`. The page writes the same file, so `uci` and LuCI
never disagree. An option with an invalid value is reported in the log and its default is used
instead:

```sh
logread -e awvoice | tail -20
```

The shipped file carries only four settings — `flash_min_ms 80`, `flash_max_ms 300`,
`led green:phone` and `sip.mode web`. **Every other value below is a compiled default**, which is
why an option that is absent from your file is not a bug.

## The line — `awvoice.main`

### The service

| option | values | default | what it does |
|---|---|---|---|
| `enabled` | `0`\|`1` | **`1`** | the whole phone line. The init script refuses to start the daemon when it is `0`, and the kernel puts the chip in reset |
| `channel` | `0`\|`1` | `1` | which of the line chip's two channels is this jack |
| `board` | a path | `/etc/awvoice/board.bin` | the board file: this board's chip operating values |
| `at_interface` | `0`–`9` | `2` | the modem's **USB interface number** holding the voice AT port. The tty is found through sysfs, not by a fixed name |
| `my_number` | digits | unset | shown on the page so you know which number this line is. Nothing is ever dialled from it |

### Dialling and the hook

| option | values | default | what it does |
|---|---|---|---|
| `dial_pause_s` | `3`–`15` | `6` | how long a pause after the last digit ends the number |
| `flash_min_ms` | `20`–`500` | `80` | a shorter break is bounce and is ignored |
| `flash_max_ms` | `300`–`3000` | `300` | a break at or above this is on hook. Between the two is a flash |
| `hotline_number` | up to 20 digits | unset | dialled when a lifted handset dials nothing |
| `hotline_delay` | `3`–`99` s | `10` | how long that wait is |

### Caller id and restriction

| option | values | default | what it does |
|---|---|---|---|
| `cid` | `dtmf`\|`bellcore`\|`etsi`\|`off` | `dtmf` | how the number reaches the handset's display |
| `cid_when` | `ring1`\|`prering` | `ring1` | FSK placement, after or before the first ring. **Ignored by the DTMF variant**, and the page shows the control disabled for it |
| `region` | `auto` or a region name | `auto` | the numbering plan that turns national digits into international form, for display and for matching. 43 regions |
| `clir` | `network`\|`hide`\|`show` | `network` | per-subscription calling-line restriction, sent as `AT+CLIR=0|1|2`. **No control on the page**; saving the page leaves the stored value as it was |

### Tones and audio

| option | values | default | what it does |
|---|---|---|---|
| `ringback` | `auto`\|`on`\|`off` | `auto` | local progress tone until the network's own audio is heard, always local, or never |
| `hd` | `0`\|`1` | `0` | HD voice wanted. The modem is asked which rate it actually puts on the bus, and the line comes up at that rate only if it answers so |
| `earpiece_volume` | `0`–`255`, or unset | unset | written to the modem as `AT+CLVL` at every modem setup, when set |
| `modem_rx_gain` | `0`–`65535`, or unset | unset | written as `AT+QRXGAIN` when set. 8192 is unity |
| `level_trace` | `0`\|`1` | `0` | logging only: the modem's audio level every 100 ms |

### Features

| option | values | default | what it does |
|---|---|---|---|
| `call_waiting` | `0`\|`1` | `1` | announce a second call, and with it hold, swap and refuse. Off, the second call is refused on arrival |
| `conference` | `0`\|`1` | **`0`** | the three-way join after a flash and `3`. **Off as installed** |
| `led` | an LED name or `''` | `green:phone` in the shipped file, empty as a compiled default | the indicator lamp. `''` leaves the lamp alone |
| `ring_rate_ms` | `100`–`3000` | `300` | the blink rate while a call rings |
| `offhook_rate_ms` | `200`–`10000` | `1000` | the blink rate while the handset is off hook |

### Recordings

| option | values | default | what it does |
|---|---|---|---|
| `record_enabled` | `0`\|`1` | `0` | record the calls this line answers |
| `record_path` | an absolute path | `/etc/awvoice/recordings` | where they go |
| `record_max_mb` | `1`–`4095` | `50` | the folder's budget; past it the **oldest** files are removed |

### The answering machine

| option | values | default | what it does |
|---|---|---|---|
| `machine_enabled` | `0`\|`1` | `0` | answer for you |
| `machine_delay` | `0`–`60` s | `10` | seconds of ringing first. `0` answers at once |
| `machine_max_s` | `10`–`600` s | `120` | the longest single message; the call ends at it |
| `machine_max_mb` | `1`–`4095` | `50` | the messages folder's budget |
| `machine_path` | an absolute path | `/etc/awvoice/messages` | where messages go |
| `machine_greeting` | — | — | **retired.** Any stored value is ignored and said so in the log. The greeting is one fixed file, `/etc/awvoice/greeting.wav`, managed from its own card |

### The browser phone

| option | values | default | what it does |
|---|---|---|---|
| `web_port` | `1024`–`65535` | `7443` | the port the audio WebSocket listens on |
| `web_iface` | a logical interface name | `lan` | whose IPv4 address the listener binds. It never binds a WAN interface |
| `web_cert` | a path | `/etc/uhttpd.crt` | the certificate the stream uses |
| `web_key` | a path | `/etc/uhttpd.key` | its key |

### Page-only settings

| option | values | default | note |
|---|---|---|---|
| `page_refresh_s` | `1`\|`2`\|`3`\|`5`\|`10`\|`15`\|`30` | `1` | the page's own poll interval. The daemon does not read it |
| `mic_gain_db`, `earpiece_gain_db` | `-99`–`99` | unset | **shown disabled** with *Not available yet*, and never written by the page |

## The network side — `awvoice.sip`

| option | values | default | what it does |
|---|---|---|---|
| `mode` | `web`, `interop`, `baresip` | `web` | whether a phone on your own network may join the line. Saving also starts or stops that service. An unknown word is refused and the previous value stays |

The service's own settings — account, port, direction, provider — are in a different package,
`/etc/config/qmodem_sip`, listed in [UCI options](../reference/options.md#qmodem_sip--the-service-a-network-phone-uses).

## Lists and records

| section type | what it holds | limits |
|---|---|---|
| `contact` | `name`, a `number` list as `digits` or `digits:mobile|home|work`, `quick`, `ring_through` | 100 contacts, 3 numbers each, name ≤ 32, `quick` exactly 2 digits and unique |
| `blocking` (the first of this type) | `anonymous`, and the lists `incoming`, `incoming_prefix`, `outgoing`, `outgoing_prefix` | 50 entries per list |
| `alarm` | `label`, `time` as `HH:MM`, a `day` list (`1` = Monday … `7`), `enabled` | 20 alarms, label ≤ 32 |
| `forwarding` (the first of this type) | `enabled`, `to`, `when` = `always|busy|noanswer|unreachable|all_conditional`, `delay` `5`–`30` in steps of 5, default `20` | the whole section is discarded if any value is invalid |
| `dnd` (every one, in file order) | `enabled`, `from`, `to`, `all_day`, `days`, `mode`, `repeat_min`, `allow` | 8 windows, 20 numbers across all the `allow` lists |

## Rules the daemon applies across options

| rule | what happens |
|---|---|
| `flash_max_ms` must be at least `flash_min_ms + 100` | if it is not, **both** fall back to their defaults |
| the recordings folder and the messages folder must not be the same | the daemon moves one. If only one can move, messages go to `<record_path>/.messages`; if they still collide, `machine_enabled` is turned off |
| an invalid value anywhere | the log names the option and the compiled default is used |

## Settings the page does not show

`at_interface` and `led` are the two that usually matter, and both ship with working values for the
AW1000. Also `clir`, `level_trace`, the four `web_*` values beyond the port, `mic_gain_db` and
`earpiece_gain_db`, `page_refresh_s` (which is in *Phone settings → Advanced*), and the whole
`forwarding` section.

```sh
uci show awvoice                          # everything as stored
uci set awvoice.main.conference=1         # turn the three-way join on
uci commit awvoice
/etc/init.d/awvoice restart
```

!!! warning "A shell commit does not reload the page"
    `uci commit` writes the file. Only the page's own save applies and reloads, and a hand edit needs
    the service restart above. See [first-boot defaults](../reference/uci-defaults.md) for the same
    trap in the other direction.

## Next

| | |
|---|---|
| What each feature does | [the handset](handset.md), [recordings and the machine](recordings-and-machine.md), [quiet hours](quiet-hours.md), [network phones](network-phones.md) |
| Every file and port | [files and ports](../reference/files-and-ports.md) |
| The whole image's options | [UCI options](../reference/options.md) |
