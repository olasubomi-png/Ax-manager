# AX-T615 Fixed Plugin Adapter

The AX-T615 adapter is a fixed, repository-owned plugin entrypoint. Registry metadata remains declarative and is never an executable command source. The adapter dispatches only allowlisted operations to repository-owned AX-T615 and VEGAS-inject engines.

## Controlled-action operation

Phase 9 adds the fixed `action` operation. It delegates only to `bin/action-engine` using its own fixed operation allowlist: `status`, `capabilities`, `plan`, `validate`, `dry-run`, `apply`, `rollback`, `history`, `lock`, and `unlock`. It does not accept a caller-supplied executable, path, setting, device target, process, package, or profile target.

The adapter starts from the controlled-action engine’s default dry-run mode and enabled emergency lock. Even after a validated explicit unlock, `apply` can affect only the engine-owned VEGAS-inject managed marker. It cannot write hardware or Android control interfaces, change games or processes, make network calls, or apply policy recommendations to a device.
