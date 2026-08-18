#!/system/bin/sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
TMP_ROOT="${TMPDIR:-/tmp}/axgo-memory-guard.$$"
FAILURES=0
cleanup() { rm -rf "$TMP_ROOT"; }
trap cleanup EXIT HUP INT TERM
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
run_guard() { S="$1"; ROOT="$TEST_DIR/fixtures/memory/$S"; MEMORY_PROC_ROOT="$ROOT/proc" MEMORY_SYS_ROOT="$ROOT/sys" MEMORY_SWAPS_FILE="$ROOT/proc/swaps" MEMORY_POLICY_FILE="$ROOT_DIR/config/memory-policy.json" AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$ROOT_DIR/bin/memory-guard" recommend 2>&1; }
expect_rec() { OUT="$(run_guard "$1")"; printf '%s\n' "$OUT" | grep -q "Recommendation: $2" && pass "$1 recommendation $2" || { printf '%s\n' "$OUT"; fail "$1 recommendation $2"; }; }
mkdir -p "$TMP_ROOT/logs" "$TMP_ROOT/runtime"
expect_rec normal NORMAL
expect_rec pressure CONSERVATIVE
expect_rec high_pressure CONSERVATIVE
expect_rec critical CRITICAL
expect_rec unknown UNKNOWN
printf '%s\n' "$(run_guard unknown)" | grep -q 'Memory state: UNKNOWN' && pass 'unknown data is fail-safe' || fail 'unknown data is fail-safe'
printf '%s\n' "$(run_guard pressure)" | grep -q 'Recommendation: CONSERVATIVE' && pass 'pressure recommendation is conservative' || fail 'pressure recommendation is conservative'
if grep -R -nE '(^|[[:space:]])(echo|printf|cat)[[:space:]]+[^|]*>[[:space:]]*(/proc|/sys)|(^|[[:space:]])(sysctl|setprop|swapon|swapoff|zramctl)([[:space:]]|$)' "$ROOT_DIR/bin/memory-controller" "$ROOT_DIR/bin/memory-guard" >/dev/null 2>&1; then fail 'memory guard has no hardware write commands'; else pass 'memory guard has no hardware write commands'; fi
[ "$FAILURES" -eq 0 ] && { echo 'All memory guard tests passed.'; exit 0; }
echo "$FAILURES memory guard test(s) failed."; exit 1
