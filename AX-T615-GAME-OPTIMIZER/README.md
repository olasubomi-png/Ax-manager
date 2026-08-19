# AX-T615-GAME-OPTIMIZER

## Project purpose

AX-T615-GAME-OPTIMIZER is a foundation framework for investigating and
eventually providing safe gaming optimizations for the Tecno POP 9 with the
Unisoc T7250 / T615 SoC. It is intended to be packaged later as an
Android root/module-style ZIP after the supported module environment and
available kernel controls are confirmed.

## Target hardware

- Device: Tecno POP 9
- SoC: Unisoc T7250 / T615
- CPU: 6x Cortex-A55 up to 1612 MHz, 2x Cortex-A75 up to 1820 MHz
- GPU: 1-core ARM Mali-G57
- Graphics APIs: Vulkan 1.3.225 and OpenGL ES 3.2
- RAM: 3 GB, with approximately 2.19 GB ZRAM observed
- Android: 14
- Display: 720x1600, with 60/90/120 Hz support observed
- Architecture: arm64-v8a

The values in `config/device.conf` are reference limits only. They are not
commands and are never used to force hardware frequencies.

## Current capabilities

- Basic module metadata and lifecycle script foundation
- Safe target identification during installation
- Read-only device, CPU topology/policy, GPU/devfreq, thermal-zone, memory,
  ZRAM, display, Game Mode, power-service, and scheduler discovery
- Detailed capability reports with readable/writable status for discovered
  control paths
- Concise hardware status through `status.sh`
- Optional timestamped hardware-only reports through `axgo capabilities --save`
- Logical `cool`, `balanced`, and `performance` profile framework
- Game database, foreground detection, session state, monitor, and recovery
  architecture
- `axgo` command interfaces for discovery and gaming-engine management

## Phase 10 — VEGAS Control Plane compatibility

Phase 10 adds repository-level `bin/control-plane` composition for the established Evidence → Analysis → Policy → Recommendation → Action Safety Gate sequence. The AX-T615 module remains the authoritative source for its existing telemetry, evidence, analysis, policy, session, profile, orchestrator, and dashboard outputs. The control plane only reads those validated outputs, preserves their provenance and unavailable states, and exposes a deterministic lifecycle for cross-component observation.

```sh
sh ../bin/control-plane status
sh ../bin/control-plane snapshot
sh ../bin/control-plane evaluate
sh ../bin/control-plane simulate
sh ../bin/control-plane capabilities
```

The AX-T615 plugin adapter exposes the same fixed `control {status|snapshot|evaluate|simulate|capabilities}` compatibility operation through the registry. No caller-provided action ID, package target, profile target, file path, shell fragment, or device-control parameter is accepted. `simulate` delegates only to the existing simulation-only Action Safety Gate; no AX-T615 hardware, game, process, memory, thermal, battery, charging, governor, or Android-property change is made.

The dashboard snapshot now carries an optional backward-compatible `control_plane` envelope. It is descriptive: it shows component availability, state, confidence, evidence quality, provenance, lifecycle, simulation state, and bounded audit metadata through text-only browser rendering. It never creates a browser-to-shell bridge, executes a CLI command, or turns the static dashboard into a device-control interface.

## Step 2 — Hardware & Kernel Discovery

The project now includes a read-only diagnostic engine for inspecting the
actual Android device and the interfaces exposed by its kernel. Run:

```sh
./status.sh
./bin/detector
./bin/capabilities
./bin/axgo status
./bin/axgo detect
./bin/axgo capabilities
./bin/axgo capabilities --save
```

The detector checks Android build properties, kernel version and CPU ABI,
online/offline CPUs, topology, dynamically discovered cpufreq policies and
clusters, CPU frequencies and governors, GPU properties and devfreq/KGSL
interfaces, thermal zones and trip points, RAM/swap/ZRAM, display information,
Game Mode services, Power/Thermal services, performance-related services, and
scheduler information. It also reports whether root or an accessible `su`
shell is available.

Missing paths are reported as unavailable. Existing paths that cannot be read
are reported as permission denied. Writable status is observed only; no file
is opened for writing. The `--save` option records only the generated
hardware/system capability report in `logs/`.

## Current limitations

This remains a discovery-only build. It does not currently:

- Increase FPS or claim performance improvements
- Change CPU governors, CPU frequencies, GPU frequencies, ZRAM, LMK/OOM,
  refresh rate, network settings, system properties, or thermal configuration
- Disable or bypass Android thermal protection
- Detect or assume game package names
- Assume a particular module manager standard beyond the basic metadata file

Unsupported or unavailable paths are reported rather than written. No tuning
is attempted until the actual target kernel controls are discovered,
validated, and explicitly enabled in a later stage.

## Safety philosophy

Kernel interfaces differ by vendor, firmware, and device. The T7250/Mali-G57
reference values are not substituted for values observed on the phone. Every
future hardware operation must first verify that its path exists and is
writable, stay within manufacturer-reported limits, and fail safely when the
control is unavailable. Thermal protection must remain enabled. Generic FPS
tweaks, guessed sysfs paths, placebo properties, and undocumented controls are
avoided because they can do nothing—or create instability—on a different
kernel.

The detector itself never writes `/sys` or `/proc`, changes Android
properties, changes display settings, modifies memory or network settings,
changes Game Mode, disables thermal throttling, or kills processes. Root is
never assumed; unprivileged Android-readable information is used first.

## Step 4A — CPU Discovery & Safety

Step 4A adds a read-only CPU policy discovery and simulation layer. It does
not apply CPU settings.

```sh
./bin/cpu-controller status
./bin/cpu-controller inspect
./bin/cpu-controller dry-run performance
./bin/axgo cpu status
./bin/axgo cpu inspect
./bin/axgo cpu dry-run performance
```

The controller discovers every dynamically present policy below
`/sys/devices/system/cpu/cpufreq/`, without assuming policy numbering. For
each policy it reports its CPU list, current/minimum/maximum frequency,
available frequencies, governors, current governor, scaling driver, and
readable/writable status. Numeric cpufreq sysfs values are retained as raw
values and documented using the Linux cpufreq convention of kHz; values with
an explicit suffix are reported with that suffix.

Cluster identification uses available CPU topology data and `/proc/cpuinfo`.
It labels a cluster `EFFICIENCY (Cortex-A55)` or
`PERFORMANCE (Cortex-A75)` only when that model is actually observed.
Otherwise it reports `UNKNOWN`; CPU IDs and governor names are never guessed.

`bin/cpu-safety` provides reusable validation functions for future CPU
changes. They reject malformed frequencies, values outside detected
minimum/maximum bounds, undiscovered policies, unavailable governors,
nonexistent or non-writable nodes, and requests made without root. Future
hardware changes must remain inside detected limits and must preserve
thermal protection.

`dry-run` describes the requested logical `cool`, `balanced`, or `performance`
profile and planned actions without changing hardware. Step 4A does not write
to `/sys` or `/proc`, change governors or frequencies, modify Android
properties, modify ZRAM/RAM/display settings, disable thermal protection, or
implement CPU apply functionality. Root will be required before any future
real CPU change is considered.

## Step 3 — Gaming Engine

The gaming engine manages game identity and logical session state without
performing hardware optimization. It can:

- Detect the foreground package through multiple `dumpsys` formats
- Match only explicitly configured game packages
- Store multiple game entries and their `cool`, `balanced`, or `performance`
  profile assignments
- Select profiles in game-specific, global, then balanced-fallback order
- Start, stop, inspect, and recover logical gaming sessions
- Poll for foreground changes through `bin/game-monitor`
- Restore the normal logical state when a game exits
- Rotate `logs/game.log` at a bounded size
- Keep a recovery registry ready for future original hardware values

Examples:

```sh
./bin/game-db list
./bin/game-db add <verified.package> "Game Name" performance
./bin/game-manager status
./bin/game-manager detect
./bin/session status
./bin/profile get
./bin/profile set balanced
./bin/recovery status
```

`service.sh` initializes runtime/log directories and starts the lightweight
game monitor unless `GAME_MONITOR_AUTOSTART=false` is set. The monitor uses
`GAME_MONITOR_INTERVAL="3"` from `config/profiles.conf`, never optimizes an
unknown application, and avoids starting duplicate sessions.

