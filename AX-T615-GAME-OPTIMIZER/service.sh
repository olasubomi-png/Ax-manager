#!/system/bin/sh
set -u

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
AXGO_ROOT="${AXGO_ROOT:-$SCRIPT_DIR}"
. "$AXGO_ROOT/bin/lib"

MESSAGE="VEGAS-inject AX-T615 Game Optimizer service initialized"
axgo_ensure_runtime || :
axgo_log INFO "$MESSAGE"
if command -v log >/dev/null 2>&1; then
    log -t VEGAS-INJECT-AX-T615 "$MESSAGE" 2>/dev/null || :
fi
echo "$MESSAGE"

GAME_MONITOR_AUTOSTART="${GAME_MONITOR_AUTOSTART:-true}"
if [ "$GAME_MONITOR_AUTOSTART" = "true" ] &&
   [ -x "$AXGO_ROOT/bin/game-monitor" ] &&
   command -v sh >/dev/null 2>&1; then
    if mkdir "$AXGO_RUNTIME_DIR/game-monitor.lock" 2>/dev/null; then
        (sh "$AXGO_ROOT/bin/game-monitor" --daemon --lock-held >/dev/null 2>&1) &
        MONITOR_PID="$!"
        axgo_write_state game-monitor.pid "$MONITOR_PID" || :
        echo "Gaming detection monitor initialized."
    else
        echo "Gaming detection monitor already initialized."
    fi
else
    echo "Gaming detection monitor autostart disabled."
fi

# The service still performs no CPU, GPU, thermal, RAM, network, refresh-rate,
# property, or other performance modification.
exit 0
