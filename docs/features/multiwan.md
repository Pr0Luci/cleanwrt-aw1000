---
title: "Multi-WAN failover for a 5G router"
description: "Add a phone tether, USB modem or Ethernet backup connection and switch to it with mwan3 when 5G drops or hits a data cap."
updated: 2026-11-06
---

# Multi-WAN failover

Add a second internet connection and let the router switch to it if 5G drops or hits a cap.

!!! note "mwan3 is not in the image"
    The 5G modem already reconnects by itself, so `mwan3` is only needed to switch to a
    *different* connection. Install it when you need it:

    ```sh
    apk add mwan3 luci-app-mwan3
    ```

## 1. Add the backup connection

| Backup | How |
|---|---|
| Phone USB tether | plug the phone in and turn on USB tethering; it appears as a network device (the `rndis` / `ipheth` driver loads automatically) |
| USB modem or USB Ethernet adapter | plug it in; `usb-modeswitch` turns dongles into modem mode |

Add it under *Network → Interfaces* (DHCP).

## 2. Enable mwan3

```sh
/etc/init.d/mwan3 enable && /etc/init.d/mwan3 start
```

Configure members and policies in *Network → Load Balancing*. Point the primary at the modem
interface (`4_1`) and the backup at your second connection.

## Common questions

??? question "Can the Arcadyan AW1000 fail over to another connection when 5G drops?"
    Yes, with mwan3. Add a phone USB tether, a USB modem or a USB Ethernet adapter as a second interface, then set the 5G modem as the primary member and the other as the backup.

??? question "Is mwan3 included in CleanWRT?"
    No. The 5G modem already reconnects by itself, so mwan3 is only needed to switch to a different connection. Install it with `apk add mwan3 luci-app-mwan3`.

## Out of the box

| | state |
|---|---|
| `mwan3`, `luci-app-mwan3` | **not in the image.** Install them with `apk add mwan3 luci-app-mwan3` |
| `luci-app-qmodem-mwan` | **deliberately excluded.** It hijacks routing through the modem package; plain mwan3 is the tool this build points people at |
| USB tethering drivers (`rndis`, `ipheth`) | in the image |
| USB modem and ethernet adapter drivers | in the image, including `asix-ax88179` and `huawei-cdc-ncm` |
| The modem interface | `wwan0` |

## What is listening

Nothing here opens a port. Failover changes the default route, which is why a proxy suite configured
for one interface has to be told about the other.

## When it does not work

| symptom | what it means |
|---|---|
| The backup link never takes over | mwan3's probes decide, not link state. Check the policy's test set |
| DNS still resolves through the dead link | the resolver is not following the policy. `dnsmasq` here is `dnsmasq-full`, which is what a source-routed setup needs |
| The proxy suites disagree about the interface | Passwall and HomeProxy bind an interface of their own. See [VPN and proxies](vpn-proxy.md) |
| `apk add` replaced something it should not have | the pinned packages are protected by the world-file pin that runs on every boot. See [updating and pinning](../updating.md) |

## Questions people ask

??? question "Is mwan3 included in CleanWRT?"
    No. The image ships the drivers a second connection needs and leaves the policy router to you:
    `apk add mwan3 luci-app-mwan3`.

??? question "Can the AW1000 use a phone on USB tethering as a backup WAN?"
    Yes. The RNDIS and iPhone tethering drivers are in the image; add the interface, then let mwan3
    decide when to use it.
