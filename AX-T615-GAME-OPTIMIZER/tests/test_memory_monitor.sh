#!/system/bin/sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
FIXTURE="$TEST_DIR/fixtures/memory/optimal"
TMP_ROOT="${TMPDIR:-/tmp}/axgo-memory-monitor.$$"
FAILURES=0
cleanup() { rm -rf "$TMP_ROOT"; }
trap cleanup EXIT HUP INT TERM
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
mkdir -p "$TMP_ROOT/logs" "$TMP_ROOT/runtime"
BEFORE="$TMP_ROOT/before.sha256"; AFTER="$TMP_ROOT/after.sha256"
find "$FIXTURE" -type f -exec sha256sum {} \; | sort > "$BEFORE"
OUTPUT="$(MEMORY_MONITOR_SAMPLES=2 MEMORY_PROC_ROOT="$FIXTURE/proc" MEMORY_SYS_ROOT="$FIXTURE/sys" MEMORY_SWAPS_FILE="$FIXTURE/proc/swaps" MEMORY_POLICY_FILE="$ROOT_DIR/config/memory-policy.json" AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$TMP_ROOT" sh "$ROOT_DIR/bin/memory-monitor" --interval 1 2>&1)"
[ "$(printf '%s\n' "$OUTPUT" | wc -l | tr -d ' ')" -eq 2 ] && pass 'monitor emits requested sample count' || fail 'monitor emits requested sample count'
printf '%s\n' "$OUTPUT" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' && pass 'monitor emits timestamps' || fail 'monitor emits timestamps'
printf '%s\n' "$OUTPUT" | grep -q 'Available RAM:' && pass 'monitor emits available RAM' || fail 'monitor emits available RAM'
printf '%s\n' "$OUTPUT" | grep -q 'Used: 28%' && pass 'monitor emits used percentage' || fail 'monitor emits used percentage'
printf '%s\n' "$OUTPUT" | grep -q 'State: OPTIMAL' && pass 'monitor emits memory state' || fail 'monitor emits memory state'
printf '%s\n' "$OUTPUT" | grep -q 'PSI: NONE' && pass 'monitor emits PSI state' || fail 'monitor emits PSI state'
printf '%s\n' "$OUTPUT" | grep -q 'ZRAM: AVAILABLE' && pass 'monitor emits ZRAM state' || fail 'monitor emits ZRAM state'
find "$FIXTURE" -type f -exec sha256sum {} \; | sort > "$AFTER"
if cmp -s "$BEFORE" "$AFTER"; then pass 'monitor leaves fixture unchanged'; else fail 'monitor leaves fixture unchanged'; fi
[ "$FAILURES" -eq 0 ] && { echo 'All memory monitor tests passed.'; exit 0; }
echo "$FAILURES memory monitor test(s) failed."; exit 1
