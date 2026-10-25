#!/usr/bin/env bash
# cw-publish-feed.sh - build and verify the CleanWRT apk feed (cw-opt).
#
# The feed at https://pr0luci.github.io/cleanwrt-aw1000/feed/ carries what the official
# OpenWrt 25.12.5 repositories do not: the apks built from our feeds (qmodem,
# passwall*, 3ginfo, diskman, cwfeed, openclash) plus the community-feed outputs of
# the official `packages` feed that the opt-set closure needs.
#
#   feed set = every *.apk in bin/packages/<arch>/<feed>/ except base and luci
#
# Run it on the build host after the release build, before flashing the build:
#
#   tools/cw-publish-feed.sh <tree>                 # build + verify only (dry run)
#   tools/cw-publish-feed.sh <tree> --out <dir>     # also write the verified feed to <dir>
#
# <dir> is then committed as feed/ on the gh-pages branch of Pr0Luci/cleanwrt-aw1000 (the
# release workflow does this). The previous commit stays in git history, so a bad push
# can be reverted.
#
# Verification (any failure stops before anything is written):
#   1. no orphan output dir (bin/packages dir not in feeds.conf.default / cwfeed)
#   2. no package name twice with different versions in the set
#   3. the index is signed with the tree key and verifies against the key shipped in
#      the image (files/etc/apk/keys/public-key.pem)
#   4. qbittorrent in the set == PKG_VERSION-r<PKG_RELEASE> of feeds-src/cwfeed
#      (no stale release) and its luci app is in the set
#   5. the device solver (apk add --simulate against the official repos + the new
#      index) resolves the opt set completely
set -eu

TREE=""; OUT=""
while [ $# -gt 0 ]; do
    case "$1" in
        --out) OUT="${2:?--out needs a directory}"; shift 2 ;;
        -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
        *) [ -z "$TREE" ] && TREE="$1" || { echo "unexpected argument: $1" >&2; exit 2; }; shift ;;
    esac
done
[ -n "$TREE" ] && [ -d "$TREE" ] || { echo "usage: $0 <build-tree> [--out <dir>]" >&2; exit 2; }

REPO=$(cd "$(dirname "$0")/.." && pwd)
ARCH=aarch64_cortex-a53
BIN="$TREE/bin/packages/$ARCH"
APK="$TREE/staging_dir/host/bin/apk"
KEY="$TREE/private-key.pem"
PUBKEY="$REPO/files/etc/apk/keys/public-key.pem"
PUBLIC_URL="https://pr0luci.github.io/cleanwrt-aw1000/feed/packages.adb"
fail() { echo "cw-publish-feed: ERROR: $*" >&2; exit 1; }

for f in "$APK" "$KEY" "$PUBKEY"; do [ -e "$f" ] || fail "missing $f"; done
[ -d "$BIN" ] || fail "missing $BIN (was the release built?)"

W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
mkdir -p "$W/feed" "$W/keys"

# 1. orphan guard + feed set
known=$(awk '/^src-/ {print $2}' "$REPO/feeds.conf.default"; echo cwfeed)
set=""
for d in "$BIN"/*/; do
    n=$(basename "$d")
    case "$n" in base|luci) continue ;; esac
    printf '%s\n' "$known" | grep -qx "$n" || fail "orphan output dir bin/packages/$ARCH/$n is not a configured feed (prune it)"
    set="$set $n"
done
[ -n "$set" ] || fail "no feed output directories found"
for n in $set; do
    for a in "$BIN/$n"/*.apk; do
        [ -f "$a" ] || continue
        b=$(basename "$a")
        if [ -e "$W/feed/$b" ]; then cmp -s "$a" "$W/feed/$b" || fail "$b exists twice with different content"; continue; fi
        ln "$a" "$W/feed/$b" 2>/dev/null || cp -p "$a" "$W/feed/$b"
    done
done
count=$(ls "$W/feed"/*.apk | wc -l)
echo "feed set: $count apks from:$set"

# 2. one version per name
dups=$(ls "$W/feed" | sed -E 's/-[0-9][^-]*(-r[0-9]+)?\.apk$//; s/\.apk$//' | sort | uniq -d | tr '\n' ' ')
if [ -n "$dups" ]; then
    # names legitimately end in a digit-led token; confirm with the apk metadata
    dups=$("$APK" --allow-untrusted adbdump "$W"/feed/*.apk 2>/dev/null | awk '/^name:/ {print $2}' | sort | uniq -d | tr '\n' ' ')
fi
[ -z "$dups" ] || fail "more than one version in the set for: $dups"

# 3. signed index + verification against the shipped key
cp "$PUBKEY" "$W/keys/"
"$APK" mkndx --allow-untrusted --sign-key "$KEY" -d "CleanWRT feed" -o "$W/feed/packages.adb" "$W"/feed/*.apk >/dev/null
"$APK" --keys-dir "$W/keys" --no-network --no-cache verify "$W/feed/packages.adb" >/dev/null 2>&1 ||
    fail "the new packages.adb does not verify against files/etc/apk/keys/public-key.pem (wrong signing key?)"
echo "index: $("$APK" --allow-untrusted adbdump "$W/feed/packages.adb" | grep -c '^  - name:') packages, signature verifies against the shipped key"

# 4. qbittorrent freshness
mk="$REPO/feeds-src/cwfeed/net/qbittorrent/Makefile"
ver=$(sed -n 's/^PKG_VERSION:=//p' "$mk" | head -1); rel=$(sed -n 's/^PKG_RELEASE:=//p' "$mk" | head -1)
want="qbittorrent-$ver-r$rel.apk"
[ -f "$W/feed/$want" ] || fail "$want is not in the feed set"
n=$(ls "$W/feed" | grep -c '^qbittorrent-[0-9]')
[ "$n" = 1 ] || fail "$n qbittorrent apks in the set (want exactly $want)"
ls "$W/feed" | grep -q '^luci-app-qbittorrent-[0-9]' || fail "luci-app-qbittorrent missing from the set"
echo "qbittorrent: $want (matches PKG_RELEASE $rel)"

# 5. device solver: official repos + the new index must resolve the opt set
root=$(ls -d "$TREE"/build_dir/target-*/root-*/ 2>/dev/null | head -1)
[ -n "$root" ] || fail "no image root in build_dir (needed for the solver check)"
cp -a "$root" "$W/root"
{ sed 's/^#.*//;/^$/d' "$REPO"/files/etc/apk/repositories.d/distfeeds.list
  printf 'file://%s/packages.adb\n' "$W/feed"; } > "$W/root/etc/apk/repositories"
out=$("$APK" --arch "$ARCH" --no-cache --root "$W/root" --allow-untrusted add -s qbittorrent luci-app-qbittorrent luci-app-openclash adguardhome 2>&1) || {
    printf '%s\n' "$out" | tail -8 >&2; fail "the opt set does not resolve against the official repos + the new index"; }
echo "solver: the opt set resolves ($(printf '%s\n' "$out" | tail -1))"

if [ -z "$OUT" ]; then
    echo "DRY RUN OK - nothing written. To write the verified feed: $0 $TREE --out <dir>"
    exit 0
fi

mkdir -p "$OUT"
cp -a "$W/feed/." "$OUT/"
loc=$(sha256sum "$OUT/packages.adb" | cut -d' ' -f1)
echo "WROTE $OUT ($count apks + packages.adb, index sha256 $loc)"
echo "Commit it as feed/ on the gh-pages branch; $PUBLIC_URL must serve the same packages.adb before an image with cw-opt.list is flashed."
