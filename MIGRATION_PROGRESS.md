# GAG2 Migration Progress

## Status: 100%

All controller behavior has been ported from gag2.lua monolith to modular controllers.

### Evidence

| Gate | Status |
|---|---|
| Controller blocker audit | 0 blockers |
| Static verification | PASS |
| APS parity static check | PASS |
| FeatureRegistry | all modular |
| Dependency wiring | complete |
| Runtime metadata | FullyMigrated=true, Percent=100 |

### Architecture

```
releases/main.lua          → entrypoint, loads all modules
src/Runtime/               → ModuleLoader, Manifest, Guard, Bridge, SelfTest
src/Core/                  → Logger, Config, ApsState, FeatureRegistry
src/Services/              → APS Safety, Webhook, Garden, Remote, HTTP, etc.
src/Controllers/           → 13 controllers with real behavior
src/UI/                    → ToggleBinder, UIRegistry
tests/                     → Static verification, parity checks, audit
```

### Controllers (13/13 modular)

1. ApsController
2. AutoCollectController
3. AutoSellController
4. LocalPlayerController
5. MailController
6. MiscController
7. OverlayController
8. PetsController
9. ShopController
10. StackFarmController
11. StealController
12. ToolAutomationController
13. WeatherController

### Safety

- Monolith bridge retained as rollback safety net
- APS reverse-before-teleport invariant preserved in ApsSafetyService
- Manual OFF abort preserved in ApsController
