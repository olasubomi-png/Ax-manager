# Universal Android Device Compatibility

## Purpose and boundary

The universal Android compatibility layer is a **read-only, evidence-backed device classifier** for VEGAS-inject. It turns a small, fixed set of locally observable Android and Linux properties into a normalized profile, a generic-first adapter choice, and conservative capability records. It does not treat a manufacturer name, Android release, SoC label, or file-path presence as permission to control a device.

> **Safety invariant:** This component observes only. It never changes a game, Android setting, property, governor, process, battery, thermal control, display mode, storage value, or network state.

The implementation is `bin/device-compatibility`. It accepts only the fixed subcommands shown below and emits line-oriented reports or a bounded JSON snapshot. Unknown input is rejected.

| Command | Result |
|---|---|
| `sh bin/vegas device status` | Non-identifying profile summary, selected adapter, source state, and read-only boundary. |
| `sh bin/vegas device capabilities` | Normalized observation and control-capability states. |
| `sh bin/vegas device inspect` | Fixed probe inventory and privacy declaration. |
| `sh bin/vegas device compatibility` | Generic-first adapter match and fallback rationale. |
| `sh bin/vegas device validate` | Read-only schema and safety-boundary validation. |
| `sh bin/vegas device snapshot` | Namespaced JSON profile for consumers such as the dashboard and action planner. |

## Normalized profile and privacy

The profile intentionally excludes device identifiers and user content. It records only coarse, non-sensitive classes needed to decide whether an observation category is meaningful. Missing input remains `UNKNOWN` or `UNAVAILABLE`; it is never replaced with a fabricated model, GPU, API level, or manufacturer-specific assumption.

| Profile field | Purpose | Privacy rule |
|---|---|---|
| `class` | Coarse Android, Linux, or unavailable runtime classification. | No serial number, account, app list, or location. |
| `android_api_level` | Observed API-level class when available. | No build fingerprint or full property dump. |
| `soc_family` / `gpu_family` | Coarse observed hardware-family labels. | No unique hardware identifier. |
| `memory_class` | Broad memory availability class. | No application memory map. |
| `root_state` | Explicit `UNAVAILABLE`, `UNKNOWN`, or observed non-escalating state. | The layer never invokes `su` or privilege escalation. |
| `source` | Which fixed read-only source category supplied a value. | No network, cloud, account, or telemetry upload. |

## Capability states and privilege tiers

Every capability has a stable ID, category, observed state, source class, confidence, required privilege tier, and action relationship. A capability may be `SUPPORTED`, `AVAILABLE`, `UNAVAILABLE`, `UNKNOWN`, `UNVERIFIED`, `BLOCKED`, `NOT_AVAILABLE`, or `NOT_AVAILABLE_UNVERIFIED`. `SUPPORTED` means an observation interface was detected; it never means a modification is safe or permitted.

| Tier | Meaning | Current Phase 16 behavior |
|---|---|---|
| 0 — application-visible | A safe local observation is available without elevated privileges. | Read-only state may be reported. |
| 1 — shell-visible | A platform-exposed value may be observable through a fixed probe. | Read-only state may be reported; no command is forwarded. |
| 2 — privileged control | A setting or subsystem would require privileged control. | Always reported as unavailable, blocked, or unverified. |
| 3 — OEM/private control | A vendor service, undocumented API, root surface, or modding path would be required. | Always `NOT_AVAILABLE_UNVERIFIED`; no adapter invokes it. |

The control categories for CPU/GPU governors, display refresh-rate changes, game modes, process scheduling, thermal limits, charging, memory management, and Android property writes remain unavailable. They are present only so the action planner can explain why it will not apply a recommendation.

## Generic-first OEM adapter selection

Adapter selection is declarative and fixed. The generic Android read-only adapter is selected first. Optional labels for Qualcomm, MediaTek, Unisoc, Samsung, Google, Xiaomi, OnePlus, OPPO, realme, vivo, Tecno, and Infinix are identification hints only; they expose no vendor command, path, setting, service, or executable metadata. If the observed profile does not meet a fixed read-only matcher, the engine emits `generic-android-read-only` with `SAFE_FALLBACK`.

This design avoids two unsafe assumptions: a known OEM is not proof that a private interface exists, and an apparent system path is not authorization to change it. New adapters must be reviewed as source code, have fixed IDs and fixed read-only probes, add privacy and safety tests, and retain the generic fallback for all unmatched devices.

## Integration with actions and dashboard

The device snapshot is included as a separate `device_compatibility` envelope in `vegas snapshot`, the AX-T615 dashboard export, and the capability-gated action-engine snapshot. Existing Action Safety Gate behavior remains separate. The action engine can use observed compatibility evidence to explain a denial, but it cannot turn an observed capability into a hardware action.

The static dashboard renders profile class, selected adapter, monitoring availability, and real-apply status through text-only DOM bindings. It has no action button, switch, browser-to-shell bridge, dynamic command field, or device-control endpoint.

## Safe on-device validation

On an Android device, validate only the fixed read-only contract:

1. Run `sh bin/vegas device validate` and retain its report locally if needed.
2. Run `sh bin/vegas device snapshot` and confirm `read_only` is true, `hardware_writes` is false, and sensitive identifiers are absent.
3. Run `sh bin/vegas action snapshot` and confirm `real_device_apply` remains `NOT_AVAILABLE` unless a future independently reviewed release says otherwise.
4. Export a dashboard snapshot with the existing dashboard command and inspect the universal compatibility panel. It must show evidence and unavailable states only, never a control.
5. If any fixed probe is unavailable, keep the reported `UNKNOWN`, `UNAVAILABLE`, or `SAFE_FALLBACK` state. Do not add paths, use root, alter SELinux, run OEM tools, or bypass Android protections to obtain a result.

This validation does not benchmark a game or claim a performance gain. It validates data shape, provenance, privacy, and the continued absence of device-changing behavior.

## Explicit non-goals

The universal layer does not install APKs, request root, use `su`, write `/proc` or `/sys`, alter Android properties, invoke `cmd`, use `settings`, call vendor APIs, change refresh rate, overclock or underclock, force a game mode, terminate processes, modify a game, enable charging changes, access accounts, retrieve location, or upload data. A future real control path would require a new reviewed capability, a device-specific evidence contract, user-visible safeguards, and tests that prove the action remains bounded; none exists in this release.
