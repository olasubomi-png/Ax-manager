#!/usr/bin/env sh
set -u
. "$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)/step9_test_lib.sh"
PROFILES="$STEP9_ROOT/config/game-profiles"
OUT="$(GAME_PROFILE_DATA_ROOT="$STEP9_TMP/valid" GAME_PROFILE_DIR="$PROFILES" sh "$STEP9_BIN/game-profile" validate)"
step9_assert_contains "$OUT" 'PROFILE VALIDATION: PASS' 'production profiles validate'
OUT="$(GAME_PROFILE_DATA_ROOT="$STEP9_TMP/list" GAME_PROFILE_DIR="$PROFILES" sh "$STEP9_BIN/game-profile" list)"
for mode in BATTERY COOL BALANCED PERFORMANCE COMPETITIVE DEFAULT_SAFE; do step9_assert_contains "$OUT" "$mode" "profile list includes $mode"; done
for name in invalid malicious missing-fields; do
  DIR="$STEP9_TMP/$name"; mkdir -p "$DIR"; cp "$STEP9_FIXTURES/profiles/$name/profile.json" "$DIR/profile.json"
  if GAME_PROFILE_DATA_ROOT="$STEP9_TMP/$name-data" GAME_PROFILE_DIR="$DIR" sh "$STEP9_BIN/game-profile" validate >/tmp/step9-$name.out 2>&1; then
    step9_fail "$name profile is rejected by validation"
  else
    step9_pass "$name profile is rejected by validation"
  fi
done
INDEX="$PROFILES/index.json"
step9_assert_contains "$(cat "$INDEX")" '"packages": {}' 'production package index remains empty without verified identifiers'
