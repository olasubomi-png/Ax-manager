# VEGAS-inject for AxManager v1.4.8

## Purpose and compatibility

`vegas-inject.zip` is a real, unrooted AxManager plugin archive for **AxManager v1.4.8**. It uses the documented AxManager module shape: root-level `module.prop`, optional installed `action.sh` and `uninstall.sh`, and `webroot/index.html`. Its `axeronPlugin=14800` value is derived from the official v1.4.8 API manifest and is the minimum server version declared by this package.

The package is intentionally not a Magisk module, Android app, kernel extension, root tool, or performance controller. It contains the existing VEGAS-inject read-only observability and advisory runtime only.

## Download AxManager and the VEGAS plugin

Install AxManager from the upstream project’s **official v1.4.8 GitHub release**, not from a third-party mirror. The verified release asset is [`AxManager_v1.4.8.r349_14800-release_2605242016.apk`](https://github.com/fahrez182/AxManager/releases/download/v1.4.8/AxManager_v1.4.8.r349_14800-release_2605242016.apk); the release page is available at [AxManager v1.4.8](https://github.com/fahrez182/AxManager/releases/tag/v1.4.8). Android may require the user to authorize the chosen browser or file manager as an installation source before it can install an APK. Do not grant root access, install an unrelated manager, or replace the official release asset.

Download the matching, repository-built [`vegas-inject.zip`](https://github.com/olasubomi-png/Ax-manager/raw/main/dist/vegas-inject.zip) archive. Retain its original ZIP form: AxManager installs a plugin as a module ZIP, so do not extract it, repackage it, or add a `customize.sh` file.

## Start AxManager with on-device wireless debugging

AxManager’s official on-device wireless-debugging startup path applies to Android 11 and later and does **not** require a computer. It is a temporary privileged-debugging channel, not root access. Repeat the start flow after every device reboot, and disable Wireless debugging when it is no longer required. [1]

1. On the device, enable **Developer options**, then enable both **USB debugging** and **Wireless debugging**. Exact menu names vary by manufacturer.
2. Open AxManager and select its **Start with Wireless Debugging** path.
3. Return to Android **Wireless debugging**, select **Pair device with pairing code**, and note the one-time code displayed by Android.
4. Enter that code in AxManager’s pairing notification. Wait for **Pairing successfully**, then return to AxManager and wait for it to connect. Some devices require one more tap on **Start**.
5. Before installing a plugin, confirm AxManager shows its connected/started state. If it does not, repeat the pairing flow rather than bypassing Android’s confirmation.

### Optional desktop ADB pairing

Desktop ADB pairing is useful for verifying a computer-to-device debugging connection, but it is **separate from AxManager’s own in-app pairing**. Pairing a computer does not activate AxManager, and it should not be used to bypass the app’s pairing confirmation. With Android 11+ and current Android SDK Platform Tools, place the computer and device on the same trusted network, select **Pair device with pairing code**, and run:

```sh
adb pair <device-ip>:<pairing-port>
```

Enter the code shown on the device, then verify the desktop connection with:

```sh
adb devices
```

Use only a trusted network, keep debugging access limited to devices you control, and remove a paired desktop through Android’s **Wireless debugging** settings when it is no longer needed. [2]

## Install, enable, disable, and uninstall

1. Keep `vegas-inject.zip` intact after download.
2. In the connected AxManager app, open its **Plugin** installer and select the ZIP. Review the AxManager **Install Plugin?** confirmation before accepting it.
3. Refresh the plugin list if needed and verify a plugin card named **VEGAS-inject (Read-only)** with ID `vegas-inject`, version `1.2.0-axmanager`, and AxManager support value `14800`.
4. AxManager auto-enables a plugin after its confirmed installation. Use the plugin toggle only to enable or disable it. This package has no `post-fs-data.sh` or `service.sh`, so enabling it never starts a daemon, applies a setting, or performs a boot-time operation.
5. When the plugin is enabled, **Web UI** opens the static safety notice and **Action** runs only `vegas action simulate`. The action can return a conservative `SIMULATION_BLOCKED` result when the observed evidence is unavailable or weak; do not attempt to bypass that result.
6. Use AxManager’s normal uninstall action to remove the plugin. The package-local `uninstall.sh` is a no-op confirmation script and does not restore, reset, or modify device settings.

The AxManager v1.4.8 source and documentation were inspected to validate this archive contract. Device-side installation still depends on the user’s AxManager installation and is not emulated by the repository test suite.

## Action entrypoint and simulation boundary

AxManager may expose `action.sh` as the module action. This package resolves its installed root with the required POSIX form:

```sh
MODDIR=${0%/*}
```

It then invokes only:

```sh
"$MODDIR/runtime/bin/vegas" action simulate
```

The result is a JSON advisory record from the existing Action Safety Gate. It is always read-only and simulation-only. It may be `SIMULATION_BLOCKED` when evidence is unavailable or too weak; that is a conservative success state, not an error to bypass.

> There is no package route for root access, `su`, `setprop`, `/proc` or `/sys` writes, governor changes, process termination, networking, shell evaluation, arbitrary command forwarding, or a real action executor.

## WebUI

The package provides `webroot/index.html`, the documented AxManager/KSU-compatible WebUI location. It is a **static, non-interactive safety notice**. It has no form controls, WebView bridge, fetch request, WebSocket, inline command mechanism, or dashboard-to-shell path. It does not present live telemetry; use the installed module action or the main VEGAS runtime interfaces for read-only snapshots.

## Included and excluded contents

Included package contents are limited to fixed VEGAS binaries, declarative plugin metadata and registry files, AX-T615 adapters and safe configuration, the module metadata and lifecycle entrypoints, and the static WebUI. The build excludes repository history, test suites, logs, generated runtime state, dashboard development assets, build scratch files, secrets, and personal information.

## Reproducible validation

From the repository root, build and verify the archive with:

```sh
sh scripts/build-axmanager-plugin.sh
sh tests/test_axmanager_plugin_package.sh
```

The package test rebuilds the ZIP, extracts it into a repository-local temporary directory, validates its official module fields and permissions, confirms the static WebUI boundary, and runs the extracted action entrypoint. It does not install software or access a device.

## References

[1]: https://fahrez182.github.io/AxManager/guide/user-manual.html "AxManager official user manual — Start with Wireless Debugging"
[2]: https://developer.android.com/studio/command-line/adb#connect-to-a-device-over-wi-fi "Android Developers — Connect to a device over Wi-Fi"
