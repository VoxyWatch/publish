# AI Context Changelog

This file tracks the AI-facing troubleshooting context and docs pack contract.

## v1 — VoxyWatch 2.156.0

- Introduced `voxywatch-ai-troubleshooting/v1`.
- The context includes public documentation links, runbook links and the `voxywatch-support-bundle/v1` allowlist payload.
- Excludes secrets, credentials, settings, logs, raw SIP, audio, CDR samples, IPs, trunks, Call-IDs and PII.

## v1.1 — VoxyWatch 2.157.0

- Added `voxywatch-ai-docs-pack/v1`, an authenticated JSON download containing the fixed allowlist of public AI Markdown files.
- Added an explicit public-docs URL copy action in Settings -> Diagnostics.
- Added release/invariant checks so the AI pack stays present in source, build/install and public publish sync.
