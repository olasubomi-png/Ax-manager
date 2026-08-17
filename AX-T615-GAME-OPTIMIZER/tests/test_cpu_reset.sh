#!/system/bin/sh
set -u

TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
FIXTURE="$TEST_DIR/fixtures/cpu"
CONTROLLER="$ROOT_DIR/bin/cpu-controller"
RESET="$ROOT_DIR/bin/cpu-reset"
WORK="${TMPDIR:-/tmp}/axgo-cpu-reset.$$"
FAILURES=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT HUP INT TERM

mkdir -p "$WORK/config" "$WORK/logs" "$WORK/runtime" "$WORK/thermal/thermal_zone0"
cp -R "$FIXTURE"/. "$WORK"/
cp "$ROOT_DIR/config/profiles.conf" "$WORK/config/profiles.conf"
printf '%s\n' 45000 > "$WORK/thermal/thermal_zone0/temp"
sed -i 's/CPU_FREQUENCY_CHANGES_ENABLED="false"/CPU_FREQUENCY_CHANGES_ENABLED="true"/' \
    "$WORK/config/profiles.conf"
sed -i 's/CPU_PERFORMANCE_TARGET_MAX_FREQ=""/CPU_PERFORMANCE_TARGET_MAX_FREQ="1401600"/' \
    "$WORK/config/profiles.conf"

CPU_ENV="CPU_SYSFS_ROOT='$WORK' CPU_PROC_CPUINFO='$WORK/proc/cpuinfo' CPU_THERMAL_ROOT='$WORK/thermal' CPU_DATA_ROOT='$WORK' CPU_SAFETY_FORCE_ROOT=true"
sh -c "$CPU_ENV sh '$CONTROLLER' apply performance" >/dev/null 2>&1 || :
RESET_OUTPUT="$(sh -c "$CPU_ENV sh '$RESET'" 2>&1)"
printf '%s\n' "$RESET_OUTPUT" | grep -q "CPU restore completed successfully" &&
    pass "emergency cpu-reset restores backups" || fail "emergency cpu-reset restores backups"
[ "$(cat "$WORK/cpufreq/policy-a55/scaling_max_freq")" = "1612000" ] &&
    pass "cpu-reset restored original frequency" || fail "cpu-reset restored original frequency"
[ ! -e "$WORK/runtime/cpu/original_policy-a55.conf" ] &&
    pass "cpu-reset removes only successful backup" || fail "cpu-reset removes only successful backup"

EMPTY_OUTPUT="$(CPU_SYSFS_ROOT="$WORK" CPU_PROC_CPUINFO="$WORK/proc/cpuinfo" \
    CPU_DATA_ROOT="$WORK" CPU_SAFETY_FORCE_ROOT=true sh "$RESET" 2>&1)"
printf '%s\n' "$EMPTY_OUTPUT" | grep -q "No CPU backups found" &&
    pass "cpu-reset does not invent settings" || fail "cpu-reset does not invent settings"

[ "$FAILURES" -eq 0 ] && { echo "All CPU reset tests passed."; exit 0; }
echo "$FAILURES CPU reset test(s) failed."
exit 1