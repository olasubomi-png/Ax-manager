#!/system/bin/sh

MESSAGE="AX-T615 Game Optimizer service initialized"

if command -v log >/dev/null 2>&1; then
    log -t AX-T615-GAME-OPTIMIZER "$MESSAGE" 2>/dev/null
fi
echo "$MESSAGE"

# Foundation stage: intentionally no CPU, GPU, thermal, RAM, network,
# refresh-rate, or system-property changes are performed.
exit 0