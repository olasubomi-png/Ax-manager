#!/system/bin/sh
set -u

TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
FIXTURE="$TEST_DIR/fixtures/cpu"
CONTROLLER="$ROOT_DIR/bin/cpu-controller"
WORK="${TMPDIR:-/tmp}/axgo-cpu-restore.$$"
FAILURES=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT HUP INT TERM

setup_case() {
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

run_controller() {
    CPU_SYSFS_ROOT="$WORK" CPU_PROC_CPUINFO="$WORK/proc/cpuinfo" \
    CPU_THERMAL_ROOT="$WORK/thermal" CPU_DATA_ROOT="$WORK" \
    CPU_SAFETY_FORCE_ROOT=true sh "$CONTROLLER" "$@"
}

setup_case
run_controller apply performance >/dev/null
RESTORE_OUTPUT="$(run_controller restore 2>&1)"
printf '%s\n' "$RESTORE_OUTPUT" | grep -q "CPU restore completed successfully" &&
    pass "restore succeeds" || fail "restore succeeds"
[ "$(cat "$WORK/cpufreq/policy-a55/scaling_max_freq")" = "1612000" ] &&
    pass "A55 maximum restored" || fail "A55 maximum restored"
[ "$(cat "$WORK/cpufreq/policy-a75/scaling_max_freq")" = "1820000" ] &&
    pass "A75 maximum restored" || fail "A75 maximum restored"
[ "$(cat "$WORK/cpufreq/policy-a55/scaling_min_freq")" = "300000" ] &&
    pass "A55 minimum restored" || fail "A55 minimum restored"
[ "$(cat "$WORK/cpufreq/policy-a55/scaling_governor")" = "uscfreq" ] &&
    pass "governor restored" || fail "governor restored"
[ ! -e "$WORK/runtime/cpu/original_policy-a55.conf" ] &&
    pass "successful restore removes A55 backup" || fail "successful restore removes A55 backup"
[ ! -e "$WORK/runtime/cpu/original_policy-a75.conf" ] &&
    pass "successful restore removes A75 backup" || fail "successful restore removes A75 backup"

setup_case
run_controller apply performance >/dev/null
PARTIAL_OUTPUT="$(CPU_SYSFS_ROOT="$WORK" CPU_PROC_CPUINFO="$WORK/proc/cpuinfo" \
    CPU_THERMAL_ROOT="$WORK/thermal" CPU_DATA_ROOT="$WORK" \
    CPU_SAFETY_FORCE_ROOT=true CPU_SAFETY_FORCE_READONLY=true \
    sh "$CONTROLLER" restore 2>&1 || :)"
printf '%s\n' "$PARTIAL_OUTPUT" | grep -q "RESTORE FAILED" &&
    pass "partial restore reports exact failure" || fail "partial restore reports exact failure"
[ -s "$WORK/runtime/cpu/original_policy-a55.conf" ] &&
    pass "failed restore retains A55 backup" || fail "failed restore retains A55 backup"

[ "$FAILURES" -eq 0 ] && { echo "All CPU restore tests passed."; exit 0; }
echo "$FAILURES CPU restore test(s) failed."
exit 1