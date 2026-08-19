# Performance Observer

**Performance Observer** is the third VEGAS-inject plugin. Its fixed POSIX adapter is a bounded, read-only normalizer for the existing AX-T615 orchestrator evidence. It does not tune device hardware, execute metadata, access networks, or modify game data.

| Fixed operation | Result |
|---|---|
| `status` | Deterministic plugin lifecycle, evidence-source, operation, and safety summary. |
| `capabilities` | Fixed observation categories and supported read-only operations. |
| `inspect` | Version, enabled state, safety classification, evidence categories, and unavailable-data policy. |
| `snapshot` | Machine-readable schema-1 normalized CPU, GPU, memory, thermal, FPS, battery, and power evidence. |

The adapter calls only `AX-T615-GAME-OPTIMIZER/bin/orchestrator-evidence` through its fixed repository location. It reports unavailable fields as `UNKNOWN`, labels its provenance, and declares `derived_values` as `NONE`; it therefore never fabricates telemetry.

```sh
sh bin/vegas performance status
sh bin/vegas performance capabilities
sh bin/vegas performance inspect
sh bin/vegas performance snapshot
```

The dashboard may include the optional `plugins.performance_observer` envelope without changing any existing AX-T615 or System Observer fields.
