# VEGAS-inject v1.0 Release

VEGAS-inject v1.0 is the final release of a **read-only observability, analysis, policy, recommendation, and simulation platform**. It is designed for Termux and Android-readable environments, with an AX-T615 compatibility module for the Tecno POP 9 / Unisoc T615 class. It is not a hardware optimizer, device-control utility, game injector, or privileged Android module.

## Scope

The public product path is fixed:

```text
Evidence → Analysis → Policy → Recommendation → Action Safety Gate → [Future Real Action Layer]
```

The bracketed future layer is **not implemented**. The public Action Safety Gate can only evaluate or simulate an internally derived advisory recommendation. The VEGAS Control Plane composes existing component outputs and delegates simulation only to that gate. Neither surface can apply, roll back, target, or execute a device action.

| Public surface | Stable v1.0 contract |
|---|---|
| `bin/vegas` | Fixed unified commands for platform, plugins, observers, evidence, analysis, policy, action-gate simulation, control-plane observation, and AX-T615 compatibility. |
| `bin/axgo` | Compatibility bridge to the hardened AX-T615 fixed router. |
| `bin/plugin-manager` | Fixed registry, bounded declarative metadata validation, and allowlisted adapters only. |
| AX-T615 `bin/axgo` | Read-only compatibility reports plus fixed `dashboard`, `evidence`, `policy`, `action`, and `control` aliases. |
| Static dashboard | Text-only rendering of validated snapshots; no command bridge or mutable control. |

## Explicit non-features

The v1.0 release does not perform hardware writes, `/proc` or `/sys` writes, Android property changes, Power HAL changes, CPU or GPU governor changes, display changes, charging changes, thermal changes, ZRAM or swap changes, LMK/OOM changes, process termination, game injection, network control, shell evaluation, dynamic executable dispatch, or arbitrary path execution. It does not collect credentials, account data, personal files, messages, or persistent identifiers.

Unknown, unavailable, stale, invalid, malformed, insufficient-confidence, or unprovenanced evidence is kept distinct and results in conservative advisory output. A simulation audit is bounded, repository-local, and never represents an applied state.

## Documentation and verification records

The complete architecture is described in [`README.md`](README.md), the AX-T615 compatibility surface in [`AX-T615-GAME-OPTIMIZER/README.md`](AX-T615-GAME-OPTIMIZER/README.md), the dashboard boundary in [`AX-T615-GAME-OPTIMIZER/dashboard/README.md`](AX-T615-GAME-OPTIMIZER/dashboard/README.md), the plugin model in [`plugins/README.md`](plugins/README.md), and the complete safety model in [`SAFETY-MODEL.md`](SAFETY-MODEL.md).

The machine-readable release capability declaration is [`release/capabilities.json`](release/capabilities.json). The executed final verification record is maintained in [`release/FINAL-VERIFICATION.md`](release/FINAL-VERIFICATION.md); the production hardening threat model and audit are maintained in [`security/SECURITY-AUDIT.md`](security/SECURITY-AUDIT.md) and [`security/audit-report.json`](security/audit-report.json).
