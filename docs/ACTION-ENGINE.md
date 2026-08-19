# VEGAS-inject Capability-Gated Action Engine

## Scope

The action engine is a **fixed, capability-gated planning layer**. It accepts only a small set of compiled-in action IDs and never accepts a shell fragment, executable path, package name, plugin command, free-form parameter, or hardware target. It separates a policy recommendation from a proposed action, a proposed action from validation, and validation from a real device effect.

> **Current release boundary:** The repository has no independently verified target-device optimization interface. Therefore `REAL_DEVICE_APPLY=NOT_AVAILABLE`, all device control capabilities are `UNVERIFIED`, and every public apply route is constrained to `--dry-run`.

| Action ID | Type | Capability state | Device effect |
|---|---|---|---|
| `refresh_telemetry` | Read-only observation | `SUPPORTED_READ_ONLY` | None |
| `profile_balanced_advisory` | Policy record | `SUPPORTED_POLICY_RECORD_ONLY` | None |
| `profile_performance_advisory` | Profile advisory | `UNSUPPORTED_DEVICE_CAPABILITY_UNVERIFIED` | None |
| `thermal_protection_advisory` | Thermal advisory | `UNSUPPORTED_DEVICE_CAPABILITY_UNVERIFIED` | None |
| `memory_conservative_advisory` | Memory advisory | `UNSUPPORTED_DEVICE_CAPABILITY_UNVERIFIED` | None |
| `battery_conservative_advisory` | Battery advisory | `UNSUPPORTED_DEVICE_CAPABILITY_UNVERIFIED` | None |

## Fixed operations

Use `sh bin/action-engine help` to display the complete interface. The public operations are `status`, `snapshot`, `capabilities`, `plan`, `validate`, `dry-run`, `apply <id> --dry-run`, `verify`, `rollback`, `history`, `lock`, and `unlock --explicit-unlock`.

`plan` reports the fixed action schema and its preconditions. `validate` checks the fixed ID, capability state, evidence quality, policy state, confidence, and read-only safety classification. `dry-run` appends a bounded local planning audit record only when the validated action has a supported non-device capability. `apply` rejects every request except its explicit dry-run spelling. `verify` and `rollback` record that no real device action exists to verify or reverse.

The action lock affects only dry-run planning state; it cannot unlock a device action. It starts enabled, and an explicit unlock still leaves `REAL_DEVICE_APPLY=NOT_AVAILABLE`.

## Mandatory safety gate

Unknown, stale, invalid, unavailable, or unsafe evidence denies planning. Unsupported device capabilities deny the action before any execution stage. The engine also blocks any identifier associated with CPU or GPU control, governors, frequencies, thermal or battery control, charging, power HAL, process control, memory subsystem control, `/proc`, `/sys`, Android properties, root, arbitrary shell or executable paths, networking, and plugin-defined commands.

The runtime writes only bounded, repository-local audit and dry-run lock records. These records contain no credentials, personal data, device modification state, or network transmission. They do not establish that an Android device was changed.

## CLI and dashboard integration

The following fixed routes are available:

```sh
sh bin/action-engine snapshot
sh bin/vegas action snapshot
sh AX-T615-GAME-OPTIMIZER/bin/axgo action snapshot
```

`vegas snapshot` now contains two distinct records: `action` for the capability-gated planning layer and `action_gate` for the existing simulation-only Action Safety Gate. The static AX-T615 dashboard displays capability state, real-device-apply status, safety gate, validation, fixed supported/unsupported actions, bounded audit count, verification/rollback status, and timestamp using `textContent` only. It contains no apply control and no browser-to-shell bridge.

## Prohibited behavior

This component does not write `/proc`, `/sys`, Android properties, governors, memory controls, charging controls, games, or arbitrary filesystem locations. It does not run `eval`, root escalation, process termination, `sysctl`, ZRAM or swap control, network transfers, or executable metadata. A future device-specific action cannot be added by configuration; it would require a separately reviewed fixed implementation, capability detection, validation, before/after evidence, verification, rollback semantics, test coverage, package update, and release review.
