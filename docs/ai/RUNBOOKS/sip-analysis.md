# Runbook: SIP Analysis

## Symptoms

- A call failed or behaved unexpectedly.
- SIP Expert reports malformed signaling.
- RFC checks flag missing headers, bad dialog behavior, content-length issues or authentication problems.
- STIR/SHAKEN identity is present or missing.
- SIP Expert classifies a known deterministic scenario without calling an LLM.

## First Checks

- SIP Expert verdict.
- Call type: INVITE dialog, REGISTER, OPTIONS, REFER, MESSAGE, SUBSCRIBE/NOTIFY or in-dialog update.
- RFC findings severity.
- Deterministic scenario tags: cancellation, authentication challenge/success/failure, redirect, media negotiation failure, 503 overload, session timer, glare, early media, Q.850 reason, identity/privacy, forwarding history, transfer/join, DTMF, no-response, NAT/private Contact, private SDP media, SRTP/security policy, codec mismatch, T.38/fax, hold/inactive media, forking, retransmissions and routing loops.
- Transaction timeline: transaction count, dialogs, retransmissions, final response per transaction and whether delayed-offer/early-media/forking behavior was observed.
- Confidence and evidence: use deterministic confidence plus message/header/SDP evidence before escalating to carrier, SBC or endpoint teams.
- SDP/media findings.
- Response codes and transaction flow.

## Likely Domains

- `integration-source`: SBC, carrier or endpoint generated invalid or incomplete SIP.
- `external-provider`: upstream carrier/network response.
- `product-code`: parser or analyzer incorrectly classifies valid SIP.
- `routing-policy`: redirects, loops, too many hops, numbering and forwarding behavior.
- `media-policy`: SDP, early media, SRTP/RTP profile, codec or DTMF interop.
- `identity-policy`: P-Asserted-Identity, Privacy and STIR/SHAKEN behavior.

## Validation

The conclusion should separate signaling corruption, normal user behavior, policy rejection, authentication, media negotiation, routing/numbering, identity/privacy, transfer features and provider-side failure.

SIP Expert is expected to be useful without an LLM. The LLM may explain or correlate the result, but deterministic findings and scenario tags are the evidence source.

When a scenario is informational, do not treat it as root cause by itself. Example: private Contact/SDP can be normal inside a LAN capture; it becomes actionable when paired with no response, media failure, one-way audio or NAT traversal symptoms.
