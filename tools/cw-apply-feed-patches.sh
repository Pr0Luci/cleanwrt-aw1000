#!/bin/sh
# cw-apply-feed-patches.sh - apply this repo's patches to an OpenWrt tree.
#
# Patches live in two places, both applied with `patch -p1` and ZERO fuzz:
#   patches/feeds/<feed>/*.patch  inside <tree>/feeds/<feed>, filename order
#   patches/tree/*.patch          at the tree root (package/..., include/...),
#                                 filename order - for files the tree carries itself
# If upstream changes the code around a hunk, a patch no longer applies and this
# script FAILS, so a build can never silently ship stale or half-applied code.
# A patch that is already applied is detected and skipped (re-runnable).
#
# Usage:
#   tools/cw-apply-feed-patches.sh <openwrt-tree> [<repo-dir>]
#   tools/cw-apply-feed-patches.sh --reset <openwrt-tree> [<repo-dir>]
#       --reset restores each patched feed to its pinned (git) state and
#       reverse-applies the tree patches (last first), so that
#       `./scripts/feeds update` can run on a tree patched by an earlier build.
set -eu

MODE=apply
if [ "${1:-}" = "--reset" ]; then MODE=reset; shift; fi
TREE="${1:?usage: cw-apply-feed-patches.sh [--reset] <openwrt-tree> [<repo-dir>]}"
REPO="${2:-$(cd "$(dirname "$0")/.." && pwd)}"

# enforce_modes <patch> <feed-dir>
#   GNU patch applies mode-only diffs unreliably (and the reverse-applied
#   detection can treat them as no-ops), so declared mode changes are enforced
#   directly from the patch text: pairs of '+++ b/<path>' followed by
#   'new mode <mode>'. Without this, a 0644->0755 fix silently regresses and
#   the release build's executability assert fails.
enforce_modes() {
    awk '
        /^diff --git / { path = $0; sub(/^.* b\//, "", path); next }
        /^\+\+\+ b\// { path = substr($0, 7); next }
        /^new mode / { m = $3; sub(/^100/, "", m); print m "\t" path }
    ' "$1" | while IFS="	" read -r mode path; do
        [ -n "$path" ] && [ -e "$2/$path" ] || continue
        cur=$(stat -c '%a' "$2/$path" 2>/dev/null || echo "?")
        [ "$cur" = "$mode" ] && continue
        chmod "$mode" "$2/$path"
        echo "mode enforced: $path -> $mode"
    done
}

# Tree patches. Their paths start at the tree root, so they never collide with a
# feed's. A persistent tree still carries last run's patches (and a base tree is a
# git checkout at the pinned tag, which is why they can always be reversed).
tree_patches() {
    for pf in "$REPO"/patches/tree/*.patch; do
        [ -e "$pf" ] || continue
        echo "$pf"
    done
}

apply_tree_patch() { # <patch-file>
    name=$(basename "$1")
    # -f: obey the direction given instead of asking; without it a reverse dry
    # run on an unpatched file prompts ("Ignore -R?") and reads the answer from
    # a non-tty stdin, which cannot be a reliable signal.
    if patch -p1 -R -f -F0 --dry-run -s -d "$TREE" < "$1" >/dev/null 2>&1; then
        echo "tree patch already applied: $name"
        return 0
    fi
    if ! patch -p1 -f -F0 --dry-run -s -d "$TREE" < "$1" >/dev/null 2>&1; then
        echo "ERROR: tree patch $name does not apply cleanly at $TREE." >&2
        echo "       Upstream changed the code it patches (or the tree is not at the" >&2
        echo "       pinned tag). Re-port the patch onto the new upstream." >&2
        exit 1
    fi
    patch -p1 -f -F0 --no-backup-if-mismatch -s -d "$TREE" < "$1"
    echo "applied tree patch: $name"
}

revert_tree_patch() { # <patch-file>
    # Not applied (fresh clone, or already reverted): nothing to restore.
    patch -p1 -R -f -F0 --dry-run -s -d "$TREE" < "$1" >/dev/null 2>&1 || return 0
    if ! patch -p1 -R -f -F0 --no-backup-if-mismatch -s -d "$TREE" < "$1"; then
        echo "ERROR: tree patch $(basename "$1") is recorded but does not reverse - the" >&2
        echo "       tree was edited by hand. Restore the file yourself (git checkout)." >&2
        exit 1
    fi
    echo "reverted tree patch: $(basename "$1")"
}

if [ "$MODE" = reset ]; then
    # Last applied first, so two patches over the same region reverse in order.
    tree_patches | sort -r | while IFS= read -r pf; do revert_tree_patch "$pf"; done
else
    tree_patches | while IFS= read -r pf; do apply_tree_patch "$pf"; done
fi

for pf in "$REPO"/patches/feeds/*/*.patch; do
    [ -e "$pf" ] || continue
    feed=$(basename "$(dirname "$pf")")
    dir="$TREE/feeds/$feed"
    name="$feed/$(basename "$pf")"

    if [ "$MODE" = reset ]; then
        # The feed may not exist yet on a first build - nothing to restore then.
        [ -d "$dir/.git" ] && git -C "$dir" checkout -q -- .
        continue
    fi

    [ -d "$dir" ] || { echo "ERROR: feed '$feed' (needed by $name) is not in $TREE/feeds" >&2; exit 1; }

    if patch -p1 -R -F0 --dry-run -s -d "$dir" < "$pf" >/dev/null 2>&1; then
        echo "feed patch already applied: $name"
        enforce_modes "$pf" "$dir"
        continue
    fi
    if ! patch -p1 -F0 --dry-run -s -d "$dir" < "$pf" >/dev/null 2>&1; then
        echo "ERROR: feed patch $name does not apply cleanly to the pinned feed." >&2
        echo "       Upstream changed the code it patches (or the feed pin moved)." >&2
        echo "       Re-port the patch onto the new upstream." >&2
        exit 1
    fi
    patch -p1 -F0 --no-backup-if-mismatch -s -d "$dir" < "$pf"
    enforce_modes "$pf" "$dir"
    echo "applied feed patch: $name"
done
