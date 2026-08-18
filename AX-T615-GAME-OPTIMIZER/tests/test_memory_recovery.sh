#!/usr/bin/env sh
set -eu
STEP7B_TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
export STEP7B_TEST_DIR
. "$STEP7B_TEST_DIR/memory_performance_test_lib.sh"

setup_case critical_normal
assert_contains "$(run_perf status)" 'Memory state: CRITICAL' 'critical start'
set_case_roots highpressure_normal
assert_contains "$(run_perf status)" 'Memory state: CRITICAL' 'critical recovery sample one'
assert_contains "$(run_perf status)" 'Memory state: CRITICAL' 'critical recovery sample two'
assert_contains "$(run_perf status)" 'Memory state: HIGH_PRESSURE' 'critical recovers to high pressure'
set_case_roots pressure_normal
assert_contains "$(run_perf status)" 'Memory state: HIGH_PRESSURE' 'high pressure recovery sample one'
assert_contains "$(run_perf status)" 'Memory state: HIGH_PRESSURE' 'high pressure recovery sample two'
assert_contains "$(run_perf status)" 'Memory state: PRESSURE' 'high pressure recovers to pressure'
set_case_roots normal_normal
assert_contains "$(run_perf status)" 'Memory state: PRESSURE' 'pressure recovery sample one'
assert_contains "$(run_perf status)" 'Memory state: PRESSURE' 'pressure recovery sample two'
assert_contains "$(run_perf status)" 'Memory state: NORMAL' 'pressure recovers to normal'
cleanup_cases
printf '%s\n' 'PASS: memory staged recovery'
