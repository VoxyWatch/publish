<div align="center">

<img src="assets/voxywatch-wordmark.png" alt="VoxyWatch" width="520">

### The agentic NOC for your voice network.

**It doesn't just capture your calls. It watches them, investigates anomalies on its own, tells you the root cause — and learns from every incident.**

VoxyWatch ingests HEP traffic from your entire VoIP estate, correlates it into calls with playable audio, attributes every call to its carrier and destination, and learns each trunk's statistical "normal". When something drifts, an **autonomous AI investigator** opens an incident, gathers the evidence (failing calls, dominant SIP codes, carrier-vs-local scope), writes the probable root cause, and pings your phone with **action buttons** — acknowledge, resolve, investigate deeper, or approve a safe remediation. Every resolution it sees makes the next diagnosis smarter.

One self-contained binary. Your hardware. Your data stays local unless an administrator explicitly
enables an external AI or remote MCP integration. The AI never touches your SBC.

As of v3.10.3, agent behavior is release-gated: diagnoses cite verifiable evidence IDs, low-confidence or
ungrounded recommendations stay observe-only, new actions can run in effect-free shadow mode, and
Spanish/English prompt-injection canaries are tested before publishing. The optional local sidecar remains
off by default; the portal is the sole routing and policy authority.

As of v3.14.4, Overview makes hidden widgets explicit and provides one-click **Show all** and
**Restore defaults** recovery, including safe handling of older browser preferences.

The optional MCP gateway lets local or remote AI clients inspect live evidence and, when separately authorized, perform bounded initial setup
traffic through the existing portal HTTPS endpoint. It is off by default, scope-gated, redacted,
rate-limited and audited; remote use requires an explicit administrator configuration.

As of v3.15.1, VoxyWatch opens in light mode by default. Light/dark selection is stored per account,
so different users sharing one browser keep independent preferences.

v3.15.2 restores AI chat responses after fixing an internal context-limiter wiring regression.

For a status-labelled map of everything implemented in the signed release, see
the **[Implemented Feature Reference](IMPLEMENTED_FEATURES.md)**. Calls that cross a B2BUA can
remain one investigation session while ingress and egress are measured independently; see
**[Multi-leg call attribution](MULTI_LEG_CALL_ATTRIBUTION.md)**.
Authorized operators can generate local, channel-separated call transcripts through the opt-in **Speech to text Beta**. It is off by default, bounded outside capture and supports TXT/JSON/SRT export; unattended processing remains locked during Beta. See the **[Speech to text Beta guide](SPEECH_TO_TEXT_BETA.md)**.

For networks that cannot export HEP or SIPREC, the opt-in **Passive Mirror Capture Beta** can ingest a dedicated SPAN/RSPAN interface, ERSPAN II/III, or AWS VPC Traffic Mirroring VXLAN without changing the existing capture paths. It is off by default and requires an explicit interface. See the **[Passive Mirror Capture guide](PASSIVE_MIRROR_CAPTURE.md)**.
LLM credentials can be supplied without storing plaintext in normal settings; see the
**[LLM credential management guide](AI_CREDENTIALS.md)**.
Deployment options for public-domain and private-network TLS are documented in the **[HTTPS configuration guide](HTTPS_CONFIGURATION.md)**.
For the exact context order, privacy boundary, RFC selection and local finding memory, see the
**[AI Context Engine guide](docs/ai/CONTEXT_ENGINE.md)**.

</div>

---

## ⚡ Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/VoxyWatch/publish/main/install.sh | sudo bash
```

Certified on **Debian 12/13**, **Ubuntu 22.04/24.04**, and **Amazon Linux 2023**, on x86_64 and ARM64.
The installer auto-detects your distro and CPU architecture, provisions a dedicated PostgreSQL + TimescaleDB cluster, and starts everything as systemd services.
On minimal hosts it also installs the mandatory GnuPG verifier through the detected OS package manager
before downloading VoxyWatch. Package signature verification remains fail-closed.

Then open **`https://YOUR-IP`** (or the HTTPS hostname selected by the installer).

| Field | Value |
|---|---|
| Username | `admin` |
| Password | `voxywatch` |

