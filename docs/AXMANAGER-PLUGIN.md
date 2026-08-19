# VEGAS-inject for AxManager v1.4.8

## Purpose and compatibility

`vegas-inject.zip` is a real, unrooted AxManager plugin archive for **AxManager v1.4.8**. It uses the documented AxManager module shape: root-level `module.prop`, optional installed `action.sh` and `uninstall.sh`, and `webroot/index.html`. Its `axeronPlugin=14800` value is derived from the official v1.4.8 API manifest and is the minimum server version declared by this package.

The package is intentionally not a Magisk module, Android app, kernel extension, root tool, or performance controller. It contains the existing VEGAS-inject read-only observability and advisory runtime only.

## Install, enable, disable, and uninstall

1. Obtain the repository-built `dist/vegas-inject.zip` artifact without modifying it.
2. In AxManager v1.4.8, use its plugin installation flow and choose the ZIP archive.
3. Confirm that the plugin list shows **VEGAS-inject (Read-only)** with ID `vegas-inject`.
4. Use AxManager’s plugin toggle to enable or disable the module. The package has no `post-fs-data.sh` or `service.sh`, so enabling it never starts a daemon, applies a setting, or performs a boot-time operation.
5. Use AxManager’s normal uninstall action to remove the plugin. The package-local `uninstall.sh` is a no-op confirmation script and does not restore, reset, or modify device settings.

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
