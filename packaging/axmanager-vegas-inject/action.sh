#!/system/bin/sh
# AxManager action contract: exact module directory resolution and fixed
# simulation-only output. This script never performs a real device action.
MODDIR=${0%/*}
RUNTIME="$MODDIR/runtime"

if [ ! -x "$RUNTIME/bin/vegas" ]; then
    printf '%s\n' 'VEGAS-inject: runtime is unavailable; no action was performed.' >&2
    exit 1
fi

PATH="$RUNTIME/bin:$RUNTIME/AX-T615-GAME-OPTIMIZER/bin:$PATH"
export PATH

exec sh "$RUNTIME/bin/vegas" action simulate
