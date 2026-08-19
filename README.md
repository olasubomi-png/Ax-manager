# VEGAS-inject

**VEGAS-inject** is a safety-first modular gaming observability and policy application. Its first validated plugin, **AX-T615 Game Optimizer**, provides read-only evidence collection, deterministic recommendations, bounded monitoring, and a static dashboard for the Tecno POP 9 / Unisoc T615 class of Android hardware.

> **Safety boundary:** VEGAS-inject is not a game injector, optimizer daemon, or hardware-control utility. It does not modify games, write device controls, bypass Android protections, or claim a device change it did not make.

## Architecture

```text
VEGAS-inject CLI and plugin manager
        ↓ fixed registry, validated metadata, fixed operation allowlist
AX-T615 Game Optimizer plugin     System Observer plugin     Performance Observer plugin
        ↓ read-only telemetry and policy engines
        ↓ bounded non-sensitive application and host observation
Orchestrator evidence → bounded analysis → fixed policy → recommendation → action safety gate → simulated result
        ↓ fixed read-only composition
VEGAS Control Plane → validated JSON snapshot → [future real action layer: NOT IMPLEMENTED]
        ↓ validated JSON snapshot
Static dashboard and logical recommendation
```

The existing `AX-T615-GAME-OPTIMIZER/bin/axgo` remains the direct compatibility CLI. The repository-level `bin/axgo` delegates to it unchanged; `bin/vegas` supplies the plugin-oriented application interface.

## Commands

| Command | Purpose |
|---|---|
| `sh bin/vegas status` | Report the unified read-only platform, all three plugin states, observed evidence, and conservative policy summary. |
| `sh bin/vegas snapshot` | Emit the fixed unified JSON snapshot with AX-T615, System Observer, and Performance Observer provenance. |
| `sh bin/vegas inspect` | Inspect product version, registered plugin count, fixed operations, evidence categories, and the no-control boundary. |
| `sh bin/vegas capabilities` | List grouped observation and policy outputs; hardware control capabilities are explicitly `NONE`. |
| `sh bin/vegas evidence status` | Report the fixed read-only evidence-engine lifecycle and no-write boundary. |
| `sh bin/vegas evidence snapshot` | Emit normalized metric state, timestamp, freshness, provenance, confidence, quality, conditions, bounded trends, and conservative fallback fields. |
| `sh bin/vegas evidence history` | Report only the fixed bounded non-sensitive history retained for trend classification. |
| `sh bin/vegas analysis status` | Report the current fixed bottleneck classification, confidence, evidence quality, advisory observation, and read-only safety state. |
| `sh bin/vegas analysis snapshot` | Emit a deterministic, read-only bottleneck-analysis envelope with explanation, supporting and conflicting evidence, bounded trend context, and an advisory recommendation. |
| `sh bin/vegas analysis capabilities` | List the allowlisted analysis operations and the explicit no-write, no-network, no-process-control boundary. |
| `sh bin/vegas policy status` | Report the fixed policy state, recommendation, confidence, priority, evidence quality, bottleneck context, and no-action boundary. |
| `sh bin/vegas policy snapshot` | Emit a deterministic, read-only policy envelope containing recommendation-only policy state, rationale, rejected options, bounded-history context, provenance, and safety classification. |
| `sh bin/vegas policy capabilities` | List the fixed policy operations and the explicit read-only, advisory-only, action-layer-not-implemented contract. |
| `sh bin/vegas action status` | Report the fixed Action Safety Gate, default deny state, simulation-only mode, bounded audit availability, and no-real-action contract. |
| `sh bin/vegas action evaluate` | Evaluate the internally derived policy recommendation against fixed safety gates without creating an action request. |
| `sh bin/vegas action simulate` | Emit a deterministic simulated recommendation result and bounded local audit entry; no device, process, game, or managed-state action occurs. |
| `sh bin/vegas action capabilities` | List only the four fixed Action Safety Gate operations and all explicitly blocked control categories. |
| `sh bin/vegas control status` | Report the fixed Evidence → Analysis → Policy → Recommendation → Action Gate lifecycle without applying an action. |
| `sh bin/vegas control snapshot` | Emit the normalized deterministic control-plane envelope with component availability, provenance, confidence, evidence quality, safety, simulation, and bounded-audit fields. |
| `sh bin/vegas control evaluate` | Evaluate the composed existing outputs without creating an action request, audit record, or device change. |
| `sh bin/vegas control simulate` | Delegate only to the Action Safety Gate’s simulation route and report the resulting read-only control-plane snapshot. |
| `sh bin/vegas control capabilities` | List the five fixed control-plane operations and explicitly unavailable execution categories. |
| `sh bin/vegas plugin health` | Validate registry, metadata, fixed adapter syntax, supported operations, and safety declarations for every registered plugin. |
| `sh bin/vegas plugin list` | List registered, validated read-only plugins. |
| `sh bin/vegas plugin info ax-t615-game-optimizer` | Show fixed metadata and lifecycle information. |
| `sh bin/vegas gaming status` | Run the established AX-T615 status report. |
| `sh bin/vegas gaming snapshot` | Emit the authoritative AX-T615 snapshot without duplicated observer envelopes. |
| `sh bin/vegas gaming dashboard path` | Resolve the static dashboard location. |
| `sh bin/vegas gaming dashboard snapshot` | Emit the existing validated dashboard snapshot. |
| `sh bin/vegas gaming dry-run` | Render the orchestration dry-run with no-write confirmation. |
| `sh bin/vegas system status` | Report the independent System Observer lifecycle and safety boundary. |
| `sh bin/vegas system inspect` | Report bounded non-sensitive application and host evidence. |
| `sh bin/vegas system snapshot` | Emit the System Observer’s read-only JSON snapshot. |
| `sh bin/vegas performance status` | Report the independent Performance Observer lifecycle and fixed safety boundary. |
| `sh bin/vegas performance capabilities` | List read-only CPU, GPU, memory, thermal, FPS, battery, and power observation categories. |
| `sh bin/vegas performance inspect` | Report bounded plugin metadata, evidence categories, and unavailable-data handling. |
| `sh bin/vegas performance snapshot` | Emit the normalized Performance Observer JSON evidence snapshot. |
| `sh bin/axgo status` | Use the unchanged AXGO compatibility route. |

