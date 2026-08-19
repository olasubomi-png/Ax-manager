#!/usr/bin/env sh
# Phase 4 contract: unified VEGAS-inject observability is fixed, read-only, and Termux-safe.
set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
VEGAS="$ROOT/bin/vegas"
MANAGER="$ROOT/bin/plugin-manager"
PERFORMANCE_META="$ROOT/plugins/performance-observer/plugin.json"
DASHBOARD="$ROOT/AX-T615-GAME-OPTIMIZER/bin/dashboard"
DASHBOARD_APP="$ROOT/AX-T615-GAME-OPTIMIZER/dashboard/assets/app.js"
BOTTLENECK="$ROOT/bin/bottleneck-engine"
POLICY="$ROOT/bin/policy-engine"
HEALTHY="$ROOT/AX-T615-GAME-OPTIMIZER/tests/fixtures/orchestrator/healthy/evidence.env"
UNKNOWN="$ROOT/AX-T615-GAME-OPTIMIZER/tests/fixtures/orchestrator/unknown/evidence.env"
TMP="${VEGAS_UNIFIED_TEST_TMP:-$ROOT/tests/.tmp/vegas-unified-$$}"
PASS=0
FAIL=0

cleanup() {
    [ -f "$TMP/original-performance-plugin.json" ] && cp "$TMP/original-performance-plugin.json" "$PERFORMANCE_META"
    rm -rf "$TMP"
    rmdir "$(dirname "$TMP")" 2>/dev/null || :
}
trap cleanup EXIT HUP INT TERM
mkdir -p "$TMP" || exit 1
cp "$PERFORMANCE_META" "$TMP/original-performance-plugin.json"

pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$1" >&2; }
contains() { printf '%s\n' "$1" | grep -Fq "$2" && pass "$3" || fail "$3"; }
not_contains() { printf '%s\n' "$1" | grep -Fq "$2" && fail "$3" || pass "$3"; }
expect_failure() { LABEL="$1"; shift; "$@" >/dev/null 2>&1 && fail "$LABEL" || pass "$LABEL"; }

STATUS=$(ORCH_EVIDENCE_FILE="$HEALTHY" sh "$VEGAS" status)
contains "$STATUS" 'VEGAS-inject' 'unified status identifies the product'
contains "$STATUS" 'Platform: READY' 'unified status reports platform readiness'
contains "$STATUS" 'Plugins: 3' 'unified status reports all registered plugins'
contains "$STATUS" 'CPU:       35' 'unified status relays observed CPU evidence'
contains "$STATUS" 'Bottleneck analysis:' 'unified status reports advisory bottleneck analysis'
contains "$STATUS" 'Recommendation policy:' 'unified status reports advisory recommendation policy'
contains "$STATUS" 'VEGAS_INJECT=READY' 'unified status preserves machine-readable compatibility'

SNAPSHOT=$(ORCH_EVIDENCE_FILE="$HEALTHY" sh "$VEGAS" snapshot)
contains "$SNAPSHOT" '"schema":"1"' 'unified snapshot declares schema one'
contains "$SNAPSHOT" '"product":"VEGAS-inject"' 'unified snapshot declares product provenance'
contains "$SNAPSHOT" '"read_only":true' 'unified snapshot declares read-only mode'
contains "$SNAPSHOT" '"ax-t615-game-optimizer"' 'unified snapshot retains AX-T615 provenance'
contains "$SNAPSHOT" '"system-observer"' 'unified snapshot retains System Observer provenance'
contains "$SNAPSHOT" '"performance-observer"' 'unified snapshot retains Performance Observer provenance'
contains "$SNAPSHOT" '"cpu_utilization":"35"' 'unified snapshot relays fixture-backed gaming evidence'
contains "$SNAPSHOT" '"hardware_writes":false' 'unified snapshot aggregates no hardware writes'
contains "$SNAPSHOT" '"network_operations":false' 'unified snapshot aggregates no network operations'
contains "$SNAPSHOT" '"code_execution":false' 'unified snapshot aggregates no code execution'
contains "$SNAPSHOT" '"analysis":{"schema":"1"' 'unified snapshot includes read-only bottleneck analysis envelope'
contains "$SNAPSHOT" '"advisory_only":"YES"' 'unified snapshot marks bottleneck analysis advisory only'
contains "$SNAPSHOT" '"policy":{"schema":"1"' 'unified snapshot includes read-only policy envelope'
contains "$SNAPSHOT" '"action_layer":"NOT_IMPLEMENTED"' 'unified policy envelope excludes action layer'

