---
title: "USB storage, Samba, DLNA and torrents on OpenWrt"
description: "Use a USB drive with the Arcadyan AW1000: auto-mount, Samba file sharing, qBittorrent, Syncthing, a DLNA media server and a printer server, all opt-in."
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
