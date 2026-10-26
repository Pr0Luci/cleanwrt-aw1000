#!/bin/sh
# cw-release-build.sh - reproducible CleanWRT release build from this repo.
#
# Builds the release image from version-controlled inputs only: the seed
# configs/arcadyan_aw1000.seed, the files/ overlay, feeds.conf.default (every feed
# pinned to a commit), configs/local-packages.pin and patches/, applied to a clean
# OpenWrt v25.12.5 tree.
#
# Usage (from a checkout of this repo):
#   tools/cw-release-build.sh <openwrt-tree-dir> [--clean|--dirclean]
#     <openwrt-tree-dir>  a git checkout of openwrt.git at tag v25.12.5
#     --clean     rebuild all packages (keep toolchain)   ~1-2 h + step 6b
#     --dirclean  rebuild everything incl. toolchain      several h
#     (no flag)   incremental, only changed packages      minutes
#
# Environment:
#   CW_ALLOW_UNPINNED_BASE=1   proceed even if the OpenWrt tree is not at
#                              $OPENWRT_TAG (experiments only, never for a release)
#   CW_SKIP_DROP_CHECK=1       skip the seed -> defconfig package-drop check (debug only)
#   CW_CHECK_ONLY=1            config-check mode: run feeds, feed patches, local
#                              package pins, defconfig + fixups and the seed checks,
#                              then exit 0 before signing, download and compile.
#   CW_REQUIRE_RELEASE_KEYS=1  refuse to build unless <tree>/private-key.pem is the key
#                              the devices trust for the cw-opt feed
#                              (tools/cw-check-release-keys.sh). Without it a tree with
#                              no key gets a fresh one that no device trusts.
#   CW_MAX_IMAGE_MB=<n>        image size gate in MiB (default 80). The image carries
#                              qBittorrent and AdGuard Home and needs the expanded
#                              rootfs layout (the UBI check below enforces CW_UBI_LAYOUT).
#
# Build on a Linux host or in docker/Dockerfile, not on macOS.
set -eu

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TREE="${1:?usage: tools/cw-release-build.sh <openwrt-tree-dir> [--clean|--dirclean]}"
# Single image configuration. CW_SEED is only an override for experiments
# (alternate seed file); the release build always uses the default seed.
SEED="${CW_SEED:-configs/arcadyan_aw1000.seed}"
case "$SEED" in /*) ;; *) SEED="$REPO/$SEED" ;; esac
[ -f "$SEED" ] || { echo "ERROR: seed file not found: $SEED" >&2; exit 1; }
echo "== seed: $SEED =="

# Image identity - SINGLE source of truth. Bump the RC label HERE;
# the seeds carry a copy (kept readable) that must agree - asserted below, so a
# stale seed fails the build instead of shipping a mismatched banner.
CW_VERSION="25.12.5-rc1"
seed_ver=$(sed -n 's/^CONFIG_VERSION_NUMBER="\(.*\)"$/\1/p' "$SEED")
[ "$seed_ver" = "$CW_VERSION" ] || {
    echo "ERROR: $SEED has CONFIG_VERSION_NUMBER=\"$seed_ver\" but the build script says \"$CW_VERSION\" - bump both" >&2
    exit 1
}
echo "== version: $CW_VERSION =="

CLEAN="${2:-}"
OPENWRT_TAG="v25.12.5"
export FORCE_UNSAFE_CONFIGURE=1   # some host tools refuse to configure as root

[ -f "$TREE/scripts/feeds" ] || { echo "ERROR: $TREE is not an OpenWrt tree" >&2; exit 1; }
case "$CLEAN" in
    "") ;;
    --clean|--dirclean) ;;
    *) echo "ERROR: unknown option '$CLEAN' (expected --clean, --dirclean or nothing)" >&2; exit 1 ;;
esac
cd "$TREE"

# 0. Confirm the pinned OpenWrt version - HARD gate, not a warning: every feed
#    pin and the kernel version are only meaningful at $OPENWRT_TAG. A shallow
#    clone without the tag fails here too (fetch the tag first).
if ! git -C "$TREE" describe --tags --exact-match 2>/dev/null | grep -qx "$OPENWRT_TAG"; then
    if [ "${CW_ALLOW_UNPINNED_BASE:-0}" = "1" ]; then
        echo "WARN: $TREE is not checked out exactly at $OPENWRT_TAG (CW_ALLOW_UNPINNED_BASE=1 - NOT a release build)" >&2
    else
        echo "ERROR: $TREE is not checked out exactly at $OPENWRT_TAG." >&2
        echo "       Run: git -C $TREE fetch --tags && git -C $TREE checkout $OPENWRT_TAG" >&2
        echo "       (export CW_ALLOW_UNPINNED_BASE=1 to override for experiments only)" >&2
        exit 1
    fi
fi

# 1. Clean for a from-scratch build (optional).
case "$CLEAN" in
    --dirclean) echo "== make dirclean (full, incl. toolchain) =="; make dirclean ;;
    --clean)    echo "== make clean (rebuild all packages) ==";     make clean ;;
esac

# 2. Pinned feeds (all feeds pinned to commits in feeds.conf.default).
#    Copy to BOTH names: scripts/feeds prefers feeds.conf when it exists, and a
#    stale unmanaged feeds.conf would silently bypass every pin.
cp "$REPO/feeds.conf.default" feeds.conf.default
cp "$REPO/feeds.conf.default" feeds.conf
# In-repo vendored feed (feeds-src/): wired in as a `src-link` entry, so
# scripts/feeds symlinks feeds/cwfeed to the vendored directory (no clone, no
# commit pin: the vendored content is the repo itself).
# It is inserted BEFORE the luci feed, not appended: names resolve first-match-wins
# and the upstream luci feed has its own luci-app-adguardhome whose +adguardhome
# dependency pulls the ~9 MiB Go binary into the image. Our vendored copy (with
# that dependency dropped) must win the name, or the image grows from 94 to 103 MiB.
# The link target is a stable directory inside the tree, not the checkout. With a
# fresh checkout every run has new file mtimes, and OpenWrt's ".prepared" stamp is
# derived from the package's files, so every cwfeed package (qt6base host and
# target, qbittorrent, ...) was rebuilt each time, about 2.5 h. rsync --checksum
# copies only files whose content changed and leaves the rest, and their mtimes,
# alone, so an unchanged package stays built.
CWFEED_DIR="$PWD/cwfeed-src"
mkdir -p "$CWFEED_DIR"
rsync -rlp --checksum --delete "$REPO/feeds-src/cwfeed/" "$CWFEED_DIR/"
sed -i "/^src-git luci /i src-link cwfeed $CWFEED_DIR" feeds.conf
# Prune every orphaned feed the tree still carries from an older flow
# feeds.conf is the single source of the feed set. A feed dir left behind from a
# pruned entry keeps its package/feeds/<name> symlinks, and `feeds install -a`
# never re-installs a package that is already installed under another feed's
# symlinks, so an incremental build would compile the stale source. `feeds
# install -a` then resolves every pruned package from a surviving feed.
feednames=$(grep -E '^src-(git|link|clone)[[:space:]]' feeds.conf | awk '{print $2}')
# staging_dir/packages/<arch>/ symlinks into a removed output dir would dangle in the index.
drop_staging_links() { # <feed name>
    for st in staging_dir/packages/*/*; do
        [ -L "$st" ] || continue
        case "$(readlink "$st")" in *"bin/packages/"*"/$1/"*) rm -f "$st" ;; esac
    done
}
for fdir in feeds/*/; do
    name=$(basename "$fdir")
    echo "$feednames" | grep -qx "$name" && continue
    echo "== prune orphaned feed: feeds/$name (not in feeds.conf) =="
    rm -rf "feeds/$name" "feeds/$name.index" "feeds/$name.targetindex" "feeds/$name.tmp"
    rm -rf "package/feeds/$name"
    # Also drop everything that feed ever output: stale apks in
    # bin/packages/<arch>/<name>/ are still indexed by make package/index, so the
    # flat index would keep resolving packages that were removed on purpose.
    for out in bin/packages/*/"$name"; do
        [ -e "$out" ] && { echo "== prune orphaned outputs: $out =="; rm -rf "$out"; }
    done
    drop_staging_links "$name"
