---
title: "WireGuard, OpenVPN and Passwall on OpenWrt"
description: "The VPN and proxy tools shipped in CleanWRT for the Arcadyan AW1000, what is off by default, which cores are in the image and which were left out."
updated: 2026-11-06
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

## Proxies and bypass tools

| App | Where | Cores |
|---|---|---|
| Passwall 2 | *Services → PassWall 2* | Xray, Sing-box, Hysteria and more |
| Passwall | *Services → PassWall* | the same cores |
| HomeProxy | *Services → HomeProxy* | sing-box |

Add a node (server), pick the matching core, set the routing mode and enable. `dnsmasq-full` and
`chinadns-ng` are already wired in.

!!! tip "Use one proxy suite at a time"
    Running more than one proxy suite on the same router makes firewall and DNS rules fight.
    Enable the one you want.

**IPv6:** if you send traffic through Passwall 2, enable **IPv6 TProxy** in its forwarding
settings. Passwall 1 hides IPv6 answers for proxied names by default.

## Common questions

??? question "Does CleanWRT include WireGuard and OpenVPN?"
    Yes. WireGuard is fully installed with no interfaces configured, and OpenVPN needs your own `.ovpn` configuration. Both ship disabled.

??? question "Can I run Passwall and HomeProxy at the same time?"
    It is better not to. Several proxy suites on one router make firewall and DNS rules fight, so enable the one you want.

??? question "Why do I need IPv6 TProxy in Passwall 2?"
    Without it, devices can reach IPv6 sites directly, outside the proxy. Enable it in the forwarding settings when you proxy traffic through Passwall 2.

## Out of the box

| | state |
|---|---|
| WireGuard | kernel module and `wireguard-tools`, **no tunnel configured** |
| OpenVPN | installed, off, needs your `.ovpn` |
| Passwall, Passwall 2, HomeProxy | installed, **all off**. Their cores — `sing-box`, `xray-core`, `v2ray-plugin`, `hysteria`, `naiveproxy`, `ipt2socks`, `microsocks`, `dns2socks` — are in the image |
| Tailscale, Cloudflare Tunnel | installed, off. They belong on [remote access](remote-access.md) |
| Shadowsocks-Rust, ShadowsocksR-libev, Simple-Obfs, shadow-tls | **not in the image**, and the reasons are in the seed: a deleted upstream asset, a recipe that fails to build, an archived project with a failing tarball hash. The same protocols are covered by xray-core and sing-box |
| OpenClash | **never seeded.** It lives in the optional `cw-opt` feed, which is not published yet |

## What is listening

A proxy suite that is off listens on nothing. When enabled, the transparent-proxy ports are local to
the router and the LAN, and none of them is forwarded from the cellular side by this image.

## When it does not work

| symptom | what it means |
|---|---|
| Traffic still goes out unproxied over IPv6 | Passwall 2 needs **IPv6 TProxy** enabled in its forwarding settings, or devices reach IPv6 sites directly |
| Two suites fight and one wins | run one. Both install transparent-proxy rules on the same ports |
| `apk upgrade` pulled a different version of a core | the feed pins decide what the image is built with; see [updating and pinning](../updating.md) |
| A server you added is refused | check the core it needs is in the image. The excluded list above is the set that is not |

## Questions people ask

??? question "Does CleanWRT include WireGuard and OpenVPN?"
    Yes. WireGuard is a kernel module plus tools and a LuCI page; OpenVPN is installed with its own
    page and needs your configuration file. Neither is configured out of the box.

??? question "Can I run Passwall and HomeProxy at the same time?"
    You can install both, but only one should be enabled: they both install transparent-proxy rules
    and the second one silently changes where the first one's traffic goes.

??? question "Why do I need IPv6 TProxy in Passwall 2?"
    Because the 5G connection is dual-stack when your carrier offers IPv6, and a proxy that only
    captures IPv4 leaves IPv6 traffic going out directly.
