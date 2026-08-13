# AI Context Changelog

## v3.63.0

- Added the selection-aware `voxywatch-ai-context-pack/v1` with exact UI time range, rollup totals, coverage and representative calls.
- Selected reports are revalidated and recalculated; selected calls include dynamic CDR, legs, SIP/RTP evidence, trends and related calls.
- Added exact-window filters to `search_calls` and the `get_call_context` dossier tool.
- Provider-bound data uses loop-stable opaque call references and structured sample reduction instead of invalid JSON truncation.

This file tracks the AI-facing troubleshooting context and docs pack contract.

## v1 — VoxyWatch 2.156.0

- Introduced `voxywatch-ai-troubleshooting/v1`.
- The context includes public documentation links, runbook links and the `voxywatch-support-bundle/v1` allowlist payload.
- Excludes secrets, credentials, settings, logs, raw SIP, audio, CDR samples, IPs, trunks, Call-IDs and PII.

## v1.1 — VoxyWatch 2.157.0

- Added `voxywatch-ai-docs-pack/v1`, an authenticated JSON download containing the fixed allowlist of public AI Markdown files.
- Added an explicit public-docs URL copy action in Settings -> Diagnostics.
- Added release/invariant checks so the AI pack stays present in source, build/install and public publish sync.
