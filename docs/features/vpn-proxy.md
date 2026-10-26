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
