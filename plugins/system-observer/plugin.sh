#!/usr/bin/env sh
# System Observer: fixed read-only VEGAS-inject adapter. It never executes metadata or controls hardware.
set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
APP_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
APP_META="$APP_ROOT/vegas.json"

usage() {
    cat <<'EOF'
Usage: system-observer {status|capabilities|inspect|snapshot}

System Observer exposes only predefined, non-sensitive, read-only application and host telemetry.
Unavailable sources are reported as UNKNOWN. No commands, metadata, hardware controls, or user files are executed.
EOF
}

json_escape() {
    printf '%s' "$1" | tr -d '\r\n' | sed 's/\\/\\\\/g; s/"/\\"/g'
}

unknown() {
    printf '%s' 'UNKNOWN'
}

app_version() {
    VALUE=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$APP_META" 2>/dev/null | head -n 1)
    [ -n "$VALUE" ] && printf '%s' "$VALUE" || unknown
}

uname_value() {
    FLAG="$1"
    if command -v uname >/dev/null 2>&1; then
        VALUE=$(uname "$FLAG" 2>/dev/null || :)
        [ -n "$VALUE" ] && printf '%s' "$VALUE" || unknown
    else
        unknown
    fi
}

safe_hostname() {
    if command -v hostname >/dev/null 2>&1; then
        VALUE=$(hostname 2>/dev/null || :)
        case "$VALUE" in
            ''|*[!A-Za-z0-9.-]*) unknown ;;
            *) printf '%s' "$VALUE" ;;
        esac
    else
        unknown
    fi
}

uptime_seconds() {
    if [ -r /proc/uptime ]; then
        VALUE=$(awk 'NF && $1 ~ /^[0-9]+(\.[0-9]+)?$/ { print int($1); exit }' /proc/uptime 2>/dev/null || :)
        [ -n "$VALUE" ] && printf '%s' "$VALUE" || unknown
    else
        unknown
    fi
}

meminfo_value() {
    KEY="$1"
    if [ -r /proc/meminfo ]; then
        VALUE=$(awk -v key="$KEY" '$1 == key ":" && $2 ~ /^[0-9]+$/ { print $2; exit }' /proc/meminfo 2>/dev/null || :)
        [ -n "$VALUE" ] && printf '%s' "$VALUE" || unknown
    else
        unknown
    fi
}

status() {
    printf 'PLUGIN_ID=system-observer\n'
    printf 'PLUGIN_NAME=System Observer\n'
    printf 'PLUGIN_STATUS=AVAILABLE\n'
    printf 'LIFECYCLE=ENABLED\n'
    printf 'READ_ONLY=YES\n'
    printf 'HARDWARE_WRITES=NO\n'
    printf 'FORBIDDEN_ACTIONS_BLOCKED=YES\n'
    printf 'TELEMETRY_POLICY=NON_SENSITIVE_ONLY\n'
}

capabilities() {
    printf 'PLUGIN_ID=system-observer\n'
    printf 'CAPABILITIES=status,capabilities,inspect,snapshot\n'
    printf 'TELEMETRY=application_version,os,architecture,hostname,kernel,uptime_seconds,memory_total_kb,memory_available_kb\n'
    printf 'READ_ONLY=YES\n'
    printf 'HARDWARE_WRITES=NO\n'
    printf 'FORBIDDEN_ACTIONS_BLOCKED=YES\n'
}

inspect() {
    status
    printf 'APPLICATION_VERSION=%s\n' "$(app_version)"
    printf 'OS=%s\n' "$(uname_value -s)"
    printf 'ARCHITECTURE=%s\n' "$(uname_value -m)"
    printf 'HOSTNAME=%s\n' "$(safe_hostname)"
    printf 'KERNEL=%s\n' "$(uname_value -r)"
    printf 'UPTIME_SECONDS=%s\n' "$(uptime_seconds)"
    printf 'MEMORY_TOTAL_KB=%s\n' "$(meminfo_value MemTotal)"
    printf 'MEMORY_AVAILABLE_KB=%s\n' "$(meminfo_value MemAvailable)"
}

snapshot() {
    APP_VERSION=$(app_version)
    OS=$(uname_value -s)
    ARCHITECTURE=$(uname_value -m)
    HOSTNAME=$(safe_hostname)
    KERNEL=$(uname_value -r)
    UPTIME=$(uptime_seconds)
    MEMORY_TOTAL=$(meminfo_value MemTotal)
    MEMORY_AVAILABLE=$(meminfo_value MemAvailable)
    printf '{'
    printf '"schema":"1",'
    printf '"source":"system-observer-read-only",'
    printf '"read_only":true,'
    printf '"plugin":{"id":"system-observer","name":"System Observer","lifecycle":"ENABLED","status":"AVAILABLE"},'
    printf '"system":{'
    printf '"application_version":"%s",' "$(json_escape "$APP_VERSION")"
    printf '"os":"%s",' "$(json_escape "$OS")"
    printf '"architecture":"%s",' "$(json_escape "$ARCHITECTURE")"
    printf '"hostname":"%s",' "$(json_escape "$HOSTNAME")"
    printf '"kernel":"%s",' "$(json_escape "$KERNEL")"
    printf '"uptime_seconds":"%s",' "$(json_escape "$UPTIME")"
    printf '"memory_total_kb":"%s",' "$(json_escape "$MEMORY_TOTAL")"
    printf '"memory_available_kb":"%s"' "$(json_escape "$MEMORY_AVAILABLE")"
    printf '},'
    printf '"safety":{"read_only":"YES","hardware_writes":"NO","forbidden_actions_blocked":"YES","sensitive_information":"NOT_COLLECTED"}'
    printf '}\n'
}

case "${1:-help}" in
    status) status ;;
    capabilities) capabilities ;;
    inspect) inspect ;;
    snapshot) snapshot ;;
    help|-h|--help) usage ;;
    *) usage >&2; exit 2 ;;
esac