## Plugin model

Discovery starts from `plugins/registry.json`. A plugin must be registered, identify itself, declare `read_only: true`, declare `hardware_writes: false`, use the fixed `plugin.sh` entrypoint, and omit executable metadata (`command`, `script`, `exec`, `shell`, or `action`). Metadata is validated as data only and cannot provide an arbitrary command path.

The AX-T615 plugin exposes only established observability operations: status, capabilities, games, game detection, profiles, FPS and performance analysis, memory/thermal/power telemetry, orchestrator status, dashboard access, fixed evidence output, fixed bottleneck analysis, fixed policy output, fixed Action Safety Gate output, and dry-run reports. The independent System Observer plugin exposes only `status`, `capabilities`, `inspect`, and `snapshot`; its fixed adapter reports application version, OS/kernel/architecture, a sanitized hostname when safe, uptime, and available memory summary. Performance Observer exposes the same fixed operation set and normalizes only existing AX-T615 orchestrator evidence across CPU, GPU, memory, thermal, FPS, battery, and power categories. Its unavailable values remain `UNKNOWN`, its provenance is declared, and it reports no derived values. The Phase 4 unified layer composes the three fixed adapters into a bounded `vegas snapshot`; it neither executes plugin-provided paths nor re-implements AX-T615 policy logic. Phase 6 adds a fixed evidence engine that classifies each metric as `VALID`, `UNKNOWN`, `UNAVAILABLE`, `STALE`, or `INVALID`, declares freshness, provenance, confidence, quality, and only a fixed small non-sensitive history for deterministic trends. Phase 7 adds the fixed `bin/bottleneck-engine`, exposed through `vegas analysis` and the AX-T615 adapter’s allowlisted `analysis` operation. Phase 8 adds the fixed `bin/policy-engine`, exposed through `vegas policy` and the adapter’s allowlisted `policy` operation. The public `vegas action` and plugin `action` routes now use the fixed `bin/action-gate`: it accepts no caller action identifier, derives its request only from policy output, and can only evaluate or simulate. The earlier `bin/action-engine` remains a repository-internal compatibility component with no public CLI or plugin dispatch. Existing `AXGO_*` paths, variables, configuration, runtime, and module identifiers are retained.

## Evidence, analysis, policy, recommendation, and action safety gate

The product maintains a deliberately constrained safety boundary. **Evidence** is normalized, provenance-labeled observation. **Analysis** is a deterministic explanation of which supported bottleneck signal may be present, plus bounded trend context and confidence. **Policy** selects a recommendation-only state using the documented safety order: safety evidence, thermal, memory, battery/power, performance, then profile preference. **Recommendation** is a read-only instruction to inspect, monitor, collect more evidence, remain conservative, or consider a named logical profile. The **Action Safety Gate** derives a fixed internal simulation request from that policy output, validates it against immutable safety gates, and returns only `SIMULATED_RECOMMENDATION` or `BLOCKED`. The **VEGAS Control Plane** then composes those existing validated outputs, AX-T615 orchestration state, and plugin health into a fixed lifecycle and snapshot; it never recomputes policy, creates an executable request, or turns a simulation into an action.

