#!/usr/bin/env sh
set -u
. "$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)/step9_test_lib.sh"
KNOWN="$STEP9_FIXTURES/known-game"
BEFORE="$(step9_hash_tree "$KNOWN")"
OUT="$(GAME_DETECTOR_DATA_ROOT="$KNOWN" GAME_PROFILE_DIR="$KNOWN" sh "$STEP9_BIN/game-detector" active)"
step9_assert_contains "$OUT" 'PACKAGE:' 'known fixture emits package label'
step9_assert_contains "$OUT" 'com.example.verified' 'known fixture extracts verified package'
step9_assert_contains "$OUT" 'fixture-verified' 'known fixture resolves profile mapping'
OUT="$(GAME_DETECTOR_DATA_ROOT="$STEP9_FIXTURES/unknown-game" GAME_PROFILE_DIR="$KNOWN" sh "$STEP9_BIN/game-detector" active)"
step9_assert_contains "$OUT" 'UNKNOWN' 'unknown fixture fails safe'
OUT="$(GAME_DETECTOR_DATA_ROOT="$STEP9_FIXTURES/malformed-package" GAME_PROFILE_DIR="$KNOWN" sh "$STEP9_BIN/game-detector" active)"
step9_assert_contains "$OUT" 'UNKNOWN' 'malformed package fails safe'
OUT="$(GAME_DETECTOR_DATA_ROOT="$STEP9_FIXTURES/missing-package" GAME_PROFILE_DIR="$KNOWN" sh "$STEP9_BIN/game-detector" active)"
step9_assert_contains "$OUT" 'UNKNOWN' 'missing package fails safe'
OUT="$(GAME_DETECTOR_DATA_ROOT="$KNOWN" GAME_PROFILE_DIR="$KNOWN" sh "$STEP9_BIN/game-detector" package com.example.verified)"
step9_assert_contains "$OUT" 'PROFILE: fixture-verified' 'explicit verified package maps to profile'
AFTER="$(step9_hash_tree "$KNOWN")"
[ "$BEFORE" = "$AFTER" ] && step9_pass 'game detector fixtures remain unchanged' || step9_fail 'game detector modified fixtures'
