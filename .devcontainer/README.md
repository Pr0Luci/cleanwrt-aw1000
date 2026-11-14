# Dev container

> Added by this fork, not part of upstream
> [Pr0Luci/cleanwrt-aw1000](https://github.com/Pr0Luci/cleanwrt-aw1000). It's a thin wrapper:
> the builder image (`docker/Dockerfile`) and the build script (`tools/cw-release-build.sh`) are
> upstream's own (see the fork's change list in the top-level `README.md`).

The pinned builder image (`docker/Dockerfile`) plus a non-root `builder` user
matching your host uid. The **parent** folder is mounted at `/workspaces/cleanwrt`:

```
cleanwrt/
├── cleanwrt-aw1000/        this repo (the working project)
├── aw1000-feed/            reference only, read-only in the editor
├── openwrt/                OpenWrt tree at the pinned tag (cw-dev tree)
├── out/                    build logs and collected images
└── cleanwrt.code-workspace
```

`aw1000-feed/` is a separate project, cloned next to this repo:
[XT-Martinez/aw1000-feed](https://github.com/XT-Martinez/aw1000-feed) by XT-Martinez
(through the fork [ShanelkaPramuditha/aw1000-feed](https://github.com/ShanelkaPramuditha/aw1000-feed)).
It's an AW1000 package feed for the `ppe-nss` OpenWrt tree. It's here only to read for
comparison: the build doesn't use it and the image contains none of its code. Its packages keep
their own licences (`PKG_LICENSE`, GPL-2.0 / GPL-2.0-only).

1. Open `cleanwrt-aw1000` in VS Code → **Dev Containers: Reopen in Container**.
2. When it asks, **Open Workspace** (`cleanwrt.code-workspace`).
3. Run tasks (Terminal → Run Task) or `cw-dev` in the terminal:

| Command | What |
|---|---|
| `cw-dev tests` | shell syntax + `tools/tests` (the `scripts` job of check.yml) |
| `cw-dev tree` | clone OpenWrt at `OPENWRT_TAG` into `../openwrt` |
| `cw-dev check` | feeds, patches, pins, defconfig, seed checks; no compile |
| `cw-dev build [--clean\|--dirclean]` | the image; incremental without a flag |
| `cw-dev collect` | copy images + checksums to `../out/<version>/` |
| `cw-dev status` | paths, tag, cache and disk use |

`tools/cw-release-build.sh` runs as root through `sudo` (it chowns the overlay
to 0:0, as in CI), so files in `../openwrt` become root-owned. The repo is only
read. `CW_MAX_IMAGE_MB=130` and `CW_CCACHE=1` are set as in the release workflow.

The build uses `make -j$(nproc)`. Under WSL, give it enough memory in
`%UserProfile%\.wslconfig` (`[wsl2]` → `memory=`, `swap=`) or large Go/Rust
packages may be killed.
