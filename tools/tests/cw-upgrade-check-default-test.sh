#!/bin/sh
# cw-upgrade-check-default-test.sh - check what 52-cw-upgrade-check guarantees.
#
#   usage: tools/tests/cw-upgrade-check-default-test.sh
#
# The guarantee is one written preference and no more. LuCI asks its firmware-check
# question on every load of Status -> Overview until attendedsysupgrade.client.
# login_check_for_upgrades exists, and it accepts any answer as an answer - so the
# default has to be written where the option is absent, and left alone where the
# router's owner has already answered. Both halves are load-bearing: writing too
# little leaves the question coming back, and writing too much overrules an owner
# who turned the check off.
#
# A second guarantee cannot be seen in that behaviour at all: it is the file's
# number. attendedsysupgrade-common ships its own uci-defaults as
# 50-attendedsysupgrade, which creates the config file with its defaults and
# without this option; uci-defaults run in name order, so the same script numbered
# below 50 would write into a file that does not exist yet and be overwritten. The
# last case pins that number, and the one before it pins the package's.
set -eu

TESTS=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# By pattern, not by name: the file's number is one of the things under test
SCRIPT=$(ls "$TESTS"/../../files/etc/uci-defaults/*-cw-upgrade-check 2>/dev/null | head -1)
[ -n "$SCRIPT" ] && [ -f "$SCRIPT" ] || { echo "test: no *-cw-upgrade-check under files/etc/uci-defaults" >&2; exit 1; }

# The package's own script, whose number this one has to be above. If a later feed
# renumbers it, the case below fails and this line is what has to be re-read.
PACKAGE_DEFAULTS=50-attendedsysupgrade

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/bin"

# A stand-in for uci: the config's shape arrives in the environment, and every call
# the script makes is logged, so a run that writes nothing can be told from one that
# writes the wrong thing.
cat > "$WORK/bin/uci" <<'STUB'
#!/bin/sh
[ "$1" = "-q" ] && shift
case "$1 $2" in
"get attendedsysupgrade.client")
	[ "$SECTION" = yes ] && { echo client; exit 0; }
	exit 1 ;;
"get attendedsysupgrade.client.login_check_for_upgrades")
	[ "$OPTION" = absent ] || { echo "$OPTION"; exit 0; }
	exit 1 ;;
"set attendedsysupgrade.client.login_check_for_upgrades=1")
	echo set >> "$LOG"; exit 0 ;;
"commit attendedsysupgrade")
	echo commit >> "$LOG"; exit 0 ;;
esac
echo "unexpected call: $*" >> "$LOG"
exit 1
STUB
chmod +x "$WORK/bin/uci"

fail=0
noted() { printf '  %-52s %s\n' "$1" "$2"; [ "$2" = ok ] || fail=1; }

# one run of the script against a described config; the log is what it did
run() { # <section> <option>
	LOG="$WORK/log"; : > "$LOG"
	SECTION="$1" OPTION="$2" LOG="$LOG" PATH="$WORK/bin:$PATH" sh "$SCRIPT"
	cat "$LOG"
}

case_run() { # <expected log> <section> <option> <what>
	got=$(run "$2" "$3" | tr '\n' ' ' | sed 's/ *$//')
	[ "$got" = "$1" ] && noted "$4" ok || noted "$4" "FAIL: wrote [$got], expected [$1]"
}

echo "the default:"
case_run "" "no" absent "no config at all: nothing is written"
case_run "set commit" "yes" absent "config without the option: it is written and committed"
case_run "" "yes" 0 "the owner turned the check off: that answer stands"
case_run "" "yes" 1 "already on: nothing is written"
case_run "" "yes" "" "an empty value is still an answer: it is left alone"

echo "the ordering:"
n=$(basename "$SCRIPT" | sed 's/^\([0-9][0-9]*\)-.*/\1/')
p=$(printf '%s' "$PACKAGE_DEFAULTS" | sed 's/^\([0-9][0-9]*\)-.*/\1/')
[ "$n" -gt "$p" ] && noted "runs after $PACKAGE_DEFAULTS ($n > $p)" ok ||
	noted "runs after $PACKAGE_DEFAULTS ($n > $p)" "FAIL: the package's defaults would overwrite it"

echo
[ "$fail" = 0 ] && echo "upgrade-check-default: all cases passed" || { echo "upgrade-check-default: failures above" >&2; exit 1; }
