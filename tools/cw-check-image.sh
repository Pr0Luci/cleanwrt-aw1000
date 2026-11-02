#!/bin/sh
# cw-check-image.sh - verify a finished release build before anything is uploaded.
#
# The build reports success when `make` returns 0. That is not the same statement as "the
# files in the output directory are the release, and they were built from the inputs this
# repository pins". This script closes that gap in seconds, so a wrong release never reaches
# a draft download page and a defect is never discovered by flashing a device.
#
# Checks (each one fails the release, none of them is advisory):
#   1. the three images exist and are non-empty: sysupgrade, factory.ubi, initramfs;
#   2. sha256sums verifies for every image it names - a truncated or mis-copied file fails here;
#   3. the config that was built is the seed's: the version label and the target profile;
#   4. the provenance bundle is complete: config, seed, feed pins, local package pins,
#      manifest, buildinfo and checksums - a release that cannot be reproduced from its own
#      bundle is not a release;
#   5. the manifest carries the packages the config selected (a band, not an exact match:
#      package names gain variant suffixes in the manifest, so an exact per-name comparison
#      would fail a healthy build; a real drop shows up as a missing fraction);
#   6. the feed key of the tree is the key devices trust (tools/cw-check-release-keys.sh),
#      when the tree holds one.
#
# Usage:   tools/cw-check-image.sh <openwrt-tree-dir> [<repo-dir>]
# Exit:    0 = release verified; 1 = a check failed (the reason is on stderr)
set -eu

TREE="${1:?usage: tools/cw-check-image.sh <openwrt-tree-dir> [<repo-dir>]}"
REPO="${2:-$(cd "$(dirname "$0")/.." && pwd)}"
OUT="$TREE/bin/targets/qualcommax/ipq807x"

fail() { echo "ERROR: cw-check-image: $*" >&2; exit 1; }
ok()   { echo "  ok: $*"; }

[ -d "$OUT" ] || fail "no output directory $OUT - the build never reached image assembly"
version=$(sed -n 's/^CW_VERSION="\(.*\)"$/\1/p' "$REPO/tools/cw-release-build.sh")
[ -n "$version" ] || fail "cannot read CW_VERSION from tools/cw-release-build.sh"
echo "== cw-check-image: $version =="

# 1 and 2. the three images: present, non-empty, and matching the checksums this build wrote
sums="$OUT/sha256sums"
[ -f "$sums" ] || fail "no sha256sums in $OUT"
missing=""
named=$(mktemp)
for s in squashfs-sysupgrade.bin squashfs-factory.ubi initramfs-uImage.itb; do
    found=$(find "$OUT" -maxdepth 1 -type f -name "*arcadyan_aw1000*$s" | head -1)
    [ -n "$found" ] || { missing="$missing $s"; continue; }
    [ "$(wc -c < "$found")" -gt 65536 ] || fail "$found is $(wc -c < "$found") bytes - too small to be a real image"
    # OpenWrt writes "<64 hex> [*]<path>": a star marks a binary entry, two spaces a text one.
    # Only the images are verified here; sha256sums also names the manifest and the buildinfo
    # files, and those are checked by the provenance pass below.
    grep "^[0-9a-f].*arcadyan_aw1000.*$s" "$sums" >> "$named" || true
done
[ -z "$missing" ] || { rm -f "$named"; fail "no image matched:$missing"; }
ok "sysupgrade, factory.ubi and initramfs present and non-empty"

covers=$(grep -c . "$named")
[ "$covers" = "3" ] ||
    { rm -f "$named"; fail "sha256sums names $covers of the three images"; }
if ! (cd "$OUT" && sha256sum -c --quiet "$named"); then
    rm -f "$named"
    fail "a checksum in sha256sums does not match the image on disk"
fi
rm -f "$named"
ok "sha256sums covers all three images and matches the files on disk"

# 3. what was built is what the seed says
[ -f "$TREE/.config" ] || fail "no .config in the tree"
grep -qx "CONFIG_VERSION_NUMBER=\"$version\"" "$TREE/.config" ||
    fail ".config carries a different version label than CW_VERSION=$version"
grep -qx 'CONFIG_TARGET_qualcommax_ipq807x_DEVICE_arcadyan_aw1000=y' "$TREE/.config" ||
    fail ".config does not select the arcadyan_aw1000 device"
ok "version label and target profile match this repository"

# 4. the provenance bundle
prov="$OUT/cw-release-provenance"
[ -d "$prov" ] || fail "no provenance bundle in $prov"
for need in config.full config.seed feeds.conf.default local-packages.pin sha256sums; do
    [ -s "$prov/$need" ] || fail "the provenance bundle is missing $need"
done
ls "$prov"/*.manifest >/dev/null 2>&1 || fail "the provenance bundle has no package manifest"
ls "$prov"/*.buildinfo >/dev/null 2>&1 || fail "the provenance bundle has no buildinfo"
ok "provenance bundle complete (config, seed, pins, manifest, buildinfo, checksums)"

# 5. the manifest against the selection
man=$(find "$prov" -maxdepth 1 -name '*.manifest' | head -1)
selected=$(grep -cE '^CONFIG_PACKAGE_[A-Za-z0-9_.-]+=y' "$TREE/.config" || true)
listed=$(wc -l < "$man" | tr -d ' ')
[ "$selected" -gt 0 ] || fail "the config selects no packages"
[ "$listed" -gt 0 ] || fail "$man is empty - the image carries no package list"
# A selection does not always reach the image as its own manifest entry (virtual packages and
# split outputs), so this is a band, not an equality: the published 25.12.5-rc2 lists 470 of the
# 511 packages its config selected - 92%. A quarter missing is a build that lost real packages.
floor=$(( selected * 3 / 4 ))
[ "$listed" -ge "$floor" ] ||
    fail "the manifest lists $listed packages but the config selects $selected: a large part of the selection never reached the image"
ok "manifest lists $listed of $selected selected packages"

# 6. the feed key, when the tree holds one
if [ -f "$TREE/private-key.pem" ]; then
    sh "$REPO/tools/cw-check-release-keys.sh" "$TREE" >/dev/null
    ok "the tree signs with the key devices trust"
else
    echo "  note: no feed key in the tree (unsigned build, cw-opt feed stays disabled)"
fi

echo "cw-check-image: verified $version for arcadyan_aw1000"
