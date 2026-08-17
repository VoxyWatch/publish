# Speech to text — Beta

Speech to text is an opt-in Beta feature that creates searchable transcripts from call audio already captured by VoxyWatch. It never runs in the SIP/RTP capture path and is disabled by default.

## Current production scope

- Manual, per-call generation from **Calls**.
- Caller and callee are transcribed independently and merged by timestamp.
- Local processing with the release-pinned `whisper.cpp` engine and managed multilingual `base` model.
- Optional OpenAI processing using the customer's configured OpenAI credential.
- TXT, JSON and SRT downloads.
- Operator/admin access only; transcripts are stored locally with mode `0600`.
- Configurable language, call-duration limit, queue limits and retention.

Automatic/background transcription is intentionally locked during Beta. This prevents unattended access to conversation content until each customer validates capacity, consent, privacy and retention requirements.

## Privacy and operational boundaries

Local mode does not send audio outside the VoxyWatch server. OpenAI mode sends only the selected call audio and must be explicitly configured. Transcript content, audio, phone numbers and Call-IDs are never written to telemetry, Sentry, support bundles or operational logs.

Speech-to-text jobs use a dedicated bounded queue and cannot execute inside the sniffer. PCI/recording suppression and normal audio retention remain authoritative: missing or suppressed audio cannot be reconstructed by transcription.

## Enable and use

1. Open **Settings → Diagnostics → Speech to text**.
2. Review the Beta notice and select Local or OpenAI processing.
3. Enable the feature and save.
4. Open a call and expand **Speech to text**.
5. Select **Generate transcript**. VoxyWatch reconstructs authorized audio if necessary, then transcribes it.

Before broad use, validate representative authorized calls for language, codec, packet loss, one-way audio, hardware load and legal/compliance requirements.

## Managed dependency

The release contains `whisper.cpp` 1.9.1 and the multilingual `ggml-base` model with pinned SHA-256 hashes. Normal product updates preserve an installed engine. A dependency refresh requires the controlled `--refresh-external-dependencies` maintenance path.
