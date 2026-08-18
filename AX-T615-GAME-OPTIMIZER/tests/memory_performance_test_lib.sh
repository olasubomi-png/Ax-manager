#!/usr/bin/env sh
set -u

TEST_DIR="${STEP7B_TEST_DIR:-$PWD/tests}"
MODULE_ROOT="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
FIXTURE_ROOT="$MODULE_ROOT/tests/fixtures/memory/combined"
TEST_TMP="${TEST_TMP:-$(mktemp -d 2>/dev/null || printf '%s/tests/.memory-performance-tmp' "$MODULE_ROOT") }"
TEST_TMP="$(printf '%s' "$TEST_TMP" | sed 's/[[:space:]]*$//')"
mkdir -p "$TEST_TMP"

setup_case() {
    CASE_NAME="$1"
    CASE_ROOT="$FIXTURE_ROOT/$CASE_NAME"
    [ -d "$CASE_ROOT" ] || { echo "missing combined fixture: $CASE_NAME" >&2; return 1; }
    RUNTIME_ROOT="$TEST_TMP/$CASE_NAME"
    rm -rf "$RUNTIME_ROOT"
    mkdir -p "$RUNTIME_ROOT"
    export AXGO_ROOT="$MODULE_ROOT"
    export AXGO_DATA_ROOT="$RUNTIME_ROOT"
    export MEMORY_PERFORMANCE_DATA_ROOT="$RUNTIME_ROOT"
    export MEMORY_PROC_ROOT="$CASE_ROOT/memory/proc"
    export MEMORY_SYS_ROOT="$CASE_ROOT/memory/sys"
    export MEMORY_PSI_FILE="$CASE_ROOT/memory/proc/pressure/memory"
    export MEMORY_SWAPS_FILE="$CASE_ROOT/memory/proc/swaps"
    export MEMORY_ZRAM_ROOT="$CASE_ROOT/memory/sys/block"
    export THERMAL_SYSFS_ROOT="$CASE_ROOT/thermal"
    export THERMAL_DATA_ROOT="$RUNTIME_ROOT/thermal-data"
    export THERMAL_RUNTIME_DIR="$RUNTIME_ROOT/thermal-data/runtime/thermal"
    export THERMAL_LOG_FILE="$RUNTIME_ROOT/thermal-data/logs/thermal.log"
    export THERMAL_GUARD_RECOMMENDATION=CONSERVATIVE
    export GPU_SKIP_THERMAL=true
}

set_case_roots() {
    CASE_NAME="$1"
    CASE_ROOT="$FIXTURE_ROOT/$CASE_NAME"
    [ -d "$CASE_ROOT" ] || { echo "missing combined fixture: $CASE_NAME" >&2; return 1; }
    export MEMORY_PROC_ROOT="$CASE_ROOT/memory/proc"
    export MEMORY_SYS_ROOT="$CASE_ROOT/memory/sys"
    export MEMORY_PSI_FILE="$CASE_ROOT/memory/proc/pressure/memory"
    export MEMORY_SWAPS_FILE="$CASE_ROOT/memory/proc/swaps"
    export MEMORY_ZRAM_ROOT="$CASE_ROOT/memory/sys/block"
    export THERMAL_SYSFS_ROOT="$CASE_ROOT/thermal"
}

run_perf() {
    sh "$MODULE_ROOT/bin/memory-performance" "$@"
}

run_axgo_perf() {
    sh "$MODULE_ROOT/bin/axgo" memory performance "$@"
}

assert_contains() {
    HAYSTACK="$1"; NEEDLE="$2"; LABEL="${3:-assertion}"
    printf '%s\n' "$HAYSTACK" | grep -Fq -- "$NEEDLE" || { echo "FAIL: $LABEL (missing: $NEEDLE)" >&2; printf '%s\n' "$HAYSTACK" >&2; return 1; }
}

assert_not_changed() {
    BEFORE="$1"; AFTER="$2"; LABEL="${3:-fixture immutability}"
    [ "$BEFORE" = "$AFTER" ] || { echo "FAIL: $LABEL" >&2; return 1; }
}

cleanup_cases() {
    rm -rf "$TEST_TMP"
}
