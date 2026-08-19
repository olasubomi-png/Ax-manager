#!/usr/bin/env sh
# VEGAS-inject plugin adapter: fixed, read-only operation allowlist over AXGO compatibility commands.
set -u

PLUGIN_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
APP_ROOT=$(CDPATH= cd -- "$PLUGIN_DIR/../.." && pwd)
MODULE_ROOT="$APP_ROOT/AX-T615-GAME-OPTIMIZER"
AXGO="$MODULE_ROOT/bin/axgo"
DASHBOARD="$MODULE_ROOT/bin/dashboard"

usage() {
    cat <<'EOF'
Usage: plugin.sh {status|capabilities|games|game-detection|profiles|fps-analysis|performance-analysis|memory-monitoring|thermal-monitoring|power-telemetry|orchestrator-status|dashboard [path|snapshot|core-snapshot]|dry-run}

This is a fixed read-only operation allowlist. No plugin metadata is executed.
EOF
}

case "${1:-status}" in
    status) exec sh "$AXGO" status ;;
    capabilities) exec sh "$AXGO" capabilities ;;
    games) exec sh "$AXGO" games ;;
    game-detection) exec sh "$AXGO" game detect ;;
    profiles) exec sh "$AXGO" game profile list ;;
    fps-analysis) exec sh "$AXGO" fps status ;;
    performance-analysis) exec sh "$AXGO" performance analyze ;;
    memory-monitoring) exec sh "$AXGO" memory status ;;
    thermal-monitoring) exec sh "$AXGO" thermal status ;;
    power-telemetry) exec sh "$AXGO" power status ;;
    orchestrator-status) exec sh "$AXGO" orchestrator status ;;
    dashboard)
        case "${2:-path}" in
            path|snapshot|core-snapshot) exec sh "$DASHBOARD" "${2:-path}" ;;
            *) usage >&2; exit 2 ;;
        esac
        ;;
    dry-run)
        sh "$AXGO" orchestrator dry-run
        STATUS=$?
        [ "$STATUS" -eq 0 ] && printf 'HARDWARE_WRITES_PERFORMED=NO\n'
        exit "$STATUS"
        ;;
    help|-h|--help) usage ;;
    *) usage >&2; exit 2 ;;
esac
