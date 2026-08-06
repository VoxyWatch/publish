# Implemented Feature Reference

This document describes capabilities that are present in the current signed
VoxyWatch release. It complements the product-oriented
[README](https://github.com/VoxyWatch/publish/blob/main/README.md) and
[Feature Catalog](https://github.com/VoxyWatch/publish/blob/main/FEATURES.md)
with an operational map.

## Availability labels

- **Active by default:** available after installation without enabling a risky
  subsystem.
- **Configurable:** active when its capture source, credentials or thresholds
  are configured.
- **Opt-in:** deliberately disabled on a fresh installation.
- **Signal-dependent:** shown only when the required SIP, RTP, RTCP or historical
  evidence exists.

VoxyWatch is observational. Its AI, agents, detectors, MCP tools and runbooks
never configure or control the customer's SBC.

## Operator workspace

| Area | Implemented capability | Availability |
|---|---|---|
| Overview | Five essential KPIs, exact time ranges, attention queue, configurable KPI/charts/table layout, Show all and Restore defaults | Active by default |
| Investigate | Live/recent calls, combined search, call detail, SIP ladder, deterministic SIP/RTP experts, quality findings, audio and exports | Active by default; media signal-dependent |
| CDR Base | Historical PostgreSQL/TimescaleDB search, filters, sortable/custom columns and CSV export | Active by default |
| Infrastructure | Trunk status, ASR/NER/ACD/MOS/loss/PDD, reasons, baselines, drill-down and Copilot context | Active by default; quality signal-dependent |
| Fraud | Profiles, high-risk destinations, short-call/velocity/international-mix signals, simulator and Flash Call Intelligence | Configurable; Flash Calls start in Shadow |
| Incidents | Open/ack/resolved lifecycle, deduplication, evidence, timeline, diagnosis, notification and auto-recovery | Active by default; detector-specific settings apply |

## Capture and protocol handling

- HEP v1/v2/v3 over UDP and TCP for SIP, RTP, RTCP and supported LOG payloads.
- Additional configurable HEP UDP ports and capture-source labeling.
- Built-in SIPREC SRS with UDP/TLS signaling and RTP/SRTP (SDES), separate
  service, allowlist and anti-abuse limits. SIPREC is opt-in.
- Optional VoxyWatch Probe for mirrored-interface capture when a platform cannot
  send HEP or SIPREC.
- Asterisk configuration import with preview-before-merge for `chan_sip`, PJSIP,
  identifies, AORs and dial-plan trunk references.
- Working-set snapshots for fast portal recovery after restart; PostgreSQL
  remains the durable CDR/SIP source of truth.
- Scanner/noise classification prevents known probe traffic from polluting call
  KPIs without blocking network traffic.

## Per-call analysis and evidence

- RFC-aware call outcomes including answered, active, busy, declined, cancelled,
  redirect, authentication challenge/failure, server failure and no response.
- SIP ladder with transaction timing, retransmissions and clickable evidence.
- Deterministic SIP Expert for call setup, REGISTER, OPTIONS, REFER, MESSAGE,
  subscriptions and in-dialog updates.
- SDP/codec negotiation, early media, hold, session timers, forking, glare,
  routing loops, NAT/private Contact or media, T.38, SRTP policy, STIR/SHAKEN
  Identity and Q.850/Reason evidence when visible.
- RTP Expert and quality metrics: MOS estimate, jitter, loss, PDD, RTCP,
  direction correlation and one-way-audio classification.
- A deterministic call-quality score with an explanation of available and
  missing evidence.
- On-demand bounded audio reconstruction, PCAP generation and RTP-event DTMF
  extraction through the heavy-job queue.
- SIP text plus SIP Expert Markdown/JSON export.
- Anonymous per-call JSON share bundle that excludes raw SIP, RTP/audio,
  credentials, exact IPs and full telephone numbers.

VoxyWatch does not invent unavailable media metrics. A valid CDR and SIP ladder
can exist without MOS, RTP correlation or playable audio.

## Analytics and storage

- Exact-window KPIs and trend/distribution charts backed by continuous hourly
  rollups.
- Carrier, customer, country and direction attribution using IP/CIDR,
  E.164/prefix and DID catalogs.
- Per-trunk health with fixed thresholds, minimum samples, coverage gates,
  sustain/recovery and optional per-trunk auto-calibration.
- Robust seasonal baseline with 168 day-of-week/hour buckets using median and
  MAD.
- Deterministic volume/ASR forecast derived from that seasonal baseline and the
  recent level, with a bounded confidence band.
- Capacity profiling and retention/burn-rate warnings based on actual host and
  traffic measurements.
- PostgreSQL + TimescaleDB hypertables, compression, incremental rollups,
  retention and hardware-adaptive working-set limits.

## Detection and incident families

| Family | Implemented evidence | Default posture |
|---|---|---|
| SIP alarms | Configurable failure classes/codes, global and per trunk | Configurable |
| Trunk health | ASR, NER, PDD, MOS, loss, volume and coverage | Active with conservative gates |
| Seasonal patterns | Traffic spike/silence and health deviation from learned hour/day normal | Silent until history is mature |
| Fraud | New destination, high-risk growth, short-call storm, velocity and international-mix spike | Opt-in/tunable |
| Flash Calls | Originator CANCEL timing, 487, no answer/media, timing MAD and destination fan-out | Shadow by default |
| One-way audio | Change in media asymmetry versus baseline | Signal-dependent |
| Capacity | Disk, audio retention and traffic/resource profile | Active/configurable |
| Platform/capture | Sniffer, source visibility, portal heap, database, rollups and update state | Active |

The incident engine creates one active incident per deterministic fingerprint.
Seven factory runbooks cover low ASR, packet loss, capture down, one-way audio,
Flash Call patterns, fraud suspects and traffic-volume drops. Customer runbooks
can be added as JSON.

## AI and agentic functions

- Optional BYO-provider chat for OpenAI, Anthropic, Google Gemini, OpenRouter,
  OpenRouter Free, DeepSeek, Groq, Perplexity Sonar and customer-owned Ollama,
  vLLM or LM Studio servers.
- Per-user private chat history, response language, profile prompt and
  sanitized UI context.
- Shared deterministic-first Context Engine for chat, copilots, alarm summaries
  and incident investigation. It adds only an optional administrator-confirmed
  organization name/type, selects relevant product/RFC references just in time,
  and never infers an employer from email. See the
  [Context Engine guide](https://github.com/VoxyWatch/publish/blob/main/docs/ai/CONTEXT_ENGINE.md).
- Private local finding ledger with evidence hashes, recurrence and administrator
  feedback. Historical hypotheses remain advisory; fresh deterministic evidence
  always wins and no finding automatically becomes an alarm or action.
- Deterministic model routing, context/output budgets, usage/latency telemetry,
  prompt-caching support and a concurrency limiter.
- Offline-only OpenAI Batch workflow for non-interactive workloads; it is not
  used for chat, incidents or urgent investigations.
- Evidence collection remains available without an LLM.
- LLM provider credentials can come from an AES-256-GCM encrypted web store, a protected Linux/systemd credential, or provider-specific environment and `_FILE` variables. The UI never receives the secret and shows only the final four characters for web-managed keys.
- Seven agent definitions: Task Orchestrator, SIP Signaling Analyzer, Fraud
  Detection Analyst, Flash Call Analyst, Traffic Statistics Analyst, Platform
  Health Monitor and Release Update Monitor.
- Optional native Google ADK workflow sidecar, installed with the product and
  disabled by default. It executes portal-selected specialist handoffs without
  LLM tokens and returns structured findings grounded in `ev_*` evidence.
- Read-only agent context/tools, redacted traces, prompt-injection canaries and
  deterministic release evaluations.
- Provider-neutral outcome rubrics, independent deterministic grading, durable redacted session events and
  reproducible execution fingerprints, implemented locally without an external managed-agent service.
- Policy-gated decision proposals and operator feedback. High-risk actions
  require admin approval; graduation is never automatic.

No agent receives an SBC-control, shell, arbitrary SQL or arbitrary network
tool.

## Integrations and notifications

- Read-only REST API v1 with hashed scoped keys, IP allowlists, rate limits,
  OpenAPI and RFC 9457 problem responses.
- Local admin-only Swagger UI at `/api/docs`; all assets are bundled, external
  validation is disabled and request execution is intentionally unavailable.
- MCP gateway with 13 read-only evidence/setup-status tools plus one opt-in,
  merge-only initial-setup tool; API-key or OAuth/JWKS authentication, separate
  `mcp:configure`, dry-run/confirmation, official MCP SDK transport and JSON-Schema validation,
  redaction, bounds and local audit. See
  [MCP Server](MCP_SERVER.md).
- SNMP v2c/v3 with standard host-resource OIDs for CPU, RAM and disk plus the
  VoxyWatch enterprise MIB for capture and voice-service metrics; downloadable
  MIB and edge-triggered traps.
- Telegram, SMTP email and webhook notifications, including per-user delivery
  preferences and scheduled digests.
- Sanitized support bundle and AI troubleshooting context for support without
  exposing secrets or traffic content.

## Security, compliance and lifecycle

- JWT authentication, admin/operator/viewer RBAC and forced password change for
  new users.
- Mandatory managed HTTPS ingress, optional OIDC SSO and restricted Origins.
- Per-user language, light/dark theme and notification preferences; light is
  the default when no preference exists.
- PCI recording pause with API/manual/DTMF triggers and SSRC propagation;
  SIP/CDR evidence remains available.
- Selective recording scope and independent SIP/CDR/audio retention.
- Secrets masked from settings responses, support evidence and browser password
  managers.
- GPG-signed packages, SHA-256 manifest verification, rollback snapshot and
  health-gated signed updater. Minimal hosts provision the mandatory GnuPG
  verifier before release download and still fail closed if it remains unavailable.
- Hardware-bound license/free-tier enforcement plus a root-only CLI that validates signature, HWID
  and expiry before atomic activation without exposing license secrets.
- Optional Sentry error reporting plus anonymous adoption telemetry; no SIP,
  RTP, CDR, Call-ID, trunk, customer IP, settings or credentials are sent.

## Administration and readiness

- Getting Started checklist shared by Settings, `voxywatch-setup` CLI and MCP, plus the public AI configuration assistant.
- Basic and Advanced Settings views; advanced infrastructure controls remain
  available without overwhelming first-time operators.
- Platform Readiness, Operational Health, deployment status, dependency checks,
  background/heavy-job state and sanitized evidence under Diagnostics.
- Published, installed, validated and upgrade-compatible version states remain
  distinct.
- One-click update through a narrowly scoped root-owned helper when service
  control is enabled; otherwise the UI supplies the manual signed-update path.

## Deliberate exclusions

VoxyWatch does not include:

- automatic call blocking, routing or SBC configuration;
- arbitrary shell, SQL or URL-fetch tools for AI/MCP;
- cloud storage of captured SIP/RTP/CDR data;
- fabricated MOS or media conclusions when the signal is absent;
- an OAuth authorization server;
- automatic firewall, DNS or certificate changes for MCP;
- autonomous approval of high-risk agent actions.