The game database intentionally contains no guessed package names. The empty
`GAME_*` template and numbered `GAME_1_*`, `GAME_2_*`, and later entries support
multiple explicitly verified games. Runtime state under `runtime/` contains
only temporary package, profile, session, and monitor state; it does not
contain personal information. `logs/game.log` records engine activity with
bounded rotation.

## Step 4B — CPU Apply & Restore

Step 4B adds a guarded CPU apply, backup, restore, and emergency reset engine.
The development configuration keeps both governor changes and CPU frequency
changes disabled:

```sh
./bin/cpu-controller apply performance
./bin/cpu-controller restore
./bin/cpu-reset
./bin/axgo cpu apply performance
./bin/axgo cpu reset
```

The apply command refuses to modify anything unless root is available, the
policy was discovered, every target node exists and is writable, the value is
numeric and within the detected minimum/maximum, the requested governor is
available, thermal temperatures are readable for performance frequency work,
and the original policy state has been backed up. A failed check aborts the
change and leaves existing backups intact. Thermal protection and trip points
are never changed.

Backups are stored as `runtime/cpu/original_policy*.conf` and contain the
policy path, original governor, original minimum frequency, and original
maximum frequency. Restore uses those values only, validates the current
policy and nodes, restores frequency bounds in a safe order, then restores
the governor. A backup is deleted only after its policy restores completely.
`bin/cpu-reset` is an emergency entry point for the same backup-only restore
operation; it never invents default settings.

The engine never overclocks. Known T615 reference ceilings are 1612000 kHz
for Cortex-A55 and 1820000 kHz for Cortex-A75, while detected lower limits
take precedence. Performance mode does not automatically force maximum clocks:
frequency selection is disabled until actual device testing explicitly enables
a validated profile request. All apply, validation, backup, modification,
restore, and error events are recorded in `logs/cpu.log`.

## Step 5A — Thermal Monitoring

Step 5A adds a read-only thermal monitoring and throttle-detection layer. It
does not change thermal trip points, thermal zones, CPU or GPU frequencies,
governors, system properties, cooling devices, or kernel parameters.

```sh
./bin/thermal-controller status
./bin/thermal-controller inspect
./bin/thermal-controller monitor --interval 2
./bin/thermal-controller dry-run
./bin/axgo thermal
./bin/axgo thermal status
./bin/axgo thermal inspect
./bin/axgo thermal monitor
./bin/axgo thermal dry-run
```

The controller dynamically discovers zones under `/sys/class/thermal/` and
`/sys/devices/virtual/thermal/`, without assuming thermal-zone numbers. It
reports zone type, current temperature, readable trip points and policy
information, plus cooling-device type and state. Numeric temperatures are
validated before conversion: Linux/Android millidegree values such as
`42500` are shown as `42.5°C`; ambiguous or malformed values are `UNKNOWN`.

The monitoring decision layer classifies the highest readable zone as `COOL`,
`NORMAL`, `WARM`, `HOT`, `CRITICAL`, or `UNKNOWN`. Its recommendations only
describe whether additional performance work should be considered. Throttle
detection reports `DETECTED`, `NOT DETECTED`, or `UNKNOWN` based on readable
cooling-device evidence; a rising temperature or a frequency below maximum is
not treated as proof of throttling.

Game sessions capture starting, peak, average, and final temperatures, thermal
state, and throttle state in a thermal session report. Samples and discovery
events are recorded in `logs/thermal.log`. Android and vendor thermal policies
remain authoritative. AX-manager does **not** disable, override, or modify
Android thermal protection.

## Step 5B — Thermal-Aware Performance Controller

Step 5B adds `bin/thermal-guard`, a read-only decision and coordination layer.
It combines the highest readable temperature, peak temperature, thermal
classification, throttle evidence, game-session state, and current CPU profile
to produce one of `BOOST`, `BALANCED`, `CONSERVATIVE`, or `BLOCKED`. These are
AX-manager decisions, not manufacturer thermal limits. The values in
`config/thermal-policy.json` are explicitly documented as **AX-manager
conservative policy thresholds**, not official TECNO or Unisoc limits.

```sh
./bin/thermal-guard status
./bin/thermal-guard check
./bin/thermal-guard recommend
./bin/thermal-guard game-start
./bin/thermal-guard game-stop
./bin/axgo thermal guard
./bin/axgo thermal guard check
./bin/axgo thermal guard recommend
```

The guard uses the performance states `OPTIMAL`, `NORMAL`, `CAUTION`,
`THROTTLED`, `CRITICAL`, and `UNKNOWN`. Configurable hysteresis and stable
recovery samples prevent rapid switching when temperature fluctuates near a
threshold. Recovery proceeds gradually from `CRITICAL` to `THROTTLED`, then to
`CAUTION`, `NORMAL`, and `OPTIMAL`; the guard does not immediately return to a
boost recommendation after cooling.

At game start, the game profile is selected first, then the thermal guard reads
its current state and passes the recommendation to the existing CPU safety/apply
layer. `BOOST` permits the requested profile, `BALANCED` or `CONSERVATIVE`
constrains a performance request to the balanced profile, and `BLOCKED` prevents
CPU performance changes. The CPU layer remains responsible for all actual
frequency/governor writes, and those writes remain disabled by default. Step
6A adds GPU discovery and recommendation reporting, but GPU hardware control
is still disabled, so the reported GPU action remains `NONE`.

When thermal information becomes unavailable, the state is `UNKNOWN` and the
recommendation is `CONSERVATIVE`; no assumption of a cool device is made. Game
stop produces an `AX-T615 THERMAL PERFORMANCE REPORT` with duration,
start/peak/average/final temperatures, maximum state, throttle detection,
decision counts, CPU/GPU changes, and safety violations. No thermal trip points,
cooling-device states, CPU/GPU frequencies, governors, properties, or kernel
controls are written by Step 5B.

## Step 6A — Mali-G57 GPU Discovery

Step 6A adds a dynamically discovered, read-only GPU framework for the ARM
Mali-G57 target. It searches the actual `/sys/class/devfreq/`,
`/sys/devices/platform/`, and platform `devfreq` paths using GPU/Mali naming
heuristics rather than assuming a Qualcomm KGSL interface or a fixed node.
For each candidate it reports the path, device name, vendor/model inference,
driver and version when exposed, current/minimum/maximum frequencies,
available frequencies, governors, utilization, and readable/writable status.

```sh
./bin/gpu-controller status
./bin/gpu-controller inspect
./bin/gpu-controller capabilities
./bin/gpu-controller dry-run performance
./bin/gpu-info
./bin/axgo gpu status
./bin/axgo gpu inspect
./bin/axgo gpu capabilities
./bin/axgo gpu dry-run performance
./bin/axgo gpu info
```

`bin/gpu-safety` provides fail-closed validators for readable nodes, root and
writable-node requirements for any future operation, discovered frequency
bounds and membership, governor membership, and uncertain capability data.
Missing interfaces are reported as `GPU control: UNAVAILABLE`; incomplete or
unknown driver data is reported as `UNCERTAIN`. Utilization is reported only
when the driver exposes it; otherwise it is `UNAVAILABLE` rather than
fabricated.

The framework detects read-only Vulkan and OpenGL ES information when exposed
through Android properties. It connects the thermal guard’s `BOOST`,
`BALANCED`, `CONSERVATIVE`, `BLOCKED`, and fail-safe `UNKNOWN` outcomes to GPU
recommendation reporting, and game-session start performs a GPU capability
check and profile dry-run. These recommendations describe intended behavior
only.

`gpu-controller dry-run` prints the detected GPU, interface, frequencies,
governor, utilization, API availability, requested logical profile, thermal
recommendation, and planned changes. Step 6A never changes GPU frequencies,
governors, driver parameters, thermal protection, Android properties, Vulkan or
OpenGL configuration, display resolution, or refresh rate. It never writes
arbitrary values to `/sys`; all GPU settings remain unmodified.

The development fixtures under `tests/fixtures/gpu/` are labeled TEST DATA and
cover available, unavailable, missing, malformed, over-limit, and unknown
interfaces. The four GPU test scripts validate detection, safety, dry-run
behavior, missing values, no-root behavior, and fixture immutability. Events
are recorded without private information in `logs/gpu.log`.

