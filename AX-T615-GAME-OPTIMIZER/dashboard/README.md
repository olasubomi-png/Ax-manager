# VEGAS-inject Dashboard/UI v2 + Evidence Engine + Intelligent Analysis + Policy

Dashboard/UI v2 is a **static, read-only observability interface** for unified VEGAS-inject outputs. It presents the AX-T615 Game Optimizer, System Observer, and Performance Observer without changing their contracts. The dashboard is deliberately separate from optimizer engines: it does not contain decision logic, execute arbitrary commands, or provide a hardware-control path.

## Safe data flow

```text
Existing Axmanager CLI engines
        ↓
bin/dashboard snapshot or export
        ↓
validated JSON snapshot
        ↓
dashboard/index.html
```

The exporter invokes the existing `orchestrator-evidence`, `orchestrator-decision`, `orchestrator`, `session`, `profile`, fixed `evidence-engine`, fixed `bottleneck-engine`, fixed `policy-engine`, legacy internal `action-engine`, and public fixed `action-gate` outputs. It does not reinterpret their policy. The browser renders the exported fields as text and rejects snapshots that are not explicitly marked `read_only: true`.

## Open the dashboard

Open `dashboard/index.html` in any modern browser. Before opening it, generate a snapshot from the same module directory:

```sh
sh bin/dashboard export
```

This writes only `dashboard/data/current-snapshot.json`. Load that file via **Load safe snapshot**, or use **Refresh exported snapshot** to make one same-origin, static-file request for that exported JSON. Refresh has no shell bridge, no URL input, no remote request, and no device command path. To stream JSON to another trusted local UI integration without writing a snapshot file, use:

```sh
sh bin/dashboard snapshot
```

No HTTP server, credentials, tokens, periodic polling loop, or browser-to-shell bridge is included. A local host may serve the static files if desired, but it must preserve the same static snapshot boundary.

## Safe controls and limitations

The UI intentionally does not expose live mutation buttons. Existing safe policy/session operations remain available through the CLI, for example:

```sh
sh bin/axgo profile get
sh bin/axgo profile set balanced
sh bin/axgo session status
sh bin/axgo orchestrator dry-run
```

This prevents a web page from becoming an arbitrary shell executor. The dashboard labels recommendations as recommendations and dry-run output as dry-run output; it never claims to have applied CPU/GPU governor or frequency changes, Power HAL changes, charging changes, thermal/battery changes, process controls, ZRAM/swap changes, or LMKD/OOM changes.

## Data availability

The dashboard displays **Unavailable**, **Not detected**, or **No data** when a sensor, session, or bounded history is absent. It does not estimate missing values. Historical charts render only when an integration provides an explicit bounded `history` array in a validated snapshot.

## Evidence engine visibility

Phase 6 adds an optional, backward-compatible `evidence_engine` envelope. The dashboard presents only its source-derived **quality classification**, **freshness**, **provenance**, per-metric **confidence**, retained bounded-history count, observed trends, conditions, and any explicit **conservative fallback** reason. Evidence states remain distinct: `VALID`, `UNKNOWN`, `UNAVAILABLE`, `STALE`, and `INVALID` are not treated as interchangeable values.

Local history is bounded and available only to the fixed evidence engine. The UI neither writes to that history nor fabricates a trend when the retained sample window is insufficient. A fallback is informational: it communicates that existing policy elected the conservative read-only branch; it cannot change hardware, processes, game state, charging, kernel values, or memory settings.

## Intelligent Analysis visibility

Phase 7 adds an optional, backward-compatible `analysis` envelope alongside `evidence_engine`. It contains only deterministic advisory fields: `classification`, `confidence`, `reason`, `supporting_evidence`, `conflicting_evidence`, `evidence_quality`, `provenance`, `recommended_observation`, `safety_classification`, and bounded `history` correlation. The browser validates that this envelope is an object before reading it and uses text-node rendering for every field.

The **Intelligent Analysis** panel presents the current bottleneck, confidence, explanation, supporting/conflicting evidence, quality, bounded history/trends, recommendation, and safety classification. It preserves `UNKNOWN` or `Unavailable` where data is absent; no telemetry is inferred. The pipeline is **Evidence → Analysis → Recommendation → Action**, and this dashboard stops at **Recommendation**. Neither analysis nor its presentation can apply CPU/GPU, display, charging, thermal, memory, process, or game modifications.

## Policy & Recommendations visibility

Phase 8 adds an optional, backward-compatible `policy` envelope alongside `evidence_engine` and `analysis`. It contains deterministic advisory fields only: `policy_state`, `recommendation`, `confidence`, `priority`, `reason`, `evidence_quality`, `bottleneck`, `bottleneck_confidence`, `supporting_evidence`, `rejected_options`, `safety_classification`, `provenance`, `generated_at`, and bounded `history`. The browser validates that this envelope is an object before reading it and renders every value through text nodes.

The **Policy & Recommendations** panel shows the selected policy state, recommendation, confidence, priority, rationale, evidence quality, bottleneck context, safety classification, rejected options, provenance, timestamp, and bounded sample count. The fixed policy hierarchy prioritizes unknown/invalid safety evidence, thermal protection, memory safety, and battery/power protection ahead of performance and profile preferences. The panel preserves `UNKNOWN` or `Unavailable` values and cannot infer a policy or execute a recommendation.

## Controlled Actions visibility

Phase 9 adds an optional, backward-compatible `action` envelope alongside `evidence_engine`, `analysis`, and `policy`. It contains only fixed observability fields: `mode`, `action_lock`, `validation`, `planned_action`, `result`, `recommendation`, `policy_state`, `evidence_quality`, `concurrency`, `rollback`, `available_actions`, `blocked_actions`, bounded `audit_history`, and `generated_at`. The browser validates this envelope as an object and renders every field through text nodes.

The **Controlled Actions** panel begins in **DRY RUN** and presents the lock, plan, validation, result, managed-state-only rollback, immutable allowed and blocked action registries, timestamp, and bounded audit count. It contains no action button, form, endpoint, browser-to-shell bridge, or hardware-control affordance. Snapshot refresh remains a static-file read only and cannot unlock, apply, or roll back an action.

## Action Safety Gate visibility

The public simulation-only Action Safety Gate adds an optional, backward-compatible `action_gate` envelope. It exposes only `gate_state`, `simulation_status`, `simulated_recommendation`, `reason`, `evidence_quality`, `confidence`, `audit_count`, `safety_classification`, `provenance`, `generated_at`, and the explicit `real_action: NONE` state. The browser validates this envelope as an object and writes each field through text nodes.

The **Action Safety Gate** panel presents the gate state, simulation result, simulated recommendation, reason, evidence quality, confidence, audit count, and clear no-real-action statement. It contains no action button, form, endpoint, browser-to-shell bridge, profile target, or hardware-control affordance. Loading or refreshing a static snapshot cannot evaluate or simulate an action.

The public data path is **Evidence → Analysis → Policy → Recommendation → Action Gate → [Future Real Action Layer]**. This dashboard ends at the gate: it does not implement action application, profile application, hardware control, charging control, display changes, thermal changes, memory changes, process control, or game modification.