done
# That loop only finds an orphan while its feeds/<name> dir still exists. An OUTPUT
# dir whose feed dir an earlier run already pruned stays behind and keeps feeding the
# flat index and cw-publish-feed.sh's orphan guard (an old bin/packages/<arch>/qbittorrent/
# held two qbittorrent releases, so the feed kept serving the old one). Every
# bin/packages/<arch>/<dir> must be a configured feed; `base` is the core package
# output, not a feed.
for out in bin/packages/*/*/; do
    [ -d "$out" ] || continue
    name=$(basename "$out")
    [ "$name" = base ] && continue
    echo "$feednames" | grep -qx "$name" && continue
    echo "== prune orphaned outputs: $out (not a feed in feeds.conf) =="
    rm -rf "$out"
    drop_staging_links "$name"
done
# scripts/feeds never moves an EXISTING git feed to a new pin ("in case git hash has been
# provided don't update the feed"), so a bumped pin was silently ignored in a persistent tree
#. Drop every pinned git feed whose checkout is not the pinned commit, so
# `feeds update` clones it again at the pin. Patches are applied to a clean checkout later.
grep -E '^src-git[[:space:]]' feeds.conf | while read -r _ pname purl _; do
    ppin=${purl##*^}
    [ "$ppin" != "$purl" ] || continue
    [ -d "feeds/$pname/.git" ] || continue
    phead=$(git -C "feeds/$pname" rev-parse HEAD 2>/dev/null || true)
    [ "$phead" = "$ppin" ] && continue
    echo "== feed $pname is at ${phead:-unknown}, pinned $ppin: clone again =="
    rm -rf "feeds/$pname" "feeds/$pname.index" "feeds/$pname.targetindex" "feeds/$pname.tmp" "package/feeds/$pname"
done
# Restore any feed we patched on a previous run, so `feeds update` sees a clean checkout.
sh "$REPO/tools/cw-apply-feed-patches.sh" --reset "$PWD" "$REPO"
./scripts/feeds update -a
# passwall_packages is the first feed (feeds.conf.default), so a clean
# `feeds install -a` already prefers its cores. A persistent tree still carries the
# symlinks of an earlier install (package/feeds/packages/xray-core -> the official
# 26.3.27), and `feeds install` never replaces an installed package, so drop every
# symlink another feed holds for a name passwall_packages provides, and the stale
# apks that copy built, before installing. Same reasoning as the orphan prune above.
for pdir in feeds/passwall_packages/*/; do
    [ -f "${pdir}Makefile" ] || continue
    pname=$(basename "$pdir")
    for link in package/feeds/*/"$pname"; do
        [ -L "$link" ] || continue
        case "$link" in package/feeds/passwall_packages/*) continue ;; esac
        echo "== passwall_packages provides $pname: drop $link =="
        rm -f "$link"
        for old_apk in bin/packages/*/*/"$pname"-[0-9]*.apk; do
            case "$old_apk" in */passwall_packages/*) continue ;; esac
            [ -e "$old_apk" ] && { echo "== drop stale $old_apk =="; rm -f "$old_apk"; }
        done
    done
done
./scripts/feeds install -a

# Passwall's LuCI apps refuse to run an Xray older than the version they write into
# every config (util_xray.lua: xray_min_version). Fail here, in the CI
# config check as well as in the release build, instead of shipping an image whose
# Passwall cannot start a node.
xray_mk=$(readlink -f package/feeds/passwall_packages/xray-core 2>/dev/null)/Makefile
[ -f "$xray_mk" ] || { echo "ERROR: xray-core is not installed from the passwall_packages feed" >&2; exit 1; }
xray_ver=$(sed -n 's/^PKG_VERSION:=//p' "$xray_mk" | head -1)
xray_need=$(sed -n 's/.*xray_min_version *= *"\([0-9.]*\)".*/\1/p' feeds/passwall*/luci-app-passwall*/luasrc/passwall*/util_xray.lua | sort -V | tail -1)
[ -n "$xray_need" ] || xray_need=0
[ "$(printf '%s\n%s\n' "$xray_need" "$xray_ver" | sort -V | head -1)" = "$xray_need" ] || {
    echo "ERROR: xray-core $xray_ver is older than the $xray_need that Passwall requires" >&2
    exit 1
}
echo "== xray-core $xray_ver (Passwall requires >= $xray_need) =="

# 2a. Our patches to the pinned feeds (patches/feeds/<feed>/*.patch), zero fuzz -
#     fails the build if upstream drifted under a patch. Replaces the former
#     whole-file 3ginfo.sh overlay.
sh "$REPO/tools/cw-apply-feed-patches.sh" "$PWD" "$REPO"

# 2a-bis. Invalidate stale prebuilt packages for every patched feed. OpenWrt
#     does not re-run Build/Prepare when feed CONTENT changes at the same pin,
#     so an ipk built before a patch transition would be reused verbatim by an
#     incremental build - shipping the unpatched file while everything prints
#     success. Remove the ipks and clean the package build dir (no-op cost).
#     Skipped in config-check mode: that mode never compiles, and CI runs it on
#     a fresh clone with no build state, so each `make .../clean` (a full package re-scan per
#     call) was 15-25 minutes of no-ops.
if [ "${CW_CHECK_ONLY:-0}" != "1" ]; then
    for f in "$REPO"/patches/feeds/*/; do
        feed=$(basename "$f")
        for mk in "feeds/$feed"/*/Makefile; do
            [ -f "$mk" ] || continue
            pkg=$(dirname "$mk" | xargs basename)
            rm -f bin/packages/*/*/"$pkg"*.ipk 2>/dev/null || true
            make "package/feeds/$feed/$pkg/clean" >/dev/null 2>&1 || true
            echo "== invalidated stale build state for feeds/$feed/$pkg =="
        done
    done

    #     The loop above only sees top-level feed dirs. Feeds with nested package dirs
    #     (qmodem: application/quectel_CM_5G_M, luci/luci-app-qmodem) would keep a stale
    #     build, so also invalidate every package a patch actually touches: walk up from
    #     each patched path to the nearest Makefile.
    for pf in "$REPO"/patches/feeds/*/*.patch; do
        [ -f "$pf" ] || continue
        feed=$(basename "$(dirname "$pf")")
        sed -n 's,^+++ [ab]/\([^[:space:]]*\).*,\1,p' "$pf" | while IFS= read -r rel; do
            d=$(dirname "feeds/$feed/$rel")
            # the package Makefile includes package.mk (a src/Makefile does not)
            while [ "$d" != "feeds/$feed" ] && [ "$d" != "." ] && ! { [ -f "$d/Makefile" ] && grep -q -e 'package\.mk' -e 'BuildPackage' "$d/Makefile"; }; do d=$(dirname "$d"); done
            [ -f "$d/Makefile" ] && grep -q -e 'package\.mk' -e 'BuildPackage' "$d/Makefile" || continue
            echo "$d"
        done | sort -u | while IFS= read -r d; do
            pkg=$(basename "$d")
            name=$(sed -n 's/^PKG_NAME[[:space:]]*:\{0,1\}=[[:space:]]*//p' "$d/Makefile" | head -1)
            rm -f bin/packages/*/*/"${name:-$pkg}"[-_]*.apk bin/packages/*/*/"${name:-$pkg}"[-_]*.ipk 2>/dev/null || true
            make "package/feeds/$feed/$pkg/clean" >/dev/null 2>&1 || true
            echo "== invalidated (patched path) feeds/$feed/${d#feeds/$feed/} =="
        done
    done
fi

# 2b. Out-of-feed packages: single-package repos (Makefile at the repo root) that
#     OpenWrt cannot index as a feed are cloned into package/<name> at a pinned
#     commit (configs/local-packages.pin) and the commit is verified.
while read -r name url sha extra; do
    case "$name" in ''|'#'*) continue ;; esac
    [ -z "$extra" ] || { echo "ERROR: malformed line in configs/local-packages.pin for '$name' (unexpected field '$extra')" >&2; exit 1; }
    case "$url" in
        http://*|https://*|git://*|ssh://*) ;;
        *) echo "ERROR: unrecognized pin URL for $name: $url" >&2; exit 1 ;;
    esac
    rm -rf "package/$name"
    src=$(mktemp -d)
    # A network blip must not cost a whole release job: fail a stalled transfer
    # after 60 s and retry, up to three attempts.
    cloned=0
    for attempt in 1 2 3; do
        rm -rf "$src/repo"
        if git -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=60 clone -q "$url" "$src/repo"; then cloned=1; break; fi
        echo "WARN: clone of $url failed (attempt $attempt/3)" >&2
        [ "$attempt" -lt 3 ] && sleep $((attempt * ${CW_GIT_RETRY_SLEEP:-20}))
    done
    [ "$cloned" = 1 ] || { echo "ERROR: could not clone $url for $name after 3 attempts" >&2; exit 1; }
    git -C "$src/repo" checkout -q --detach "$sha"
    got=$(git -C "$src/repo" rev-parse HEAD)
    [ "$got" = "$sha" ] || { echo "ERROR: package/$name is at $got, pin says $sha" >&2; exit 1; }
    # Feed-compatible repos keep the package in a <name>/ subdirectory (a root
    # Makefile breaks the feeds indexer); legacy single-package repos have the
    # Makefile at the root. Install whichever layout the pinned commit has.
    if [ -f "$src/repo/$name/Makefile" ]; then
        cp -a "$src/repo/$name" "package/$name"
    elif [ -f "$src/repo/Makefile" ]; then
        cp -a "$src/repo" "package/$name"; rm -rf "package/$name/.git"
        # Deterministic version for luci.mk apps without an upstream PKG_VERSION
        # (homeproxy): with .git stripped, luci.mk's findrev falls back to file
        # mtimes and the apk version would drift per build. Pin it to the date of the
        # pinned commit (digits only): apk accepts only digit segments in the numeric
        # part of a version, a short sha like 98a6ad9e is rejected at packaging.
        grep -q '^PKG_VERSION' "package/$name/Makefile" || {
            vdate=$(git -C "$src/repo" show -s --format=%cd --date=short "$sha" | tr -d '-')
            sed -i "s|^\(PKG_NAME:=.*\)|&\nPKG_VERSION:=${vdate}|" "package/$name/Makefile"
        }
    else
        echo "ERROR: pinned $name has no Makefile at <root> or <root>/$name/" >&2; exit 1
    fi
    rm -rf "$src"
    [ -f "package/$name/Makefile" ] || { echo "ERROR: package/$name/Makefile missing after install" >&2; exit 1; }
    echo "== local package $name @ $sha =="
