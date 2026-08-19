# Safe On-Device Validation Protocol

## Purpose and current limit

This protocol distinguishes **repository validation** from **real-device validation**. The automated suite can validate schemas, fixed command routing, package structure, static rendering, and absence of prohibited write paths. It cannot prove that a Tecno POP 9, Unisoc T615/T7250, Mali-G57, Android 14 device accepted or benefited from a real optimization action because no target device is connected to this environment.

Consequently, the released action engine reports `REAL_DEVICE_APPLY=NOT_AVAILABLE`; a dry-run may be validated, but no applied action, observed performance gain, thermal change, or rollback success is claimed.

## Preparation

Use an authorized device under the owner’s control. Install AxManager and the untouched `vegas-inject.zip` package as described in [`AXMANAGER-PLUGIN.md`](AXMANAGER-PLUGIN.md). If AxManager requires its documented wireless-debugging session, establish it using Android’s visible pairing confirmation; do not bypass Android security prompts, use root escalation, or connect through an untrusted network.

Record a baseline using normal game behavior and the read-only snapshot surfaces. Capture only non-sensitive, session-scoped telemetry and keep game account data, personal files, credentials, and unrelated application logs out of the test artifact.

## Validation sequence

1. Confirm the plugin identity, `axeronPlugin=14800`, and static WebUI safety notice.
2. Run `sh bin/action-engine status` and `sh bin/action-engine snapshot`. Confirm `MODE=DRY_RUN`, `REAL_DEVICE_APPLY=NOT_AVAILABLE`, `DEVICE_CAPABILITIES=UNVERIFIED`, and `SAFETY_GATE=ENFORCED`.
3. Run a known fixed dry-run, such as `sh bin/action-engine dry-run refresh_telemetry`. A result is a planning record only, not an action on the device.
4. Confirm the audit record remains bounded and declares `hardware_changed=NO`. Confirm `verify` reports `NOT_APPLIED` and `rollback` reports `NO_APPLIED_ACTION`.
5. Inspect `vegas snapshot` and the static dashboard. Confirm the action panel shows the same non-apply state and still exposes no browser control.
6. Disable or uninstall the plugin through AxManager and confirm no device configuration restoration is necessary, because the package does not modify device state.

## Evidence and stop conditions

Stop immediately if a command claims a real device apply, requests root, exposes an arbitrary path or command, writes a system control, lacks a clear device-owned confirmation, or produces malformed/unknown/stale evidence. Preserve the generated bounded audit and the exact command output for review; do not retry by altering package files, bypassing a safety gate, or manually writing system paths.

Any future request to implement a physical action must first identify a stable, documented, device-owned control interface and then satisfy the fixed-action review requirements in [`ACTION-ENGINE.md`](ACTION-ENGINE.md). It must be versioned, tested on the target device, independently verified with before/after evidence, and provide a safe rollback plan before it can replace this release’s `NOT_AVAILABLE` result.
