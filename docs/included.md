# What is included

CleanWRT is vanilla OpenWrt 25.12.5 plus the apps below. Everything else in the firmware is
stock OpenWrt. For the complete, generated list of selected packages see
[Full package list](generated/packages.md).

Apps marked **Off** are installed but do nothing until you turn them on: open the page named in
the table, tick **Enable** and press **Save & Apply**. Every one of them has this same single
switch.

| App | Where in LuCI | Out of the box | What it is for |
|---|---|---|---|
| AWvoice | Services → AWvoice(RJ11) | On | phone calls on the RJ11 port over the SIM ([AWvoice](awvoice.md)) |
| QModem (+ SMS, TTL) | Modem | On | 5G modem control, SMS, TTL tools |
| 3ginfo-lite | Modem → 3gInfo-lite | On | SIM and signal details |
| sms-forwarder | part of QModem | On | forwards received SMS |
| Passwall | Services → PassWall | Off (configure servers) | proxy / bypass suite |
| Passwall 2 | Services → PassWall 2 | Off (configure servers) | proxy / bypass suite (v2) |
| HomeProxy | Services → HomeProxy | Off | sing-box based proxy |
| WireGuard | Network → Interfaces | needs a tunnel from you | VPN protocol support |
| OpenVPN | VPN → OpenVPN | Off (needs your .ovpn file) | VPN client and server |
| Tailscale | Services → Tailscale | needs your login | mesh VPN |
| Cloudflare Zero Trust Tunnel | Services → Cloudflare Zero Trust Tunnel | Off | publish a service without a public IP |
| Adblock | Services → Adblock | Off | DNS ad blocking |
| Watchcat | Tools → Watchcat | no rule (add one) | reboot or restart an interface when the connection is lost |
| AdGuard Home | Services → AdGuard Home | Off | DNS filtering with its own dashboard ([web apps](features/web-apps.md)) |
| Disk Manager | Services → Disk Manager | On | partition and format USB drives |
| HDD Idle | Tools → HDD Idle | Off | spin down a USB hard disk |
| Network Shares (Samba) | Network → Filesystem Share | Off (no guest access) | Windows / macOS / Linux file sharing |
| miniDLNA | Services → miniDLNA | Off | media server for TVs and players |
| Syncthing | Services → Syncthing | Off | folder sync with your phone and PC ([web apps](features/web-apps.md)) |
| qBittorrent | Services → qBittorrent | Off | download client with its own web interface ([web apps](features/web-apps.md)) |
| File Manager | Tools → File Manager | On | browse and edit router files |
| Printer server (p910nd) | Services → p910nd | Off | share a USB printer |
| Bandwidth Monitor | Tools → Bandwidth Monitor | On | traffic per device |
| vnStat | Statistics → vnStat | On | traffic history, monthly totals |
| SQM QoS | Network → SQM QoS | Off (set your speeds) | fix bufferbloat |
| Web terminal (ttyd) | Tools → Terminal | On | a shell in the browser |
| Apex theme | System → System → Language and Style | On | the default look ([theme](theme.md)) |
| LED Management | System → LED Management | On | front-panel LEDs ([LEDs](leds.md)) |
| New-version notice | Status → Overview | On | tells you when a newer CleanWRT is published |

## Core and system

| Package | Role |
|---|---|
| `luci` and the `luci-mod-*` set | web admin UI |
| `dnsmasq-full` | DNS and DHCP server |
| `firewall4` / `nftables` | firewall and NAT |
| `kmod-ath11k` and `wpad` | Wi-Fi |
| `kmod-qca-nss-dp`, `kmod-qca-ssdk` | Ethernet data plane |
| `irqbalance`, `zram-swap`, packet steering | spreads load over the four cores |
| BBR congestion control | good for cellular links |

## Command line tools

`bash`, `htop`, `nano`, `jq`, `curl`, `openssl-util`, `openssh-sftp-server`, `ethtool-full`,
`mtr-json`, `iperf3`, `usbutils`, and `cw-diag` (see [Monitoring](features/monitoring.md)).

## Need something else?

The official OpenWrt package repositories are enabled, so `apk add <name>` works (for example
`apk add mwan3 luci-app-mwan3`). Packages you add yourself are yours to manage. See
[Extra packages](extra-packages.md).

## IPv6 and proxies

The 5G connection is dual-stack when your carrier offers IPv6. If you send traffic through
Passwall 2, enable **IPv6 TProxy** in its forwarding settings. To use IPv4 only, set the
modem's PDP type to IPv4 in *Modem → QModem*.
