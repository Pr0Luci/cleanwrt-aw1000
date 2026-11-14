---
title: "AW1000 5G modem: QModem, SMS, TTL, SIP"
description: "The Quectel RG500Q-EA modem on the Arcadyan AW1000: QModem, 3gInfo, SMS, TTL, which process uses which AT port, the LAN SIP service, and modem firmware."
updated: 2026-11-06
---

# The 5G modem

The AW1000 carries a Quectel **RG500Q-EA** 5G modem. CleanWRT drives it with **QModem** and the
vendor QMI dialer, so it dials and recovers on its own.

## What works out of the box

| feature | where | notes |
|---|---|---|
| modem control and status | *Modem → QModem* | auto-dial, auto-recovery, dual-stack IPv4/IPv6 when your carrier offers IPv6 |
| signal and network details | *Modem → 3gInfo-lite* | registration shows correctly on data-only SIMs, from a CEREG-based fix in this build |
| SMS | *Modem → SMS* | read and send. Received messages can be forwarded |
| tethering-detection bypass (TTL) | *Modem → TTL* | **on by default**: forwarded packets get a fixed TTL of 64 |
| data usage | *Statistics → vnStat* | daily and monthly totals on the modem interface |
| Wi-Fi regulatory domain | automatic | taken from the network's country code once the modem registers |
| the LAN SIP service | no page of its own — the switch is on **AWvoice → SIP** | it comes with the same feed as the modem apps. See below |

!!! note "About the TTL setting"
    The TTL rule exists so tethered traffic looks like traffic from the router itself. Whether that
    is allowed depends on your carrier's terms. Change the value or switch it off in
    *Modem → TTL* — the shipped rule is an `/etc/nftables.d/` fragment, which is what fw4 actually
    applies.

## The radio page

*Modem → 3gInfo-lite* reads the modem through one collector, `radiodata.sh`, and shows what it
measured: the registration state and the mode, the signal of each serving carrier, the cells around
you, and how long the last collection took. The refresh and the neighbour scan both start at five
seconds and can be set to 15 or 30 seconds, 1 or 5 minutes. Neighbours also scan on their own while
the page is open, and *Scan now* takes a reading at once.

## AWvoice and the modem

[AWvoice](awvoice.md) uses this modem for voice, over VoLTE, and needs it in **PCM slave mode**. If
you use the phone port, read that page before you change the modem's audio or IMS settings: AWvoice
reads the audio mode and the IMS registration and reports both, and does not change either one
itself. Changing the audio rate does restart the modem, so mobile data drops for about half a
minute.

## The SIP service that arrives with this feed

