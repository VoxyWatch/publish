<div align="center">

# 🛰️ VoxyWatch

### The self-hosted SIP capture platform that became a NOC copilot.

**Capture every call. Understand every carrier. Get told what's failing — before your customers call you.**

VoxyWatch ingests HEP traffic from your entire VoIP estate, correlates it into calls, reconstructs the audio, attributes every call to its carrier and destination country, learns what "normal" looks like for each trunk, and — when something drifts — tells your NOC the *likely root cause and the action to take*, in plain language.

One self-contained binary. Your hardware. Your data. No cloud, ever.

</div>

---

## ⚡ Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/VoxyWatch/publish/main/install.sh | sudo bash
```

Supports **Debian 11+**, **Ubuntu 20.04+**, **RHEL / CentOS / Rocky / AlmaLinux 8+**.
The installer auto-detects your distro and CPU architecture, provisions a dedicated PostgreSQL + TimescaleDB cluster, and starts everything as systemd services.

Then open **`http://YOUR-IP:3080`**.

| Field | Value |
|---|---|
| Username | `admin` |
| Password | `voxywatch` |

> ⚠️ **Change the default password immediately** — Settings → Security → Users.

---

## 💡 Why VoxyWatch

Most capture tools stop at *"here are the packets."* VoxyWatch keeps going:

- **It's passive and safe.** VoxyWatch only *observes* mirrored/HEP traffic. It never touches your SBC, never routes a call, never changes a thing. Zero risk to production.
- **It speaks carrier, not just packets.** Load your trunks once and every call is attributed to its carrier, direction and destination country — turning raw SIP into business-level analytics.
- **It learns.** Each trunk builds its own statistical baseline. A trunk whose ASR normally sits at 90% and quietly drops to 70% gets flagged — even though a static 50% threshold would never catch it.
- **It explains.** The built-in NOC copilot reads the health, the baseline and the recent trend, and writes you the probable cause + the recommended action. Bring your own LLM key; your tokens, your control.
- **It's honest.** When there isn't enough signal to judge, it says so instead of inventing an alarm.

From "we have pcaps somewhere" to *"the trunk to Carrier X is degrading, likely a 5xx surge on their gateway — here's what to check"* — that's the jump.

---

## 🚀 What it does

### 📡 Universal multi-source capture
- Receives **HEP v1 / v2 / v3** over **UDP and TCP** (port 9060 + configurable extras).
- Works with virtually every SIP platform that speaks HEP: **Asterisk, Kamailio, OpenSIPS, FreeSWITCH, Oracle/ACME Packet, Ribbon/Sonus, AudioCodes, Cisco CUBE, RTPEngine, HEPlify, CaptAgent** and more.
- Ships its own lightweight **capture probe** (`voxywatch-probe`, Go + libpcap, **amd64 & arm64**) for sources that can't emit HEP — it sniffs SIP/RTP/RTCP straight off the NIC and forwards HEP v3 — a self-contained, no-dependency capture agent.
- Auto-detects quirky SBCs that mix RTP into `protocol_id=1` or mint a new capture-id per call.

### 📞 Deep call & SIP analysis
- **Full SIP ladder diagram** per call — every request/response, retransmissions, timing.
- **SDP & codec analysis** — offered/answered codecs, hold detection, re-INVITE tracking, NAT detection.
- **Dialog-completeness** scoring with human-readable diagnostics.
- Per-call quality: **MOS** (E-model), **jitter**, **packet loss**, **PDD**, **RTCP** enrichment when available.
- Traces are reconstructed from **RAM + database**, so even calls mid-eviction render complete.

### 🔊 Audio you can actually listen to
- **SIPREC stereo reconstruction** — caller/callee on separate channels, played in the browser.
- Multi-codec decode: **PCMU/PCMA, G.722, G.729**, plus dynamic AMR-NB/WB, GSM, G.723 via SDP hints.
- Per-call **PCAP export** for Wireshark.

### 📊 Real-time dashboard & CDR
- Live VoIP KPIs: **ASR, NER, ACD, MOS, PDD, jitter, packet loss, concurrency** — sampled live, with time-series from a continuous rollup.
- **CDR base**: sortable, filterable, CSV-exportable call records with caller/callee/IP-label resolution — served straight from the database with keyset pagination and trigram search, so it stays fast at millions of rows.
- Group and compare by **Inbound / Outbound / Carrier / Country**.

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

