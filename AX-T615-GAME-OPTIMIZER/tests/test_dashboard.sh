#!/usr/bin/env sh
# Step 12 test contract: validates a read-only dashboard exporter and static UI without invoking hardware-control paths.
set -u

TEST_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
MODULE_ROOT=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
FIXTURES="$MODULE_ROOT/tests/fixtures/orchestrator"
TMP="${STEP12_DASHBOARD_TEST_TMP:-$MODULE_ROOT/tests/.tmp/dashboard-$$}"
mkdir -p "$TMP" || exit 1
cleanup() {
    rm -rf "$TMP" "$MODULE_ROOT/dashboard/data/current-snapshot.json"
    rmdir "$(dirname "$TMP")" 2>/dev/null || :
}
trap cleanup EXIT HUP INT TERM

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
contains "$SNAPSHOT" '"decision":{"state":"balanced"' "healthy snapshot preserves orchestrator decision"
contains "$SNAPSHOT" '"forbidden_actions_blocked":"YES"' "snapshot exposes safety guard"
contains "$SNAPSHOT" '"blocked_actions":"write_proc,write_sys' "snapshot exposes blocked policy actions"
contains "$SNAPSHOT" '"plugins":{"system_observer":{' "snapshot exposes optional System Observer envelope"
contains "$SNAPSHOT" '"sensitive_information":"NOT_COLLECTED"' "System Observer dashboard envelope excludes sensitive information"
contains "$SNAPSHOT" '"performance_observer":{"schema":"1","source":"performance-observer-read-only"' "snapshot exposes optional Performance Observer envelope"
contains "$SNAPSHOT" '"observed_telemetry":"AX-T615_ORCHESTRATOR_EVIDENCE"' "Performance Observer dashboard envelope declares evidence provenance"
contains "$SNAPSHOT" '"evidence_engine":{"schema":"1","source":"vegas-inject-evidence-engine-read-only"' "snapshot exposes backward-compatible Evidence Engine envelope"
contains "$SNAPSHOT" '"classification":"HEALTHY"' "healthy telemetry remains healthy in Evidence Engine"
contains "$SNAPSHOT" '"analysis":{"schema":"1","source":"vegas-inject-bottleneck-engine-read-only"' "snapshot exposes backward-compatible intelligent analysis envelope"
contains "$SNAPSHOT" '"advisory_only":"YES"' "intelligent analysis remains advisory only"
contains "$SNAPSHOT" '"policy":{"schema":"1","source":"vegas-inject-policy-engine-read-only"' "snapshot exposes backward-compatible policy envelope"
contains "$SNAPSHOT" '"action_layer":"NOT_IMPLEMENTED"' "policy remains recommendation-only"
contains "$SNAPSHOT" '"action":{"schema":"1","source":"vegas-inject-controlled-action-engine"' "snapshot exposes backward-compatible controlled action envelope"
contains "$SNAPSHOT" '"dry_run_default":"YES"' "controlled action envelope keeps dry-run default"
contains "$SNAPSHOT" '"action_lock_default":"ENABLED"' "controlled action envelope keeps emergency lock default"
contains "$SNAPSHOT" '"action_gate":{"schema":"1","source":"vegas-inject-action-safety-gate"' "snapshot exposes simulation-only Action Safety Gate envelope"
contains "$SNAPSHOT" '"real_action_execution":"NOT_AVAILABLE"' "Action Safety Gate envelope blocks real execution"
contains "$SNAPSHOT" '"control_plane":{"schema":"1","component":"vegas-control-plane"' "snapshot exposes backward-compatible VEGAS Control Plane envelope"
contains "$SNAPSHOT" '"real_action_layer":"NOT_IMPLEMENTED"' "Control Plane envelope blocks real action layer"

CORE_SNAPSHOT=$(ORCH_EVIDENCE_FILE="$FIXTURES/healthy/evidence.env" AXGO_ROOT="$MODULE_ROOT" DASHBOARD_RUNTIME_DIR="$TMP/core-runtime" ORCH_RUNTIME_DIR="$TMP/core-orchestrator" sh "$MODULE_ROOT/bin/dashboard" core-snapshot)
contains "$CORE_SNAPSHOT" '"decision":{"state":"balanced"' "core snapshot preserves orchestrator decision"
contains "$CORE_SNAPSHOT" '"plugins":{}' "core snapshot omits duplicated observer envelopes"
contains "$CORE_SNAPSHOT" '"evidence_engine":{' "core snapshot retains fixed Evidence Engine envelope"
contains "$CORE_SNAPSHOT" '"analysis":{' "core snapshot retains fixed intelligent analysis envelope"
contains "$CORE_SNAPSHOT" '"policy":{' "core snapshot retains fixed policy envelope"
contains "$CORE_SNAPSHOT" '"action":{' "core snapshot retains fixed controlled-action envelope"
contains "$CORE_SNAPSHOT" '"action_gate":{' "core snapshot retains simulation-only Action Safety Gate envelope"
contains "$CORE_SNAPSHOT" '"control_plane":{' "core snapshot retains fixed Control Plane envelope"
not_contains "$CORE_SNAPSHOT" '"system_observer":{"schema"' "core snapshot excludes duplicated System Observer envelope data"
not_contains "$CORE_SNAPSHOT" '"performance_observer":{"schema"' "core snapshot excludes duplicated Performance Observer envelope data"

