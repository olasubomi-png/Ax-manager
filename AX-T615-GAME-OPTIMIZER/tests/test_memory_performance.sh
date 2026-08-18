#!/usr/bin/env sh
set -eu
STEP7B_TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
export STEP7B_TEST_DIR
. "$STEP7B_TEST_DIR/memory_performance_test_lib.sh"

snapshot="$(find "$FIXTURE_ROOT/normal_normal" -type f -exec sha256sum {} \; | sort)"
setup_case normal_normal
OUT="$(run_perf status)"
assert_contains "$OUT" 'Final recommendation: BOOST_ALLOWED' 'normal memory and thermal permit boost'
assert_contains "$OUT" 'No memory settings were modified.' 'read-only status'
assert_contains "$(run_axgo_perf check)" 'Final recommendation: BOOST_ALLOWED' 'axgo performance check'
assert_contains "$(run_axgo_perf recommend)" 'CPU: READY' 'axgo performance recommendation'

setup_case pressure_normal
assert_contains "$(run_perf status)" 'Final recommendation: BALANCED_ONLY' 'pressure limits performance'
setup_case highpressure_normal
assert_contains "$(run_perf status)" 'Final recommendation: CONSERVATIVE' 'high pressure is conservative'
setup_case critical_normal
assert_contains "$(run_perf status)" 'Final recommendation: PERFORMANCE_BLOCKED' 'critical memory blocks performance'
setup_case zram_active_pressure
assert_contains "$(run_perf status)" 'ZRAM: ACTIVE' 'active zram reported'
setup_case zram_unavailable_pressure
assert_contains "$(run_perf status)" 'ZRAM: UNAVAILABLE' 'unavailable zram reported'
setup_case unknown_both
assert_contains "$(run_perf status)" 'Final recommendation: CONSERVATIVE' 'unknown inputs fail safe'

setup_case normal_normal
START="$(run_perf game-start 'Example Game')"
assert_contains "$START" 'AX-MANAGER GAME SESSION' 'memory game-start report'
assert_contains "$START" 'Final recommendation: BOOST_ALLOWED' 'memory game-start recommendation'
run_perf sample >/dev/null
STOP="$(run_perf game-stop)"
assert_contains "$STOP" 'MEMORY PERFORMANCE REPORT' 'memory game-stop report'
assert_contains "$STOP" 'Game: Example Game' 'memory game name in report'
assert_contains "$STOP" 'No unsafe memory operations were performed.' 'memory session safety report'
[ -f "$RUNTIME_ROOT/runtime/memory-performance/memory-performance.report" ] || { echo 'FAIL: memory session report file' >&2; exit 1; }

after="$(find "$FIXTURE_ROOT/normal_normal" -type f -exec sha256sum {} \; | sort)"
assert_not_changed "$snapshot" "$after" 'combined fixtures remain unchanged'
cleanup_cases
printf '%s\n' 'PASS: memory-performance integration'
