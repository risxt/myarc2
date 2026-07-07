# GAG2 Project Brain

## Purpose

This file is the source of truth for the GAG2 refactor/migration work.

Current stable source: `../gag2.lua`.
New workspace: `GAG2/`.

## Non-Negotiable APS Invariants

1. APS must never teleport/rejoin without reverse safety.
2. Reverse must be fired immediately before APS teleport/rejoin.
3. If reverse fails after retry, APS must abort teleport and log SAFETY.
4. Manual OFF must set `Cfg.autoPlantScan=false` and `Cfg.apsResume=false`.
5. Manual OFF during scan or rejoin wait must abort pending teleport.
6. Webhook is notification-only and must never drive APS logic.
7. APS success must cancel reverse, stop APS, clear resume, and save config.
8. Old crops must not count as current batch.
9. `kg == nil` must never pass threshold.
10. Multi-account config/log isolation must be preserved.

## Current APS Core Flow

1. Wait for local player plot.
2. Read saved sprinkler position.
3. Force teleport-disable settings for APS stability.
4. Fire reverse packet.
5. Place sprinkler at saved position.
6. Snapshot old/current plant IDs to ignore stale crops.
7. Plant seed batch.
8. Scan crop KG against threshold.
9. If no candidate is seen, apply grace scan before rejoin.
10. If success, cancel reverse, stop APS, clear resume, send success webhook.
11. If fail/below, keep resume, fire reverse safety, delay, re-check manual OFF, fire reverse again, then teleport.

## APS Webhook Policy

Discord webhook is only for user-facing information.

Current policy:

- Send only on `success` / target hit.
- Ping `@everyone`.
- Green embed.
- Clean no-emoji format.
- Do not send `below`.
- Do not send `fail_rejoin`.
- Trace logs still record internal skip/fail states.

## Config / Resume Semantics

- Config file is per account by `Player.Name` unless mapped explicitly.
- `apsResume=true` means resume due to APS-controlled fail/rejoin.
- Manual OFF must clear `apsResume` permanently until user turns APS ON again.
- UI initialization callbacks must not overwrite manual OFF state.
- `cfgReadyToSave` protects init-time callback saves.

## Migration Rule

Before moving any APS branch into a new module, map it in `APS_PARITY_MATRIX.md` and add a test case.
