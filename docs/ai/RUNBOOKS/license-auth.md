# Runbook: License And Auth

## Symptoms

- License appears invalid or expired.
- User cannot log in.
- Browser asks to save non-login secrets.
- API key or token field behaves like a password field.

## First Checks

- License status in Settings -> License and Diagnostics.
- User role and password-change requirement.
- API key creation flow.
- Browser autocomplete behavior for non-login secrets.

## Likely Domains

- `configuration`: expired or missing license, role issue, user setting.
- `product-code`: UI input attributes or auth flow bug.
- `security`: credential exposure risk.

## Validation

Only login password fields should be saveable by browsers. API tokens, SNMP secrets, provider tokens and generated user passwords must avoid browser password-manager capture.
