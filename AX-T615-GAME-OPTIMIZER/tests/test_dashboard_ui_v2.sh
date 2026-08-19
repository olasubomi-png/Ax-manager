#!/usr/bin/env sh
# Dashboard/UI v2 contract: static, responsive, read-only rendering with no browser-to-device control path.
set -u

TEST_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$TEST_DIR/.." && pwd)
TMP="${DASHBOARD_UI_V2_TMP:-$ROOT/tests/.tmp/dashboard-ui-v2-$$}"
mkdir -p "$TMP" || exit 1
cleanup() { rm -rf "$TMP"; rmdir "$(dirname "$TMP")" 2>/dev/null || :; }
trap cleanup EXIT HUP INT TERM

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL: %s\n' "$1" >&2; }
contains() { printf '%s\n' "$1" | grep -Fq "$2" && pass "$3" || fail "$3"; }
not_contains() { printf '%s\n' "$1" | grep -Fq "$2" && fail "$3" || pass "$3"; }

HTML=$(cat "$ROOT/dashboard/index.html")
APP=$(cat "$ROOT/dashboard/assets/app.js")
CSS=$(cat "$ROOT/dashboard/assets/styles.css")
SOURCES="$HTML\n$APP\n$CSS"

if node --check "$ROOT/dashboard/assets/app.js" >/dev/null 2>&1; then pass "Dashboard/UI v2 JavaScript syntax"; else fail "Dashboard/UI v2 JavaScript syntax"; fi
contains "$HTML" 'VEGAS-INJECT' "dashboard brands VEGAS-inject"
contains "$HTML" 'Unified Gaming &amp; System Observer' "dashboard includes unified observer subtitle"
contains "$HTML" 'id="modeLabel"' "header exposes read-only status"
contains "$HTML" 'id="unifiedPluginCount"' "header exposes plugin count"
contains "$HTML" 'id="unifiedControl"' "header exposes safety status"

for metric in cpu gpu memory thermal battery powerMetric; do contains "$HTML" "id=\"${metric}Value\"" "system overview exposes ${metric} value"; done
for field in gameName packageName sessionStatus profileValue sessionFpsValue sessionFrameTimeValue sessionFramePacingValue sessionFpsTrendValue; do contains "$HTML" "id=\"${field}\"" "gaming session exposes ${field}"; done
for field in recommendationState confidenceValue priorityChip recommendationReason evidenceStatusValue actionsValue recoveryValue; do contains "$HTML" "id=\"${field}\"" "policy section exposes ${field}"; done
contains "$HTML" 'Intelligent Analysis' "dashboard includes the Phase 7 advisory analysis section"
for field in analysisClassification analysisConfidence analysisExplanation analysisSupportingEvidence analysisConflictingEvidence analysisEvidenceQuality analysisRecommendation analysisSafetyClassification analysisHistoryCount analysisTrendList; do contains "$HTML" "id=\"${field}\"" "analysis section exposes ${field}"; done
contains "$APP" 'Invalid analysis section.' "malformed analysis envelope is rejected"
contains "$APP" 'renderAnalysisTrends' "analysis trends render through a text-safe helper"
contains "$HTML" 'Policy &amp; Recommendations' "dashboard includes the Phase 8 policy section"
for field in policyState policyRecommendation policyConfidence policyPriority policyReason policyEvidenceQuality policyBottleneck policySafetyClassification policyRejectedOptions policyProvenance policyTimestamp policyHistoryCount; do contains "$HTML" "id=\"${field}\"" "policy section exposes ${field}"; done
contains "$APP" 'Invalid policy section.' "malformed policy envelope is rejected"
contains "$APP" 'snapshot.policy' "policy rendering reads the validated policy envelope"

contains "$HTML" 'id="pluginHealthGrid"' "plugin health grid exists"
contains "$APP" 'snapshot.plugin_health' "plugin health reads unified snapshot source"
contains "$APP" 'plugin.availability' "plugin health exposes enabled availability"
contains "$APP" 'plugin.supported_operations' "plugin health exposes supported operations"
contains "$APP" '"ax-t615-game-optimizer"' "plugin UI reserves AX-T615 card"
contains "$HTML" 'System Observer' "plugin UI reserves System Observer card"
contains "$HTML" 'Performance Observer' "plugin UI reserves Performance Observer card"

for field in safetyReadOnly safetyHardwareWrites safetyProcessControl safetyProcWrites safetySysWrites safetyAndroidProperties safetyNetworkOperations safetyGameModification safetyCodeExecution; do contains "$HTML" "id=\"${field}\"" "safety ledger exposes ${field}"; done
contains "$APP" 'const blocked =' "safety states are source-derived"
contains "$HTML" 'READ-ONLY PLUGIN' "dashboard labels plugin boundaries"
contains "$HTML" 'POLICY OUTPUT / NOT APPLIED' "dashboard labels informational policy output"

contains "$APP" 'EXPORTED_SNAPSHOT_URL = "data/current-snapshot.json"' "refresh uses fixed local snapshot path"
contains "$APP" 'cache: "no-store"' "refresh avoids stale exported data"
contains "$APP" '1024 * 1024' "refresh enforces bounded snapshot size"
contains "$APP" 'refreshExportedSnapshot' "refresh behavior exists"
contains "$APP" 'Snapshot must be a JSON object.' "malformed snapshot is rejected"
contains "$APP" 'Invalid system section.' "malformed optional unified section is rejected"
contains "$APP" 'UNKNOWN' "unknown values remain explicit"
contains "$APP" 'UNAVAILABLE' "unavailable values remain explicit"

contains "$CSS" '@media (max-width:1050px)' "tablet responsive breakpoint exists"
contains "$CSS" '@media (max-width:780px)' "mobile responsive breakpoint exists"
contains "$CSS" '.plugin-health-grid { grid-template-columns:1fr;' "mobile plugin cards use a single column"
contains "$CSS" '.safety-ledger { grid-template-columns:1fr;' "mobile safety ledger uses a single column"
contains "$CSS" '.analysis-grid { grid-template-columns:1fr;' "mobile analysis panel uses a single column"
contains "$CSS" '.policy-grid { grid-template-columns:1fr;' "mobile policy panel uses a single column"
contains "$CSS" 'prefers-reduced-motion' "reduced motion support exists"

not_contains "$SOURCES" 'eval(' "no eval in Dashboard/UI v2"
not_contains "$SOURCES" 'Function(' "no Function constructor in Dashboard/UI v2"
not_contains "$SOURCES" 'innerHTML' "no unsafe HTML injection sink"
not_contains "$SOURCES" 'document.write' "no document write sink"
not_contains "$SOURCES" 'javascript:' "no javascript URL execution"
not_contains "$APP" 'child_process' "no browser-side process execution"
not_contains "$APP" 'window.open(' "no arbitrary URL execution"
not_contains "$APP" 'loadScript' "no dynamic script loading"
not_contains "$HTML" '<form' "dashboard exposes no control form"
not_contains "$HTML" 'type="range"' "dashboard exposes no hardware-control slider"
not_contains "$HTML" 'CPU boost' "dashboard exposes no CPU boost control"
not_contains "$HTML" 'GPU boost' "dashboard exposes no GPU boost control"
not_contains "$HTML" 'Overclock' "dashboard exposes no overclock control"

case "$TMP" in "$ROOT/tests/.tmp/"*) pass "tests use repository-local Termux-safe temporary path" ;; *) fail "tests use repository-local Termux-safe temporary path" ;; esac
printf 'DASHBOARD_UI_V2_TESTS: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
