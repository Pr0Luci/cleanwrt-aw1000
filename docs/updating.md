---
title: "Updating CleanWRT and package pinning"
description: "How to update CleanWRT on the AW1000, which packages are pinned and why, and what to do if a package upgrade breaks something."
---

# Updating and pinning

## Firmware updates

Install a new release with `sysupgrade` (see [Installation](installation.md#already-on-openwrt-sysupgrade)).
Keep settings between CleanWRT releases; use a clean install (`-n`) when changing major versions
or when a release note asks for it.

## What is pinned, and why

An on-device `apk upgrade` once replaced the LuCI pages with the upstream builds and silently
dropped the project's patches (the overview cards went back to plain tables). To prevent that,
the following are **pinned** to the versions of the release:

| Pinned | Because |
|---|---|
| every package from the LuCI feed | the patched pages must never be replaced by a stock build |
| `base-files` | its files in `/rom` are read-only |
| the kernel and every `kmod-*` | they are tied to the running kernel; a kernel change is always a flash |

They change only with the next firmware release.

Every other package is **unpinned**. `apk update && apk upgrade` delivers upstream security fixes
(for example `openssl`, `mbedtls`, `ca-bundle`, `uhttpd`).

!!! note "Upgrading packages restarts services"
    Upgrading packages restarts the affected services (network, Wi-Fi, web server) for a moment.

## If a package upgrade breaks something

Recovery from a failed package upgrade is **flashing the release again**. A factory reset does
**not** restore packages that were replaced.

## Pins are renewed after every flash

The pin list is generated from the installed package database on the first boot after a flash,
including a keep-settings `sysupgrade`. The pins therefore always match the running image, and an
old pin can never demand a downgrade.

## Source pins in the repository

For builders: every feed is pinned to a commit in `feeds.conf.default`, and the packages that
are not feeds are pinned in `configs/local-packages.pin`. The build fails if a checkout does not
match its pin. See [Build from source](building.md).