## Step 6B — Guarded GPU Apply & Restore

Step 6B adds an opt-in, fail-closed GPU apply and restore architecture on top of
Step 6A discovery. The default configuration in `config/gpu-policy.json` keeps
both `GPU_GOVERNOR_CONTROL` and `GPU_FREQUENCY_CONTROL` disabled. The profile
model therefore remains logical until a device-specific policy, detected node,
root context, thermal recommendation, supported governor, and in-range detected
frequency have all been validated.

```sh
./bin/gpu-controller apply performance
./bin/gpu-controller restore
./bin/gpu-controller reset
./bin/gpu-reset
./bin/axgo gpu apply performance
./bin/axgo gpu restore
./bin/axgo gpu reset
```

`apply` refuses a request when root is unavailable, the dynamically discovered
GPU interface is missing or uncertain, a target node is not readable and
writable, the requested governor is not detected, the requested frequency is
not a member of the detected list, the value is outside detected bounds, the
thermal guard denies the request, or a previous backup already exists. No
frequency is invented from the reference hardware values, and no overclocking
is implemented. Profiles do not select production frequencies until an
explicit, device-specific policy supplies a validated request.

Before any future modification, the controller records only detected original
values in `runtime/gpu/original_gpu.conf`. The backup includes the interface,
driver identity, and each setting node that would actually be changed. A
backup is never overwritten. Restore validates the current interface and driver
against the recorded backup, writes only the recorded originals, and deletes
the backup only after successful completion. `gpu-reset` is an emergency
backup-only restore and never invents defaults. If any step fails, earlier
changes are rolled back when possible and the backup remains available for
manual recovery. Game-session stop requests GPU restore alongside the existing
thermal and CPU restore flow.

Thermal recommendations are enforced before an apply: `BOOST` may proceed to
validated opt-in controls, while `BALANCED`, `CONSERVATIVE`, `BLOCKED`, and
`UNKNOWN` constrain or deny requests according to the requested profile. The
controller never disables or modifies Android thermal protection. Test fixtures
are explicitly labeled TEST DATA and cannot be applied or restored in a
real-device context; fixture writes require an explicit test-only environment.
All apply, validation, backup, modification, rollback, restore, reset, and
error events are recorded in `logs/gpu.log` without private information.

The Step 6B suites cover no-root refusal, missing or uncertain interfaces,
read-only and unsupported nodes, governor and frequency validation, thermal
recommendations, successful fixture-only apply and restore, backup reuse
protection, emergency reset, and partial-failure rollback. They also verify
that rejected operations leave fixture contents unchanged and that no
unconditional GPU sysfs write path exists.

## Future development roadmap

1. Identify the module manager/environment and confirm its packaging contract.
2. Collect device reports from the Tecno POP 9 / T7250 and validate the kernel
   control paths against the actual firmware.
3. Document safe bounds and behavior for any controls that are actually
   available and writable.
4. Add opt-in, guarded tuning with thermal and rollback safety checks.
5. Test the gaming engine with explicitly verified package names on-device.
6. Test across supported firmware versions before enabling any default tuning.

Do not proceed to hardware tuning until the target kernel controls have been
investigated.


## Step 7A — Memory Monitoring & Pressure Guard

Step 7A adds a read-only memory engine for RAM, PSI memory pressure, ZRAM, and
swap visibility. It does not change RAM allocation, ZRAM size or algorithm,
swap state, LMK/OOM settings, sysctl values, `/proc`, `/sys`, Android
properties, or hardware performance controls. Thresholds in
`config/memory-policy.json` are AX-manager monitoring thresholds only; they are
not official TECNO, Unisoc, Linux, or Android limits.

```sh
./bin/memory-controller status
./bin/memory-controller inspect
./bin/memory-controller pressure
./bin/memory-controller zram
./bin/memory-controller swap
./bin/memory-controller dry-run
./bin/memory-guard recommend
./bin/memory-monitor --interval 2
./bin/axgo memory status
./bin/axgo memory inspect
./bin/axgo memory pressure
./bin/axgo memory zram
./bin/axgo memory swap
./bin/axgo memory dry-run
./bin/axgo memory guard recommend
./bin/axgo memory monitor --interval 2
```

The controller reads `MemTotal`, `MemAvailable`, `MemFree`, used and available
percentages, major `/proc/meminfo` fields, PSI `some` and `full` windows, ZRAM
size and compression statistics when exposed, and active swap devices. Missing,
malformed, or permission-denied data is reported as `UNKNOWN` or
`UNAVAILABLE`; it is never invented. A ZRAM device is reported as `ACTIVE`,
`INACTIVE`, or `UNKNOWN`, and swap is reported as `ACTIVE`, `INACTIVE`, or
`UNAVAILABLE`.

The memory decision layer classifies observations as `OPTIMAL`, `NORMAL`,
`PRESSURE`, `HIGH_PRESSURE`, `CRITICAL`, or `UNKNOWN`. The memory guard maps
these to the recommendation labels `NORMAL`, `CONSERVATIVE`, `CRITICAL`, or
`UNKNOWN`. These recommendations are informational only and never invoke
`swapon`, `swapoff`, `zramctl`, `sysctl`, LMK/OOM changes, or any write to
`/proc` or `/sys`. `dry-run` always reports `Planned changes: NONE`.

The monitor prints bounded timestamped samples containing available RAM, used
percentage, memory state, PSI state, and ZRAM state. Game-session start records
the total and starting available RAM plus memory, PSI, ZRAM, and swap state.
Active sessions update the minimum available RAM, peak used percentage, pressure
events, and final states. Game-session stop emits a `MEMORY SESSION REPORT` with
duration, total RAM, starting and minimum available RAM, peak used percentage,
pressure indication, ZRAM state, and swap state. Runtime state is stored only in
`runtime/memory/` and is removed after a report is generated; samples and events
are recorded in `logs/memory.log` without private information.

The labeled TEST DATA fixtures under `tests/fixtures/memory/` cover optimal,
normal, pressure, high-pressure, critical, missing, and incomplete data. The
Step 7A tests validate RAM calculations, PSI and ZRAM/swap detection,
classification and fail-safe recommendations, bounded monitoring, game-session
capture and reporting, axgo routing, fixture immutability, and the absence of
memory hardware write commands.

## Step 7B — Memory-Aware Gaming Performance Engine

Step 7B adds `bin/memory-performance`, a read-only coordination engine that combines memory pressure, thermal state, and the existing logical gaming profile to decide whether additional performance work may be considered. It does not apply CPU or GPU settings itself. Instead, it forwards a constrained recommendation to the existing CPU and GPU safety layers, which remain responsible for their own validation and any future opt-in apply behavior.

```sh
./bin/memory-performance status
./bin/memory-performance check
./bin/memory-performance recommend
./bin/memory-performance game-start [game]
./bin/memory-performance game-stop
./bin/axgo memory performance status
./bin/axgo memory performance check
./bin/axgo memory performance recommend
./bin/axgo memory performance game-start [game]
./bin/axgo memory performance game-stop
```

The memory recommendation mapping is deliberately fail-safe. `OPTIMAL` and `NORMAL` map to `BOOST_ALLOWED`; `PRESSURE` maps to `BALANCED_ONLY`; `HIGH_PRESSURE` maps to `CONSERVATIVE`; `CRITICAL` maps to `PERFORMANCE_BLOCKED`; and `UNKNOWN` maps to `CONSERVATIVE`. The engine combines the memory and thermal recommendations using the most restrictive result. Critical thermal state blocks performance regardless of memory state, while unavailable or unknown thermal information fails safe to `CONSERVATIVE` rather than assuming that the device is cool.

The controller includes hysteresis and staged recovery. Escalation occurs immediately when a more severe memory state is observed. Recovery requires three consecutive stable samples at a lower state by default, as configured by `stable_recovery_samples` in `config/memory-policy.json`. Each recovery step lowers the restriction by only one level, preventing rapid oscillation from `PERFORMANCE_BLOCKED` back to `BOOST_ALLOWED` during short-lived fluctuations.

