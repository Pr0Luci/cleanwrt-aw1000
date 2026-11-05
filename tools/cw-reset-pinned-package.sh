#!/bin/sh
# cw-reset-pinned-package.sh - put a locally pinned package back to "never built".
#
# Usage: tools/cw-reset-pinned-package.sh <openwrt-tree> <package-name>
#
# A release build writes package/<name> from configs/local-packages.pin after the previous
# build's work is already in the tree. OpenWrt decides whether to copy a package's sources
# into its build directory from a stamp of its own, and that stamp does not notice that the
# files under package/<name> were replaced - the same version number, the same Makefile,
# different content. The build then compiles what was there before and packages that, while
# every line of this script reports success. What a device meets is a package from an
# earlier commit of the pinned repository, and nothing in the build log says so.
#
# So the three places a finished package survives are cleared by name before the pin is
# installed: the build directory, the package's own records in the staging area, and the
# .apk that the image is assembled from. A name that never built anything matches nothing
# and is not an error - that is the first build of a tree.
#
# Only the named package is touched. A version is a digit, so <name>-<digit...> belongs to
# it and <name>-<letter...> belongs to another package that shares its prefix
# (luci-app-qmodem and luci-app-qmodem-sms are two packages, not one with a version).
set -eu

[ $# -eq 2 ] || { echo "usage: $0 <openwrt-tree> <package-name>" >&2; exit 2; }
TREE=${1%/}
NAME=$2

[ -d "$TREE" ] || { echo "ERROR: no tree at $TREE" >&2; exit 1; }
case "$NAME" in
    ''|*[!A-Za-z0-9._+-]*) echo "ERROR: unusable package name '$NAME'" >&2; exit 1 ;;
esac
[ -f "$TREE/package/$NAME/Makefile" ] || {
    echo "ERROR: package/$NAME is not installed in $TREE before this is run" >&2; exit 1
}

removed=0
report() {
    removed=$((removed + 1))
    echo "== reset: ${1#"$TREE"/}"
}

for dir in "$TREE"/build_dir/target-*/; do
    [ -d "$dir" ] || continue
    for stale in "$dir$NAME" "$dir$NAME"-[0-9]*; do
        [ -e "$stale" ] || continue
        report "$stale"
        rm -rf "$stale"
    done
done

for dir in "$TREE"/staging_dir/target-*/; do
    [ -d "$dir" ] || continue
    for stale in "$dir"pkginfo/"$NAME".*; do
        [ -e "$stale" ] || continue
        report "$stale"
        rm -f "$stale"
    done
done

for stale in "$TREE"/staging_dir/packages/*/"$NAME"-[0-9]*.apk; do
    [ -e "$stale" ] || continue
    report "$stale"
    rm -f "$stale"
done

# A feed that carries a package of this name shadows the pin, and the build does not say so.
# `./scripts/feeds install -a` links every feed package into package/feeds/<feed>/, and two
# recipes of one PKG_NAME are resolved by OpenWrt to one of them - so the pinned repository's
# files are installed, verified, and then quietly never compiled, while the image ships the
# feed's older copy under the same name and the same version-shaped label. This happened with
# Footstrap: the theme reached upstream LuCI at a copy older than the pinned release, and the
# device got that one. Only the link into the tree is removed; the feed's own directory stays,
# so a later `./scripts/feeds update` sees the feed exactly as its pin has it.
for shadow in "$TREE"/package/feeds/*/"$NAME" "$TREE"/package/feeds/*/"$NAME"-[0-9]*; do
    [ -e "$shadow" ] || continue
    removed=$((removed + 1))
    echo "== shadowed by the pin: ${shadow#"$TREE"/}"
    rm -rf "$shadow"
done

[ "$removed" = 0 ] && echo "== reset: $NAME had nothing to clear"
exit 0
