# Multi-leg call and trunk attribution

VoxyWatch keeps one logical call for investigation while accounting for every
observed signaling leg independently. This is required when a B2BUA preserves
the same SIP Call-ID on its ingress and egress sides.

## How it works

- A session remains one call and one item in Calls/Investigate.
- Each initial INVITE endpoint pair has its own direction, dialed number,
  response codes, outcome, message count and trunk attribution.
- Ownership comes from IP Directory (`IP:port`; omitted port means 5060).
- A session with both inbound and outbound legs is shown as `Transit`.
- CDR Base and CSV expose the ingress and egress trunks independently.
- Trunk health and hourly metrics count the applicable leg, while global call
  totals continue to count the logical session once.

Investigate renders a compact route above the unified chronological SIP
sequence and labels every message by leg. Operators get the complete call story
without losing the ability to identify which carrier side failed.

## Catalog integrity

Two trunks cannot share the same canonical endpoint, SIP port and dial prefix,
even if their direction or priority differs. IP Directory also treats
`192.0.2.10` and `192.0.2.10:5060` as the same endpoint.

Create, edit and every import path fail closed before persistence. Existing
conflicts remain readable but generate a critical notification, repair banner
and highlighted rows. VoxyWatch never selects one of those trunks arbitrarily.

## Historical enrichment

A bounded background task enriches retained calls from the last seven days at
10 calls per minute and recalculates completed hourly trunk buckets. It is
additive, resumable and does not delay capture or API requests.
