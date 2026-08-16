#!/system/bin/sh
set -u

# Development-only CPU discovery tests. The fixture is never copied to /sys.
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
CONTROLLER="$ROOT_DIR/bin/cpu-controller"
FIXTURE="$ROOT_DIR/tests/fixtures/cpu"
FAILURES=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
fixture_env() {
    CPU_SYSFS_ROOT="$FIXTURE"
    CPU_PROC_CPUINFO="$FIXTURE/proc/cpuinfo"
    export CPU_SYSFS_ROOT CPU_PROC_CPUINFO
}

fixture_env
if sh -n "$CONTROLLER" && sh -n "$ROOT_DIR/bin/cpu-safety"; then
    pass "CPU scripts have valid shell syntax"
else
    fail "CPU scripts have valid shell syntax"
fi

OUTPUT="${TMPDIR:-/tmp}/axgo-cpu-controller.$$"
trap 'rm -f "$OUTPUT"' EXIT HUP INT TERM

if sh "$CONTROLLER" inspect > "$OUTPUT" 2>&1; then
    pass "fixture inspection runs without root"
else
    fail "fixture inspection runs without root"
fi
grep -q "policy-a55" "$OUTPUT" && pass "dynamic first policy discovered" || fail "dynamic first policy discovered"
grep -q "policy-a75" "$OUTPUT" && pass "dynamic second policy discovered" || fail "dynamic second policy discovered"
grep -q "EFFICIENCY (Cortex-A55)" "$OUTPUT" && pass "A55 cluster detected from cpuinfo" || fail "A55 cluster detected from cpuinfo"
grep -q "PERFORMANCE (Cortex-A75)" "$OUTPUT" && pass "A75 cluster detected from cpuinfo" || fail "A75 cluster detected from cpuinfo"
grep -q "Frequency unit: kHz (numeric cpufreq sysfs convention)" "$OUTPUT" &&
    pass "frequency unit documented" || fail "frequency unit documented"
grep -q "Current governor: uscfreq" "$OUTPUT" && pass "observed governor reported" || fail "observed governor reported"
grep -q "No hardware settings were changed" "$OUTPUT" &&
    pass "inspection declares read-only behavior" || fail "inspection declares read-only behavior"

MISSING="${TMPDIR:-/tmp}/axgo-cpu-controller-missing.$$"
mkdir -p "$MISSING"
if CPU_SYSFS_ROOT="$MISSING" CPU_PROC_CPUINFO="$MISSING/cpuinfo" \
    sh "$CONTROLLER" inspect > "$OUTPUT" 2>&1; then
    pass "missing policy is handled safely"
else
    fail "missing policy is handled safely"
fi
grep -q "No CPU policies discovered" "$OUTPUT" && pass "missing policy reported" || fail "missing policy reported"
rm -rf "$MISSING"

MUTANT="${TMPDIR:-/tmp}/axgo-cpu-controller-mutant.$$"
cp -R "$FIXTURE" "$MUTANT"
rm -f "$MUTANT/cpufreq/policy-a55/scaling_available_governors"
printf '%s\n' "not-a-frequency" > "$MUTANT/cpufreq/policy-a55/scaling_cur_freq"
if CPU_SYSFS_ROOT="$MUTANT" CPU_PROC_CPUINFO="$MUTANT/proc/cpuinfo" \
    sh "$CONTROLLER" inspect > "$OUTPUT" 2>&1; then
    pass "malformed and missing nodes are handled safely"
else
    fail "malformed and missing nodes are handled safely"
fi
grep -q "Available governors: unavailable" "$OUTPUT" &&
    pass "missing governor reported" || fail "missing governor reported"
grep -q "Frequency unit: unknown" "$OUTPUT" &&
    pass "malformed frequency reported as unknown" || fail "malformed frequency reported as unknown"
rm -rf "$MUTANT"

if grep -nE '(/sys|/proc).*(>|>>|tee|chmod|chown|rm |mv )' \
    "$CONTROLLER" "$ROOT_DIR/bin/cpu-safety" >/dev/null 2>&1; then
    fail "CPU scripts contain a real sysfs/procfs write"
else
    pass "CPU scripts contain no sysfs/procfs writes"
fi

[ "$FAILURES" -eq 0 ] && { echo "All CPU controller tests passed."; exit 0; }
echo "$FAILURES CPU controller test(s) failed."
exit 1