# Runbook: High CPU

## Symptoms

- Portal load average remains high.
- UI slows down.
- Capture warning says CPU is the bottleneck.
- Background jobs or rollups stay busy.

## First Checks

- Operational health portal, database, rollups and heavy jobs components.
- Whether capture queue drops are present.
- Recent release version.
- Worker limits and background cadence.

## Likely Domains

- `data-capacity`: traffic exceeds available CPU.
- `product-code`: expensive query or loop.
- `deployment-os`: too few cores, noisy neighbor or CPU throttling.
- `configuration`: worker/background settings too aggressive.

## Validation

CPU issue is resolved when capture remains at target percentage, queue drops are zero, portal requests respond normally and rollups catch up.
