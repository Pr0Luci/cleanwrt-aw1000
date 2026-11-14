---
title: "WireGuard, OpenVPN, Nikki and HomeProxy on OpenWrt"
description: "The VPN and proxy tools shipped in CleanWRT for the Arcadyan AW1000, what is off by default, and the two proxy apps in the image: Nikki (mihomo, Clash profiles) and HomeProxy (sing-box)."
updated: 2026-11-14
---

# VPN and proxies

All of these ship installed and **disabled**. They need your servers, keys or configuration.

## WireGuard { #wireguard }

WireGuard is fully installed (kernel module, `wg` tools and LuCI protocol support) but has **no
interfaces configured**. An empty *Status* page is normal until you create one.

**Create a tunnel:** *Network → Interfaces → Add new interface*, name it (for example `wg0`),
protocol **WireGuard VPN**, *Create interface*. In the interface's *Configuration* tab set the
private key and the peers (a peer is an endpoint plus allowed IPs).

Command line alternative:

```sh
wg genkey | tee privatekey | wg pubkey > publickey
```

then configure with `wg set`.

## OpenVPN

*VPN → OpenVPN*. The service needs your `.ovpn` configuration, so it ships disabled. Enable it
per configuration.

## Proxies

| App | Where | Core | Configured with |
|---|---|---|---|
| Nikki | *Services → Nikki* | mihomo (Clash Meta) | a Clash YAML profile: a file or a subscription URL |
| HomeProxy | *Services → HomeProxy* | sing-box | nodes added in LuCI |

!!! tip "Use one at a time"
    Both install transparent-proxy firewall rules and take over DNS. Enable one.

## Nikki: Clash profiles and a dashboard { #nikki }

Nikki runs the mihomo core with an ordinary Clash (Clash Meta) configuration, so a profile from
your provider or one you wrote yourself works as it is.

1. *Services → Nikki → Profile*. Either upload your `config.yaml` (**Upload Profile**), or add a
   **subscription** with the URL your provider gave you and press **Update**.
2. *Services → Nikki → App Config*: pick that profile, tick **Enable**, **Save & Apply**.
3. **Open Dashboard** on the same page opens Zashboard, already installed, with the secret filled
   in. There you switch proxies and groups, run latency tests, and watch connections, rules and
   logs live.

*Mixin Config* overrides parts of the profile without editing it: ports, DNS mode (fake-ip by
default), TUN or TProxy, and the dashboard address. *Proxy Config* chooses which LAN devices and
which traffic go through the proxy.

**Dashboard address:** `http://192.168.1.1:9090/ui/`. The API on port 9090 needs the secret, which
the first boot sets to 32 random characters (`nikki.mixin.api_secret`). LuCI passes it for you.

**Update Dashboard** downloads the newest Zashboard release over the installed one. A clean
install brings back the version the image ships.

## HomeProxy

Add a node (server), set the routing mode and enable. `dnsmasq-full` is already in the image, so
HomeProxy can hand its DNS rules to dnsmasq.

## Common questions

??? question "Does CleanWRT include WireGuard and OpenVPN?"
    Yes. WireGuard is fully installed with no interfaces configured, and OpenVPN needs your own `.ovpn` configuration. Both ship disabled.

??? question "Can I use my Clash config?"
    Yes, with Nikki. Upload the YAML file or add its subscription URL on *Services → Nikki → Profile*. mihomo reads Clash and Clash Meta profiles.

??? question "Where did Passwall go?"
    Passwall and Passwall 2 are not in this build. Nikki (mihomo) and HomeProxy (sing-box) cover the same use.

## Out of the box

| | state |
|---|---|
| WireGuard | kernel module and `wireguard-tools`, **no tunnel configured** |
| OpenVPN | installed, off, needs your `.ovpn` |
| Nikki | installed, **off**. Its core is `mihomo-meta` (stable); the Zashboard dashboard is preinstalled. First boot moves its HTTP proxy port from 8080 (taken) to **7893** and sets a random dashboard secret and proxy password |
| HomeProxy | installed, **off**. Its core, `sing-box`, is in the image (from the official OpenWrt packages feed) |
| Tailscale, Cloudflare Tunnel | installed, off. They belong on [remote access](remote-access.md) |
| Passwall, Passwall 2 | **not in the image** |
| OpenClash | **never seeded.** It lives in the optional `cw-opt` feed, which is not published yet |

## What is listening

A proxy that is off listens on nothing. When Nikki is enabled it listens on the LAN: 7890 (mixed
HTTP/SOCKS), 7893 (HTTP), 1080 (SOCKS), 7891/7892 (redirect and TProxy), 1053 (its DNS) and 9090
(the dashboard API, secret required). When enabled, the transparent-proxy ports are local to
the router and the LAN, and none of them is forwarded from the cellular side by this image.

## When it does not work

| symptom | what it means |
|---|---|
| Nikki will not start | the profile failed its test. *Services → Nikki → Log* shows mihomo's reason; a common one is a port in the profile that another service already uses |
| The dashboard says it cannot connect | the API address or secret. Open it from LuCI's **Open Dashboard**, which fills both in |
| Nikki and HomeProxy both enabled, traffic goes the wrong way | run one. Both install transparent-proxy rules |
| HomeProxy and a VPN fight over the traffic | run one transparent proxy or full-tunnel VPN at a time. Each installs its own routing rules |
| `apk upgrade` pulled a different version of sing-box | the feed pins decide what the image is built with; see [updating and pinning](../updating.md) |
| A server you added is refused | check that sing-box supports its protocol. sing-box is the only proxy core in the image |

## Questions people ask

??? question "Does CleanWRT include WireGuard and OpenVPN?"
    Yes. WireGuard is a kernel module plus tools and a LuCI page; OpenVPN is installed with its own
    page and needs your configuration file. Neither is configured out of the box.

??? question "Can I install Passwall myself?"
    It is not built for this image, and its cores (xray-core and others) are not in the image either.
    Nikki and HomeProxy are the supported proxy apps.

??? question "Which dashboard is it, and why that one?"
    Zashboard, the dashboard Nikki itself defaults to. The image carries its build without bundled
    fonts (it uses the system's), about 1.5 MiB on flash, so it opens without downloading anything.
