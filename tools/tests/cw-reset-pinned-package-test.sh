#!/bin/sh
# cw-reset-pinned-package-test.sh - check what cw-reset-pinned-package.sh guarantees
# on a scratch tree that needs no network.
#
#   usage: tools/tests/cw-reset-pinned-package-test.sh
#
# The guarantee is a name boundary. A release build clears one pinned package's finished
# state - its build directory, its records in the staging area, and the .apk an image is
# assembled from - because OpenWrt's own stamp does not notice that the files under
# package/<name> were replaced between two builds, and the tree then ships what an earlier
# commit of the pinned repository produced. Two ways that goes wrong both look like success:
# clearing too little leaves the old package in the image, and clearing too much takes a
# neighbour's work with it, because package names share prefixes (luci-app-qmodem and
# luci-app-qmodem-sms are two packages). So every case below asks both halves of the same
# question: did the named package's state go, and did every other name stay where it was.
set -eu

TESTS=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SCRIPT="$TESTS/../cw-reset-pinned-package.sh"
[ -f "$SCRIPT" ] || { echo "test: $SCRIPT not found" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'chmod -R u+rwX "$WORK" 2>/dev/null; rm -rf "$WORK"' EXIT INT TERM

mk() { mkdir -p "$(dirname "$1")"; printf 'content of %s\n' "$(basename "$1")" > "$1"; }

# the package the tool is pointed at, and one of its own version directories
mk "$WORK/tree/package/demo/Makefile"
mk "$WORK/tree/build_dir/target-any_musl/demo/src/old.c"
mk "$WORK/tree/build_dir/target-any_musl/demo-1.2/src/older.c"
mk "$WORK/tree/staging_dir/target-any_musl/pkginfo/demo.provides"
mk "$WORK/tree/staging_dir/packages/any/demo-1.2.apk"
# the neighbours: a package whose name starts with demo's, and its records and apk
mk "$WORK/tree/build_dir/target-any_musl/demo-extra/src/keepme.c"
mk "$WORK/tree/build_dir/target-any_musl/demo-extra-9.9/src/keepme2.c"
mk "$WORK/tree/staging_dir/target-any_musl/pkginfo/demo-extra.provides"
mk "$WORK/tree/staging_dir/packages/any/demo-extra-1.0.apk"

# the shadow: a feed that carries a package of the same name, linked into the tree the way
# `./scripts/feeds install -a` links it, with older content than the pin
mk "$WORK/tree/feeds/luci/themes/demo/Makefile"
mk "$WORK/tree/feeds/luci/themes/demo/htdocs/older.js"
mk "$WORK/tree/feeds/luci/themes/demo-extra/Makefile"
mkdir -p "$WORK/tree/package/feeds/luci"
ln -s ../../../feeds/luci/themes/demo "$WORK/tree/package/feeds/luci/demo"
ln -s ../../../feeds/luci/themes/demo-extra "$WORK/tree/package/feeds/luci/demo-extra"

sh "$SCRIPT" "$WORK/tree" demo > "$WORK/first.out" 2>&1

for gone in \
    "build_dir/target-any_musl/demo/src/old.c" \
    "build_dir/target-any_musl/demo-1.2/src/older.c" \
    "staging_dir/target-any_musl/pkginfo/demo.provides" \
    "staging_dir/packages/any/demo-1.2.apk"; do
    [ ! -e "$WORK/tree/$gone" ] || {
        echo "FAIL: the named package's own state is still there: $gone" >&2; exit 1; }
done
for kept in \
    "build_dir/target-any_musl/demo-extra/src/keepme.c" \
    "build_dir/target-any_musl/demo-extra-9.9/src/keepme2.c" \
    "staging_dir/target-any_musl/pkginfo/demo-extra.provides" \
    "staging_dir/packages/any/demo-extra-1.0.apk"; do
    [ -f "$WORK/tree/$kept" ] || {
        echo "FAIL: a neighbour package was cleared: $kept" >&2; exit 1; }
done
# the feed's link into the tree goes, so the pin is the only recipe of this name; the feed's
# own directory stays, because a `./scripts/feeds update` is entitled to find the feed as pinned
[ ! -e "$WORK/tree/package/feeds/luci/demo" ] || {
    echo "FAIL: the feed still shadows the pinned package" >&2; exit 1; }
[ -f "$WORK/tree/feeds/luci/themes/demo/Makefile" ] || {
    echo "FAIL: the feed's own source was deleted instead of its link" >&2; exit 1; }
[ -e "$WORK/tree/package/feeds/luci/demo-extra" ] || {
    echo "FAIL: a neighbouring feed link was removed" >&2; exit 1; }
grep -q 'shadowed by the pin' "$WORK/first.out" || {
    echo "FAIL: the shadow went silently" >&2; exit 1; }
grep -q 'demo' "$WORK/first.out" || {
    echo "FAIL: the tool said nothing about what it cleared" >&2; exit 1; }

# A second run on a tree with nothing left is not an error - that is the first build.
sh "$SCRIPT" "$WORK/tree" demo > "$WORK/second.out" 2>&1 || {
    echo "FAIL: an empty tree is refused instead of reported" >&2; exit 1; }
grep -q 'had nothing to clear' "$WORK/second.out" || {
    echo "FAIL: an empty tree went quiet instead of saying so" >&2; exit 1; }

# The preflight is what keeps a mistyped name from being a licence to delete: the tool is
# called after the pin is installed, so a package that is not in the tree stops it here.
if sh "$SCRIPT" "$WORK/tree" nosuchpkg > "$WORK/preflight.out" 2>&1; then
    echo "FAIL: a package that is not installed was accepted" >&2; exit 1;
fi
grep -q 'nosuchpkg' "$WORK/preflight.out" || {
    echo "FAIL: the refusal did not name the package it would not touch" >&2; exit 1; }
[ -f "$WORK/tree/build_dir/target-any_musl/demo-extra/src/keepme.c" ] || {
    echo "FAIL: the refused run cleared something anyway" >&2; exit 1; }

# A name is matched against the tree, not run through a shell: a name carrying a glob or a
# separator is refused rather than expanded.
if sh "$SCRIPT" "$WORK/tree" 'demo*' > "$WORK/badname.out" 2>&1; then
    echo "FAIL: a name with a shell metacharacter was accepted" >&2; exit 1;
fi

printf 'cw-reset-pinned-package-test: all tests passed\n'
