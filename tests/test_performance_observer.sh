#!/usr/bin/env sh
# Performance Observer contract: fixed, independent, read-only telemetry normalization with no hardware or network controls.
set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
VEGAS="$ROOT/bin/vegas"
MANAGER="$ROOT/bin/plugin-manager"
PLUGIN="$ROOT/plugins/performance-observer/plugin.sh"
META="$ROOT/plugins/performance-observer/plugin.json"
FIXTURE="$ROOT/AX-T615-GAME-OPTIMIZER/tests/fixtures/orchestrator/healthy/evidence.env"
TMP="${PERFORMANCE_OBSERVER_TEST_TMP:-$ROOT/tests/.tmp/performance-observer-$$}"
PASS=0
FAIL=0

cleanup() {
    [ -f "$TMP/original-plugin.json" ] && cp "$TMP/original-plugin.json" "$META"
    rm -rf "$TMP"
    rmdir "$(dirname "$TMP")" 2>/dev/null || :
}
trap cleanup EXIT HUP INT TERM
mkdir -p "$TMP" || exit 1
cp "$META" "$TMP/original-plugin.json"

pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$1" >&2; }
contains() { printf '%s\n' "$1" | grep -Fq "$2" && pass "$3" || fail "$3"; }
not_contains() { printf '%s\n' "$1" | grep -Fq "$2" && fail "$3" || pass "$3"; }
expect_failure() { LABEL="$1"; shift; "$@" >/dev/null 2>&1 && fail "$LABEL" || pass "$LABEL"; }

[ -x "$PLUGIN" ] && pass 'fixed adapter has executable permission' || fail 'fixed adapter has executable permission'
sh -n "$PLUGIN" && pass 'fixed adapter has POSIX shell syntax' || fail 'fixed adapter has POSIX shell syntax'

VALIDATION=$(sh "$MANAGER" validate performance-observer)
contains "$VALIDATION" 'PLUGIN_VALID=YES' 'metadata validates'
contains "$VALIDATION" 'READ_ONLY=YES' 'metadata requires read-only mode'
contains "$VALIDATION" 'HARDWARE_WRITES=NO' 'metadata forbids hardware writes'

LIST=$(sh "$VEGAS" plugin list)
contains "$LIST" 'performance-observer | ENABLED | VALID | READ_ONLY' 'registry registers enabled Performance Observer'

STATUS=$(sh "$VEGAS" performance status)
contains "$STATUS" 'PLUGIN_NAME=Performance Observer' 'status reports plugin name'
contains "$STATUS" 'ENABLED=YES' 'status reports enabled state'
contains "$STATUS" 'OPERATIONS=status,capabilities,inspect,snapshot' 'status reports fixed operations'
contains "$STATUS" 'EVIDENCE_SOURCES=AX-T615_ORCHESTRATOR_EVIDENCE' 'status reports fixed evidence source'
contains "$STATUS" 'FORBIDDEN_ACTIONS_BLOCKED=YES' 'status reports safety boundary'

CAPABILITIES=$(sh "$VEGAS" performance capabilities)
contains "$CAPABILITIES" 'CAPABILITIES=status,capabilities,inspect,snapshot' 'capabilities limits adapter operations'
contains "$CAPABILITIES" 'EVIDENCE_CATEGORIES=cpu,gpu,memory,thermal,fps,battery,power' 'capabilities lists evidence categories'
not_contains "$CAPABILITIES" 'write_' 'capabilities expose no control operations'

INSPECT=$(sh "$VEGAS" performance inspect)
contains "$INSPECT" 'PLUGIN_VERSION=1.0.0' 'inspect reports version'
contains "$INSPECT" 'SUPPORTED_EVIDENCE=cpu,gpu,memory,thermal,fps,battery,power' 'inspect reports supported evidence categories'
contains "$INSPECT" 'DERIVED_VALUES=NONE' 'inspect documents no derived values'
not_contains "$INSPECT" 'AXGO_ROOT=' 'inspect exposes no filesystem path'

SNAPSHOT=$(ORCH_EVIDENCE_FILE="$FIXTURE" sh "$VEGAS" performance snapshot)
contains "$SNAPSHOT" '"schema":"1"' 'snapshot emits schema version'
contains "$SNAPSHOT" '"read_only":true' 'snapshot declares read-only mode'
contains "$SNAPSHOT" '"source":"performance-observer-read-only"' 'snapshot identifies read-only source'
contains "$SNAPSHOT" '"utilization":"35"' 'snapshot relays observed CPU utilization'
contains "$SNAPSHOT" '"temperature_c":"39"' 'snapshot relays observed thermal temperature'
contains "$SNAPSHOT" '"value":"60"' 'snapshot relays observed FPS'
contains "$SNAPSHOT" '"estimated_watts":"3.31"' 'snapshot relays observed power evidence'
contains "$SNAPSHOT" '"observed_telemetry":"AX-T615_ORCHESTRATOR_EVIDENCE"' 'snapshot declares evidence provenance'
contains "$SNAPSHOT" '"derived_values":"NONE"' 'snapshot does not fabricate derived values'
contains "$SNAPSHOT" '"process_control":"NOT_AVAILABLE"' 'snapshot declares no process-control capability'

