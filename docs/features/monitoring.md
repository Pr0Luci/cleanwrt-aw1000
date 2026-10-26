# Monitoring

| What | Where |
|---|---|
| Data usage on metered 5G | *Statistics → vnStat*: daily and monthly totals on the modem interface (already tracked) |
| Live bandwidth per host | *Tools → Bandwidth Monitor* |
| Signal and network details | *Modem → 3gInfo-lite* |
| System logs | *Status → System Log* (or `logread` over SSH) |

## Ad blocking

Adblock is installed but **off by default**. Open *Services → Adblock*, tick **Enabled**, pick a
blocklist and press **Save & Restart** (not only Save & Apply). Use Adblock or AdGuard Home, not
both.

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
