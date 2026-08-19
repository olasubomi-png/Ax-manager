# VEGAS-inject Safety Model

## Security posture

VEGAS-inject v1.0 is a **read-only, recommendation-only, simulation-only** platform. Every public program accepts only fixed allowlisted operations. Programs derive their repository locations from their own source directory, validate bounded data before composition, reject extra arguments and caller-selected executable paths, and fail closed when evidence is missing, stale, malformed, unknown, unprovenanced, or unsafe.

| Boundary | Enforced behavior |
|---|---|
| CLI dispatch | Fixed commands and exact bounded argument forms; unknown and surplus input is rejected. |
| Plugins | Fixed registry, declarative metadata, known capability values, fixed `plugin.sh` adapter, no executable metadata or path injection. |
| Evidence | Read-only source observation; unavailable values remain explicit rather than inferred. |
| Analysis and policy | Deterministic advisory output only; no device request is emitted. |
| Action Safety Gate | Internally derived context only; evaluate and simulate only; default deny; bounded audit. |
| Control Plane | Composes validated existing outputs; no duplicated policy decision and no execution path. |
| Dashboard | Static snapshot input, structural validation, text-node rendering, no command or URL bridge. |

## Simulation boundary

`simulate` means that a program may create a bounded repository-local record describing a simulated advisory result. It never means that a policy was applied. Simulation does not create a managed action marker, rollback target, hardware state, game target, process target, profile change, or package target.

> Evidence → Analysis → Policy → Recommendation → Action Safety Gate → **STOP**

No public interface extends past the stop condition. The future real action layer is unavailable by design and no executable metadata, dynamic plugin command, environment-supplied module root, `eval`, or arbitrary path can enable it.

## Data and portability

The platform is designed to operate without root and uses POSIX shell-compatible logic. Android or Termux paths that cannot be read are reported as unavailable. All temporary test state is repository-local rather than relying on `/tmp`. Hardware reference information is descriptive and never becomes a write instruction.
