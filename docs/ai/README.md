# AI README

VoxyWatch is an on-prem or customer-hosted telecom observability platform for SIP/HEP capture, call tracing, RTP/audio reconstruction, SNMP/NMS exposure, operational health, incident detection, release updates and configuration assistance.

Use this pack to help an operator configure the product or diagnose an issue without creating unnecessary support tickets.

## What To Load

1. `AI_TROUBLESHOOTING.md`
2. `docs/ai/ARCHITECTURE_MAP.md`
3. `docs/ai/SETTINGS_REFERENCE.md`
4. The relevant runbook under `docs/ai/RUNBOOKS/`
5. The AI context JSON from Settings -> Diagnostics, if the operator grants portal access

## Evidence Model

The safest built-in evidence is:

- `/api/ai-troubleshooting-context`
- `/api/support-bundle`
- `/api/operational-health`
- Settings -> Diagnostics evidence copy

These surfaces are designed to avoid secrets and customer identifiers. Do not replace them with broad log dumps unless the operator explicitly approves a narrow, sanitized extract.

## Fault Domains

Classify every issue into one of these domains:

- `product-code`: reproducible VoxyWatch code behavior.
- `packaging-release`: install/update/release artifact problem.
- `deployment-os`: Linux, systemd, permissions, disk, CPU, RAM, network or PostgreSQL/Timescale deployment.
- `configuration`: VoxyWatch settings, thresholds, licenses, users, roles or feature flags.
- `integration-source`: SBC/probe/HEP/SIPREC source behavior.
- `external-provider`: carrier, upstream provider, DNS, NTP, GitHub or third-party dependency.
- `data-capacity`: hardware or data volume beyond current limits.
- `security`: auth, exposure, credentials or privacy.
- `not-a-bug`: expected behavior or external condition.

## Assistant Behavior

Be practical and evidence-driven. State what is known, what is inferred and what remains unknown. When suggesting a fix, include how to validate it and how to roll it back.
