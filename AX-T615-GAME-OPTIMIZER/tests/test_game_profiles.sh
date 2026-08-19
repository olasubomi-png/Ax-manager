#!/usr/bin/env sh
set -u
. "$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)/step9_test_lib.sh"
PROFILES="$STEP9_ROOT/config/game-profiles"
OUT="$(GAME_PROFILE_DATA_ROOT="$STEP9_TMP/commands" GAME_PROFILE_DIR="$PROFILES" sh "$STEP9_BIN/game-profile" list)"; step9_assert_contains "$OUT" 'AX GAME PROFILES' 'profile list command works'
OUT="$(GAME_PROFILE_DATA_ROOT="$STEP9_TMP/show" GAME_PROFILE_DIR="$PROFILES" sh "$STEP9_BIN/game-profile" show battery)"; step9_assert_contains "$OUT" 'Profile: BATTERY' 'profile show resolves battery example'
OUT="$(GAME_PROFILE_DATA_ROOT="$STEP9_TMP/detect" GAME_PROFILE_DIR="$PROFILES" sh "$STEP9_BIN/game-profile" detect com.example.unverified)"; step9_assert_contains "$OUT" 'DEFAULT_SAFE' 'unknown package detection uses default-safe'
CUSTOM="$STEP9_TMP/custom-profiles"; mkdir -p "$CUSTOM"
OUT="$(GAME_PROFILE_DATA_ROOT="$STEP9_TMP/create" GAME_PROFILE_DIR="$CUSTOM" sh "$STEP9_BIN/game-profile" create 'Fixture Created Game')"; step9_assert_contains "$OUT" 'Created data-only profile' 'profile create writes a data-only profile'
step9_assert_file "$CUSTOM/fixture-created-game.json" 'created profile file exists'
OUT="$(GAME_PROFILE_DATA_ROOT="$STEP9_TMP/create" GAME_PROFILE_DIR="$CUSTOM" sh "$STEP9_BIN/game-profile" show fixture-created-game)"; step9_assert_contains "$OUT" 'Profile: BALANCED' 'created profile shows balanced mode'
OUT="$(GAME_PROFILE_DATA_ROOT="$STEP9_TMP/export" GAME_PROFILE_DIR="$PROFILES" sh "$STEP9_BIN/game-profile" export)"; step9_assert_contains "$OUT" 'Example Performance' 'profile export includes example data'
IMPORT="$STEP9_TMP/import-source.json"; cp "$STEP9_ROOT/config/game-profiles/example-cool.json" "$IMPORT"
OUT="$(GAME_PROFILE_DATA_ROOT="$STEP9_TMP/import" GAME_PROFILE_DIR="$CUSTOM" sh "$STEP9_BIN/game-profile" import "$IMPORT")"; step9_assert_contains "$OUT" 'Imported data-only profile' 'profile import validates and stores data'
OUT="$(GAME_PROFILE_DATA_ROOT="$STEP9_TMP/override" GAME_PROFILE_DIR="$PROFILES" sh "$STEP9_BIN/game-profile" use performance)"; step9_assert_contains "$OUT" 'Temporary profile override' 'profile use sets a session-only override'
OUT="$(GAME_PROFILE_DATA_ROOT="$STEP9_TMP/override" GAME_PROFILE_DIR="$PROFILES" sh "$STEP9_BIN/game-profile" clear)"; step9_assert_contains "$OUT" 'cleared' 'profile clear removes the session-only override'
OUT="$(GAME_PROFILE_DATA_ROOT="$STEP9_TMP/auto" GAME_PROFILE_DIR="$PROFILES" GAME_DETECTOR_DATA_ROOT="$STEP9_FIXTURES/unknown-game" sh "$STEP9_BIN/game-profile" auto)"; step9_assert_contains "$OUT" 'AX AUTO GAME PROFILE' 'automatic profile selection command works'
