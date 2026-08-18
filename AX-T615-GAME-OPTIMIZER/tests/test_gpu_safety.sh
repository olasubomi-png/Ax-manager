#!/system/bin/sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0" 2>/dev/null)" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
SAFETY="$ROOT_DIR/bin/gpu-safety"
WORK="${TMPDIR:-/tmp}/axgo-gpu-safety.$$"
FAILURES=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT HUP INT TERM
. "$SAFETY"
mkdir -p "$WORK"
printf '%s\n' test > "$WORK/node"
gpu_safety_validate_frequency 500 200 800 && pass "frequency within limits accepted" || fail "frequency within limits accepted"
gpu_safety_validate_frequency 900 200 800 && fail "frequency above maximum rejected" || pass "frequency above maximum rejected"
gpu_safety_validate_frequency invalid 200 800 && fail "invalid frequency rejected" || pass "invalid frequency rejected"
gpu_safety_validate_frequency 500 800 200 && fail "reversed limits rejected" || pass "reversed limits rejected"
GPU_SAFETY_FORCE_ROOT=true gpu_safety_validate_frequency_request 500 200 800 "200 500 800" && pass "future frequency request validates" || fail "future frequency request validates"
GPU_SAFETY_FORCE_ROOT=true gpu_safety_validate_frequency_request 600 200 800 "200 500 800" && fail "guessed frequency rejected" || pass "guessed frequency rejected"
GPU_SAFETY_FORCE_NON_ROOT=true gpu_safety_validate_frequency_request 500 200 800 "200 500 800" && fail "non-root future write rejected" || pass "non-root future write rejected"
gpu_safety_validate_node "$WORK/node" && pass "readable node accepted" || fail "readable node accepted"
gpu_safety_validate_node "$WORK/missing" && fail "missing node rejected" || pass "missing node rejected"
gpu_safety_validate_governor simple_ondemand "simple_ondemand performance" && pass "discovered governor accepted" || fail "discovered governor accepted"
gpu_safety_validate_governor powersave "simple_ondemand performance" && fail "unknown governor rejected" || pass "unknown governor rejected"
[ "$(gpu_safety_capability_status "$WORK/node" mali 500 200 800)" = AVAILABLE ] && pass "complete capability is available" || fail "complete capability is available"
[ "$(gpu_safety_capability_status "$WORK/node" unknown 500 200 800)" = UNCERTAIN ] && pass "unknown driver is uncertain" || fail "unknown driver is uncertain"
[ "$(gpu_safety_capability_status "$WORK/missing" mali 500 200 800)" = UNAVAILABLE ] && pass "missing node is unavailable" || fail "missing node is unavailable"
GPU_SAFETY_WRITES_ENABLED=true gpu_safety_writes_enabled && fail "Step 6A writes cannot be enabled" || pass "Step 6A writes remain disabled"
[ "$FAILURES" -eq 0 ] && { echo "All GPU safety tests passed."; exit 0; }
echo "$FAILURES GPU safety test(s) failed."
exit 1
