#!/usr/bin/env sh
set -u

TEST_ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." 2>/dev/null && pwd)"
STEP8_ROOT="$TEST_ROOT"
BIN_DIR="$STEP8_ROOT/bin"
FIXTURE_DIR="$STEP8_ROOT/tests/fixtures"
TMP_ROOT=""

step8_setup() {
    TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/axgo-step8.XXXXXX")"
    mkdir -p "$TMP_ROOT/coord/config" "$TMP_ROOT/coord/runtime" "$TMP_ROOT/coord/logs" "$TMP_ROOT/runtime"
    cp "$STEP8_ROOT/config/memory-policy.json" "$TMP_ROOT/coord/config/memory-policy.json" 2>/dev/null || :
    cp "$STEP8_ROOT/config/thermal-policy.json" "$TMP_ROOT/coord/config/thermal-policy.json" 2>/dev/null || :
    export AXGO_DATA_ROOT="$TMP_ROOT/coord"
    export FPS_RUNTIME_DIR="$TMP_ROOT/runtime/fps"
    export FPS_LOG_FILE="$TMP_ROOT/fps.log"
    export DISPLAY_LOG_FILE="$TMP_ROOT/display.log"
    export MEMORY_PERFORMANCE_LOG="$TMP_ROOT/memory-performance.log"
    export THERMAL_LOG_FILE="$TMP_ROOT/thermal.log"
    mkdir -p "$FPS_RUNTIME_DIR"
}

step8_cleanup() { [ -n "$TMP_ROOT" ] && rm -rf "$TMP_ROOT"; }
step8_fail() { echo "FAIL: $*" >&2; step8_cleanup; exit 1; }
step8_pass() { echo "PASS: $*"; }
step8_assert_contains() { TEXT="$1"; NEEDLE="$2"; LABEL="${3:-$2}"; printf '%s\n' "$TEXT" | grep -Fq "$NEEDLE" || step8_fail "$LABEL"; }
step8_assert_not_contains() { TEXT="$1"; NEEDLE="$2"; LABEL="${3:-unexpected $2}"; printf '%s\n' "$TEXT" | grep -Fq "$NEEDLE" && step8_fail "$LABEL" || :; }
step8_assert_file_missing() { [ ! -e "$1" ] || step8_fail "file still exists: $1"; }
step8_fixture_hash() { find "$1" -type f -print0 2>/dev/null | sort -z | xargs -0 sha256sum 2>/dev/null | sha256sum | awk '{print $1}'; }
step8_run_fps() { FPS_DATA_ROOT="$1" DISPLAY_DATA_ROOT="$2" FPS_PACKAGE="${3:-}" sh "$BIN_DIR/fps-controller" analyze; }
step8_run_display() { DISPLAY_DATA_ROOT="$1" sh "$BIN_DIR/display-controller" "$2"; }
