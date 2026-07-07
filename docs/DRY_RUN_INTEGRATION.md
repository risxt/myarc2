# Dry-Run Integration Plan

## Purpose

Dry-run mode validates that GAG2 modules can load and initialize without taking over APS behavior.

## Rule

Old APS remains active.

New APS controller must **not** call:

```lua
ApsController.start()
ApsController.runCycle()
```

in dry-run mode.

## Dry-Run Checks

- required modules exist,
- critical services exist,
- `ApsSafetyService` is present,
- `ApsController` is present,
- dependencies can be injected,
- no production state is changed.

## Success Output

```txt
[GAG2 DryRun] module validation: true
[GAG2 DryRun] old APS remains active; new APS is not started
```

## Fail Behavior

If dry-run fails:

- do not start new APS,
- keep old APS active,
- log missing dependency,
- keep feature flag false.
