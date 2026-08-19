#!/usr/bin/env sh
set -u

TEST_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
MODULE_ROOT=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
FIXTURE_ROOT="$MODULE_ROOT/tests/fixtures/orchestrator"
TEST_TMP="${STEP11_TEST_TMP:-/tmp/axgo-step11-tests-$$}"
mkdir -p "$TEST_TMP"

PASS_COUNT=0
FAIL_COUNT=0

pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf 'FAIL: %s\n' "$1" >&2; }
assert_contains() { HAYSTACK="$1"; NEEDLE="$2"; LABEL="${3:-contains}"; printf '%s\n' "$HAYSTACK" | grep -Fq "$NEEDLE" && pass "$LABEL" || fail "$LABEL (missing: $NEEDLE)"; }
assert_not_contains() { HAYSTACK="$1"; NEEDLE="$2"; LABEL="${3:-not-contains}"; if printf '%s\n' "$HAYSTACK" | grep -Fq "$NEEDLE"; then fail "$LABEL (unexpected: $NEEDLE)"; else pass "$LABEL"; fi; }
assert_equal() { ACTUAL="$1"; EXPECTED="$2"; LABEL="${3:-equal}"; if [ "$ACTUAL" = "$EXPECTED" ]; then pass "$LABEL"; else fail "$LABEL (expected '$EXPECTED', got '$ACTUAL')"; fi; }
assert_success() { LABEL="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$LABEL"; else fail "$LABEL (command failed)"; fi; }

fixture_env() {
    NAME="$1"
    export ORCH_EVIDENCE_FILE="$FIXTURE_ROOT/$NAME/evidence.env"
    export ORCH_RUNTIME_DIR="$TEST_TMP/runtime-$NAME"
    export ORCH_LOG_FILE="$TEST_TMP/log-$NAME/orchestrator.log"
    export ORCH_DATA_ROOT="$TEST_TMP/data-$NAME"
    export AXGO_DATA_ROOT="$ORCH_DATA_ROOT"
    export ORCH_DRY_RUN=YES
    export ORCH_INTERVAL=0
    export ORCH_DURATION=1
    rm -rf "$ORCH_RUNTIME_DIR" "$ORCH_DATA_ROOT" "$TEST_TMP/log-$NAME"
    mkdir -p "$ORCH_RUNTIME_DIR" "$ORCH_DATA_ROOT"
}

reset_env() {
    unset ORCH_EVIDENCE_FILE ORCH_RUNTIME_DIR ORCH_LOG_FILE ORCH_DATA_ROOT AXGO_DATA_ROOT ORCH_DRY_RUN ORCH_INTERVAL ORCH_DURATION
}

orchestrator() { AXGO_ROOT="$MODULE_ROOT" sh "$MODULE_ROOT/bin/orchestrator" "$@"; }
evidence() { ORCH_EVIDENCE_FILE="$ORCH_EVIDENCE_FILE" sh "$MODULE_ROOT/bin/orchestrator-evidence"; }
decision() { evidence > "$TEST_TMP/current-evidence.env"; ORCH_EVIDENCE_FILE="$TEST_TMP/current-evidence.env" sh "$MODULE_ROOT/bin/orchestrator-decision"; }
axgo() { AXGO_ROOT="$MODULE_ROOT" sh "$MODULE_ROOT/bin/axgo" "$@"; }

fixture_checksum() {
    find "$FIXTURE_ROOT" -type f -print | sort | while IFS= read -r FILE; do sha256sum "$FILE"; done
}

cleanup_step11_test() {
    reset_env
    rm -rf "$TEST_TMP"
}
