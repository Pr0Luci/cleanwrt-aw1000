#!/bin/sh
# cw-apply-feed-patches.sh - apply this repo's patches to the pinned feeds of an OpenWrt tree.
#
# Patches live in patches/feeds/<feed>/*.patch (applied in filename order) and are
# applied with `patch -p1` inside <tree>/feeds/<feed>. They are applied with ZERO
# fuzz: if upstream changes the code around a hunk, the patch no longer applies and
# this script FAILS, so a build can never silently ship stale or half-applied code.
# A patch that is already applied is detected and skipped (re-runnable).
#
# Usage:
#   tools/cw-apply-feed-patches.sh <openwrt-tree> [<repo-dir>]
#   tools/cw-apply-feed-patches.sh --reset <openwrt-tree> [<repo-dir>]
#       --reset restores each patched feed to its pinned (git) state, so that
#       `./scripts/feeds update` can run on a tree whose feeds were patched before.
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
