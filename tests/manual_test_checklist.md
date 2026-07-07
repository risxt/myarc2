# GAG2 Manual Test Checklist

## APS Lifecycle

- [ ] Autoexecute resume starts APS only when `apsResume=true`.
- [ ] Manual OFF during scan clears `autoPlantScan` and `apsResume`.
- [ ] Manual OFF during scan prevents rejoin.
- [ ] Manual OFF during 7s rejoin wait aborts teleport.
- [ ] Manual OFF does not cancel reverse that was already fired.

## APS Success

- [ ] Crop above threshold stops APS.
- [ ] Success cancels reverse.
- [ ] Success clears resume.
- [ ] Success sends green webhook.
- [ ] Success webhook pings `@everyone`.
- [ ] Success webhook has no emoji.

## APS Fail / Rejoin

- [ ] Below threshold does not send Discord webhook.
- [ ] Fail/no-candidate does not send Discord webhook.
- [ ] Below threshold follows safe rejoin path.
- [ ] No-candidate waits grace scan before rejoin.
- [ ] Teleport retry fires reverse again first.

## Safety

- [ ] No APS teleport exists outside safety wrapper after refactor.
- [ ] Reverse fail aborts teleport.
- [ ] `kg == nil` does not pass threshold.
- [ ] Old crops are ignored.
- [ ] Exact threshold passes for `Above` with `>=`.
- [ ] Exact threshold passes for `Below` with `<=`.

## Multi-Instance

- [ ] Two accounts use separate config files.
- [ ] Two accounts use separate APS debug logs.
- [ ] Shared webhook still identifies account in message.
- [ ] `_G` state does not collide across separate clients.

## Non-APS Regression

- [ ] Auto collect still works.
- [ ] Reactive instant collect still works.
- [ ] Dropped item collector still works.
- [ ] Stock webhook still works.
- [ ] Sprinkler placement still works.
- [ ] UI settings save/load correctly.