During coordination, the engine forwards only logical recommendations such as `BOOST`, `BALANCED`, `CONSERVATIVE`, or `BLOCKED` to the CPU and GPU controllers. It does not write CPU or GPU frequencies, governors, devfreq nodes, or any other hardware control. ZRAM and swap values are observed for reporting only. The combined decision is logged to `logs/memory-performance.log` without private information.

Game-session integration captures the combined memory and thermal state at `game-start` and samples it during the active session at the configured two-second interval. `game-stop` emits an `AX-T615 MEMORY PERFORMANCE REPORT`, forwards the legacy memory session report, and records duration, starting and minimum available RAM, peak memory use, memory and thermal states, recommendation decisions, ZRAM state, and the coordinated CPU/GPU outcomes. The top-level `bin/session` lifecycle invokes the memory-performance start and stop commands once, avoiding duplicate memory-session reports.

Step 7B preserves the project-wide read-only guarantee. It never changes memory allocation, ZRAM size or algorithm, swap state, LMK/OOM settings, sysctl values, Android properties, CPU or GPU controls, or thermal protection. It never kills processes and never writes to `/proc` or `/sys`. A static forbidden-write scan reports `NO_FORBIDDEN_MEMORY_WRITES`.

The Step 7B test coverage includes recommendation mapping, ZRAM availability states, thermal coordination, unknown-input fail-safe behavior, CPU and GPU recommendation forwarding, game-session lifecycle and report generation, immediate pressure escalation, three-sample hysteresis recovery, staged recovery across all restriction levels, fixture immutability, axgo routing, and continuation of all prior Steps 5B, 6A, 6B, and 7A test suites.


## Step 8 — FPS, Frame-Time & Display Performance Engine

Step 8 adds a read-only measurement and analysis layer for real gaming performance. It observes available Android display, rendering, frame-time, thermal, memory, GPU, and CPU telemetry without assuming that any universal FPS interface exists. When no valid FPS or frame-time source is available, the engine reports `UNAVAILABLE` or `UNKNOWN`; it never substitutes refresh rate, CPU frequency, GPU frequency, or another proxy as fabricated FPS.

### Display discovery and refresh-rate reporting

`bin/display-controller` tolerantly parses available `dumpsys display`, `dumpsys SurfaceFlinger`, `wm`, and read-only settings output. It reports display ID, resolution, logical size, density, current refresh rate, supported refresh rates, supported display modes, active mode, and HDR capability where those values are exposed. Android and OEM output formats differ, so missing or malformed values are reported as `UNKNOWN` or `UNAVAILABLE` rather than treated as confirmed hardware capabilities.

```sh
./bin/display-controller status
./bin/display-controller inspect
./bin/display-controller refresh
./bin/display-controller modes
./bin/axgo display status
./bin/axgo display inspect
./bin/axgo display refresh
./bin/axgo display modes
```

The controller only reads display information. It does not change resolution, refresh rate, display mode, SurfaceFlinger, compositor, Android properties, or any other display setting. A target FPS is validated against the detected refresh rate and supported modes; unsupported targets are reported as `TARGET_UNSUPPORTED_BY_DISPLAY` and are never forced.

### FPS, frame-time, jank, spikes, and pacing

`bin/fps-controller` accepts direct FPS samples and frame-time samples. Direct FPS data is labeled `MEASURED`. When valid frame-time samples are available without direct FPS, FPS is calculated mathematically from those samples and labeled `DERIVED`. Empty, malformed, or unavailable data remains `UNAVAILABLE`. The controller reports average, minimum, maximum, P50, P90, P95, and P99 for both FPS and frame-time where samples exist.

The analysis layer counts slow frames against the configured target-frame-time threshold, classifies jank as `NO_JANK`, `LOW_JANK`, `MODERATE_JANK`, `HIGH_JANK`, or `SEVERE_JANK`, and reports janky-frame count, total frames, jank percentage, jank bursts, and the longest frame. It separately detects frame-time spikes and reports spike count, largest spike, average spike, and spike frequency. Frame pacing is classified as `STABLE`, `VARIABLE`, `UNSTABLE`, or `UNKNOWN` using the configured variation thresholds. These labels are AX-manager analysis results, not official Android or Tecno limits.

The session classification combines FPS, frame-time, jank, spikes, pacing, and display evidence. It reports `EXCELLENT`, `GOOD`, `STABLE`, `UNSTABLE`, `POOR`, `CRITICAL`, or `UNKNOWN`; average FPS alone is never sufficient for a classification.

```sh
./bin/fps-controller status
./bin/fps-controller inspect
./bin/fps-controller monitor --package com.example.game --interval 1
./bin/fps-controller analyze --package com.example.game
./bin/fps-controller recommend
./bin/fps-controller session-start [game]
./bin/fps-controller session-stop
./bin/fps-controller report
./bin/axgo fps status
./bin/axgo fps inspect
./bin/axgo fps monitor --package com.example.game --interval 1
./bin/axgo fps analyze --package com.example.game
./bin/axgo fps recommend
./bin/axgo fps report
```

The standalone `bin/fps-monitor` entry point uses a one-second interval by default and accepts `--package` and `--interval`. Monitoring is intentionally bounded by the requested interval and does not create an uncontrolled high-frequency polling loop.

### Target recommendations and coordination

`config/display-policy.json` contains the default one-second monitoring interval, target candidates `30`, `40`, `45`, `60`, `90`, and `120` FPS, frame-time thresholds, jank thresholds, spike thresholds, pacing thresholds, and explicit read-only flags. The target is a decision input only. The engine compares it with measured performance and detected display capability, but never attempts to force an unsupported target.

`fps-controller recommend` returns only analytical recommendations: `QUALITY`, `BALANCED`, `PERFORMANCE`, `CONSERVATIVE`, or `UNKNOWN`. Thermal and memory restrictions are merged conservatively with measured frame performance. The coordination mapping is summarized below.

| Evidence | Step 8 behavior |
|---|---|
| Normal thermal and memory state with stable measured performance | Normal analysis; typically `BALANCED` when the target is being sustained |
| Thermal `CAUTION`, `THROTTLED`, or `HOT` | Conservative recommendation |
| Thermal `CRITICAL` | `PERFORMANCE_BLOCKED` |
| Thermal `UNKNOWN` | Conservative fail-safe behavior |
| Memory `PRESSURE` | Balanced recommendation ceiling |
| Memory `HIGH_PRESSURE` | Conservative recommendation ceiling |
| Memory `CRITICAL` | `PERFORMANCE_BLOCKED` |
| Memory `UNKNOWN` | Conservative fail-safe behavior |
| GPU or CPU telemetry unavailable | `UNKNOWN` evidence; no utilization is fabricated |

The FPS engine forwards logical recommendations to the existing CPU and GPU safety layers for coordination only. It does not apply CPU or GPU settings, alter governors or frequencies, modify thermal protection, change memory policy, or change display settings.

### Bottleneck analysis and confidence

`bin/performance-analyzer` combines the FPS engine’s measurements with available thermal, memory, GPU, CPU, and display evidence. It may identify `LIKELY_CPU_PRESSURE`, `LIKELY_GPU_PRESSURE`, `LIKELY_THERMAL_LIMIT`, `LIKELY_MEMORY_PRESSURE`, `LIKELY_FRAME_PACING`, `LIKELY_DISPLAY_LIMIT`, or `UNKNOWN`. Every result includes `HIGH`, `MEDIUM`, `LOW`, or `UNKNOWN` confidence and an evidence summary. The analyzer does not claim certainty when telemetry is incomplete, and it reports unavailable GPU utilization rather than inferring utilization from clocks or refresh rate.

```sh
./bin/performance-analyzer
./bin/axgo performance analyze
```

### Game-session reports

The existing `bin/session` coordinator starts, samples, and stops the FPS session alongside the established thermal, memory, CPU, and GPU safety layers. At game start it records the game name, package, display resolution, refresh rate, active display mode, initial FPS and frame-time when available, and the initial thermal, memory, GPU, and CPU states. During gameplay it samples FPS and frame-time, jank, spikes, pacing, display changes, and coordination evidence. At game stop it emits an `FPS PERFORMANCE REPORT` containing game and package metadata, duration, display and refresh information, FPS statistics, P95 FPS, frame-time statistics, janky frames, jank percentage, spikes, pacing, performance classification, thermal state, and memory state.

