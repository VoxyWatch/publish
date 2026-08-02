# VoxyWatch AI Context Engine

VoxyWatch uses a deterministic-first context pipeline for its optional LLM features. The model is the explanation and correlation layer, not the source of operational truth.

## Context order

1. Stable product identity, installed version, safety rules and read-only boundary.
2. Minimal administrator-confirmed organization profile: name and organization type.
3. Current user's portal role, interface language and optional personal AI instructions; personal identity stays local.
4. Server-side chat history, bounded by the configured context budget.
5. Current deterministic snapshot and fresh results from read-only tools.
6. Locally selected VoxyWatch documentation and RFC references relevant to the question.
7. Related historical findings, clearly marked as leads rather than current facts.

Stable instructions are kept before dynamic evidence to improve provider prompt-cache reuse. VoxyWatch never sends email addresses or infers the organization from an email domain. Raw SIP, audio, telephone numbers, customer IP addresses, Call-IDs, credentials and server paths remain excluded.

## Knowledge selection

The built-in catalog routes questions to public product documentation and applicable RFC families, including SIP, RTP/RTCP, SDP, offer/answer, STIR/PASSporT, RTCP XR, DTMF and SIPREC. References are selected just in time; the entire repository or RFC corpus is never placed in every prompt. A URL identifies an authoritative source but is not represented as fetched content unless a tool actually retrieves it.

## Finding ledger

Incident investigations can persist a bounded local `voxywatch_ai_findings.json` ledger. Each entry contains a reproducible evidence hash, scope, hypothesis, confidence, evidence IDs, prompt/model version, recurrence count and review state. It contains no raw evidence or customer identifiers.

Allowed review states are `unverified`, `confirmed`, `refuted` and `resolved`. Historical findings are advisory. Fresh deterministic evidence always wins. Promotion follows:

`detector evidence -> LLM hypothesis -> human feedback -> replay -> shadow candidate -> deterministic rule`

No LLM hypothesis automatically becomes an alarm or changes customer infrastructure.

## API

- `GET /api/ai/findings` lists the local ledger for operator and administrator roles.
- `POST /api/ai/findings/{id}/feedback` lets an administrator classify a finding and record a bounded outcome.
