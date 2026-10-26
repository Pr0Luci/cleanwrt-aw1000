---
title: "Remote access to a 5G CGNAT router"
description: "Reach your AW1000 and your LAN behind 5G CGNAT with Tailscale, Cloudflare Tunnel or WireGuard. Everything ships disabled until you turn it on."
---

# Remote access

5G gives you a **CGNAT** address, so port forwarding does not work. To reach the router or your
LAN from outside, pick **one** of these. All of them ship **disabled**; enable only what you use.

!!! warning "Set a root password first"
    See [Security](security.md). A tunnel to a router with no password is an open door.

## Tailscale

A mesh VPN, and the easiest option.

```sh
/etc/init.d/tailscale enable && /etc/init.d/tailscale start
tailscale up        # prints a login URL; open it to authenticate
```

The LuCI page is *Services → Tailscale*.

## Cloudflare Tunnel

Exposes a service through your Cloudflare account, with no public IP needed.

*Services → Cloudflare Zero Trust Tunnel → Configuration*: paste your tunnel token and enable.

!!! info "A red `cloudflared` error is normal until you configure it"
    Until you set it up on the **Configuration** tab, the **Tunnels** and **Log** tabs show a red
    `cloudflared` error (`config.yml was empty` or no origin certificate). That is expected for
    an unconfigured tunnel, not a fault. Configure the token first.

## WireGuard

You can also run your own WireGuard server on the router. See [VPN and proxies](vpn-proxy.md#wireguard).

## Which one?

| You want | Use |
|---|---|
| to reach the whole LAN from your devices with little setup | Tailscale |
| to publish one web service under your own domain | Cloudflare Tunnel |
| a classic VPN you control end to end (needs a public endpoint somewhere) | WireGuard |