### 🤖 NOC AI Copilot  *(bring your own key)*
- **Per-trunk copilot**: feeds the LLM a compact context (current KPIs + alarms + learned baseline + 48h trend + top SIP codes + destinations) and returns **probable cause → NOC actions → short-term risk**.
- **NOC summary copilot**: prioritizes and groups all alarming trunks and suggests the action per group.
- **You bring the key** (OpenAI, Anthropic, Google Gemini, or OpenRouter) — your tokens, your cost, your data path. Off until you enable it.
- **Guardrailed**: the copilot only explains and recommends; it never touches the SBC. Responses are cached to control spend, and it's bilingual.

### 🔔 Alerting that reaches you everywhere
- **Traffic / trunk alerts** → the Monitoring tab + **webhooks** (global and per-trunk), fired on state transition (no spam), with a rich JSON payload.
- **Server / infra alerts** → the header **notification bell** (CPU, RAM, disk, capture loss, HEP source gone silent, sniffer down) **and** **SNMP traps**.
- **Embedded SNMP agent** (v2c + v3) exposes 30+ OIDs (host, capture, VoIP KPIs, bottleneck diagnosis) and sends edge-triggered traps for capture loss, sniffer down, no-sources, disk/RAM/CPU high, RTP/kernel drops, low ASR, low MOS — with a downloadable MIB. The **same thresholds drive the bell and the traps**, so they always agree.

### 🔌 Integration API
- A read-only, versioned REST API (**`/api/v1`**) for billing and monitoring systems: CDR search, single CDR, SIP-trace JSON, PCAP and audio.
- **API keys** (hashed, scoped: `cdr:read` / `trace:read` / `audio:read`), per-key **IP allowlists** and **rate limits**, a stable public CDR schema decoupled from internals, RFC 9457 `problem+json` errors and a published OpenAPI spec.

### 🔐 Security & access control
- **JWT auth** with **RBAC** (admin / operator / viewer) and **SSO via OIDC** (Google, Microsoft, Okta, Keycloak, Auth0).
- Hardened by two security audits + a penetration test (50+ fixes): CSRF/Origin checks, XSS escaping, command-injection-safe subprocess calls, path-traversal protection, secret masking, security headers.
- Optional **HTTPS** with your own certificate.

### 🌍 Operations & platform
- **English & Spanish** UI, switchable per user.
- **Non-blocking startup** — after a restart the UI and your CDRs/traces/config are usable instantly; live KPIs fill in as history loads in the background. **Capture is never interrupted.**
- **Self-managing retention** — auto-purge by disk pressure: RTP/audio first, CDRs and recordings protected.
- **Hardware-adaptive** — working-set, parse budget and capture capacity derive from the machine's RAM/CPU/disk. No fixed caps; scales from a small VM to a 32-vCPU telco box.
- **Storage**: PostgreSQL + **TimescaleDB** (hypertables for packets/RTP, a calls table for CDRs, hourly rollups) — provisioned and isolated by the installer on its own port.
- **One-click auto-update** from the portal (signed, SHA-256 + GPG verified), or via the CLI updater.
- **IP label directory** — map IPs/subnets to friendly names everywhere.

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
| `get-hwid.js` | Hardware ID tool for license activation |

---

## 🆓 Free tier

VoxyWatch runs fully featured out of the box, no license required:

| Limit | Free tier |
|---|---|
| Concurrent calls | 50 |
| CDR records | 1,000 |
| Features | **Everything included** |

Need more? Production and Telco (unlimited) tiers unlock higher capacity with the same binary — purchase at **[voxywatch.com/pricing](https://voxywatch.com/pricing/)**.

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
cp voxywatch.key /etc/voxywatch/license.key
chown root:voxywatch /etc/voxywatch/license.key
chmod 640 /etc/voxywatch/license.key
```

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
- **Sales & licensing:** [contact@voxywatch.com](mailto:contact@voxywatch.com)
- **Web:** [voxywatch.com](https://voxywatch.com)

<div align="center">
<sub><b>VoxyWatch</b> — see every call, understand every carrier, fix it before it escalates.</sub>
</div>
