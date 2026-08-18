#!/system/bin/sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0" 2>/dev/null)" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
WORK="${TMPDIR:-/tmp}/axgo-gpu-apply.$$"
FIXTURE="$WORK/fixture"
DATA="$WORK/data"
CONTROLLER="$ROOT_DIR/bin/gpu-controller"
RESET="$ROOT_DIR/bin/gpu-reset"
FAILURES=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
cleanup_apply_fixture() { rm -rf "$WORK"; }
setup_apply_fixture() {
    rm -rf "$WORK"
    mkdir -p "$WORK" "$DATA"
    cp -R "$ROOT_DIR/tests/fixtures/gpu/available" "$FIXTURE"
    printf '%s\n' 500000000 > "$FIXTURE/class/devfreq/mali-g57/target_freq"
}
run_gpu_apply() {
    env AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$DATA" GPU_SYSFS_ROOT="$FIXTURE" \
        GPU_PROPERTIES_FILE="$FIXTURE/properties" GPU_LOG_FILE="$DATA/logs/gpu.log" \
        THERMAL_GUARD_RECOMMENDATION="${THERMAL_GUARD_RECOMMENDATION:-BOOST}" \
        THERMAL_GUARD_STATE="${THERMAL_GUARD_STATE:-NORMAL}" \
        GPU_SAFETY_FORCE_ROOT="${GPU_SAFETY_FORCE_ROOT:-true}" \
        GPU_APPLY_TEST_MODE="${GPU_APPLY_TEST_MODE:-true}" \
        GPU_ALLOW_FIXTURE_APPLY="${GPU_ALLOW_FIXTURE_APPLY:-true}" \
        GPU_GOVERNOR_CONTROL="${GPU_GOVERNOR_CONTROL:-true}" \
        GPU_FREQUENCY_CONTROL="${GPU_FREQUENCY_CONTROL:-true}" \
        GPU_TEST_GOVERNOR="${GPU_TEST_GOVERNOR:-performance}" \
        GPU_TEST_FREQUENCY="${GPU_TEST_FREQUENCY:-400000000}" \
        GPU_TEST_FREQUENCY_NODE="$FIXTURE/class/devfreq/mali-g57/target_freq" \
        GPU_TEST_FAIL_AFTER_GOVERNOR="${GPU_TEST_FAIL_AFTER_GOVERNOR:-false}" \
        sh "$CONTROLLER" "$@"
}
run_gpu_reset() {
    env AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$DATA" GPU_SYSFS_ROOT="$FIXTURE" \
        GPU_PROPERTIES_FILE="$FIXTURE/properties" GPU_LOG_FILE="$DATA/logs/gpu.log" \
        GPU_SAFETY_FORCE_ROOT="${GPU_SAFETY_FORCE_ROOT:-true}" \
        GPU_APPLY_TEST_MODE=true GPU_ALLOW_FIXTURE_APPLY=true sh "$RESET" "$@"
}
