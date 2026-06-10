# Changelog

All notable changes to VoxyWatch are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [2.49.0] — Unreleased (upcoming; not yet in `latest.json`)

### Added
- **PCI-DSS pause/resume recording** — suppress call audio during the card/CVV window so it is never stored (PCI-DSS Req. 3.2). **Programmable on/off** via `pci.enabled` (OFF by default) and per-call through the API: `POST /api/v1/recording/suppress {call_id, action: "pause"|"resume"}` (scope `recording:control`). **Defense in depth across 3 layers, matched by SSRC:** the **Probe** drops the RTP at the source (the sensitive audio never leaves the secure environment), the **sniffer** never persists it (any HEP source), and the **portal** wipes anything that slips through. **Auto-trigger** for trunks/DIDs dedicated to payments (`pci.sensitive_trunks`/`sensitive_dids`); SIP/CDR metadata preserved; full audit log for attestation. With `pci.enabled=false` behavior is identical to before. (Also in this train: v2.46.x bug fixes K/5/C/D, v2.47.0 incremental purge.)

## [2.31.0] — 2026-06-07

### Added
- **Server/infra alerts in the header notification bell** — CPU high, RAM high, capture loss and "HEP source gone silent" now surface in the bell, alongside the existing disk and sniffer notifications. Backed by a new `GET /api/server-alerts` endpoint that shares the exact same thresholds (`snmp_thr_*`) and data source as the embedded SNMP agent, so the bell and the SNMP traps always agree. Bilingual, auto-clearing when the condition resolves.

## [2.30.1] — 2026-06-07

### Fixed
- **Installer version accuracy** — the binary now answers `voxywatch-portal --version` (prints the baked-in version and exits before loading anything). `install.sh` records the version from the **installed binary itself** instead of the CDN-cached manifest string, so the recorded version always matches what is actually running.

## [2.30.0] — 2026-06-07

### Added
- **NOC AI Copilot** — bring-your-own-key LLM analysis (OpenAI / Anthropic / Google Gemini / OpenRouter). A **per-trunk copilot** reads current KPIs, active alarms, the learned baseline, the 48-hour trend and top SIP codes/destinations and returns probable cause → recommended NOC actions → short-term risk. A **NOC summary copilot** prioritizes and groups all alarming trunks. Guardrailed (observe-only, never touches the SBC), cached to control token spend, bilingual. Off until enabled in Settings → AI Chat.

## [2.29.1] — 2026-06-07

### Fixed
- **Zero transient 401s on startup** — a global auth gate now holds protected API requests until the session is ready (covering even parse-time fetches), and `/api/auth/me` returns a clean state instead of a 401 when there is no session. Verified headless: no 401 noise on login or reload.

## [2.29.0] — 2026-06-07

### Added
- **Automatic per-trunk baselines** — each trunk learns its own normal (mean ± σ per hour, per metric) from its history and is flagged when a metric deviates beyond *N*·σ, catching gradual degradations a static threshold would miss (e.g. an ASR that normally sits at 90% drifting to 70%). Won't judge a metric until it has enough history. Configurable sensitivity; the learned "normal" is drawn over the drill-down charts.

## [2.28.1] — 2026-06-07

### Fixed
- **Integration API contract** — unknown `/api/*` and `/api/v1/*` routes now return JSON / `problem+json` instead of HTML, with `405 + Allow` for wrong methods; out-of-contract query parameters (`limit`, `status`, `channel`) return `400` instead of being silently ignored.
- **API keys** — `DELETE /api/apikeys/{id}` reports `revoked:true` and the list hides revoked keys by default.
- **Diagnostics** — exposes cumulative kernel UDP `RcvbufErrors` (total + delta since start), not just the current interval.
- **AI Chat** readiness — the widget no longer lets you send without a configured provider key.

## [2.28.0] — 2026-06-07

### Added
- **Carrier & Country columns** in the CDR base (sortable; with direction and ONNET tagging).
- **Non-blocking startup** — after a restart the UI, CDRs, traces and configuration are usable immediately; live KPIs and per-trunk health fill in as history loads in the background. Capture is never interrupted.

