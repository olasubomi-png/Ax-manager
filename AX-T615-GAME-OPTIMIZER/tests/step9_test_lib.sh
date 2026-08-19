#!/usr/bin/env sh
set -u
STEP9_TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
STEP9_ROOT="$(CDPATH= cd -- "$STEP9_TEST_DIR/.." 2>/dev/null && pwd)"
STEP9_BIN="$STEP9_ROOT/bin"
STEP9_FIXTURES="$STEP9_TEST_DIR/fixtures/games"
STEP9_TMP="${TMPDIR:-/tmp}/axgo-step9.$$"
mkdir -p "$STEP9_TMP"
step9_pass() { echo "PASS: $1"; }
step9_fail() { echo "FAIL: $1" >&2; exit 1; }
step9_assert_contains() { printf '%s\n' "$1" | grep -Fq "$2" && step9_pass "$3" || { printf '%s\n' "$1" >&2; step9_fail "$3"; }; }
step9_assert_not_contains() { printf '%s\n' "$1" | grep -Fq "$2" && step9_fail "$3" || step9_pass "$3"; }
step9_assert_file() { [ -e "$1" ] && step9_pass "$2" || step9_fail "$2"; }
step9_assert_missing() { [ ! -e "$1" ] && step9_pass "$2" || step9_fail "$2"; }
step9_hash_tree() { find "$1" -type f -not -path '*/runtime/*' -print0 2>/dev/null | sort -z | xargs -0 sha256sum 2>/dev/null | sha256sum | awk '{print $1}'; }
step9_cleanup() { rm -rf "$STEP9_TMP"; }
trap step9_cleanup EXIT INT TERM
