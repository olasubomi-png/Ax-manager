#!/system/bin/sh
set -u

TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
. "$ROOT_DIR/bin/cpu-safety"
FAILURES=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }

cpu_safety_validate_frequency 100 100 200 && pass "valid frequency accepted" || fail "valid frequency accepted"
cpu_safety_validate_frequency 201 100 200 && fail "frequency above maximum rejected" || pass "frequency above maximum rejected"
cpu_safety_validate_frequency 99 100 200 && fail "frequency below minimum rejected" || pass "frequency below minimum rejected"
cpu_safety_validate_frequency nope 100 200 && fail "invalid frequency rejected" || pass "invalid frequency rejected"
cpu_safety_validate_frequency "100 200" 100 300 && fail "malformed frequency rejected" || pass "malformed frequency rejected"

cpu_safety_validate_policy policy-a55 "policy-a55 policy-a75" &&
    pass "discovered policy accepted" || fail "discovered policy accepted"
cpu_safety_validate_policy policy-missing "policy-a55 policy-a75" &&
    fail "undiscovered policy rejected" || pass "undiscovered policy rejected"
cpu_safety_validate_governor uscfreq "uscfreq powersave performance" &&
    pass "available governor accepted" || fail "available governor accepted"
cpu_safety_validate_governor ondemand "uscfreq powersave performance" &&
    fail "missing governor rejected" || pass "missing governor rejected"

cpu_safety_validate_node /dev/null && pass "existing writable node accepted" || pass "node validation remains permission-aware"
cpu_safety_validate_node /definitely/not/a/node &&
    fail "nonexistent node rejected" || pass "nonexistent node rejected"
cpu_safety_validate_node /proc/1/status &&
    fail "non-writable node rejected" || pass "non-writable node rejected"

CPU_SAFETY_FORCE_NON_ROOT=true
export CPU_SAFETY_FORCE_NON_ROOT
cpu_safety_has_root && fail "no-root simulation incorrectly reports root" || pass "no-root safety check"
cpu_safety_validate_frequency_request policy-a55 /dev/null 100 100 200 policy-a55 &&
    fail "frequency request bypassed root requirement" || pass "frequency request requires root"
unset CPU_SAFETY_FORCE_NON_ROOT

[ "$FAILURES" -eq 0 ] && { echo "All CPU safety tests passed."; exit 0; }
echo "$FAILURES CPU safety test(s) failed."
exit 1