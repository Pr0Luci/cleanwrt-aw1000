# CleanWRT

**CleanWRT** is an independent, community build of OpenWrt 25.12.5 for the
**Arcadyan AW1000** 5G router (Qualcomm IPQ8072, Quectel RG500Q-EA modem). It adds
**AWvoice**, which turns the RJ11 socket into a working phone line, a working 5G stack, a modern
interface and a curated set of opt-in apps to stock OpenWrt. It is built in the open on GitHub from
pinned sources.

!!! note "Not affiliated with OpenWrt"
    CleanWRT is *Powered by OpenWrt* and is not affiliated with or endorsed by the OpenWrt
    project. OpenWrt® is a registered trademark of Software Freedom Conservancy (SFC).

<div class="grid cards" markdown>

-   **Plug in a phone: AWvoice**

    ---

    Use a normal desk phone on the router's RJ11 socket and make calls over your SIM. No extra
    box, no PBX, no SIP account.

    [:octicons-arrow-right-24: AWvoice](awvoice.md)

-   **Install it**

    ---

    Flash from the stock firmware (UART + TFTP) or from an existing OpenWrt install.

    [:octicons-arrow-right-24: Installation](installation.md)

-   **Check the layout first**

    ---

    The image needs the *expanded* flash layout. Flashing it on the stock layout can brick the router.

    [:octicons-arrow-right-24: MTD layout](mtd-layout.md)

-   **Know the way back**

    ---

    Failsafe, U-Boot, serial console. Read this *before* you flash, not after.

    [:octicons-arrow-right-24: Recovery](recovery.md)

-   **Use the 5G modem**

    ---

    QModem, signal details, SMS, TTL, and what a modem firmware upgrade involves.

    [:octicons-arrow-right-24: The 5G modem](modem.md)

</div>

## A look at CleanWRT

=== "Dark"

    [![Status overview in dark mode](assets/img/overview-dark.png)](assets/img/overview-dark.png)

=== "Light"

    [![Status overview in light mode](assets/img/overview-light.png)](assets/img/overview-light.png)

=== "On a phone"

    [![Status overview on a phone](assets/img/overview-mobile.png)](assets/img/overview-mobile.png){ width="300" }

!!! info "About the screenshots"
    The screenshots in this documentation were taken from a development preview of the interface
    (the same theme, pages and LED app as the firmware) running on a computer, with a simulated
    modem. Values such as the kernel, memory and storage differ on a real router.

## What you get on top of stock OpenWrt

- **AWvoice, phone calls on the RJ11 port:** an ordinary desk phone makes and takes calls over the
  SIM, with caller id, call waiting, hold, a three-way join, recall of a held call, a call log, speed
  dial, call blocking and alarm calls. See [AWvoice](awvoice.md).
- **A 5G stack that works out of the box:** QModem UI, auto-dial, dual-stack IPv4/IPv6 data,
  TTL control, SMS, a registration fix for data-only SIMs, per-interface vnStat accounting.
- **A modern interface:** the [Apex theme](theme.md) with dark and light mode, a sidebar, a mobile
  drawer and card-style status widgets.
- **Real front-panel LEDs:** a small daemon that shows 5G type, signal quality and internet
  reachability, with a night mode. See [Front-panel LEDs](leds.md).
- **Proxy and VPN tools:** Passwall, Passwall2, HomeProxy, WireGuard, OpenVPN, Tailscale and
  Cloudflare Tunnel, all installed and all off until you configure them.
- **Opt-in apps:** file sharing, DLNA, printer server, Syncthing, AdGuard Home, qBittorrent,
  Adblock and more. Nothing listens on your network until you tick **Enable**.
- **Safe defaults:** LuCI over HTTPS, BBR congestion control, no open services, no hidden
  remote access.
- **Verifiable releases:** every release has checksums and a provenance bundle (the full build
  configuration, the pinned sources and the package manifest).

## Status

CleanWRT is a release-candidate series (`25.12.5-rc1`). The image is built on GitHub Actions
from the sources pinned in the repository. Read the [known limits](faq.md#known-limits)
before relying on it for anything important.

## Where to go next

| I want to... | Go to |
|---|---|
| use a phone on the router | [AWvoice](awvoice.md) |
| download an image and check it | [Releases](releases.md) |
| know if my router is supported | [Hardware](hardware.md) |
| flash it | [Installation](installation.md) |
| set it up after flashing | [First boot](first-boot.md) |
| see what apps are included | [What is included](included.md) |
| build it myself | [Build from source](building.md) |
| fix something | [FAQ and troubleshooting](faq.md) |
| see the source code | [Repositories](repositories.md) |
