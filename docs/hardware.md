# Hardware

CleanWRT supports **one device**: the Arcadyan AW1000 5G router (the Telstra variant).

!!! danger "No other device"
    Flashing this image on any other router can brick it. The partition table lives on the
    router, not in the image, and an image built for a different table is the classic way to
    destroy a router.

## Specification

| | |
|---|---|
| SoC | Qualcomm IPQ8072 (`ipq807x`), four cores |
| Memory | 1 GiB RAM, 1 GiB NAND flash |
| 5G modem | Quectel RG500Q-EA (separate firmware, see [The 5G modem](modem.md)) |
| Wi-Fi | Qualcomm `ath11k` radios |
| Ethernet | Qualcomm NSS data plane |
| Kernel | Linux 6.12.94 |
| Target | `qualcommax/ipq807x`, board name `arcadyan,aw1000` |
| OpenWrt base | 25.12.5 |

The official OpenWrt [Table of Hardware page](https://openwrt.org/toh/arcadyan/astoria/aw1000)
has further background on the device.

## Front panel

The router has indicator LEDs for power, Wi-Fi, 5G, signal, internet and phone. CleanWRT
drives the first five; see [Front-panel LEDs](leds.md). The phone LED belongs to
[AWvoice](awvoice.md) and is left alone by the LED app.

## The phone port

The AW1000 has an **RJ11 socket** with a line-interface chip, for an ordinary analogue phone.
[AWvoice](awvoice.md) uses it to make and take calls over the SIM card. Mind the voltages on the
contacts, and see the safety notes on that page.

## What you need to know before flashing

- The router must have the **expanded flash layout**. The stock layout is too small. See
  [MTD layout](mtd-layout.md).
- The first install from the stock firmware needs a **serial console**. See the
  [UART guide](uart.md).
- Keep a copy of the stock firmware settings if you may ever want to go back.
