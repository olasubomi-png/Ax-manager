#!/system/bin/sh

MODDIR="${MODDIR:-${MODPATH:-}}"
echo "AX-T615 Game Optimizer uninstall"
echo "No system settings or hardware controls were modified by this foundation build."

# Only remove a module-owned runtime log if one exists. The module manager
# remains responsible for removing the installed module directory.
if [ -n "$MODDIR" ] && [ -f "$MODDIR/service.log" ]; then
    rm -f "$MODDIR/service.log"
fi

echo "Nothing to restore."
exit 0