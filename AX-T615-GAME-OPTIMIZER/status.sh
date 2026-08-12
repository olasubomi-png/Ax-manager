#!/system/bin/sh

getprop_safe() {
    if command -v getprop >/dev/null 2>&1; then
        getprop "$1" 2>/dev/null
    fi
}

first_nonempty() {
    VALUE="$1"
    [ -n "$VALUE" ] && echo "$VALUE" && return 0
    VALUE="$2"
    [ -n "$VALUE" ] && echo "$VALUE" && return 0
    echo "unknown"
}

MANUFACTURER="$(first_nonempty "$(getprop_safe ro.product.manufacturer)" "$(getprop_safe ro.product.brand)")"
MODEL="$(getprop_safe ro.product.model)"
ANDROID_VERSION="$(first_nonempty "$(getprop_safe ro.build.version.release)" "$(getprop_safe ro.build.version.sdk)")"
KERNEL_VERSION="$(uname -r 2>/dev/null)"
CPU_ABI="$(first_nonempty "$(getprop_safe ro.product.cpu.abi)" "$(uname -m 2>/dev/null)")"

if command -v getconf >/dev/null 2>&1; then
    CPU_CORES="$(getconf _NPROCESSORS_ONLN 2>/dev/null)"
fi
[ -n "$CPU_CORES" ] || CPU_CORES="$(grep -c '^processor' /proc/cpuinfo 2>/dev/null)"
[ -n "$CPU_CORES" ] || CPU_CORES="unknown"

RAM_MB="unknown"
if [ -r /proc/meminfo ]; then
    RAM_KB="$(awk '/^MemTotal:/ {print $2; exit}' /proc/meminfo 2>/dev/null)"
    [ -n "$RAM_KB" ] && RAM_MB="$((RAM_KB / 1024))"
fi

REFRESH_RATE="unknown"
if command -v settings >/dev/null 2>&1; then
    REFRESH_RATE="$(settings get system peak_refresh_rate 2>/dev/null)"
    [ "$REFRESH_RATE" = "null" ] && REFRESH_RATE=""
fi
if [ -z "$REFRESH_RATE" ] && command -v dumpsys >/dev/null 2>&1; then
    REFRESH_RATE="$(dumpsys display 2>/dev/null | grep -m 1 -Eo '[0-9]+(\.[0-9]+)? ?Hz' | head -n 1)"
fi
[ -n "$REFRESH_RATE" ] || REFRESH_RATE="unknown"

GPU_INFO="$(getprop_safe ro.hardware.egl)"
[ -n "$GPU_INFO" ] || GPU_INFO="$(getprop_safe ro.hardware.vulkan)"
[ -n "$GPU_INFO" ] || GPU_INFO="unknown"

if command -v id >/dev/null 2>&1 && [ "$(id -u 2>/dev/null)" = "0" ]; then
    ROOT_STATUS="yes"
else
    ROOT_STATUS="no"
fi

if [ -w /sys ]; then
    SYS_WRITABLE="yes"
else
    SYS_WRITABLE="no"
fi

echo "AX-T615 Game Optimizer status"
echo "Device: $(first_nonempty "$MODEL" "unknown")"
echo "Manufacturer: $MANUFACTURER"
echo "Android version: $ANDROID_VERSION"
echo "Kernel version: $(first_nonempty "$KERNEL_VERSION" "unknown")"
echo "CPU ABI: $CPU_ABI"
echo "CPU core count: $CPU_CORES"
echo "Available RAM: ${RAM_MB} MB"
echo "Current refresh rate: $REFRESH_RATE"
echo "GPU information: $GPU_INFO"
echo "Root available: $ROOT_STATUS"
echo "/sys writable: $SYS_WRITABLE"
echo "Diagnostics are read-only; no settings were changed."

exit 0