> ⚠️ **Change the default password immediately** — Settings → Security → Users.

### Connect an AI client through MCP

VoxyWatch includes an optional MCP gateway for ChatGPT, Claude, Codex and other
compatible clients. It uses the portal listener; **do not open a separate MCP port**.

- Local endpoint: `http://127.0.0.1:3080/mcp`
- Remote endpoint: `https://YOUR-VOXYWATCH-HOST/mcp` through the existing reverse proxy on TCP 443
- Protocol/transport: official MCP TypeScript SDK, protocol `2025-11-25`, stateless Streamable HTTP JSON responses
- Authentication: scoped VoxyWatch API key, or OAuth access token validated with issuer, audience and JWKS
- Scopes: `mcp:read`, `mcp:traffic`, `mcp:incidents`; `mcp:sensitive` is an additional explicit opt-in

In **Settings → AI connections**, enable MCP, create a key with only the needed scopes, and run the
built-in MCP test. For remote access, also enable Remote MCP, configure
HTTPS, list browser Origins when applicable, and preferably configure an OAuth identity provider.
Keep Sensitive data disabled unless the use case truly requires raw identifiers. The live-traffic
tool supports client-selected refresh intervals from 5 seconds to 30 minutes.

The gateway starts disabled. It never writes to VoxyWatch, returns audio/RTP/PCAP/DTMF, or controls
an SBC. Remote access should be firewall-restricted to TCP 443; portal port 3080 should remain private
behind the reverse proxy.

Full configuration, the current 12-tool catalog, client examples, security
controls and troubleshooting are in the
**[MCP Server guide](MCP_SERVER.md)** · **[Reports guide](REPORTS.md)**.

Initial setup can also be inspected and applied through Settings, the root-only `voxywatch-setup`
CLI or the gated MCP setup tool. Portal passwords and LLM keys never belong in MCP calls.
**[Initial setup channels](INITIAL_SETUP_CHANNELS.md)**.

### Detect Flash Call authentication patterns

Flash Call Intelligence passively identifies repeated originator-side SIP
`CANCEL` patterns, timing concentration, destination fan-out, unanswered calls
and absence of media. Detection is deterministic, local and token-free.

It starts in **Shadow** mode. Operators review Flash findings in **Operations → Flash Calls**,
while general fraud signals live beside them under **Operations → Fraud**. They tune or
enable sustained **Alerting** from **Configuration → Fraud**.
VoxyWatch never blocks or reroutes these calls and never controls the SBC.

See **[Flash Call Detection](FLASH_CALL_DETECTION.md)** for prerequisites,
thresholds, interpretation, false-positive tuning, privacy and safe rollout.

### AI-assisted configuration

After the first login, open **Settings → Getting started**. If you want your own AI assistant to help configure VoxyWatch, ask it to read:

https://github.com/VoxyWatch/publish/blob/main/AI_VOXYWATCH_CONFIGURATION_ASSISTANT.md

The guide explains which operational data the AI should collect and validate: capture sources, IP labels, trunks, DID ranges, thresholds, retention, alerts and users. It intentionally contains no customer secrets or real customer IPs.

### Anonymous telemetry

Settings → Diagnostics & Telemetry controls Sentry error reporting and anonymous adoption telemetry together. When enabled, VoxyWatch sends a lightweight hourly ping and one daily installation check-in so releases, active versions and platform adoption can be measured without customer call data. It never sends customer IPs, trunks, SIP/RTP payloads, CDRs, settings, Call-IDs, audio or credentials.

### 🔑 Root & `sudo` — what's required

The installer **must run with root privileges**. It creates a dedicated `voxywatch` system user, installs the binary to `/opt/voxywatch`, provisions an isolated PostgreSQL + TimescaleDB cluster and registers systemd services — none of which is possible unprivileged. **There is no non-root install.** What changes is only *how* you reach root:

```bash
# A) You're a regular user WITH sudo rights (most common):
curl -fsSL https://raw.githubusercontent.com/VoxyWatch/publish/main/install.sh | sudo bash

# B) You're ALREADY root (e.g. after `su -`, or a root shell): drop the sudo
curl -fsSL https://raw.githubusercontent.com/VoxyWatch/publish/main/install.sh | bash
```

