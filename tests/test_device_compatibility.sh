#!/usr/bin/env sh
# Phase 16 contract: universal Android compatibility is fixed, read-only, non-identifying, and capability-gated.
set -u

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
DEVICE="$ROOT/bin/device-compatibility"
VEGAS="$ROOT/bin/vegas"
MANAGER="$ROOT/bin/plugin-manager"
AXGO="$ROOT/AX-T615-GAME-OPTIMIZER/bin/axgo"
DASHBOARD="$ROOT/AX-T615-GAME-OPTIMIZER/bin/dashboard"
ACTION="$ROOT/bin/action-engine"
DASHBOARD_HTML="$ROOT/AX-T615-GAME-OPTIMIZER/dashboard/index.html"
DASHBOARD_JS="$ROOT/AX-T615-GAME-OPTIMIZER/dashboard/assets/app.js"
TMP="${DEVICE_COMPAT_TEST_TMP:-$ROOT/tests/.tmp/device-compatibility-$$}"
FIXTURE="$TMP/unisoc"
UNKNOWN="$TMP/unknown"
PASS=0
FAIL=0

cleanup() {
    rm -rf "$TMP"
    rmdir "$(dirname "$TMP")" 2>/dev/null || :
}
trap cleanup EXIT HUP INT TERM
mkdir -p "$FIXTURE/system" "$FIXTURE/proc" "$FIXTURE/sys/class/thermal" "$FIXTURE/sys/class/power_supply" "$FIXTURE/sys/class/drm" "$UNKNOWN" || exit 1

cat > "$FIXTURE/system/build.prop" <<'EOF'
ro.product.manufacturer=Tecno
ro.product.brand=TECNO
ro.product.model=KL4
ro.product.device=TECNO-KL4
ro.board.platform=ums9230
ro.hardware=ums9230
ro.build.version.sdk=34
ro.build.version.release=14
ro.product.cpu.abi=arm64-v8a
ro.hardware.egl=Mali-G57
ro.soc.model=Unisoc T615
EOF
cat > "$FIXTURE/proc/cpuinfo" <<'EOF'
Processor	: ARMv8 Processor rev 1 (v8l)
Hardware	: Unisoc T615
EOF
cat > "$FIXTURE/proc/meminfo" <<'EOF'
MemTotal:        3145728 kB
MemFree:          512000 kB
EOF
cat > "$FIXTURE/proc/version" <<'EOF'
Linux version 5.10.149-android13 (builder@localhost)
EOF

ok() { PASS=$((PASS + 1)); printf 'ok %s\n' "$1"; }
not_ok() { FAIL=$((FAIL + 1)); printf 'not ok %s\n' "$1"; }
contains() { NAME=$1; HAYSTACK=$2; NEEDLE=$3; printf '%s' "$HAYSTACK" | grep -F "$NEEDLE" >/dev/null 2>&1 && ok "$NAME" || not_ok "$NAME"; }
not_contains() { NAME=$1; HAYSTACK=$2; NEEDLE=$3; printf '%s' "$HAYSTACK" | grep -F "$NEEDLE" >/dev/null 2>&1 && not_ok "$NAME" || ok "$NAME"; }
fails() { NAME=$1; shift; "$@" >/dev/null 2>&1 && not_ok "$NAME" || ok "$NAME"; }
run_device() { VEGAS_DEVICE_TEST_ROOT="$FIXTURE" sh "$DEVICE" "$@"; }
run_unknown() { VEGAS_DEVICE_TEST_ROOT="$UNKNOWN" sh "$DEVICE" "$@"; }
run_vegas() { VEGAS_DEVICE_TEST_ROOT="$FIXTURE" sh "$VEGAS" "$@"; }

STATUS=$(run_device status)
contains 'status exposes the fixed compatibility component' "$STATUS" 'COMPONENT=vegas-universal-android-compatibility'
contains 'profile is non-identifying by contract' "$STATUS" 'PROFILE_CLASS=NON_IDENTIFYING_DEVICE_COMPATIBILITY'
contains 'fixture detection recognizes Unisoc evidence' "$STATUS" 'CPU_VENDOR=UNISOC'
contains 'fixture detection selects Unisoc read-only adapter' "$STATUS" 'ADAPTER=unisoc-read-only'
contains 'status exposes read-only privilege tier' "$STATUS" 'PRIVILEGE_TIER=READ_ONLY_USER_SHELL'
contains 'status denies root requirement' "$STATUS" 'ROOT_REQUIRED=NO'
contains 'status preserves no hardware-write boundary' "$STATUS" 'HARDWARE_WRITES=NO'
contains 'status does not collect serials' "$STATUS" 'SERIAL=NOT_COLLECTED'
contains 'status does not collect fingerprints' "$STATUS" 'FINGERPRINT=NOT_COLLECTED'
contains 'status does not transmit network data' "$STATUS" 'NETWORK_TRANSMISSION=NO'