done < "$REPO/configs/local-packages.pin"

# 3. Seed -> .config and the files/ rootfs overlay, straight from the repo.
#    The staged banner gets a per-build version line, so every boot shows what is
#    running without logging in.
cp "$SEED" .config
rm -rf files
cp -a "$REPO/files" files
# The user-visible version is exactly "<dist> <version>".
# Stock base-files appends the version code to DISTRIB_DESCRIPTION and
# OPENWRT_RELEASE; with an empty VERSION_CODE that is the OpenWrt revision, so drop
# the %C from the two templates for this build and restore them on exit (the next
# run restores them too). base-files is cleaned so an
# incremental build cannot reuse a copy built from the stock templates.
CW_VERSION_TEMPLATES="package/base-files/files/etc/openwrt_release package/base-files/files/usr/lib/os-release"
cw_restore_version_templates() {
    # shellcheck disable=SC2086
    git checkout -q HEAD -- $CW_VERSION_TEMPLATES 2>/dev/null || true
}
trap cw_restore_version_templates EXIT
cw_restore_version_templates
for t in $CW_VERSION_TEMPLATES; do
    sed -i "s/ %C\([\"']\)/\1/" "$t"
    if grep -q '%C' "$t"; then
        echo "ERROR: $t still contains %C after the edit - the version label would carry a build code" >&2
        exit 1
    fi