### Read-only architecture and validation

Step 8 measures and analyzes performance. It does not force display or hardware settings. The implementation contains no writes to `/proc` or `/sys`, no refresh-rate or resolution changes, no display-mode or SurfaceFlinger changes, no CPU or GPU frequency changes, no thermal-setting changes, no ZRAM or swap changes, no LMKD/OOM changes, and no process kills. TEST DATA fixtures are clearly labeled and remain immutable during all scenarios.

The Step 8 test suites cover display detection, refresh-rate detection, multiple modes, malformed and missing display data, measured and derived FPS, frame-time percentiles, jank classes and bursts, frame-time spikes, pacing, target validation, recommendations, thermal/memory/GPU/CPU coordination, bottleneck classification and confidence, package-specific unavailable FPS, monitor behavior, game-session start and stop, fixture immutability, axgo routing, and the complete prior Steps 1–7B suite.


## Step 9 — Game-Specific Performance Profiles

Step 9 adds a data-only game profile policy engine. It separates verified game identity from policy data and produces bounded recommendations without applying hardware settings. `bin/game-detector` reads Android foreground-package evidence, fixture sources, or an explicitly supplied package; `bin/game-profile` validates, lists, displays, selects, exports, imports, and recommends JSON profiles under `config/game-profiles/`.

```sh
./bin/game-detector identify
./bin/game-detector active
./bin/game-detector package <package>
./bin/game-detector list
./bin/game-profile list
./bin/game-profile show <game>
./bin/game-profile detect <package>
./bin/game-profile validate
./bin/game-profile recommend <game>
./bin/game-profile auto
./bin/game-profile create "Game Name"
./bin/game-profile export
./bin/game-profile import <file>
./bin/game-profile use <profile>
./bin/game-profile clear
./bin/axgo game detect
./bin/axgo game active
./bin/axgo game profile list
./bin/axgo game profile recommend <game>
```

Profiles are JSON data only. The supported logical modes are `BATTERY`, `COOL`, `BALANCED`, `PERFORMANCE`, and `COMPETITIVE`; each profile may describe a target FPS, preferred refresh-rate policy, CPU/GPU policy, memory policy, thermal ceiling, and package list. `default-safe.json` is used for unknown games, malformed foreground data, missing verified mappings, and unavailable profile data. It selects `BALANCED`, `AUTO` FPS, `AUTO` display behavior, balanced CPU/GPU/memory policy, and conservative thermal handling. The example battery, cool, balanced, performance, and competitive profiles are intentionally labeled examples and do not claim support for any real game package.

`config/game-profiles/index.json` is the only production package-to-profile mapping. It remains empty until a package has been explicitly verified; the engine does not invent package identifiers. Profile validation checks JSON-like structure, required identifiers and fields, unique profile IDs, Android package syntax, supported FPS targets, supported modes and policy values, and rejects command-like fields such as `command`, `script`, `exec`, `shell`, or `action` when they would turn profile data into executable configuration.

Recommendations combine the selected profile with available Step 5–8 evidence. Critical thermal, memory, or hardware-safety states have highest priority; throttled or high-pressure conditions constrain the result next; caution or pressure states constrain it further; only normal, known telemetry permits the profile's normal policy. Unknown game, thermal, memory, CPU, GPU, FPS, frame-time, or display data fails safe rather than being fabricated. The output includes the selected profile, package identity, display/FPS target, thermal and memory states, CPU/GPU evidence, final recommendation, reason, and an explicit statement that no hardware settings were changed.

A bounded hysteresis policy in `config/game-profile-policy.json` prevents rapid oscillation. Escalation toward a more restrictive recommendation is immediate. Recovery requires the configured number of stable samples, moves one mode at a time, and observes minimum mode-duration and thermal/memory recovery delays where evidence is available. `game-profile use <profile>` creates a session-only override, while `game-profile clear` removes it; neither command changes the persistent profile catalog or hardware.

The existing `bin/session` coordinator invokes the Step 9 profile engine at game start, samples it while the session is active, and emits a `GAME PERFORMANCE REPORT` at game stop. The report includes game and package identity, profile, duration, target FPS, available FPS/frame-pacing evidence, thermal and memory evidence, CPU/GPU state, performance mode, mode transitions, intervention counts, bottleneck/confidence fields when available, and the Step 9 read-only safety statement. Step 9 does not restore values that it never changed.

Step 9 remains strictly read-only. It does not write `/proc` or `/sys`, change display settings, set Android properties, change CPU/GPU frequencies or governors, modify ZRAM/swap/LMKD/OOM behavior, alter thermal protection, kill or force-stop processes, or invoke shell evaluation. The Step 9 test suites cover detector behavior, profile commands, schema validation, malicious-profile rejection, safety scanning, recommendation priority, hysteresis and stable recovery, session integration, runtime cleanup, and fixture immutability.


## Step 10 — Power & Battery-Aware Gaming Engine

Step 10 adds a read-only power and battery-awareness layer for game sessions. `bin/power-controller` dynamically discovers Android battery evidence from `/sys/class/power_supply` and, when available, `dumpsys battery`. It tolerantly reports battery percentage, status, health, temperature, voltage, current, capacity, charging state, and charger source without assuming a fixed vendor layout or fabricating missing values.

```sh
./bin/power-controller status
./bin/power-controller inspect
./bin/power-controller battery
./bin/power-controller charging
./bin/power-controller health
./bin/power-controller temperature
./bin/power-controller estimate
./bin/power-controller dry-run
./bin/power-monitor --once
./bin/power-monitor --interval 10 --samples 3
./bin/power-guard status
./bin/power-guard check
./bin/power-guard recommend
./bin/power-guard dry-run
./bin/power-guard override set conservative 30
./bin/power-guard override status
./bin/power-guard override clear
./bin/axgo power status
./bin/axgo power inspect
./bin/axgo power battery
./bin/axgo power charging
./bin/axgo power health
./bin/axgo power temperature
./bin/axgo power estimate
./bin/axgo power monitor --once
./bin/axgo power guard recommend
./bin/axgo power guard dry-run
```

Battery classification is policy-driven through `config/power-policy.json`. Readable percentage values are classified as `FULL`, `HIGH`, `MEDIUM`, `LOW`, `CRITICAL`, or `UNKNOWN`; charging is reported as `NOT_CHARGING`, `CHARGING`, `FULL`, or `UNKNOWN`; and health is reported as `GOOD`, `OVERHEAT`, `DEAD`, `OVER_VOLTAGE`, `UNSPECIFIED_FAILURE`, `COLD`, or `UNKNOWN`. Battery temperature is kept distinct from SoC temperature. The power state combines battery, charging, battery-temperature, health, and thermal evidence into `OPTIMAL`, `NORMAL`, `POWER_LIMITED`, `BATTERY_LOW`, `BATTERY_CRITICAL`, `CHARGING_HOT`, or `UNKNOWN`.

`bin/power-guard` produces logical recommendations only: `PERFORMANCE_ALLOWED`, `BALANCED`, `CONSERVATIVE`, `PERFORMANCE_BLOCKED`, or `UNKNOWN`. Restrictive evidence wins. Critical thermal and memory states remain blocking, critical battery blocks performance, low battery is conservative, charging while hot is conservative, and unknown evidence fails safe. Normal high-battery operation can allow performance when optional profile and FPS evidence is absent rather than being invented. Game-profile, FPS, CPU/GPU, thermal, and memory recommendations are forwarded as logical evidence only; no controller applies a hardware setting. `AUTO`, `NORMAL`, and `CONSERVATIVE` charging gaming modes are recommendation-only. Temporary guard overrides have bounded expiration and can be cleared without changing persistent policy or hardware.

`bin/power-monitor` defaults to a ten-second interval and supports bounded `--interval`, `--samples`, and `--once` operation. It records timestamp, battery percentage, battery temperature, charging state, voltage, current, source, and estimated electrical power. Instantaneous power is calculated only when readable voltage and current are available, is labeled `ESTIMATED`, and is explicitly not a measurement of total device power consumption. Missing voltage or current remains `UNAVAILABLE`.

