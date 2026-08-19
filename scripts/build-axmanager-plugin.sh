#!/usr/bin/env sh
# AxManager v1.4.8 packaging contract: copy fixed repository-owned VEGAS runtime
# files only; no installer, lifecycle, network, or device-control behavior.
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEMPLATE="$ROOT/packaging/axmanager-vegas-inject"
DIST="$ROOT/dist"
MODULE="$DIST/vegas-inject"
ZIPFILE="$DIST/vegas-inject.zip"

rm -rf "$MODULE" "$ZIPFILE"
mkdir -p "$MODULE/runtime" "$MODULE/runtime/AX-T615-GAME-OPTIMIZER" "$MODULE/webroot"

install -m 0644 "$TEMPLATE/module.prop" "$MODULE/module.prop"
install -m 0755 "$TEMPLATE/action.sh" "$MODULE/action.sh"
install -m 0755 "$TEMPLATE/uninstall.sh" "$MODULE/uninstall.sh"
install -m 0644 "$TEMPLATE/README.md" "$MODULE/README.md"
install -m 0644 "$TEMPLATE/webroot/index.html" "$MODULE/webroot/index.html"

mkdir -p "$MODULE/runtime/bin" "$MODULE/runtime/plugins" "$MODULE/runtime/AX-T615-GAME-OPTIMIZER/bin"
for entry in action-engine action-gate axgo bottleneck-engine control-plane evidence-engine plugin-manager policy-engine vegas; do
    install -m 0755 "$ROOT/bin/$entry" "$MODULE/runtime/bin/$entry"
done

install -m 0644 "$ROOT/plugins/registry.json" "$MODULE/runtime/plugins/registry.json"
for plugin in ax-t615-game-optimizer performance-observer system-observer; do
    mkdir -p "$MODULE/runtime/plugins/$plugin"
    install -m 0644 "$ROOT/plugins/$plugin/plugin.json" "$MODULE/runtime/plugins/$plugin/plugin.json"
    install -m 0755 "$ROOT/plugins/$plugin/plugin.sh" "$MODULE/runtime/plugins/$plugin/plugin.sh"
done

cp -R "$ROOT/AX-T615-GAME-OPTIMIZER/bin/." "$MODULE/runtime/AX-T615-GAME-OPTIMIZER/bin/"
cp -R "$ROOT/AX-T615-GAME-OPTIMIZER/config" "$MODULE/runtime/AX-T615-GAME-OPTIMIZER/config"
install -m 0644 "$ROOT/vegas.json" "$MODULE/runtime/vegas.json"

find "$MODULE/runtime/bin" "$MODULE/runtime/AX-T615-GAME-OPTIMIZER/bin" -type f -exec chmod 0755 {} \;
find "$MODULE" -type d -exec chmod 0755 {} \;

(
    cd "$MODULE"
    zip -X -q -r "$ZIPFILE" .
)

printf '%s\n' "Built AxManager module: $MODULE"
printf '%s\n' "Built AxManager ZIP: $ZIPFILE"
