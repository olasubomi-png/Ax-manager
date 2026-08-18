#!/system/bin/sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0" 2>/dev/null)" && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
FIXTURE="$TEST_DIR/fixtures/gpu/available"
CONTROLLER="$ROOT_DIR/bin/gpu-controller"
WORK="${TMPDIR:-/tmp}/axgo-gpu-dry-run.$$"
FAILURES=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT HUP INT TERM
run_gpu() {
    RECOMMENDATION="$1"; shift
    AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$WORK/data" GPU_SYSFS_ROOT="$FIXTURE" \
    GPU_PROPERTIES_FILE="$FIXTURE/properties" THERMAL_GUARD_RECOMMENDATION="$RECOMMENDATION" \
        sh "$CONTROLLER" "$@"
}
mkdir -p "$WORK"
OUTPUT="$(run_gpu BOOST dry-run performance)"
printf '%s\n' "$OUTPUT" | grep -q "AX-T615 GPU DRY RUN" && pass "dry-run heading present" || fail "dry-run heading present"
printf '%s\n' "$OUTPUT" | grep -q "Requested profile: PERFORMANCE" && pass "performance profile accepted" || fail "performance profile accepted"
printf '%s\n' "$OUTPUT" | grep -q "Thermal recommendation: BOOST" && pass "BOOST recommendation accepted" || fail "BOOST recommendation accepted"
printf '%s\n' "$OUTPUT" | grep -q "GPU recommendation: BOOST" && pass "BOOST GPU recommendation reported" || fail "BOOST GPU recommendation reported"
printf '%s\n' "$OUTPUT" | grep -q "Planned changes:" && pass "planned changes section present" || fail "planned changes section present"
printf '%s\n' "$OUTPUT" | grep -q "NONE" && pass "dry-run plans no changes" || fail "dry-run plans no changes"
printf '%s\n' "$OUTPUT" | grep -q "No changes were made" && pass "dry-run confirms no changes" || fail "dry-run confirms no changes"
OUTPUT="$(run_gpu BLOCKED dry-run performance)"
printf '%s\n' "$OUTPUT" | grep -q "GPU recommendation: BLOCKED" && pass "BLOCKED recommendation reported" || fail "BLOCKED recommendation reported"
OUTPUT="$(run_gpu UNKNOWN dry-run cool)"
printf '%s\n' "$OUTPUT" | grep -q "Thermal recommendation: CONSERVATIVE" && pass "unknown thermal state fails conservative" || fail "unknown thermal state fails conservative"
OUTPUT="$(AXGO_ROOT="$ROOT_DIR" AXGO_DATA_ROOT="$WORK/data-axgo" GPU_SYSFS_ROOT="$FIXTURE" GPU_PROPERTIES_FILE="$FIXTURE/properties" THERMAL_GUARD_RECOMMENDATION=BOOST sh "$ROOT_DIR/bin/axgo" gpu dry-run performance)"
printf '%s\n' "$OUTPUT" | grep -q "Requested profile: PERFORMANCE" && pass "axgo gpu dry-run route works" || fail "axgo gpu dry-run route works"
OUTPUT="$(run_gpu BOOST dry-run invalid 2>&1)"; STATUS=$?
[ "$STATUS" -eq 2 ] && pass "invalid profile rejected" || fail "invalid profile rejected"
BEFORE="$(find "$FIXTURE" -type f -exec sha256sum {} \; | sort)"
run_gpu BOOST dry-run balanced >/dev/null
AFTER="$(find "$FIXTURE" -type f -exec sha256sum {} \; | sort)"
[ "$BEFORE" = "$AFTER" ] && pass "dry-run leaves GPU data unchanged" || fail "dry-run leaves GPU data unchanged"
[ "$FAILURES" -eq 0 ] && { echo "All GPU dry-run tests passed."; exit 0; }
echo "$FAILURES GPU dry-run test(s) failed."
exit 1