**The `sudo` *package* must be present either way** — even when you run as root. The installer uses it internally to run the PostgreSQL setup as the `postgres` / `voxywatch` users via peer authentication. It does **not** grant VoxyWatch general root. Install it first if missing:

```bash
apt-get install -y sudo      # Debian / Ubuntu
dnf install -y sudo          # Amazon Linux 2023
```

**Updates also require root.** Existing installations use the root-owned installer that arrived
inside the last signed package:

```bash
sudo /opt/voxywatch/install.sh --update
```

The portal checks hourly and announces a new version in the 🔔 bell (Settings → Update). The **one-click "Update now"** button applies it on its own when you allowed VoxyWatch to manage itself during install (the *Service control* prompt). That grant is scoped: a **polkit rule** that lets the unprivileged portal ask systemd to start **one root-owned helper unit** (`voxywatch-apply-update.service` → `apply-update.sh`) which only ever runs the official signed installer — never general root, and it works under `NoNewPrivileges=true`. You can toggle it anytime with `sudo /opt/voxywatch/enable-service-control.sh` / `disable-service-control.sh`. On hosts without that grant, the button shows the exact `--update` command to run as root.

> **Upgrading from v2.80 – v2.84.0?** The one-click button couldn't actually apply updates on those versions (it printed *“needs privilege”* or did nothing). To get past it, run the official installer **once** as root — afterwards the button works for every future release:
> ```bash
> curl -fsSL https://raw.githubusercontent.com/VoxyWatch/publish/main/install.sh | sudo bash -s -- --update
> sudo /opt/voxywatch/enable-service-control.sh   # enables one-click going forward
> ```
> Fresh installs (v2.84.1+) are unaffected — they get a working one-click from day one.

---

## 💡 Why VoxyWatch

Most capture tools stop at *"here are the packets."* Most monitoring tools stop at *"here's a red light."* VoxyWatch closes the whole loop a NOC engineer would:

**DETECT → INVESTIGATE → DIAGNOSE → NOTIFY → ACT (with your approval) → LEARN**

- **It's passive and safe.** VoxyWatch only *observes* mirrored/HEP traffic. It never touches your SBC, never routes a call. The AI has no tool to change your network — by design, not by promise.
- **It speaks carrier, not just packets.** Every call is attributed to its carrier, direction and destination country — raw SIP becomes business-level analytics.
- **It learns what's normal.** Each trunk builds its own statistical baseline. The trunk whose ASR quietly drops 90% → 70% gets flagged — even though a static threshold would never catch it. And a trunk that has *always* been mediocre doesn't wake you up at 3 AM.
- **It investigates before it bothers you.** When an incident opens, the system gathers the evidence on its own — sample failing calls, dominant SIP codes, affected destinations, whether other trunks degraded at the same time (local vs carrier) — and the AI investigator writes the probable cause *citing that evidence*.
- **It's statistically honest.** Critical alarms require real sample sizes, real measurement coverage and sustained degradation. Validated on production data: **−92% false-critical noise** versus naive thresholds — without losing a single record.

From "we have pcaps somewhere" to *"Incident #41: trunk to Carrier X degrading, 91% of failures are 503s from their gateway, other trunks unaffected → carrier-side issue. [Ack] [Resolve] [Investigate]"* — delivered to your phone. That's the jump.

---

## 🤖 The Agentic NOC

The flagship of VoxyWatch: a virtual NOC engineer that runs the incident loop end-to-end.

### 🚨 Incident engine
Every anomaly — trunk degradation, capture loss, sniffer down, silent HEP sources, system bottlenecks, global traffic drops, low audio retention — becomes a **persistent incident** with a lifecycle (`open → acknowledged → resolved`), deduplication (one live incident per problem, no alert storms), an **auditable timeline** of everything that happened, and stability-based auto-resolve. A dedicated **Incidents tab** with filters, detail view and one-click actions; open-incident badge in the nav and the notification bell.

