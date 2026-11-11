#!/bin/sh
# cw-default-theme-test.sh - check what 96-cw-default-theme guarantees.
#
#   usage: tools/tests/cw-default-theme-test.sh
#
# The guarantee is a working web interface after an upgrade it did not choose. The
# design a router opens with is one uci value; the designs the selector offers are
# luci.themes, one entry per installed package. A sysupgrade keeps /etc/config/luci
# and drops the packages, so both can name a directory that is no longer there - the
# base renders a page with no styles, and the selector offers a choice that cannot
# work. This script is the repair, and it must leave a choice that still exists alone.
#
# The script reads /www and /etc/config/luci, so it takes a CW_ROOT prefix and the
# cases run against a tree in a temporary directory.
set -eu

TESTS=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SCRIPT="$TESTS/../../files/etc/uci-defaults/96-cw-default-theme"
[ -f "$SCRIPT" ] || { echo "test: $SCRIPT is missing" >&2; exit 1; }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/bin"

# A stand-in for uci over a key=value file, so a case is the file it is given.
# Every call that changes something is logged; a run that writes nothing can then be
# told from one that writes the wrong thing.
cat > "$WORK/bin/uci" <<'STUB'
#!/bin/sh
[ "$1" = "-q" ] && shift
case "$1" in
get)
	line=$(grep "^$2=" "$CFG" 2>/dev/null | head -1)
	[ -n "$line" ] || exit 1
	printf '%s\n' "${line#*=}"
	exit 0 ;;
show)
	sed -n "s|^\($2\.[^=]*=.*\)$|\1|p" "$CFG" | sed "s|=\(.*\)$|='\1'|"
	exit 0 ;;
delete)
	grep -v "^$2=" "$CFG" > "$CFG.tmp" 2>/dev/null || :
	mv "$CFG.tmp" "$CFG"
	printf 'delete %s\n' "$2" >> "$LOG"
	exit 0 ;;
set)
	key=${2%%=*}; val=${2#*=}
	grep -v "^$key=" "$CFG" > "$CFG.tmp" 2>/dev/null || :
	mv "$CFG.tmp" "$CFG"
	printf '%s=%s\n' "$key" "$val" >> "$CFG"
	printf 'set %s\n' "$2" >> "$LOG"
	exit 0 ;;
commit)
	printf 'commit %s\n' "$2" >> "$LOG"
	exit 0 ;;
esac
printf 'unexpected call: %s\n' "$*" >> "$LOG"
exit 1
STUB
chmod +x "$WORK/bin/uci"

fail=0
noted() { printf '  %-58s %s\n' "$1" "$2"; [ "$2" = ok ] || fail=1; }

# A case is the config file's lines plus the theme directories that exist. Bootstrap
# and Footstrap are in every image, so they are always there; more can be added.
run() { # <config-lines> [extra-dir...]
	ROOT="$WORK/root"
	rm -rf "$ROOT"
	mkdir -p "$ROOT/etc/config" "$ROOT/www/luci-static/bootstrap" \
	         "$ROOT/www/luci-static/footstrap"
	printf '%s\n' "$1" > "$ROOT/etc/config/luci"
	shift
	for d in "$@"; do mkdir -p "$ROOT/www/luci-static/$d"; done
	LOG="$WORK/log"; : > "$LOG"
	CFG="$ROOT/etc/config/luci" LOG="$LOG" CW_ROOT="$ROOT" PATH="$WORK/bin:$PATH" \
		sh "$SCRIPT"
	cat "$LOG"
}

case_run() { # <what> <expected log> <config lines> [extra-dir...]
	what=$1; want=$2; cfg=$3; shift 3
	got=$(run "$cfg" "$@" | tr '\n' ' ' | sed 's/ *$//')
	[ "$got" = "$want" ] && noted "$what" ok || noted "$what" "FAIL: did [$got], expected [$want]"
}

set_strap="set luci.themes.Footstrap=/luci-static/footstrap set luci.main.mediaurlbase=/luci-static/footstrap commit luci"
repair="delete luci.themes.Argon set luci.themes.Footstrap=/luci-static/footstrap set luci.main.mediaurlbase=/luci-static/footstrap commit luci"

echo "the base:"
case_run "already Footstrap: nothing is written" "" "luci.main.mediaurlbase=/luci-static/footstrap"
case_run "the stock bootstrap base is replaced" "$set_strap" "luci.main.mediaurlbase=/luci-static/bootstrap"
case_run "a base whose directory is gone is repaired" "$set_strap" "luci.main.mediaurlbase=/luci-static/argon"
case_run "a chosen theme that is installed is left alone" "" "luci.main.mediaurlbase=/luci-static/custom" custom

echo "the design selector:"
case_run "an entry without a directory is removed" "delete luci.themes.Argon commit luci" "luci.main.mediaurlbase=/luci-static/footstrap
luci.themes.Argon=/luci-static/argon
luci.themes.Bootstrap=/luci-static/bootstrap"
case_run "an entry that is installed is kept" "" "luci.main.mediaurlbase=/luci-static/footstrap
luci.themes.Bootstrap=/luci-static/bootstrap"
case_run "an entry with no path at all is removed" "delete luci.themes.Ghost commit luci" "luci.main.mediaurlbase=/luci-static/footstrap
luci.themes.Ghost="
case_run "a stale entry and a lost theme together" "$repair" "luci.main.mediaurlbase=/luci-static/argon
luci.themes.Argon=/luci-static/argon
luci.themes.Bootstrap=/luci-static/bootstrap"

echo "dead state:"
case_run "a marker an older image left is removed" "delete luci.cw_state commit luci" "luci.main.mediaurlbase=/luci-static/footstrap
luci.cw_state=1"

echo "what must not happen:"
rm -rf "$WORK/none"; mkdir -p "$WORK/none"
: > "$WORK/log"
CW_ROOT="$WORK/none" PATH="$WORK/bin:$PATH" CFG="$WORK/none/none" LOG="$WORK/log" sh "$SCRIPT"
[ ! -s "$WORK/log" ] && noted "no /etc/config/luci: nothing is written" ok ||
	noted "no /etc/config/luci" "FAIL: wrote $(tr '\n' ' ' < "$WORK/log")"

rm -rf "$WORK/bare"; mkdir -p "$WORK/bare/etc/config" "$WORK/bare/www/luci-static/bootstrap"
: > "$WORK/bare/etc/config/luci"; : > "$WORK/log"
CFG="$WORK/bare/etc/config/luci" LOG="$WORK/log" CW_ROOT="$WORK/bare" PATH="$WORK/bin:$PATH" sh "$SCRIPT"
[ ! -s "$WORK/log" ] && noted "Footstrap not installed: the stock theme stays" ok ||
	noted "Footstrap not installed" "FAIL: wrote $(tr '\n' ' ' < "$WORK/log")"

echo
[ "$fail" = 0 ] && echo "default-theme: all cases passed" || { echo "default-theme: failures above" >&2; exit 1; }