The QModem feed this build pins carries `qmodem-sipd`, the LAN SIP service that a
[network phone](awvoice/network-phones.md#what-the-service-is) uses. It is selected into the image,
and it is **not started** by the image.

| fact | value |
|---|---|
| package | `qmodem-sipd`, which pulls the vendor VoIP engine, the SMS daemon and the seven pjproject libraries |
| size in the image | 166 KiB for the service itself, about 1.5 MiB for the seven pjsip packages together |
| config file | `/etc/config/qmodem_sip`, listed option by option in [UCI options](reference/options.md#qmodem_sip--the-service-a-network-phone-uses) |
| what starts it | the AWvoice page's SIP switch, through `/etc/init.d/qmodem_voip_sipd` |
| boot order, if enabled | SMS daemon 92, phone daemon 95, VoIP engine 99, SIP service 100 |
| what is deliberately **not** selected | `luci-app-qmodem-voip`. Two pages for one service drift apart, so the switch, the credentials and the audio socket live on the AWvoice screen |
| the vendor VoIP engine | stopped and taken off the boot path at first boot, because it claims the front-end name the phone daemon answers |

Six patches in `patches/feeds/qmodem/` change this service's behaviour — the 2xx ACK, the in-dialog
BYE from either side, the CANCEL of an unanswered LAN INVITE, the UCI section as the credential
record, the defaults the phone bridge needs, and the migration for a configuration that kept the
vendor engine's socket. What each one does is in
[what this build changes upstream](building.md#what-this-build-changes-upstream).

!!! warning "If a soft phone registers but no call goes through"
    That is the vendor VoIP engine holding the front-end name. This image's first-boot script takes
    it off the boot path for exactly this reason; on a router where the script did not run, the
    AWvoice page's Diagnostics pane names the holder.

## IPv4 only

To use IPv4 only, set the modem's PDP type to IPv4 in *Modem → QModem*. If you send traffic through
HomeProxy, also turn on its IPv6 support, otherwise devices can reach IPv6 sites directly, outside
the proxy.

## AT ports

The modem exposes several serial ports, and more than one program uses them.

| who | which port | how it is chosen |
|---|---|---|
| the phone daemon | the tty on the modem's **USB interface 2** (`awvoice.main.at_interface`) | by interface number, through sysfs — not by a fixed device name |
| the LED daemon | `/dev/ttyUSB2`, configurable | by device name. Usually the same port as above, which is why it holds a lock, polls every 30 seconds, and absorbs a cut-short reply with its [contention grace](leds.md#settings) setting |
| QModem | `/dev/ttyUSB3` | the port left to it by `47-cw-awvoice-at-port`, which removes the ubus AT daemon's claim on the other one |

!!! warning "Do not keep a port open"
    Two programs reading one AT port interleave their replies. A terminal left open on any of them
    can blank the LEDs, stall QModem, or make the phone daemon's modem questions time out. Close the
    session when you are done.

A read that does not disturb anything:

```sh
( timeout 3 cat /dev/ttyUSB3 > /tmp/at.out & ); sleep 1; printf 'ATI\r' > /dev/ttyUSB3; sleep 2
tr -d '\r' < /tmp/at.out; rm -f /tmp/at.out
```

```text
ATI      ->  Quectel / RG500Q-EA / Revision: RG500QEAAAR13A01M4G
AT+QGMR  ->  RG500QEAAAR13A01M4G_01.200.01.200
```

## Modem firmware

The modem's firmware is **separate from the router firmware**. Flashing CleanWRT does not change it.
CleanWRT does not ship, host or redistribute Quectel firmware or tools, and the project has not
performed the upgrade itself: it is the vendor's procedure and your risk.

### When is an upgrade needed?

Only when the modem misbehaves on your carrier — no registration, no 5G, unstable data — and the
carrier or Quectel confirms that a newer firmware fixes it. Some units are reported to ship with a
region-customised firmware that works poorly on other carriers; the revision string above is what to
quote when asking Quectel. **If the modem works, leave it alone.**

### Where the firmware comes from

Only from Quectel, or your supplier acting for Quectel: the package for your exact module variant and
revision, with the vendor's release notes. Do not use packages from forums or other sites. A wrong or
modified package can brick the modem.

### The upgrade, in outline

Quectel's Linux flashing tool is **QFirehose**. It is not in the OpenWrt 25.12.5 package feeds and
not in the CleanWRT feed; it comes with the vendor's Linux tools package. Follow the README of the
version you receive, because the flags differ between versions.

1. Read the version and keep the output.
2. Power the router from a stable supply and do not touch it during the flash.
3. Stop what uses the modem ports:

    ```sh
    /etc/init.d/cw-led stop
    /etc/init.d/awvoice stop
    /etc/init.d/qmodem_network stop
    /etc/init.d/qmodem_monitor stop
    ```

4. Run QFirehose against the unpacked vendor firmware directory, as its README says.
5. Wait for the modem to re-enumerate, read the version again, then start the services again — or
   reboot.

### Risk and recovery

- An interrupted or wrong flash can leave the modem unusable. A downgrade is not guaranteed to work:
  plan as if the upgrade is one-way.
- The router itself is unaffected, so SSH and LuCI stay reachable over LAN and Wi-Fi.
- If the modem does not come back, the vendor's tool and package are the recovery path.

## What the image fixes around the modem

| change | why |
|---|---|
| `98-cw-modem-fix` enables a small init script | a registration fix for data-only SIMs, which otherwise show as not registered |
| `97-cw-net-tuning` sets `network.globals.packet_steering='1'` | receive work spread over the four cores, which a 5G link actually uses |
| IPv6 gets its own retry ladder in `quectel-CM-5G-M` | a failed IPv6 setup no longer tears down the IPv4 call. 60 seconds, doubling, capped at 32 minutes |
| `qmi_wwan_q` keeps its NSS branch behind its own guard | without it the module cannot even be packaged in this tree |
| the generic QMI driver is **not** selected | with it the modem registers and gets an address but no data flows. The vendor-patched drivers are what work |

## Common questions

??? question "Why does the 5G modem of my AW1000 not register?"
    Open *Modem → QModem* and *Modem → 3gInfo-lite* and check the SIM, the APN and the signal first.
    A modem firmware upgrade is a last resort, and only when the carrier or Quectel confirms a newer
    firmware fixes your case.

??? question "How do I read and send SMS on the Arcadyan AW1000?"
    *Modem → SMS* in LuCI. Received messages can be forwarded from the same place. Note that this
    image selects one SMS forwarder deliberately: the two packages that exist install the same init
    script and the image would refuse to assemble with both.

??? question "What does the TTL setting do on the AW1000?"
    It gives forwarded packets a fixed TTL of 64 so tethered traffic looks like traffic from the
    router itself. It is on by default. Whether that is allowed depends on your carrier's terms.

??? question "Which AT port do I use on the AW1000 modem?"
    `/dev/ttyUSB3` for QModem, and the tty on USB interface 2 for the phone daemon; the LED daemon is
    configured for `/dev/ttyUSB2`. Do not leave a terminal open on any of them.

??? question "Does CleanWRT include a SIP server?"
    It includes a LAN SIP **service**, from the same feed as the modem apps, that a soft phone on your
    own network registers to. It ships stopped, it listens on nothing until the AWvoice page's switch
    starts it, and it never reaches outside your network unless you configure the outbound direction
    yourself.
