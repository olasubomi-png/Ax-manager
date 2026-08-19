# Ax-manager

**Axmanager** is a safety-first, read-only gaming-performance observability and recommendation project for the Tecno POP 9 / Unisoc T615 class of Android hardware. It collects available device evidence, applies deterministic policy guards, and reports a logical recommendation. It does **not** claim to tune a device, bypass Android protection, or apply hardware changes.

## Final architecture

```text
Read-only Android telemetry
        ↓
CPU · GPU · memory · thermal · FPS/frame-time · profile · battery engines
        ↓
Unified orchestrator evidence → decision → lifecycle/hysteresis/audit
        ↓
Axmanager CLI and static dashboard snapshot exporter
        ↓
Responsive dashboard / safe policy recommendation
```

The shell engines remain usable without the dashboard. The dashboard is a separate static observability interface that reads a validated snapshot emitted by `AX-T615-GAME-OPTIMIZER/bin/dashboard`; it does not duplicate decision logic, execute arbitrary commands, or expose device-control endpoints.

## Capabilities

The module reports CPU and Mali-G57 GPU discovery data, memory pressure, thermal state, FPS/frame-time evidence where supported, game-profile policy, battery and charging evidence, logical session state, and the unified orchestrator recommendation. It supports bounded monitoring, dry-run reports, transition auditing, deterministic safety priority, and hysteresis-based recovery.

## Safety guarantees

Axmanager is **recommendation-only**. Its dashboard and core engines do not write `/proc` or `/sys`, change CPU/GPU frequency or governors, modify the Power HAL, Android properties, charging limits, battery behavior, thermal protection, ZRAM, swap, LMKD/OOM configuration, or processes. It does not kill or force-stop applications. Missing or unsupported telemetry is reported as unavailable or unknown rather than invented.

## Quick start

```sh
cd AX-T615-GAME-OPTIMIZER
sh bin/axgo status
sh bin/axgo orchestrator dry-run
sh bin/dashboard snapshot > /tmp/axmanager-snapshot.json
# Open dashboard/index.html locally, then load the exported JSON file.
```

See [`AX-T615-GAME-OPTIMIZER/README.md`](AX-T615-GAME-OPTIMIZER/README.md) for the full CLI, dashboard, dry-run, testing, security, and hardware-limitation documentation.
