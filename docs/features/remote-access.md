---
title: "Remote access to a 5G CGNAT router"
description: "Reach your AW1000 and your LAN behind 5G CGNAT with Tailscale, Cloudflare Tunnel or WireGuard. Everything ships disabled until you turn it on."
updated: 2026-11-06
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

## Common questions

??? question "How can I reach my router behind 5G CGNAT?"
    5G gives you a carrier-grade NAT address, so port forwarding does not work. Use Tailscale, a Cloudflare Tunnel or a WireGuard server you run yourself. All of them ship disabled.

??? question "Should I use Tailscale or Cloudflare Tunnel on the AW1000?"
    Tailscale is the easiest way to reach the whole LAN from your own devices. A Cloudflare Tunnel is better for publishing one web service under your own domain.

??? question "Why does cloudflared show a red error?"
    That is expected until you configure the tunnel token on the *Configuration* tab. It is not a fault.

## Out of the box

| | state | what it needs |
|---|---|---|
| Tailscale | installed, **off** | your login. `luci-app-tailscale-community` |
| Cloudflare Tunnel | installed, **off** | your tunnel token. `cloudflared` plus its page |
| WireGuard | kernel module and tools, no tunnel | a peer config from wherever you keep one |
| OpenVPN | installed, **off** | your `.ovpn` file |
| SSH (`dropbear`) | on, with password authentication and root password authentication enabled, and **no root password set** | set a password before you use it from anywhere |
| LuCI | HTTPS on the LAN, HTTP redirected to it | see [security](security.md) |

## What is listening

| port | what | reachable from |
|---|---|---|
| 443 | LuCI over HTTPS | the LAN. Never forwarded by this image |
| 22 | SSH | the LAN |
| — | Tailscale and Cloudflare both make **outbound** connections; neither opens an inbound port |

That last row is the reason both are recommended on a CGNAT connection: there is no port to open, no
dynamic DNS to update and no rule to expose.

## When it does not work

| symptom | what it means |
|---|---|
| `cloudflared` shows a red error on its page | expected until you put a token in. It is not a fault |
| Tailscale says "needs authentication" | it does. The page gives you the link; nothing works until you have logged in |
| You cannot reach LuCI from the tunnel | the tunnel publishes a service, it does not automatically route the admin interface. Point it at the LAN address deliberately |
| SSH refuses you | no root password is set on a new router, and that is the state a remote login must not be in. Set one first |

## Questions people ask

??? question "How can I reach my router behind 5G CGNAT?"
    Outbound-first: Tailscale or a Cloudflare Tunnel. Both connect out, neither needs a public address
    or a forwarded port. WireGuard is the third option when you already have a server somewhere with
    an address.

??? question "Should I use Tailscale or Cloudflare Tunnel on the AW1000?"
    Tailscale for reaching the router and the network behind it as yourself; Cloudflare Tunnel for
    publishing one service to other people. They solve different problems and both are installed.

??? question "Is it safe to enable SSH on this router?"
    Only after you set a root password. The image ships password authentication on and no password
    set, which is OpenWrt's first-login model and is meant for the LAN with a cable in.
