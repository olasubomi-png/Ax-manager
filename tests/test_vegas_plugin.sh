#!/usr/bin/env sh
# VEGAS-inject plugin registry and compatibility tests. No Android hardware access is required.
set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
MANAGER="$ROOT/bin/plugin-manager"
VEGAS="$ROOT/bin/vegas"
AXGO="$ROOT/bin/axgo"
META="$ROOT/plugins/ax-t615-game-optimizer/plugin.json"
SYSTEM_META="$ROOT/plugins/system-observer/plugin.json"
PERFORMANCE_META="$ROOT/plugins/performance-observer/plugin.json"
FIXTURES="$ROOT/tests/fixtures/plugins"
TMP="${VEGAS_TEST_TMP:-$ROOT/tests/.tmp/vegas-plugin-$$}"
PASS=0
FAIL=0

cleanup() {
    [ -f "$TMP/original-plugin.json" ] && cp "$TMP/original-plugin.json" "$META"
    [ -f "$TMP/original-performance-plugin.json" ] && cp "$TMP/original-performance-plugin.json" "$PERFORMANCE_META"
    rm -rf "$TMP"
    rmdir "$(dirname "$TMP")" 2>/dev/null || :
}
trap cleanup EXIT HUP INT TERM
mkdir -p "$TMP" || exit 1
cp "$META" "$TMP/original-plugin.json"
cp "$PERFORMANCE_META" "$TMP/original-performance-plugin.json"

pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$1" >&2; }
contains() { printf '%s\n' "$1" | grep -Fq "$2" && pass "$3" || fail "$3"; }
not_contains() { printf '%s\n' "$1" | grep -Fq "$2" && fail "$3" || pass "$3"; }
expect_failure() { LABEL="$1"; shift; "$@" >/dev/null 2>&1 && fail "$LABEL" || pass "$LABEL"; }

VALIDATION=$(sh "$MANAGER" validate ax-t615-game-optimizer)
contains "$VALIDATION" 'PLUGIN_VALID=YES' 'registered plugin validates'
contains "$VALIDATION" 'READ_ONLY=YES' 'plugin declares read-only mode'
contains "$VALIDATION" 'HARDWARE_WRITES=NO' 'plugin blocks hardware writes'
contains "$VALIDATION" 'FORBIDDEN_ACTIONS_BLOCKED=YES' 'plugin blocks forbidden operations'

LIST=$(sh "$MANAGER" list)
contains "$LIST" 'ax-t615-game-optimizer | ENABLED | VALID | READ_ONLY' 'plugin list exposes lifecycle and safety state'
contains "$LIST" 'system-observer | ENABLED | VALID | READ_ONLY' 'plugin list exposes isolated observer lifecycle and safety state'
contains "$LIST" 'performance-observer | ENABLED | VALID | READ_ONLY' 'plugin list exposes Performance Observer lifecycle and safety state'
INFO=$(sh "$MANAGER" info ax-t615-game-optimizer)
contains "$INFO" 'PLUGIN_ENTRYPOINT=plugin.sh (fixed allowlist)' 'metadata entrypoint is fixed'
CAPABILITIES=$(sh "$MANAGER" capabilities ax-t615-game-optimizer)
contains "$CAPABILITIES" 'dashboard,dry-run' 'plugin exposes dashboard and dry-run capabilities'

STATUS=$(sh "$MANAGER" status ax-t615-game-optimizer)
contains "$STATUS" 'LIFECYCLE=ENABLED' 'plugin lifecycle reports enabled'
contains "$STATUS" 'AVAILABILITY=AVAILABLE' 'plugin lifecycle reports available'

VEGAS_STATUS=$(sh "$VEGAS" status)
contains "$VEGAS_STATUS" 'VEGAS_INJECT=READY' 'main CLI reports ready status'
contains "$VEGAS_STATUS" 'PLUGINS_VALID=3' 'main CLI reports validated plugin count'
DASHBOARD_PATH=$(sh "$VEGAS" gaming dashboard path)
contains "$DASHBOARD_PATH" '/AX-T615-GAME-OPTIMIZER/dashboard/index.html' 'gaming dashboard resolves existing dashboard'
DRY_RUN=$(sh "$VEGAS" gaming dry-run)
contains "$DRY_RUN" 'HARDWARE_WRITES_PERFORMED=NO' 'plugin dry-run remains recommendation-only'

AXGO_STATUS=$(sh "$AXGO" status)
contains "$AXGO_STATUS" 'AX-T615 concise hardware status (read-only)' 'compatibility AXGO wrapper preserves direct status'

SYSTEM_VALIDATION=$(sh "$MANAGER" validate system-observer)
contains "$SYSTEM_VALIDATION" 'PLUGIN_VALID=YES' 'System Observer metadata validates independently'
SYSTEM_STATUS=$(sh "$VEGAS" system status)
contains "$SYSTEM_STATUS" 'PLUGIN_STATUS=AVAILABLE' 'System Observer lifecycle reports available'
contains "$SYSTEM_STATUS" 'TELEMETRY_POLICY=NON_SENSITIVE_ONLY' 'System Observer declares bounded telemetry policy'
SYSTEM_SNAPSHOT=$(sh "$VEGAS" system snapshot)
contains "$SYSTEM_SNAPSHOT" '"source":"system-observer-read-only"' 'System Observer emits a fixed read-only snapshot'
contains "$SYSTEM_SNAPSHOT" '"sensitive_information":"NOT_COLLECTED"' 'System Observer snapshot documents sensitive-data exclusion'
not_contains "$SYSTEM_SNAPSHOT" '"credentials"' 'System Observer snapshot excludes credentials'
not_contains "$SYSTEM_SNAPSHOT" '"account"' 'System Observer snapshot excludes account data'
AX_STATUS_BEFORE=$(sh "$MANAGER" status ax-t615-game-optimizer)
sh "$MANAGER" invoke system-observer inspect >/dev/null
AX_STATUS_AFTER=$(sh "$MANAGER" status ax-t615-game-optimizer)
[ "$AX_STATUS_BEFORE" = "$AX_STATUS_AFTER" ] && pass 'System Observer invocation does not alter AX-T615 lifecycle output' || fail 'System Observer invocation does not alter AX-T615 lifecycle output'
expect_failure 'System Observer rejects arbitrary operations' sh "$MANAGER" invoke system-observer unknown-operation

