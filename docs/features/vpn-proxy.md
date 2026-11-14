---
title: "WireGuard, OpenVPN and HomeProxy on OpenWrt"
description: "The VPN and proxy tools shipped in CleanWRT for the Arcadyan AW1000, what is off by default, and which proxy core is in the image."
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

## Proxy: HomeProxy

| App | Where | Core |
|---|---|---|
| HomeProxy | *Services → HomeProxy* | sing-box |

Add a node (server), set the routing mode and enable. `dnsmasq-full` is already in the image, so
HomeProxy can hand its DNS rules to dnsmasq.

## Common questions

??? question "Does CleanWRT include WireGuard and OpenVPN?"
    Yes. WireGuard is fully installed with no interfaces configured, and OpenVPN needs your own `.ovpn` configuration. Both ship disabled.

??? question "Where did Passwall go?"
    Passwall and Passwall 2 are not in this build. HomeProxy with sing-box covers the same use: a node, a routing mode and transparent proxying.

## Out of the box

| | state |
|---|---|
| WireGuard | kernel module and `wireguard-tools`, **no tunnel configured** |
| OpenVPN | installed, off, needs your `.ovpn` |
| HomeProxy | installed, **off**. Its core, `sing-box`, is in the image (from the official OpenWrt packages feed) |
| Tailscale, Cloudflare Tunnel | installed, off. They belong on [remote access](remote-access.md) |
| Passwall, Passwall 2 | **not in the image** |
| OpenClash | **never seeded.** It lives in the optional `cw-opt` feed, which is not published yet |

## What is listening

A proxy that is off listens on nothing. When enabled, the transparent-proxy ports are local to
the router and the LAN, and none of them is forwarded from the cellular side by this image.

## When it does not work

| symptom | what it means |
|---|---|
| HomeProxy and a VPN fight over the traffic | run one transparent proxy or full-tunnel VPN at a time. Each installs its own routing rules |
| `apk upgrade` pulled a different version of sing-box | the feed pins decide what the image is built with; see [updating and pinning](../updating.md) |
| A server you added is refused | check that sing-box supports its protocol. sing-box is the only proxy core in the image |

## Questions people ask

??? question "Does CleanWRT include WireGuard and OpenVPN?"
    Yes. WireGuard is a kernel module plus tools and a LuCI page; OpenVPN is installed with its own
    page and needs your configuration file. Neither is configured out of the box.

??? question "Can I install Passwall myself?"
    It is not built for this image, and its cores (xray-core and others) are not in the image either.
    HomeProxy is the supported proxy app.
