# VoxyWatch — Feature Catalog (website source material)

> Source of truth for the website, datasheets and sales decks. Updated for **v2.151.2** (2026-06-28).
> Everything below is shipped and validated in production (live telco deployment, ~200k calls/hour peak, 32 vCPU).

---

## 🎯 Positioning

**Primary (EN):** *The agentic NOC for your voice network.*
**Primary (ES):** *El NOC agéntico para tu red de voz.*

**Subhead (EN):** It doesn't just capture your calls. It watches them, investigates anomalies on its own, tells you the root cause — and learns from every incident.
**Subhead (ES):** No solo captura tus llamadas. Las vigila, investiga las anomalías por sí solo, te dice la causa raíz — y aprende de cada incidente.

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
4. MCP server: your own AI agents can interrogate the platform.
5. Carrier/country attribution built-in (E.164 engine, 197 country codes).
6. 100% self-hosted, single binary, the AI never touches the SBC.
7. Per-installation deployment status separates published, installed, validated and upgrade-compatible versions without centralizing customer data or secrets.
8. Public AI-assisted configuration guide: customers can load `AI_VOXYWATCH_CONFIGURATION_ASSISTANT.md` into their own AI assistant to collect IPs, trunks, capture sources, thresholds, retention, alerts and users correctly.
9. Anonymous adoption telemetry, tied to the existing Sentry toggle, reports active version/platform/tier by installation without sending customer IPs, trunks, SIP/RTP, CDRs, settings or credentials.

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
| **Autonomous investigator** | The moment an incident opens, VoxyWatch gathers evidence by itself: failing call samples, dominant SIP codes, failing IP paths, affected countries, and the carrier-vs-local tell (did other trunks degrade too?). An AI investigator then writes the root cause **citing that evidence**. |
| **Structured diagnosis** | Probable cause · confidence · scope (carrier / customer / local / capacity) · recommended action. Budgeted & cached LLM usage. Works without an LLM too — raw evidence is always collected. |
| **Actionable Telegram** | Critical incidents hit your phone with the diagnosis and inline buttons: Ack · Resolve · Investigate · approve the proposed fix. Closed action catalog (never the SBC), full audit trail. |
| **Per-user notifications** | One bot per installation; each user links their own Telegram with a one-time code (no tokens, no chat IDs) and/or enables email. Actions audited under the real username and gated by role; per-user severity threshold and digest opt-in. Global SMTP with Gmail/365 presets, in-product step-by-step guide and live test. |
| **Runbooks** | Field procedures the investigator follows and cites step by step. Ships with 4; add your own as JSON. |
| **Case memory** | Human resolutions become institutional memory: "same as incident #123 (Jun 3) — carrier maintenance". The system gets smarter with every incident you close. |
| **Anti-false-positives** | CRITICAL must be earned: minimum sample size, **Wilson confidence intervals** on rates (a trunk with 2 calls can't trip a critical), measurement coverage, deviation from the trunk's *own* robust seasonal baseline (median/MAD), sustained degradation (hysteresis). −92% noise, zero lost records. |
| **Auto-calibrated thresholds** | Opt-in: each mature trunk derives its own alarm thresholds from its learned history (median ± k·MAD) — a wholesale trunk that *normally* runs 25% ASR stops false-alarming at 25%, while a retail trunk alarms the moment it dips below *its* 90%. Manual overrides always win. Validated A/B on production: −40% alarms, no real signal lost. |
| **Capacity forecast** | Audio retention measured in hours + write rate; capacity incidents before you run out; daily/weekly digest via Telegram/webhook. |
| **Three-tier alarms** | (1) Manual thresholds — editable SIP failure-rate rules per class/code, global and per trunk, plus SBC-vs-carrier reject attribution. (2) Learned patterns — a 168-bucket seasonal baseline (day-of-week × hour, robust median/MAD) compares your Monday against *your* Mondays: traffic spikes, anomalous silence, ASR/PDD drift against that hour's normal. (3) Honest learning: without enough history the system stays silent instead of guessing. |
| **Fraud early-warning** | The "suddenly calling Cuba" detector: alerts the first day a trunk calls a country absent from its last 4 weeks — critical if it's on the (editable) IRSF high-risk list. Plus short-call storms to one destination (premium-number sweeps, hacked PBX — active from day one), abnormal growth to high-risk destinations, and international-mix spikes vs the trunk's own history. Factory runbook included: who originates, time-of-day tells, block at *your* SBC, dispute with the carrier. A **fraud-risk score (0–100)** fuses the signals via a model trained offline on labelled history (privacy-safe: training off-box, inference on-box, no data leaves your server) and gates which alerts escalate to critical. |
| **Predictive forecast** | Seasonal forecast (Holt-Winters over the 168-bucket baseline) projects each trunk's volume/ASR hours ahead with confidence bands, and turns audio-retention burn-rate into capacity incidents *before* you run out of disk. |
| **MCP server** | Standalone Model Context Protocol server: Claude (or any MCP agent) queries health, KPIs, trunks, CDRs and incidents through 6 read-only scoped tools. |

### 2 · Capture & analysis

| Feature | Copy |
|---|---|
| Two ingest paths: HEP **and** SIPREC | **HEP v1/v2/v3** (UDP+TCP) from the softswitches & proxies that speak it natively — **Asterisk, Kamailio, OpenSIPS, FreeSWITCH, RTPEngine** — plus the **HEPlify / CaptAgent** agents (or the bundled NIC probe) to bring in anything that can't. **SIPREC** (RFC 7865/7866) for the tier-1 hardware SBCs that record natively — **Ribbon/Sonus, Oracle/ACME Packet, AudioCodes, Cisco CUBE, Avaya** — straight into VoxyWatch's built-in SRS, no HEP agent needed. Auto-detects quirky senders. |
| Own capture probe | `voxywatch-probe` (Go + libpcap, amd64/arm64): sniffs SIP/RTP/RTCP off the NIC and emits HEP v3 for sources that can't. |
| **Native SIPREC recording** | Built-in **SRS** (Session Recording Server, RFC 7865/7866): any tier-1 SBC — Ribbon, Oracle/ACME, AudioCodes, Cisco CUBE, Avaya — streams its recording **straight into VoxyWatch over SIPREC**, no HEP agent or port mirroring needed. SIP over **UDP or TLS**, media **RTP or SRTP** (SDES). Reconstructs stereo caller/callee audio from `rs-metadata`; the call shows in the CDR like any other. Runs as a **separate service** (if it falls, HEP capture is untouched), **OFF by default**, with an SBC IP allowlist and anti-DoS limits. |
| SIP ladder & dialog analysis | Full request/response ladder, retransmissions, SDP/codec analysis, hold/re-INVITE/NAT detection, dialog-completeness scoring, RFC compliance audit. |
| **Codec-agnostic capture** | Every call is captured and analyzed **regardless of codec**, over **both HEP and SIPREC** — the SIP ladder, CDR, attribution and quality metrics (jitter/loss/PDD) work for any payload type. Audio *reconstruction* to playable WAV covers the common set below; capture itself never drops a call for using an exotic codec. |
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
| Self-hosted, period | Your hardware, your data. No cloud dependency. LLM keys are yours (OpenAI/Anthropic/Google/OpenRouter) and optional. |

### 4 · Integration & operations

| Feature | Copy |
|---|---|
| REST API v1 | Read-only versioned API: CDRs, traces, audio, health, stats, trunk health, **incidents**. Scoped hashed API keys, IP allowlists, rate limits, problem+json, OpenAPI spec. |
| Sanitized support bundle | Authenticated, read-only ticket evidence with versions, fault domain, component status, metrics and dependency checks; strict allowlist excludes secrets, PII, audio and raw SIP. |
| SNMP agent | Embedded v2c+v3 agent, 30+ OIDs, edge-triggered traps, downloadable MIB (IANA PEN 65985). |
| Webhooks | Per-trunk and global, transition-fired (no spam), rich JSON with incident_id. |
| Self-managing | Hardware-adaptive limits (RAM/CPU/disk derived), retention auto-purge by disk pressure, non-blocking startup, capture never interrupted. |
| Instant restarts | Persistent working-set snapshot: after any update/restart the full call history is visible in seconds (measured in production: ~40k calls restored at second 11) while the background sync converges. |
| Bilingual | English & Spanish UI, per user. |
| Storage | PostgreSQL + TimescaleDB (hypertables, compression, hourly rollups) — provisioned and isolated by the installer. |

---

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
- Avoid legacy references: storage is **PostgreSQL + TimescaleDB** (never SQLite/JSONL — those were pre-2.x internals).
- Current version channel: see `latest.json`. All claims in this file are shipped as of v2.151.2.
