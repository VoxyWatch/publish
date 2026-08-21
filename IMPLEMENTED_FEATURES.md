# Implemented feature reference

This public reference intentionally describes customer-visible behavior rather
than internal architecture.

| Area | Customer-visible capability | Availability |
|---|---|---|
| Overview | Voice-network KPIs, configurable operational views and NOC fullscreen mode | Active |
| Calls | Search, call detail, SIP sequence, signaling findings and available media evidence | Active; evidence-dependent |
| CDRs | Historical filters, sorting, custom columns and export | Active |
| Operations | Incidents, trunk/IP health, fraud and Flash Call findings | Active or configurable |
| Configuration | Capture sources, trunks, IP directory, alerts, fraud and integrations | Role-gated |
| Reports | Templates, custom reports, charts and export | Active |
| AI | Optional chat, guided analysis and specialist workflows | Opt-in |
| MCP | Scoped access for compatible AI clients through the HTTPS portal | Off by default |
| Speech to text | Per-call transcription and export | Beta; opt-in |

VoxyWatch is observational. It does not configure, block, reroute or control the
customer's SBC. Results depend on the SIP, SDP, RTP, RTCP and catalog evidence
available to the installation.

Operational configuration remains documented in the focused guides linked from
[README.md](README.md). Detailed implementation catalogs, algorithms and
engineering history are maintained privately.
