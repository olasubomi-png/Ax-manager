# VEGAS-inject Plugin Model

Plugins are declarative records registered in `plugins/registry.json`. The registry and metadata are data, not executable configuration. `bin/plugin-manager` validates the fixed registry path, the plugin identifier, bounded metadata shape, known capability declarations, fixed `plugin.sh` entrypoint, and mandatory `read_only: true` and `hardware_writes: false` declarations before invoking a fixed adapter operation.

The v1.0 product bundles AX-T615 Game Optimizer, System Observer, and Performance Observer. Their public operations are fixed by `bin/plugin-manager`; an adapter does not receive arbitrary command text, a caller-selected path, a shell fragment, or an executable metadata field.

| Rejected declaration or input | Reason |
|---|---|
| Traversal or absolute paths | Plugins cannot redirect execution outside the trusted repository layout. |
| `command`, `script`, `exec`, `shell`, or action metadata | Metadata cannot define executable behavior. |
| URLs or remote references | Plugins have no remote loading or network-control capability. |
| Unknown IDs, capabilities, operations, or surplus arguments | Public routing is fixed and fail-closed. |
| Write-capable or control-oriented declarations | v1.0 is read-only and contains no real action layer. |

For the product-level command map, see [`../README.md`](../README.md). For the independent hardening audit, see [`../security/SECURITY-AUDIT.md`](../security/SECURITY-AUDIT.md).
