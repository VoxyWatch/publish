# Changelog

All notable changes to VoxyWatch are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