CAPABILITIES=$(run_device capabilities)
contains 'capabilities report observed CPU telemetry only' "$CAPABILITIES" 'READ_CPU_TELEMETRY=SUPPORTED_READ_ONLY'
contains 'capabilities report observed thermal telemetry only' "$CAPABILITIES" 'READ_THERMAL_TELEMETRY=SUPPORTED_READ_ONLY'
contains 'capabilities deny CPU governor writes' "$CAPABILITIES" 'CPU_GOVERNOR_WRITE=UNSUPPORTED_NO_DEVICE_WRITE_CONTRACT'
contains 'capabilities deny refresh-rate writes' "$CAPABILITIES" 'DISPLAY_REFRESH_WRITE=UNSUPPORTED_NO_DEVICE_WRITE_CONTRACT'
contains 'capabilities deny game-mode writes when unverified' "$CAPABILITIES" 'GAME_MODE_WRITE=UNSUPPORTED_NO_DEVICE_WRITE_CONTRACT'
contains 'action records keep refresh telemetry read only' "$CAPABILITIES" 'ACTION_refresh_telemetry=SUPPORTED_READ_ONLY'
contains 'performance action remains capability denied' "$CAPABILITIES" 'ACTION_profile_performance_advisory=UNSUPPORTED_DEVICE_CAPABILITY_UNVERIFIED'

INSPECT=$(run_device inspect)
contains 'inspection has a fixed scope' "$INSPECT" 'INSPECTION_SCOPE=fixed properties,proc cpu/memory,sys telemetry presence only'
contains 'inspection declares prohibited operations' "$INSPECT" 'PROHIBITED=hardware writes,sys writes,proc writes,setprop,root,su,kill,network,arbitrary commands,game modification'
COMPAT=$(run_device compatibility)
contains 'compatibility selects an adapter' "$COMPAT" 'ADAPTER=unisoc-read-only'
contains 'compatibility does not expose an OEM control bridge' "$COMPAT" 'OEM_CONTROL_BRIDGE=NOT_AVAILABLE'
VALIDATE=$(run_device validate)
contains 'validation accepts only profile schema safety' "$VALIDATE" 'VALIDATION_RESULT=VALID'
contains 'validation enforces no device-write interface' "$VALIDATE" 'NO_DEVICE_WRITE_INTERFACE=ENFORCED'

SNAPSHOT=$(run_device snapshot)
contains 'snapshot is structurally read only' "$SNAPSHOT" '"read_only":true'
contains 'snapshot includes adapter record' "$SNAPSHOT" '"adapter":{"id":"unisoc-read-only"'
contains 'snapshot includes normalized CPU monitoring' "$SNAPSHOT" '"cpu_monitoring":"SUPPORTED_READ_ONLY"'
contains 'snapshot includes unsupported refresh control' "$SNAPSHOT" '"refresh_rate_control":"UNSUPPORTED_NO_DEVICE_WRITE_CONTRACT"'
contains 'snapshot includes no real device apply state' "$SNAPSHOT" '"real_device_apply":"NOT_AVAILABLE"'
contains 'snapshot excludes personal data' "$SNAPSHOT" '"personal_data_collected":false'
contains 'snapshot excludes serial collection' "$SNAPSHOT" '"serial_collected":false'
contains 'snapshot excludes network transmission' "$SNAPSHOT" '"network_transmission":false'
contains 'snapshot excludes process control' "$SNAPSHOT" '"process_control":false'
contains 'snapshot excludes Android property writes' "$SNAPSHOT" '"android_property_writes":false'

UNKNOWN_STATUS=$(run_unknown status)
contains 'unknown devices use generic fallback' "$UNKNOWN_STATUS" 'ADAPTER=generic-android-read-only'
contains 'unknown devices keep control unavailable' "$UNKNOWN_STATUS" 'GAMING_MODE_CONTROL=NOT_AVAILABLE_UNVERIFIED'

