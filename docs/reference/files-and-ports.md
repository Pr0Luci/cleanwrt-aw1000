---
title: "Files, ports and paths on CleanWRT"
description: "Where everything lives on the AW1000: config files, recordings and messages, what survives an upgrade, which process owns each port, and every listener."
updated: 2026-11-06
---

# Files, ports and paths

Where things are, and who owns them. Every path here is one a package installs or a service
creates; nothing is a guess.

## Configuration

| file | written by | what it holds |
|---|---|---|
| `/etc/config/awvoice` | the AWvoice page, or `uci` | the line, the network side, the quiet-hours windows, the phone book |
| `/etc/config/cw-led` | the LED Management page, or `uci` | the daemon's settings. A package conffile, so an upgrade keeps your changes |
| `/etc/config/footstrap` | the theme's page, or the image's first-boot script | the look. A package conffile |
| `/etc/config/qmodem_sip` | the SIP service's package, edited on the AWvoice page | the network phone's account and media socket |
| `/etc/config/uhttpd` | OpenWrt, extended by this image | the admin server, and the plain listener that serves a provisioning file |
| `/etc/config/{network,wireless,system,dropbear,firewall}` | OpenWrt | the usual four, with this image's defaults |
| `/etc/config/{fstab,irqbalance,minidlna,p910nd,qmodem_ttl,samba4,syncthing,watchcat}` | this image | the opt-in apps, shipped off or inert. See [first-boot defaults](uci-defaults.md) |
| `/etc/apk/world` | `96-cw-apk-world-pin`, on every boot | which packages are pinned to an exact version and which may upgrade |

## The phone port's data

| path | what it is |
|---|---|
| `/etc/awvoice/board.bin` | this board's chip values. Installed by the first service start from the package, and never overwritten |
| `/etc/awvoice/greeting.wav` | the greeting the answering machine plays. One fixed place, never a setting |
| `/usr/share/awvoice/greeting-default.wav` | the packaged default, copied in only when the router has none |
| `/etc/awvoice/calls.json` | the call log as it stands on flash |
| `/var/run/awvoice-phoned/calls.json` | the same log in memory while the service runs |
| `/etc/awvoice/recordings/` | the call recordings, one WAV per answered call |
| `/etc/awvoice/messages/` | the answering machine's messages |
| `/etc/awvoice/audio.key`, `/etc/awvoice/audio.pem` | the audio path's own pair, when the browser stream is configured with something other than the uhttpd defaults |
| `/var/run/awvoice-phoned/media.sock` | the unix socket the SIP service hands audio to. The two programs meet here and over `ubus`; neither contains the other's code |
| `/www/awvoice-provision/awvoice-<32 hex>.xml` | the account file a scanned code points a soft phone at, retired after ten minutes |
| `/usr/libexec/awvoice-provision` | the writer of that file |

!!! note "What survives an upgrade"
    Everything under `/etc/awvoice/` is kept across a `sysupgrade` and appears in a
    `sysupgrade -b` backup, because the phone package installs a keep-list entry at
    `/lib/upgrade/keep.d/awvoice`. You do **not** need to add the directory to
    `/etc/sysupgrade.conf` yourself. The call log, the recordings, the messages and your greeting
    come through a flash on their own.

    `/etc/config/awvoice` is a package conffile, so it is kept too. A clean install
    (`sysupgrade -n`) keeps neither.

## The rest of the state

| path | what it is |
|---|---|
| `/etc/footstrap/login-bg`, `/etc/footstrap/pattern.svg` | the two files that make the image's background. The theme lists this directory in its own keep file, so a `sysupgrade` keeps whatever you uploaded there |
| `/www/luci-static/cw-branding/login-logo.png` | the branding logo the login page shows. Outside the theme's directory, so a theme update can neither overwrite it nor collide with the patch that places it |
| `/var/run/qmodem_voip/sip.conf` | the derived credential file the SIP service actually reads. `/etc/config/qmodem_sip` is the record; this file is generated from it at start and on reload |
| `/var/lock/cw-led-at.lock` | the LED daemon's claim on the modem's AT port while it is asking a question |
| `/proc/mtd`, `/sys/class/leds/*` | the flash layout the [MTD page](../mtd-layout.md) is about, and the lamps the LED daemon writes |

## Serial ports

The modem exposes several serial devices, and more than one program uses them.

