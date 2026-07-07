# Controller Boundary Expansion

This phase adds module boundaries for major remaining monolith feature groups:

- Mail send/claim
- Pets
- Tool automation
- Weather features
- ESP / overlays
- Runtime diagnostics

These are boundaries, not full behavior ports. Monolith fallback remains required for actual feature behavior until each boundary receives exact migrated logic and runtime parity tests pass.

Current honest migration percentage: 60%.
