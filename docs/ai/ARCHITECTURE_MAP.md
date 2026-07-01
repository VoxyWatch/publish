# Architecture Map

## Core Services

- `voxywatch`: Node.js portal, API, UI, settings, incidents, rollups, updates and operational health.
- `voxywatch-sniffer`: capture process for HEP/SIP/RTP ingestion.
- `voxywatch-srs`: optional SIPREC SRS, disabled by default.
- PostgreSQL + TimescaleDB: local database for packets, calls, rollups and operational data.

## Data Flow

1. SBC/probe sends HEP/SIP/RTP or SIPREC source traffic.
2. Sniffer ingests and writes packets/calls/audio segment metadata.
3. Portal serves call search, SIP flows, SIP Expert, dashboards, incidents, audio/PCAP jobs and settings.
4. Heavy jobs queue handles audio reconstruction, PCAP and DTMF extraction.
5. Rollups produce dashboard and trunk health aggregates.
6. Incident engine creates actionable system, trunk, SIP, pattern and fraud alerts.
7. SNMP exposes health to NMS through VoxyWatch private OIDs and selected standard aliases.

## Safety Boundaries

- Capture hot path must stay minimal.
- Portal must not block ingestion with heavy queries.
- Audio, PCAP and DTMF must use the heavy job queue.
- Operational health and support bundle should be O(1) snapshots.
- AI tools and the product agent must never access the customer SBC.

## Public Contracts

- API v1 must be additive within 2.x.
- `latest.json` fields used by updater must not be renamed.
- On-disk RTP segment and index formats must remain backwards compatible.
- Settings changes must be whitelisted and sanitized server-side.
