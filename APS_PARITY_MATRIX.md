# APS Parity Matrix

| Existing Branch | Current Behavior | New Owner | Test Case | Status |
|---|---|---|---|---|
| No saved sprinkler position | Wait/retry, keep resume state | ApsController | Start APS without saved position | Pending |
| Sprinkler place failed | Keep APS/resume, save config, retry | ApsController | Remove sprinkler/tool or force fail | Pending |
| plantedCount <= 0 | Stop APS, clear resume, save config | ApsController | No seed/tool/valid spots | Pending |
| Initial scan success | Cancel reverse, stop APS, clear resume, webhook success | ApsController + WebhookService | Set threshold low | Pending |
| Below threshold | Continue scan then safe rejoin | ApsController + ApsSafetyService | Set high threshold | Pending |
| No candidate / slow load | Extra 12s grace scan before rejoin | ApsController | Slow load / crop not ready | Pending |
| Manual OFF during scan | Clear resume, save, stop before rejoin | ApsController | Toggle OFF while scanning | Pending |
| Manual OFF during rejoin wait | Clear resume, save, abort teleport | ApsSafetyService | Toggle OFF during 7s wait | Pending |
| Teleport failed | Retry teleport only after reverse safety | ApsSafetyService | Force teleport pcall fail if possible | Pending |
| Old crop present | Ignore old IDs / old plantedAt | GardenService / ApsController | Existing old crop before batch | Pending |
| `kg == nil` | Must not pass threshold | GardenService | Crop with missing weight | Pending |
| Above threshold | `kg >= threshold` passes | GardenService | Exact equals threshold | Pending |
| Below threshold mode | `kg <= threshold` passes | GardenService | Exact equals threshold | Pending |
| Webhook fail | APS logic continues | WebhookService | Bad webhook URL | Pending |
| Two accounts | Separate config/log, no `_G` collision across clients | ConfigService | Run 2 clients | Pending |
