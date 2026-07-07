# 70 Percent Migration Gate

This gate means architecture coverage, not pure behavior completion.

## Added in this gate

- Stack farm controller boundary
- Steal controller boundary
- Local player controller boundary
- Misc controller boundary
- Runtime feature parity checklist
- Expanded feature registry

## Honest meaning of 70%

Most major feature groups now have a module/controller owner and are loaded by `releases/main.lua`.

## Still not 100%

Monolith fallback is still required because many controller boundaries do not yet contain exact migrated behavior.