### 🔍 Autonomous investigator
The moment an incident opens, VoxyWatch investigates it **by itself** — no human, no LLM needed yet: it collects sample failing calls, the dominant SIP failure codes, the failing IP paths, affected destinations, and whether *other* trunks degraded at the same time (the local-vs-carrier tell). Then, if you've configured an LLM key, an AI investigator with live tools produces a structured diagnosis: **probable root cause, confidence, scope (carrier / customer / local / capacity), recommended action — citing the evidence**. Budgeted and cached so it can't run up your token bill.

### 📲 Actionable Telegram & email notifications — per user
Critical incidents reach your phone with the diagnosis attached and **inline buttons**: `✅ Ack` · `✔ Resolve` · `🔍 Investigate` · plus the **proposed remediation** when one applies. Actions come from a **closed, code-level catalog** (restart the capture sniffer, recompute baselines — never your SBC), execute only after *your* tap, and land in the incident timeline with who-approved-what.

Notifications are **personal**: your team creates one Telegram bot for the installation (a 2-minute guided wizard), then **each portal user links their own chat with a one-time code** — no tokens, no chat IDs. Every action is audited under the real portal username and **gated by role** (viewers receive read-only notifications). Each user picks their minimum severity, opts into the digest, and can also receive incidents **by email** (global SMTP with Gmail/Microsoft 365 presets, step-by-step in-product guide and live test). An optional NOC-room group chat receives everything. Admins configure all delivery channels in **Settings → Notifications**; operators tune SIP and learned-pattern rules directly in **Configuration → Alerts**.

### 📚 Runbooks + case memory
Ships with seven field runbooks (low ASR, packet loss, capture down, one-way audio, Flash Call patterns, fraud suspects and traffic-volume drops) that the investigator **follows and cites step by step** — and you can add your own as JSON. When you resolve an incident and write down the cause, that resolution becomes **institutional memory**: the next time the same pattern fires, the diagnosis references it — *"same as incident #123 (Jun 3), resolved: carrier maintenance"*.

