# APS Safety Invariants

These rules are non-negotiable.

## Absolute Rules

1. APS must never teleport/rejoin without reverse safety.
2. Reverse must be attempted immediately before APS teleport.
3. If reverse fails after retry, APS must abort teleport.
4. Manual OFF must clear `Cfg.autoPlantScan` and `Cfg.apsResume`.
5. Manual OFF during rejoin wait must abort teleport.
6. Webhook failure must never affect APS decisions.
7. Success threshold must cancel reverse, stop APS, clear resume, and save config.
8. Old crops must not count as current batch.
9. `kg == nil` must never pass threshold.
10. Two Roblox clients must keep config/log state separated per account.

## Safe Rejoin Requirements

A safe APS rejoin must do this sequence:

```txt
check manual OFF
fire reverse with retry
if reverse failed -> stop/abort
save resume state
wait delay
check manual OFF again
fire reverse with retry again
if reverse failed -> stop/abort
teleport
if teleport failed -> fire reverse again before retry
```

## Forbidden Patterns

```lua
TeleportService:Teleport(...)
```

inside APS code without going through the safety wrapper.

```lua
Cfg.apsResume = true
```

after user manual OFF.

```lua
_G._sendApsWebhook("below", ...)
```

as a Discord notification. Below is trace-only now.

## Logging Requirement

Safety-critical events must be logged with a clear tag:

```txt
SAFETY reverse_failed_before_rejoin
SAFETY teleport_aborted_manual_off
SAFETY teleport_attempt_after_reverse
```
