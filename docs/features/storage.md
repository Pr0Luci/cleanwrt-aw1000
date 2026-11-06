---
title: "USB storage, Samba, DLNA and torrents on OpenWrt"
description: "Use a USB drive with the Arcadyan AW1000: auto-mount, Samba file sharing, qBittorrent, Syncthing, a DLNA media server and a printer server, all opt-in."
updated: 2026-11-06
---

# USB storage and NAS

Plug in a USB drive and it auto-mounts under `/mnt` (ext4, FAT, exFAT and NTFS). Manage mounts in
*System → Mount Points*.

## Prepare a drive in the browser

*Services → Disk Manager* creates partition tables (GPT or MBR), partitions and formats (ext4,
FAT32, exFAT, NTFS, btrfs), and shows disk health (SMART, including USB-NVMe enclosures).

!!! note "Mounts made in Disk Manager are live only"
    Set the boot-time mount in *System → Mount Points* afterwards so the drive is there after
    every reboot. The `smartd` daemon ships disabled; the UI only uses the `smartctl` command.

## NAS services (all opt-in)

Everything below ships **installed but disabled** and is pointed at the USB drive. Nothing
listens on the LAN until you enable it. **Set credentials before you enable each service.**

| Service | Where | Notes |
|---|---|---|
| Network file share (SMB) | *Network → Filesystem Share* | serves all of `/mnt` as `\\192.168.1.1\USB`; guest access is off |
| Torrents (qBittorrent) | *Services → qBittorrent* | web UI on `:8080`; downloads go to `/mnt/download` |
| Folder sync (Syncthing) | *Services → Syncthing* | web UI on `:8384` |
| Media server (miniDLNA) | *Services → miniDLNA* | DLNA on the LAN only, port 8200 |
| Printer share (p910nd) | *Services → p910nd* | raw port 9100 and mDNS |
| Web file manager | *Tools → File Manager* | browse, edit, upload, delete, hex editor |
| Drive spin-down | *Tools → HDD Idle* | for USB hard disks |

More download clients are available from the official repositories:

```sh
apk add transmission-daemon transmission-web luci-app-transmission
apk add aria2 luci-app-aria2
```

!!! warning "Plug a drive in before you download"
    Downloads default to the first USB drive (`/mnt/sda1`). With no drive attached they would fill
    the router's small internal flash. Do not start downloads without a drive.

## Streaming to a TV or phone (DLNA)

1. Plug in a drive with media.
2. Enable *Services → miniDLNA*; it scans `/mnt`.
3. Smart TVs (Samsung, LG, Sony), VLC, Kodi, phone apps and a PS4/Xbox see the server on the LAN.

For a very large library, point the database directory at the drive (*miniDLNA → Advanced*), so
it does not re-scan on every reboot.

!!! info "PlayStation 5"
    The PS5 has no built-in DLNA player. Use an app such as Plex on it.

## Common questions

??? question "Can I use a USB drive as a NAS on the Arcadyan AW1000?"
    Yes. A drive auto-mounts under `/mnt` (ext4, FAT, exFAT and NTFS), and you can share it with SMB, DLNA, Syncthing and qBittorrent. All of these ship installed but disabled, so set credentials before you enable them.

??? question "Can the AW1000 stream media to a smart TV?"
    Yes. Enable miniDLNA with a drive of media attached. Smart TVs, VLC, Kodi and phone apps on the LAN will see the server. A PlayStation 5 has no built-in DLNA player, so use an app such as Plex there.

??? question "Why should I plug a drive in before downloading?"
    Downloads default to the first USB drive. With no drive attached they would fill the router's small internal flash.

## Out of the box

| | state | what it means |
|---|---|---|
| `block-mount` | on, `anon_mount='1'`, `auto_mount='1'`, `delay_root='5'`, `check_fs='0'` | a drive plugged in appears under `/mnt` within seconds, with no swap taken and no filesystem check at boot |
| Samba | **the daemon starts** | there is one share, `USB` → `/mnt`, writable, with `guest_ok='no'` — so nothing is reachable until you add users. The package's init script has no `enabled` switch, which is why the daemon is running |
| miniDLNA | **off** (`enabled='0'`) | when on: port 8200 on `br-lan`, media from `/mnt`, database in `/var/run/minidlna`, name `CleanWRT` |
| Syncthing | **off** | when on, its own interface on `0.0.0.0:8384` and its config in `/etc/syncthing` |
| qBittorrent | **off** | downloads default to the first USB drive |
| p910nd (printer) | **off** | when on, `/dev/usb/lp0`, advertised over mDNS as `CleanWRT USB printer` |
| `hd-idle` | **off** | spin-down for a USB hard disk |
| `smartd` | **not in the image** | deliberately |
| Transmission | **not in the image** | qBittorrent covers the same job; the package is in the official feed if you want it |

## What is listening

| port | what | default state |
|---|---|---|
| 139, 445 | Samba | **open on the LAN**, but the share refuses guest access |
| 8384 | Syncthing's web interface | off. When enabled it binds all addresses, so set a password first |
| 8200 | miniDLNA | off |
| 515 | p910nd | off |
| 8080 | qBittorrent's own interface | off until the app is enabled |

## When it does not work

| symptom | what it means |
|---|---|
| The share asks for a password you do not have | `guest_ok='no'` and no users defined. Add one in *Network → Filesystem Share* |
| A new drive is not visible | mounts made inside Disk Manager are live only; add a real mount point, or plug the drive in before boot |
| Downloads filled the flash | the download directory defaults to the first USB drive. With no drive plugged in it falls back somewhere small. Plug one in first |
| The TV sees no media | miniDLNA is off by default, and its `media_dir` is `/mnt` |
| Syncthing's page is unreachable | its config section must be named `syncthing`; a section named `main` is silently ignored by the init script |

## Questions people ask

??? question "Can I use a USB drive as a NAS on the Arcadyan AW1000?"
    Yes, and it is the only place this router has room. Samba serves `/mnt` as one writable share
    with guest access off, so it is private until you add users.

??? question "Can the AW1000 stream media to a smart TV?"
    With miniDLNA switched on: port 8200 on the LAN bridge, scanning `/mnt`, announcing itself as
    `CleanWRT`.
