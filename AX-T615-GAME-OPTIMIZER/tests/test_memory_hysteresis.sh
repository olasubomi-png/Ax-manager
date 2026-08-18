#!/usr/bin/env sh
set -eu
STEP7B_TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
export STEP7B_TEST_DIR
. "$STEP7B_TEST_DIR/memory_performance_test_lib.sh"

setup_case normal_normal
assert_contains "$(run_perf status)" 'Memory state: NORMAL' 'initial normal state'
set_case_roots pressure_normal
assert_contains "$(run_perf status)" 'Memory state: PRESSURE' 'pressure escalation is immediate'
set_case_roots normal_normal
assert_contains "$(run_perf status)" 'Memory state: PRESSURE' 'first recovery sample remains pressured'
assert_contains "$(run_perf status)" 'Memory state: PRESSURE' 'second recovery sample remains pressured'
assert_contains "$(run_perf status)" 'Memory state: NORMAL' 'third stable recovery sample relaxes state'
set_case_roots pressure_normal
run_perf status >/dev/null
set_case_roots normal_normal
run_perf status >/dev/null
set_case_roots pressure_normal
assert_contains "$(run_perf status)" 'Memory state: PRESSURE' 'fluctuation does not relax the state'
cleanup_cases
printf '%s\n' 'PASS: memory hysteresis'
