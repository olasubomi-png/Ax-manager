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
frequency/governor writes, and those writes remain disabled by default. GPU
control does not exist in this step, so the reported GPU action is always
`NONE`.

When thermal information becomes unavailable, the state is `UNKNOWN` and the
recommendation is `CONSERVATIVE`; no assumption of a cool device is made. Game
stop produces an `AX-T615 THERMAL PERFORMANCE REPORT` with duration,
start/peak/average/final temperatures, maximum state, throttle detection,
decision counts, CPU/GPU changes, and safety violations. No thermal trip points,
cooling-device states, CPU/GPU frequencies, governors, properties, or kernel
controls are written by Step 5B.

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