done
make package/base-files/clean >/dev/null 2>&1 || true
echo "== version templates: no build code in DISTRIB_DESCRIPTION / OPENWRT_RELEASE =="
printf '\n CleanWRT %s\n' "$CW_VERSION" >> files/etc/banner
# rcS silently skips an init script that is not executable (a 0644 file shipped
# once shipped an installer that could never run).
for f in files/etc/init.d/*; do
    [ -f "$f" ] || continue
    [ -x "$f" ] || { echo "ERROR: $f is not executable (mode 0755 required, rcS skips it silently)" >&2; exit 1; }
    # rc.common switches to procd mode on any NON-EMPTY USE_PROCD (even "0"), replacing
    # start() - a classic non-procd script must leave it unset (or use 1 with start_service).
    procd_line=$(grep -E '^[[:space:]]*(export[[:space:]]+)?USE_PROCD=' "$f" | head -1 || true)
    if [ -n "$procd_line" ]; then
        procd_val=$(printf '%s' "$procd_line" | sed -E "s/^[[:space:]]*(export[[:space:]]+)?USE_PROCD=//; s/[[:space:]#].*//; s/[\"']//g")
        if [ -n "$procd_val" ] && [ "$procd_val" != 1 ]; then
            echo "ERROR: $f sets USE_PROCD=$procd_val; rc.common treats any non-empty value as procd mode and ignores start() - leave it unset or use 1" >&2
            exit 1
        fi
    fi
    # Opposite polarity: start_service() only runs in procd mode. Without USE_PROCD=1 and
    # without an own start(), the script is dead code (rc.common's stub start() returns 0).
    if grep -qE '^start_service[[:space:]]*\(\)' "$f" \
       && ! grep -qE '^[[:space:]]*(export[[:space:]]+)?USE_PROCD=1([[:space:]]|$)' "$f" \
       && ! grep -qE '^start[[:space:]]*\(\)' "$f"; then
        echo "ERROR: $f defines start_service() but neither sets USE_PROCD=1 nor defines start() - it would never run" >&2
        exit 1
    fi
done

# 4. defconfig + MANDATORY post-defconfig fixups (make defconfig undoes these
#    regardless of the seed).
make defconfig
# enable(): unlike a blind append, first flip the "# CONFIG_X is not set" line
# kconfig already wrote, so .config never holds both states of one symbol.
cfg_enable() {
    if ! grep -qx "$1" .config; then
        sym="${1%%=*}"
        sed -i "s|^# ${sym} is not set$|$1|" .config
        grep -qx "$1" .config || echo "$1" >> .config
    fi
}
# (a) CleanWRT branding. The seed carries CONFIG_IMAGEOPT=y, so defconfig keeps
#     VERSIONOPT and the VERSION_* identity; these enables are
#     no-ops for that seed and stay as a guard for alternative CW_SEED seeds.
cfg_enable 'CONFIG_IMAGEOPT=y'
cfg_enable 'CONFIG_VERSIONOPT=y'
cfg_enable 'CONFIG_VERSION_FILENAMES=y'
cfg_enable 'CONFIG_VERSION_DIST="CleanWRT"'
# RC label comes from CW_VERSION (top of this script).
# Kconfig string symbols MUST be quoted; cfg_set also removes any earlier
# assignment / "is not set" line so exactly one definition remains.
cfg_set() {
    grep -v -e "^CONFIG_$1=" -e "^# CONFIG_$1 is not set\$" .config > .config.cw-new || true
    mv .config.cw-new .config
    echo "CONFIG_$1=\"$2\"" >> .config
}
cfg_set VERSION_NUMBER "$CW_VERSION"
# No build date in the label: VERSION_CODE stays empty,
# so version.mk falls back to the OpenWrt revision (rNNNNN-hash) and the image
# reports "CleanWRT <version> <revision>" like stock OpenWrt does.
cfg_set VERSION_CODE ""
cfg_enable 'CONFIG_VERSION_PRODUCT="CleanWRT AW1000 5G Router"'
cfg_enable 'CONFIG_VERSION_HWREV="v1"'
cfg_enable 'CONFIG_VERSION_MANUFACTURER="CleanWRT"'
# (d) public identity: os-release points at the project page.
cfg_enable 'CONFIG_VERSION_HOME_URL="https://github.com/Pr0Luci/cleanwrt-aw1000"'
cfg_enable 'CONFIG_VERSION_BUG_URL="https://github.com/Pr0Luci/cleanwrt-aw1000/issues"'
cfg_enable 'CONFIG_VERSION_SUPPORT_URL="https://github.com/Pr0Luci/cleanwrt-aw1000/issues"'
# Optional compiler cache for CI runs (CW_CCACHE=1). Off by default; it does not change
# what is built, only how fast a repeated build is. CONFIG_CCACHE needs CONFIG_DEVEL.
if [ "${CW_CCACHE:-0}" = "1" ]; then
    cfg_enable 'CONFIG_DEVEL=y'
    cfg_enable 'CONFIG_CCACHE=y'