> Trunk catalog, call→carrier attribution, E.164 country resolution, per-carrier/country dashboards, the per-trunk health engine, the Monitoring tab and per-trunk drill-down charts were introduced across the 2.23–2.27 line leading up to this release.

## [1.2.17] — 2026-05-27

### Fixed
- **Sniffer service name auto-detection** — `server.js` hardcoded `voxywatch-sniffer.service` everywhere; the service is now detected at startup by probing `voxywatch-sniffer.service` first (production package installs) and falling back to `hep-sniffer.service` (source/dev installs); all status, restart, and diagnostics calls use the detected name
- **Sniffer restart fallback** — `POST /api/sniffer/restart` now tries `busctl` D-Bus first (required when `NoNewPrivileges=true`); if `busctl` fails due to a missing polkit rule, it automatically falls back to `sudo systemctl restart`, so the button works on both production and development environments

---

## [1.2.16] — 2026-05-27

### Added
- Support and contact email links in the Settings footer (visible from any settings tab):
  - `support@voxywatch.com` — technical support tickets
  - `contact@voxywatch.com` — commercial inquiries and licensing

---

## [1.2.15] — 2026-05-27

### Security
- **VULN-001** Stored XSS via `portal_title` — HTML special characters (`<>"'\``) are now stripped at save time; `escHtml()` applied at render time in the `<title>` tag
- **VULN-002** Mass-assignment bypass for `auth_enabled` — toggling this field via `POST /api/settings` now requires the admin's current password in `_confirm_password`
- **VULN-003** Auto-update without integrity verification — the tarball SHA-256 from the manifest is verified with `sha256sum` before extraction; updates without a valid 64-character hex hash are aborted
- **VULN-004** Router path traversal (`../` segments) — `path.posix.normalize()` middleware applied to every incoming URL before route matching
- **VULN-005** No rate limiting on login — in-memory rate limiter: max 10 failed attempts per IP per 15-minute window; counter resets on successful login; returns HTTP 429 with a wait hint
- **VULN-006** Sensitive data on unauthenticated endpoints — `/api/health` now returns only `{ok, license.valid, ts}`; `customer` field in `/api/license/status` is only included for authenticated callers
- **VULN-007** Excessive JWT session duration — `session_duration_hours` maximum capped at 168 h (7 days), down from 720 h (30 days)
- **VULN-008** `X-Powered-By: Express` header removed via `app.disable('x-powered-by')`

### Added
- `voxywatch.com/pricing` links throughout all license-related UI surfaces:
  - Blocked page — each error case (expired, HWID mismatch, invalid signature, no license)
  - Free Tier usage banner
  - Free Tier limit-reached overlay
  - Settings → License tab (load license section)
  - Settings → License tab (invalid license status card)

---

## [1.2.14] — 2026-05-27

### Fixed
- **Sniffer restart** — `POST /api/sniffer/restart` was returning HTTP 500 with *"sudo: The 'no new privileges' flag is set"*; replaced `sudo systemctl` with a `busctl` D-Bus call (`org.freedesktop.systemd1.Manager.RestartUnit`); polkit rule added in `postinst.sh` granting the `voxywatch` user permission to restart `voxywatch-sniffer.service`
- **PCAP / audio download** — files were downloaded as JSON because browser `<a download>` requests bypass the patched `fetch()` and send no `Authorization` header; replaced with a programmatic `_authDownload()` function using the patched `fetch()` so the JWT is always included
- **Call classification** — calls with a 200 OK but no BYE were incorrectly classified as "Completed"; they now appear as "Active" (`call_result = 'active'`); ASR/NER statistics still count active calls as answered
- **Calls list scroll reset** — the call list no longer appended a truncation message and scrolled down when changing filters; the list now scrolls to the top on every filter change
- **Diagnostics i18n** — the license status label "Válida" was always rendered in Spanish regardless of the selected UI language
- **systemd service documentation links** — `Documentation=` URL in both service files corrected to the GitHub repository

### Added
- `--reset-admin` CLI flag: stops the portal, resets all admin accounts to the default password (`voxywatch`), sets `force_change: true` so a new password is required on next login, then exits; no data is modified
- `GET /api/calls/active` — returns calls with `call_result = 'active'`; registered before `GET /api/calls/:id` to prevent the literal string `"active"` from being interpreted as a call ID
- `POST /api/auth/logout` — returns `{ok: true}` for stateless JWT clients; token invalidation is handled client-side
- polkit rule deployed by `postinst.sh` at `/etc/polkit-1/rules.d/50-voxywatch.rules`

