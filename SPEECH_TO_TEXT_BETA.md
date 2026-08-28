# Speech to text — Beta

Speech to text is an opt-in Beta feature that creates searchable transcripts from call audio already captured by VoxyWatch. It never runs in the SIP/RTP capture path and is disabled by default.

## Current production scope

- Explicit processing policy: **Off** by default, **On demand**, **All new calls with recoverable audio**, or **Only selected trunks**.
- Manual, per-call generation from **Calls** remains available in On demand and automatic modes.
- Caller and callee are transcribed independently and merged by timestamp.
- Local processing with the release-pinned `whisper.cpp` engine and managed multilingual `base` model.
- Optional OpenAI processing with a dedicated STT credential and `whisper-1`, `gpt-4o-mini-transcribe` or `gpt-4o-transcribe`.
- TXT, JSON and SRT downloads.
- Clickable timestamp segments synchronized with the reconstructed-audio player.
- Search inside one transcript or across the bounded local transcript store.
- Explicit deletion plus the shared oldest-first disk-pressure policy owned only by **Settings → Data**; there is no parallel age sweep.
- Detected language, channel-mapping provenance and warnings for one-way audio, high RTP loss or recording suppression.
- An administrator-only readiness panel verifies the pinned engine/model with a real bounded runtime probe, FFmpeg, transcript filesystem and queue separately. It also reports aggregate Beta corpus coverage and downloads a content-free evidence JSON.
- Operator/admin access only; transcripts are stored locally with mode `0600`.
- Automatic multilingual detection or one explicit language; workload limits remain conservative internal Beta guards.
- Persistent asynchronous jobs: the portal may be reloaded while processing, and a restart marks unfinished work explicitly as interrupted.
- A local metadata index for paginated discovery by call-time range, exact source, exact destination or Call-ID. The private file catalog remains the durable fallback and `include=full` returns at most 25 complete transcripts per page.
- Asynchronous JSONL/CSV range exports with a dedicated `transcript:export` scope, 31-day/10,000-record bounds, 24-hour result expiry and content-free local audit.
- Legacy mounted-storage migration is retained only for compatibility and rollback; it is not a second portal storage or retention policy.

Automatic processing is a controlled Beta opt-in. Selecting an automatic mode starts at the current completion point and processes only new completed calls; it never backfills historical calls. **Only selected trunks** uses the trunk records selected in Settings, so renamed trunks remain correctly scoped. Calls without recoverable audio are safely skipped.

## Privacy and operational boundaries

Local mode uses the single release-managed model, needs no key and does not send audio outside the server. OpenAI mode sends only selected audio and uses the isolated `openai_stt` credential from secure store, `VOXYWATCH_STT_OPENAI_API_KEY` (`OPENAI_STT_API_KEY` alias), or Linux credential `voxywatch-stt-openai.key`; the browser never receives the secret. The Settings control is visually masked but deliberately does not use browser password-field semantics, so a password manager cannot mistake the API key for a portal login; the login remains the only browser-saveable password. Expert interpretation is separate: it sends bounded transcript text through the global LLM connection, preserves the original and never uses the STT key. Transcript content, audio, phone numbers and Call-IDs are never written to telemetry, Sentry, operational diagnostics or logs.

Speech-to-text jobs use a dedicated bounded queue and cannot execute inside the sniffer. Automatic jobs run below manually requested jobs, in small bounded batches, and preserve their progress across a portal restart without storing conversation content in their operational state. Local workers use enforced resource limits and adapt concurrency to the host. PCI/recording suppression and normal audio retention remain authoritative: missing or suppressed audio cannot be reconstructed by transcription.

**Ask AI** is an explicit disclosure boundary: the transcript is attached to that single request as untrusted evidence and is not part of normal chat, telemetry or background context. Long transcripts are passed as structured timestamped segments rather than copied into the prompt field; exceptionally long calls are reduced in stages and report omitted segments when the internal safety limit is reached.

The Integration API exposes separate `transcript:read`, `transcript:generate` and `transcript:export` scopes. Generation and bulk export return `202 Accepted` plus persistent job URLs. Export requests require `from`/`to`, may span at most 31 days, return at most 10,000 records and expire after 24 hours. Audit records action, outcome, counts and filter field names, never filter values or transcript content. MCP exposes stored transcripts only through `get_call_transcript`, which requires both `mcp:sensitive` and the administrator's sensitive-data switch. Neither channel enables automatic transcription.

## Enable and use

1. Open **Settings → Operation → Transcription**.
2. Review the Beta notice and select Local or OpenAI processing.
3. Choose **On demand**, **All new calls with recoverable audio**, or **Only selected trunks**, then enable the feature and save. Automatic choices never process older calls.
4. For selected-trunk mode, choose one or more trunks from the list.
5. For a manual transcript, open **Calls**, select a call, expand **Speech to text** and select **Generate transcript**. VoxyWatch reconstructs authorized audio if necessary, then transcribes it.
6. Use **Run readiness check** in Transcription to verify the real engine/model runtime, credential when applicable, FFmpeg, storage, queue, recent media coverage and completed output.
7. Use **Download safe evidence** to retain an aggregate validation snapshot. It never contains transcript text, Call-IDs, phone numbers, IP addresses or per-job identifiers.

Before broad use, validate representative authorized calls for language, codec, packet loss, one-way audio, hardware load and legal/compliance requirements.

## Managed dependency

The release contains `whisper.cpp` 1.9.1 and the multilingual `ggml-base` model with pinned SHA-256 hashes. The installer preserves valid managed artifacts and automatically repairs a missing or corrupt executable, manifest or model from the signed release. A version change still requires the controlled `--refresh-external-dependencies` maintenance path.

OpenAI uploads are bounded per request. Large WAV files are split locally into ten-minute PCM chunks, transcribed serially and merged by timestamp; temporary chunks are removed after success, cancellation or failure.

## Beta exit evidence

Do not remove the Beta label until an authorized representative corpus covers English and Spanish, supported codecs, noisy and lossy media, one-way calls and multi-leg/B2BUA direction. Readiness measures engine, selected model, credential/connection when applicable, storage, queue, language/warning coverage, processing rate and failures. Accuracy, codec diversity, peak CPU/RAM and capture impact still require an authorized corpus. `Enabled`, `Configured`, `Verified` and `Processing` are distinct states; every visible feature requires an operational real-path test, not only a settings or DOM assertion.

Audio reconstruction now distinguishes missing/expired RTP (`no_audio`) from captured payload that cannot be decoded (`audio_unconvertible`). Missing FFmpeg or helper/database failures remain product-health failures rather than being mislabeled as a call without audio.

## Three-phase roadmap

1. **Scalable foundation (implemented):** persistent asynchronous jobs, private atomic catalog and bounded API listing by call-time range, exact source, exact destination or Call-ID.
2. **Governance and capacity (implemented):** reconstructible metadata index, asynchronous bounded bulk exports, dedicated export scope/content-free audit, transcript disk budget and oldest-first safe retention enforcement.
3. **Storage and controlled automation (implemented):** transcript migration to a mounted partition/external disk has verification and rollback. Automatic Beta modes are explicit, no-backfill, restart-safe, lower priority than manual work and selectable by stable trunk identity. Audio relocation remains pending until all legacy audio files share one canonical boundary.
