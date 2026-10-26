---
title: "Apex: a dark and light LuCI theme for OpenWrt"
description: "Apex is the default LuCI theme of CleanWRT: dark and light mode, a sidebar and mobile drawer, and card-style status widgets. Screenshots and details."
---

# The Apex theme

Apex is the default LuCI theme in CleanWRT. It is a dense, technical interface that stays
readable on a phone. The source is in the
[`luci-theme-apex`](https://github.com/Pr0Luci/luci-theme-apex) repository.

## What it looks like

- **Dark by default**, with an automatic light mode that follows your system, and a toggle in
  the top bar to force either one (your choice is remembered in the browser).
- A **sidebar** for navigation and a **drawer** on small screens (a 390 px phone is a first-class
  target).
- A teal accent colour and monospace type for technical values.
- A dedicated **login page**, which also introduces [AWvoice](awvoice.md).
- **Card-style status widgets** on *Status → Overview* for system, modem, memory and storage,
  instead of long tables.

## Screenshots

=== "Dark"

    [![Status overview, dark](assets/img/overview-dark.png)](assets/img/overview-dark.png)

=== "Light"

    [![Status overview, light](assets/img/overview-light.png)](assets/img/overview-light.png)

=== "Phone"

    [![Status overview on a phone](assets/img/overview-mobile.png)](assets/img/overview-mobile.png){ width="300" }

The login page, dark and light:

| Dark | Light |
|---|---|
| ![Login, dark](assets/img/login-dark.png) | ![Login, light](assets/img/login-light.png) |

!!! info "About the screenshots"
    The screenshots in this documentation were taken from a development preview of the interface
    (the same theme, pages and LED app as the firmware) running on a computer, with a simulated
    modem. Values such as the kernel, memory and storage differ on a real router.

## Switching themes

Apex is selected on the first boot. To change it later:

*System → System → Language and Style → Design*

The stock Bootstrap theme stays installed as a fallback. Pages that use the card widgets fall
back to the normal tables when another theme is active, so nothing is lost.

## Fonts

The login page uses two self-hosted fonts, Inter and JetBrains Mono, licensed under the SIL
Open Font License 1.1. No font is loaded from an outside server.

## Notes for developers

The other parts of CleanWRT are on the [Repositories](repositories.md) page.

The theme is an ordinary LuCI ucode theme: `header.ut`, `footer.ut` and the login page
`sysauth.ut` under `ucode/template/themes/apex/`, a stylesheet with design tokens
(`--ax-*` custom properties) and a small script for the sidebar. The status widgets are produced
by patches to the pinned LuCI and QModem feeds (`patches/feeds/`), and only render while Apex is
the active theme.

## Common questions

??? question "Does CleanWRT have a dark mode?"
    Yes. The Apex theme is dark by default, switches to a light mode that follows your system, and has a toggle in the top bar to force either one. Your choice is remembered in the browser.

??? question "Does the Apex theme work on a phone?"
    Yes. A sidebar becomes a drawer on small screens, and a 390 px wide phone is a first-class target.

??? question "How do I switch back to the default OpenWrt theme?"
    Go to *System → System → Language and Style → Design*. The stock Bootstrap theme stays installed as a fallback, and pages with card widgets fall back to normal tables when another theme is active.
