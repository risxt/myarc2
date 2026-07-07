# 100 Percent Gate Blockers

I will not mark this project 100% until these are true:

1. `releases/main.lua` no longer loads `releases/gag2.live.lua`.
2. Every controller contains the exact behavior currently owned by `gag2.live.lua`.
3. `LiveReadinessGate.check(_G.GAG2)` returns true.
4. `MigrationGuard.isFullyMigrated()` returns true.
5. Runtime parity tests are completed for every `FeatureParityChecklist` item.
6. APS reverse-before-teleport invariant passes in modular-only mode.
7. Manual OFF aborts pending APS rejoin/teleport in modular-only mode.
8. UI toggles bind to controller logic instead of monolith callbacks.
9. Config load/save is module-owned and equivalent to monolith config.
10. Monolith fallback is removed safely after verification.

## Current honest status

90% architecture/readiness coverage.

## Why not 100% yet

Several controllers are still boundary modules and return `not_migrated_monolith_fallback_required`.
That means behavior is still provided by `releases/gag2.live.lua` fallback.

Marking 100% now would be false.