INSPECT=$(sh "$VEGAS" inspect)
contains "$INSPECT" 'Plugin count: 3' 'unified inspect reports plugin count'
contains "$INSPECT" 'Safety classification: READ_ONLY_OBSERVABILITY' 'unified inspect reports safety classification'
contains "$INSPECT" 'Control capabilities: NONE' 'unified inspect reports no control capability'

CAPABILITIES=$(sh "$VEGAS" capabilities)
contains "$CAPABILITIES" 'OBSERVATION' 'unified capabilities group observations'
contains "$CAPABILITIES" 'POLICY' 'unified capabilities group policy outputs'
contains "$CAPABILITIES" 'Hardware control capabilities: NONE' 'unified capabilities explicitly deny hardware control'

HEALTH=$(sh "$VEGAS" plugin health)
contains "$HEALTH" 'VEGAS PLUGIN HEALTH' 'plugin health has a unified heading'
contains "$HEALTH" 'ax-t615-game-optimizer' 'plugin health covers AX-T615'
contains "$HEALTH" 'system-observer' 'plugin health covers System Observer'
contains "$HEALTH" 'performance-observer' 'plugin health covers Performance Observer'
not_contains "$HEALTH" 'FAIL' 'plugin health passes for registered safe plugins'

GAMING_STATUS=$(sh "$VEGAS" gaming status)
contains "$GAMING_STATUS" 'AX-T615 concise hardware status (read-only)' 'gaming status remains routed to AX-T615'
GAMING_SNAPSHOT=$(ORCH_EVIDENCE_FILE="$HEALTHY" sh "$VEGAS" gaming snapshot)
contains "$GAMING_SNAPSHOT" '"cpu_utilization":"35"' 'gaming snapshot uses authoritative AX-T615 evidence'
contains "$GAMING_SNAPSHOT" '"plugins":{}' 'gaming snapshot excludes duplicated observer envelopes'
GAMING_DASHBOARD=$(sh "$VEGAS" gaming dashboard path)
contains "$GAMING_DASHBOARD" '/AX-T615-GAME-OPTIMIZER/dashboard/index.html' 'gaming dashboard preserves fixed path routing'

SYSTEM_STATUS=$(sh "$VEGAS" system status)
contains "$SYSTEM_STATUS" 'PLUGIN_ID=system-observer' 'system status uses manager route'
SYSTEM_SNAPSHOT=$(sh "$VEGAS" system snapshot)
contains "$SYSTEM_SNAPSHOT" '"source":"system-observer-read-only"' 'system snapshot uses fixed observer adapter'
PERFORMANCE_STATUS=$(sh "$VEGAS" performance status)
contains "$PERFORMANCE_STATUS" 'PLUGIN_ID=performance-observer' 'performance status uses manager route'
PERFORMANCE_SNAPSHOT=$(ORCH_EVIDENCE_FILE="$HEALTHY" sh "$VEGAS" performance snapshot)
contains "$PERFORMANCE_SNAPSHOT" '"utilization":"35"' 'performance snapshot preserves observed CPU evidence'
ANALYSIS_STATUS=$(ORCH_EVIDENCE_FILE="$HEALTHY" sh "$VEGAS" analysis status)
contains "$ANALYSIS_STATUS" 'VEGAS-INJECT INTELLIGENT ANALYSIS' 'fixed analysis route exposes the bottleneck engine'
ANALYSIS_SNAPSHOT=$(ORCH_EVIDENCE_FILE="$HEALTHY" sh "$VEGAS" analysis snapshot)
contains "$ANALYSIS_SNAPSHOT" '"read_only":true' 'fixed analysis snapshot remains read-only'
POLICY_STATUS=$(ORCH_EVIDENCE_FILE="$HEALTHY" sh "$VEGAS" policy status)
contains "$POLICY_STATUS" 'VEGAS-INJECT POLICY & RECOMMENDATIONS' 'fixed policy route exposes the policy engine'
POLICY_SNAPSHOT=$(ORCH_EVIDENCE_FILE="$HEALTHY" sh "$VEGAS" policy snapshot)
contains "$POLICY_SNAPSHOT" '"read_only":true' 'fixed policy snapshot remains read-only'
expect_failure 'arbitrary policy route is rejected' sh "$VEGAS" policy ../../outside

