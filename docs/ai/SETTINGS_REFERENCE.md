# Settings Reference

This guide tells an AI assistant what each settings area is for. It is not a substitute for the live UI; use the UI labels and installed version as the source of truth.

## Getting Started

Guides first-run configuration. It checks core readiness such as capture source setup, license state, retention/autopurge, SNMP/NMS readiness and anonymous telemetry preference.

## Capture

Controls HEP/SIP capture inputs, source visibility and capture-related behavior. Capture is business-critical; avoid changes that interrupt ingestion unless the operator approves.

## Trunks

Maps SIP traffic to named carriers, trunks, countries and profiles. Trunk attribution affects health, rollups, incidents, recording scope and analytics.

## Monitoring And Thresholds

Controls health thresholds, adaptive baselines, alarms and incident behavior. Threshold changes should reduce false positives without hiding real outages.

## Fraud

Configures fraud detection profiles, risk countries, velocity caps and simulation. Treat it as read-only analysis until the operator approves active alerting changes.

## SIPREC

Controls the optional SIPREC SRS service. It is a separate service and is off by default. It must never share the sniffer hot path or touch the customer SBC directly.

## SNMP

Configures SNMP agent bind address, allowlist, SNMPv2c community, SNMPv3, traps and thresholds. VoxyWatch exposes private OIDs and standard aliases for generic NMS tools.

## API Integration

Configures read-only API v1 access. API keys are scoped and rate-limited. Do not expose or log API key secrets.

## AI Configuration

Configures provider/model and server-side API token storage for AI summaries. Tokens must not be copied into tickets, docs or chat.

## Diagnostics

Central operational support tab. It exposes operational health, system diagnostics, safe evidence, support bundle and AI troubleshooting context.

## Update

Shows latest published version and runs signed opt-in updates when service control is enabled.

## License

Uploads and validates license state. License problems should not stop the sniffer from capturing.

## Security And Users

Controls users, roles and password behavior. Only login passwords should be browser-saveable; generated user passwords should require change on first login when offered.
