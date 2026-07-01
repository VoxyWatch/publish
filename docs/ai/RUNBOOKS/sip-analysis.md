# Runbook: SIP Analysis

## Symptoms

- A call failed or behaved unexpectedly.
- SIP Expert reports malformed signaling.
- RFC checks flag missing headers, bad dialog behavior, content-length issues or authentication problems.
- STIR/SHAKEN identity is present or missing.

## First Checks

- SIP Expert verdict.
- Call type: INVITE dialog, REGISTER, OPTIONS, REFER, MESSAGE, SUBSCRIBE/NOTIFY or in-dialog update.
- RFC findings severity.
- SDP/media findings.
- Response codes and transaction flow.

## Likely Domains

- `integration-source`: SBC, carrier or endpoint generated invalid or incomplete SIP.
- `external-provider`: upstream carrier/network response.
- `product-code`: parser or analyzer incorrectly classifies valid SIP.

## Validation

The conclusion should separate signaling corruption, policy rejection, authentication, media negotiation and provider-side failure.
