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
Orchestrator evidence → decision → lifecycle / hysteresis / audit
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

The AX-T615 plugin exposes only established observability operations: status, capabilities, games, game detection, profiles, FPS and performance analysis, memory/thermal/power telemetry, orchestrator status, dashboard access, and dry-run reports. The independent System Observer plugin exposes only `status`, `capabilities`, `inspect`, and `snapshot`; its fixed adapter reports application version, OS/kernel/architecture, a sanitized hostname when safe, uptime, and available memory summary. Performance Observer exposes the same fixed operation set and normalizes only existing AX-T615 orchestrator evidence across CPU, GPU, memory, thermal, FPS, battery, and power categories. Its unavailable values remain `UNKNOWN`, its provenance is declared, and it reports no derived values. The Phase 4 unified layer composes the three fixed adapters into a bounded `vegas snapshot`; it neither executes plugin-provided paths nor re-implements AX-T615 policy logic. Existing `AXGO_*` paths, variables, configuration, runtime, and module identifiers are retained.

## Safety guarantees

VEGAS-inject and all bundled plugins are **read-only and recommendation-only**. They do not write `/proc` or `/sys`, alter CPU/GPU governors or frequencies, change Android properties, Power HAL behavior, display mode, charging, battery controls, thermal policy, ZRAM, swap, LMKD/OOM settings, or processes. They do not kill or force-stop applications, execute profile/telemetry/metadata content, inject into games, or expose raw hardware-control commands. **Hardware control capabilities are `NONE`.** System Observer does not collect personal files, credentials, account data, messages, persistent identifiers, or arbitrary environment variables. Performance Observer does not access the network, run arbitrary commands, or infer missing performance values.

Unknown telemetry remains unavailable. Safety policy prioritizes thermal and battery protection over performance requests, and dashboard output is a visible policy recommendation rather than a device action.

| Path | Responsibility |
|---|---|
| `bin/vegas` | Main VEGAS-inject CLI. |
| `bin/plugin-manager` | Registry, validation, lifecycle, capabilities, and safe routing. |
| `plugins/` | Registry plus declarative metadata and fixed adapters. |
| `AX-T615-GAME-OPTIMIZER/` | Existing validated engines, dashboard, policies, tests, runtime, and logs. |
| `tests/` | VEGAS-inject registry, compatibility, safety, and integration tests. |

For engine-level commands, dashboard use, policies, and hardware limitations, see [`AX-T615-GAME-OPTIMIZER/README.md`](AX-T615-GAME-OPTIMIZER/README.md).
