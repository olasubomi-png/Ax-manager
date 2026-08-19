#!/usr/bin/env sh
# Phase 11 security contract: all checks are repository-local and no device control is attempted.
set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
VEGAS="$ROOT/bin/vegas"
MANAGER="$ROOT/bin/plugin-manager"
AXGO="$ROOT/bin/axgo"
GATE="$ROOT/bin/action-gate"
CONTROL="$ROOT/bin/control-plane"
REPORT="$ROOT/security/audit-report.json"
AUDIT_DOC="$ROOT/security/SECURITY-AUDIT.md"
DASHBOARD_JS="$ROOT/AX-T615-GAME-OPTIMIZER/dashboard/assets/app.js"
META="$ROOT/plugins/ax-t615-game-optimizer/plugin.json"
UNSAFE_META="$ROOT/tests/fixtures/plugins/unsafe/plugin.json"
REGISTRY="$ROOT/plugins/registry.json"
TMP="${VEGAS_TEST_TMP:-$ROOT/tests/.tmp/security-audit-$$}"
PASS=0
FAIL=0

cleanup() {
    [ -f "$TMP/plugin.json" ] && cp "$TMP/plugin.json" "$META"
    [ -f "$TMP/registry.json" ] && cp "$TMP/registry.json" "$REGISTRY"
    rm -rf "$TMP"
    rmdir "$(dirname "$TMP")" 2>/dev/null || :
}
trap cleanup EXIT HUP INT TERM
mkdir -p "$TMP" || exit 1
cp "$META" "$TMP/plugin.json"
cp "$REGISTRY" "$TMP/registry.json"

pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$1" >&2; }
expect_failure() { LABEL="$1"; shift; "$@" >/dev/null 2>&1 && fail "$LABEL" || pass "$LABEL"; }
contains() { printf '%s\n' "$1" | grep -Fq "$2" && pass "$3" || fail "$3"; }

STATIC_FILES="$VEGAS $MANAGER $AXGO $GATE $CONTROL $ROOT/plugins/ax-t615-game-optimizer/plugin.sh $ROOT/AX-T615-GAME-OPTIMIZER/bin/axgo"
if grep -nE '(^|[[:space:];])eval([[:space:];]|$)|setprop[[:space:]]|(^|[[:space:];])kill([[:space:];]|$)|(^|[[:space:];])pkill([[:space:];]|$)|sysctl[[:space:]]|>[[:space:]]*/(proc|sys)/|curl[[:space:]]|wget[[:space:]]|nc[[:space:]]' $STATIC_FILES >/dev/null 2>&1; then
    fail 'fixed production surfaces contain no forbidden execution, network, process, or hardware-write capability'
else
    pass 'fixed production surfaces contain no forbidden execution, network, process, or hardware-write capability'
fi

[ -f "$REPORT" ] && [ -f "$AUDIT_DOC" ] && pass 'machine-readable and human-readable security audit deliverables exist' || fail 'machine-readable and human-readable security audit deliverables exist'
REPORT_CONTENT=$(cat "$REPORT" 2>/dev/null || :)
contains "$REPORT_CONTENT" '"schema": "vegas-security-audit-v1"' 'audit report declares fixed schema'
contains "$REPORT_CONTENT" '"security_status": "PASS"' 'audit report declares passing security status'
contains "$REPORT_CONTENT" '"execution_model": "READ_ONLY_SIMULATION_ONLY"' 'audit report records simulation-only execution model'

expect_failure 'VEGAS rejects unknown top-level commands' sh "$VEGAS" arbitrary-command
expect_failure 'VEGAS rejects surplus control arguments' sh "$VEGAS" control status surplus
expect_failure 'VEGAS rejects surplus action arguments' sh "$VEGAS" action simulate surplus
expect_failure 'plugin manager rejects traversal plugin identifiers' sh "$MANAGER" validate ../../etc/passwd
expect_failure 'plugin manager rejects surplus invoke arguments' sh "$MANAGER" invoke system-observer snapshot "$TMP/untrusted" extra
expect_failure 'Action Safety Gate rejects surplus arguments' sh "$GATE" status surplus
expect_failure 'Control Plane rejects surplus arguments' sh "$CONTROL" snapshot surplus
expect_failure 'AXGO rejects CPU apply route' sh "$AXGO" cpu apply performance
expect_failure 'AXGO rejects reset route' sh "$AXGO" reset
AXGO_STATUS=$(sh "$AXGO" status 2>/dev/null || :)
contains "$AXGO_STATUS" 'AX-T615 concise hardware status (read-only)' 'AXGO preserves reviewed read-only status route'

cp "$UNSAFE_META" "$META"
UNSAFE=$(sh "$MANAGER" validate ax-t615-game-optimizer 2>&1 || :)
contains "$UNSAFE" 'PLUGIN_ERROR=FORBIDDEN_CAPABILITY' 'unsafe metadata is rejected before any adapter invocation'
cp "$TMP/plugin.json" "$META"

printf '%s\n' '{malformed-json' > "$META"
expect_failure 'malformed plugin metadata is rejected before adapter invocation' sh "$MANAGER" validate ax-t615-game-optimizer
cp "$TMP/plugin.json" "$META"

sed 's#plugins/ax-t615-game-optimizer#../untrusted-plugin#' "$TMP/registry.json" > "$REGISTRY"
expect_failure 'registry path traversal is rejected before adapter invocation' sh "$MANAGER" validate ax-t615-game-optimizer
cp "$TMP/registry.json" "$REGISTRY"

grep -Fq 'MAX_AUDIT_RECORDS=' "$GATE" 2>/dev/null && pass 'Action Safety Gate declares a bounded local audit limit' || fail 'Action Safety Gate declares a bounded local audit limit'
grep -Fq 'MAX_COMPONENT_BYTES=' "$CONTROL" 2>/dev/null && pass 'Control Plane declares bounded component-output limit' || fail 'Control Plane declares bounded component-output limit'
grep -Fq 'textContent' "$DASHBOARD_JS" 2>/dev/null && pass 'dashboard uses text-only bindings for snapshot values' || fail 'dashboard uses text-only bindings for snapshot values'
if grep -nE 'innerHTML[[:space:]]*=|insertAdjacentHTML|document\.write' "$DASHBOARD_JS" >/dev/null 2>&1; then
    fail 'dashboard contains no HTML injection rendering sink'
else
    pass 'dashboard contains no HTML injection rendering sink'
fi

printf 'SECURITY_AUDIT_TESTS: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
