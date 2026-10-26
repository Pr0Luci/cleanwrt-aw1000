---
title: "AW1000 expanded MTD layout explained"
description: "Why the Arcadyan AW1000 needs the expanded flash layout for CleanWRT, what has to fit in the rootfs partition, and how to check your router first."
---

# MTD layout

!!! danger "Read this before the first flash"
    CleanWRT does **not** fit the stock flash layout of the AW1000. It needs the **expanded
    layout**. Flashing it on a stock layout can leave the router unbootable (UART + TFTP
    recovery needed).

## What actually has to fit

What must fit is the set of **UBI volumes inside the `rootfs` MTD partition**, not the size of
the sysupgrade file.

A stock-layout AW1000 has a 100 MiB `rootfs` partition (`0x06400000`, which is 400 erase blocks
of 256 KiB). UBI reserves part of it for itself:

| Reserved by UBI | Blocks |
|---|---|
| layout volume | 2 |
| wear leveling and erase-block bookkeeping | 2 |
| bad-block reserve (20/1024 of the **whole 1 GiB chip**, whatever the partition size) | 80 |

So **316 blocks (about 76 MiB)** are left for volumes. The stock firmware's own UBI on that
partition uses exactly 316 (kernel 24 + rootfs 177 + rootfs_data 115).

## What CleanWRT needs

The `25.12.5-rc1` image needs **498 blocks**. That is more than the stock layout offers (316)
and fits the expanded layout (2720 blocks on a router with a 701 MiB `rootfs`). The release
build prints a line like this and fails if the image does not fit:

```text
UBI_PEBS volumes need 498 PEBs; stock 100 MiB layout (316): does NOT fit; gate layout=expanded (capacity 2720)
```

A `sysupgrade` that cannot create the new volumes after removing the old ones can leave the
router unbootable.

## Check your router

On a router running OpenWrt:

```sh
cat /proc/mtd
```

- The `rootfs` partition must be **at least `0x08000000`** (128 MiB, 512 blocks).
- On a stock layout that partition appears as `rootfs_bak` / `rootfs1_bak` instead. If you see
  that, **do not flash this image**.

!!! warning "Never flash an image built for another layout"
    The partition table lives on the router, not in the image. An image built for a different
    table can brick the router.

## If your router has the stock layout

CleanWRT does not convert the layout. Use a layout-conversion procedure from the OpenWrt
community for this device first, and only then install CleanWRT. Make sure you can reach the
[serial console](uart.md) before you start; you will need it if anything goes wrong.

Next: [Recovery](recovery.md). Read it before you flash.

## Common questions

??? question "How do I check the flash layout of my Arcadyan AW1000?"
    Run `cat /proc/mtd` on a router that runs OpenWrt. The `rootfs` partition must be at least `0x08000000` (128 MiB). If it shows up as `rootfs_bak` instead, you have the stock layout, so do not flash this image.

??? question "Why does OpenWrt not fit on the stock AW1000 flash layout?"
    The stock `rootfs` partition leaves 316 erase blocks for UBI volumes, and the CleanWRT image needs 498. The build checks this and fails if the image does not fit the layout it targets.

??? question "Can I flash CleanWRT if my AW1000 has the stock layout?"
    No. CleanWRT does not convert the layout. Use a layout-conversion procedure from the OpenWrt community first, make sure you can reach the serial console, and only then install.
