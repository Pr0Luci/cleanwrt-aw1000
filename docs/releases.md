# Releases

Images are published on the project's
[GitHub Releases page](https://github.com/Pr0Luci/cleanwrt-aw1000/releases). Every release is
built by the `build` workflow in the repository, from the sources pinned in the release tag.

## Versions

A version looks like `25.12.5-rc1`: the OpenWrt base (`25.12.5`) and the stage.

| Stage | Meaning |
|---|---|
| `-rc1`, `-rc2` ... | release candidates. They are the testing series. |
| `-rc1.1` ... | a fix after the candidate was published |
| no suffix (`25.12.5`) | a stable release |

## What a release contains

| File | What it is |
|---|---|
| `cleanwrt-<version>-qualcommax-ipq807x-arcadyan_aw1000-squashfs-sysupgrade.bin` | the permanent image, installed with `sysupgrade` |
| `…-initramfs-uImage.itb` | a boot-in-RAM image, used for the very first install from the stock firmware |
| `…-squashfs-factory.ubi` | the raw UBI image |
| `*.manifest` | every package in the image with its version |
| `profiles.json` | machine-readable image description (also used by the LuCI update check) |
| `sha256sums`, `sha256sums.cw` | checksums of the images and of the provenance files |
| `provenance.tar.gz` | the full build `.config`, the seed, the pinned feed list, the local package pins and the exact source commits |

## Verify before you flash

Always check the checksum. A corrupted image is the most common cause of a bad flash.

=== "Linux / macOS"

    ```sh
    sha256sum -c sha256sums.cw --ignore-missing
    ```

=== "Windows (PowerShell)"

    ```powershell
    Get-FileHash .\cleanwrt-*-sysupgrade.bin -Algorithm SHA256
    # compare with the matching line in sha256sums.cw
    ```

!!! tip "Check the model too"
    The filename must contain `arcadyan_aw1000`. Never flash an image built for another device
    or another flash layout.

## Update notice in LuCI

The *Status → Overview* page can tell you when a newer CleanWRT is published. It reads a small
file on the project site, so it needs internet access. You can switch it off any time with
*Stop showing upgrade alerts*. The check never installs anything.

## Reproducing a release

The release tag, `configs/arcadyan_aw1000.seed`, `feeds.conf.default`, `configs/local-packages.pin`
and `patches/` are the complete input. See [Build from source](building.md).
