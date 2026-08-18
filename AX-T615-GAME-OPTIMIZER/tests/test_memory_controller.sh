#!/system/bin/sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
FIXTURE="$TEST_DIR/fixtures/memory/optimal"
TMP_ROOT="${TMPDIR:-/tmp}/axgo-memory-controller.$$"
FAILURES=0
cleanup() { rm -rf "$TMP_ROOT"; }
trap cleanup EXIT HUP INT TERM
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }

mkdir -p "$TMP_ROOT/logs" "$TMP_ROOT/runtime"
BEFORE="$TMP_ROOT/before.sha256"
AFTER="$TMP_ROOT/after.sha256"
find "$FIXTURE" -type f -exec sha256sum {} \; | sort > "$BEFORE"

ENV_COMMON="MEMORY_PROC_ROOT=$FIXTURE/proc MEMORY_SYS_ROOT=$FIXTURE/sys MEMORY_SWAPS_FILE=$FIXTURE/proc/swaps MEMORY_POLICY_FILE=$ROOT_DIR/config/memory-policy.json AXGO_ROOT=$ROOT_DIR AXGO_DATA_ROOT=$TMP_ROOT"
STATUS_OUTPUT="$(eval "$ENV_COMMON sh $ROOT_DIR/bin/memory-controller status" 2>&1)"
printf '%s\n' "$STATUS_OUTPUT" | grep -q 'Physical RAM: 3000.0 MB' && pass 'physical RAM discovered' || fail 'physical RAM discovered'
printf '%s\n' "$STATUS_OUTPUT" | grep -q 'Available percentage: 71%' && pass 'available RAM calculated' || fail 'available RAM calculated'
printf '%s\n' "$STATUS_OUTPUT" | grep -q 'Memory state: OPTIMAL' && pass 'optimal state classified' || fail 'optimal state classified'
printf '%s\n' "$STATUS_OUTPUT" | grep -q 'Memory PSI: NONE' && pass 'PSI state reported' || fail 'PSI state reported'
printf '%s\n' "$STATUS_OUTPUT" | grep -q 'ZRAM: AVAILABLE' && pass 'ZRAM detected' || fail 'ZRAM detected'
printf '%s\n' "$STATUS_OUTPUT" | grep -q 'Swap: ACTIVE' && pass 'swap detected' || fail 'swap detected'

INSPECT_OUTPUT="$(eval "$ENV_COMMON sh $ROOT_DIR/bin/memory-controller inspect" 2>&1)"
printf '%s\n' "$INSPECT_OUTPUT" | grep -q 'MemTotal: 3072000 kB' && pass 'inspect exposes meminfo fields' || fail 'inspect exposes meminfo fields'
DRY_OUTPUT="$(eval "$ENV_COMMON sh $ROOT_DIR/bin/memory-controller dry-run" 2>&1)"
printf '%s\n' "$DRY_OUTPUT" | grep -q 'Planned changes:' && pass 'dry-run has planned changes section' || fail 'dry-run has planned changes section'
printf '%s\n' "$DRY_OUTPUT" | grep -q '^NONE$' && pass 'dry-run plans no changes' || fail 'dry-run plans no changes'
AXGO_OUTPUT="$(eval "$ENV_COMMON sh $ROOT_DIR/bin/axgo memory status" 2>&1)"
printf '%s\n' "$AXGO_OUTPUT" | grep -q 'AX-T615 MEMORY STATUS' && pass 'axgo memory routing' || fail 'axgo memory routing'

find "$FIXTURE" -type f -exec sha256sum {} \; | sort > "$AFTER"
if cmp -s "$BEFORE" "$AFTER"; then pass 'fixture files remain unchanged'; else fail 'fixture files remain unchanged'; fi

[ "$FAILURES" -eq 0 ] && { echo 'All memory controller tests passed.'; exit 0; }
echo "$FAILURES memory controller test(s) failed."; exit 1
