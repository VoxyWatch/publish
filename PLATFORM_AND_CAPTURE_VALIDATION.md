# Platform and HEP Sniffer Validation

This guide defines the supported Linux/CPU matrix and the shortest reliable
end-to-end acceptance test for the native HEP sniffer. It contains no customer
addresses, credentials or captured traffic.

## Supported platform policy

- **Recommended:** Debian 12 or 13 on x86_64; Debian 13 on ARM64.
- **Also supported:** Ubuntu 22.04/24.04 LTS and Amazon Linux 2023 on x86_64 or
  ARM64.
- Other distributions require a separate compatibility review before
  installation. Similar package names are not evidence of compatibility.

Every signed release contains separate native `linux-x64` and `linux-arm64`
artifacts, SHA-256 values and GPG signatures. The installer selects the artifact
from `uname -m`; it does not run an x86 binary through QEMU on ARM.

Release 3.77.4 was acceptance-tested on a clean Debian 13 AArch64 host. The
test covered signed installation, the AArch64 ELF/process, PostgreSQL 17,
TimescaleDB, systemd services, internal HTTPS by IP, login, CLI, HEP SIP/RTP
ingestion, CDR classification, API search/detail, RTP correlation, audio
reconstruction, restart and persistence. Amazon Linux 2023 ARM64 was also
validated through the signed install/update path.

## Native HEP network contract

The default collector is:

| Traffic | Default | Required network rule |
|---|---:|---|
| HEP SIP/RTP/RTCP | UDP 9060 | Allow only approved capture-agent/SBC source IPs |
| HEP over TCP | TCP 9060 | Allow only when the sender is configured for HEP/TCP |
| Portal and remote MCP | TCP 443 | Allow intended users/management networks |
| Portal backend | TCP 3080 loopback | Do not expose; Caddy terminates HTTPS |

Additional HEP UDP ports and a dedicated RTP HEP port are optional settings.
Open them only after enabling the corresponding setting. RTP encapsulated in
HEP uses the HEP collector port; it does **not** require exposing the original
media port range to the VoxyWatch host.

An AWS Security Group, cloud firewall or host firewall can silently discard UDP
while `voxywatch-sniffer` is healthy and listening. A listener on
`0.0.0.0:9060` proves only the local bind. A remote test must also produce a
packet/CDR increase. If loopback HEP works but remote HEP does not, fix the
network rule or route; do not reinstall VoxyWatch.

Passive Mirror Capture has a different network contract: local SPAN/RSPAN needs
no listening port, ERSPAN uses IP protocol 47, and AWS Traffic Mirroring uses
VXLAN/UDP 4789. See `PASSIVE_MIRROR_CAPTURE.md`.

## End-to-end acceptance test

Use synthetic numbers and a unique Call-ID. Never replay customer SIP or audio
into a test installation.

1. Confirm the signed installed version and that the portal, sniffer, Caddy and
   PostgreSQL services are active.
2. Send an answered HEP dialog: INVITE, provisional response, 200, ACK, BYE and
   final 200.
3. Confirm all SIP messages reached `packets`, exactly one call reached `calls`,
   and the call is `answered`.
4. Send bounded RTP with the same Call-ID and SDP endpoint pair. Confirm a
   flow-keyed row reaches `rtp_packets` and call detail reports
   `rtp_available=true`.
5. Reconstruct audio and download it through the authenticated API. A successful
   test returns a non-empty `audio/wav` response.
6. Exercise rejected, busy and cancelled dialogs. An OPTIONS transaction must
   not become a call.
7. Restart only the portal, then confirm the CDR/RTP evidence persists, HTTPS
   returns 200 and recent service journals contain no new errors.

Global packet/RTP totals use bounded cached PostgreSQL/Timescale estimates and
can lag immediately after a tiny synthetic injection. Per-call detail and the
underlying rows are the authoritative immediate acceptance evidence. `ANALYZE`
may be used on a disposable validation database to refresh estimates; it is not
required for normal capture.

## RTP correlation requirements

VoxyWatch first correlates media using the SDP `c=` address and `m=` port. When
an SBC rewrites media to an endpoint that never appears in visible SDP, the HEP
sender should include HEPv3 chunk `0x0011` (Correlation ID) on RTP and RTCP with
the same SIP Call-ID. This gives exact correlation without unsafe IP/time
guessing. VoxyWatch intentionally refuses ambiguous media matches.

## Scope of the approval

A successful platform test approves the native VoxyWatch artifact and local
pipeline. It does not certify an unrelated cloud firewall, SBC exporter, mirror
configuration or customer routing policy. Those must pass the remote-ingestion
step in their own environment.