Power sessions capture starting battery percentage, charging, temperature, health, source, power state, thermal state, and memory state. Samples track battery, temperature, charging, power state, recommendation, and coordination evidence. Game stop emits a `POWER PERFORMANCE REPORT` with game identity, duration, start/end battery, drain, drain rate in percent per hour, charging transition, battery-temperature start/end/peak, health, power/thermal/memory states, and logical recommendation observations. The `long_session_minutes` policy increases monitoring awareness for long sessions but does not automatically reduce performance or change a device setting. Hysteresis escalates immediately and requires configured stable recovery samples before moving down one recommendation level at a time.

The top-level `bin/session` coordinator invokes power session start after the existing thermal, memory, FPS, and game-profile lifecycle calls; it samples power and guard state while a game is active; and it emits the power report during the existing stop path. Runtime state is isolated under the session data root and is removed at stop. `axgo` exposes the power command family without replacing earlier Steps 1–9 routes.

Step 10 is strictly read-only. It does not write battery, charging, thermal, CPU, GPU, governor, kernel, Power HAL, ZRAM, swap, LMKD, or OOM controls. It does not change charging limits, bypass charging protection, set Android properties, write `/proc` or `/sys`, kill or force-stop processes, or claim exact total device power consumption. Battery and power safety mechanisms remain under Android and the device manufacturer’s control. The Step 10 test data is explicitly labeled `TEST DATA`, and the test suites verify discovery, charging, health, temperature, estimation, guard priority, hysteresis, session reporting, monitor bounds, fixture immutability, and forbidden-write scanning.


## Step 11 — Unified Gaming Performance Orchestration Engine

Step 11 adds a unified, read-only orchestration layer that combines the evidence produced by the thermal, memory, FPS/frame-time, game-profile, GPU, CPU, and power engines. The flow is deliberately separated into three deterministic layers: `bin/orchestrator-evidence` normalizes labeled fixture data or live controller output; `bin/orchestrator-decision` applies the safety-first policy and returns a logical decision; and `bin/orchestrator` owns lifecycle state, bounded sampling, hysteresis, and transition auditing. Evidence is treated as data, not as executable configuration, and unavailable signals remain `UNKNOWN`.

The orchestrator supports the following logical and lifecycle states: `idle`, `starting`, `balanced`, `performance`, `conservative`, `thermal-protection`, `battery-protection`, `recovery`, `stopping`, and `stopped`. Starting a session records a generated session identifier and game metadata, performs one bounded sample, and leaves the service in a visible active lifecycle. Repeated start and stop operations are idempotent; they report `already active` or `already stopped` rather than creating duplicate work or failing unsafely.

```sh
./bin/orchestrator status
./bin/orchestrator start "Game Name"
./bin/orchestrator sample
./bin/orchestrator decision
./bin/orchestrator inspect
./bin/orchestrator monitor
./bin/orchestrator dry-run
./bin/orchestrator stop
./bin/axgo orchestrator status
./bin/axgo orchestrator start "Game Name"
./bin/axgo orchestrator sample
./bin/axgo orchestrator decision
./bin/axgo orchestrator inspect
./bin/axgo orchestrator monitor
./bin/axgo orchestrator dry-run
./bin/axgo orchestrator stop
```

The decision engine uses a strict safety-first priority order. Thermal danger and unsafe telemetry take precedence over every performance request; critical battery conditions then take precedence over performance; CPU, GPU, memory, thermal caution, charging, health, FPS, frame-time, display, and profile evidence constrain the result in descending safety importance. Healthy, known evidence may produce `balanced` or `performance`; pressure or uncertain evidence produces `conservative`; thermal and critical battery evidence produce the corresponding protection state. The output includes `DECISION_SCHEMA=1`, normalized evidence status, selected state, priority, confidence, reason, safe logical recommendations, and the complete blocked-action set.

Protection escalation is immediate. Recovery is intentionally slower: a thermal or battery protection state remains held until `recovery_stable_samples` consecutive stable samples have been observed, then enters `recovery`; the recovery state requires the same stable threshold before returning to a normal state. Performance downgrades also use a bounded cooldown for ordinary demand fluctuations, while safety downgrades remain immediate. The default policy requires three stable samples and records the stable-sample count in every transition, preventing rapid oscillation around a threshold.

`monitor` is bounded by `monitor_interval_seconds` and `monitor_max_duration_seconds` in `config/orchestrator-policy.json`; it reports completion and sample count instead of spawning an unbounded background process. Every state transition is written to `logs/orchestrator.log` with the session identifier, previous and next states, reason, priority, evidence source, safety classification, and timestamp. Runtime lifecycle data is isolated under `runtime/orchestrator/` and is removed or reset through the normal stop path.

The `dry-run` command renders the proposed logical action plan and explicitly reports `HARDWARE_WRITES_PERFORMED=NO`. The canonical blocked actions are `write_proc`, `write_sys`, `write_power_hal`, `write_governor`, `write_charging_limit`, `modify_battery`, `kill_process`, `force_stop`, `modify_zram`, `modify_swap`, `modify_lmkd`, `disable_thermal_protection`, and `disable_battery_protection`. These are policy identifiers only; the orchestrator never invokes them. No Step 11 code writes `/proc` or `/sys`, changes CPU/GPU governors or frequencies, modifies charging limits, changes Power HAL behavior, changes ZRAM/swap/LMKD/OOM settings, disables thermal or battery protection, kills or force-stops processes, or evaluates commands from telemetry or profile data.

The existing `bin/session` coordinator invokes the orchestrator once at game-session start, once for each bounded sample path, and once at stop. This integration adds unified evidence and lifecycle visibility without replacing the thermal, memory, FPS, profile, GPU, CPU, or power engines. Step 11 therefore remains a recommendation and audit layer: it coordinates safe logical states, preserves all earlier read-only guarantees, and never claims that a hardware setting was applied.

The Step 11 test suites cover evidence normalization, decision priority and unknown fallback, lifecycle idempotence, bounded monitoring, protection and performance hysteresis, session integration, blocked-action reporting, static forbidden-write scanning, dry-run behavior, audit/runtime cleanup, fixture immutability, and top-level `axgo` routing. The complete repository regression suite remains required after every orchestration change.

## VEGAS-inject integration — Modular Application Layer

VEGAS-inject adds a compatible application layer above this module without replacing its AX-T615 command, configuration, runtime, or test contracts. The module is registered at `plugins/ax-t615-game-optimizer` beside the independent `plugins/system-observer` and `plugins/performance-observer` plugins; its existing `bin/axgo` router remains authoritative, and the repository-level `bin/axgo` wrapper delegates to it for compatibility.

The `bin/vegas` CLI routes only a fixed set of read-only operations through `bin/plugin-manager`. Plugin metadata is declarative data: validation requires identity, version, description, type, literal `plugin.sh` entrypoint, `read_only: true`, and `hardware_writes: false`. Metadata containing executable keys (`command`, `script`, `exec`, `shell`, or `action`) or blocked operation identifiers is rejected. The adapter maps only established AXGO observations and dry-runs; it cannot call arbitrary paths or execute metadata.

```sh
sh ../bin/vegas status
sh ../bin/vegas plugin list
sh ../bin/vegas gaming status
sh ../bin/vegas gaming dashboard path
sh ../bin/vegas gaming dashboard snapshot
sh ../bin/vegas gaming dry-run
sh ../bin/vegas system status
sh ../bin/vegas system inspect
sh ../bin/vegas system snapshot
sh ../bin/vegas performance status
sh ../bin/vegas performance capabilities
sh ../bin/vegas performance inspect
sh ../bin/vegas performance snapshot
sh ../bin/vegas analysis status
sh ../bin/vegas analysis snapshot
sh ../bin/vegas analysis capabilities
sh ../bin/vegas policy status
sh ../bin/vegas policy snapshot
sh ../bin/vegas policy capabilities
sh ../bin/vegas action status
sh ../bin/vegas action evaluate
sh ../bin/vegas action simulate
sh ../bin/vegas action capabilities
sh ../bin/axgo status
```