PERFORMANCE_VALIDATION=$(sh "$MANAGER" validate performance-observer)
contains "$PERFORMANCE_VALIDATION" 'PLUGIN_VALID=YES' 'Performance Observer metadata validates independently'
PERFORMANCE_STATUS=$(sh "$VEGAS" performance status)
contains "$PERFORMANCE_STATUS" 'PLUGIN_STATUS=AVAILABLE' 'Performance Observer lifecycle reports available'
contains "$PERFORMANCE_STATUS" 'SAFETY_CLASSIFICATION=READ_ONLY_OBSERVABILITY' 'Performance Observer declares read-only safety classification'
PERFORMANCE_CAPABILITIES=$(sh "$VEGAS" performance capabilities)
contains "$PERFORMANCE_CAPABILITIES" 'OBSERVATION_CAPABILITIES=read_cpu,read_gpu,read_memory,read_thermal,read_fps,read_battery,read_power' 'Performance Observer exposes only bounded observation categories'
PERFORMANCE_SNAPSHOT=$(sh "$VEGAS" performance snapshot)
contains "$PERFORMANCE_SNAPSHOT" '"source":"performance-observer-read-only"' 'Performance Observer emits a fixed read-only snapshot'
contains "$PERFORMANCE_SNAPSHOT" '"derived_values":"NONE"' 'Performance Observer identifies no derived telemetry'
contains "$PERFORMANCE_SNAPSHOT" '"network_access":"NOT_AVAILABLE"' 'Performance Observer declares no network capability'
AX_STATUS_BEFORE=$(sh "$MANAGER" status ax-t615-game-optimizer)
sh "$MANAGER" invoke performance-observer inspect >/dev/null
AX_STATUS_AFTER=$(sh "$MANAGER" status ax-t615-game-optimizer)
[ "$AX_STATUS_BEFORE" = "$AX_STATUS_AFTER" ] && pass 'Performance Observer invocation does not alter AX-T615 lifecycle output' || fail 'Performance Observer invocation does not alter AX-T615 lifecycle output'
SYSTEM_STATUS_BEFORE=$(sh "$MANAGER" status system-observer)
sh "$MANAGER" invoke performance-observer snapshot >/dev/null
SYSTEM_STATUS_AFTER=$(sh "$MANAGER" status system-observer)
[ "$SYSTEM_STATUS_BEFORE" = "$SYSTEM_STATUS_AFTER" ] && pass 'Performance Observer invocation does not alter System Observer lifecycle output' || fail 'Performance Observer invocation does not alter System Observer lifecycle output'
expect_failure 'Performance Observer rejects arbitrary operations' sh "$MANAGER" invoke performance-observer unknown-operation
expect_failure 'Performance Observer rejects arbitrary operation arguments' sh "$MANAGER" invoke performance-observer snapshot "$TMP/not-an-operation"

expect_failure 'unknown plugins are rejected' sh "$MANAGER" validate unknown-plugin

cp "$FIXTURES/invalid/plugin.json" "$META"
INVALID=$(sh "$MANAGER" validate ax-t615-game-optimizer 2>&1 || :)
contains "$INVALID" 'PLUGIN_ERROR=READ_ONLY_REQUIRED' 'metadata without read-only declaration is rejected'

cp "$FIXTURES/unsafe/plugin.json" "$META"
UNSAFE=$(sh "$MANAGER" validate ax-t615-game-optimizer 2>&1 || :)
contains "$UNSAFE" 'PLUGIN_ERROR=FORBIDDEN_CAPABILITY' 'forbidden metadata capability is rejected before execution'
not_contains "$UNSAFE" 'do-not-run' 'unsafe metadata is never executed'

cp "$TMP/original-plugin.json" "$META"

STATIC_FILES="$ROOT/bin/vegas $ROOT/bin/plugin-manager $ROOT/bin/axgo $ROOT/plugins/ax-t615-game-optimizer/plugin.sh $ROOT/plugins/system-observer/plugin.sh $ROOT/plugins/performance-observer/plugin.sh"
if grep -nE '(^|[[:space:];])eval([[:space:];]|$)|setprop[[:space:]]|[[:space:]]kill([[:space:];]|$)|[[:space:]]pkill([[:space:];]|$)|>[[:space:]]*/(proc|sys)/|sysctl[[:space:]]' $STATIC_FILES >/dev/null 2>&1; then
    fail 'new VEGAS executable sources contain no forbidden execution or hardware writes'
else
    pass 'new VEGAS executable sources contain no forbidden execution or hardware writes'
fi

printf 'VEGAS_PLUGIN_TESTS: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
