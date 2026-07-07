# Full Migration Tracker

> Rule: Do not delete monolith fallback until every row is `Live Modular` and runtime-tested.

## Current Honest Migration Percentage

35%

## Feature Areas

| Area | Monolith Lines / Section | Module Target | Status | Runtime Parity |
|---|---|---|---|---|
| Core bootstrap/services | 1-100 | RuntimeContext / ModuleLoader | Partial | Not tested |
| Config mapping/load/save | 17+, config functions | ConfigService | Skeleton | Not tested |
| Speed UI Library | 700-2300 approx | UI/SpeedLibrary.lua | Not started | Not tested |
| Dynamic dropdowns | global `_G._GAG_DYNAMIC_DROPDOWNS` | UI/DropdownService | Not started | Not tested |
| APS reverse safety | APS section | ApsSafetyService | Draft + live monolith patch | Not runtime-tested modular |
| APS webhook | `_G._sendApsWebhook` | WebhookService | Draft | Not runtime-tested modular |
| APS garden scan | APS helper functions | GardenService | Draft | Not runtime-tested modular |
| APS lifecycle worker | APS worker | ApsController | Draft | Not runtime-tested modular |
| Reactive instant collect | `REACTIVE INSTANT COLLECT` | AutoCollectController | Not started | Not tested |
| Auto collect/weather seeds | `AUTO COLLECT WEATHER SEEDS` | WeatherSeedController | Not started | Not tested |
| Auto sell | `AUTO SELL` | AutoSellController | Not started | Not tested |
| Auto shop | `AUTO SHOP` | ShopController | Not started | Not tested |
| Auto steal | `AUTO STEAL` | StealController | Not started | Not tested |
| Auto pets | `AUTO PETS` | PetsController | Not started | Not tested |
| Auto mail send | `AUTO MAIL SEND` | MailSendController | Not started | Not tested |
| Auto mail claim | `AUTO MAIL CLAIM` | MailClaimController | Not started | Not tested |
| Stack farm manager | `STACK FARM MANAGER` | StackFarmController | Not started | Not tested |
| Auto sprinkler | `AUTO SPRINKLER` | SprinklerService/Controller | Not started | Not tested |
| Watering can | `AUTO WATERING CAN` | WateringController | Not started | Not tested |
| Trowel | `AUTO TROWEL` | TrowelController | Not started | Not tested |
| Shovel | `AUTO SHOVEL` | ShovelController | Not started | Not tested |
| Favorite | `AUTO FAVORITE` | FavoriteController | Not started | Not tested |
| ESP | `ESP` | EspController | Not started | Not tested |
| Misc | `MISC` | MiscController | Not started | Not tested |
| Auto plants | `AUTO PLANTS` | AutoPlantsController | Not started | Not tested |
| Local player features | `LOCAL PLAYER FEATURES` | LocalPlayerController | Not started | Not tested |
| Weather predict | `WEATHER PREDICT` | WeatherPredictController | Not started | Not tested |
| Auto weather disconnect | `AUTO WEATHER DISCONNECT` | WeatherDisconnectController | Not started | Not tested |
| Weather bar HUD | `WEATHER BAR HUD` | WeatherHud | Not started | Not tested |
| Inventory value overlay | `INVENTORY VALUE OVERLAY` | InventoryOverlay | Not started | Not tested |
| UI tabs/controls | `UI` onward | UI modules | Not started | Not tested |

## Safe Migration Order

1. Runtime + config.
2. UI library shell.
3. Shared services/remotes.
4. APS fully live modular.
5. Auto collect/weather/stock.
6. Tools automation.
7. Pets/mail/stack farm.
8. ESP/overlays/misc.
9. Remove monolith fallback only after all tests pass.

## Definition of 100%

- `releases/main.lua` does not load `releases/gag2.live.lua`.
- Every feature above is module-owned.
- Every feature passes runtime parity test.
- Autoexecute uses modular `main.lua` only.
