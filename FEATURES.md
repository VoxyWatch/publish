# VoxyWatch — Feature Catalog (website, sales and tutorial source material)

> Source of truth for the website, datasheets, sales decks and tutorial planning. Updated for **v3.18.0** (2026-07-28).
> Everything below is shipped and validated with automated regression gates, the public demo and historical high-volume telco evidence.

---

## 🎯 Positioning

**Primary (EN):** *The agentic NOC for your voice network.*
**Primary (ES):** *El NOC agéntico para tu red de voz.*

**Subhead (EN):** It doesn't just capture your calls. It watches them, investigates anomalies on its own, tells you the root cause — and learns from every incident.
**Subhead (ES):** No solo captura tus llamadas. Las vigila, investiga las anomalías por sí solo, te dice la causa raíz — y aprende de cada incidente.

**Outcome message (EN):** *From a failed call to carrier-ready evidence in under five minutes.*
**Outcome message (ES):** *De una llamada fallida a evidencia lista para el carrier en menos de cinco minutos.*

**One-liner alternates:**
- "From packets to verdicts." / "De paquetes a veredictos."
- "Your virtual NOC engineer — on your hardware, never in the cloud."
- "The SIP capture platform that grew a brain."

**The loop (hero diagram):**
`DETECT → INVESTIGATE → DIAGNOSE → NOTIFY → ACT (human-approved) → LEARN`

**Hard differentiators (vs Homer/VoIPmonitor/etc.):**
1. Autonomous incident investigation with evidence-cited AI diagnosis.
2. Per-trunk statistical baselines + anti-false-positive engine (−92% critical noise, validated on production data) — now with **per-trunk auto-calibration**: each trunk is judged against *its own* learned normal, not a global threshold.
3. Actionable Telegram notifications with human-approved remediation.
4. MCP gateway: local or remote AI clients can inspect live traffic through read-only, scoped,
   redacted and audited tools, with refresh intervals from 5 seconds to 30 minutes.
5. Carrier/country attribution built-in (E.164 engine, 197 country codes).
6. 100% self-hosted, single binary, the AI never touches the SBC.
7. Per-installation deployment status separates published, installed, validated and upgrade-compatible versions without centralizing customer data or secrets.
8. Public AI-assisted configuration guide: customers can load `AI_VOXYWATCH_CONFIGURATION_ASSISTANT.md` into their own AI assistant to collect IPs, trunks, capture sources, thresholds, retention, alerts and users correctly.
9. Anonymous adoption telemetry, tied to the existing Sentry toggle, reports active version/platform/tier by installation without sending customer IPs, trunks, SIP/RTP, CDRs, settings or credentials.
10. Native agentic runtime: v3 ships an ADK-ready sidecar with specialist agents, Diagnostics status/control and a read-only tool contract.
11. Tutorial-ready product map: every main module and Settings section can be explained with a practical NOC scenario, a screen walkthrough and a safe validation test.
12. Verifiable agentic behavior: structured evidence citations, deterministic release evals, confidence gates, shadow mode, short-lived redacted traces and prompt-injection canaries.
13. Verifiable implementation catalog: [Implemented Feature Reference](IMPLEMENTED_FEATURES.md) labels what is active, configurable, opt-in or signal-dependent and lists deliberate exclusions.

---

## 📊 Proof points (real, from production)

| Claim | Number |
|---|---|
| Peak traffic validated | ~200,000 calls/hour |
| Capture loss at peak | 0 packets dropped (kernel drops = 0) |
| False-critical reduction (anti-FP engine) | −92% vs naive thresholds |
| Answered calls with playable audio | ~90% (SBC without RTP correlation IDs; 100% with compliant sources) |
| Calls with BOTH audio directions correlated | ~85% (multi-leg correlation, B2BUA without RTP Call-ID) |
| Portal API latency | < 10 ms typical |
| Boot to usable UI after update | ~8-11 s with full history visible (working-set snapshot) |
| Security hardening | 2 audits + 1 pentest, 50+ fixes; CSP without unsafe-inline; GPG-signed updates |

---

## 🧱 Feature blocks (website sections)

### 1 · Agentic NOC *(flagship — lead with this)*

