# cwfeed - the CleanWRT vendor feed

Packages the official OpenWrt feeds do not carry, vendored in this repository and wired
into the build as a `src-link` feed by `tools/cw-release-build.sh`.

- The qBittorrent stack from ImmortalWrt, unmodified, attribution retained:
  `net/qbittorrent`, `libs/qt6base`, `libs/libdouble-conversion`, `utils/qt6tools`
  (ImmortalWrt @ e731ba76) and `applications/luci-app-qbittorrent` plus the feed-root
  `luci.mk` (ImmortalWrt luci @ 5fc1fac5).
- `applications/luci-app-adguardhome`, from ImmortalWrt luci @ 5fc1fac5 (GPL-2.0-only,
  attribution retained). One deviation, documented in its Makefile: the `+adguardhome`
  binary dependency is dropped. The image seed names the binary explicitly and this app
  is the LuCI page for it.
- `applications/luci-app-syncthing`: the on/off switch for Syncthing, original code.

The compiled apks are served from https://pr0luci.github.io/cleanwrt-aw1000/feed/.
