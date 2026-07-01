# Runbook: Portal OOM

## Symptoms

- `voxywatch` restarts.
- UI becomes unavailable.
- Journal shows heap or out-of-memory errors.
- Working-set trims appear frequently.

## First Checks

- Installed version.
- Portal heap metrics.
- Database component and rollup state.
- Recent expensive queries or heavy jobs.

## Likely Domains

- `product-code`: unbounded in-memory structure or query result.
- `data-capacity`: traffic volume beyond configured memory.
- `deployment-os`: RAM too small or memory pressure outside VoxyWatch.

## Guardrails

Never fix OOM by broadening database scans or reloading large windows into memory. Prefer bounded queries, streaming, working-set caps and tests that reproduce the memory shape.
