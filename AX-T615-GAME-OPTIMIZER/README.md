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
- Placeholder `cool`, `balanced`, and `performance` profile framework
- Placeholder action and `axgo` command interfaces

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

## Future development roadmap

1. Identify the module manager/environment and confirm its packaging contract.
2. Collect device reports from the Tecno POP 9 / T7250 and validate the kernel
   control paths against the actual firmware.
3. Document safe bounds and behavior for any controls that are actually
   available and writable.
4. Add opt-in, guarded tuning with thermal and rollback safety checks.
5. Add explicitly verified game-package detection and user-facing status.
6. Test across supported firmware versions before enabling any default tuning.

Do not proceed to hardware tuning until the target kernel controls have been
investigated.