### 🛡️ Statistical confidence (anti-false-positives)
Declaring CRITICAL requires earning it: a **minimum sample** of calls, **Wilson confidence intervals** on rates (a trunk with 2 calls can't trip a critical), **measurement coverage** for quality metrics (MOS/loss only alarm when actually measured on enough calls), **deviation from the trunk's own robust seasonal baseline** (median/MAD per day-of-week × hour — chronic mediocrity ≠ incident), and **sustained degradation** across consecutive evaluations (hysteresis). Validated against production incidents: **−92% critical noise**. Everything stays recorded and visible — confidence only gates *what wakes you up*.

**Auto-calibration (opt-in):** each mature trunk can derive its *own* thresholds from its learned history (median ± k·MAD). A wholesale trunk that normally runs 25% ASR stops false-alarming at 25%, while a retail trunk alarms the moment it dips below *its* 90%. Manual overrides always win. Validated A/B on production: **−40% alarms, no real signal lost**.

### 📋 Capacity forecast & scheduled digest
Audio retention is **measured, not guessed** (hours of recoverable audio + write rate, exposed in the API) and can open a capacity incident before you run out. A **daily/weekly digest** (incidents, trunk health, volume vs previous period, capacity) lands in Telegram or your webhook on schedule — or on demand via API.

### 🔗 MCP gateway — your voice network, exposed to *your* agents
VoxyWatch ships a **Model Context Protocol gateway**: connect ChatGPT, Claude, Codex or another compatible client locally or remotely and use 13 read-only tools plus one opt-in initial-setup tool. API-key/OAuth scopes, dry-run, confirmation, redaction, bounded results and content-free audit keep access explicit. [MCP guide](MCP_SERVER.md) · [setup channels](INITIAL_SETUP_CHANNELS.md).

VoxyWatch v3 also ships a native **agentic runtime** foundation: `voxywatch-agentic.service`, a loopback-only Google ADK 2.6.3 workflow with a Task Orchestrator and ten specialists covering SIP, fraud, Flash Calls, RTP/media, routing attribution, incident correlation, traffic, platform health, integrations and releases. The portal scopes typed handoffs, tools and evidence; up to three specialists fan out and a coordinator merges their findings without LLM tokens. ADK never receives database credentials, media or SBC control. It is disabled by default and visible/controllable from Settings -> Diagnostics for admins.

Support can export an authenticated, read-only **sanitized ticket bundle** with version, fault domain, component
status, metrics, dependencies and input/process/output signals. It uses a strict allowlist and excludes secrets,
PII, audio and raw SIP before the JSON can be attached to a ticket.

---

## 🚀 What it does

### 📡 Universal multi-source capture
- Receives **HEP v1 / v2 / v3** over **UDP and TCP** (port 9060 + configurable extras).
- Two ways in: **HEP** from the softswitches & proxies that speak it natively (**Asterisk, Kamailio, OpenSIPS, FreeSWITCH, RTPEngine**) — plus **HEPlify / CaptAgent** agents or the bundled NIC probe for anything else — and **SIPREC** (RFC 7865/7866) from the tier-1 hardware SBCs that record natively (**Ribbon/Sonus, Oracle/ACME Packet, AudioCodes, Cisco CUBE, Avaya**), straight into VoxyWatch's built-in SRS.
- Ships its own lightweight **capture probe** (`voxywatch-probe`, Go + libpcap, **amd64 & arm64**) for sources that can't emit HEP — it sniffs SIP/RTP/RTCP straight off the NIC and forwards HEP v3 — a self-contained, no-dependency capture agent.
- Auto-detects quirky SBCs that mix RTP into `protocol_id=1` or mint a new capture-id per call.
- **Native SIPREC recording (RFC 7865/7866)** — a built-in **SRS** lets any tier-1 SBC stream its recording **straight into VoxyWatch over SIPREC**, no HEP agent or port mirroring required. SIP over **UDP or TLS**, media **RTP or SRTP** (SDES), stereo caller/callee audio reconstructed from `rs-metadata`. Runs as a **separate service** (HEP capture untouched if it falls), **OFF by default**, with an SBC IP allowlist and anti-DoS limits. Point your SBC's recording profile at the SRS host:port and the call shows in the CDR like any other.

### 📞 Deep call & SIP analysis
- **Full SIP ladder diagram** per call — every request/response, retransmissions, timing.
- **SDP & codec analysis** — offered/answered codecs, hold detection, re-INVITE tracking, NAT detection.
- **Dialog-completeness** scoring with human-readable diagnostics.
- Per-call quality: **MOS** (E-model), **jitter**, **packet loss**, **PDD**, **RTCP** enrichment when available.
- Traces are reconstructed from **RAM + database**, so even calls mid-eviction render complete.

### 🔊 Audio you can actually listen to
- **SIPREC stereo reconstruction** — caller/callee on separate channels, played in the browser.
- **Codec-agnostic capture**: every call is captured and analyzed regardless of codec — over **both HEP and SIPREC** — so the CDR, SIP ladder and quality metrics work for any payload type.
- Multi-codec audio *decode* (reconstruction to playable WAV): **PCMU/PCMA, G.722, G.729**, plus dynamic AMR-NB/WB, GSM, G.723, Opus, Speex via SDP hints.
- Per-call **PCAP export** for Wireshark.

### 📊 Real-time dashboard & CDR
- **Window-accurate KPIs**: **Attempts, Answered, Active now, ASR, NER, ACD, MOS, PDD, minutes, concurrency** — every headline number is aggregated from continuous rollups for the **exact time range you pick** (last hour … *yesterday* … *today* … custom … all), so a date filter shows that day's reality, not a snapshot of "now". "Active now" is the live count of calls in progress.
- **Trend charts** (~48 points on any range): call attempts, answered, simultaneous calls (concurrency), CPS, ASR/NER. Plus distribution charts: **Disconnect Causes** (by SIP family: 2xx/3xx/4xx/5xx/6xx/Ignored), duration, PDD, codecs and **MOS distribution**.
- **CDR base**: sortable, filterable, CSV-exportable call records with caller/callee/IP-label resolution — served straight from the database with keyset pagination and trigram search, so it stays fast at millions of rows.
- Group and compare by **Inbound / Outbound / Carrier / Country**. Fully bilingual (EN/ES).
- *Honest by design:* MOS needs RTCP or stored RTP to be measured per call — where the source provides neither, the dashboard says so instead of inventing a number.

### 🏢 Carrier & trunk intelligence  *(the part nobody else has)*
- **Trunk catalog** — load your carriers once (name, direction, IPs/CIDRs, prefixes). Import/export CSV or JSON, with a downloadable template.
- **Automatic attribution** — every call is matched to its carrier by IP and to its **destination country** via an ITU-T E.164 engine (197 country codes, longest-match), stripping your technical routing prefixes first.
- **Carrier & country dashboards** — volume, ASR, NER, ACD, MOS, PDD per carrier and per destination.
- **ONNET / internal trunks** flagged separately, so on-net traffic never pollutes your PSTN alarms.

### 🩺 Per-trunk health + auto-baselines
- A **rule-based health engine** scores every trunk (`ok / warn / critical / idle`) with structured, plain-language reasons: low ASR/NER, **5xx surges (carrier down)**, false-answer (short ACD with high ASR), low MOS, high loss, high PDD, silence.
- **Auto-baselines**: each trunk learns its own normal (mean ± σ per hour, per metric) from its history and is flagged on **deviation beyond *N*·σ** — catching the "90% → 70%" drops a global threshold misses. Honest: it won't judge a metric until it has enough history.
- Every threshold is **configurable**, globally and per-trunk.

### 🖥️ Monitoring & per-trunk drill-down
- A dedicated **Monitoring** tab: status summary, active-alarm cards with diagnostics, and a live per-trunk metrics table (auto-refresh).
- Click any trunk → a **drill-down with charts of its entire history**: volume, ASR/NER, 5xx, ACD, minutes, MOS, loss, PDD, SIP-code & country distributions, inbound/outbound — with the learned **"normal" line** overlaid. Pick 24h / 7d / 30d / Max.
- History depth is **not capped by code** — it's whatever your CDR retention holds. More disk → more history → a smarter copilot.

### 🤖 NOC AI Copilot — chat with your network  *(bring your own key)*
- **Contextual LLM**: keeps per-user history, applies the user's profile prompt, understands the current portal view through a sanitized context hint, and can use live read-only tools for calls, SIP ladders, trunks and incidents.
- **NOC summary copilot**: prioritizes and groups all alarming trunks and suggests the action per group.
- **Per-user chat memory**: each operator keeps private chat sessions, can reopen or delete prior conversations, and can define a profile prompt plus AI language.
- **Cost and freshness controls**: operators choose manual, 30-second, 1-, 5-, 15- or 30-minute AI refresh while local KPIs stay live; admins set the floor and can configure prompt caching, token/context budgets, fast/standard/deep routing and offline Batch.
- **You bring the key** (OpenAI, Anthropic, Google Gemini, OpenRouter/OpenRouter Free, DeepSeek, Groq, or Perplexity), or connect your own Ollama-style server — your tokens, your cost, your data path. Off until you enable it.
- **Guardrailed**: the copilot only explains and recommends; it never touches the SBC. Responses are cached to control spend, and it's bilingual.

### 🔔 Alerting that reaches you everywhere
- **Traffic / trunk alerts** → the Monitoring tab + **webhooks** (global and per-trunk), fired on state transition (no spam), with a rich JSON payload.
- **Server / infra alerts** → the header **notification bell** (CPU, RAM, disk, capture loss, HEP source gone silent, sniffer down) **and** **SNMP traps**.
- **Embedded SNMP agent** (v2c + v3) exposes 30+ OIDs (host, capture, VoIP KPIs, bottleneck diagnosis) and sends edge-triggered traps for capture loss, sniffer down, no-sources, disk/RAM/CPU high, RTP/kernel drops, low ASR, low MOS — with a downloadable MIB. The **same thresholds drive the bell and the traps**, so they always agree.

### 🔌 Integration API
- A read-only, versioned REST API (**`/api/v1`**) for billing and monitoring systems: CDR search, single CDR, Call Insight Audio/RTP Expert, SIP-trace JSON, PCAP and audio.
- **API keys** (hashed, scoped: `cdr:read` / `trace:read` / `audio:read`), per-key **IP allowlists** and **rate limits**, a stable public CDR schema decoupled from internals, RFC 9457 `problem+json` errors, a published OpenAPI spec and bundled admin-only Swagger UI at `/api/docs`.
- **Platform readiness** in Settings -> Diagnostics combines health, configuration, update safety, heavy jobs, AI troubleshooting context and hardware fit, then shows guided actions with priority, likely fault domain, confidence and next step. Each CDR carries a deterministic quality score for faster triage.

### 🔐 Security & access control
- **JWT auth** with **RBAC** (admin / operator / viewer) and **SSO via OIDC** (Google, Microsoft, Okta, Keycloak, Auth0).
- Hardened by two security audits + a penetration test (50+ fixes): CSRF/Origin checks, XSS escaping, command-injection-safe subprocess calls, path-traversal protection, secret masking, security headers.
- Optional **HTTPS** with your own certificate.

### 🌍 Operations & platform
- **English & Spanish** UI, switchable per user.
- **Non-blocking startup** — after a restart the UI and your CDRs/traces/config are usable instantly; live KPIs fill in as history loads in the background. **Capture is never interrupted.**
- **Self-managing retention** — auto-purge by disk pressure: RTP/audio first, CDRs and recordings protected.
- **Selective recording** — record audio only for the trunks that matter (SIP/CDR always kept) and stretch your audio retention from hours to days on the same disk.
- **Hardware-adaptive** — working-set, parse budget and capture capacity derive from the machine's RAM/CPU/disk. No fixed caps; scales from a small VM to a 32-vCPU telco box.
- **Storage**: PostgreSQL + **TimescaleDB** (hypertables for packets/RTP, a calls table for CDRs, hourly rollups) — provisioned and isolated by the installer on its own port.
- **One-click auto-update** from the portal (signed, SHA-256 + GPG verified), or via the CLI updater.
- **IP label directory** — map IPs/subnets to friendly names everywhere.

---

## 🔒 PCI-DSS — pause/resume recording

Capturing call audio in a contact center that takes **card payments by phone**? VoxyWatch can
**suppress the audio during the card/CVV window** so it is never stored — required to stay
PCI-DSS compliant (Req. 3.2: the CVV must never be retained).

- **Programmable on/off** — master switch `pci.enabled` (OFF by default, affects no one) plus
  per-call control via API: `POST /api/v1/recording/suppress {call_id, action: "pause"|"resume"}`.
- **Defense in depth (3 layers, matched by SSRC):** the **Probe** drops the RTP *at the source*
  (the sensitive audio never leaves your network), the **sniffer** never persists it, and the
  **portal** wipes anything that slips through. SIP/CDR metadata is kept (no card data in it).
- **Auto-triggers**: trunks/DIDs dedicated to payments, and **DTMF detection** (SIP INFO) — recording pauses while the customer keys in the card and resumes automatically when the tones stop.
- Full audit log for your attestation. Configurable from the portal (Settings → Security).

---

## 🧩 What's installed

| Component | Description |
|---|---|
| `voxywatch-portal` | Self-contained binary: web portal, REST API, SNMP agent, copilot, schedulers (port 3080) |
| `hep_sniffer.py` | Multiprocess HEP v1/v2/v3 capture sniffer (UDP + TCP) |
| `voxywatch-probe` | Optional NIC capture agent → HEP (Go + libpcap, amd64 & arm64) |
| `reconstruct_audio.py` | SIPREC stereo audio reconstruction (multi-codec) |
| `generate_pcap.py` | Per-call PCAP export |
| PostgreSQL + TimescaleDB | Dedicated, isolated capture database |
| `voxywatch-mcp.js` | Local stdio bridge to the scoped VoxyWatch MCP gateway |
| `get-hwid.js` | Hardware ID tool for license activation |
| `voxywatch-license` | Root CLI to validate and atomically replace the product license without the portal |

---

## 🆓 Free tier

VoxyWatch runs fully featured out of the box, no license required:

| Limit | Free tier |
|---|---|
| Concurrent calls | 50 |
| CDR history | **Unlimited** (bounded only by your disk) |
| Features | **Everything included** |

The tiers differ **only** in concurrent-call capacity — every feature and full CDR/history retention are the same on all of them. Need more simultaneous calls? Production and Telco (unlimited) unlock it with the same binary — purchase at **[voxywatch.com/pricing](https://voxywatch.com/pricing/)**.

---

## 🔑 Licensing

Licenses are hardware-bound (MAC + hostname), offline-validated (RSA), and available as:

| Plan | Duration |
|---|---|
| Monthly | 1 month |
| Semi-annual | 6 months |
| Annual | 1 year |
| Biennial | 2 years |

**Activate:**

```bash
sudo /opt/voxywatch/voxywatch-portal license install /path/to/license.key
# or without retaining another server-side copy:
sudo /opt/voxywatch/voxywatch-portal license install --stdin < license.key
```

The command verifies signature, HWID and expiration before an atomic replacement, restarts only the
portal when active and restores the previous license if activation fails. See the
**[License CLI guide](LICENSE_CLI.md)**. A fresh install also exposes `voxywatch-license` as a shorter alias.

No restart required — the portal picks it up within seconds. Get your **Hardware ID** from **Settings → License** or:

```bash
node /opt/voxywatch/get-hwid.js
```

---

## 📦 Manual installation

If you prefer not to pipe the script, run the installer from disk — it auto-detects your distro and CPU architecture and fetches the latest signed package.

```bash
# Dependencies — Debian/Ubuntu
apt-get update && apt-get install -y curl sudo gnupg
#   RHEL/Rocky/Alma:  dnf install -y curl sudo gnupg2

curl -fsSL https://raw.githubusercontent.com/VoxyWatch/publish/main/install.sh -o install.sh
sudo bash install.sh
```

Pin a specific version with `--version`:

```bash
sudo bash install.sh --update --version 2.31.0
```

> The installer records the version from the **installed binary itself** (`voxywatch-portal --version`), so what's logged always matches what's actually running — never a stale manifest.

---

## 🛠️ Administration

### Reset admin password

Locked out? Reset from the CLI (no data loss):

```bash
sudo systemctl stop voxywatch
sudo /opt/voxywatch/voxywatch-portal --reset-admin
sudo systemctl start voxywatch
```

This resets **all admin accounts** to `voxywatch` and forces a change on next login.

### Service control

```bash
sudo systemctl status voxywatch voxywatch-sniffer
journalctl -u voxywatch -f            # portal logs
journalctl -u voxywatch-sniffer -f    # capture logs
```

---

## 🩹 Troubleshooting

**Forgot admin password / locked out** → see [Reset admin password](#reset-admin-password).

**`systemctl: command not found`** (minimal containers) → VoxyWatch runs as a systemd service; minimal images lack systemd. For container deployments contact [support@voxywatch.com](mailto:support@voxywatch.com).

**Portal shows "loading history" after a restart** → expected and non-blocking: the UI, CDRs and traces are already usable; live KPIs and per-trunk health repopulate as the working set loads. Capture is not interrupted.

---

## 🔏 Verifying package integrity

Every release is signed with GPG. To verify before installing:

```bash
# Import the VoxyWatch release signing key (first time only)
curl -fsSL https://raw.githubusercontent.com/VoxyWatch/publish/main/voxywatch-release.gpg.pub | gpg --import

# Download the package + its .asc signature from the release, then:
gpg --verify <package>.asc <package>
```

The installer also verifies the SHA-256 from the signed manifest before extracting.

---

## 📬 Contact

- **Support:** [support@voxywatch.com](mailto:support@voxywatch.com)
- **Immediate assistance on WhatsApp:** [+52 55 9221 7665](https://wa.me/525592217665)
- **Sales & licensing:** [contact@voxywatch.com](mailto:contact@voxywatch.com)
- **Web:** [voxywatch.com](https://voxywatch.com)

<div align="center">
<sub><b>VoxyWatch</b> — see every call, understand every carrier, fix it before it escalates.</sub>
</div>
