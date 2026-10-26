---
title: "Multi-WAN failover for a 5G router"
description: "Add a phone tether, USB modem or Ethernet backup connection and switch to it with mwan3 when 5G drops or hits a data cap."
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
