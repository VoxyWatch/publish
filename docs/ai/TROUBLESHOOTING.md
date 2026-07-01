# Troubleshooting Workflow

## 1. Confirm Scope

Identify:

- Symptom and first observed time.
- Affected module: capture, portal, database, rollups, incidents, SIP flow, audio, SNMP, updates, license/auth or settings.
- Impact: visibility only, degraded analysis, data loss risk, service down or security risk.
- Fault domain.

## 2. Gather Safe Evidence

Prefer:

- AI context JSON from Settings -> Diagnostics.
- Support bundle from Settings -> Diagnostics.
- Operational health snapshot.
- Exact VoxyWatch version and latest published version.

Avoid:

- Raw SIP payloads unless explicitly needed and sanitized.
- Audio.
- Full logs with IPs, phone numbers, Call-IDs or tokens.
- Settings files with credentials.

## 3. Decide Ownership

Use this rule:

- If VoxyWatch says capture is healthy but calls/audio are missing, inspect the integration source behavior.
- If VoxyWatch cannot ingest, write or serve data, inspect deployment and product evidence.
- If a signed update cannot run, inspect packaging-release and deployment permissions.
- If the portal is slow under high volume, inspect data-capacity and product query paths.

## 4. Validate

A valid fix has:

- Reproduction or measurable symptom.
- Code/config change or explicit non-bug conclusion.
- Test or read-only validation.
- Updated documentation or guardrail if the process failed.
- Release version if code changed.

## 5. Close

Close a product/development ticket only after the fix is tested, signed, published and documented with evidence. Customer opt-in installation is a separate operational step.