VEGAS_STATUS=$(run_vegas device status)
contains 'VEGAS device status delegates to fixed engine' "$VEGAS_STATUS" 'COMPATIBILITY_STATUS=SAFE_READ_ONLY'
VEGAS_SNAPSHOT=$(run_vegas device snapshot)
contains 'VEGAS device snapshot is read only' "$VEGAS_SNAPSHOT" '"component":"vegas-universal-android-compatibility"'
VEGAS_UNIFIED=$(run_vegas snapshot)
contains 'unified snapshot namespaces compatibility separately' "$VEGAS_UNIFIED" '"device_compatibility":{"schema":"1","component":"vegas-universal-android-compatibility"'
fails 'VEGAS rejects device route without a fixed subcommand' sh "$VEGAS" device
fails 'VEGAS rejects unknown device subcommands' sh "$VEGAS" device ../../outside
fails 'VEGAS rejects device route extra arguments' sh "$VEGAS" device status extra

PLUGIN_DEVICE=$(VEGAS_DEVICE_TEST_ROOT="$FIXTURE" sh "$MANAGER" invoke ax-t615-game-optimizer device)
contains 'plugin manager allowlists the device report' "$PLUGIN_DEVICE" 'ADAPTER=unisoc-read-only'
AXGO_DEVICE=$(VEGAS_DEVICE_TEST_ROOT="$FIXTURE" sh "$AXGO" device status)
contains 'AX-T615 router exposes fixed device report' "$AXGO_DEVICE" 'COMPATIBILITY_STATUS=SAFE_READ_ONLY'
fails 'AX-T615 router rejects device route extra arguments' sh "$AXGO" device status extra

ACTION_SNAPSHOT=$(VEGAS_DEVICE_TEST_ROOT="$FIXTURE" sh "$ACTION" snapshot)
contains 'action snapshot embeds compatibility evidence without enabling apply' "$ACTION_SNAPSHOT" '"device_compatibility":{"schema":"1","component":"vegas-universal-android-compatibility"'
DASHBOARD_SNAPSHOT=$(VEGAS_DEVICE_TEST_ROOT="$FIXTURE" sh "$DASHBOARD" snapshot)
contains 'dashboard snapshot embeds compatibility evidence separately' "$DASHBOARD_SNAPSHOT" '"device_compatibility":{"schema":"1","component":"vegas-universal-android-compatibility"'
for ID in deviceProfile deviceAdapter deviceAdapterState deviceCpuMonitoring deviceThermalMonitoring deviceGamingMode deviceRefreshControl deviceRealApply; do
    grep -F "$ID" "$DASHBOARD_HTML" >/dev/null 2>&1 && ok "dashboard has static $ID field" || not_ok "dashboard has static $ID field"
    grep -F "$ID" "$DASHBOARD_JS" >/dev/null 2>&1 && ok "dashboard text-binds $ID" || not_ok "dashboard text-binds $ID"
done

contains 'tests use repository-local scratch state' "$TMP" "$ROOT/tests/.tmp/"
not_contains 'engine does not use literal writable temp paths' "$(grep -n '/tmp/' "$DEVICE" 2>/dev/null || :)" '/tmp/'
for TARGET in "$DEVICE" "$VEGAS" "$MANAGER" "$ROOT/plugins/ax-t615-game-optimizer/plugin.sh" "$AXGO" "$DASHBOARD"; do
    grep -E '[>][[:space:]]*/(proc|sys)' "$TARGET" >/dev/null 2>&1 && not_ok "no proc sys write in $(basename "$TARGET")" || ok "no proc sys write in $(basename "$TARGET")"
done
grep -E '(^|[[:space:]])(eval|setprop|kill|pkill|sysctl|su|curl|wget|nc)[[:space:]]' "$DEVICE" >/dev/null 2>&1 && not_ok 'device engine excludes control and network primitives' || ok 'device engine excludes control and network primitives'
grep -E 'innerHTML|outerHTML|insertAdjacentHTML' "$DASHBOARD_JS" >/dev/null 2>&1 && not_ok 'dashboard excludes HTML injection sinks' || ok 'dashboard excludes HTML injection sinks'

printf 'PHASE16_DEVICE_COMPATIBILITY_TESTS: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