### Changed
- `call_result` now uses six distinct values: `answered`, `active`, `busy`, `cancelled`, `failed`, `no-answer`
- Completed ES / EN translation keys for: CDR filter labels, pagination strings, sniffer status badges, default-password warning banner

---

## [1.2.8] — 2026-05-27

### Added
- **SQLite WAL backend** — `hep_capture.db` replaces the JSONL flat file; ~47 % storage reduction; concurrent-read safe; indices on `call_id`, `ts_sec`, `protocol_id`, `sender_ip`
- **Incremental parse** — `parseIncrementalCapture()` ingests only new rows (`id > _lastParsedMaxId`) without reloading the full database; full-parse is triggered only after purge events
- **Granular data wipe** — separate controls to delete audio files, SIP traces, or CDR records independently; CDR snapshot preserved on wipe
- **AI assistant** — built-in chat proxy supporting OpenAI, Anthropic Claude, Google Gemini, and OpenRouter; rate-limited to prevent API key abuse

### Security (43 issues resolved across two audit cycles)
- Command injection in PCAP export, audio serve, purge, and timezone handlers → `execFile()` / `execFileSync()` with separate argument arrays
- Path traversal in audio serving → `safeAudioPath()` validates that the resolved path is inside `__dirname` and has a `.wav` / `.g722` extension
- Race condition between parse and purge → `isParsing` lock prevents concurrent execution
- API key and admin password masked in `GET /api/settings` responses (`••••••••`)
- `express.static` blocked for `.jsonl`, `.json`, `.key` file extensions
- JWT `alg:none` attack rejected
- XSS: license banner fields escaped with `escHtml()`
- Security headers added: `Content-Security-Policy`, `X-Frame-Options: SAMEORIGIN`, `Referrer-Policy`, `X-XSS-Protection`, `Permissions-Policy`
- CSRF middleware: `Origin` / `Referer` validated against `Host` for all mutating methods
- TCP receive buffer capped at 10 MB per connection in the sniffer
- `/api/ai/chat` rate-limited (prevents runaway API costs)

---

## [1.2.7] — 2026-05-27

### Added
- **SSO / OIDC** — single sign-on via Google, Microsoft Entra ID, Okta, Keycloak, Auth0, and any standards-compliant provider; configurable from Settings → Security; optional auto-provisioning of new users with a default role; domain restriction filter
- **CDR base** — searchable, sortable, paginated call-detail records with caller/callee label resolution, duration, codec, MOS, and CSV export
- **Dashboard KPIs** — live ASR, NER, ACD, MOS, PDD cards with per-source and per-codec breakdown; 10-second cache to minimize recalculation

---

## [1.2.0] — 2026-05-26

### Initial public release

- HEP v1 / v2 / v3 capture sniffer (`hep_sniffer.py`) — UDP + TCP, ports 9060 / 9910 / 9911
- SIP flow viewer — full ladder diagram per call with SDP analysis and codec detection
- SIPREC stereo audio reconstruction (G.711 µ-law / G.722) with in-browser playback
- Per-call PCAP export (`generate_pcap.py`)
- Hardware-bound RSA license system (offline validation, no cloud call-home)
- JWT authentication with RBAC roles: `admin`, `operator`, `viewer`
- IP label directory — map IPs and CIDR prefixes to friendly names; CSV / JSON import/export
- Source tracking — groups HEP senders by source IP, shows active sources and packet counts
- Settings: disk auto-purge, HEP port configuration, HTTPS / TLS certificate upload, timezone, NTP, DNS
- Diagnostics page — system info, service status, license state, OS/Node/Python versions
- Dark theme UI; English and Spanish language support
- Compatible sources at launch: Asterisk, Kamailio, OpenSIPS, FreeSWITCH, RTPEngine, CaptAgent, HEPlify, Avaya SM, Oracle ACME, AudioCodes, Ribbon/Sonus, Cisco CUBE, custom SBCs
