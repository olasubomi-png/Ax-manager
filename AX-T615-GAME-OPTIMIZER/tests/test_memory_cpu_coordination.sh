#!/usr/bin/env sh
set -eu
STEP7B_TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
export STEP7B_TEST_DIR
. "$STEP7B_TEST_DIR/memory_performance_test_lib.sh"

setup_case normal_normal
NORMAL="$(run_perf status)"
assert_contains "$NORMAL" 'CPU: READY (recommendation forwarded: BOOST)' 'CPU boost recommendation'
assert_contains "$NORMAL" 'No hardware settings were changed' 'CPU coordination remains read-only'
setup_case pressure_normal
PRESSURE="$(run_perf status)"
assert_contains "$PRESSURE" 'CPU: READY (recommendation forwarded: BALANCED)' 'CPU balanced recommendation'
setup_case highpressure_normal
assert_contains "$(run_perf status)" 'CPU: READY (recommendation forwarded: CONSERVATIVE)' 'CPU conservative recommendation'
setup_case critical_normal
CRITICAL="$(run_perf status)"
assert_contains "$CRITICAL" 'CPU: READY (recommendation forwarded: BLOCKED)' 'CPU blocked recommendation'
cleanup_cases
printf '%s\n' 'PASS: memory-CPU coordination'
