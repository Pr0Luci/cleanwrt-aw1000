#!/bin/bash
# cw-dev - local front end to the CleanWRT build, for the dev container.
#
#   cw-dev tree              clone the OpenWrt tree at the pinned tag (once)
#   cw-dev tests             what check.yml runs: shell syntax + tools/tests
#   cw-dev check             feeds, patches, pins, defconfig, seed checks; no compile
#   cw-dev build [--clean|--dirclean]
#                            full image build (incremental without a flag)
#   cw-dev collect           copy the images and checksums to $CW_OUT
#   cw-dev status            paths, tag, disk and cache sizes
#
# Paths come from the container's environment (devcontainer.json): CW_REPO,
# CW_TREE, CW_OUT. Builds log to $CW_OUT/build-<date>.log.
set -euo pipefail

REPO="${CW_REPO:-$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)}"
TREE="${CW_TREE:-$REPO/../openwrt}"
OUT="${CW_OUT:-$REPO/../out}"
TAG=$(sed -n 's/^OPENWRT_TAG="\(.*\)"$/\1/p' "$REPO/tools/cw-release-build.sh")
VER=$(sed -n 's/^CW_VERSION="\(.*\)"$/\1/p' "$REPO/tools/cw-release-build.sh")
TARGET_DIR="$TREE/bin/targets/qualcommax/ipq807x"

need_tree() {
    [ -f "$TREE/scripts/feeds" ] || { echo "No OpenWrt tree at $TREE: run 'cw-dev tree' first" >&2; exit 1; }
}

cmd_tree() {
    if [ -d "$TREE/.git" ]; then
        have=$(git -C "$TREE" describe --tags --exact-match 2>/dev/null || echo "?")
        echo "Tree exists at $TREE (tag: $have, wanted: $TAG)"
        [ "$have" = "$TAG" ] || echo "WARNING: not at $TAG; the build will refuse it. Remove $TREE and rerun." >&2
        return
    fi
    git clone --depth 1 --branch "$TAG" https://github.com/openwrt/openwrt.git "$TREE"
}

cmd_tests() {
    cd "$REPO"
    echo "== shell syntax"
    grep -rlE '^#!.*(sh|bash)' tools files | while IFS= read -r f; do
        case "$(head -1 "$f")" in *bash*) bash -n "$f" ;; *) sh -n "$f" ;; esac
    done
    for t in tools/tests/*-test.sh; do
        echo "== $t"
        sh "$t"
    done
    echo "== all tests passed"
}

run_build() {
    need_tree
    mkdir -p "$OUT"
    log="$OUT/build-$(date +%Y%m%d-%H%M%S).log"
    echo "== logging to $log"
    # The release script must run as root: it chowns the rootfs overlay to 0:0 so
    # every file on the device belongs to root (as in CI). Only the build runs as
    # root; the repo is only read, and the log and images stay yours.
    as_root=()
    [ "$(id -u)" = 0 ] || as_root=(sudo --preserve-env=CW_CHECK_ONLY,CW_MAX_IMAGE_MB,CW_CCACHE,CW_BUILD_OPT_ARTIFACTS,CW_REQUIRE_RELEASE_KEYS,FORCE_UNSAFE_CONFIGURE)
    # No terminal, as in CI: the seed has no CONFIG_HAVE_DOT_CONFIG, so OpenWrt's
    # make opens menuconfig on some steps (e.g. `make package/base-files/clean`,
    # whose output the script sends to /dev/null). In CI that fails at once and the
    # script carries on; on a terminal it waits, invisibly, for a keypress.
    "${as_root[@]}" env -u TERM "$REPO/tools/cw-release-build.sh" "$TREE" "$@" < /dev/null 2>&1 | tee "$log"
}

cmd_check() { CW_CHECK_ONLY=1 run_build; }
cmd_build() { run_build "$@"; }

cmd_collect() {
    [ -d "$TARGET_DIR" ] || { echo "No build output in $TARGET_DIR" >&2; exit 1; }
    dest="$OUT/$VER"
    mkdir -p "$dest"
    find "$TARGET_DIR" -maxdepth 1 -type f \
        \( -name '*arcadyan_aw1000*' -o -name '*.manifest' -o -name 'profiles.json' \
           -o -name 'sha256sums*' -o -name '*.buildinfo' \) -exec cp {} "$dest"/ \;
    ls -l "$dest"
    ( cd "$dest" && sha256sum ./*.bin ./*.ubi ./*.itb 2>/dev/null || true )
}

cmd_status() {
    echo "repo:    $REPO ($(git -C "$REPO" rev-parse --abbrev-ref HEAD) @ $(git -C "$REPO" rev-parse --short HEAD))"
    echo "version: $VER, OpenWrt $TAG"
    echo "tree:    $TREE $( [ -d "$TREE/.git" ] && git -C "$TREE" describe --tags 2>/dev/null || echo '(missing)')"
    echo "out:     $OUT"
    echo "cpus:    $(nproc), memory: $(free -h | awk '/Mem:/{print $2}')"
    du -sh "$TREE/dl" "$TREE/.ccache" "$TREE/build_dir" 2>/dev/null || true
    df -h "$TREE" 2>/dev/null | tail -1 || df -h "$REPO" | tail -1
}

case "${1:-}" in
    tree|tests|check|collect|status) c=$1; shift; "cmd_$c" "$@" ;;
    build) shift; cmd_build "$@" ;;
    *) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
