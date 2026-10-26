---
title: "Extra packages and the CleanWRT package feed"
description: "Install more packages on the Arcadyan AW1000 with apk from the official OpenWrt repositories, and how the optional CleanWRT feed works."
---

# Extra packages

## From the official repositories

The official OpenWrt 25.12.5 repositories are enabled on every router:

```sh
apk update
apk add <package>
```

Examples that are not part of the image: `mwan3` and `luci-app-mwan3` (multi-WAN),
`transmission-daemon` (another download client), `aria2`, `luci-app-acme` (certificates).

Packages you add yourself stay unpinned and are yours to manage.

## The optional CleanWRT feed (`cw-opt`)

CleanWRT can publish its own signed `apk` feed for packages the official repositories do not
carry, such as OpenClash. **The feed is not active in the `25.12.5-rc1` image**: the repository
holds a disabled template, `files/etc/apk/repositories.d/cw-opt.list.disabled`, and the feed is
switched on only when its index is published and its signing key exists.

How it is enabled (for the project, not for users):

1. Build once so the tree creates its apk signing key.
2. Copy the public half to `files/etc/apk/keys/public-key.pem`.
3. Publish the index first. An image that carries a dead feed entry breaks `apk update` on every
   device.
4. Rename the file to `cw-opt.list` and rebuild.

Until then, `apk update` talks to the official repositories only, and it works from the first
boot.

## What is already baked in

qBittorrent and AdGuard Home are part of the image, with the Qt6 stack that qBittorrent needs.
They come from the project's vendored feed (`feeds-src/cwfeed`) and stay disabled until you
enable them.
