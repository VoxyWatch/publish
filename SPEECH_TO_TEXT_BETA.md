# Speech to text — Beta

Speech to text is an opt-in Beta feature that creates searchable transcripts from call audio already captured by VoxyWatch. It never runs in the SIP/RTP capture path and is disabled by default.

## Current production scope

- Manual, per-call generation from **Calls**.
- Caller and callee are transcribed independently and merged by timestamp.
- Local processing with the release-pinned `whisper.cpp` engine and managed multilingual `base` model.
- Optional OpenAI processing using the customer's configured OpenAI credential.
- TXT, JSON and SRT downloads.
- Clickable timestamp segments synchronized with the reconstructed-audio player.
- Search inside one transcript or across the bounded local transcript store.
- Explicit deletion and a six-hour retention sweep, independent of new jobs.
- Detected language, channel-mapping provenance and warnings for one-way audio, high RTP loss or recording suppression.
- Operator/admin access only; transcripts are stored locally with mode `0600`.
- Configurable language, call-duration limit, queue limits and retention.

Automatic/background transcription is intentionally locked during Beta. This prevents unattended access to conversation content until each customer validates capacity, consent, privacy and retention requirements.

## Privacy and operational boundaries

Local mode does not send audio outside the VoxyWatch server. OpenAI mode sends only the selected call audio and must be explicitly configured. Transcript content, audio, phone numbers and Call-IDs are never written to telemetry, Sentry, support bundles or operational logs.

Speech-to-text jobs use a dedicated bounded queue and cannot execute inside the sniffer. Local workers run with an enforceable 1 GB address-space ceiling and timeout; concurrency is reduced automatically when host RAM cannot safely sustain multiple jobs. PCI/recording suppression and normal audio retention remain authoritative: missing or suppressed audio cannot be reconstructed by transcription.

**Ask AI** is an explicit disclosure boundary: the transcript is attached to that single request as untrusted evidence and is not part of normal chat, telemetry or background context. Long transcripts are passed as structured timestamped segments rather than copied into the prompt field; exceptionally long calls are reduced in stages and report omitted segments when the configured context budget is reached.

The Integration API exposes separate `transcript:read` and `transcript:generate` scopes. MCP exposes stored transcripts only through `get_call_transcript`, which requires both `mcp:sensitive` and the administrator's sensitive-data switch. Neither channel enables automatic transcription.

## Enable and use

1. Open **Settings → Diagnostics → Speech to text**.
2. Review the Beta notice and select Local or OpenAI processing.
3. Enable the feature and save.
4. Open a call and expand **Speech to text**.
5. Select **Generate transcript**. VoxyWatch reconstructs authorized audio if necessary, then transcribes it.
6. Use **Verify local engine** in Diagnostics to re-check the installed binary, manifest and model hashes.

Before broad use, validate representative authorized calls for language, codec, packet loss, one-way audio, hardware load and legal/compliance requirements.

## Managed dependency

The release contains `whisper.cpp` 1.9.1 and the multilingual `ggml-base` model with pinned SHA-256 hashes. The installer preserves valid managed artifacts and automatically repairs a missing or corrupt executable, manifest or model from the signed release. A version change still requires the controlled `--refresh-external-dependencies` maintenance path.

OpenAI uploads are bounded per request. Large WAV files are split locally into ten-minute PCM chunks, transcribed serially and merged by timestamp; temporary chunks are removed after success, cancellation or failure.

## Beta exit evidence

Do not remove the Beta label until an authorized representative corpus covers English and Spanish, supported codecs, noisy and lossy media, one-way calls and multi-leg/B2BUA direction. Record accuracy review, real-time factor, peak CPU/RAM, queue saturation, cancellation/failure rate and confirmation that capture drops/RTP shedding remain unchanged. Automatic processing stays unavailable until consent, retention, capacity and trunk-selection behavior pass that review.
