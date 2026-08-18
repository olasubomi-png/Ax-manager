#!/system/bin/sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
FAILURES=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
run_state() { S="$1"; ROOT="$TEST_DIR/fixtures/memory/$S"; MEMORY_PROC_ROOT="$ROOT/proc" MEMORY_SYS_ROOT="$ROOT/sys" MEMORY_SWAPS_FILE="$ROOT/proc/swaps" MEMORY_POLICY_FILE="$ROOT_DIR/config/memory-policy.json" AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="${TMPDIR:-/tmp}/axgo-memory-detection.$$" sh "$ROOT_DIR/bin/memory-controller" pressure 2>&1 | sed -n 's/^Memory state: //p' | head -n 1; }
run_rec() { S="$1"; ROOT="$TEST_DIR/fixtures/memory/$S"; MEMORY_PROC_ROOT="$ROOT/proc" MEMORY_SYS_ROOT="$ROOT/sys" MEMORY_SWAPS_FILE="$ROOT/proc/swaps" MEMORY_POLICY_FILE="$ROOT_DIR/config/memory-policy.json" AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="${TMPDIR:-/tmp}/axgo-memory-detection.$$" sh "$ROOT_DIR/bin/memory-guard" recommend 2>&1 | sed -n 's/^Recommendation: //p' | tail -n 1; }
EXPECT_STATE() { ACTUAL="$(run_state "$1")"; [ "$ACTUAL" = "$2" ] && pass "$1 state is $2" || { echo "Observed: $ACTUAL"; fail "$1 state is $2"; }; }
EXPECT_REC() { ACTUAL="$(run_rec "$1")"; [ "$ACTUAL" = "$2" ] && pass "$1 recommendation is $2" || { echo "Observed: $ACTUAL"; fail "$1 recommendation is $2"; }; }
EXPECT_STATE optimal OPTIMAL; EXPECT_REC optimal NORMAL
EXPECT_STATE normal NORMAL; EXPECT_REC normal NORMAL
EXPECT_STATE pressure PRESSURE; EXPECT_REC pressure CONSERVATIVE
EXPECT_STATE high_pressure HIGH_PRESSURE; EXPECT_REC high_pressure CONSERVATIVE
EXPECT_STATE critical CRITICAL; EXPECT_REC critical CRITICAL
EXPECT_STATE unknown UNKNOWN; EXPECT_REC unknown UNKNOWN
EXPECT_STATE incomplete UNKNOWN; EXPECT_REC incomplete UNKNOWN
[ "$FAILURES" -eq 0 ] && { echo 'All memory detection tests passed.'; exit 0; }
echo "$FAILURES memory detection test(s) failed."; exit 1
