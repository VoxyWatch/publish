# Settings Reference

This guide tells an AI assistant what each settings area is for. It is not a substitute for the live UI; use the UI labels and installed version as the source of truth.

Settings and operational Configuration expose contextual `?` help beside configurable rows. The same help is available by pointer hover, keyboard focus or click/tap and follows the user's English/Spanish UI language. Health threshold help also states the evaluation direction, sample gate and the practical effect of sensitivity changes; consult it before proposing a threshold edit.

## Getting Started

Guides first-run configuration. It checks core readiness such as capture source setup, license state, retention/autopurge, SNMP/NMS readiness and anonymous telemetry preference.

## Capture

Controls HEP/SIP capture inputs, source visibility and capture-related behavior. Capture is business-critical; avoid changes that interrupt ingestion unless the operator approves.

## Trunks

Maps SIP traffic to named carriers, trunks, countries and profiles. Trunk attribution affects health, rollups, incidents, recording scope and analytics.

## Monitoring And Thresholds

Configuration → Alerts owns grouped global trunk-health thresholds, adaptive baselines, alarms and incident behavior. Minimum sample is intentionally configured per trunk because traffic volume differs by carrier; an individual trunk can inherit or override the remaining values. Threshold changes should reduce false positives without hiding real outages.

- `warn` is the first degraded state; `crit` is the severe state.
- ASR, NER and MOS degrade when they fall below their limits. SIP 5xx, packet loss, PDD and OWA degrade when they rise above their limits.
- Minimum samples and consecutive open/clear evaluations are anti-noise gates, not quality targets.
- Shared-endpoint controls correlate several logical trunks on one IP or IP:port; shadow mode calculates evidence without opening a visible incident.

## Fraud

Configures fraud detection profiles, risk countries, velocity caps and simulation. Treat it as read-only analysis until the operator approves active alerting changes.

## SIPREC

**Settings → Capture → SIPREC** controls optional recording ingestion, off by default.
See the [capture guide](../../PLATFORM_AND_CAPTURE_VALIDATION.md#siprec-validation) for ports and evidence limits.

## SNMP

Configures SNMP agent bind address, allowlist, SNMPv2c community, SNMPv3, traps and thresholds. VoxyWatch exposes private OIDs and standard aliases for generic NMS tools.

## API Integration

Configures scoped API v1 access, including reads and explicitly permitted export/generation jobs.
API keys are scoped and rate-limited. Do not expose or log API key secrets.

## AI Configuration

Configures provider/model and server-side API token storage for AI summaries. Tokens must not be copied into tickets, docs or chat.

## Update

The compact Settings header shows the installed/available version and update controls;
there is no separate Update tab. Updates are explicit administrative actions.

## Diagnostics and logs

Diagnostics shows local system resources and their recent history; use Refresh to
request the current status. Logs separates permitted user, system and AI events.
Review any export before sharing it; never send secrets or customer content to support.

## Transcription and data

Settings → Transcription controls optional transcription and its engine/language.
Settings → Data owns retention thresholds. Transcription readiness, queued work
and finished results are different states; see the [Beta guide](../../SPEECH_TO_TEXT_BETA.md).

## License

Uploads and validates license state. License problems should not stop the sniffer from capturing.

## Security And Users

Controls users, roles and password behavior. Only login passwords should be browser-saveable; generated user passwords should require change on first login when offered.
