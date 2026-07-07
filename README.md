# GAG2 — Grow a Garden Automation

Private modular automation suite for Grow a Garden (Roblox).

## Quick Start

Use the safe modular loader:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/risxt/myarc2/main/releases/loader.lua?v=" .. tostring(os.time())))()
```

## Repository Structure

```text
releases/
  loader.lua          -- Safe GitHub loader for modular runtime
  main.lua            -- Modular runtime entrypoint
  gag2.live.lua       -- Legacy monolith fallback/reference
src/
  Core/               -- Shared state, config, logging, registry
  Runtime/            -- Module loader, guards, diagnostics
  Services/           -- Pure/core feature services
  Controllers/        -- Feature controllers
  UI/                 -- UI extraction and binding layer
docs/                 -- Migration and safety documentation
tests/                -- Static verification scripts and reports
PROJECT_BRAIN.md      -- Source-of-truth architecture memory
```

## Production Entrypoint

`releases/loader.lua` fetches and executes `releases/main.lua` with compile/runtime error reporting.
