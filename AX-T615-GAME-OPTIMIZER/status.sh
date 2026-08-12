#!/system/bin/sh

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
DETECTOR="$SCRIPT_DIR/bin/detector"

if [ ! -x "$DETECTOR" ]; then
    echo "AX-T615 detector is unavailable."
    exit 1
fi

exec sh "$DETECTOR" --summary