| Feature | Copy |
|---|---|
| **Incident engine** | Every anomaly becomes a persistent incident with lifecycle (open → ack → resolved), deduplication, auditable timeline and stability-based auto-resolve. No alert storms — one live incident per problem. |
| **Outcome-first Overview** | Five essential KPIs plus a prioritized queue of open incidents and degraded trunks. One click opens the exact incident evidence or affected infrastructure; advanced charts remain customizable. |
| **Guided live demo** | The public demo moves from degraded trunk → open incident → failed calls → carrier-ready evidence in four explicit steps, with one-click access and no misleading pre-auth dashboard. |
| **Autonomous investigator** | The moment an incident opens, VoxyWatch gathers evidence by itself: failing call samples, dominant SIP codes, failing IP paths, affected countries, and the carrier-vs-local tell (did other trunks degrade too?). An AI investigator then writes the root cause **citing that evidence**. |
| **Structured diagnosis** | Probable cause · confidence · scope (carrier / customer / local / capacity) · recommended action. Budgeted & cached LLM usage. Works without an LLM too — raw evidence is always collected. |
| **Actionable Telegram** | Critical incidents hit your phone with the diagnosis and inline buttons: Ack · Resolve · Investigate · approve the proposed fix. Closed action catalog (never the SBC), full audit trail. |
| **Per-user notifications** | One bot per installation; each user links their own Telegram with a one-time code (no tokens, no chat IDs) and/or enables email. Actions audited under the real username and gated by role; per-user severity threshold and digest opt-in. Global SMTP with Gmail/365 presets, in-product step-by-step guide and live test. |
| **Runbooks** | Seven field procedures cover low ASR, packet loss, capture down, one-way audio, Flash Calls, fraud suspects and traffic-volume drops. The investigator cites them step by step; add your own as JSON. |
| **Case memory** | Human resolutions become institutional memory: "same as incident #123 (Jun 3) — carrier maintenance". The system gets smarter with every incident you close. |
| **Anti-false-positives** | CRITICAL must be earned: minimum sample size, **Wilson confidence intervals** on rates (a trunk with 2 calls can't trip a critical), measurement coverage, deviation from the trunk's *own* robust seasonal baseline (median/MAD), sustained degradation (hysteresis). −92% noise, zero lost records. |
| **Auto-calibrated thresholds** | Opt-in: each mature trunk derives its own alarm thresholds from its learned history (median ± k·MAD) — a wholesale trunk that *normally* runs 25% ASR stops false-alarming at 25%, while a retail trunk alarms the moment it dips below *its* 90%. Manual overrides always win. Validated A/B on production: −40% alarms, no real signal lost. |
| **Capacity forecast** | Audio retention measured in hours + write rate; capacity incidents before you run out; daily/weekly digest via Telegram/webhook. |
| **Three-tier alarms** | (1) Manual thresholds — editable SIP failure-rate rules per class/code, global and per trunk, plus SBC-vs-carrier reject attribution. (2) Learned patterns — a 168-bucket seasonal baseline (day-of-week × hour, robust median/MAD) compares your Monday against *your* Mondays: traffic spikes, anomalous silence, ASR/PDD drift against that hour's normal. (3) Honest learning: without enough history the system stays silent instead of guessing. |
| **Fraud early-warning** | The "suddenly calling Cuba" detector: alerts the first day a trunk calls a country absent from its last 4 weeks — critical if it's on the (editable) IRSF high-risk list. Plus short-call storms to one destination (premium-number sweeps, hacked PBX — active from day one), abnormal growth to high-risk destinations, and international-mix spikes vs the trunk's own history. Factory runbook included: who originates, time-of-day tells, block at *your* SBC, dispute with the carrier. A **fraud-risk score (0–100)** fuses the signals via a model trained offline on labelled history (privacy-safe: training off-box, inference on-box, no data leaves your server) and gates which alerts escalate to critical. |
| **Predictive forecast** | A deterministic seasonal forecast uses the robust 168-bucket day/hour baseline plus the recent level to project each trunk's volume/ASR with a bounded confidence band, and turns audio-retention burn-rate into capacity incidents *before* you run out of disk. |
| **Flash Call Intelligence** | Passive, deterministic detection of probable missed-call authentication traffic from originator `CANCEL` timing, `487`, no-answer/no-media evidence and destination fan-out. Starts in Shadow, can create sustained recoverable incidents in Alerting, and never blocks or controls the SBC. [Operational guide](FLASH_CALL_DETECTION.md). |
| **MCP gateway** | ChatGPT, Claude, Codex and other MCP clients can query live traffic, health, KPIs, trunks, CDRs, incidents, baselines, forecasts and Flash Call evidence through 12 local/remote read-only tools. API-key/OAuth scopes, redaction, rate limits, bounded results and local audit. [Configuration guide](MCP_SERVER.md). |
| **License CLI** | Root administrators can validate and atomically replace a product license without portal access; the command protects process/log output, restarts only the portal and rolls back on activation failure. [Command guide](LICENSE_CLI.md). |
| **Per-user contextual LLM** | Built-in LLM keeps private conversation sessions per user, lets operators reopen/delete history, applies each user's profile prompt, infers reply language from the latest operator message, receives a sanitized hint of the current UI view/call/incident, and supports OpenAI, Anthropic, Google Gemini, OpenRouter, Perplexity Sonar and custom OpenAI-compatible endpoints. |
| **AI cost and freshness control** | Operators choose manual, 30-second, 1-, 5-, 15- or 30-minute narrative refresh while live KPIs remain immediate. Admin floors, critical bypass, token telemetry, context/output budgets, prompt caching, deterministic model routing and offline-only Batch keep spend visible and controlled. |
| **Agent tools API** | Authenticated read-only tool catalog for built-in chat and future ADK/sidecar runtimes, with rate limits and no SBC/network control. |
| **Verifiable agent decisions** | Every diagnosis can cite stable evidence IDs; unverifiable or low-confidence output stays observe-only. New actions begin in shadow, operator feedback is audited, and release evals block policy/grounding regressions. |

### 2 · Capture & analysis

| Feature | Copy |
|---|---|
| Two ingest paths: HEP **and** SIPREC | **HEP v1/v2/v3** (UDP+TCP) from the softswitches & proxies that speak it natively — **Asterisk, Kamailio, OpenSIPS, FreeSWITCH, RTPEngine** — plus the **HEPlify / CaptAgent** agents (or the bundled NIC probe) to bring in anything that can't. **SIPREC** (RFC 7865/7866) for the tier-1 hardware SBCs that record natively — **Ribbon/Sonus, Oracle/ACME Packet, AudioCodes, Cisco CUBE, Avaya** — straight into VoxyWatch's built-in SRS, no HEP agent needed. Auto-detects quirky senders. |
| Own capture probe | `voxywatch-probe` (Go + libpcap, amd64/arm64): sniffs SIP/RTP/RTCP off the NIC and emits HEP v3 for sources that can't. |
| **Native SIPREC recording** | Built-in **SRS** (Session Recording Server, RFC 7865/7866): any tier-1 SBC — Ribbon, Oracle/ACME, AudioCodes, Cisco CUBE, Avaya — streams its recording **straight into VoxyWatch over SIPREC**, no HEP agent or port mirroring needed. SIP over **UDP or TLS**, media **RTP or SRTP** (SDES). Reconstructs stereo caller/callee audio from `rs-metadata`; the call shows in the CDR like any other. Runs as a **separate service** (if it falls, HEP capture is untouched), **OFF by default**, with an SBC IP allowlist and anti-DoS limits. |
| SIP ladder & dialog analysis | Full request/response ladder, retransmissions, SDP/codec analysis, hold/re-INVITE/NAT detection, dialog-completeness scoring, RFC compliance audit. |
| SIP/RFC compliance panel | Every call flow can be audited against core SIP/RFC rules with a clear verdict, prioritized findings, detected standards, clickable message evidence and Markdown/JSON export for tickets or tutorials. |
| SIP Expert | One-click trace diagnosis that classifies call setup, REGISTER, OPTIONS, REFER, MESSAGE, subscriptions and in-dialog updates; flags malformed signaling, RFC violations and STIR/SHAKEN Identity status; then gives an executive summary with likely root cause, suggested owner and operator-ready recommendations. |
| **Codec-agnostic capture** | Every call is captured and analyzed **regardless of codec**, over **both HEP and SIPREC** — the SIP ladder, CDR, attribution and quality metrics (jitter/loss/PDD) work for any payload type. Audio *reconstruction* to playable WAV covers the common set below; capture itself never drops a call for using an exotic codec. |
| **Asterisk import** | Upload sanitized `chan_sip`, PJSIP and dial-plan files, preview detected trunks/IPs/prefixes and warnings, then merge only after operator review. |
| **Portable call evidence** | Export SIP text, SIP Expert Markdown/JSON, PCAP and a bounded anonymous call-share JSON. RTP-event DTMF is shown when captured; share bundles exclude raw SIP/RTP/audio, exact IPs and full numbers. |
| Quality metrics | MOS (E-model), jitter, loss, PDD, RTCP enrichment. Honest "not enough signal" instead of invented numbers. |
| **One-way audio detection** | Multi-leg media correlation (handles B2BUA SBCs that keep the Call-ID across legs) tags every answered call: two-way / **one-way** (with which side is missing) / not-correlated. Per-trunk one-way % feeds a configurable alarm with a learned baseline — chronic asymmetry (media bypass) never alerts, only the *change* does. Factory runbook: NAT/firewall tells, codec renegotiation, where to fix it. |
| Playable stereo audio | SIPREC reconstruction, caller/callee channels, in-browser player. PCMU/PCMA, G.722, G.729 + AMR/GSM/G.723 via SDP hints. Per-call PCAP export. |
| Carrier & country attribution | Trunk catalog (IPs/CIDRs/prefixes) → every call attributed to carrier, direction and destination country (ITU-T E.164, longest match). |
| Trunk health + baselines | Rule engine (ok/warn/critical/idle) with plain-language reasons + per-trunk learned baselines (mean ± σ). Catches the 90%→70% drop a fixed threshold misses. |
| Dashboard & CDR base | **Window-accurate KPIs** — Attempts, Answered, Active-now, ASR, NER, ACD, MOS, PDD, minutes and concurrency aggregated from continuous rollups for the *exact* range picked (hour / today / yesterday / custom / all), not a live snapshot. ~48-point trend charts (attempts, answered, concurrency, CPS, ASR/NER) + distributions (disconnect causes by SIP family, duration, PDD, codecs, MOS). Sortable/filterable/CSV CDR base at millions of rows (keyset + trigram search). Bilingual EN/ES. Honest MOS: shows "no data" when the source lacks RTCP/RTP rather than inventing one. |

### 3 · Compliance & security

| Feature | Copy |
|---|---|
| PCI-DSS recording pause | Audio suppressed during the card/CVV window (Req. 3.2) — 3 defense layers matched by SSRC (probe → sniffer → portal), DTMF auto-trigger, API control, full audit log. OFF by default. |
| Selective recording | Record audio only for the trunks that matter; stretch audio retention from hours to days on the same disk. SIP/CDR always kept. |
| Hardened | 2 security audits + pentest (50+ fixes). CSP without unsafe-inline, CSRF/Origin checks, JWT + RBAC, OIDC SSO (Google/Microsoft/Okta/Keycloak/Auth0), optional HTTPS. |
| Signed supply chain | Releases GPG-signed; installer/updater verifies signature **and** SHA-256 before touching anything. |
| Self-hosted, period | Your hardware, your data. No cloud dependency. LLM keys are yours (OpenAI/Anthropic/Google/OpenRouter/Perplexity/custom) and optional. |

### 4 · Integration & operations

| Feature | Copy |
|---|---|
| REST API v1 | Read-only versioned API: CDRs, Call Insight Audio/RTP Expert, traces, audio, health, stats, trunk health, **incidents**. Scoped hashed API keys, IP allowlists, rate limits, problem+json, OpenAPI spec. |
| Platform readiness | Settings -> Diagnostics summarizes production health, configuration gaps, update safety, heavy jobs, AI troubleshooting context and hardware fit in one operator view, then turns that state into guided actions with priority, likely fault domain, confidence and next step. |
| Agentic runtime control | Settings -> Diagnostics shows `voxywatch-agentic.service` status, specialist agents and health; admins can enable/start or stop/disable the local sidecar without touching the SBC. |
| Sanitized support bundle | Authenticated, read-only ticket evidence with versions, fault domain, component status, metrics and dependency checks; strict allowlist excludes secrets, PII, audio and raw SIP. |
| SNMP agent | Embedded v2c+v3 agent, 30+ OIDs, edge-triggered traps, downloadable MIB (IANA PEN 65985). |
| Webhooks | Per-trunk and global, transition-fired (no spam), rich JSON with incident_id. |
| Self-managing | Hardware-adaptive limits (RAM/CPU/disk derived), retention auto-purge by disk pressure, non-blocking startup and signed updates. Minimal hosts provision mandatory GnuPG before release download; verification remains fail-closed. |
| Fast local portal | Large JavaScript/CSS assets are preloaded, gzip-compressed and cached by exact release version for quick repeat visits without a CDN. |
| Instant restarts | Persistent working-set snapshot: after any update/restart the full call history is visible in seconds (measured in production: ~40k calls restored at second 11) while the background sync converges. |
| Bilingual | English & Spanish UI, per user. |
| Storage | PostgreSQL + TimescaleDB (hypertables, compression, hourly rollups) — provisioned and isolated by the installer. |

---

## 🎥 Tutorial map

Use this section as the high-level index for YouTube walkthroughs, training videos and onboarding material.

| Tutorial block | What to show | Demo proof |
|---|---|---|
| What VoxyWatch is | Capture → correlate → detect → investigate → notify → learn | Show the loop from a call to an incident. |
| Dashboard | Global KPIs, time ranges, charts, cause/codec/MOS distributions | Change the time range and explain ASR/NER/PDD/MOS. |
| Calls | Search, filters, SIP ladder, audio, SIP text and PCAP | Open answered and rejected demo calls. |
| CDR Base | Structured filters, column customization and CSV export | Filter by trunk/country/result and export CSV. |
| Trunks | IP/CIDR/prefix/DID attribution to carriers/routes | Add a demo trunk and show labels in CDR/Monitoring. |
| Monitoring | Trunk health, reasons, baselines and Copilot diagnosis | Compare a healthy trunk with a degraded one. |
| Fraud | New destination, high-risk countries, profiles and simulator | Show a safe demo fraud event or simulation. |
| Incidents | Lifecycle, evidence, AI diagnosis, ack/resolve and timeline | Open a demo incident and walk through evidence. |
| Operational Health | Capture, portal, database, rollups, incidents and update status inside Settings → Diagnostics, with copyable support evidence | Refresh Diagnostics health after a restart/update and copy the evidence block. |
| Getting Started | Configuration checklist and public AI assistant guide | Walk from pending items to a useful first configuration. |
| Settings | Grouped Start, Operation, Security/Integrations and Support sections: General, Data, Capture, SIPREC, Security, Alerts, Users, IP Labels, License, API, SNMP, AI, Diagnostics with Health, and Update | Show each group with one practical safe test. |
| Troubleshooting | No calls, no audio, no MOS, wrong trunk, noisy alerts, update pending | Use one symptom per video and separate source/config/product causes. |

Suggested tutorial rule: each video should explain the business value in the first minute, show the actual UI, run one safe validation, and end with the next action for the viewer.

## 💬 FAQ seeds

- **Does the AI touch my SBC?** Never. The action catalog is closed at code level and only contains VoxyWatch-internal operations (e.g. restart its own capture service). There is no tool to modify your network.
- **Do I need an LLM key?** No. Detection, evidence collection, incidents, baselines and alerting are fully deterministic. The LLM only writes the narrative diagnosis — bring your own key to enable it.
- **Cloud?** None. Single binary + PostgreSQL on your box. Telemetry is optional and contains no traffic content.
- **What scale?** Validated at ~200k calls/hour on a 32 vCPU box; limits derive from your hardware, not from the code.
- **Free tier?** Fully featured, **50 concurrent calls**, no license needed. The tiers differ **only** in concurrent-call capacity — never in features or CDR/history retention.

---

## 🗒 Notes for the website build

- Lead with the **agentic loop** (animated diagram of DETECT→…→LEARN works well as hero).
- The Telegram screenshot (incident + buttons) is the single most convincing visual — capture one from production.
- Secondary page sections: Capture & Analysis → Compliance (PCI) → Integration (API/SNMP/MCP) → Pricing.
- For tutorials, use a clean demo dataset. Do not show real customer IPs, phone numbers, Call-IDs, tokens, license material, private SIP payloads or private audio.
- Avoid legacy references: storage is **PostgreSQL + TimescaleDB** (never SQLite/JSONL — those were pre-2.x internals).
- Current version channel: see `latest.json`. All claims in this file are shipped as of v3.18.0.
