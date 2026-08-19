# VEGAS-inject for AxManager

This archive is an **unrooted AxManager plugin module** for the fixed, read-only VEGAS-inject observability stack. Version `1.2.0-axmanager` adds a universal Android compatibility report alongside the capability-gated dry-run action planner, but it does not add a real device-apply capability. It is packaged for AxManager v1.4.8 with `axeronPlugin=14800`, the API version code derived by the official v1.4.8 source from `1 × 10,000 + 4 × 1,000 + 800`. [1] [2]

## Install and use

Install `vegas-inject.zip` with AxManager’s module installer. The archive root contains the required `module.prop`, a fixed `action.sh`, optional safe `uninstall.sh`, and `webroot/index.html` as required or recognized by AxManager’s documented plugin model. [1] The module must be installed as one folder under AxManager’s plugin directory; do not nest the extracted `vegas-inject` folder inside another directory.

The AxManager **Action** entry runs only `vegas action simulate`. It may report a blocked or simulated advisory record, but it never performs a real action. The capability-gated planner is visible through the included fixed runtime and still reports `REAL_DEVICE_APPLY=NOT_AVAILABLE` until a separately reviewed device interface exists. The AxManager **WebUI** is static and non-interactive; it presents the module identity and safety boundary without a browser-to-shell bridge.

## Runtime contents and limitations

The package includes only the existing fixed VEGAS command router, universal `device-compatibility` report engine, policy/evidence/control-plane components, Action Safety Gate, AX-T615 read-only adapter scripts, static configuration, and declarative plugin files. The fixed route `vegas device snapshot` explains normalized non-identifying compatibility evidence, but it does not inspect writable device control paths or unlock optimization controls. The package excludes the source repository, Git metadata, tests, logs, generated runtime state, dashboards with live browser refresh mechanisms, secrets, and personal information.

No module lifecycle service or boot script is included. The plugin does not write device settings, `/proc`, `/sys`, Android properties, governors, ZRAM, swap, LMK/OOM state, or charging state. It performs no network access, process termination, arbitrary command forwarding, dynamic metadata execution, or real action execution. A bounded local dry-run audit is the only runtime state. Uninstalling the module requires no device rollback because no device state is modified. See [`docs/ANDROID-COMPATIBILITY.md`](../../docs/ANDROID-COMPATIBILITY.md), [`docs/ACTION-ENGINE.md`](../../docs/ACTION-ENGINE.md), and [`docs/ON_DEVICE_VALIDATION.md`](../../docs/ON_DEVICE_VALIDATION.md) in the source repository for the complete compatibility, action, and validation contracts.

## References

[1]: https://fahrez182.github.io/AxManager/plugin/what-is-plugin.html "AxManager official plugin documentation"
[2]: https://github.com/fahrez182/AxManager/tree/79500fc447af7545068c684ca0ac5be994d75752 "AxManager v1.4.8 official source"
