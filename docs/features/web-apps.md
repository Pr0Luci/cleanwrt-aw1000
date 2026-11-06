---
title: "Syncthing, AdGuard Home and qBittorrent"
description: "The three apps on CleanWRT for the AW1000 with a web interface of their own: what they listen on, what to set first, and what the image wires up for them."
updated: 2026-11-06
---

# Apps with their own web interface

Some apps are configured in their own dashboard, opened in the browser, and not inside LuCI. The
three below are installed with the firmware. The examples assume the router is at `192.168.1.1`.

## Start and stop an app

Every app has an **Enable** box on its LuCI page (*Services → the app's name*). Tick it and press
**Save & Apply** to start; untick it and press **Save & Apply** to stop. One switch, the same
everywhere.

Advanced: *System → Startup* lists services with Start and Stop buttons. They act only for the
current session. The **Enable** box is what decides whether the app runs after a reboot.

## Syncthing: folder sync

Keeps folders in step between your phone, your PC and a drive on the router.

1. *Services → Syncthing*, tick **Enable**, **Save & Apply**.
2. Open the dashboard: `http://192.168.1.1:8384`.
3. **First thing to do:** *Actions → Settings → GUI*, set a user name and password. Until then
   anyone on your network can open the dashboard.
4. Add your other devices (*Add Remote Device*) and choose the folders to share.

To keep the dashboard private to the router itself, set the *Dashboard address* on the LuCI page
to `http://127.0.0.1:8384`.

## AdGuard Home: DNS filtering

Blocks ads and trackers for every device and shows what each device looks up.

1. *Services → AdGuard Home*, tick **Enable**, **Save & Apply**.
2. The first time, the setup wizard is at `http://192.168.1.1:3000`.
3. In the wizard choose a dashboard port other than 80 or 443 (LuCI uses those) and a DNS port
   other than 53, unless you move the router's own DNS (dnsmasq).
4. Finish the wizard and open the dashboard at the address you chose.

Adblock does a similar job. Use one of them, not both.

## qBittorrent: download client

Downloads to a USB drive attached to the router, controlled from a web page.

1. *Services → qBittorrent*, tick **Enable**, **Save & Apply**.
2. Open `http://192.168.1.1:8080`.
3. The user is `admin`. There is no shared default password: until you set your own, qBittorrent
   makes a temporary one every time it starts and prints it to the log. Read it with
   `logread -e qbittorrent` (*System → Logs*).
4. Set your own: *Tools → Options → Web UI → Authentication*.

The default download folder is on the USB drive (`/mnt`); attach and mount it first.

## Out of the box

| app | state | its own interface | first thing to set |
|---|---|---|---|
| AdGuard Home | **off** | its own dashboard | it is given a local upstream by `97-cw-adguard-enable-bridge`, so the router's own resolution keeps working when the filter starts |
| Syncthing | **off** | `http://0.0.0.0:8384` | a password. The interface binds all addresses as shipped |
| qBittorrent | **off** | its own web UI | the download directory. It defaults to the first USB drive |
| Adblock | **off** | no interface of its own | the checkbox on its LuCI page |

## What is listening

Nothing until you enable an app. Each one's port and address are in
[files, ports and paths](../reference/files-and-ports.md#network-ports).

## When it does not work

| symptom | what it means |
|---|---|
| The whole network stops resolving when AdGuard Home starts | the upstream loop. This image's first-boot script wires the local upstream precisely to prevent it; if the script did not run, check the resolver port it expects |
| Syncthing's page is open to your network | it is: `0.0.0.0:8384`. Set a username and password before you enable it |
| Downloads go to flash and fill it | the download directory. Point it at a mounted USB drive first |
| An app's page shows nothing after `apk upgrade` | the pinned LuCI packages were replaced. See [updating and pinning](../updating.md) |

## Questions people ask

??? question "Which apps have their own web page on CleanWRT?"
    AdGuard Home, Syncthing and qBittorrent. Each is installed and switched off, and each listens on
    its own port only after you enable it.

??? question "Does enabling AdGuard Home break the router's own DNS?"
    Not on this image. A first-boot script gives it the local upstream it needs, which is the usual
    way this goes wrong on a stock install.
