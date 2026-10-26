---
title: "OpenWrt router security defaults on the AW1000"
description: "How CleanWRT secures the Arcadyan AW1000 by default: no open services, HTTPS for the admin UI, a first-login password, Wi-Fi key and service advice."
---

# Security

## Defaults

CleanWRT starts the way stock OpenWrt does:

- **No root password** at first. The first login happens over **Ethernet**, and LuCI asks you
  to set one.
- Wi-Fi is on, WPA2-PSK, with the default key `CleanWRT#40`. Change it on the first login.
- Every opt-in service is **disabled**. Nothing listens on your network until you enable it.
- LuCI is served over **HTTPS**; plain HTTP only redirects to it.

See [First boot](../first-boot.md) for the steps.

!!! warning "Before you expose the router remotely"
    Set your root password first. Otherwise a tunnel publishes an admin interface with no
    password to the internet.

## Why the browser says "Not secure" { #why-the-browser-says-not-secure }

The admin UI uses a **self-signed TLS certificate**, generated on your router at first boot.
Every router gets a different one and no public authority signed it, so browsers warn exactly
as they do on stock OpenWrt. The connection is still encrypted. Click *Advanced → Proceed*.

If you own a domain, you can get a trusted certificate:

```sh
apk add acme-common luci-app-acme
```

Then issue a Let's Encrypt certificate with a DNS challenge (it works behind CGNAT).

## Changing the password and the Wi-Fi key later

- Root password: *System → Administration*, or `passwd` over SSH.
- Wi-Fi key: *Network → Wireless*, edit the interface, *Wireless Security*.

No re-flash is needed.

## Keeping services private

| Service | Reach | Advice |
|---|---|---|
| File sharing (SMB) | LAN | guest access is off; create users first |
| qBittorrent web UI (`:8080`) | LAN | the first start prints a temporary password to the log; set your own |
| Syncthing GUI (`:8384`) | LAN | set a GUI user and password before pairing |
| AdGuard Home (`:3000` wizard) | LAN | choose a dashboard port other than 80/443 |
| miniDLNA (`:8200`) | LAN only | no login; do not expose it |

## Reporting a problem

For a security problem, please open a private report from the repository's *Security* tab
(*Report a vulnerability*) if it is enabled, or open an issue that does not include exploit
details and ask for a private channel.

## Common questions

??? question "Why does my browser say the OpenWrt router connection is not secure?"
    LuCI uses a self-signed certificate that your router creates at first boot. The connection is still encrypted, but no public authority signed the certificate. Click *Advanced → Proceed*, or install a trusted certificate with ACME if you own a domain.

??? question "What are the default passwords on CleanWRT?"
    There is no root password at first. The first login happens over Ethernet and LuCI asks you to set one. Wi-Fi is WPA2-PSK with the default key `CleanWRT#40`. Change both on the first login.

??? question "How do I get a trusted HTTPS certificate on the router?"
    Install `acme-common` and `luci-app-acme`, then issue a Let's Encrypt certificate with a DNS challenge. That works behind CGNAT because it needs no inbound connection.
