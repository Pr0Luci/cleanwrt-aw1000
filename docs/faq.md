---
title: "Arcadyan AW1000 OpenWrt FAQ and troubleshooting"
description: "Answers about OpenWrt on the Arcadyan AW1000: the RJ11 phone port, VoLTE, the 5G modem, the flash layout, recovery and known limits of CleanWRT."
---

# FAQ and troubleshooting

## Known limits { #known-limits }

- **Only the Arcadyan AW1000**, and only with the expanded flash layout. See
  [MTD layout](mtd-layout.md).
- **The first install from the stock firmware needs a serial console.**
- **QModem is not free for commercial use.** Its licence adds a non-commercial clause. See
  [Licence and notices](licence.md).
- **AWvoice is not for emergency calls.** See the safety notes on the [AWvoice](awvoice.md) page.
- **Images are unsigned** unless the project's image-signing key is configured for the release.
- **The `cw-opt` package feed is not active yet.**
- The modem's own firmware is separate and is not provided by this project.

## Questions

??? question "Does OpenWrt run on the Arcadyan AW1000?"
    Yes. CleanWRT is OpenWrt 25.12.5 built for the AW1000 (`qualcommax/ipq807x`), with the 5G modem,
    Wi-Fi, the front-panel LEDs and the RJ11 phone port working. It needs the expanded flash layout,
    see the MTD layout page.

??? question "Can I use a normal phone on the AW1000's RJ11 port?"
    Yes, with AWvoice, which is part of CleanWRT: an ordinary analogue phone makes and takes calls
    over the SIM.

??? question "Does the AW1000 do VoLTE voice calls on OpenWrt?"
    Yes, with AWvoice. The 5G modem carries the call over VoLTE, so you need a SIM and an operator
    that provide VoLTE.

??? question "Why does the browser say the connection is not secure?"
    LuCI uses a self-signed certificate created on your router at first boot. The connection is
    encrypted, but no public authority signed the certificate. See
    [Security](features/security.md#why-the-browser-says-not-secure).

??? question "I cannot log in after flashing."
    The first login is over **Ethernet** with **no password**, at `http://192.168.1.1`. Connect
    a computer to a LAN port and set its address to `192.168.1.x` if it does not get one. If it
    still fails, use [failsafe mode](recovery.md#failsafe-mode).

??? question "Can I flash it on my router if it is not an AW1000?"
    No. Never flash an image built for another device. It can brick the router.

??? question "`sysupgrade` says the image is not valid."
    Check the file name (`arcadyan_aw1000`), re-download the image and check its checksum. If you
    flash a community build that has no metadata, you would need `-F`; do not force an image you
    did not verify.

??? question "The 5G modem does not register."
    Open *Modem → QModem* and *Modem → 3gInfo-lite* and check the SIM, the APN and the signal.
    See [The 5G modem](modem.md). A modem firmware upgrade is only a last resort.

??? question "The 5G and signal LEDs went dark."
    The LED daemon cannot read the modem. Check that nothing holds the AT port open, and read
    `logread -e cw-led`. See [Front-panel LEDs](leds.md#troubleshooting).

??? question "Wi-Fi works but 'Internet' says unreachable."
    Open the connectivity check settings in *System → LED Management*. The LED only mirrors the
    probe. Test the real connection from a computer too.

??? question "Cloudflared shows a red error."
    That is expected until you configure the tunnel token. See
    [Remote access](features/remote-access.md).

??? question "I ran `apk upgrade` and the overview cards look different."
    The LuCI packages are pinned for a reason (see [Updating and pinning](updating.md)). Flash the
    release again to get back to its state. A factory reset does not restore replaced packages.

??? question "Downloads are filling the router's flash."
    Downloads default to the first USB drive. Plug a drive in before you start a download.

??? question "Can I use it commercially?"
    The project is free of charge. The bundled QModem component prohibits commercial use. Check
    its licence before you deploy this firmware in a business, an ISP or a paid service.

??? question "How do I go back to the stock firmware?"
    Restoring the stock firmware needs the stock image and a serial console. Keep a backup of the
    stock firmware before you flash.

## Still stuck?

1. Collect a diagnostic capture: `cw-diag full` (SIM identifiers, public IPs and Wi-Fi keys are
   redacted).
2. Read the [Recovery](recovery.md) page.
3. Open an issue on [GitHub](https://github.com/Pr0Luci/cleanwrt-aw1000/issues) with the version,
   what you did, and the relevant log lines. Do not paste passwords or keys.
