#!/system/bin/sh
set -u

TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
FIXTURE="$ROOT_DIR/tests/fixtures/cpu"
CONTROLLER="$ROOT_DIR/bin/cpu-controller"
AXGO="$ROOT_DIR/bin/axgo"
FAILURES=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }

OUTPUT="${TMPDIR:-/tmp}/axgo-cpu-dry-run.$$"
trap 'rm -f "$OUTPUT"' EXIT HUP INT TERM
export CPU_SYSFS_ROOT="$FIXTURE"
export CPU_PROC_CPUINFO="$FIXTURE/proc/cpuinfo"

if sh "$CONTROLLER" dry-run performance > "$OUTPUT" 2>&1; then
    pass "performance dry-run succeeds"
else
    fail "performance dry-run succeeds"
fi
grep -q "Requested profile: PERFORMANCE" "$OUTPUT" && pass "performance profile selected" || fail "performance profile selected"
grep -q "Planned changes:" "$OUTPUT" && pass "dry-run lists planned changes" || fail "dry-run lists planned changes"
grep -q "No real changes." "$OUTPUT" && pass "dry-run makes no real changes" || fail "dry-run makes no real changes"
grep -q "policy-a55" "$OUTPUT" && pass "dry-run reports discovered policies" || fail "dry-run reports discovered policies"

if sh "$CONTROLLER" dry-run turbo >/dev/null 2>&1; then
    fail "invalid dry-run profile accepted"
else
    pass "invalid dry-run profile rejected"
fi

AXGO_OUTPUT="$(sh "$AXGO" cpu dry-run performance 2>&1)"
printf '%s\n' "$AXGO_OUTPUT" | grep -q "AX-T615 CPU DRY RUN" &&
    pass "axgo CPU dry-run route" || fail "axgo CPU dry-run route"

if grep -nE '(/sys|/proc).*(>|>>|tee|chmod|chown|rm |mv )' \
    "$CONTROLLER" "$AXGO" >/dev/null 2>&1; then
    fail "dry-run route contains a sysfs/procfs write"
else
    pass "dry-run route contains no sysfs/procfs writes"
fi

[ "$FAILURES" -eq 0 ] && { echo "All CPU dry-run tests passed."; exit 0; }
echo "$FAILURES CPU dry-run test(s) failed."
exit 1