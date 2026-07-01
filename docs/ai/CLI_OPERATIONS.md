# CLI Operations

Use CLI only when portal evidence is insufficient or the operator explicitly grants shell access. Prefer read-only commands first.

## Safe Read-Only Checks

- Service status for `voxywatch`, `voxywatch-sniffer` and optional `voxywatch-srs`.
- Bounded journal excerpts for the affected service.
- Disk, CPU, RAM and load averages.
- PostgreSQL/Timescale health with statement timeouts.
- Local version from the installed portal binary.

## Production Rules

- Do not edit files under `/opt/voxywatch` as a fix.
- Do not patch JavaScript, Python or SQL directly on a customer server.
- Do not restart capture services unless the operator approved the operational impact.
- Do not run broad database scans on high-volume installs.
- Do not run destructive SQL, delete audio/segments/CDR or force-reset repositories.

## Update Path

Production code fixes must flow through:

`local code -> tests -> signed build -> GitHub release -> latest.json -> portal updater or installer -> validation`

If the portal update button fails, classify whether it is:

- Service-control permission problem.
- Release manifest/download problem.
- Signature/SHA problem.
- Installer/runtime problem.
- Network egress problem.
