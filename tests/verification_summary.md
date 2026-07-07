# Verification Summary

## Completed Static Verification

### Load Order

Source: `tests/check_load_order.cjs`

Result: PASS

All current GAG2 modules exist and return module tables.

### Safety Ownership

Source: `tests/static_verify.cjs`

Result: PASS

Findings:

- APS teleport references only exist inside `ApsSafetyService.lua`.
- Reverse constant only exists inside `ApsSafetyService.lua`.
- Modules return tables.
- `ApsController.lua` owns APS resume lifecycle state writes.

### Static Parity

Source: `tests/parity_static_check.cjs`

Result: PASS

Checked parity:

- `Above` threshold uses `>=`.
- `Below` threshold uses `<=`.
- `kg == nil` does not pass.
- fruit readiness uses `Age` and `MaxAge`.
- old plant/fruit ignore structures exist.
- `plantedAfterStart` guard exists.
- multi/single scan branches exist.
- reverse/cancel packet constants match.
- success webhook keeps `@everyone`, green color, and target-hit title.

## Not Yet Done

These require Roblox/runtime execution:

- Success threshold test.
- Below/rejoin test.
- Manual OFF during scan.
- Manual OFF during rejoin wait.
- Reverse fail simulation.
- Two-account sanity.

## Production Status

`../gag2.lua` has not been modified by this refactor phase.

GAG2 modules are not production-wired yet.

## Next Gate

Before runtime testing, prepare a dry-run integration mode that loads modules but keeps old APS active.