The product name **VEGAS-inject** denotes the modular application packaging only. It does not inject code into games, alter game data, write Android settings, or perform a hardware operation. The System Observer adapter is independently fixed to bounded application/host observability and cannot invoke AX-T615 operations. Performance Observer is also independently dispatched, but its fixed adapter normalizes only existing AX-T615 orchestrator evidence into named CPU, GPU, memory, thermal, FPS, battery, and power categories. It reports unavailable fields as `UNKNOWN`, declares `derived_values: NONE`, and cannot apply a hardware or game change. The AX-T615 plugin remains read-only and continues to enforce all previously documented safeguards. The Step 12 snapshot now includes optional `plugins.system_observer` and `plugins.performance_observer` data when the top-level manager is available, otherwise it emits explicit unavailable envelopes without changing AX-T615 fields.

## Step 12 — Dashboard/UI & Final Validation

Step 12 completes the planned Axmanager milestone with a separate, responsive dashboard for the existing read-only engines and a final end-to-end validation layer. The dashboard is an **observability and policy interface**: it renders only a normalized snapshot from the same Axmanager CLI and orchestration contracts used by terminal users. It does not contain its own decision algorithm, hardware-control path, arbitrary command execution, mutation API, or background collector.

```text
Read-only device telemetry
  → CPU/GPU/memory/thermal/FPS/profile/power controllers
  → orchestrator evidence → decision → lifecycle, hysteresis, audit
  → bin/dashboard snapshot/export
  → static dashboard/index.html
```

### Dashboard workflow

The dashboard is dependency-free static HTML, CSS, and browser JavaScript under `dashboard/`. `bin/dashboard` is its small read-only service boundary. It calls existing controller and orchestrator commands, normalizes their output into a JSON snapshot, and never writes to a device-control interface. The browser validates snapshot shape, requires an explicit read-only marker, caps loaded local snapshot files at 1 MB, renders text through DOM text nodes rather than HTML injection, and rejects malformed or non-read-only data.

```sh
./bin/dashboard path
./bin/dashboard snapshot
./bin/dashboard export
```

`snapshot` prints a JSON document to standard output. `export` writes only `dashboard/data/current-snapshot.json`, which is ignored as runtime data, and reports `READ_ONLY=YES`. Open `dashboard/index.html` in a modern local browser and use **Load safe snapshot** to choose the exported JSON. The user interface is responsive for desktop, tablet, and narrow mobile widths; it presents unavailable hardware data as `Unavailable`, `Unsupported`, `Not detected`, or `No data` instead of fabricating a measurement.

The overview presents system health, CPU/GPU/memory/thermal/battery/FPS information when evidence exists, game-session/profile status, bounded monitoring context, a recommendation dossier, recovery status, blocked policy-operation classes, and a dry-run chain. The profiles panel is policy-only: it lists known profile catalog entries from the existing profile engine and shows the CLI commands that support inspection or safe selection. It does **not** assert that profile selection changes a governor, clock, charging policy, or any device setting.

### Orchestrator and session compatibility

The top-level `axgo` CLI and every earlier controller remain unchanged. The dashboard exporter delegates all recommendations to `bin/orchestrator-decision`, and it derives evidence through `bin/orchestrator-evidence`. Session and profile information comes from the existing `bin/session`, `bin/profile`, and `bin/game-profile` interfaces. The dashboard does not introduce a second policy source, and its dry-run representation is explicitly labeled as a recommendation, not an applied optimization.

### Safety, security, and deployment model

Step 12 preserves the complete read-only boundary. It does not write `/proc` or `/sys`, change CPU/GPU governors or frequencies, call a Power HAL, set Android properties, modify charging limits, alter battery or thermal protection, change ZRAM/swap/LMKD/OOM settings, or kill/force-stop processes. The dashboard exposes no secret material, filesystem browser, or arbitrary shell endpoint. Snapshot values are treated as display data only; no value from a snapshot is executed as shell or browser code.

The expected model is a local static dashboard opened by the device owner, or a separately hosted static copy behind an operator-controlled access boundary. It has no authentication layer because it has no remote command API and reads a locally selected, read-only snapshot. If an operator chooses to host snapshots remotely, transport security and access control are the operator's responsibility; Axmanager does not provide remote device control.

## Phase 4 — Unified VEGAS-inject control plane

The repository-level `bin/vegas` now provides a fixed unified read-only observability boundary over the existing AX-T615 adapter, System Observer, and Performance Observer. `sh ../bin/vegas status` reports platform readiness, all three registered plugins, observed CPU/GPU/memory/thermal/FPS/battery/power evidence where available, and the existing conservative policy recommendation. `sh ../bin/vegas snapshot` composes a schema-`1` JSON document with separate `system`, `performance`, `gaming`, `decision`, `plugins`, and `safety` sections. The AX-T615 object is intentionally obtained through `gaming snapshot`, which omits nested observer envelopes and avoids duplicate telemetry payloads.

`sh ../bin/vegas inspect`, `sh ../bin/vegas capabilities`, and `sh ../bin/vegas plugin health` expose only fixed metadata, bounded evidence categories, validated adapter health, and the **hardware control capabilities: NONE** boundary. Existing `gaming`, `system`, `performance`, dashboard, AXGO, module scripts, profiles, policy adapters, and orchestrator behavior remain compatible. The dashboard accepts both its established AX-T615 snapshot and the unified VEGAS-inject snapshot; unified input is normalized only after its object shape and read-only marker are validated, then rendered with text nodes rather than HTML injection.

The unified layer preserves the complete safety policy: no arbitrary path dispatch, metadata execution, hardware writes, Android property changes, network operations, process control, game modification, inferred telemetry, or duplicated policy engine. Missing evidence is retained as `UNKNOWN`/unavailable rather than fabricated. `../tests/test_vegas_unified.sh` covers the unified CLI, schema/provenance, fixture-backed healthy and unavailable telemetry, malformed metadata rejection, arbitrary-operation rejection, plugin isolation, dashboard no-injection behavior, static forbidden-operation checks, and repository-local temporary paths for Termux portability.

## Phase 6 — Advanced Telemetry & Evidence Engine

`../bin/evidence-engine` is a fixed POSIX, read-only normalizer exposed through `sh ../bin/vegas evidence {status|capabilities|inspect|evaluate|snapshot|history}` and the AX-T615 plugin’s fixed `evidence` operation. It consumes only repository-owned orchestrator evidence, preserves each metric’s explicit state (`VALID`, `UNKNOWN`, `UNAVAILABLE`, `STALE`, or `INVALID`), and emits timestamp, freshness, provenance, confidence, and validity without fabricating values. Its small fixed history contains no personal data and supplies deterministic CPU/GPU/memory/thermal/FPS/frame-time/battery/power trend classifications only.

The engine reports transparent quality classifications and names thermal escalation, memory pressure, FPS instability, frame-pacing degradation, and power anomalies only when supported by normalized evidence. When safety evidence is invalid, stale, missing, or unreliable, `bin/orchestrator-decision` reports an explicit conservative read-only fallback with its reason; it does not perform a control action. Unified VEGAS and dashboard snapshots retain established schemas and plugin envelopes while adding the separate `evidence_engine` section. The static dashboard validates that shape before text-safe rendering of availability, freshness, provenance, confidence, trends, bounded history, quality, conditions, and fallback rationale.

## Phase 7 — Intelligent Bottleneck Analysis Engine

`../bin/bottleneck-engine` is a fixed POSIX, read-only analysis component, available through `sh ../bin/vegas analysis {status|analyze|snapshot|capabilities}` and the AX-T615 plugin’s fixed `analysis` operation. It consumes the Phase 6 evidence-engine snapshot rather than raw or fabricated device values. It can emit only the deterministic classifications `CPU_LIMITED`, `GPU_LIMITED`, `MEMORY_LIMITED`, `THERMAL_LIMITED`, `POWER_LIMITED`, `FRAME_PACING_LIMITED`, `DISPLAY_LIMITED`, `MIXED_BOTTLENECK`, `NO_CLEAR_BOTTLENECK`, or `INSUFFICIENT_EVIDENCE`, together with confidence, explanation, supporting and conflicting evidence, source provenance, a bounded trend summary, and a recommended observation.

