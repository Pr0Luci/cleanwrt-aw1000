---
title: "Data usage and bandwidth on the AW1000"
description: "vnStat data usage, live bandwidth per host, Watchcat, SQM and the cw-diag diagnostic tool on CleanWRT for the Arcadyan AW1000."
updated: 2026-11-14
---

# Monitoring

| What | Where |
|---|---|
| Data usage on metered 5G | *Statistics → vnStat*: daily and monthly totals on the modem interface (already tracked) |
| Live bandwidth per host | *Tools → Bandwidth Monitor* |
| Signal and network details | *Modem → 3gInfo-lite* |
| System logs | *Status → System Log* (or `logread` over SSH) |

## Watchcat

*Tools → Watchcat* is installed but has **no rule**, so it does nothing until you add one. The 5G
modem already re-dials on its own, so add a rule only if you want a whole-router or an interface
watchdog.

## Quality of service

*Network → SQM QoS* is installed and **inert**. Set your interface and your real bandwidth to
fight bufferbloat. BBR congestion control is already on, which suits cellular links.

## Command line diagnostics

`cw-diag` collects a redacted diagnostic capture:

```sh
cw-diag <modem|qmi-rx|nss|wifi|bridge|sysup|full>
```

The output goes to `/var/log/cw-diag-<subsystem>-<time>.log`. SIM identifiers, public IPs and
Wi-Fi keys are redacted. Also installed: `htop`, `mtr`, `iperf3`, `ethtool`, `usbutils`.

## Out of the box

| tool | state | where |
|---|---|---|
| vnStat 2 | **on** | *Statistics → vnStat*. Daily and monthly totals per interface |
| Bandwidth Monitor (nlbwmon) | **on** | *Tools → Bandwidth Monitor*. Traffic per device |
| Watchcat | **no rule at all** | *Tools → Watchcat*. Deliberate: the package default is an active "ping, reboot after 6 failures" rule, and this image ships the file with the sections removed |
| SQM QoS | **off** | *Network → SQM QoS* |
| `irqbalance` | **on** | no page. Interrupts spread over the four cores |
| packet steering | **on** | `network.globals.packet_steering='1'`, written by `97-cw-net-tuning` |
| `cw-diag` | always available | a shell command, below |

## What is listening

Nothing on this page opens a port by itself. Bandwidth monitoring and vnStat read netlink and the interface counters rather than listening.

## When it does not work

| symptom | what it means |
|---|---|
| vnStat shows no history | the database is in `/var/lib/vnstat`, which is on flash. A keep-settings upgrade keeps it; a clean install does not |
| The router rebooted itself | it did not, unless you added a Watchcat rule. This image ships Watchcat with **no rule** precisely so that cannot happen by default |
| Bandwidth Monitor shows nothing for the modem interface | it counts per interface. The modem's data interface is `wwan0` |

## Questions people ask

??? question "Does CleanWRT reboot the router when 5G drops?"
    Not as shipped. OpenWrt's Watchcat is the tool that would, and its package default is exactly
    that rule; this image installs Watchcat with **no rule configured**, so nothing reboots until you
    write one.

??? question "How do I collect a diagnostic report from the router?"
    `cw-diag full`. It redacts SIM identifiers, public addresses and Wi-Fi keys, which is what makes
    it safe to attach to a report.

??? question "Can I block ads on the whole network?"
    Not with a built-in app: Adblock and AdGuard Home are not in this build. You can point the
    router's upstream DNS at a filtering resolver (*Network → DHCP and DNS → Forwards*).
