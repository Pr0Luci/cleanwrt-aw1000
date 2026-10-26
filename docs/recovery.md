# Recovery and unbrick

Read this page before you flash. The AW1000 has a **single NAND layout with no A/B fallback
partition**. A bad write to the kernel or rootfs partitions leaves you at the bootloader, and
recovery needs the [serial console](uart.md).

Pick the situation that matches yours:

| Situation | Go to |
|---|---|
| the router boots, but LuCI or SSH is unreachable or misconfigured | [Failsafe mode](#failsafe-mode) |
| boot loop, the LEDs stop early, or a `sysupgrade` was interrupted | [Bootloader recovery](#bootloader-level-recovery-u-boot-alive) |
| the serial console shows nothing at all | [U-Boot is broken](#u-boot-itself-is-broken) |

## Failsafe mode

Use it when the router boots but you cannot reach it.

1. Set your computer's network card to `192.168.1.x` (for example `192.168.1.10`) and connect to
   a LAN port with **Ethernet**.
2. Power-cycle the router. When the boot LED starts blinking, press the reset button a few times;
   failsafe starts if a press is registered during boot.
3. The router comes up at `192.168.1.1` with SSH and **no root password**.

    ```sh
    ssh root@192.168.1.1
    mount_root          # mount the overlay so you can edit your config
    firstboot && reboot # factory reset (destroys your configuration)
    # or fix the specific file under /overlay/upper/... and then: reboot
    ```

Failsafe works only over **Ethernet**. It does not work over Wi-Fi or the 5G modem.

## Bootloader level recovery (U-Boot alive)

Symptoms: boot loop, the LED stops early, or you interrupted a `sysupgrade`.

1. Connect the [UART](uart.md) and interrupt U-Boot.
2. Boot an **initramfs** image over TFTP (`tftpboot` then `bootm`, see
   [Installation](installation.md#first-install-from-stock-firmware-uart-tftp)). Nothing is
   written to flash, so this works even with a corrupt rootfs.
3. From the live RAM system, run `sysupgrade -v` with a full `*-sysupgrade.bin`.

## U-Boot itself is broken

If the bootloader does not answer on the UART (no prompt, no countdown), recovery means
reprogramming the NAND chip externally, with a programmer clipped onto the chip or after
removing it. That is the real brick wall. It is why you should **double-check the
[MTD layout](mtd-layout.md) and the image name before every flash**.

## What sysupgrade keeps

| Mode | Result |
|---|---|
| default (keep settings) | `/etc/config/*` and the overlay survive: passwords, Wi-Fi keys and enabled services carry across releases |
| `sysupgrade -n` | clean slate: no root password, Wi-Fi back to the default key `CleanWRT#40`, every opt-in service back to disabled |

!!! info "Upgrades do not re-run first-boot scripts"
    On a keep-settings upgrade, fixes to defaults apply only to settings that are still at
    their default. When a release note mentions a default-credential fix, do a `sysupgrade -n`
    or rotate the affected credentials by hand.

## Packages replaced by `apk upgrade`

A factory reset does **not** restore packages that `apk upgrade` replaced. To get back to the
state of a release, flash that release again. See [Updating and pinning](updating.md).
