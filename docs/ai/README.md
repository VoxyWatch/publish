# AI README

VoxyWatch is an on-prem or customer-hosted telecom observability platform for SIP/HEP capture, call tracing, RTP/audio reconstruction, SNMP/NMS exposure, operational health, incident detection, release updates and configuration assistance.

Use this pack to help an operator configure the product or diagnose an issue without creating unnecessary support tickets.

## Operational pack

Load only the operator material needed for the question:

1. [AI troubleshooting](../../AI_TROUBLESHOOTING.md) for symptom-led diagnosis.
2. [Configuration and credentials](../../AI_CREDENTIALS.md) or the relevant Settings screen.
3. [MCP](../../MCP_SERVER.md), [HTTPS](../../HTTPS_CONFIGURATION.md), or
   [Passive Mirror](../../PASSIVE_MIRROR_CAPTURE.md) when that integration is in scope.
4. Authorized diagnostic results obtained through the portal or MCP.

Do not load internal architecture maps, source maps, governance records or broad logs
into an operator/support conversation.

## Evidence Model

The safest built-in evidence is:

- `/api/operational-health`

These surfaces are designed to avoid secrets and customer identifiers. Do not replace them with broad log dumps unless the operator explicitly approves a narrow, sanitized extract.

## Fault Domains

Classify every issue into one of these domains:

- `product-code`: reproducible VoxyWatch code behavior.
- `packaging-release`: install/update/release artifact problem.
- `deployment-os`: Linux, service management, permissions, disk, CPU, RAM or network deployment.
- `configuration`: VoxyWatch settings, thresholds, licenses, users, roles or feature flags.
- `integration-source`: SBC/probe/HEP/SIPREC source behavior.
- `external-provider`: carrier, upstream provider, DNS, NTP, GitHub or third-party dependency.
- `data-capacity`: hardware or data volume beyond current limits.
- `security`: auth, exposure, credentials or privacy.
- `not-a-bug`: expected behavior or external condition.

## Assistant Behavior

Be practical and evidence-driven. State what is known, what is inferred and what remains unknown. When suggesting a fix, include how to validate it and how to roll it back.