Its retained trend context is capped by the Phase 6 evidence-engine history; the analysis component does not create unbounded logs or access any personal data. Missing, stale, invalid, or unsafe safety evidence produces `INSUFFICIENT_EVIDENCE`, `LOW` confidence, and the advisory `remain_conservative` recommendation. Valid degraded evidence can still be explained as an advisory bottleneck, but never authorizes a change.

The model is explicitly ordered as **Evidence → Analysis → Recommendation → Action**. Evidence is normalized observation; analysis is a deterministic interpretation; recommendation is an inspect/monitor/collect-more-evidence statement. **Action** would modify device or game state, and AX-T615/VEGAS-inject intentionally stops before that stage. `bin/orchestrator-decision` retains its existing safety-first policy behavior and exports analysis fields only as advisory decision context.

## Phase 8 — Policy & Recommendation Engine

`../bin/policy-engine` is a fixed POSIX, read-only recommendation component, available through `sh ../bin/vegas policy {status|evaluate|snapshot|capabilities}` and the AX-T615 plugin’s fixed `policy` operation. It consumes only the Phase 6 evidence snapshot, Phase 7 bottleneck analysis, and explicitly available AX-T615 profile/session context. It emits the deterministic states `SAFE`, `CONSERVATIVE`, `BALANCED`, `PERFORMANCE_ADVISORY`, `COOL_ADVISORY`, `BATTERY_ADVISORY`, `INSUFFICIENT_EVIDENCE`, `SAFETY_BLOCKED`, or `UNKNOWN` together with a recommendation, confidence, priority, reason, evidence quality, bottleneck context, rejected options, safety classification, provenance, timestamp, and bounded-history summary.

The policy order is fixed: **safety evidence**, **thermal**, **memory**, **battery/power**, **performance**, then **user profile**. Unknown, stale, invalid, or unsafe safety evidence always returns `INSUFFICIENT_EVIDENCE` with low confidence and `remain_conservative`. Valid thermal, memory, and power pressure outrank every performance or profile preference. A GPU or CPU performance advisory requires bounded supporting history and inherits the bottleneck confidence conservatively; frame-pacing and display findings retain investigation-oriented recommendations. The user profile is a preference only and can never override protection.

Bounded evidence history prevents the policy from escalating toward performance advice on a single sample, while a validated safety degradation can immediately produce a protective downgrade. The policy engine stores no unbounded history, accesses no personal data, and exposes no action layer. The required product boundary is **Evidence → Analysis → Policy → Recommendation → [Future Action Layer]**; this release stops at **Recommendation**. Its `policy` envelope is advisory context for `bin/orchestrator-decision`, unified VEGAS snapshots, and `bin/dashboard snapshot`; none of those outputs can apply profile, CPU/GPU, display, charging, thermal, memory, process, or game changes.

Unified snapshots and `bin/dashboard snapshot` include a separate `analysis` envelope. The dashboard’s **Intelligent Analysis** panel text-safely presents the current bottleneck, confidence, explanation, supporting and conflicting evidence, evidence quality, bounded history/trends, recommended observation, and safety classification. No dashboard field is executable, and no analysis result changes CPU/GPU controls, display refresh, charging, thermal policy, memory policy, processes, or game data.

## Phase 9 — Controlled Action Layer Architecture

`../bin/action-engine` is a fixed POSIX controlled-action component, available through `sh ../bin/vegas action {status|snapshot|capabilities|plan|validate|dry-run|apply|rollback|history|lock|unlock}` and the AX-T615 plugin’s allowlisted `action` operation. It is **dry-run by default** and begins with the action lock **enabled**. Its immutable allowed-action registry contains only `refresh_telemetry`, `clear_runtime_state`, and `reset_recommendation_state`; all three map to the same deterministic, engine-owned `refresh_managed_recommendation_state` marker. It never accepts a caller-supplied shell command, path, setting, package, process, profile, or hardware target.

The validation sequence is fixed: a plan must use an allowed identifier; safety evidence must be fresh and `HEALTHY` or `VALID`; the action lock must be explicitly released through `unlock`; explicit apply must be requested; the short managed-state cooldown and single execution lock must permit the operation; and the action must remain within the engine’s repository-local runtime directory. Unknown, stale, invalid, unsafe, or degraded safety evidence cannot unlock or apply an action. Thermal, memory, and battery/power protection therefore remain above any performance or profile preference.

`apply` records only a VEGAS-inject managed marker, an execution status, and a bounded local audit record. It does not modify device state. `rollback` is fixed and removes only that managed marker; it does not restore or change CPU/GPU controls, charging, display, thermal policy, memory policy, kernel settings, processes, games, apps, Android properties, or system files. Bounded audit history is limited to sixteen non-sensitive local entries, and a stale engine-owned execution lock is deterministically recoverable.

The required boundary is **Evidence → Analysis → Policy → Recommendation → Action Plan → Validation → Dry Run → Explicit Apply → Verification → Rollback**. The dashboard reports this architecture without exposing browser controls. Unified, AX-T615, and dashboard snapshots contain a backward-compatible `action` envelope with plan, validation, lock, allowed/blocked action categories, result, rollback, and bounded audit context.

## Action Safety Gate — Simulation-Only Boundary

The public action interface is now `../bin/action-gate`, available through `sh ../bin/vegas action {status|evaluate|simulate|capabilities}` and the AX-T615 plugin’s fixed `action` operation. It is not a continuation of the earlier public controlled-action route. It accepts no caller-selected action ID, shell command, path, setting, process, package, game, profile, or hardware target. Instead, it derives exactly one internal request from the existing policy snapshot and returns either `SIMULATED_RECOMMENDATION` or `BLOCKED`.

The fixed priority order is **policy availability and safety classification**, **evidence quality/freshness**, **confidence**, then the derived recommendation. `UNKNOWN`, `UNAVAILABLE`, `STALE`, `INVALID`, empty, malformed, or insufficient safety evidence fails closed; an `unsafe` policy classification, low confidence, unknown recommendation, or conservative policy state also returns `BLOCKED`. `simulate` may append a non-sensitive bounded local audit record but never creates a device, profile, process, or managed-state action. The retained audit window has at most sixteen records and cannot be set by an input argument.

The architecture boundary is **Evidence → Analysis → Policy → Recommendation → Action Gate → [Future Real Action Layer]**. The bracketed future layer is deliberately absent. Existing `bin/action-engine` files remain repository-internal compatibility components but are not exposed by `vegas action` or the AX-T615 plugin. `bin/orchestrator-decision`, unified snapshots, and dashboard snapshots surface Action Safety Gate context only as advisory, simulation-only evidence.

### Final validation

`tests/test_dashboard.sh` verifies snapshot export, read-only markers, decision/safety propagation, static browser-script syntax, bounded JSON rendering safeguards, dry-run wording, and the absence of unsafe UI operations. `tests/test_e2e_final.sh` covers realistic healthy-gaming, thermal escalation, low-battery, conflicting-signal, unavailable-telemetry, and recovery scenarios using labeled fixture evidence. The full `tests/test_*.sh` suite remains the final regression gate and includes all earlier CPU, thermal, GPU, memory, FPS, profile, power, and orchestration tests.

```sh
sh tests/test_dashboard.sh
sh tests/test_e2e_final.sh
failed=0; for test_file in tests/test_*.sh; do sh "$test_file" || failed=1; done; exit "$failed"
```

The release review also checks shell and browser-script syntax, `git diff --check`, static forbidden-write patterns, CLI smoke paths, runtime cleanup, fixture immutability, and absence of generated runtime files. The final Step 12 validation run completed **70 test suites with 0 failures**; the focused dashboard suite completed **24 assertions with 0 failures**, and the end-to-end suite completed **16 assertions with 0 failures**.

### Final limitations

Axmanager is limited by the hardware and Android interfaces that the target device actually exposes. Sensors, GPU utilization, FPS/frame-time data, battery electrical fields, foreground-game detection, and session durations can be unavailable or unsupported. Historical charts are intentionally absent unless bounded-session telemetry is supplied. Profile selection is policy-only, and all recommendations remain recommendations. Android and manufacturer thermal and battery protection remain authoritative at all times.
