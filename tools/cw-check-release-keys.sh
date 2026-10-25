#!/bin/sh
# cw-check-release-keys.sh - prove an OpenWrt build tree signs the cw-opt feed
# with the key CleanWRT devices trust.
#
# The cw-opt feed index (packages.adb) is signed with <tree>/private-key.pem.
# OpenWrt generates a NEW private-key.pem whenever the tree has none (v25.12.5
# package/Makefile:62-66), but every device trusts only the shipped
# files/etc/apk/keys/public-key.pem - the public half of the existing tree key
# - because the overlay replaces the tree key base-files installs.
# A build from a tree with any other key produces a feed no device can verify.
#
# Checks:
#   - <tree>/private-key.pem exists and its public half equals the shipped
#     trust anchor (both compared as DER, so PEM line wrapping cannot matter);
#   - the private signing keys (private-key.pem, and key-build when present)
#     are readable by their user only: no group or other permission bits
#     Fix with `chmod 600`.
# Read-only: never writes into the tree and never prints key material.
#
# Usage: tools/cw-check-release-keys.sh <openwrt-tree-dir>
# Exit:  0 = keys match and are user-only; 1 = missing / mismatched /
#        unreadable / group- or world-accessible key (reason on stderr)
set -eu

REPO="$(cd "$(dirname "$0")/.." && pwd)"
TREE="${1:?usage: tools/cw-check-release-keys.sh <openwrt-tree-dir>}"
ANCHOR="$REPO/files/etc/apk/keys/public-key.pem"
PRIV="$TREE/private-key.pem"

fail() { echo "ERROR: cw-check-release-keys: $*" >&2; exit 1; }

[ -f "$ANCHOR" ] || fail "trust anchor $ANCHOR missing from this repo checkout"
[ -f "$PRIV" ] || fail "$PRIV missing - OpenWrt would generate a new feed key that no device trusts. Build in the tree that holds the feed key."

# User-only permissions on every private signing key in the tree.
for key in "$PRIV" "$TREE/key-build"; do
    [ -e "$key" ] || continue
    mode=$(stat -c '%a' "$key") || fail "cannot read the permissions of $key"
    case "$mode" in
        *[0-7]00) ;;
        *) fail "$key has mode $mode - a private signing key must be readable by its user only. Fix: chmod 600 $key (on a shared host, check who could have read it and consider rotating the key)." ;;
    esac
done

# The tree's own host openssl first (built by the buildroot), else the system one.
OSSL="$TREE/staging_dir/host/bin/openssl"
if [ ! -x "$OSSL" ]; then
    OSSL=$(command -v openssl) || fail "no openssl found (neither $TREE/staging_dir/host/bin/openssl nor on PATH)"
fi

work=$(mktemp -d) || fail "mktemp -d failed"
trap 'rm -rf "$work"' EXIT

"$OSSL" pkey -in "$PRIV" -pubout -outform DER -out "$work/tree.der" 2>"$work/err" ||
    fail "cannot derive the public key from $PRIV ($(head -1 "$work/err"))"
"$OSSL" pkey -pubin -in "$ANCHOR" -outform DER -out "$work/anchor.der" 2>"$work/err" ||
    fail "cannot parse the trust anchor $ANCHOR ($(head -1 "$work/err"))"

fp() { sha256sum "$1" | cut -c1-16; }
if ! cmp -s "$work/tree.der" "$work/anchor.der"; then
    fail "the tree feed key (public sha256 $(fp "$work/tree.der")) is not the shipped trust anchor (sha256 $(fp "$work/anchor.der")). Do not build a release here: its cw-opt feed would be unverifiable on every device. Rotating the key is a deliberate change of $ANCHOR, not a build-time accident."
fi
echo "cw-check-release-keys: feed key matches the shipped trust anchor (public sha256 $(fp "$work/anchor.der"))"
