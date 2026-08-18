#!/usr/bin/env sh
set -eu
STEP7B_TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
export STEP7B_TEST_DIR
. "$STEP7B_TEST_DIR/memory_performance_test_lib.sh"

setup_case normal_normal
NORMAL="$(run_perf status)"
assert_contains "$NORMAL" 'GPU: READY (recommendation forwarded: BOOST)' 'GPU boost recommendation'
assert_contains "$NORMAL" 'No hardware settings were changed' 'GPU coordination remains read-only'
setup_case pressure_normal
assert_contains "$(run_perf status)" 'GPU: READY (recommendation forwarded: BALANCED)' 'GPU balanced recommendation'
setup_case highpressure_normal
assert_contains "$(run_perf status)" 'GPU: READY (recommendation forwarded: CONSERVATIVE)' 'GPU conservative recommendation'
setup_case critical_normal
CRITICAL="$(run_perf status)"
assert_contains "$CRITICAL" 'GPU: READY (recommendation forwarded: BLOCKED)' 'GPU blocked recommendation'
cleanup_cases
printf '%s\n' 'PASS: memory-GPU coordination'