fi
# (b) transitive deps a minimal seed does not pull through defconfig.
cfg_enable 'CONFIG_PACKAGE_libiwinfo=y'
cfg_enable 'CONFIG_PACKAGE_luci-theme-bootstrap=y'
cfg_enable 'CONFIG_PACKAGE_kmod-qmi_wwan_q=y'
cfg_enable 'CONFIG_PACKAGE_kmod-qmi_wwan_f=y'
cfg_enable 'CONFIG_PACKAGE_kmod-qmi_wwan_s=y'
# (c) upstream default-y packages that fail to build - force them off.
# Reusable: EVERY make defconfig in this script must be followed by this pass -
# defconfig re-enables default-y symbols (e.g. ruby's RUBY_ENABLE_YJIT, which
# drags the rust host toolchain into the openclash closureb).
disable_broken_toggles() {
for s in \
    RUBY_ENABLE_YJIT \
    PACKAGE_luci-app-passwall2_INCLUDE_Shadowsocks_Rust_Client \
    PACKAGE_luci-app-passwall2_INCLUDE_ShadowsocksR_Libev_Client \
    PACKAGE_luci-app-passwall2_INCLUDE_Simple_Obfs \
    PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client \
    PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Client \
    PACKAGE_luci-app-passwall_INCLUDE_Simple_Obfs \
    PACKAGE_shadowsocksr-libev-ssr-local \
    PACKAGE_shadowsocksr-libev-ssr-redir \
    PACKAGE_simple-obfs-client \
    PACKAGE_shadowsocks-rust-sslocal \
    PACKAGE_shadow-tls ; do
    sed -i "s|^CONFIG_${s}=y|# CONFIG_${s} is not set|" .config
done
}
disable_broken_toggles
# NB: do NOT run `make defconfig` again here - it re-enables the default-y
# toggles disabled above (any later defconfig must be followed by
# disable_broken_toggles, as the opt-artifact pass does). Branding is no longer
# the reason: with CONFIG_IMAGEOPT=y, defconfig keeps VERSIONOPT and VERSION_*
#. The single defconfig above already expanded deps; the fixups
# must be the LAST edit before `make`.

# 4b. The identity symbols must each be defined exactly once, quoted.
for sym in VERSION_NUMBER VERSION_CODE; do
    [ "$(grep -c "^CONFIG_${sym}=\"" .config)" = 1 ] && [ "$(grep -c "^CONFIG_${sym}=" .config)" = 1 ] || {
        echo "ERROR: CONFIG_${sym} is not defined exactly once as a quoted string in .config" >&2
        grep -n "CONFIG_${sym}" .config >&2 || true
        exit 1
    }
done

# 5. Sanity-check the intended set survived defconfig. Catch-all first: every
#    explicit CONFIG_*=y in the seed (packages AND other symbols such as
#    DEVEL-gated build options) must still be =y afterwards
#    (defconfig silently drops symbols whose deps it cannot resolve).
# benign defconfig substitutions (package -> variant that provides it):
# defconfig prefers the json variant of nftables and busybox's uclient-fetch
# over the standalone wget.
variant_present() {
    case "$1" in
        nftables) grep -qx "CONFIG_PACKAGE_nftables-json=y" .config ;;
        wget)     grep -qx "CONFIG_PACKAGE_uclient-fetch=y" .config ;;
        *)        return 1 ;;
    esac
}

if [ "${CW_SKIP_DROP_CHECK:-0}" != "1" ]; then
    dropped=0
    variants=""
    while IFS= read -r line; do
        case "$line" in CONFIG_[A-Za-z0-9_]*=y) ;; *) continue ;; esac
        if ! grep -qx "$line" .config; then
            pkg=""
            case "$line" in CONFIG_PACKAGE_*) pkg="${line#CONFIG_PACKAGE_}"; pkg="${pkg%%=*}" ;; esac
            if [ -n "$pkg" ] && variant_present "$pkg"; then
                variants="$variants $pkg"
            else
                echo "ERROR: seed option dropped by defconfig: $line" >&2
                dropped=1
            fi
        fi
    done < "$SEED"
    [ -n "$variants" ] && echo "NOTE: benign variant substitutions by defconfig:$variants (the variant package is present)"
    [ "$dropped" = 0 ] || { echo "ERROR: seed options were silently dropped - fix the seed deps / missing gate symbol, or export CW_SKIP_DROP_CHECK=1 to debug" >&2; exit 1; }
