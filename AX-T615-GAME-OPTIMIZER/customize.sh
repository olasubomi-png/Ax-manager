#!/system/bin/sh

MODNAME="AX-T615 Game Optimizer"

ui_print_safe() {
    if command -v ui_print >/dev/null 2>&1; then
        ui_print "$1"
    else
        echo "$1"
    fi
}

getprop_safe() {
    if command -v getprop >/dev/null 2>&1; then
        getprop "$1" 2>/dev/null
    fi
}

ARCH="$(getprop_safe ro.product.cpu.abi)"
[ -n "$ARCH" ] || ARCH="$(uname -m 2>/dev/null)"
MANUFACTURER="$(getprop_safe ro.product.manufacturer)"
[ -n "$MANUFACTURER" ] || MANUFACTURER="$(getprop_safe ro.product.brand)"
MODEL="$(getprop_safe ro.product.model)"
SOC="$(getprop_safe ro.soc.model)"
[ -n "$SOC" ] || SOC="$(getprop_safe ro.board.platform)"
[ -n "$SOC" ] || SOC="$(getprop_safe ro.hardware)"

ui_print_safe "*******************************"
ui_print_safe "$MODNAME"
ui_print_safe "*******************************"
ui_print_safe "Architecture: ${ARCH:-unknown}"
ui_print_safe "Manufacturer: ${MANUFACTURER:-unknown}"
ui_print_safe "Model: ${MODEL:-unknown}"
ui_print_safe "SoC: ${SOC:-unknown}"
ui_print_safe "Foundation install: no performance changes"

TARGET_DATA="${MANUFACTURER} ${MODEL} ${SOC}"
if ! echo "$TARGET_DATA" | grep -Eiq 'tecno|pop[ -]?9|t7250|t615'; then
    ui_print_safe "Unsupported environment: intended Tecno POP 9 / T7250 target not detected."
    ui_print_safe "No system or hardware changes were made."
    exit 1
fi

ui_print_safe "Target appears compatible."
ui_print_safe "No CPU, GPU, thermal, RAM, network, property, or refresh-rate changes performed."
exit 0