SECOND_SNAPSHOT=$(ORCH_EVIDENCE_FILE="$FIXTURE" sh "$VEGAS" performance snapshot)
[ "$SNAPSHOT" = "$SECOND_SNAPSHOT" ] && pass 'snapshot structure is deterministic for fixed evidence' || fail 'snapshot structure is deterministic for fixed evidence'
UNAVAILABLE=$(ORCH_EVIDENCE_FILE="$TMP/missing-evidence.env" sh "$VEGAS" performance snapshot)
contains "$UNAVAILABLE" '"utilization":"UNKNOWN"' 'unavailable CPU evidence is explicit'
contains "$UNAVAILABLE" '"unavailable_telemetry":"UNKNOWN"' 'unavailable telemetry provenance is explicit'

AX_BEFORE=$(sh "$MANAGER" status ax-t615-game-optimizer)
sh "$VEGAS" performance inspect >/dev/null
AX_AFTER=$(sh "$MANAGER" status ax-t615-game-optimizer)
[ "$AX_BEFORE" = "$AX_AFTER" ] && pass 'Performance Observer preserves AX-T615 lifecycle isolation' || fail 'Performance Observer preserves AX-T615 lifecycle isolation'
SYSTEM_BEFORE=$(sh "$MANAGER" status system-observer)
sh "$VEGAS" performance snapshot >/dev/null
SYSTEM_AFTER=$(sh "$MANAGER" status system-observer)
[ "$SYSTEM_BEFORE" = "$SYSTEM_AFTER" ] && pass 'Performance Observer preserves System Observer lifecycle isolation' || fail 'Performance Observer preserves System Observer lifecycle isolation'

expect_failure 'unknown Performance Observer operation is rejected' sh "$VEGAS" performance unknown-operation
expect_failure 'arbitrary Performance Observer argument is rejected' sh "$MANAGER" invoke performance-observer snapshot "$TMP/arbitrary-path"
expect_failure 'unknown plugin remains rejected' sh "$MANAGER" validate no-such-plugin

cp "$TMP/original-plugin.json" "$META"
sed 's/"read_only": true/"read_only": false/' "$TMP/original-plugin.json" > "$META"
MALFORMED=$(sh "$MANAGER" validate performance-observer 2>&1 || :)
contains "$MALFORMED" 'PLUGIN_ERROR=READ_ONLY_REQUIRED' 'malformed metadata is rejected'

cp "$TMP/original-plugin.json" "$META"
sed 's/"minimum_app_version"/"command": "do-not-run", "minimum_app_version"/' "$TMP/original-plugin.json" > "$META"
EXECUTABLE_METADATA=$(sh "$MANAGER" validate performance-observer 2>&1 || :)
contains "$EXECUTABLE_METADATA" 'PLUGIN_ERROR=EXECUTABLE_METADATA_REJECTED' 'executable metadata is rejected'
not_contains "$EXECUTABLE_METADATA" 'do-not-run' 'executable metadata is never executed'
cp "$TMP/original-plugin.json" "$META"

STATIC_CONTENT=$(cat "$PLUGIN" "$META")
if grep -nE '(^|[[:space:];])eval([[:space:];]|$)|(^|[^[:alnum:]_])exec([^[:alnum:]_]|$)|setprop[[:space:]]|[[:space:]]kill([[:space:];]|$)|[[:space:]]pkill([[:space:];]|$)|>[[:space:]]*/(proc|sys)/|sysctl[[:space:]]|(^|[^[:alnum:]_])(curl|wget|nc)([^[:alnum:]_]|$)' "$PLUGIN" >/dev/null 2>&1; then
    fail 'adapter has no unsafe execution, hardware-write, process, or network constructs'
else
    pass 'adapter has no unsafe execution, hardware-write, process, or network constructs'
fi
not_contains "$STATIC_CONTENT" '"command"' 'metadata has no command field'
not_contains "$STATIC_CONTENT" '"shell"' 'metadata has no shell field'
not_contains "$STATIC_CONTENT" '"path"' 'metadata has no arbitrary path field'

printf 'PERFORMANCE_OBSERVER_TESTS: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
