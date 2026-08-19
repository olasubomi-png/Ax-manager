# Phase 3 — Performance Observer Plugin Checklist

- [x] Audit existing telemetry outputs, plugin contracts, dashboard snapshot schema, tests, and the clean baseline.
- [x] Implement declarative metadata and a fixed POSIX-safe read-only Performance Observer adapter.
- [x] Register fixed CLI routes, lifecycle visibility, optional dashboard envelope, and concise documentation.
- [x] Add focused validation for metadata, routing, deterministic snapshots, unavailable telemetry, multi-plugin isolation, and prohibited capabilities.
- [x] Run focused tests, complete regression, CLI smoke checks, JSON validation, safety scans, and permission checks.
- [x] Review the intended diff, exclude generated state, commit `feat: add performance observer plugin`, push to `origin/main`, and verify synchronization.

## Phase 4 — Unified VEGAS-inject Control Plane

- [x] Inspect the complete Phase 4 specification, current CLI/plugin contracts, dashboard snapshot schema, and baseline tests.
- [x] Define fixed read-only aggregation contracts for unified status, snapshot, inspection, capabilities, plugin health, and platform safety.
- [x] Implement allowlisted CLI routes that aggregate existing plugin adapters without arbitrary execution or duplicate AX-T615 logic.
- [x] Upgrade the dashboard to expose the unified normalized observability snapshot with text-safe unavailable-data rendering.
- [x] Add unified CLI, schema, safety, plugin isolation, dashboard, malformed-metadata, arbitrary-path, and Termux portability tests.
- [x] Run focused validation, complete regression, static forbidden-operation scans, and source-diff review.
- [x] Commit the exact requested release message, push to `origin/main`, and verify synchronization.