fi
#    Named must-haves (belt-and-suspenders; also covers script-added options).
#    A package the seed does not select is SKIPPED, not failed (an experimental
#    seed via CW_SEED may omit opt-in packages).
for p in luci luci-mod-admin-full luci-theme-bootstrap luci-theme-apex libiwinfo rpcd-mod-iwinfo \
         luci-app-passwall2 luci-app-qmodem qmodem kmod-qmi_wwan_q \
         minidlna samba4-server syncthing \
         luci-app-qmodem-ttlfw4 luci-app-tailscale-community luci-app-cw-led \
         luci-app-3ginfo-lite bash ttyd ; do
    grep -qx "CONFIG_PACKAGE_${p}=y" "$SEED" || continue   # not selected by this seed
    grep -qx "CONFIG_PACKAGE_${p}=y" .config || { echo "ERROR: ${p} dropped from .config" >&2; exit 1; }
done

# Config-check mode: everything above is the release logic that
# decides whether the seed/feeds/patches compose. CI stops here.
if [ "${CW_CHECK_ONLY:-0}" = "1" ]; then
    echo "== CW_CHECK_ONLY=1: feeds, patches, local pins, defconfig and seed checks passed ($SEED) - not building =="
    exit 0
fi

# 5b. Release signing: if a signing keypair exists in
#     keys-release/ (managed by tools/cw-sign-keys.sh), stage it at the tree
#     root - the OpenWrt build then embeds a usign signature into every image
#     via fwtool. No keys = unsigned build (local test builds).
if [ -f "$REPO/keys-release/key-build" ]; then
    sh "$REPO/tools/cw-sign-keys.sh" --install "$PWD"
fi

# 5c. Feed key continuity: the cw-opt feed index is signed with
#     private-key.pem from this tree, and OpenWrt creates a new one during the
#     build if none exists. Checked before `make` so a release can never be
#     signed with a key the devices do not trust.
if [ "${CW_REQUIRE_RELEASE_KEYS:-0}" = "1" ]; then
    sh "$REPO/tools/cw-check-release-keys.sh" "$PWD"
fi

# 6. Download every distfile first (hash-verified, fails in minutes not hours),
#    then build.
echo "=== CW RELEASE BUILD START $(date -u) (clean='${CLEAN:-incremental}') ==="
# Every artifact in the target output dir must come from THIS build:
# remove the previous images, manifests, buildinfo, checksums and provenance
# bundle in every mode (an incremental build would otherwise leave them for
# the release upload, and sha256sums.cw would hash them). Subdirectories
# stay: packages/ holds the target apks the image is assembled from (OpenWrt
# rules.mk PACKAGE_DIR, package/Makefile).
OUT_DIR=bin/targets/qualcommax/ipq807x
if [ -d "$OUT_DIR" ]; then
    find "$OUT_DIR" -maxdepth 1 -type f -exec rm -f {} + ||
        { echo "ERROR: cannot clear previous artifacts in $OUT_DIR" >&2; exit 1; }
    rm -rf "$OUT_DIR/cw-release-provenance" ||
        { echo "ERROR: cannot remove the previous $OUT_DIR/cw-release-provenance" >&2; exit 1; }
fi
make download -j"$(nproc)"
rc=0
make -j"$(nproc)" || rc=$?
echo "-- world rc=$rc --"
if [ "$rc" -ne 0 ]; then
    # The parallel run hides the real error ("re-run with -j1 V=s"). Everything already built is
    # reused, so a verbose single-job pass is quick and prints the cause into the build log.
    echo "== world failed: verbose single-job pass for the cause =="
    make -j1 V=s 2>&1 | tail -n 120 || true
fi

