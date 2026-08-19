#!/usr/bin/env sh
set -u
. "$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)/step9_test_lib.sh"
FAIL=0
for FILE in "$STEP9_BIN/game-detector" "$STEP9_BIN/game-profile"; do
    grep -nE '(^|[;&|])[[:space:]]*(eval|system\(|exec[[:space:]]|sh[[:space:]]+-c|bash[[:space:]]+-c|setprop|sysctl|settings[[:space:]]+put|kill|pkill|am[[:space:]]+force-stop)|>[[:space:]]*/(proc|sys)|>>[[:space:]]*/(proc|sys)' "$FILE" 2>/dev/null | grep -v 'grep -Eq' > /tmp/step9-safety-match || :
    if [ -s /tmp/step9-safety-match ]; then
        echo "Forbidden Step 9 pattern in $FILE:" >&2; cat /tmp/step9-safety-match >&2; FAIL=1
    fi
done
[ "$FAIL" -eq 0 ] && step9_pass 'Step 9 core controllers contain no forbidden hardware or process writes' || step9_fail 'Step 9 static safety scan found forbidden writes'
