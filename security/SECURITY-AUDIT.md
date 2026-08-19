# VEGAS-inject Security Audit

## Scope and conclusion

This Phase 11 audit records the production hardening boundary for VEGAS-inject and the AX-T615 compatibility module. The project remains a **read-only, simulation-only observability system**. It does not grant a device-control capability, a process-control capability, an arbitrary command capability, or a browser-to-shell capability.

The associated machine-readable release record is [`audit-report.json`](audit-report.json). Its status is valid only when the repository-local security contract and complete regression suite pass. A failed structural, safety, compatibility, or adversarial control blocks release rather than degrading to an action-capable path.

## Threat model and trust boundaries

| Boundary | Trusted input | Rejected input or capability | Required response |
|---|---|---|---|
| Public CLI | Fixed commands and fixed argument shapes | Unknown commands, extra arguments, caller-selected executable paths | Reject with a non-zero status and a fixed error message. |
| Plugin registry and metadata | Three fixed registered plugins, declarative metadata, `plugin.sh` entrypoints | Duplicate or unknown IDs, traversal, absolute paths, URLs, executable keys, unknown capabilities | Reject before an adapter is invoked. |
| Evidence and policy composition | Existing bounded component output with provenance, confidence, and quality fields | Malformed, missing, oversized, stale, unknown, or insufficient-confidence input | Emit an explicit unavailable or blocked conservative result. |
| Action Safety Gate | Internally derived recommendation from validated policy output | Caller action IDs, profiles, packages, paths, shell text, and any apply request | Evaluate or simulate only; do not create a real action. |
| Dashboard | Same-origin exported snapshot data | HTML, command paths, remote URLs, browser-to-shell requests, mutation controls | Validate the object shape and render values as text only. |
| Audit storage | Bounded repository-local simulation records | Device state, symlink targets, arbitrary runtime locations, unbounded histories | Keep bounded non-symlink local records; never create an applied-state marker. |

## Enforced controls

The root `bin/vegas`, `bin/plugin-manager`, `bin/action-gate`, and `bin/control-plane` programs use fixed dispatch and repository-owned paths. Plugin metadata is treated as declarative data, not a command source. The plugin manager rejects executable metadata fields, URLs, absolute paths, traversal, unknown capabilities, duplicate IDs, malformed booleans, and non-fixed entrypoints.

The AX-T615 compatibility router accepts only reviewed status, inspection, bounded observation, and dry-run forms. Action-oriented forms such as apply, restore, reset, start, stop, profile mutation, and arbitrary forwarded arguments are rejected at the compatibility boundary. Fixed child programs continue to receive only validated known arguments.

The control plane and Action Safety Gate preserve conservative evidence ordering. Missing provenance, malformed structure, stale or unavailable context, low confidence, and unsafe conditions result in `BLOCKED`, `UNKNOWN`, or unavailable state. Simulation can only delegate through the Action Safety Gate and cannot become execution.

## Explicitly unavailable capabilities

The following categories are not implemented: CPU/GPU governor or frequency changes; `/proc` or `/sys` writes; Android property changes; Power HAL, charging, thermal, display, ZRAM, swap, LMKD, or OOM changes; process kill, force-stop, launch, or package mutation; network access; command, script, URL, executable, or arbitrary path execution; and browser-to-shell control.

> A simulation audit record is observability data, not evidence of a managed action. It cannot authorize, apply, roll back, or claim a device change.

## Verification procedure

Run the Phase 11 security contract, the existing component contracts, and the complete repository regression using repository-local temporary directories. The contract performs static forbidden-capability scans, malformed-input checks, unknown-command and extra-argument checks, plugin metadata and path attack checks, bounded-resource checks, dashboard text-safety checks, and fixture immutability checks. The release procedure also performs POSIX shell and browser JavaScript syntax validation, whitespace checks, and generated-artifact cleanup.

## Residual risk and release rule

This repository intentionally retains historical discovery and dry-run components for compatibility, but the production-facing VEGAS, plugin, Action Safety Gate, control-plane, dashboard, and hardened AX-T615 compatibility interfaces stop before any real control. A future real action layer would require a separate explicit design, distinct threat model, consent model, hardware validation, and security audit. It is not part of this release.