# 6b. Opt-in artifacts for the cw-opt binary feed: qBittorrent is
#     NOT in the image (Qt6 stack), but the RC build compiles it anyway so
#     bin/packages/aarch64_cortex-a53/ becomes a ready-to-publish signed apk
#     repository. Publishing that directory (tools/cw-publish-feed.sh) must happen
#     before an image carrying cw-opt.list is flashed anywhere: a dead feed entry
#     breaks apk update. The first build compiles qt6base: budget +1-2 h.
if [ "${CW_BUILD_OPT_ARTIFACTS:-1}" = "1" ]; then
    echo "== opt-in artifacts: compiling the qBittorrent stack + OpenClash + AdGuardHome (none in the image) =="
    cp .config .config.cw-image
    cfg_enable 'CONFIG_PACKAGE_qbittorrent=y'
    cfg_enable 'CONFIG_PACKAGE_luci-app-qbittorrent=y'
    # On-demand set: OpenClash (own feed) and AdGuardHome (official
    # packages feed). Neither is seeded; both stay out of the image and land in
    # the published cw-opt apk repo for anyone who wants them later. Runtime
    # deps (ruby/ruby-yaml, libtorrent-rasterbar, krb5-libs…) are pulled into
    # the same published set by the closure loop below - the
    # official release repos do NOT carry them.
    cfg_enable 'CONFIG_PACKAGE_luci-app-openclash=y'
    cfg_enable 'CONFIG_PACKAGE_adguardhome=y'
    make defconfig >/dev/null
    disable_broken_toggles
    if make package/qbittorrent/compile package/luci-app-qbittorrent/compile \
            package/luci-app-openclash/compile package/adguardhome/compile; then
        # An apk directory compiled outside the world build gets no signed index. `make package/index` merges every bin/packages/ dir into
        # one flat signed repository (staging_dir/packages/qualcommax/),
        # packages.adb signed with the tree's openssl apk key (private-key.pem -
        # the device trusts it via the shipped /etc/apk/keys/public-key.pem; NOT
        # the 5b keys-release usign keypair, which signs images only).
        echo "OPT_ARTIFACTS_COMPILE_OK - indexing (signed)"
        make package/index || { echo "WARNING: package/index failed - the cw-opt feed must NOT be published until re-run" >&2; }

        # On-demand closure: the official 25.12.5 release repos are
        # sparse (no libtorrent-rasterbar/krb5-libs/ruby*), so the published set
        # must carry its FULL dependency closure. Drive the device's own solver
        # (apk add --simulate)
        # against the official repo set + the flat local index, and compile
        # anything unresolved until the set closes.
        APKBIN="$PWD/staging_dir/host/bin/apk"
        unresolved=""
        if [ -x "$APKBIN" ]; then
            solve_root=$(mktemp -d)
            cp -a build_dir/target-*/root-*/ "$solve_root"/root
            { sed 's/^#.*//;/^$/d' "$REPO/files/etc/apk/repositories.d/"*.list
              printf 'file://%s/staging_dir/packages/qualcommax/packages.adb\n' "$PWD"
            } > "$solve_root"/root/etc/apk/repositories
            for iter in 1 2 3 4 5 6 7 8; do
                unresolved=$("$APKBIN" --arch aarch64_cortex-a53 --no-cache \
                    --root "$solve_root"/root --allow-untrusted \
                    add -s qbittorrent luci-app-qbittorrent luci-app-openclash adguardhome 2>&1 \
                    | grep -oE '^  [a-zA-Z0-9._-]+ \(no such package\)' | sed 's/ (no such package)//' )
                unresolved=$(echo "$unresolved" | tr '\n' ' ' | sed 's/ *$//')
                [ -z "$unresolved" ] && break
                echo "== closure: resolving $unresolved (iteration $iter) =="
                for m in $unresolved; do cfg_enable "CONFIG_PACKAGE_${m}=y"; done
                make defconfig >/dev/null
                disable_broken_toggles
                make -j"$(nproc)" || break
                make package/index >/dev/null 2>&1 || true
            done
            if [ -z "$unresolved" ]; then
                echo "OPT_CLOSURE_OK - the on-demand set resolves completely against official + cw-opt"
                # 6b freshness assert: an orphan OUTPUT dir left by
                # an older flow is still indexed by make package/index, and the
                # solver would then happily resolve it (an old qbittorrent release
                # would shadow the fixed one). Every
                # resolved opt-set version must exist as an apk file under the
                # surviving feeds' outputs.
                resolved=$("$APKBIN" --arch aarch64_cortex-a53 --no-cache \
                    --root "$solve_root"/root --allow-untrusted \
                    add -s qbittorrent luci-app-qbittorrent luci-app-openclash adguardhome 2>&1 \
                    | grep -oE '^  [a-zA-Z0-9._~-]+-[0-9][^([ ]*' | sed 's/^  *//; s/\[.*$//' | sort -u)
                stale=""
                for tok in $resolved; do
                    case "$tok" in
                        qbittorrent-*|luci-app-qbittorrent-*|luci-app-openclash-*|adguardhome-*) ;;
                        *) continue ;;
                    esac
                    [ -n "$(find bin/packages/aarch64_cortex-a53 -name "$tok.apk" -print -quit)" ] || stale="$stale $tok"
                done
                if [ -n "$stale" ]; then
                    echo "ERROR: stale opt-set resolution$stale - the flat index still carries versions the surviving feeds do not build; do not publish" >&2
                    rc=1
                fi
                rm -rf "$solve_root"
            else
                echo "WARNING: on-demand set STILL unresolved: $unresolved - do not publish until closed" >&2
            fi
        else
            echo "WARNING: host apk missing - closure not verified; do not publish blind" >&2
        fi
        if [ "$rc" = 0 ]; then
            echo "OPT_ARTIFACTS_OK bin/packages/aarch64_cortex-a53/ (publish to the openwrt-aw1000-feed pages branch)"
        else
            echo "OPT_ARTIFACTS_FAILED - do not publish the cw-opt feed" >&2
        fi
    else
        echo "WARNING: opt-in artifacts failed to compile - the IMAGE above is unaffected," >&2
        echo "         but the cw-opt binary feed was not refreshed." >&2
    fi
    mv .config.cw-image .config
fi

