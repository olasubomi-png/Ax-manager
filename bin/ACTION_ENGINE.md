# Controlled Action Engine

`action-engine` is the fixed Phase 9 VEGAS-inject managed-state action component. It is **not** a device optimizer, command runner, shell wrapper, hardware controller, process manager, network client, or profile executor.

## Fixed interface

| Operation | Behavior |
|---|---|
| `status` / `snapshot` / `capabilities` | Describe the fixed registry, dry-run mode, lock, validation boundary, rollback scope, and no-control contract. |
| `plan` / `validate` / `dry-run` | Produce deterministic non-applying records for the policy-selected fixed action. |
| `unlock` / `lock` | Release or restore the engine-owned emergency lock; unlock requires fresh `HEALTHY` or `VALID` safety evidence. |
| `apply` | Requires an unlocked engine, explicit operation selection, fresh safety evidence, an allowed fixed identifier, cooldown availability, and the engine-owned execution lock. |
| `rollback` | Removes only the engine-owned managed marker and writes a bounded audit result. |
| `history` | Shows no more than sixteen local, non-sensitive audit records. |

## Immutable action boundary

The immutable allowed identifiers are `refresh_telemetry`, `clear_runtime_state`, and `reset_recommendation_state`. They resolve internally to `refresh_managed_recommendation_state`, which writes only a VEGAS-inject runtime marker. Blocked categories include direct or indirect CPU/GPU, governor, frequency, display, Power HAL, charging, thermal, battery, memory, ZRAM, swap, LMKD/OOM, Android-property, process, game, package, network, filesystem-target, arbitrary-path, and arbitrary-command operations.

> The engine follows **Recommendation → Action Plan → Validation → Dry Run → Explicit Apply → Verification → Rollback**. It never turns a recommendation into a device action. Its only reversible mutation is an engine-owned local marker and its bounded audit/lock state.

## Safety rules

The default lock is enabled and dry run is the default mode. Unknown, stale, invalid, unavailable, unsafe, or degraded evidence cannot unlock the action engine. An apply request fails closed if the allowed identifier, lock state, evidence quality, cooldown, concurrency state, or managed-state target is not valid. No caller argument is interpolated into a command, path, or target.

Rollback uses a fixed operation and can remove only the specific managed marker recorded by this engine. It cannot undo, create, or alter a device setting because the engine never creates one.