> `Evidence → Analysis → Policy → Recommendation → Action Gate → [Future Real Action Layer]` stops at the Action Gate. The `analysis`, `policy`, and `action_gate` envelopes cannot authorize an executable path, action ID, device setting, process, game, or package target. The only gate mutation is a bounded local audit record created by `simulate`; it never creates an applied-state marker or a rollback target.

The Phase 10 control-plane interface preserves that stop condition. Its only public forms are fixed `status`, `snapshot`, `evaluate`, `simulate`, and `capabilities` operations; unavailable or unsafe component input yields an explicit fail-closed `BLOCKED` lifecycle. It can emit a bounded local simulation audit only through the existing Action Safety Gate, with no write to a device-control surface. See [`bin/CONTROL_PLANE.md`](bin/CONTROL_PLANE.md) for the architecture and normalized envelope.

## Phase 11 security hardening

Phase 11 hardens the production boundary without introducing a control layer. Public VEGAS and AX-T615 compatibility routes now reject unknown commands, surplus arguments, action-oriented forms, caller-selected paths, and arbitrary forwarding. Plugin metadata and registry content are bounded declarative data: only fixed plugin IDs, fixed relative registry paths, a fixed `plugin.sh` entrypoint, known read-only capabilities, and explicit `read_only: true` / `hardware_writes: false` declarations are accepted. The Action Safety Gate and Control Plane reject malformed, missing-provenance, unknown, stale, insufficient-confidence, oversized, or untrusted context conservatively.

The dashboard retains a text-only static-data boundary. It validates optional envelopes before use, renders values through DOM text bindings, and contains no command bridge, action form, dynamic URL input, remote request, or mutation control. The machine-readable release record is [`security/audit-report.json`](security/audit-report.json); the threat model, blocked capabilities, and verification procedure are documented in [`security/SECURITY-AUDIT.md`](security/SECURITY-AUDIT.md).

## Final v1.0 release

VEGAS-inject v1.0 finalizes the product as a portable POSIX-shell platform for observation, deterministic advisory reasoning, and bounded simulation records. It is safe to run from Termux or another Android-readable shell because missing privileged paths are reported as unavailable and no root, device write, network operation, or remote service is required.

The fixed AX-T615 compatibility route includes `sh bin/axgo dashboard`, `evidence`, `policy`, `action`, and `control` aliases in addition to its established status surface. These are direct aliases to existing fixed read-only or simulation-only components; they do not restore unrestricted forwarding or action-oriented arguments. See [`RELEASE.md`](RELEASE.md) for the v1.0 scope, [`SAFETY-MODEL.md`](SAFETY-MODEL.md) for the security boundary, [`plugins/README.md`](plugins/README.md) for the declarative plugin model, and [`release/capabilities.json`](release/capabilities.json) for machine-readable public capabilities.

## Safety guarantees

VEGAS-inject evidence, analysis, policy, the public Action Safety Gate, and all bundled plugins are **read-only and recommendation-only**. The gate may append a bounded repository-local audit record after a simulation, but it never writes a managed action marker, `/proc`, `/sys`, Android properties, Power HAL state, display mode, charging, battery controls, thermal policy, ZRAM, swap, LMKD/OOM settings, or process state. It does not kill or force-stop applications, execute profile/telemetry/metadata content, inject into games, or expose raw hardware-control commands. **Hardware control capabilities are `BLOCKED`.** System Observer does not collect personal files, credentials, account data, messages, persistent identifiers, or arbitrary environment variables. Performance Observer does not access the network, run arbitrary commands, or infer missing performance values.

Unknown telemetry remains unavailable. Safety policy prioritizes thermal and battery protection over performance requests, and dashboard output is a visible policy recommendation rather than a device action.

| Path | Responsibility |
|---|---|
| `bin/vegas` | Main VEGAS-inject CLI. |
| `bin/plugin-manager` | Registry, validation, lifecycle, capabilities, and safe routing. |
| `bin/control-plane` | Fixed Phase 10 composition of existing evidence, analysis, policy, Action Safety Gate, orchestration, and plugin health outputs. |
| `plugins/` | Registry plus declarative metadata and fixed adapters. |
| `AX-T615-GAME-OPTIMIZER/` | Existing validated engines, dashboard, policies, tests, runtime, and logs. |
| `tests/` | VEGAS-inject registry, compatibility, safety, and integration tests. |

For engine-level commands, dashboard use, policies, and hardware limitations, see [`AX-T615-GAME-OPTIMIZER/README.md`](AX-T615-GAME-OPTIMIZER/README.md).