# 7. Post-build integrity asserts + provenance bundle.
BIN=""
if [ "$rc" = 0 ]; then
    # The CEREG patch MUST be in the built copy of 3ginfo.sh, executable: guards
    # against any future silent staleness of the patched feed package.
    SH_LIST=$(find build_dir -path '*luci-app-3ginfo-lite*' -path '*root/usr/share/3ginfo-lite/3ginfo.sh' 2>/dev/null || true)
    [ -n "$SH_LIST" ] || { echo "ERROR: built 3ginfo.sh not found in build_dir" >&2; rc=1; }
    for f in $SH_LIST; do
        # 'CEREG_STAT=' is introduced by our patch ONLY - upstream already
        # contains the word CEREG (TAC extraction), so grepping for that would
        # false-pass on a stale unpatched copy.
        grep -q 'CEREG_STAT=' "$f" || { echo "ERROR: $f is NOT patched (no CEREG_STAT= handler) - stale build state" >&2; rc=1; }
        [ -x "$f" ] || { echo "ERROR: $f is not executable (mode fix lost)" >&2; rc=1; }
    done

    OUT=bin/targets/qualcommax/ipq807x
    BIN=$(find "$OUT" -maxdepth 1 -name '*-squashfs-sysupgrade.bin' 2>/dev/null | head -1)
    if [ -n "$BIN" ]; then
        PROV="$OUT/cw-release-provenance"
        mkdir -p "$PROV"
        cp .config "$PROV/config.full"
        cp "$SEED" "$PROV/config.seed"
        cp "$REPO/feeds.conf.default" "$PROV/feeds.conf.default"
        [ ! -f "$REPO/configs/local-packages.pin" ] || cp "$REPO/configs/local-packages.pin" "$PROV/local-packages.pin"
        # SBOM + release metadata straight from the OpenWrt build outputs.
        for meta in "$OUT"/*.manifest "$OUT"/version.buildinfo "$OUT"/feeds.buildinfo "$OUT"/sha256sums; do
            [ -f "$meta" ] && cp "$meta" "$PROV/"
        done
        # Image size gate: the AW1000 rootfs partition is ~100 MiB; releasing
        # near the ceiling leaves no keep-settings overlay or growth room.
        max_mb="${CW_MAX_IMAGE_MB:-80}"
        actual_mb=$(( ($(wc -c < "$BIN") + 1048575) / 1048576 ))
        echo "IMAGE_SIZE ${actual_mb} MiB (gate ${max_mb} MiB)"
        [ "$actual_mb" -le "$max_mb" ] || {
            echo "ERROR: image is ${actual_mb} MiB, over the ${max_mb} MiB gate." >&2
            echo "       Slim the package set or export CW_MAX_IMAGE_MB=<n> knowingly." >&2
            rc=1
        }
        # UBI fit. The size gate above measures the sysupgrade file, but what must fit
        # the rootfs MTD is the UBI volumes: kernel + rootfs + rootfs_data (minimum 5 PEBs in the
        # ubinize layout) = factory.ubi PEBs - 2 (layout volume) + 5. Capacity of an MTD of N PEBs
        # = N - 2 (layout) - bad_peb_limit - 2 (wear leveling, EBA); bad_peb_limit is 20/1024 of the
        # WHOLE 1 GiB chip (4096 PEBs) = 80, whatever the partition size (UBI build.c, CONFIG_MTD_UBI_
        # BEB_LIMIT=20). Verified twice on the router: stock mtd18 (400 PEBs) holds volumes of
        # 24+177+115 = 316 = 400-2-80-2, and the 2804-PEB rootfs: 2799 = 2720+2+75+1+1.
        # -> stock 100 MiB layout: 316; expanded 701 MiB layout: 2804-2-80-2 = 2720.
        ubi_img=$(ls "$OUT"/*-squashfs-factory.ubi 2>/dev/null | head -1)
        if [ -n "$ubi_img" ]; then
            ubi_need=$(( $(wc -c < "$ubi_img") / 262144 - 2 + 5 ))
            ubi_layout="${CW_UBI_LAYOUT:-expanded}"
            case "$ubi_layout" in
                stock) ubi_cap=316 ;;
                expanded) ubi_cap=2720 ;;
                *) echo "ERROR: CW_UBI_LAYOUT must be stock or expanded" >&2; ubi_cap=0 ;;
            esac
            if [ "$ubi_need" -le 316 ]; then ubi_stock="fits"; else ubi_stock="does NOT fit"; fi
            echo "UBI_PEBS volumes need $ubi_need PEBs; stock 100 MiB layout (316): $ubi_stock; gate layout=$ubi_layout (capacity $ubi_cap)"
            [ "$ubi_need" -le "$ubi_cap" ] || {
                echo "ERROR: the image needs $ubi_need UBI PEBs, more than the $ubi_layout layout offers ($ubi_cap)." >&2
                rc=1
            }
        fi
        # Kernel vermagic vs the kmods repo the image points at. apk resolves kmods by
        # the exact `kernel (=<ver>~<vermagic>-rN)` dependency; a kmods repo built for another
        # vermagic can never be used and makes every apk upgrade / apk add of a kmod-needing
        # package fail on the device. The repo URL ends in <kernel>-<release>-<vermagic>.
        vm_file=$(find build_dir -maxdepth 5 -name .vermagic -path '*linux-*' 2>/dev/null | head -1)
        vm_built=$(cat "$vm_file" 2>/dev/null)
        for kl in "$REPO"/files/etc/apk/repositories.d/*.list; do
            kurl=$(grep -h -E '^[^#].*/kmods/[^/]+/packages\.adb' "$kl" 2>/dev/null | head -1)
            [ -n "$kurl" ] || continue
            vm_repo=$(printf '%s' "$kurl" | sed -n 's|.*/kmods/[^/]*-\([0-9a-f]\{32\}\)/packages\.adb.*|\1|p')
            if [ -n "$vm_built" ] && [ "$vm_repo" = "$vm_built" ]; then
                echo "KMODS_VERMAGIC_OK kernel $vm_built = the kmods repo in $(basename "$kl")"
            else
                echo "ERROR: the kmods repo in $(basename "$kl") is for vermagic '$vm_repo' but the built kernel is '$vm_built': apk upgrade / apk add would fail on the device." >&2
                echo "       Build with CONFIG_ALL_KMODS=y, or ship the kernel modules in the cw-opt feed and drop this line." >&2
                rc=1
            fi
        done
        {
            echo "built: $(date -u)"
            echo "cw-repo HEAD: $(git -C "$REPO" rev-parse HEAD 2>/dev/null || echo unknown)"
            echo "build mode: ${CLEAN:-incremental}"
            # `describe --dirty` alone said "v25.12.5-dirty" for every build, because this script
            # replaces the tracked feeds.conf.default with the repo's pinned list. State what differs
            # from the tag: that one expected file is "clean"; anything else is listed.
            ow_tag=$(git -C "$TREE" describe --tags --always 2>/dev/null || echo unknown)
            # Expected differences: feeds.conf.default (the pinned list) and the two base-files
            # templates this script rewrites for the version label (no %C), restored later.
            ow_dirty=$(git -C "$TREE" status --porcelain --untracked-files=no 2>/dev/null | awk '{print $2}' | grep -v -E '^(feeds\.conf\.default|package/base-files/files/etc/openwrt_release|package/base-files/files/usr/lib/os-release)$' | tr '\n' ' ')
            if [ -z "$ow_dirty" ]; then
                echo "openwrt: $ow_tag (tracked files identical to the tag except the expected build edits: feeds.conf.default = the repo's pinned feed list, and the two base-files version-label templates)"
            else
                echo "openwrt: $ow_tag-dirty (modified tracked files: $ow_dirty)"
            fi
            for fd in feeds/*/; do
                [ -d "$fd/.git" ] || continue
                echo "feed $(basename "$fd"): $(git -C "$fd" rev-parse HEAD 2>/dev/null || echo unknown)"
            done
        } > "$PROV/provenance.txt"
        ( cd "$OUT" && sha256sum ./*.bin ./cw-release-provenance/* > sha256sums.cw )
        if [ "$rc" = 0 ]; then echo "IMAGE_OK $BIN"; else echo "IMAGE_BUILT_WITH_PRIOR_ERRORS $BIN"; fi
        sha256sum "$BIN"
        echo "PROVENANCE $PROV (sha256sums.cw next to the image)"
    elif [ "$rc" = 0 ]; then
        echo "NO_IMAGE"
        rc=1
    fi
fi
echo "=== CW RELEASE BUILD END $(date -u) ==="
exit "$rc"
