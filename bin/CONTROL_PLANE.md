# VEGAS Control Plane

`bin/control-plane` is the **Phase 10 Unified Orchestration & Control-Plane Integration** entry point. It composes the existing fixed Evidence Engine, Bottleneck Analysis Engine, Policy Engine, Action Safety Gate, AX-T615 orchestrator status, and plugin-manager health output into one deterministic, read-only snapshot.

> The control plane is an observability and simulation boundary. It is **not** a real action layer, a hardware-control utility, a shell bridge, or a mechanism for passing caller-defined action identifiers or targets.

## Fixed interface

| Command | Output | Safety property |
|---|---|---|
| `sh bin/control-plane status` | Human-readable lifecycle, stage, recommendation, and safety summary | Reads fixed component outputs only. |
| `sh bin/control-plane snapshot` | Normalized JSON envelope | Declares `read_only: true` and `simulation_only: true`. |
| `sh bin/control-plane evaluate` | Deterministic read-only evaluation | Does not create an action request or audit record. |
| `sh bin/control-plane simulate` | Deterministic simulated result | Delegates only to the existing Action Safety Gate simulation path. |
| `sh bin/control-plane capabilities` | Fixed capability report | Declares blocked hardware, process, network, arbitrary-execution, and dynamic-dispatch categories. |

Only these five operations are accepted. Extra arguments and unknown operations are rejected with exit status `2`.

## Data flow and lifecycle

```text
Fixed Evidence Engine output
        ↓
Fixed Bottleneck Analysis output
        ↓
Fixed Policy Engine output
        ↓
Recommendation-only policy state
        ↓
Fixed Action Safety Gate simulation output
        ↓
VEGAS Control Plane snapshot / static dashboard visibility
        ↓
[Future Real Action Layer — NOT IMPLEMENTED]
```

The lifecycle is descriptive only: `IDLE`, `OBSERVING`, `ANALYZING`, `EVALUATING`, `GATED`, `SIMULATING`, and `BLOCKED`. Unavailable, stale, invalid, malformed, missing, or contradictory input fails closed to `BLOCKED` with explicit `UNKNOWN`, `UNAVAILABLE`, or `INSUFFICIENT_EVIDENCE` stage values. The control plane propagates existing decisions and provenance; it does not duplicate policy logic, fabricate a recommendation, derive an executable command, or reinterpret a safety gate.

## Snapshot contract

The normalized `snapshot` envelope exposes fixed records for `evidence`, `analysis`, `policy`, `recommendation`, `action_gate`, `plugins`, `safety`, `provenance`, `simulation`, and `audit`. Every stage record preserves its state, confidence, evidence quality, provenance, and availability. The `safety` record explicitly declares the absence of hardware writes, process control, network operations, arbitrary execution, and dynamic dispatch, and identifies the real action layer as `NOT_IMPLEMENTED`.

The only persistent effect available through this component is the existing Action Safety Gate’s bounded repository-local simulation audit. It retains at most 16 non-sensitive records, never records device changes, never creates an applied-state marker, and is unchanged by `status`, `snapshot`, `evaluate`, or `capabilities`.

## Phase 11 hardening invariant

The control plane accepts component output only when its object structure, read-only marker, known provenance, required stage fields, safety state, and bounded size are valid. The component-output limit is fixed at `262144` bytes; oversized, malformed, missing-provenance, stale, unknown, or low-confidence input is converted to a conservative unavailable or `BLOCKED` state. Environment values cannot redirect the component root outside the repository-owned AX-T615 module or redirect an evidence fixture outside the reviewed repository-local fixture and runtime locations. The audit directory is similarly fenced to repository-local storage and refuses unsafe symlink targets.

## Integration boundaries

`sh bin/vegas control {status|snapshot|evaluate|simulate|capabilities}` is the public fixed route. The AX-T615 plugin’s `control` compatibility surface and the plugin manager use the same five-operation allowlist. `vegas snapshot` and `AX-T615-GAME-OPTIMIZER/bin/dashboard snapshot` embed the control-plane envelope for static, text-only dashboard rendering. Neither route accepts browser input, metadata-provided executable fields, arbitrary file paths, action IDs, shell fragments, package targets, or control parameters.

## Explicitly unavailable capabilities

The control plane cannot write `/proc` or `/sys`, alter CPU/GPU governor or frequency state, modify Android properties, charging, thermal policy, memory/ZRAM/swap, LMK/OOM, display state, games, or files outside its bounded simulation audit. It does not stop processes, invoke network operations, use `eval`, execute plugin metadata, dynamically dispatch to caller-provided paths, or create a rollback/apply path.
