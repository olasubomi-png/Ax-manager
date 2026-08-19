#!/usr/bin/env sh
# Phase 12 final-release contract: repository-local, read-only, and Termux-safe.
set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
VEGAS="$ROOT/bin/vegas"
AXGO="$ROOT/bin/axgo"
MANAGER="$ROOT/bin/plugin-manager"
GATE="$ROOT/bin/action-gate"
CONTROL="$ROOT/bin/control-plane"
DASHBOARD="$ROOT/AX-T615-GAME-OPTIMIZER/bin/dashboard"
AXGO_MODULE="$ROOT/AX-T615-GAME-OPTIMIZER/bin/axgo"
CAPABILITIES="$ROOT/release/capabilities.json"
RELEASE="$ROOT/RELEASE.md"
SAFETY="$ROOT/SAFETY-MODEL.md"
VERIFICATION="$ROOT/release/FINAL-VERIFICATION.md"
DASHBOARD_JS="$ROOT/AX-T615-GAME-OPTIMIZER/dashboard/assets/app.js"
TMP="${VEGAS_TEST_TMP:-$ROOT/tests/.tmp/final-release-$$}"
PASS=0
FAIL=0

cleanup() {
    rm -rf "$TMP"
    rmdir "$(dirname "$TMP")" 2>/dev/null || :
}
trap cleanup EXIT HUP INT TERM
mkdir -p "$TMP" || exit 1

pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$1" >&2; }
expect_success() { LABEL="$1"; shift; "$@" >"$TMP/command.out" 2>&1 && pass "$LABEL" || { fail "$LABEL"; cat "$TMP/command.out" >&2; }; }
expect_failure() { LABEL="$1"; shift; "$@" >"$TMP/command.out" 2>&1 && fail "$LABEL" || pass "$LABEL"; }
contains() { printf '%s\n' "$1" | grep -Fq "$2" && pass "$3" || fail "$3"; }

for program in "$VEGAS" "$AXGO" "$MANAGER" "$GATE" "$CONTROL" "$DASHBOARD" "$AXGO_MODULE"; do
    [ -x "$program" ] && pass "required executable is executable: ${program#$ROOT/}" || fail "required executable is executable: ${program#$ROOT/}"
done

[ -f "$RELEASE" ] && [ -f "$SAFETY" ] && [ -f "$CAPABILITIES" ] && [ -f "$VERIFICATION" ] && pass 'final release documents and metadata exist' || fail 'final release documents and metadata exist'
CAPABILITY_DATA=$(cat "$CAPABILITIES" 2>/dev/null || :)
contains "$CAPABILITY_DATA" '"release": "v1.0.0"' 'release metadata declares v1.0.0'
contains "$CAPABILITY_DATA" '"mode": "read_only_simulation_only"' 'release metadata declares read-only simulation-only mode'
contains "$CAPABILITY_DATA" '"real_action_layer": "NOT_IMPLEMENTED"' 'release metadata declares no real action layer'
contains "$CAPABILITY_DATA" '"browser_shell_bridge": false' 'release metadata declares no browser shell bridge'

expect_success 'VEGAS unified status route is fixed' sh "$VEGAS" status
expect_success 'VEGAS plugin health route is fixed' sh "$VEGAS" plugin health
expect_success 'VEGAS gaming status route is fixed' sh "$VEGAS" gaming status
expect_success 'VEGAS system status route is fixed' sh "$VEGAS" system status
expect_success 'VEGAS performance status route is fixed' sh "$VEGAS" performance status
expect_success 'VEGAS evidence status route is fixed' sh "$VEGAS" evidence status
expect_success 'VEGAS analysis status route is fixed' sh "$VEGAS" analysis status
expect_success 'VEGAS policy status route is fixed' sh "$VEGAS" policy status
expect_success 'VEGAS Action Safety Gate status route is fixed' sh "$VEGAS" action status
expect_success 'VEGAS Control Plane status route is fixed' sh "$VEGAS" control status

expect_success 'AXGO status compatibility route is fixed' sh "$AXGO" status
expect_success 'AXGO dashboard compatibility route is fixed' sh "$AXGO" dashboard
expect_success 'AXGO evidence compatibility route is fixed' sh "$AXGO" evidence
expect_success 'AXGO policy compatibility route is fixed' sh "$AXGO" policy
expect_success 'AXGO action compatibility route is fixed' sh "$AXGO" action
expect_success 'AXGO control compatibility route is fixed' sh "$AXGO" control

ACTION_SIMULATION=$(sh "$VEGAS" action simulate 2>/dev/null || :)
contains "$ACTION_SIMULATION" '"execution_mode":"SIMULATION_ONLY"' 'Action Safety Gate reports simulation-only mode'
contains "$ACTION_SIMULATION" '"real_action_execution":"NOT_AVAILABLE"' 'Action Safety Gate reports no execution capability'
contains "$ACTION_SIMULATION" '"hardware_writes":"NO"' 'Action Safety Gate reports no hardware-write capability'
CONTROL_SIMULATION=$(sh "$VEGAS" control simulate 2>/dev/null || :)
contains "$CONTROL_SIMULATION" '"simulation":true' 'Control Plane reports simulation-only result'
contains "$CONTROL_SIMULATION" '"executed":false' 'Control Plane reports no execution'
contains "$CONTROL_SIMULATION" '"hardware_changed":false' 'Control Plane reports no hardware change'

DASHBOARD_SNAPSHOT=$(sh "$DASHBOARD" snapshot 2>/dev/null || :)
contains "$DASHBOARD_SNAPSHOT" '"read_only":true' 'dashboard snapshot declares read-only data'
contains "$DASHBOARD_SNAPSHOT" '"simulation_only":true' 'dashboard snapshot exposes simulation-only control state'
contains "$DASHBOARD_SNAPSHOT" '"state":"UNKNOWN"' 'dashboard preserves unknown telemetry explicitly'
grep -Fq 'textContent' "$DASHBOARD_JS" 2>/dev/null && pass 'dashboard renders snapshot values through text bindings' || fail 'dashboard renders snapshot values through text bindings'
if grep -nE 'innerHTML[[:space:]]*=|insertAdjacentHTML|document\.write' "$DASHBOARD_JS" >/dev/null 2>&1; then
    fail 'dashboard contains no HTML injection sink'
else
    pass 'dashboard contains no HTML injection sink'
fi

expect_failure 'VEGAS rejects an unknown final-release command' sh "$VEGAS" release-apply
expect_failure 'VEGAS rejects surplus action arguments' sh "$VEGAS" action simulate extra
expect_failure 'AXGO rejects surplus control arguments' sh "$AXGO" control status extra
expect_failure 'AXGO rejects action-oriented CPU apply route' sh "$AXGO" cpu apply performance
expect_failure 'plugin manager rejects path traversal' sh "$MANAGER" validate ../../outside

STATIC_FILES="$VEGAS $AXGO $MANAGER $GATE $CONTROL $AXGO_MODULE"
if grep -nE '(^|[[:space:];])eval([[:space:];]|$)|setprop[[:space:]]|(^|[[:space:];])kill([[:space:];]|$)|(^|[[:space:];])pkill([[:space:];]|$)|sysctl[[:space:]]|>[[:space:]]*/(proc|sys)/|curl[[:space:]]|wget[[:space:]]|nc[[:space:]]' $STATIC_FILES >/dev/null 2>&1; then
    fail 'public release surfaces contain no forbidden execution, network, process, or hardware-write capability'
else
    pass 'public release surfaces contain no forbidden execution, network, process, or hardware-write capability'
fi

printf 'FINAL_RELEASE_TESTS: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