| device | who uses it | notes |
|---|---|---|
| the tty on the modem's **USB interface 2** | the phone daemon | chosen by interface number, not by a fixed name: the daemon walks sysfs and takes that interface's tty. `awvoice.main.at_interface` is the setting |
| `/dev/ttyUSB2` | the LED daemon | configured by device name. On this board it is usually the same port the phone daemon opens, which is why the LED daemon holds a lock, polls slowly, and absorbs a cut-short reply with its [contention grace](../leds.md#settings) setting |
| `/dev/ttyUSB3` | QModem | the modem's own control port. `47-cw-awvoice-at-port` exists so the two do not collide |

!!! warning "Do not hold a port open"
    Two programs reading one AT port interleave their replies. A terminal left open on any of them
    can blank the LEDs, stall QModem, or make the phone daemon's modem questions time out. Close the
    session when you are done.

## Network ports

Nothing below is open unless the row says it is on by default.

| port | protocol | open by default | what it is |
|---|---|---|---|
| 80 | TCP | yes, as a redirect | plain HTTP, moved to HTTPS by `uhttpd.main.redirect_https` |
| 443 | TCP | **yes** | LuCI over HTTPS with a self-signed certificate created on the router |
| 8080 | TCP | **yes, LAN only** | the plain HTTP listener that serves a scanned provisioning file, from a directory that holds nothing else, with directory listings off and the private-network filter on |
| 7443 | TCP | while the phone line is up | the web phone's encrypted audio stream, on the LAN address (`web_iface`), using the uhttpd certificate pair unless you point it at another. The listener opens when the service starts with a LAN address to bind, whichever side the SIP switch names; a **session** on it is the separate thing, and only one page may hold it |
| 5060 | UDP and TCP | **no** — only after the AWvoice SIP switch is turned on | the network phone's inbound SIP listener, on the LAN interface |
| 40000–40031 | UDP | with the SIP side on | the RTP range the SIP service uses for media |
| 53, 67 | UDP | yes | DNS and DHCP on the LAN, as in stock OpenWrt |
| 8384 | TCP | no (Syncthing ships disabled) | Syncthing's own web interface, bound to all addresses when enabled — set a password before you turn it on |
| 8200 | TCP/UDP | no (miniDLNA ships disabled) | the media server, on the LAN bridge when enabled |
| 139, 445 | TCP | the Samba daemon starts | one share, `guest_ok='no'`, so nothing is reachable until you add users |
| 515 | TCP | no (p910nd ships disabled) | the USB printer share |

!!! info "What this means for a scan of your network"
    A new router with nothing switched on exposes: the web server on 80 and 443, the provisioning
    listener on 8080 (private-network filtered, serving one nearly-empty directory), and the usual
    LAN-side DNS and DHCP. The phone's SIP port appears only when you ask for it, and the browser
    audio port appears only while a page is actually using it.

## Services and boot order

| init script | boot | what it is |
|---|---|---|
| `awvoice` | starts at 95 | the phone daemon. The line is on as installed (`main.enabled=1`) |
| `cw-led` | starts at 50 | the LED daemon, deliberately early so the panel shows the search state while the modem dials |
| `cw-modem-fix` | enabled at first boot | the modem registration fix |
| `qmodem_voip_sipd` | 100, **not enabled by the image** | the SIP service. The AWvoice page's switch starts and stops it |
| `qmodem_voip` | 99, **taken off the boot path by `51-cw-awvoice-voipd-off`** | the vendor VoIP engine. It claims the same front-end name the phone daemon answers, which is why it is off |
| `qmodem-smsd` | 92 | the SMS daemon |
| `uhttpd` | stock | the web server, with the second instance this image adds |

Restart a service after a hand edit:

```sh
/etc/init.d/awvoice restart
/etc/init.d/cw-led reload
```

## `ubus` objects

| object | published by | used for |
|---|---|---|
| `awvoice` | the phone daemon | everything the AWvoice page reads and writes. Listed method by method in [the API and who may call it](ubus-and-acl.md) |
| `luci.cw-led` | rpcd's LED module | the live lamp state and the option lists the LED page draws. Read-only |
| `qmodem_voip` | the phone daemon when a network phone is asked for, otherwise the vendor engine | the front end a call is carried through. Which program holds the name is a fact the AWvoice page's guards report |

## Next

| | |
|---|---|
| The options in these files | [UCI options](options.md) |
| What the image writes at first boot | [first-boot defaults](uci-defaults.md) |
| Who may call what | [the API and who may call it](ubus-and-acl.md) |