AX_BEFORE=$(sh "$MANAGER" status ax-t615-game-optimizer)
SYSTEM_BEFORE=$(sh "$MANAGER" status system-observer)
PERFORMANCE_BEFORE=$(sh "$MANAGER" status performance-observer)
ORCH_EVIDENCE_FILE="$HEALTHY" sh "$VEGAS" snapshot >/dev/null
AX_AFTER=$(sh "$MANAGER" status ax-t615-game-optimizer)
SYSTEM_AFTER=$(sh "$MANAGER" status system-observer)
PERFORMANCE_AFTER=$(sh "$MANAGER" status performance-observer)
[ "$AX_BEFORE" = "$AX_AFTER" ] && pass 'unified aggregation does not alter AX-T615 lifecycle state' || fail 'unified aggregation does not alter AX-T615 lifecycle state'
[ "$SYSTEM_BEFORE" = "$SYSTEM_AFTER" ] && pass 'unified aggregation does not alter System Observer lifecycle state' || fail 'unified aggregation does not alter System Observer lifecycle state'
[ "$PERFORMANCE_BEFORE" = "$PERFORMANCE_AFTER" ] && pass 'unified aggregation does not alter Performance Observer lifecycle state' || fail 'unified aggregation does not alter Performance Observer lifecycle state'

UNKNOWN_STATUS=$(ORCH_EVIDENCE_FILE="$UNKNOWN" sh "$VEGAS" status)
contains "$UNKNOWN_STATUS" 'CPU:       UNKNOWN' 'unified status keeps unavailable CPU evidence unknown'
UNKNOWN_SNAPSHOT=$(ORCH_EVIDENCE_FILE="$UNKNOWN" sh "$VEGAS" snapshot)
contains "$UNKNOWN_SNAPSHOT" '"unavailable_telemetry":"UNKNOWN"' 'unified snapshot preserves unavailable telemetry provenance'

expect_failure 'unknown plugin is rejected' sh "$MANAGER" validate unknown-plugin
expect_failure 'unknown unified operation is rejected' sh "$VEGAS" unsupported-operation
expect_failure 'unknown gaming operation is rejected' sh "$VEGAS" gaming unsupported-operation
expect_failure 'arbitrary plugin path is rejected' sh "$VEGAS" plugin invoke performance-observer snapshot "$TMP/not-a-permitted-operation"

printf '%s\n' '{"id":"performance-observer","name":"Performance Observer","version":"1.0.0","description":"invalid","type":"gaming","entrypoint":"plugin.sh","capabilities":["status"],"read_only":false,"hardware_writes":false,"minimum_app_version":"1.0.0"}' > "$PERFORMANCE_META"
expect_failure 'malformed registered metadata is rejected' sh "$VEGAS" plugin health
MALFORMED_HEALTH=$(sh "$VEGAS" plugin health 2>&1 || :)
contains "$MALFORMED_HEALTH" 'Metadata: FAIL' 'health exposes malformed metadata failure'
cp "$TMP/original-performance-plugin.json" "$PERFORMANCE_META"

printf '%s\n' '{"id":"performance-observer","name":"Performance Observer","version":"1.0.0","description":"invalid","type":"gaming","entrypoint":"plugin.sh","capabilities":["status"],"read_only":true,"hardware_writes":false,"exec":"do-not-run","minimum_app_version":"1.0.0"}' > "$PERFORMANCE_META"
EXECUTABLE_METADATA=$(sh "$MANAGER" validate performance-observer 2>&1 || :)
contains "$EXECUTABLE_METADATA" 'PLUGIN_ERROR=EXECUTABLE_METADATA_REJECTED' 'executable metadata is rejected before dispatch'
cp "$TMP/original-performance-plugin.json" "$PERFORMANCE_META"

contains "$(printf '%s' "$TMP")" "$ROOT/tests/.tmp/" 'unified test uses a repository-local temporary directory'
not_contains "$(grep -nE 'eval[[:space:]]*\(|innerHTML|outerHTML|setprop|force-stop|/[[:space:]]*(proc|sys)/' "$DASHBOARD_APP" "$ROOT/AX-T615-GAME-OPTIMIZER/dashboard/index.html" 2>/dev/null || :)" 'innerHTML' 'dashboard source contains no arbitrary HTML injection'

STATIC_FILES="$ROOT/bin/vegas $ROOT/bin/plugin-manager $BOTTLENECK $POLICY $ROOT/plugins/ax-t615-game-optimizer/plugin.sh $DASHBOARD $DASHBOARD_APP"
if grep -nE '(^|[[:space:];])eval([[:space:];]|$)|setprop[[:space:]]|[[:space:]]kill([[:space:];]|$)|[[:space:]]pkill([[:space:];]|$)|>[[:space:]]*/(proc|sys)/|sysctl[[:space:]]|curl[[:space:]]|wget[[:space:]]|nc[[:space:]]' $STATIC_FILES >/dev/null 2>&1; then
    fail 'unified source contains no forbidden execution, network, process, or hardware writes'
else
    pass 'unified source contains no forbidden execution, network, process, or hardware writes'
fi

printf 'VEGAS_UNIFIED_TESTS: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
