# GAG2

Modular refactor workspace for `gag2.lua`.

## Current Status

This repo/workspace contains the modular GAG2 structure and GitHub loader prep.

Production `../gag2.lua` currently keeps the old APS worker active, with a direct safety patch added so APS rejoin aborts if reverse packet fails.

## Structure

```txt
src/
  Core/
    Logger.lua
    ApsState.lua
    ConfigService.lua
  Services/
    ApsSafetyService.lua
    WebhookService.lua
    GardenService.lua
  Controllers/
    ApsController.lua
  loader.local.lua
  integration.disabled.lua
  dry_run.integration.lua
releases/
  loader.lua
  loader.github.template.lua
  RELEASE_CHECKLIST.md
docs/
tests/
backups/
```

## Safety Rules

- APS must never teleport/rejoin without reverse safety.
- Manual OFF must clear `apsResume`.
- Webhook is notification-only.
- `Above` means `kg >= threshold`.
- `Below` means `kg <= threshold`.
- `kg == nil` does not pass.

## GitHub Usage Later

Autoexecute target after upload:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/<USER>/<REPO>/<BRANCH>/releases/loader.lua"))()
```

Use `stable` branch or a version tag for production.
Do not use `main` for stable autoexecute unless intentionally testing dev code.
