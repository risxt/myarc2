# What Changed In Live gag2.lua

## Direct production patch already applied

File: `../gag2.lua`

Area: APS rejoin path.

Change:

- Before saving resume/rejoining, APS now checks `sendReversePacket()` result.
- Before teleport, APS checks `sendReversePacket()` result.
- Before retry teleport, APS checks manual OFF and reverse result again.

## Why

Old behavior could continue teleport even when `sendReversePacket()` returned false.

New behavior:

```txt
reverse failed -> clear apsResume -> save config -> stop APS -> no teleport
```

## What did not change

- Old APS worker is still active.
- New modular GAG2 APS controller is not live yet.
- Webhook behavior remains success-only.
- GitHub loader is prepared but not used yet.
