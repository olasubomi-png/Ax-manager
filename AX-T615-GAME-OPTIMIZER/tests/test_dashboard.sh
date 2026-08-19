#!/usr/bin/env sh
# Step 12 test contract: validates a read-only dashboard exporter and static UI without invoking hardware-control paths.
set -u

TEST_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
MODULE_ROOT=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
FIXTURES="$MODULE_ROOT/tests/fixtures/orchestrator"
TMP="${STEP12_DASHBOARD_TEST_TMP:-/tmp/axgo-dashboard-test-$$}"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$1" >&2; }
contains() { printf '%s\n' "$1" | grep -Fq "$2" && pass "$3" || fail "$3"; }
not_contains() { printf '%s\n' "$1" | grep -Fq "$2" && fail "$3" || pass "$3"; }

assert_file() { [ -f "$1" ] && pass "file exists: ${1#$MODULE_ROOT/}" || fail "file missing: $1"; }

assert_file "$MODULE_ROOT/bin/dashboard"
assert_file "$MODULE_ROOT/dashboard/index.html"
assert_file "$MODULE_ROOT/dashboard/assets/styles.css"
assert_file "$MODULE_ROOT/dashboard/assets/app.js"
assert_file "$MODULE_ROOT/dashboard/README.md"

if sh -n "$MODULE_ROOT/bin/dashboard" && node --check "$MODULE_ROOT/dashboard/assets/app.js" >/dev/null 2>&1; then
    pass "dashboard exporter and browser script syntax"
else
    fail "dashboard exporter and browser script syntax"
fi

PATH_OUTPUT=$(AXGO_ROOT="$MODULE_ROOT" sh "$MODULE_ROOT/bin/dashboard" path)
contains "$PATH_OUTPUT" "$MODULE_ROOT/dashboard/index.html" "dashboard path output"

SNAPSHOT=$(ORCH_EVIDENCE_FILE="$FIXTURES/healthy/evidence.env" AXGO_ROOT="$MODULE_ROOT" DASHBOARD_RUNTIME_DIR="$TMP/runtime" ORCH_RUNTIME_DIR="$TMP/orchestrator" sh "$MODULE_ROOT/bin/dashboard" snapshot)
contains "$SNAPSHOT" '"schema":"1"' "snapshot schema"
contains "$SNAPSHOT" '"source":"axmanager-read-only-cli"' "snapshot source"
contains "$SNAPSHOT" '"read_only":true' "snapshot marks read-only"
contains "$SNAPSHOT" '"state":"balanced"' "healthy snapshot preserves orchestrator decision"
contains "$SNAPSHOT" '"forbidden_actions_blocked":"YES"' "snapshot exposes safety guard"
contains "$SNAPSHOT" '"blocked_actions":"write_proc,write_sys' "snapshot exposes blocked policy actions"

EXPORT_ROOT="$TMP/export-root"
mkdir -p "$EXPORT_ROOT/dashboard/data"
cp "$FIXTURES/healthy/evidence.env" "$TMP/evidence.env"
cp "$MODULE_ROOT/bin/dashboard" "$TMP/dashboard"
EXPORT_OUTPUT=$(ORCH_EVIDENCE_FILE="$TMP/evidence.env" AXGO_ROOT="$MODULE_ROOT" DASHBOARD_RUNTIME_DIR="$TMP/export-runtime" ORCH_RUNTIME_DIR="$TMP/export-orchestrator" sh "$MODULE_ROOT/bin/dashboard" export)
contains "$EXPORT_OUTPUT" 'DASHBOARD_SNAPSHOT=' "export reports destination"
[ -f "$MODULE_ROOT/dashboard/data/current-snapshot.json" ] && { pass "export writes runtime snapshot"; rm -f "$MODULE_ROOT/dashboard/data/current-snapshot.json"; } || fail "export writes runtime snapshot"

STATIC_CONTENT=$(cat "$MODULE_ROOT/bin/dashboard" "$MODULE_ROOT/dashboard/assets/app.js" "$MODULE_ROOT/dashboard/index.html")
not_contains "$STATIC_CONTENT" 'eval(' "dashboard has no eval"
not_contains "$STATIC_CONTENT" 'innerHTML' "dashboard has no HTML injection sink"
not_contains "$STATIC_CONTENT" 'force-stop' "dashboard does not expose process termination"
not_contains "$STATIC_CONTENT" 'setprop ' "dashboard does not expose Android property writes"
not_contains "$STATIC_CONTENT" '/sys/' "dashboard does not expose sysfs writes"
not_contains "$STATIC_CONTENT" '/proc/' "dashboard does not expose procfs writes"
contains "$(cat "$MODULE_ROOT/dashboard/index.html")" 'No fabricated telemetry.' "UI states no fabricated telemetry"
contains "$(cat "$MODULE_ROOT/dashboard/index.html")" 'DRY-RUN ONLY' "UI labels dry-run"
contains "$(cat "$MODULE_ROOT/dashboard/index.html")" 'POLICY OUTPUT / NOT APPLIED' "UI labels policy output"

printf 'STEP12_DASHBOARD_TESTS: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