cp "$FIXTURES/healthy/evidence.env" "$TMP/evidence.env"
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
contains "$(cat "$MODULE_ROOT/dashboard/index.html")" 'Hardware control' "UI exposes the no-control boundary"
contains "$(cat "$MODULE_ROOT/dashboard/index.html")" 'Hardware control capabilities:' "UI explicitly states hardware controls are none"
contains "$(cat "$MODULE_ROOT/dashboard/assets/app.js")" 'raw.product === "VEGAS-inject"' "UI recognizes unified VEGAS snapshots"
contains "$(cat "$MODULE_ROOT/dashboard/assets/app.js")" 'textContent' "UI keeps unified values text-safe"
contains "$(cat "$MODULE_ROOT/dashboard/index.html")" 'Evidence quality ledger' "UI exposes evidence quality ledger"
contains "$(cat "$MODULE_ROOT/dashboard/assets/app.js")" 'evidenceEngineQuality' "UI renders Evidence Engine quality text-safely"
contains "$(cat "$MODULE_ROOT/dashboard/assets/app.js")" 'evidenceEngineFallbackReason' "UI renders conservative fallback rationale text-safely"
contains "$(cat "$MODULE_ROOT/dashboard/index.html")" 'Intelligent Analysis' "UI exposes the intelligent analysis section"
contains "$(cat "$MODULE_ROOT/dashboard/assets/app.js")" 'analysisRecommendation' "UI renders analysis recommendations text-safely"
contains "$(cat "$MODULE_ROOT/dashboard/index.html")" 'Policy &amp; Recommendations' "UI exposes the policy recommendations section"
contains "$(cat "$MODULE_ROOT/dashboard/assets/app.js")" 'Invalid policy section.' "UI rejects malformed policy envelopes"
contains "$(cat "$MODULE_ROOT/dashboard/assets/app.js")" 'policyRecommendation' "UI renders policy recommendations text-safely"
contains "$(cat "$MODULE_ROOT/dashboard/index.html")" 'Controlled Actions' "UI exposes controlled-action observability"
contains "$(cat "$MODULE_ROOT/dashboard/index.html")" 'LOCKED BY DEFAULT' "UI labels default controlled-action lock"
contains "$(cat "$MODULE_ROOT/dashboard/assets/app.js")" 'Invalid action section.' "UI rejects malformed controlled-action envelopes"
contains "$(cat "$MODULE_ROOT/dashboard/assets/app.js")" 'actionPlannedAction' "UI renders controlled-action plans text-safely"
not_contains "$(cat "$MODULE_ROOT/dashboard/index.html")" 'id="actionApply"' "UI exposes no action execution button"
contains "$(cat "$MODULE_ROOT/dashboard/index.html")" 'Action Safety Gate' "UI exposes simulation-only Action Safety Gate observability"
contains "$(cat "$MODULE_ROOT/dashboard/index.html")" 'SIMULATION ONLY' "UI labels Action Safety Gate simulation-only boundary"
contains "$(cat "$MODULE_ROOT/dashboard/assets/app.js")" 'Invalid action gate section.' "UI rejects malformed Action Safety Gate envelopes"
contains "$(cat "$MODULE_ROOT/dashboard/assets/app.js")" 'actionGateRecommendation' "UI renders Action Safety Gate recommendations text-safely"
not_contains "$(cat "$MODULE_ROOT/dashboard/index.html")" 'id="actionGateApply"' "UI exposes no Action Safety Gate execution button"
contains "$(cat "$MODULE_ROOT/dashboard/index.html")" 'VEGAS Control Plane' "UI exposes fixed Control Plane observability"
contains "$(cat "$MODULE_ROOT/dashboard/index.html")" 'cannot execute a device action' "UI labels Control Plane no-execution boundary"
contains "$(cat "$MODULE_ROOT/dashboard/assets/app.js")" 'Invalid control plane section.' "UI rejects malformed Control Plane envelopes"
contains "$(cat "$MODULE_ROOT/dashboard/assets/app.js")" 'controlPlaneRecommendation' "UI renders Control Plane recommendations text-safely"
not_contains "$(cat "$MODULE_ROOT/dashboard/index.html")" 'id="controlPlaneSimulate"' "UI exposes no Control Plane simulation button"

printf 'STEP12_DASHBOARD_TESTS: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
