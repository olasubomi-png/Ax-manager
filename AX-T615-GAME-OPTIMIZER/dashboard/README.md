# Axmanager Dashboard

The Step 12 dashboard is a **static, read-only observability interface** for existing Axmanager outputs. It is deliberately separate from the optimizer engines: it does not contain decision logic, execute arbitrary commands, or provide a hardware-control path.

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

The exporter invokes the existing `orchestrator-evidence`, `orchestrator-decision`, `orchestrator`, `session`, and `profile` outputs. It does not reinterpret their policy. The browser renders the exported fields as text and rejects snapshots that are not explicitly marked `read_only: true`.

## Open the dashboard

Open `dashboard/index.html` in any modern browser. Before opening it, generate a snapshot from the same module directory:

```sh
sh bin/dashboard export
```

This writes only `dashboard/data/current-snapshot.json`. Load that file via **Load safe snapshot**. To stream JSON to another trusted local UI integration without writing a snapshot file, use:

```sh
sh bin/dashboard snapshot
```

No HTTP server, credentials, tokens, polling loop, or browser-to-shell bridge is included. A local host may serve the static files if desired, but it must preserve the same manual snapshot boundary.

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
