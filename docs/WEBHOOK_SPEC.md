# APS Webhook Spec

## Purpose

APS webhook is user-facing notification only. It must never control APS logic.

## Current Behavior

Send Discord webhook only when APS target threshold is reached.

Do not send:

- below threshold,
- fail/rejoin,
- no candidate,
- scan debug events.

Those events belong in trace/debug log only.

## Success Payload

Required behavior:

- content: `@everyone`,
- allowed_mentions parse includes `everyone`,
- green embed,
- no emoji,
- clean concise fields.

Example:

```txt
@everyone

Auto-Plant — Target Hit

Target Status Target reached
Weight 56.58 kg
Target Above 35.00 kg
Focus Mega
Scanning Carrot
Username tanoraaken
Action Status Success — stopped
```

## Failure Handling

If webhook request fails:

- log warning/trace,
- do not stop APS,
- do not rejoin because of webhook,
- do not retry in a blocking way.

## Refactor Target

```lua
WebhookService.sendApsSuccess(data)
```

The service should be called after core APS logic already determined success.
