# UART guide

The serial console (UART) is how you reach the bootloader. It is required for the first
install from the stock firmware, and it is the universal recovery path as long as the
bootloader is intact.

## What you need

| Item | Notes |
|---|---|
| USB-UART adapter | **3.3 V logic only.** A 5 V adapter can damage the board. |
| Three jumper wires | TX, RX and GND. Do not connect the adapter's power pin. |
| Phillips screwdriver | to open the case |
| Terminal program | `screen`, `minicom`, PuTTY or similar |

## Connection settings

| Setting | Value |
|---|---|
| Speed | 115200 baud |
| Data / parity / stop | 8N1 |
| Flow control | none |

## Wiring

Locate the UART pads on the board. They are marked for TX, RX and GND.

- Router **TX** to adapter **RX**
- Router **RX** to adapter **TX**
- Router **GND** to adapter **GND**

Cross the data lines: transmit goes to receive. If you see nothing, swap TX and RX before you
suspect anything else.

## Connect

```sh
# Linux
screen /dev/ttyUSB0 115200
# macOS
screen /dev/tty.usbserial-XXXX 115200
```

Power the router on. You should see the boot messages. To stop the boot at the bootloader,
press a key when the countdown appears. You are now at the U-Boot prompt, and the
[installation](installation.md) and [recovery](recovery.md) steps can continue from there.

## Tips

- Disconnect the adapter's power wire; the router must power itself.
- Keep the serial session open while you flash; it shows exactly what failed if something does.
- Close the terminal when you are done. A stuck terminal on the modem's AT port (not the board
  UART) is a different matter, see [The 5G modem](modem.md).
