#!/system/bin/sh

# Development-only, unprivileged checks for the read-only diagnostic engine.
# The test suite never writes to /sys, /proc, Android properties, or settings.

TEST_DIR="$(CDPATH= cd -- "$(dirname "$0")" 2>/dev/null && pwd)"
ROOT_DIR="$(CDPATH= cd -- "$TEST_DIR/.." 2>/dev/null && pwd)"
DETECTOR="$ROOT_DIR/bin/detector"
CAPABILITIES="$ROOT_DIR/bin/capabilities"
STATUS="$ROOT_DIR/status.sh"
SHELL_BIN="$(command -v sh 2>/dev/null || printf '%s' sh)"

FAILURES=0

pass() {
    echo "PASS: $1"
}

fail() {
    echo "FAIL: $1"
    FAILURES=$((FAILURES + 1))
}

require_file() {
    if [ -f "$1" ]; then
        pass "file exists: $1"
    else
        fail "missing file: $1"
    fi
}

require_file "$DETECTOR"
require_file "$CAPABILITIES"
require_file "$STATUS"

for FILE in "$DETECTOR" "$CAPABILITIES" "$STATUS" "$ROOT_DIR/bin/axgo"; do
    if [ -f "$FILE" ] && sh -n "$FILE" 2>/dev/null; then
        pass "shell syntax: $FILE"
    else
        fail "shell syntax: $FILE"
    fi
done

if grep -n -E '(^|[;&|[:space:]])(setprop|sysctl|tee|dd|chmod|chown)[[:space:]]' \
    "$DETECTOR" "$CAPABILITIES" "$STATUS" >/dev/null 2>&1; then
    fail "diagnostic scripts contain a prohibited write command"
else
    pass "no prohibited write commands in diagnostic scripts"
fi

if grep -n -E '(^|[;&|[:space:]])(kill|killall|pkill)[[:space:]]' \
    "$DETECTOR" "$CAPABILITIES" "$STATUS" >/dev/null 2>&1; then
    fail "diagnostic scripts contain a process-kill command"
else
    pass "no process-kill commands in diagnostic scripts"
fi

OUTPUT_FILE="${TMPDIR:-/tmp}/axgo-detector-test.$$"
trap 'rm -f "$OUTPUT_FILE"' EXIT HUP INT TERM

if sh "$DETECTOR" --summary > "$OUTPUT_FILE" 2>&1; then
    pass "detector runs without root"
else
    fail "detector failed without root"
fi

if grep -q "No hardware settings were changed" "$OUTPUT_FILE"; then
    pass "summary declares read-only behavior"
else
    fail "summary did not declare read-only behavior"
fi

MISSING_COMMAND_OUTPUT="${OUTPUT_FILE}.missing-command"
if PATH="/definitely-missing-command-path" "$SHELL_BIN" "$DETECTOR" --summary > "$MISSING_COMMAND_OUTPUT" 2>&1; then
    pass "detector handles missing optional commands"
else
    fail "detector failed when optional commands were unavailable"
fi
rm -f "$MISSING_COMMAND_OUTPUT"

if sh "$DETECTOR" --report > "$OUTPUT_FILE" 2>&1; then
    if grep -q "unavailable\|permission denied" "$OUTPUT_FILE"; then
        pass "missing or inaccessible sysfs nodes are reported safely"
    else
        pass "report completed with available host nodes"
    fi
else
    fail "detailed detector report failed"
fi

if [ "$(id -u 2>/dev/null)" = "0" ]; then
    echo "INFO: running as UID 0; non-root behavior check skipped"
else
    if sh "$DETECTOR" --summary >/dev/null 2>&1; then
        pass "non-root execution"
    else
        fail "non-root execution"
    fi
fi

# No Android getprop in a normal development shell is an unsupported-target
# simulation for the installer; it must exit without changing anything.
if sh "$ROOT_DIR/customize.sh" >/dev/null 2>&1; then
    fail "unsupported environment was accepted by customize.sh"
else
    pass "unsupported environment exits safely"
fi

if [ "$FAILURES" -eq 0 ]; then
    echo "All detector tests passed."
    exit 0
fi

echo "$FAILURES detector test(s) failed."
exit 1