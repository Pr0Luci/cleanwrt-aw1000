#!/bin/sh
# cw-apply-feed-patches-test.sh - check what cw-apply-feed-patches.sh guarantees
# about a feed it is about to patch, on a scratch tree that needs no network.
#
#   usage: tools/tests/cw-apply-feed-patches-test.sh
#
# The tree here is built from two miniature git repositories: one feed of its own,
# and one linked to the tree the way a src-link feed is. The feed's two patches are
# the shapes that matter. The first rewrites a tracked file and creates a new one,
# which is what stops a build on a tree an earlier build already used: a feed update
# puts the tracked file back at the pinned commit but keeps the created file, so the
# create hunk meets a file already in place. The second patch is stacked on the first
# and reads lines only the first one writes, so a restore done between the two would
# pull the ground out from under it.
set -eu

TESTS=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SCRIPT="$TESTS/../cw-apply-feed-patches.sh"
[ -f "$SCRIPT" ] || { echo "test: $SCRIPT not found" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'chmod -R u+rwX "$WORK" 2>/dev/null; rm -rf "$WORK"' EXIT INT TERM

git init -q "$WORK/tree"
echo top one > "$WORK/tree/toplevel-file"
echo not tracked > "$WORK/tree/rootmarker"
git -C "$WORK/tree" add toplevel-file
git -C "$WORK/tree" -c user.email=t@t -c user.name=t commit -q -m base

mkdir -p "$WORK/tree/feeds/demo"
printf 'line one\nline two\n' > "$WORK/tree/feeds/demo/Makefile"
git init -q "$WORK/tree/feeds/demo"
git -C "$WORK/tree/feeds/demo" add Makefile
git -C "$WORK/tree/feeds/demo" -c user.email=t@t -c user.name=t commit -q -m demo
ln -s "$WORK/tree" "$WORK/tree/feeds/link"

mkdir -p "$WORK/repo/patches/feeds/demo" "$WORK/repo/patches/feeds/link"
DEMO="$WORK/tree/feeds/demo"

# the first patch: one hunk on a tracked file, one creating a file
mkdir -p "$DEMO/src"
printf 'line one\nline two patched\nline three\n' > "$DEMO/Makefile"
echo created by the patch > "$DEMO/src/new.c"
git -C "$DEMO" add Makefile src/new.c
git -C "$DEMO" diff --cached -M HEAD > "$WORK/repo/patches/feeds/demo/0001-demo.patch"
pin=$(git -C "$DEMO" rev-parse HEAD)
# committed, so the second patch can be written as the change from here on: stacked
# patches each carry only their own hunk, the way a feed's patch chain is written
git -C "$DEMO" -c user.email=t@t -c user.name=t commit -q -m one
printf 'line one\nline two patched\nline three stacked\n' > "$DEMO/Makefile"
printf 'created by the patch\nstacked on the created file\n' > "$DEMO/src/new.c"
git -C "$DEMO" add Makefile src/new.c
git -C "$DEMO" diff --cached -M HEAD > "$WORK/repo/patches/feeds/demo/0002-demo-stacked.patch"
git -C "$DEMO" reset -q --hard "$pin"
git -C "$DEMO" clean -qfd

# the linked feed's patch works at the tree root, the way a src-link feed does
printf 'top one changed\n' > "$WORK/tree/toplevel-file"
mkdir -p "$WORK/tree/extra"
echo linked > "$WORK/tree/extra/created"
git -C "$WORK/tree" add toplevel-file extra/created
git -C "$WORK/tree" diff --cached -M HEAD > "$WORK/repo/patches/feeds/link/0001-link.patch"
git -C "$WORK/tree" reset -q --hard
rm -rf "$WORK/tree/extra"

# the state an incremental build is met with: created file present, tracked file back
# at the pinned commit
(cd "$WORK/tree/feeds/demo" && patch -p1 -F0 -i "$WORK/repo/patches/feeds/demo/0001-demo.patch" >/dev/null)
git -C "$WORK/tree/feeds/demo" checkout -q -- .
[ -e "$WORK/tree/feeds/demo/src/new.c" ] || { echo "test: the leftover file was not set up" >&2; exit 1; }
grep -q '^line two$' "$WORK/tree/feeds/demo/Makefile" || { echo "test: the tracked file was not reset" >&2; exit 1; }

sh "$SCRIPT" "$WORK/tree" "$WORK/repo" > "$WORK/first.out" 2>&1 || {
    echo "test: the patch pass failed on a scratch tree set up as an incremental build leaves it" >&2
    sed 's/^/    /' "$WORK/first.out" >&2
    exit 1
}
grep -q 'applied feed patch: demo/0001-demo.patch' "$WORK/first.out" || {
    echo "test: the feed's first patch is not reported applied" >&2; exit 1; }
grep -q 'applied feed patch: demo/0002-demo-stacked.patch' "$WORK/first.out" || {
    echo "test: the stacked patch is not reported applied - the feed was restored between its patches" >&2
    sed 's/^/    /' "$WORK/first.out" >&2
    exit 1
}
grep -q 'line two patched' "$WORK/tree/feeds/demo/Makefile" || {
    echo "test: the tracked file is not patched" >&2; exit 1; }
grep -q 'line three stacked' "$DEMO/Makefile" || {
    echo "test: the stacked patch did not reach the tracked file" >&2; exit 1; }
[ -f "$WORK/tree/feeds/demo/src/new.c" ] || {
    echo "test: the file the patch creates is missing" >&2; exit 1; }
grep -q 'stacked on the created file' "$DEMO/src/new.c" || {
    echo "test: the stacked patch did not reach the created file" >&2; exit 1; }

# a src-link feed is patched where it points, and the tree's own untracked file stays
grep -q 'top one changed' "$WORK/tree/toplevel-file" || {
    echo "test: the linked feed's patch did not apply" >&2; exit 1; }
[ -f "$WORK/tree/extra/created" ] || {
    echo "test: the linked feed's created file is missing" >&2; exit 1; }
[ -f "$WORK/tree/rootmarker" ] || {
    echo "test: the linked feed was cleared, and that cleared the tree" >&2; exit 1; }

# running the pass again must land in the same place
sh "$SCRIPT" "$WORK/tree" "$WORK/repo" > "$WORK/second.out" 2>&1 || {
    echo "test: the second pass failed" >&2; sed 's/^/    /' "$WORK/second.out" >&2; exit 1; }
grep -q 'line three stacked' "$DEMO/Makefile" || {
    echo "test: the second pass lost the stack" >&2; exit 1; }
grep -q 'stacked on the created file' "$DEMO/src/new.c" || {
    echo "test: the second pass lost the stacked file" >&2; exit 1; }
[ -f "$WORK/tree/rootmarker" ] || {
    echo "test: the second pass cleared the linked tree" >&2; exit 1; }

# --reset leaves a feed exactly at the commit it is checked out at
sh "$SCRIPT" --reset "$WORK/tree" "$WORK/repo" > "$WORK/reset.out" 2>&1 || {
    echo "test: --reset failed" >&2; sed 's/^/    /' "$WORK/reset.out" >&2; exit 1; }
git -C "$WORK/tree/feeds/demo" -c safe.directory="$WORK/tree/feeds/demo" status --porcelain > "$WORK/reset.state"
[ -s "$WORK/reset.state" ] && {
    echo "test: --reset left the feed changed:" >&2
    sed 's/^/    /' "$WORK/reset.state" >&2
    exit 1
}
grep -q '^line two$' "$WORK/tree/feeds/demo/Makefile" || {
    echo "test: --reset did not restore the tracked file" >&2; exit 1; }
[ -e "$WORK/tree/feeds/demo/src/new.c" ] && {
    echo "test: --reset left the file the patch created" >&2; exit 1; }
[ -f "$WORK/tree/rootmarker" ] || {
    echo "test: --reset cleared the linked tree" >&2; exit 1; }

printf 'cw-apply-feed-patches-test: all tests passed\n'
