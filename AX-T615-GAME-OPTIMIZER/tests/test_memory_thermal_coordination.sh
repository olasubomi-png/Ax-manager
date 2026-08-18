#!/usr/bin/env sh
set -eu
STEP7B_TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
export STEP7B_TEST_DIR
. "$STEP7B_TEST_DIR/memory_performance_test_lib.sh"

setup_case normal_normal
assert_contains "$(run_perf recommend)" 'Final recommendation: BOOST_ALLOWED' 'normal thermal coordination'
setup_case normal_hot
HOT="$(run_perf recommend)"
assert_contains "$HOT" 'Thermal state: CRITICAL' 'hot thermal state detected'
assert_contains "$HOT" 'Final recommendation: PERFORMANCE_BLOCKED' 'hot thermal state blocks boost'
setup_case normal_critical
CRITICAL="$(run_perf recommend)"
assert_contains "$CRITICAL" 'Thermal state: CRITICAL' 'critical thermal state detected'
assert_contains "$CRITICAL" 'Final recommendation: PERFORMANCE_BLOCKED' 'critical thermal state blocks performance'
setup_case unknown_thermal
UNKNOWN="$(run_perf recommend)"
assert_contains "$UNKNOWN" 'Thermal state: UNKNOWN' 'unknown thermal state detected'
assert_contains "$UNKNOWN" 'Final recommendation: CONSERVATIVE' 'unknown thermal state fails safe'
setup_case unknown_both
assert_contains "$(run_perf recommend)" 'Final recommendation: CONSERVATIVE' 'unknown memory and thermal fail safe'
cleanup_cases
printf '%s\n' 'PASS: memory-thermal coordination'
