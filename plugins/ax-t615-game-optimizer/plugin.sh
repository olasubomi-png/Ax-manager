#!/usr/bin/env sh
# VEGAS-inject plugin adapter: fixed, read-only operation allowlist over AXGO compatibility commands.
set -u

PLUGIN_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
APP_ROOT=$(CDPATH= cd -- "$PLUGIN_DIR/../.." && pwd)
MODULE_ROOT="$APP_ROOT/AX-T615-GAME-OPTIMIZER"
AXGO="$MODULE_ROOT/bin/axgo"
DASHBOARD="$MODULE_ROOT/bin/dashboard"
EVIDENCE_ENGINE="$APP_ROOT/bin/evidence-engine"
BOTTLENECK_ENGINE="$APP_ROOT/bin/bottleneck-engine"
POLICY_ENGINE="$APP_ROOT/bin/policy-engine"
ACTION_ENGINE="$APP_ROOT/bin/action-engine"
ACTION_GATE="$APP_ROOT/bin/action-gate"
CONTROL_PLANE="$APP_ROOT/bin/control-plane"

usage() {
    cat <<'EOF'
Usage: plugin.sh {status|capabilities|games|game-detection|profiles|fps-analysis|performance-analysis|memory-monitoring|thermal-monitoring|power-telemetry|orchestrator-status|evidence {status|capabilities|inspect|evaluate|snapshot|history}|analysis {status|analyze|snapshot|capabilities}|policy {status|evaluate|snapshot|capabilities}|action {status|snapshot|capabilities|plan|validate|dry-run|apply|verify|rollback|history|lock|unlock|evaluate|simulate}|control {status|snapshot|evaluate|simulate|capabilities}|dashboard [path|snapshot|core-snapshot]|dry-run}

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
    evidence)
        case "${2:-status}" in
            status|capabilities|inspect|evaluate|snapshot|history) exec sh "$EVIDENCE_ENGINE" "${2:-status}" ;;
            *) usage >&2; exit 2 ;;
        esac
        ;;
    analysis)
        case "${2:-status}" in
            status|analyze|snapshot|capabilities) exec sh "$BOTTLENECK_ENGINE" "${2:-status}" ;;
            *) usage >&2; exit 2 ;;
        esac
        ;;
    policy)
        case "${2:-status}" in
            status|evaluate|snapshot|capabilities) exec sh "$POLICY_ENGINE" "${2:-status}" ;;
            *) usage >&2; exit 2 ;;
        esac
        ;;
    action)
        case "${2:-status}" in
            status|evaluate|simulate) exec sh "$ACTION_GATE" "${2:-status}" ;;
            snapshot|capabilities|history|lock) exec sh "$ACTION_ENGINE" "${2:-status}" ;;
            plan|validate|dry-run|verify|rollback|unlock) [ "$#" -eq 3 ] || { usage >&2; exit 2; }; exec sh "$ACTION_ENGINE" "$2" "$3" ;;
            apply) [ "$#" -eq 4 ] || { usage >&2; exit 2; }; exec sh "$ACTION_ENGINE" "$2" "$3" "$4" ;;
            *) usage >&2; exit 2 ;;
        esac
        ;;
    control)
        case "${2:-status}" in
            status|snapshot|evaluate|simulate|capabilities) exec sh "$CONTROL_PLANE" "${2:-status}" ;;
            *) usage >&2; exit 2 ;;
        esac
        ;;
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
