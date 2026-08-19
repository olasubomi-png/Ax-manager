# Action Safety Gate

`action-gate` is the public, fixed VEGAS-inject action boundary. It is a **simulation-only safety gate**, not a command runner, device optimizer, profile applier, process manager, game controller, network client, or hardware-control interface.

## Fixed operations

| Operation | Result |
|---|---|
| `status` | Reports the default deny state, supported fixed operations, bounded-audit policy, and `real_action: NONE`. |
| `evaluate` | Derives the sole candidate request from `policy-engine snapshot` and validates policy safety, evidence quality, freshness, and confidence. |
| `simulate` | Emits a deterministic `SIMULATED_RECOMMENDATION` or `BLOCKED` result and appends one bounded non-sensitive audit record. |
| `capabilities` | Lists the fixed operation set, explicit blocked categories, absence of a real action layer, and no-dynamic-dispatch contract. |

## Gate rules

No operation accepts an action identifier, executable command, path, profile, setting, package, process, game, device target, or hardware-control argument. Every request is derived by the engine from the fixed policy snapshot. The gate fails closed for unknown, unavailable, stale, invalid, missing, malformed, unsafe, degraded, or low-confidence policy/evidence context. It returns a stable reason instead of guessing or attempting a recovery action.

`simulate` can record a maximum of sixteen local non-sensitive audit entries. An audit record documents a simulation decision only. It cannot represent an applied configuration, and no apply, rollback, lock, unlock, plan, or arbitrary-dispatch operation exists.

> **Evidence → Analysis → Policy → Recommendation → Action Gate → [Future Real Action Layer]** ends at the gate. The future layer is not implemented. The gate cannot alter hardware, Android settings, charging, thermal behavior, memory policy, processes, games, profiles, packages, files outside its own bounded audit record, or network state.
