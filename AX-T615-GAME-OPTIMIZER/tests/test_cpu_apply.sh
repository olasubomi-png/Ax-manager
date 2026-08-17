#!/system/bin/sh
set -u

TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
FIXTURE="$TEST_DIR/fixtures/cpu"
CONTROLLER="$ROOT_DIR/bin/cpu-controller"
WORK="${TMPDIR:-/tmp}/axgo-cpu-apply.$$"
FAILURES=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT HUP INT TERM

new_case() {
    rm -rf "$WORK"
    cp -R "$FIXTURE" "$WORK"
    mkdir -p "$WORK/config" "$WORK/logs" "$WORK/runtime" "$WORK/thermal/thermal_zone0"
    cp "$ROOT_DIR/config/profiles.conf" "$WORK/config/profiles.conf"
    printf '%s\n' 45000 > "$WORK/thermal/thermal_zone0/temp"
    sed -i 's/CPU_FREQUENCY_CHANGES_ENABLED="false"/CPU_FREQUENCY_CHANGES_ENABLED="true"/' \
        "$WORK/config/profiles.conf"
    sed -i 's/CPU_PERFORMANCE_TARGET_MAX_FREQ=""/CPU_PERFORMANCE_TARGET_MAX_FREQ="1401600"/' \
        "$WORK/config/profiles.conf"
}

run_apply() {
    CPU_SYSFS_ROOT="$WORK" \
    CPU_PROC_CPUINFO="$WORK/proc/cpuinfo" \
    CPU_THERMAL_ROOT="$WORK/thermal" \
    CPU_DATA_ROOT="$WORK" \
    CPU_SAFETY_FORCE_ROOT=true \
    sh "$CONTROLLER" apply performance
}

new_case
NO_ROOT_OUTPUT="$(CPU_SYSFS_ROOT="$WORK" CPU_PROC_CPUINFO="$WORK/proc/cpuinfo" \
    CPU_DATA_ROOT="$WORK" CPU_SAFETY_FORCE_NON_ROOT=true \
    sh "$CONTROLLER" apply performance 2>&1 || :)"
printf '%s\n' "$NO_ROOT_OUTPUT" | grep -q "ROOT REQUIRED" &&
    pass "no-root apply rejected" || fail "no-root apply rejected"
printf '%s\n' "$NO_ROOT_OUTPUT" | grep -q "NO CHANGES MADE" &&
    pass "no-root apply made no changes" || fail "no-root apply made no changes"
[ "$(cat "$WORK/cpufreq/policy-a55/scaling_max_freq")" = "1612000" ] &&
    pass "no-root fixture unchanged" || fail "no-root fixture unchanged"

new_case
rm -f "$WORK/cpufreq/policy-a55/scaling_max_freq"
MISSING_OUTPUT="$(run_apply 2>&1 || :)"
printf '%s\n' "$MISSING_OUTPUT" | grep -q "REJECTED frequency change" &&
    pass "missing node rejected" || fail "missing node rejected"

new_case
READONLY_OUTPUT="$(CPU_SYSFS_ROOT="$WORK" CPU_PROC_CPUINFO="$WORK/proc/cpuinfo" \
    CPU_THERMAL_ROOT="$WORK/thermal" CPU_DATA_ROOT="$WORK" \
    CPU_SAFETY_FORCE_ROOT=true CPU_SAFETY_FORCE_READONLY=true \
    sh "$CONTROLLER" apply performance 2>&1 || :)"
printf '%s\n' "$READONLY_OUTPUT" | grep -q "REJECTED frequency change" &&
    pass "read-only node rejected" || fail "read-only node rejected"

for VALUE in not-a-frequency 2000000 1000; do
    new_case
    sed -i "s/CPU_PERFORMANCE_TARGET_MAX_FREQ=\"[^\"]*\"/CPU_PERFORMANCE_TARGET_MAX_FREQ=\"$VALUE\"/" \
        "$WORK/config/profiles.conf"
    VALUE_OUTPUT="$(run_apply 2>&1 || :)"
    printf '%s\n' "$VALUE_OUTPUT" | grep -q "REJECTED frequency" &&
        pass "invalid or out-of-limit value rejected: $VALUE" ||
        fail "invalid or out-of-limit value rejected: $VALUE"
    [ ! -d "$WORK/runtime/cpu" ] || [ -z "$(find "$WORK/runtime/cpu" -type f -print -quit)" ] &&
        pass "rejected value created no backup: $VALUE" ||
        fail "rejected value created no backup: $VALUE"
done

new_case
SUCCESS_OUTPUT="$(run_apply 2>&1)"
printf '%s\n' "$SUCCESS_OUTPUT" | grep -q "CPU changes applied safely" &&
    pass "successful simulated apply" || fail "successful simulated apply"
[ "$(cat "$WORK/cpufreq/policy-a55/scaling_max_freq")" = "1401600" ] &&
    pass "A55 simulated frequency write" || fail "A55 simulated frequency write"
[ "$(cat "$WORK/cpufreq/policy-a75/scaling_max_freq")" = "1401600" ] &&
    pass "A75 simulated frequency write" || fail "A75 simulated frequency write"
[ -s "$WORK/runtime/cpu/original_policy-a55.conf" ] &&
    pass "A55 original state backed up" || fail "A55 original state backed up"
[ -s "$WORK/runtime/cpu/original_policy-a75.conf" ] &&
    pass "A75 original state backed up" || fail "A75 original state backed up"
grep -q "apply request" "$WORK/logs/cpu.log" &&
    pass "CPU apply logging" || fail "CPU apply logging"

[ "$FAILURES" -eq 0 ] && { echo "All CPU apply tests passed."; exit 0; }
echo "$FAILURES CPU apply test(s) failed."
exit 1