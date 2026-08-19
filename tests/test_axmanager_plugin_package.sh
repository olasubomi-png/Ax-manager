#!/usr/bin/env sh
# Phase 13 AxManager package contract: repository-local, read-only, and Termux-safe.
set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
BUILD="$ROOT/scripts/build-axmanager-plugin.sh"
TEMPLATE="$ROOT/packaging/axmanager-vegas-inject"
DIST="$ROOT/dist/vegas-inject"
ZIPFILE="$ROOT/dist/vegas-inject.zip"
GUIDE="$ROOT/docs/AXMANAGER-PLUGIN.md"
TMP="${VEGAS_TEST_TMP:-$ROOT/tests/.tmp/axmanager-package-$$}"
EXTRACT="$TMP/extract"
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
contains() { printf '%s\n' "$1" | grep -Fq "$2" && pass "$3" || fail "$3"; }
rejects() { "$@" >"$TMP/reject.out" 2>&1 && fail "$1" || pass "$1"; }

sh -n "$BUILD" "$TEMPLATE/action.sh" "$TEMPLATE/uninstall.sh" && pass 'package scripts pass POSIX syntax validation' || fail 'package scripts pass POSIX syntax validation'
sh "$BUILD" >"$TMP/build.out" 2>&1 && pass 'package build succeeds' || { fail 'package build succeeds'; cat "$TMP/build.out" >&2; }

[ -f "$ZIPFILE" ] && [ -d "$DIST" ] && pass 'real AxManager module tree and ZIP exist' || fail 'real AxManager module tree and ZIP exist'
unzip -t "$ZIPFILE" >"$TMP/unzip-test.out" 2>&1 && pass 'module ZIP integrity check passes' || { fail 'module ZIP integrity check passes'; cat "$TMP/unzip-test.out" >&2; }
unzip -q "$ZIPFILE" -d "$EXTRACT" && pass 'module ZIP extracts cleanly' || fail 'module ZIP extracts cleanly'

for item in module.prop action.sh uninstall.sh README.md runtime/bin/vegas runtime/bin/action-gate runtime/bin/control-plane runtime/plugins/registry.json runtime/AX-T615-GAME-OPTIMIZER/bin/axgo webroot/index.html; do
    [ -f "$EXTRACT/$item" ] && pass "required package file exists: $item" || fail "required package file exists: $item"
done

PROP=$(cat "$EXTRACT/module.prop" 2>/dev/null || :)
contains "$PROP" 'id=vegas-inject' 'module ID is fixed and valid'
contains "$PROP" 'version=1.1.0-axmanager' 'module version is declared'
contains "$PROP" 'versionCode=10100' 'module version code is declared'
contains "$PROP" 'axeronPlugin=14800' 'module declares official AxManager v1.4.8 compatibility code'

[ -x "$EXTRACT/action.sh" ] && [ -x "$EXTRACT/uninstall.sh" ] && [ -x "$EXTRACT/runtime/bin/vegas" ] && pass 'module action and runtime entrypoints are executable' || fail 'module action and runtime entrypoints are executable'
grep -Fq 'MODDIR=${0%/*}' "$EXTRACT/action.sh" && pass 'action entrypoint resolves installed module root portably' || fail 'action entrypoint resolves installed module root portably'
grep -Fq 'vegas" action simulate' "$EXTRACT/action.sh" && pass 'action entrypoint invokes only fixed simulation route' || fail 'action entrypoint invokes only fixed simulation route'

ACTION=$(sh "$EXTRACT/action.sh" 2>/dev/null || :)
contains "$ACTION" '"execution_mode":"SIMULATION_ONLY"' 'extracted module action reports simulation-only mode'
contains "$ACTION" '"real_action_execution":"NOT_AVAILABLE"' 'extracted module action exposes no execution capability'
contains "$ACTION" '"hardware_writes":"NO"' 'extracted module action exposes no hardware-write capability'

WEBUI=$(cat "$EXTRACT/webroot/index.html" 2>/dev/null || :)
contains "$WEBUI" 'READ-ONLY · CAPABILITY-GATED · NO DEVICE APPLY' 'static WebUI states read-only capability-gated boundary'
contains "$WEBUI" 'Real device apply is not available.' 'static WebUI states no-control boundary'
if grep -nE 'fetch\(|XMLHttpRequest|WebSocket|addJavascriptInterface|innerHTML[[:space:]]*=|<form|<button' "$EXTRACT/webroot/index.html" >/dev/null 2>&1; then
    fail 'WebUI contains no interactive or browser-to-shell bridge surface'
else
    pass 'WebUI contains no interactive or browser-to-shell bridge surface'
fi

if unzip -Z1 "$ZIPFILE" | grep -E '(^|/)(\.git|tests|logs|dist|node_modules|\.env)(/|$)|runtime/(runtime|logs|tests|\.tmp)(/|$)|\.pem$|\.key$|\.secret$' >/dev/null 2>&1; then
    fail 'ZIP excludes repository, generated, and sensitive artifacts'
else
    pass 'ZIP excludes repository, generated, and sensitive artifacts'
fi

STATIC_FILES="$EXTRACT/action.sh $EXTRACT/uninstall.sh $EXTRACT/runtime/bin/vegas $EXTRACT/runtime/bin/action-gate $EXTRACT/runtime/bin/control-plane $EXTRACT/runtime/AX-T615-GAME-OPTIMIZER/bin/axgo"
if grep -nE '(^|[[:space:];])eval([[:space:];]|$)|(^|[[:space:];])su([[:space:];]|$)|setprop[[:space:]]|(^|[[:space:];])kill([[:space:];]|$)|(^|[[:space:];])pkill([[:space:];]|$)|sysctl[[:space:]]|>[[:space:]]*/(proc|sys)/|curl[[:space:]]|wget[[:space:]]|nc[[:space:]]' $STATIC_FILES >/dev/null 2>&1; then
    fail 'package public surfaces contain no root, execution, network, process, or hardware-write primitive'
else
    pass 'package public surfaces contain no root, execution, network, process, or hardware-write primitive'
fi

[ -f "$GUIDE" ] && grep -Fq 'AxManager v1.4.8' "$GUIDE" && grep -Fq 'Device-side installation' "$GUIDE" && pass 'module installation and compatibility guide is present and honest about device validation' || fail 'module installation and compatibility guide is present and honest about device validation'

printf 'AXMANAGER_PLUGIN_PACKAGE_TESTS: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
