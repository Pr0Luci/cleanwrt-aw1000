#!/bin/sh
# cw-site-update.sh - add one release to the project site (the gh-pages branch).
#
# Usage: tools/cw-site-update.sh <site-dir> <version> <release-url> <profiles.json>
#   <site-dir>      checkout of the gh-pages branch
#   <version>       e.g. 25.12.5-rc1 (a -rc label is recorded as the upcoming version)
#   <release-url>   the GitHub release page of that version
#   <profiles.json> profiles.json from bin/targets/qualcommax/ipq807x/
#
# It maintains what the LuCI upgrade check reads (patches/feeds/luci/0007):
#   .versions.json                                 stable_version / upcoming_version
#   releases/<version>/index.html                  redirect to the release page
#   releases/<version>/targets/<target>/profiles.json
set -eu

SITE="${1:?usage: cw-site-update.sh <site-dir> <version> <release-url> <profiles.json>}"
VER="${2:?version missing}"
URL="${3:?release url missing}"
PROF="${4:?profiles.json missing}"
TARGET="qualcommax/ipq807x"

[ -d "$SITE" ] || { echo "ERROR: $SITE is not a directory" >&2; exit 1; }
[ -s "$PROF" ] || { echo "ERROR: $PROF is missing or empty" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required" >&2; exit 1; }
case "$VER" in
    [0-9]*.[0-9]*.[0-9]*|[0-9]*.[0-9]*.[0-9]*-rc[0-9]*) ;;
    *) echo "ERROR: unexpected version '$VER'" >&2; exit 1 ;;
esac
case "$URL" in https://github.com/*) ;; *) echo "ERROR: release url must be a github.com url" >&2; exit 1 ;; esac
jq -e --arg t "arcadyan_aw1000" '.profiles | has($t)' "$PROF" >/dev/null ||
    { echo "ERROR: profiles.json has no arcadyan_aw1000 profile" >&2; exit 1; }

DEST="$SITE/releases/$VER/targets/$TARGET"
mkdir -p "$DEST"
cp "$PROF" "$DEST/profiles.json"

cat > "$SITE/releases/$VER/index.html" <<HTML
<!doctype html>
<meta charset="utf-8">
<meta http-equiv="refresh" content="0; url=$URL">
<title>CleanWRT $VER</title>
<a href="$URL">CleanWRT $VER</a>
HTML

[ -f "$SITE/.versions.json" ] || echo '{}' > "$SITE/.versions.json"
case "$VER" in
    *-rc*) jq --arg v "$VER" '.upcoming_version = $v' "$SITE/.versions.json" > "$SITE/.versions.json.new" ;;
    *)     jq --arg v "$VER" '.stable_version = $v | del(.upcoming_version)' "$SITE/.versions.json" > "$SITE/.versions.json.new" ;;
esac
mv "$SITE/.versions.json.new" "$SITE/.versions.json"

touch "$SITE/.nojekyll"
[ -f "$SITE/index.html" ] || cat > "$SITE/index.html" <<'HTML'
<!doctype html>
<meta charset="utf-8">
<title>CleanWRT</title>
<h1>CleanWRT</h1>
<p>OpenWrt based firmware for the Arcadyan AW1000.</p>
<ul>
  <li><a href="https://github.com/Pr0Luci/cleanwrt-aw1000/releases">Releases</a></li>
  <li><a href="https://github.com/Pr0Luci/cleanwrt-aw1000">Source</a></li>
</ul>
HTML
echo "site updated for $VER"
