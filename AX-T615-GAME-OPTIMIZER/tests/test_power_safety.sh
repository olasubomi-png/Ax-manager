#!/usr/bin/env sh
set -u
TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
MODULE_ROOT="$(CDPATH= cd -- "$TEST_DIR/.." && pwd)"
FILES="$MODULE_ROOT/bin/power-controller $MODULE_ROOT/bin/power-guard $MODULE_ROOT/bin/power-monitor"
CODE="$(for FILE in $FILES; do sed '/^[[:space:]]*#/d' "$FILE"; done)"
FORBIDDEN='(^|[^A-Za-z])(setprop|settings[[:space:]]+put|cmd[[:space:]]+power|svc[[:space:]]+(power|usb)|kill[[:space:]]|pkill[[:space:]]|am[[:space:]]+(force-stop|kill)|dumpsys[[:space:]]+deviceidle|Power[[:space:]]+HAL|battery[[:space:]]+(bypass|charge|set)|charging[[:space:]]+(limit|bypass|set)|echo[[:space:]].*>[[:space:]]*/(proc|sys)|printf[[:space:]].*>[[:space:]]*/(proc|sys))'
if printf '%s\n' "$CODE" | grep -Eiq "$FORBIDDEN"; then
    echo 'FORBIDDEN_POWER_WRITE'
    printf '%s\n' "$CODE" | grep -Ein "$FORBIDDEN"
    exit 1
fi
printf '%s\n' 'NO_FORBIDDEN_POWER_WRITES'
