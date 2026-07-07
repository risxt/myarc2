# Release Checklist

## Before GitHub Upload

- [ ] Static verification PASS.
- [ ] Static parity PASS.
- [ ] Manual test checklist reviewed.
- [ ] Feature flag remains false.
- [ ] `loader.github.template.lua` placeholders replaced.
- [ ] Stable branch/tag selected.

## Before Production Autoexecute

- [ ] GitHub loader fetches modules successfully.
- [ ] Cache fallback tested.
- [ ] Dry-run integration passes.
- [ ] Old APS fallback still available.
- [ ] No direct APS teleport outside `ApsSafetyService`.
- [ ] New APS not enabled until runtime tests pass.

## Runtime Tests Required

- [ ] Success threshold.
- [ ] Below/rejoin.
- [ ] Manual OFF during scan.
- [ ] Manual OFF during rejoin wait.
- [ ] Reverse fail abort.
- [ ] Two-account sanity.
