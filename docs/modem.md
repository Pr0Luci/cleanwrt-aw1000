---
title: "AW1000 5G modem: QModem, SMS, TTL and firmware"
description: "Set up and manage the Quectel RG500Q-EA 5G modem of the Arcadyan AW1000 with QModem: signal, SMS, TTL, IPv4/IPv6, AT ports and modem firmware."
---

# The 5G modem

The AW1000 has a Quectel **RG500Q-EA** 5G modem. CleanWRT drives it with **QModem** and the
vendor QMI dialer, so it dials and recovers on its own.

## What works out of the box

| Feature | Where | Notes |
|---|---|---|
| Modem control and status | *Modem → QModem* | auto-dial, auto-recovery, dual-stack IPv4/IPv6 when your carrier offers IPv6 |
| Signal and network details | *Modem → 3gInfo-lite* | registration shows correctly on data-only SIMs (a CEREG-based fix) |
| SMS | *Modem → SMS* | read and send; received SMS can be forwarded |
| Carrier tethering-detection bypass (TTL) | *Modem → TTL* | **on by default**: forwarded packets get a fixed TTL of 64 |
| Data usage | *Statistics → vnStat* | daily and monthly totals on the modem interface |
| Wi-Fi regulatory domain | automatic | taken from the network's country code once the modem registers |

!!! note "About the TTL setting"
    The TTL rule exists so tethered traffic looks like traffic from the router itself. Whether
    that is allowed depends on your carrier's terms. You can change the value or turn it off
    in *Modem → TTL*.

## AWvoice and the modem

[AWvoice](awvoice.md) uses the modem for voice calls (VoLTE) and needs it in PCM slave mode. If you
use the phone port, read that page before you change the modem's audio or IMS settings.

## IPv4 only

To use IPv4 only, set the modem's PDP type to IPv4 in *Modem → QModem*. If you send traffic
through Passwall 2, also enable **IPv6 TProxy** in its forwarding settings, otherwise devices
can reach IPv6 sites directly, outside the proxy.

## AT ports

The modem exposes several serial ports. Two of them are for AT commands:

| Port | Used by |
|---|---|
| `/dev/ttyUSB2` | the LED daemon (see [Front-panel LEDs](leds.md)) |
| `/dev/ttyUSB3` | QModem |

!!! warning "Do not keep a port open"
    Two programs reading one AT port interleave their replies. Do not leave a terminal open
    on either port for a long time: a stuck session can blank the LEDs or stall QModem. Close
    the session when you are done.

## Modem firmware

The modem's firmware is **separate from the router firmware**. Flashing CleanWRT does not change
it. CleanWRT does not ship, host or redistribute Quectel firmware or tools, and the project has
not performed the upgrade itself: it is the vendor's procedure and your risk.

### 1. Read the current version (safe, changes nothing)

Easiest is the *QModem* page, which shows the firmware revision. Over SSH:

```sh
( timeout 3 cat /dev/ttyUSB3 > /tmp/at.out & ); sleep 1; printf 'ATI\r' > /dev/ttyUSB3; sleep 2
tr -d '\r' < /tmp/at.out; rm -f /tmp/at.out
```

A reply looks like this:

```text
ATI      ->  Quectel / RG500Q-EA / Revision: RG500QEAAAR13A01M4G
AT+QGMR  ->  RG500QEAAAR13A01M4G_01.200.01.200
```

### 2. When is an upgrade needed?

Only when the modem misbehaves on your carrier (no registration, no 5G, unstable data) and
the carrier or Quectel confirms that a newer firmware fixes it. Some units are reported to ship
with a region-customised firmware that works poorly on other carriers; the revision string is
what to quote when asking Quectel. **If the modem works, leave it alone.**

### 3. Where the firmware comes from

Only from Quectel (or your supplier acting for Quectel): the package for your exact module
variant and revision, with the vendor's release notes. Do not use packages from forums or other
sites. A wrong or modified package can brick the modem.

### 4. The upgrade (vendor procedure)

Quectel's Linux flashing tool is **QFirehose**. It is not in the OpenWrt 25.12.5 package feeds
and not in the CleanWRT feed; it comes with the vendor's Linux tools package. Follow the README
of the version you receive, because the flags differ between versions. In outline:

1. Read the version (step 1) and keep the output.
2. Power the router from a stable supply and do not touch it during the flash.
3. Stop what uses the modem ports:

    ```sh
    /etc/init.d/cw-led stop
    /etc/init.d/qmodem_network stop
    /etc/init.d/qmodem_monitor stop
    ```

4. Run QFirehose against the unpacked vendor firmware directory, as its README says.
5. Wait for the modem to re-enumerate, read the version again, then start the services again
   (or reboot).

### 5. Risk and recovery

- An interrupted or wrong flash can leave the modem unusable. A downgrade is not guaranteed to
  work: plan as if the upgrade is one-way.
- The router itself is unaffected, so SSH and LuCI stay reachable over LAN and Wi-Fi.
- If the modem does not come back, the vendor's tool and package are the recovery path. Contact
  Quectel with the revision string you saved.

## Common questions

??? question "Why does the 5G modem of my AW1000 not register?"
    Open *Modem → QModem* and *Modem → 3gInfo-lite* and check the SIM, the APN and the signal first. A modem firmware upgrade is only a last resort, and only when the carrier or Quectel confirms that a newer firmware fixes your problem.

??? question "How do I read and send SMS on the Arcadyan AW1000?"
    Use *Modem → SMS* in LuCI. You can read and send messages there, and received SMS can be forwarded.

??? question "What does the TTL setting do on the AW1000?"
    It gives forwarded packets a fixed TTL of 64 so tethered traffic looks like traffic from the router itself. It is on by default. Whether that is allowed depends on your carrier's terms, and you can change or switch it off in *Modem → TTL*.

??? question "How do I use IPv4 only on the AW1000 5G connection?"
    Set the modem's PDP type to IPv4 in *Modem → QModem*. If you send traffic through Passwall 2, also enable IPv6 TProxy in its forwarding settings so devices cannot reach IPv6 sites outside the proxy.

??? question "Which AT port do I use on the AW1000 modem?"
    The modem exposes two AT ports. The LED daemon uses `/dev/ttyUSB2` and QModem uses `/dev/ttyUSB3`. Do not leave a terminal open on either one, because two programs reading one port interleave their replies.

??? question "Do I need to upgrade the modem firmware on my AW1000?"
    Only if the modem misbehaves on your carrier. If it works, leave it alone. The firmware is separate from CleanWRT, comes only from Quectel, and an interrupted or wrong flash can leave the modem unusable.
