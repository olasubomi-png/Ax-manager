#!/usr/bin/env sh
set -u
. "$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)/step9_test_lib.sh"
PROFILES="$STEP9_ROOT/config/game-profiles"
ROOT="$STEP9_TMP/hysteresis"; mkdir -p "$ROOT"
run_recommend() { GAME_PROFILE_DATA_ROOT="$ROOT" GAME_PROFILE_DIR="$PROFILES" GAME_PROFILE_THERMAL_STATE="$1" GAME_PROFILE_MEMORY_STATE="$2" sh "$STEP9_BIN/game-profile" recommend performance; }
OUT="$(run_recommend NORMAL NORMAL)"; step9_assert_contains "$OUT" 'Final recommendation: PERFORMANCE' 'hysteresis starts at performance'
OUT="$(run_recommend CRITICAL NORMAL)"; step9_assert_contains "$OUT" 'Final recommendation: PERFORMANCE_BLOCKED' 'hysteresis escalation is immediate'
OUT="$(run_recommend NORMAL NORMAL)"; step9_assert_contains "$OUT" 'Final recommendation: PERFORMANCE_BLOCKED' 'first recovery sample holds blocked mode'
OUT="$(run_recommend NORMAL NORMAL)"; step9_assert_contains "$OUT" 'Final recommendation: PERFORMANCE_BLOCKED' 'second recovery sample holds blocked mode'
OUT="$(run_recommend NORMAL NORMAL)"; step9_assert_contains "$OUT" 'Final recommendation: CONSERVATIVE' 'third recovery sample steps down one level'
OUT="$(GAME_PROFILE_DATA_ROOT="$ROOT" GAME_PROFILE_DIR="$PROFILES" sh "$STEP9_BIN/game-profile" use cool)"; step9_assert_contains "$OUT" 'Temporary profile override' 'temporary profile override is accepted'
OUT="$(GAME_PROFILE_DATA_ROOT="$ROOT" GAME_PROFILE_DIR="$PROFILES" GAME_PROFILE_THERMAL_STATE=NORMAL GAME_PROFILE_MEMORY_STATE=NORMAL sh "$STEP9_BIN/game-profile" recommend performance)"; step9_assert_contains "$OUT" 'Profile: COOL' 'temporary override supersedes requested profile'
OUT="$(GAME_PROFILE_DATA_ROOT="$ROOT" GAME_PROFILE_DIR="$PROFILES" sh "$STEP9_BIN/game-profile" clear)"; step9_assert_contains "$OUT" 'cleared' 'temporary profile override can be cleared'
step9_assert_missing "$ROOT/runtime/game-profile/override.state" 'override state is removed after clear'
