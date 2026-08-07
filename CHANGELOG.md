# Changelog

## [3.42.1] — 2026-08-07

### IP failures become actionable incidents
- Shared SIP host failures now create `sip_endpoint_health` incidents by default after the existing sample, breadth and persistence gates pass.
- Incidents exposes an explicit **IP failures** type filter, and the Trunks health action selects that type plus the exact IP before loading results.

### Honest trunk discovery reasons
- The discovery panel is now titled **Unattributed observed SIP traffic** instead of claiming every row is absent from the catalog.
- Each row distinguishes an endpoint missing from Trunks from a known IP:port whose dialed number matched no configured prefix or fallback route.
- Route mismatches include a bounded list of candidate trunk names, without exposing dialed numbers.

## [3.42.0] — 2026-08-07

### Hierarchical SIP endpoint health
- VoxyWatch correlates attributed commercial SIP legs at three levels: logical trunk, observed IP:port service and parent host IP.
- Shared endpoint candidates require minimum traffic, at least two affected trunks, material trunk/traffic breadth and compatible ASR, NER, 5xx, PDD or retransmission symptoms.
- Scanner and non-commercial/ignored SIP activity stay outside the calculation; signaling endpoints are not confused with RTP media endpoints.

### Parent incidents without alert storms
- Correlation starts in shadow mode: health and candidates are visible while no endpoint incident is created.
- When explicitly enabled, a sustained host condition opens one deduplicated `sip_endpoint_health|IP` parent incident. Affected trunk incidents are folded into its evidence and return automatically if the fault becomes isolated.
- Opening and recovery have independent sustained-evaluation gates. Evidence includes ports, directions, affected and healthy trunks, impact, symptoms and top SIP codes.

### Operator and AI experience
- Trunks shows a compact shared-endpoint panel with shadow/active state and a direct path to filtered incidents.
- Incident filters, bilingual titles, deterministic runbook and the live AI overview understand endpoint-level failures without requiring an LLM for detection.
- All thresholds are configurable under global trunk health; incident creation remains off until the operator validates local traffic.

## [3.41.5] — 2026-08-07

### Destination country accuracy
- A configured routing prefix is removed before E.164 country resolution. When the remaining number is plausible, its calling code is authoritative and a catalog label can no longer misclassify the destination.
- The catalog country label remains a safe fallback only when the number left after routing-prefix removal cannot be resolved as E.164.

### Exact CDR navigation
- The CDR action opens the exact Call-ID immediately and then refreshes the Calls list with the same identifier; it can no longer leave a previously selected call visible while the server-side search is pending.

### Validation
- Regression fixtures cover a `595` operator prefix followed by Mexico `52`, direct Paraguay E.164, catalog fallback, and stale-detail prevention without customer-specific logic.

## [3.41.4] — 2026-08-07

### Fixed
- A shared SIP endpoint where no dial prefix or valid directional fallback matches is now classified as `No matching trunk route`, not as an ambiguous trunk.
- Overview shows the affected IP:port and offers an `Add route` action that opens Trunks with the endpoint and direction prefilled. A prefix is suggested only from consistent bounded evidence.
- Known catalog endpoints with a missing route also appear in Trunks discovery after one commercial call; scanner protections remain unchanged for completely unknown sockets.
- Investigate and CDR use the same description. `Ambiguous trunk` is now reserved for genuine ties between applicable rules.

### Validation
- Read-only UCTel evidence for `104.152.200.149:5060` and `10.220.1.162:5060` is correctly identified as missing routes/prefixes without modifying the customer server or adding customer-specific code.

## [3.41.3] — 2026-08-07

### Fixed
- A prefixless trunk now acts as the explicit fallback for a shared SIP endpoint, but only when no specific dial prefix matches.
- Multiple equal fallback routes remain ambiguous, preserving fail-closed behavior instead of choosing by import order.
- Legacy CDRs without signaling legs now include the affected IP:port in the ambiguity label.

### Validation
- Against the read-only UCTel catalog, traffic on `10.206.4.66:5060` with the unmatched `159302…` route resolves from 84 endpoint candidates to its single configured `OTHER` fallback without customer-specific code.

## [3.41.2] — 2026-08-07

### Fixed
- SIP messages carrying a Call-ID without a proven INVITE remain searchable evidence but no longer enter Overview, commercial KPIs, trunk health/discovery/rollups, AI context or voice SNMP metrics.
- Only a `200 OK` explicitly tied to an INVITE CSeq can mark a call answered, preventing orphan responses from creating false active calls.
- Overview now projects inbound and outbound external legs independently for transit sessions while global KPIs continue to count the session once.
- A genuine final trunk tie now identifies the affected IP:port instead of showing an anonymous ambiguity. VoxyWatch still fails closed rather than inventing a carrier.

### Migration
- Versioned global, minute and trunk rollups converge automatically under the corrected commercial-call boundary. Historical SIP/CDR evidence is preserved.

## [3.41.1] — 2026-08-07

### Fixed
- Trunk discovery no longer offers one-off sockets or scanner-tagged traffic as carrier candidates.
- High fan-out IPs whose source ports are mostly single observations are suppressed as `port_spray`, preventing SIP scanning or attack traffic from becoming an Add trunk suggestion.
- Legitimate multi-service SIP peers remain eligible once each IP:port has stable repeated evidence. Capture exclusions continue to preserve historical evidence while preventing future matching traffic from being stored.

## [3.41.0] — 2026-08-06

### SIP and commercial accuracy
- Final 3xx responses, including `302 Moved Temporarily`, are classified as rejected calls while preserving the SIP code for investigation.
- `Ignored` is now strictly limited to an INVITE, optionally followed by CANCEL, with no SIP response observed.
- Ignored attempts remain searchable in CDR and Investigate but no longer affect volume, ASR/NER, concurrency, trunk health/discovery/rollups, AI operational context or voice SNMP KPIs.

### Visibility
- Overview adds an optional hourly unanswered-SIP activity chart. It is an investigation signal, not an automatic attack verdict, because asymmetric capture or an ACL can produce the same evidence.
- Global, minute and trunk rollups automatically migrate to the corrected semantics.

## [3.40.0] — 2026-08-06

### Added — turn unknown traffic into a configured trunk
- Trunks now lists recently observed external SIP endpoints missing from the catalog, including IP:port, direction and call volume. One click opens a prefilled trunk form.
- Overview shows the real unattributed endpoint instead of a generic warning and links directly to Add trunk.
- Administrators can ignore an exact IP or CIDR range in analytics only, or explicitly prevent matching future packets from being captured.

### Safety
- Capture exclusions require confirmation, never delete historical evidence and reload without restarting services. VoxyWatch does not guess carrier names or turn full subscriber numbers into trunk prefixes.

## [3.39.3] — 2026-08-06

### Fixed
- Completed the observed-direction integration for multi-leg trunk attribution. The call projection now forwards each leg's inbound/outbound direction all the way into the resolver; 3.39.2 contained the resolver behavior but omitted this field at the final integration boundary.

### Reliability
- Added a regression covering both internal handoffs so the live CDR path cannot diverge from isolated resolver tests again.

## [3.39.2] — 2026-08-06

### Fixed
- Multi-leg trunk attribution now follows the direction already established by IP Directory. Outbound legs resolve the external destination and inbound legs resolve the external source, preventing shared local endpoint rules from producing false `Ambiguous trunk` results.

### Accuracy and safety
- Longest-prefix and priority resolution remain authoritative on the observed external endpoint. Genuine final ties remain visible as ambiguous, and legacy calls without a reliable leg direction retain fail-closed compatibility.

## [3.39.1] — 2026-08-06

### Fixed
- Trunk catalogs replaced through CLI, MCP-assisted setup or another atomic writer are now detected by the running portal within one second. Trunk attribution refreshes automatically instead of retaining stale `Ambiguous trunk` results until restart.

### Safety
- The check is bounded to one filesystem revision read per second, stays outside packet capture and does not rewrite CDR data or require a database migration.

## [3.39.0] — 2026-08-06

### Added
- Calls crossing a B2BUA remain one investigation session while exposing independent ingress and egress signaling legs, outcomes and trunk attribution.
- CDR Base now shows session direction, ingress trunk and egress trunk. Investigate shows the complete route and labels every SIP message by leg.
- Duplicate trunk rules and duplicate internal SBC endpoints are blocked before saving or importing. Existing conflicts appear as a critical notification with direct repair guidance.

### Accuracy and safety
- Global totals count each logical call once, while per-trunk health and hourly metrics count the leg actually observed on that trunk.
- VoxyWatch never chooses arbitrarily between trunks with the same canonical IP:port and dial prefix. An omitted SIP port means 5060 in both Trunks and IP Directory.
- A bounded background enrichment updates retained calls without delaying capture.

## [3.38.0] — 2026-08-06

### Changed — Web Access belongs in Security
- Fresh installation no longer asks for a public DNS name or certificate mode. It starts on the detected private IP/hostname with Caddy's internal CA; admins configure public DNS later from Settings → Web Access.
- General no longer shows fixed product/port facts. Web Access now keeps authentication/session, managed HTTPS URL and hostname, certificate state, OIDC SSO and PCI controls together under Security.

### Security and reliability
- Hostname changes run through a fixed root-owned, polkit-scoped helper that validates the request, refuses unmanaged Caddy configuration and rolls back on failure.
- Fixed malformed Settings markup that hid SSO/HTTPS content and could hide HEP controls. Fixed the legacy custom certificate upload request contract.

## [3.37.1] — 2026-08-06

### Process reliability
- Release validation now detects installer changes and explicitly requires two demo updater passes. This verifies behavior from the newly installed root-owned script rather than assuming the first pass used it.

## [3.37.0] — 2026-08-06

### Changed — clearer first installation
- Fresh interactive installs no longer ask for or advertise the internal 3080 backend port. Users always enter through managed HTTPS on port 443; `--port` remains available for advanced automation.
- HTTPS setup is now one explicit decision without a countdown. Public mode explains DNS and TCP 80/443 requirements and accepts only a fully-qualified domain name. Private IP/hostname mode explains TCP 443 and the one-time Caddy root trust requirement.
- Portal service control is enabled by default without an unnecessary prompt; an advanced CLI opt-out remains available.

### Security
- Removed obsolete portal permissions for timezone, NTP, DNS, `systemd-timesyncd` and resolver files. The scoped grant now covers only VoxyWatch services and signed updates.

## [3.36.0] — 2026-08-06

### Added — named endpoints throughout call investigation
- Call cards, Investigate, the interactive SIP sequence diagram, SIP message table/inspector/export, Overview IP filters and CDRs now show the resolved trunk or internal service name together with the IP:port.
- Trunks sharing an endpoint are resolved with the complete call context, including longest dial-prefix and priority.

### Safety
- SIP responses reuse the call-level attribution instead of being misclassified from their reversed packet direction. Ambiguous matches remain unnamed and the technical socket stays visible.

## [3.35.2] — 2026-08-06

### Fixed — IP-owned traffic direction
- Overview now treats traffic sourced by an IP registered in IP Directory as outbound and traffic terminating on that IP as inbound, independently of its SIP service port.
- IP+port remains exact for labels and carrier identity, so the fix restores direction without merging services or guessing an ambiguous trunk.

## [3.35.1] — 2026-08-06

### Fixed — external-trunk selector feedback
- Selecting Outbound, All external or Country now moves the active highlight to the chosen view instead of visually leaving Inbound selected.
- A selection made while Overview data is loading is retained and applied as soon as data becomes available.

## [3.35.0] — 2026-08-06

### Changed — external-trunk Overview
- The lower Overview now shows named external trunks instead of treating internal SBC/IP Directory labels as clients or providers.
- Inbound and outbound views follow the observed carrier leg; explicitly internal/on-net trunks are excluded from commercial rows.
- Ambiguous and unattributed external traffic remains visible as a catalog issue that administrators can correct.

### Reliability
- Historical trunk aggregation now preserves SIP ports stored in each CDR, so carriers sharing one IP on different ports remain separated. Legacy CDRs without ports keep the compatible 5060 default.

## [3.34.1] — 2026-08-06

### Fixed — isolated Internal IP imports
- Choosing an Internal IP CSV or JSON file no longer writes immediately. The portal shows the exact filename and a read-only merged-count preview, then requires a separate Apply action.
- Internal IP and Trunks imports keep independent inputs and state; late reads from an older selection cannot replace the newest file.
- After a successful import, the visible IP Directory, its ETag and its in-memory labels refresh through one canonical path instead of leaving stale rows on screen.

## [3.34.0] — 2026-08-06

### Added — SIP endpoint-aware trunks and internal IPs
- Trunks and the internal IP Directory can now distinguish multiple services on the same SBC IP by SIP port, such as `10.0.0.1:5060` and `10.0.0.1:5070`.
- Omitting the port means SIP port 5060, preserving a simple default while preventing that rule from matching a different port.
- Port-aware matching works together with direction, CIDR or dotted-IP specificity, dialed-number prefixes and trunk priority.

### Reliability
- Live calls and CDRs retain caller, callee and attributed carrier ports so labels and trunk assignment use the observed SIP endpoint.
- Asterisk imports preserve nonstandard ports and normalize explicit 5060 to the compatible default form.
- Invalid endpoints and ports fail closed instead of being silently ignored or converted to 5060.

## [3.33.0] — 2026-08-06

### Added — conflict-safe shared-IP trunk catalogs
- Trunk attribution now evaluates every shared-IP candidate by observed direction, IP specificity, longest dialed-number prefix and an optional bounded priority.
- CSV, JSON and Asterisk imports show a no-write preflight with shared IPs, ambiguous rules and entries without an IP before an administrator applies the catalog.
- Monitoring can switch between trunks active in the current window and all configured trunks.

### Reliability
- Import order no longer silently assigns a shared IP to the last trunk. Final ties are reported as `Ambiguous trunk` in CDRs and charts.
- Commercial direction remains a preference with an explicit B2BUA fallback marker, preserving compatibility when the observed SIP leg is reversed.

## [3.32.4] — 2026-08-06

### Fixed — Overview loads immediately after authentication
- Protected dashboard requests now wait until the portal has validated the session, preventing an empty Overview immediately after sign-in.
- First login with a required password change hydrates the active view without requiring a search or a manual Refresh click.
- Session restoration is idempotent, and logout closes the protected-data gate before returning to the login screen.

### Reliability
- Regression contracts cover pre-auth suppression, normal session restore, forced-password-change login, local no-auth mode, single initial hydration and logout cleanup.

## [3.32.3] — 2026-08-05

### Fixed — reliable DB-backed audio reconstruction
- Calls whose RTP does not carry a Call-ID can now reconstruct audio from database storage when their captured RTP matches a persisted SDP destination IP and port within the call window.
- New RTP blobs contain one destination flow and are explicitly marked as safely correlated. Older rows remain untrusted, preventing audio from concurrent calls from being selected.
- Investigate no longer enables reconstruction merely because unrelated RTP exists in the same time window.
- Existing RTP spools remain upgrade-safe through bounded streaming conversion.

### Compatibility and safety
- No SBC configuration or traffic handling changes are required. Existing CDRs and RTP remain readable, but historical rows without safe flow evidence continue to fail closed rather than risk cross-call audio.

## [3.32.2] — 2026-08-05

### Fixed — bounded and privacy-safe audio reconstruction
- Calls without correlated SSRCs no longer trigger an ambiguous full PostgreSQL RTP-window scan that could exhaust the media job memory limit or select another concurrent call's audio. They return the normal no-audio result unless a bounded segment index identifies at most two candidates.
- If local RTP segments already provide correlated audio and PostgreSQL becomes unavailable, reconstruction keeps only the complete local packets and discards partial SQL rows. Without local media, the database failure remains explicit.
- Media failures sent to logs and Sentry contain only a sanitized category, exit code and codec. Subprocess arguments, Call-IDs, IP addresses, raw stderr and database messages are excluded.

### Reliability
- Release invariants now execute deterministic regressions for unknown SSRCs, SQL failure fallback, partial-row rollback and media telemetry redaction.

## [3.32.1] — 2026-08-05

### Fixed — controlled HTTPS migration recognizes early VoxyWatch proxies
- The installer recognizes the exact early VoxyWatch Caddy configuration consisting only of the requested host and loopback reverse proxy, even when it predates the ownership marker.
- Recognition stays fail-closed: a different host, port or any additional directive is treated as customer-owned and is never overwritten.
- Controlled migrations from legacy ingress to managed public/internal HTTPS can now complete without weakening unrelated Caddy protection.

## [3.32.0] — 2026-08-05

### Fixed — secure readiness and configuration writes
- Platform readiness reports an HTTP backend exposed beyond loopback as a critical security condition and directs the operator to managed public or internal HTTPS.
- SNMP health is included in Operational Health and the privacy-safe Support Bundle with sanitized error codes, timestamps and request/rejection counters; credentials, usernames and source addresses are never emitted.
- Trunk and IP-label replacement writes publish stable ETags. Removing existing entries requires explicit replace-all confirmation and the current revision, preventing empty/partial payload loss and stale concurrent overwrites.

### Compatibility
- Existing trunk and IP-label GET response bodies are unchanged; revisions are additive HTTP headers.
- Legacy HTTPS installations remain reachable during normal updates, but Diagnostics marks a non-loopback backend critical until a controlled migration.
- User update/delete routes continue using `username` as the unambiguous public resource key.

## [3.31.1] — 2026-08-04

### Fixed — SNMP settings now follow the selected security version
- Common listener settings stay visible while v2c shows Community, v3 shows USM security, and `v2c + v3` shows both authentication cards.
- SNMPv3 progressively shows auth and privacy controls according to `authPriv`, `authNoPriv` or `noAuthNoPriv`, without erasing stored values.
- Fixed a CSS priority conflict that kept the SNMPv3 card visible even when v2c was selected.

### Improved
- Bind address visibly defaults to `0.0.0.0`; concise help explains interface exposure and that an empty NMS allowlist accepts any source.

## [3.31.0] — 2026-08-04

### Added — complete server SNMP telemetry
- Added disk read/write throughput, read/write IOPS and cumulative bytes; network RX/TX bandwidth and cumulative bytes; swap usage and exact root-filesystem capacity.
- The generated MIB, CSV, Zabbix and JSON exports now contain 47 private scalar OIDs with units and scaling metadata.
- Standard SNMPv2-MIB and HOST-RESOURCES-MIB monitoring remains available for uptime, CPU, RAM and storage.

### Improved
- Base OID is now a visible, copyable read-only reference. Existing legacy trees are preserved, but attempted portal/API edits are ignored.
- HOST-RESOURCES-MIB virtual memory now reports swap/paged storage rather than duplicating physical RAM.
- Counter64 values use correct ASN.1 encoding and are covered by a permanent live UDP test.

## [3.30.3] — 2026-08-04

### Added — portable SNMP exports for common monitoring systems
- SNMP Settings now downloads an English SMIv2 MIB suitable for PRTG MIB Importer and standard MIB browsers.
- Administrators can also export a scalar OID CSV, a Zabbix 7.4 YAML template or a versioned JSON catalog from the same compact selector.
- Every export follows the configured enterprise base OID and documents the required `.0` scalar instance suffix.

### Improved
- The SNMP status and download area no longer mixes Spanish text into the default English interface.
- The MIB now includes module identity, object/notification groups and a compliance statement, validated with an independent SMI parser.

## [3.30.2] — 2026-08-04

### Changed — SNMP settings are practical to copy into an NMS
- Administrators now see the configured v2c/trap communities and SNMPv3 USM keys as plain text in the SNMP editor.
- Read-only viewer/operator sessions continue to receive masked values, and unrelated credentials remain protected.
- Save round-trips the visible values, applies community/version changes immediately and allows an administrator to clear obsolete SNMPv3 keys.

### Validation
- Security projections, SNMP standard OIDs, Settings UI, signed-update invariants and remote SNMP wire behavior were validated.

## [3.30.1] — 2026-08-03

### Fixed — Overview no longer appears empty while loading
- KPIs and trend charts now paint from small rollup endpoints without waiting for the CDR detail sample.
- Initial detail loading drops from 20,000 CDRs to 1,000; IP/client searches and the optional detail table expand to a bounded 5,000 only when needed.
- Failed HTTP responses no longer become false zero dashboards. The portal keeps the last good sample, retries once and shows an accessible loading/error state.

## [3.30.0] — 2026-08-02

### Added — native agent outcomes and durable sessions
- Agentic investigations now use provider-neutral outcome contracts and an independent, token-free grader for grounding, specialist coverage, safe non-execution and bounded results.
- Each run records a local redacted lifecycle and a reproducible fingerprint of the VoxyWatch, agent, prompt, tool-catalog and outcome-catalog versions.
- Administrators can inspect bounded session history and the outcome pass rate from the API and Diagnostics.

### Privacy and compatibility
- The feature adds no managed-agent service, external port, credential, dependency, scheduler or common permission layer.
- The local 0600 store keeps only bounded metadata; it excludes tasks, prompts, raw findings, SIP/RTP, phone numbers, IP addresses, Call-IDs and credentials. A storage failure cannot stop an investigation.

## [3.29.1] — 2026-08-02

### Security — current validated Caddy release
- Updated the controlled fresh-install Caddy pin from 2.11.3 to 2.11.4 after the live demo inventory and Caddy's official release page confirmed the newer security-patch release.
- Normal VoxyWatch updates still preserve the customer's installed Caddy version and do not apply this external dependency change automatically.

## [3.29.0] — 2026-08-02

### Added — HTTPS-only deployments
- Fresh installations now offer automatic public HTTPS for a DNS domain or private HTTPS backed by Caddy's internal CA, both on TCP 443.
- Managed installations keep the VoxyWatch backend on loopback and use Caddy for certificates, renewal, compression and HTTP-to-HTTPS redirects.
- General, Security and Diagnostics now report the effective secure entry point without exposing an HTTPS disable switch or internal listener setting.

### Upgrade safety
- Normal signed updates preserve the installed Caddy package and configuration. Adopting or changing managed HTTPS on an older installation requires the explicit controlled dependency refresh path.
- The installer pins validated Caddy 2.11.3, refuses to overwrite unrelated Caddy configuration and restores the previous proxy configuration if an update fails.

## [3.28.0] — 2026-08-02

### Changed — telemetry belongs in Diagnostics
- Moved the complete Diagnostics & Telemetry card from General to Diagnostics, including Sentry/adoption consent, privacy details, network destinations and the disabled-state notice.
- Diagnostics now provides its own save action for this setting while preserving the existing value, permissions and immediate runtime behavior.

## [3.27.1] — 2026-08-02

### Fixed — system diagnostics visible to read-only roles
- Moved the port, timezone, NTP and DNS card outside the admin-only diagnostics container so viewers and demo mode can see it without gaining access to sensitive settings or operational diagnostics.

## [3.27.0] — 2026-08-02

### Changed — system-owned portal configuration
- The browser identity is now consistently `VoxyWatch Agentic NOC`; per-installation tab-title editing was removed.
- General Settings shows the effective HTTP port used by the running portal, including a custom `PORT` value.
- Host timezone, NTP and DNS moved to Diagnostics as live read-only troubleshooting data. VoxyWatch no longer stores or changes these operating-system settings.
- Call timestamps and time-based analytics now follow the host timezone instead of a fixed fallback timezone.

## [3.26.1] — 2026-08-02

### Fixed — consistent form fields in light and dark themes
- Normalized all Settings inputs, selects and text areas to the same theme-aware background, text and border treatment, including previously browser-default SNMP and agent-runtime number fields.
- Profile fields no longer use hard-coded dark colors and now follow each user's light or dark theme for normal, focused, placeholder and disabled states.
- Updated the stylesheet cache identifier so existing browsers receive the correction immediately after upgrading.

## [3.26.0] — 2026-08-02

### Added — grounded, organization-aware AI context
- VoxyWatch now gives its AI copilots consistent product, role and optional organization context while preserving bounded server-side chat history.
- General Settings adds only a compact optional organization name and type selector; detailed AI preferences remain in each user's existing profile.
- Relevant VoxyWatch documentation and VoIP RFC references are selected automatically for each task.
- A private local finding ledger remembers recurring incident hypotheses, supporting evidence and administrator review without storing raw SIP, audio or credentials.

### Privacy and reliability
- Personal names and email addresses are not sent as AI context, and VoxyWatch never infers an employer from an email domain.
- Fresh deterministic evidence remains authoritative over model memory and historical findings, across chat, alarms, trunk and overview copilots, offline reviews and incident investigations.

## [3.25.0] — 2026-08-02

### Changed — clearer LLM setup
- Simplified **Custom server** for customer-owned Ollama, vLLM and LM Studio endpoints and removed unreliable model-catalog controls.
- Added Groq as a first-class provider with secure credentials, live discovery, chat and agent tools.
- Settings now identifies exact environment variables and protected Linux credential files, with safe setup instructions.
- Removed the speculative Token volume preview; measured token usage remains available.

## [3.24.0] — 2026-08-02

### Added — unified initial setup for Settings, CLI and MCP
- Added a dedicated **AI connections** Settings page and state-driven Getting Started integration.
- Added `voxywatch-setup` status, validate and root-only apply commands using stdin.
- Added MCP setup status plus opt-in, merge-only LLM/trunk/IP-label configuration with `mcp:configure`, dry-run and confirmation.

### Security
- MCP never accepts portal passwords or LLM credentials, remains off for configuration by default, never deletes catalogs or touches capture/SBC behavior, and audits without arguments or content.

## [3.23.1] — 2026-08-02

### Fixed — current recommended model catalogs
- **Show recommended models** now replaces the previous list and selection completely, instead of silently retaining a stale model.
- OpenAI presets now expose the current GPT-5.6 family: Luna, Terra and Sol.
- Anthropic presets now expose Haiku 4.5, Sonnet 5, Opus 5 and Fable 5.

## [3.23.0] — 2026-08-02

### Added — OpenRouter Free and native DeepSeek
- Added **OpenRouter Free** as a dedicated provider option. It reuses the normal OpenRouter credential and fixes the model to `openrouter/free`, so routing cannot silently select a paid model.
- Added native DeepSeek configuration, secure credential sources, authenticated model discovery, chat and agent tool support, with current V4 Flash and V4 Pro presets.
- Added English-first and Spanish UI guidance plus regression coverage for provider switching and shared-credential handling.

## [3.22.0] — 2026-08-02

### Added — model selection before credentials
- Administrators can choose conservative provider presets before adding a key; presets are explicitly unverified and never claim account access.
- After credentials are configured, VoxyWatch loads the provider-authorized catalog. OpenRouter retains public discovery and keyless Custom endpoints remain supported.

### Fixed
- Missing or rejected credentials now produce English/Spanish UI guidance instead of a Spanish-only backend message.
- The first visible choice now populates the saved model field, credential testing is distinct from catalog browsing, and robotics-specialized models are excluded from the NOC list.

## [3.21.1] — 2026-08-02

### Fixed — reliable first upgrade for the ADK workflow
- The established agentic runtime now contains an embedded native ADK workflow fallback, so an older installer that does not yet recognize the new module filename cannot disable native ADK during the first signed upgrade.
- Clean installs and subsequent updates still receive the separate workflow module; capture, portal availability and deterministic fallback are unchanged.
- Added a release regression test for the exact old-installer transition observed on the public demo.

## [3.21.0] — 2026-08-02

### Added — official MCP, native ADK workflow and local API documentation
- The remote MCP endpoint now uses the official Model Context Protocol TypeScript SDK while retaining VoxyWatch scopes, redaction, bounded results, opaque call references and content-free audit.
- The optional loopback sidecar now runs portal-selected specialist handoffs as a native, token-free Google ADK workflow with verifiable evidence citations and no action executor.
- MCP tool arguments and agentic analysis requests now use compile-once JSON Schema validation with errors that never echo submitted values.
- Administrators can browse the bundled OpenAPI contract at `/api/docs`; Swagger UI uses local assets, disables its online validator and cannot execute requests.
- Heplify remote probes remain an evaluated future option and are not installed or required by this release.

## [3.20.6] — 2026-08-02

### Changed — controlled external dependencies
- Normal signed updates now preserve installed OS, PostgreSQL, TimescaleDB and isolated Python dependency versions while continuing versioned VoxyWatch schema migrations.
- Added an explicit maintenance-only dependency refresh constrained to the installed PostgreSQL major, plus exact Google ADK 2.1.0 and pylibsrtp 1.0.0 locks.
- Added a signed dependency manifest and removed automatic Python telemetry installation from native package updates.

## [3.20.5] — 2026-08-02

### Improved — safer internal modularity
- Separated pure SIP/RTP call presentation from the portal server without changing capture, correlation, storage or public APIs.
- Separated early browser authentication and disclosure controls into a small ordered shell, reducing the main frontend bundle's responsibilities.
- Added parity, packaging and first-update guards so the new asset works both on clean installs and signed upgrades from older installers.

## [3.20.4] — 2026-08-02

### Changed — careful Express 5 migration
- Upgraded the portal HTTP framework from Express 4.22 to Express 5.2.1 without changing public routes or the capture path.
- Preserved controlled empty-body handling, pinned scalar query parsing and adapted startup bind-error handling.
- Added migration guards for every portal route, removed APIs, rejected async handlers and occupied-port startup failures.

## [3.20.3] — 2026-08-02

### Improved — reproducible functional and protocol validation
- Added a real-browser public-demo audit for primary views, roles, Settings, Investigate, mobile layout, SIP details, network/console health and optional live AI replies.
- Added wire-level validators for standard/private SNMP OIDs and the Google ADK sidecar.
- The local MCP bridge now proves authenticated stdio-to-HTTP forwarding and bounded timeout recovery.
- PostgreSQL integration now requires the incident engine instead of allowing an unavailable database to look successful.
- Updated compatible Sentry, PostgreSQL client and JavaScript parser dependencies; the production dependency audit remains clear.

## [3.20.2] — 2026-08-02

### Fixed — role-clean update checks
- Viewer and demo sessions no longer call the admin-only update discovery endpoint on page load, hourly polling or Diagnostics.
- Administrators retain manual and scheduled release checks after authentication.

## [3.20.1] — 2026-08-02

### Fixed — complete mobile Investigate and cleaner viewer sessions
- Investigate now stacks captured sessions and call analysis on phones, keeping the full workflow within the viewport.
- The closed SIP drawer, header telemetry and navigation no longer widen the mobile page.
- Demo/viewer sessions avoid admin-only status requests; administrator telemetry remains available after authentication.
- Release publishing now targets the source branch explicitly and reports safe failure categories.

### Added — repeatable full functional audit
- Added a release-candidate audit matrix for roles, telecom workflows, AI, desktop/mobile UI, security, dependencies and signed deployment.

## [3.20.0] — 2026-08-02

### Added — reusable progressive-disclosure controls
- Investigate can collapse its session list into a 44 px rail with an always-visible restore control, giving the selected call more room.
- Audio/RTP Expert, SIP Expert, SIP message details and equivalent advanced sections share one accessible expand/collapse style.
- Settings Advanced now expands and collapses from the same control, while Flash Call, trunk alerts, health thresholds, per-trunk overrides and the glossary reuse the canonical pattern.
- Controls remain English-first, switch to Spanish with the user language and expose accurate accessible names and states.

## [3.19.7] — 2026-08-02

### Fixed — accurate and understandable SIP retransmissions
- Normal SIP responses no longer inflate the retransmission counter merely because they share the request CSeq.
- Transaction identity now includes request method, CSeq and network direction, preventing B2BUA legs from being merged.
- Severity is proportional: 1–2 informational, 3–5 warning and 6+ critical; Investigate explains the metric in English or Spanish.

## [3.19.6] — 2026-08-02

### Changed — progressive disclosure in Investigate
- Audio/RTP Expert, SIP Expert and the detailed SIP message table are collapsed by default, keeping the essential call data and SIP arrow ladder immediately visible.
- Advanced sections remain one click away; the SIP Expert action opens its analysis explicitly.
- The full header Call-ID now wraps across lines instead of being shortened with an ellipsis.

## [3.19.5] — 2026-08-02

### Fixed — license activation no longer returns to a stale duplicate blocker
- Successful web activation now reconciles capacity before responding, so the previous Free Tier block cannot survive for another three minutes.
- Capacity limits keep the canonical portal shell available and use its single Free Tier/License flow; the blue recovery page is reserved for expired, invalid or wrong-HWID licenses.
- Old `/blocked.html` tabs redirect to the portal once the hard failure is gone, preventing the frozen `Checking license status…` / empty-HWID state caused by the normal portal CSP.

## [3.19.4] — 2026-08-01

### Added — trial-license path in the free-tier limit dialog
- The free-tier limit dialog now displays the server Hardware ID with a copy button, using the existing license-status response without widening data exposure.
- A bilingual callout invites evaluators to request a full trial license at `support@voxywatch.com`.
- HWID copy works through the secure Clipboard API and includes a fallback for direct HTTP installations.

## [3.19.3] — 2026-08-01

### Fixed — complete English-first interface and localized API errors
- Static HTML, dynamic settings/agent/free-tier messages and data counters now start in English and switch fully to Spanish per user, without mixed-language flashes.
- API errors carry stable machine codes and return English by default while preserving detailed Spanish for users who select Spanish.
- Executable guards now synchronize HTML defaults, validate i18n markers and reject visible Spanish literals outside the translation system.

## [3.19.2] — 2026-08-01

### Fixed — capacity warning follows the user's language
- The live free-tier capacity warning now starts in English and switches immediately to Spanish only when selected by that user.
- Server-provided capacity values are safely escaped, and a regression test prevents fixed Spanish text from returning.

## [3.19.1] — 2026-08-01

### Fixed — free-plan notices follow the user's language
- The usage banner and concurrent-limit dialog now start in English and switch completely to Spanish when
  selected, including actions, accessible labels and the dynamic reason containing the plan limit.
- A regression test prevents Spanish literals from returning to the English-first free-plan components.

## [3.19.0] — 2026-08-01

### Added — secure, customer-controlled LLM credentials
- AI Settings now supports an AES-256-GCM encrypted VoxyWatch store, a protected Linux/systemd
  credential, or provider-specific environment and `_FILE` variables with explicit fail-closed selection.
- Web-managed keys are removed from normal settings and only their final four characters return to the
  browser. Existing plaintext settings migrate automatically without exposing the value.
- New `voxywatch-ai-key` CLI reads secrets only from stdin, selects the provider/source and restarts only
  the portal. Gemini credentials now use the `x-goog-api-key` header instead of request URLs.

## [3.18.1] — 2026-08-01

### Fixed — license CLI available on the first upgrade hop
- The canonical entrypoint now lives in the binary every historical installer already replaces:
  `/opt/voxywatch/voxywatch-portal license install …`, so it works on the first signed upgrade.
- `voxywatch-license` remains a convenience alias once the current installer has been able to create it.
- Release tooling executes the extracted binary's CLI before publication, preventing documentation of
  a command that is not yet reachable after a direct upgrade from an older version.

## [3.18.0] — 2026-08-01

### Added — secure command-line product license activation
- New `sudo voxywatch-license install /path/license.key` and `--stdin` mode activate a license without
  portal access or accepting license material as a process-visible argument.
- The root-only CLI bounds input, reuses RSA/HWID/expiry validation, atomically writes mode `0640`
  `root:voxywatch` and restarts only the portal; the sniffer remains uninterrupted.
- A failed restart restores the previous license, invalid input never changes disk, and GUI uploads now
  validate before writing. The package includes the command, upgrade compatibility and a complete guide.

## [3.17.8] — 2026-08-01

### Improved — VoxyWatch heartbeat identity
- The interactive splash now opens with a cardiac-monitor mark: an ECG trace and VoxyWatch name
  enclosed in a terminal frame with rounded corners, followed by the full wordmark.
- The design remains readable within 78 columns, adds no dependencies and leaves the compact
  systemd, CI and non-TTY updater heading unchanged.
- Its visual regression requires both rounded edges, the heartbeat trace, branding, width and preflight order.

## [3.17.7] — 2026-08-01

### Changed — every install offers Service Control as Yes again
- Reinstalls and updates no longer inherit a previous decline: every run selects Service Control
  `yes` by default, including non-TTY updater executions.
- `n` and `--service-control no` still disable it for the current run; the next reinstall/update
  starts from Yes again to keep frequent portal releases straightforward.
- The installer notice now explains that scope and a regression prevents persisted `disabled` state returning.

## [3.17.6] — 2026-08-01

### Changed — Service Control enabled by default
- Fresh installs now select Service Control `yes` in both interactive terminals and unattended
  non-TTY runs; pressing Enter or letting the countdown expire also accepts it.
- An explicit decline and a persisted `disabled` preference still take precedence, so an update
  never re-enables permissions that an administrator revoked.
- An executable regression covers the default and every precedence path before release.

## [3.17.5] — 2026-08-01

### Improved — a distinctive installer welcome
- Interactive installs now open with a VoxyWatch ASCII splash, radio-signal mark and product tagline,
  without requiring figlet, tput or any additional package.
- Timers, CI and non-TTY updates retain a compact heading to keep captured logs readable.
- An executable regression covers both modes, safe artwork width and preflight placement while the
  signed trust chain remains unchanged.

## [3.17.4] — 2026-08-01

### Fixed — minimal-host installation without preinstalled GnuPG
- The installer detects a missing `gpg` before fetching release metadata or downloading the package,
  and provisions the mandatory verifier through apt, dnf or yum.
- Unsupported package managers, repository failures or a still-missing executable abort fail-closed;
  SHA-256, the embedded vendor key and the detached GPG signature remain mandatory.
- An executable regression covers apt/dnf/yum success and failure paths plus pre-download ordering.

## [3.17.3] — 2026-07-28

### Documentation — public capabilities reconciled with the runtime
- `IMPLEMENTED_FEATURES.md` maps shipped functions and labels each area Active, Configurable,
  Opt-in or Signal-dependent, with explicit exclusions.
- README and Features now cover Asterisk import, DTMF, anonymous call sharing, Flash Calls,
  seven agents and seven runbooks, and describe the actual deterministic seasonal forecast.
- Release gates derive the 12-tool MCP, 7-agent and 7-runbook catalogs from code and require the
  reference in build, installed documentation and GitHub.

## [3.17.2] — 2026-07-28

### Fixed — operational guides install on the first upgrade
- Flash Call and MCP guides also travel through the documentation path recognized by older
  installers, so a direct signed upgrade installs them without requiring a second update.
- Package and regression gates now require the backward-compatible documentation paths.

## [3.17.1] — 2026-07-28

### Documentation — adoption guides for Flash Call Detection and MCP
- A new Flash Call guide covers SIP prerequisites, modes, every default threshold, evidence
  interpretation, safe simulation, false-positive tuning, incidents, privacy and limitations.
- The MCP guide now documents the 12 live read-only tools, scopes, redaction, OAuth/API-key
  authentication, local and remote clients, network exposure, rollout and troubleshooting.
- README and Features link both guides, and signed packages install local copies for operators.

## [3.17.0] — 2026-07-28

### Added — operational and explainable Flash Call Intelligence
- Alerting mode turns only sustained high-confidence patterns into deduplicated, recoverable incidents
  through existing notification channels, without blocking traffic or controlling the SBC.
- The Fraud view shows probable volume, deterministic score, cancel timing/MAD, destination fan-out and
  configurable estimated displaced A2P value, with advanced thresholds collapsed by default.
- A dedicated read-only specialist receives aggregate evidence with hashed source identifiers; AI is not
  involved in detection, scoring, incidents or estimation.
- A read-only synthetic test validates the detector without inserting CDRs or creating incidents.

## [3.16.0] — 2026-07-28

### Added — passive flash-call detection in shadow mode
- SIP correlation now records normalized origin-cancel timing and `487` evidence without retaining
  raw signaling.
- A deterministic on-box detector measures repeated cancel timing, low variance, destination fan-out,
  unanswered calls and absence of media without using AI.
- The feature starts in shadow mode: it observes bounded in-memory evidence but does not alert, block
  traffic or control the SBC.

All notable changes to VoxyWatch are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [3.15.2] — 2026-07-28

### Fixed — AI chat responds again
- `/api/ai/chat` now invokes the context-limiter alias that is actually imported. The previous
  `limitMessages` reference raised a `ReferenceError` before contacting the configured provider.
- A wiring regression now binds the endpoint call to `limitAiMessages`, preventing helper-only tests
  from passing while the integrated route retains an undefined identifier.

## [3.15.1] — 2026-07-28

### Changed — Light by default, theme remembered per account
- New accounts and accounts without a preference now open VoxyWatch in the light theme from the
  first render.
- Switching to dark or back to light persists on that user's profile. Two accounts sharing one
  browser no longer overwrite each other's choice, and the preference follows the account to
  another device.
- The old browser-wide value no longer controls the theme because previous versions wrote the dark
  default there even without user intent. Every choice made from this release onward is attributable.

## [3.15.0] — 2026-07-28

### Added — Local and remote MCP with live traffic
- ChatGPT, Claude, Codex and other MCP clients can inspect VoxyWatch through local stdio or
  Streamable HTTP at `/mcp`, reusing the portal HTTP(S) port.
- A live-traffic tool returns active and recent calls, signaling outcome, quality, attribution and
  data freshness with a client-selected refresh interval from 5 seconds to 30 minutes.
- Settings adds local/remote enablement, Origin and tool allowlists, bounded responses, OAuth/JWKS
  resource-server configuration and a deterministic live test.
- Least-privilege scopes separate health, traffic, incidents and sensitive data. Phone numbers, IPs,
  Call-IDs and raw signaling stay redacted unless both the administrator and token explicitly allow them.
- Local audit records actor, tool, latency, size and outcome without storing tokens, arguments or traffic.
  Audio, RTP, PCAP, DTMF, writes and SBC control remain outside the MCP contract.

## [3.14.4] — 2026-07-28

### Fixed — Recoverable and predictable Overview
- Overview now discloses how many widgets are hidden and can reveal every widget with one action.
- Restore defaults resets both visibility and ordering without touching product data, filters or settings.
- Legacy, partial or invalid browser preferences are sanitized before use. Missing widgets follow their
  documented default instead of appearing unexpectedly.
- Recovery controls and accessible status text ship in English by default and Spanish as the second language.

## [3.14.3] — 2026-07-26

### Fixed — Cleaner PostgreSQL error signal
- Expected PostgreSQL administrative shutdowns (`SQLSTATE 57P01`) remain visible in the local journal
  but no longer create a Sentry issue.
- Real primary, read and rollup pool failures are reported once. Previously console capture and an
  explicit exception could create two issues for one event.
- A dedicated policy test prevents controlled restarts from being classified as product defects
  without suppressing unexpected connection failures.

## [3.14.2] — 2026-07-26

### Improved — A truly simpler Basic mode
- Basic now hides Data, SIPREC, IP Directory, API and SNMP, plus internal AI, agentic runtime and
  lab controls. Daily operation, Diagnostics and Update remain visible.
- Empty navigation groups disappear instead of leaving confusing headings.
- A guided action that requires a technical tab explicitly enables Advanced before navigating, so
  the active panel and its selector cannot get out of sync.
- Basic/Advanced exposes its selected state to assistive technology without changing permissions or
  any saved configuration.

## [3.14.1] — 2026-07-26

### Fixed — Reliable bootstrap for new frontend assets
- A signed binary can now serve an embedded frontend asset when the trusted installer from the
  previous release did not yet know that filename. Direct upgrades from v3.13.0 no longer leave
  `product-ux.js` unavailable.
- Current installers require the product UX asset to be present and fail closed on an incomplete
  package instead of reporting a successful installation.

## [3.14.0] — 2026-07-26

### Improved — Market-ready product experience
- Settings keeps English as the default language and Spanish as the secondary language, clearly
  explains Basic versus Advanced mode, and keeps Diagnostics available in the basic workflow.
- Empty HEP source, trunk, monitoring and incident views now explain the state and provide a direct
  next action instead of leaving the operator at a dead end.
- Diagnostics adds an executive summary and explicit safe checks for API, SNMP, SIPREC, the agentic
  runtime and AI capabilities. Tests that send external messages still require a deliberate click.
- AI settings provide a conservative monthly request and output-token volume preview based on the
  selected schedule and workload, without presenting incomplete provider pricing as a real cost.
- Guided readiness actions use structured destinations, small-screen layouts are more usable, and
  feedback privacy is explicit: feedback remains local to the installation.

## [3.13.0] — 2026-07-25

### Added — Safer automatic update recovery
- Existing installations now create a root-only snapshot of application files, configuration, service
  units and system tuning before an update changes them.
- If installation or final portal/sniffer health verification fails, VoxyWatch restores the previous
  files and restarts the prior core services. Customer traffic data is never copied or restored.

### Fixed — Reliable first startup
- The local user store safely creates a missing parent data directory while preserving atomic writes,
  restrictive file permissions and fail-closed behavior.

## [3.12.0] — 2026-07-25

### Improved — Clearer setup and safer AI operation
- Settings now opens in a simpler basic mode with advanced mode, full search, use-case guidance,
  a VoIP glossary and a visible unsaved-changes indicator.
- AI setup reports provider capabilities, offers an explicit connection/model test and breaks token
  usage down by workload. Future lab flags are no longer presented as working features.
- Optional API, telemetry and SNMP integrations no longer prevent a healthy installation from being
  reported as market-ready.

### Fixed — AI integrity and cost controls
- Corrupt chat history fails closed and remains untouched instead of being silently replaced.
- Legacy chat payloads now enforce message count, per-message and total-size limits before provider use.
- Incident investigations reuse a persistent diagnosis while material evidence is unchanged and cap
  concurrent LLM narratives, without delaying local evidence or manual critical analysis.
- The deterministic agent replay expands from 12 to 20 telecom scenarios.

## [3.11.15] — 2026-07-25

### Fixed — GUI updates finish cleanly
- The privileged helper now replaces its own process with the signed installer before an upgrade
  overwrites that helper. This prevents a false shell syntax failure after all update files were
  already installed successfully.
- A regression gate now requires this atomic process handoff in every future installer.

## [3.11.14] — 2026-07-25

### Fixed — Observable persistence
- Corrupt or unwritable AI usage history no longer appears as zero usage or gets overwritten;
  the bilingual API and UI keep the failure visible until read/write access recovers.
- Rollup cursors and sealing no longer report success when metadata persistence or the one-minute
  refresh fails; the error reaches observable operational state.

### Fixed — Python and reproducible builds
- The agentic sidecar rejects negative HTTP lengths and bodies larger than 1 MiB before reading,
  and times out incomplete local bodies after 10 seconds.
- Exceptionally long Call-IDs use bounded deterministic WAV/PCAP names with exact Node/Python
  parity, while normal historical names remain unchanged.
- Installation now fails closed if required Audio, PCAP, or DTMF helpers cannot be installed.
- Build staging installs production dependencies without removing development test tooling and
  includes the agentic replay fixtures required by the packaged binary.

### Security and maintenance
- Sentry and Nodemailer were updated to audited versions, reducing known installed dependency
  findings from eight to zero without forced upgrades.
- A release gate checks imports across all 22 versioned Python files.

### Performance and robustness
- Dashboard window caches are bounded to 64 entries and 30 seconds.
- Repeated HTTP cleanup can no longer cancel shared Audio/PCAP/DTMF work still used by another request.
- Copilot retains at most 256 analyses for one physical hour without changing the operator-selected
  freshness or the critical-traffic bypass.

### Documentation and tests
- Runtime contracts, versioned feature catalogs, and the canonical release path are now guarded
  against drift; 69 unreachable lines from the obsolete native-package publisher were removed.
- The final regression covers JavaScript, Python, headless UI, SRS, ephemeral PostgreSQL/Timescale,
  deterministic inventory, dependency audit, and release invariants.

## [3.11.13] — 2026-07-25

### Improved — Smaller, auditable runtime code
- Removed the obsolete blocking warm-up page, an unused call-insight helper, and a fraud resolver
  that had no caller since its introduction. Active startup, fraud profiles, and portal behavior
  remain unchanged.
- A new AST-based release gate detects top-level runtime callables with only their declaration as a
  reference. Comments and documentation can no longer hide dead code.

### Tests
- The detector regression covers live functions, HTML callbacks, comments, documentation, and `$`
  identifiers; the complete release invariant suite executes the gate.

## [3.11.12] — 2026-07-25

### Fixed — Predictable, fail-closed signed updates
- The installer explicitly recognizes `--update`, rejects unknown options and detects missing values,
  preventing typos from silently changing behavior.
- Updates preserve the configured portal port; only an explicit `--port` migrates it.
- The portal's manual fallback uses the root-owned local installer delivered by the last signed
  release and never executes mutable code through `curl | sudo`.
- The privileged helper rejects group/world-writable installer files, and installation fails when
  a core service remains inactive after its retry.
- Release downloads have bounded timeouts/retries and SHA-256 is computed as a stream.

### Tests
- Security contracts lock the trust chain, permissions, option parser, port preservation, bounded
  transfer, streaming hash and final service verification.

## [3.11.11] — 2026-07-25

### Fixed — Capture resilience against malformed input and database outages
- HEP over TCP rejects declared lengths smaller than its header and closes the connection instead
  of entering a non-consuming loop.
- HEPv3 rejects malformed or truncated chunks, while compressed payload expansion is capped at
  1 MiB to prevent decompression bombs.
- Failed PostgreSQL replay restores rotated spools in 1 MiB chunks instead of reading potentially
  huge files into memory.
- The spool disk cap now includes incoming rows and reports written versus dropped rows accurately.

### Tests
- The HEP fixture covers valid, partial and malformed framing, bounded compression, strict spool
  capacity and streaming recovery. Valid parsing remains near 129k packets/s per worker.

## [3.11.10] — 2026-07-25

### Fixed — Per-call media isolation and bounded readers
- RFC 4733 DTMF now accepts only SSRCs correlated with the selected call; unknown correlation returns
  an empty safe result instead of mixing digits from concurrent calls.
- DTMF reads both SEG files and transitional PostgreSQL data with a hard 10,000-event limit.
- SEG readers bound legacy datagrams to 65,535 bytes and sidecar indexes to 4,096 SSRCs.
- PCAP fallback streams within the call time window and matches anchored RFC `Call-ID:` or compact
  `i:` headers, never lookalikes such as `X-Call-ID`.

### Tests
- A permanent Python regression covers SSRC isolation, deduplication, caps, truncated SEG files and
  canonical, compact and adversarial SIP Call-ID headers.

## [3.11.9] — 2026-07-25

### Fixed — CSP-operable controls with verified accessibility
- Sniffer quick restart/apply, separate RTP toggle and Enter-to-send chat now use external listeners; all 15 inline handlers blocked by CSP are gone.
- All 261 controls and 242 buttons have accessible names, reusing visible translated labels or explicit ARIA names for ambiguous fields.
- Settings moves focus into the dialog, traps it and restores it to the opener; eight relevant overlays expose dialog semantics.
- ARIA names follow the ES/EN interface language, including CDR filters, webhooks and routing models.

### Tests
- Real Chrome enforces zero unnamed controls/buttons, zero inline handlers, semantic dialogs, translated labels and focus restoration.

## [3.11.8] — 2026-07-25

### Fixed — Predictable frontend HTTP boundary
- Authentication preserves caller headers and attaches the JWT when `fetch` receives `Request`, `URL` or `Headers`, not only plain URL strings and objects.
- Partial alarm, AI and feature saves no longer inherit unrelated authentication, telemetry or memory values from a global settings interceptor.
- The general settings form now declares the fields it owns, while HEP/SIPREC receives loaded settings through an explicit contract.

### Tests
- Real Chrome covers the standard Fetch contract, and an AST guard limits `window.fetch` to the two authentication wrappers.

## [3.11.7] — 2026-07-25

### Fixed — Resilient integrations with preserved opt-in
- SNMP resends active traps every five minutes in addition to transition raise/clear, and its generated MIB now identifies official PEN 65985 correctly.
- MCP bounds each message, times out stalled portal calls and returns valid JSON-RPC errors for invalid input.
- Webhook failures log only the origin, never credentials carried in userinfo, path, query or fragment.
- SIPREC keeps the per-dialog media address through re-INVITE and CDR generation on multihomed hosts.
- Updates restore SIPREC only when both the enabled unit and persisted opt-in existed; fresh installations stay dormant.

### Tests
- 40 SRS assertions, a real local two-stream SIPREC E2E and new SNMP, MCP, webhook and installer lifecycle contracts.

## [3.11.6] — 2026-07-25

### Improved — Predictable AI budgets with real-time headroom
- Translation is capped at 250 tokens, alert summaries at 220, and interactive chat keeps 1,024; routine monitoring spends less while 30–60 second monitoring keeps the original evidence headroom.
- Per-user manual/30s/1m/5m/15m/30m frequency remains persistent and cannot bypass the administrator floor.
- Provider timeouts, DNS/TLS failures and malformed JSON now count in error telemetry exactly once.

### Fixed — Recoverable offline Batch without RAM spikes
- Corrupt local tracking fails closed, and a remotely created Batch id remains visible if local persistence fails.
- JSONL results stream directly to the browser instead of being fully loaded into portal memory.
- Batch refresh and download require OpenAI and its API key to be configured.

### Tests
- New contracts cover tier budgets, atomic tracking/corruption, streaming and transport/decode failures.

## [3.11.5] — 2026-07-25

### Fixed — Concurrent incidents and atomic audit timeline
- Simultaneous detections of the same fingerprint now converge on one incident, and every caller receives the same id without unique-index errors.
- Escalations and relapses are row-serialized, so one effective transition creates exactly one event and one investigation.
- Opening, recovery, acknowledgement and resolution now commit state and timeline together; an audit failure rolls the transition back.
- Incident comments and agent feedback no longer report success when their event was not persisted.
- Fraud restart reconciliation reads open incidents from the primary, avoiding replica-lag zombies.

### Tests
- The Timescale E2E gate now exercises 12 concurrent opens, 10 concurrent escalations and an injected audit failure that must roll back.

## [3.11.4] — 2026-07-25

### Fixed — Bounded PostgreSQL pools and consistent control reads
- All three pools now have a finite connection/checkout budget, preventing saturation from waiting forever before `statement_timeout` starts.
- Idle transactions are bounded per role and each lane exposes a distinct `application_name` for diagnostics.
- Capture, capacity, retention and rollup cursors always read from the primary; replica lag can no longer govern control decisions.
- DSN query parameters cannot override the safety limits assigned to a pool role.

### Tests
- The Timescale E2E now runs the real schema and migration twice, requiring apply→skip with a stable ledger.
- 120,000 synthetic CDRs prove through `EXPLAIN JSON` that the real keyset, rollup and trigram indexes are selected.
- A PostgreSQL test verifies session GUCs and the actual saturated-pool checkout timeout.

## [3.11.3] — 2026-07-24

### Fixed — RFC 3261 SIP/CDR correlation
- The sniffer and portal now recognize long and compact Call-ID, From, To and Via headers, plus `sips:`/`tel:` URIs and unquoted display names.
- Identity and correlation headers are line-anchored, so extensions such as `X-From`, `X-To`, `X-Call-ID` and `X-CSeq` cannot shadow real SIP headers.
- Call outcomes now use INVITE responses only and the last non-auth final response; BYE, UPDATE and CANCEL responses no longer contaminate `call_result` or `fail_code`.
- Redirect reason text remains available, and `600 Busy Everywhere` is classified as busy.

### Performance and tests
- The precompiled CDR extractor measured 16.5% faster than the previous parser over 100,000 canonical messages.
- The Timescale E2E gate now covers standard and compact answered dialogs, compact Call-ID fallback without a HEP correlation chunk, an INVITE-only failure sequence, and RTP persistence.

## [3.11.2] — 2026-07-24

### Security — Safe HTTP and settings boundaries
- Settings responses now pass through one recursive redaction boundary; passwords, tokens, API keys and SNMP communities never leave the server in clear text.
- The disk endpoint no longer serializes raw settings, and masked SNMP community values safely round-trip without overwriting the stored credentials.
- Protected mutations authenticate before accepting large payloads. Public login/API-key requests stay capped at 64 KB, while authenticated administrative imports retain their 5 MB contract.
- Invalid or oversized JSON returns stable 400/413 responses without creating Sentry noise.
- Public SSO errors and anonymous boot progress no longer expose provider response bodies, internal URLs or SIP/RTP/CDR volumes.

## [3.11.1] — 2026-07-24

### Security — Revoked sessions and private telemetry
- Public license and health endpoints reveal operational detail only when the JWT still belongs to an active user with the current authorization version.
- Sentry now correlates installations through an irreversible hash and no longer receives raw hardware IDs, customer names, host names or non-pseudonymous users.
- Adoption telemetry now allowlists optional fields, preventing callers from overriding identity/event data or attaching settings and secrets.

### Reliability — Fail-closed identities
- An existing corrupt or unreadable user database can no longer be mistaken for a new installation or recreate the default administrator.
- User changes are persisted with mode 0600 through an atomic temporary-file rename; write failures no longer return false success.
- Bootstrap background jobs now share an observable boundary for synchronous throws and rejected promises.

## [3.11.0] — 2026-07-24

### Changed — Faster portal, useful telemetry
- Main assets are preloaded once, gzip-compressed and served with ETags plus version-bound immutable caching.
- A valid license is retained as error context without creating an informational Sentry issue or consuming event quota.

### Reliability — Reproducible database integration gate
- A disposable local TimescaleDB cluster now validates HEP→SIP/RTP→CDR and exact rollup counts without modifying the system PostgreSQL cluster.

## [3.10.3] — 2026-07-23

### Fixed — Updater compatibility with private temporary directories
- The installer streams ownership repair SQL through stdin, so PostgreSQL no longer needs to traverse root's private temporary directory.
- The v3.10.2 SNMP separation remains included: standard MIBs for the host and private PEN 65985 for VoxyWatch service metrics.

## [3.10.2] — 2026-07-23

### Fixed — Accurate standard SNMP for PRTG
- `sysUpTime` reports the VoxyWatch agent uptime, while `hrSystemUptime` reports Linux host uptime.
- `sysName` exposes the host name and `hrStorageTable` uses exact filesystem size and usage.

### Compatibility
- Generic host monitoring uses SNMPv2-MIB/HOST-RESOURCES-MIB; VoxyWatch service, capture and VoIP metrics remain under private PEN 65985.
- Historical private resource OIDs remain available as backward-compatible aliases.

## [3.10.1] — 2026-07-23

### Fixed — PostgreSQL integrity on inherited installations
- The installer now idempotently repairs ownership and privileges for VoxyWatch tables and dependent sequences before applying the baseline and migrations.
- This prevents CDR write, rollup read, and runtime index failures caused by application objects inherited from a different owner.

### Changed — Actionable operational telemetry
- Sustained CPU bottlenecks remain visible in local incidents and logs, while Sentry now receives state transitions instead of repeating the same event every five minutes.

## [3.10.0] — 2026-07-14

### Added — Visible agent quality
- Diagnostics now provides a local per-action scorecard for shadow volume, operator feedback, accuracy, helpfulness and configurable readiness criteria.
- Administrators can run the 12-case synthetic telecom replay from the app without contacting a model or consuming tokens.
- Redacted visual traces show tool flow, result and latency; incident details explain why no action was taken and accept direct thumbs-up/down feedback.

### Safety and privacy
- Feedback remains inside the installation and is not delivered to VoxyWatch or an AI provider. Evaluation candidates exclude operational evidence and content.
- Meeting shadow thresholds only marks an action ready for administrator review; it never enables or executes an action automatically.

## [3.9.0] — 2026-07-14

### Added — Verifiable agentic operations
- Diagnostics adds conservative shadow mode, administrator-only short-lived traces, confidence thresholds and operator feedback.
- Incident diagnoses cite structured evidence IDs; unverifiable citations or low confidence cannot prefill an operational proposal.
- A deterministic release evaluation covers groundedness, action policy and Spanish/English prompt-injection canaries.

### Changed — Safer agent architecture
- The portal is now the only routing and policy authority. The optional loopback sidecar accepts typed specialist handoffs and remains disabled by default.
- Agent runs disclose evidence truncation, iteration exhaustion and budget skips, and record an explicit prompt version for auditing.
- UI, SIP and network-derived strings are treated as untrusted data rather than instructions. VoxyWatch still never controls a customer SBC.

## [3.8.2] — 2026-07-14

### Fixed — Data and concurrency reliability
- Automatic retention now evicts deleted trace ranges from memory immediately and no longer blocks its own trace-relief operation.
- Incremental catch-up has a finite database timeout, processes bounded batches and refreshes its state without a stale cache response.
- Capture change detection uses constant-time sequence state, including late inserts assigned to older Timescale chunks, without scanning compressed history.
- Diagnostic capture-ID tracking is tightly bounded per source, and four operational timers contain unexpected exceptions instead of restarting the portal.

### Performance
- The preceding hourly rollup is recomputed only when newly parsed traffic could have changed it; live traffic remains fresh while idle systems avoid redundant database work.

## [3.8.1] — 2026-07-14

### Fixed — Safer updates and trustworthy evidence
- One-click updates now require the published SHA-256 and VoxyWatch GPG signature, and the privileged helper executes only the trusted local installer delivered by a signed package.
- SSO identities can no longer adopt local accounts by display name or unverified email; role, password and username changes revoke existing sessions.
- PCI recording suppression handles decimal and hexadecimal SSRC formats reliably, while call detail and CDR views ignore late responses from a previous selection.
- SIPREC selects a routable media address per SBC, rejects non-SIPREC sessions and recovers safely from stalled setup or RTP sequence wraparound.

### Reliability
- Incremental capture catch-up is bounded in batches and advances only after call state is persisted; parsing and automatic retention no longer overlap.
- Release validation now covers the complete frontend and SIPREC asset set plus executable security regression checks.

## [3.8.0] — 2026-07-13

### Added — AI cost and freshness controls
- Every operator can choose manual AI refresh or 30 seconds, 1, 5, 15 or 30 minutes. Administrators set the minimum interval, while critical conditions may bypass the normal wait.
- Settings → LLM adds deterministic fast/standard/deep model routing, Prompt Caching, a chat context budget, aggregate token usage and opt-in OpenAI Batch analysis for offline trunk reviews.
- AI usage records calls, input/output/cached/reasoning tokens, errors and latency without storing prompts, SIP/RTP, CDRs, phone numbers, customer IPs or credentials.

### Changed — Savings without delaying critical detection
- Live KPIs, alarms and evidence remain local and immediate; only the LLM narrative follows the selected freshness interval.
- Chat history is bounded by a total context budget, outputs adapt to workload and urgency, and critical investigations retain a larger response budget.

### Safety
- Batch is admin-only, disabled by default, isolated from chat/alarms/incidents and rejects duplicate active jobs.

## [3.7.1] — 2026-07-13

### Fixed — Visible attention queue
- The prioritized attention queue and guided demo story no longer collapse inside the fixed-height flex dashboard; both keep their content height while the dashboard continues to scroll normally.

### Process
- Authenticated visual validation against the public demo is now required for new Overview surfaces, and the CSS contract explicitly prevents flex shrinking.

## [3.7.0] — 2026-07-12

### Added — Outcome-first operator experience
- Overview now starts with a prioritized queue of open incidents and degraded trunks, including impact, evidence and a direct investigation action.
- The public demo adds one-click access and a four-step live scenario from degradation to failed calls and carrier-ready evidence.
- Primary navigation is reduced to Overview, Investigate, Incidents and Infrastructure; Fraud, Trunks and CDR remain available under More.

### Changed — Faster first investigation
- New users start with five essential KPIs and five operational charts; every advanced widget remains available through Customize.
- Portal and login positioning are unified as “Agentic NOC for Voice Networks”.
- The dashboard stays hidden until authentication finishes, eliminating the misleading inactive-capture screen before login.

### Fixed — Verifiable one-click updater
- A connection closed by the portal restart is no longer reported immediately as a network failure; the UI reconnects and verifies the installed version.
- Invalid/non-JSON updater responses are handled clearly, and the button recovers when the old version remains installed.

### Process
- Added 26 automated contracts for authentication bootstrap, demo, navigation and updater behavior, plus a reproducible visual smoke test.

## [3.6.1] — 2026-07-12

### Fixed — One-click updates on minimal Debian installations
- The installer now installs and verifies polkit when scoped service control is enabled. Previously it could write the authorization rule and mark service control enabled even when no polkit daemon existed, causing the Update button to fail with `Access denied`.
- `enable-service-control.sh` now fails clearly when polkit is unavailable instead of reporting a permission that systemd cannot evaluate.

### Process
- Release invariants now require the installer to provide and verify polkit for the D-Bus updater.

## [3.6.0] — 2026-07-12

### Added — SIP Expert timeline, confidence and evidence
- SIP Expert now builds a deterministic transaction timeline with transactions, dialogs, retransmissions, final response per transaction, delayed-offer, early-media, forking and early-BYE signals.
- Each scenario can now carry confidence and evidence so operators can see the exact message, header or SDP behind the conclusion.
- New no-LLM scenarios cover private Contact/NAT, private SDP media, SRTP/security policy, codec mismatch, T.38/fax, hold/inactive media, late offer, forking, retransmissions and routing loops.
- The UI and Markdown export now show confidence and timeline details.

### Fixed — SIP precision and false positives
- Private Contact/SDP are informational by themselves and no longer override likely owner/root cause when a call completes successfully.
- ACK transactions are shown as one-way instead of no-response.
- Retransmission counting now works when the original request is message #1/index 0.

### Operations
- Added deterministic tests for ACK one-way, retransmissions, private NAT/SDP, SRTP, codec mismatch, late offer, T.38 and forking.

## [3.5.0] — 2026-07-12

### Added — Expanded deterministic SIP Expert
- SIP Expert now recognizes common SIP scenarios without requiring an LLM: CANCEL/487 cancellation, redirects, authentication challenge/success/failure, SDP/media negotiation failure, 503 capacity without Retry-After, session timers, 491 glare, early media, Q.850 Reason, identity/privacy, forwarding history, transfer/join, DTMF and no-response flows.
- The executive summary uses those deterministic scenarios to suggest likely root cause, likely owner and operational next steps.
- The UI now shows detected scenario chips, and Markdown/JSON exports include the same scenario classification for carrier disputes or external troubleshooting.
- RFC coverage now includes PUBLISH, CANCEL, BYE, Replaces, Join, Path, SIP Outbound, GRUU, P-Early-Media, Resource-Priority, 3GPP P-Headers, SUBSCRIBE/NOTIFY/PUBLISH Event, 422 Min-SE, 420 Unsupported and 405 Allow.

### Fixed — SIP dialog precision
- Missing ACK detection now checks each 200 OK INVITE dialog/fork by tags, preventing false negatives when multiple 200 OK responses exist and only one receives ACK.

### Operations
- Added deterministic tests for cancellation, media failure, 503 without Retry-After, REGISTER challenge-response, SUBSCRIBE/NOTIFY events and forked 200 OK without ACK.
- SIP Analysis runbooks now document that SIP Expert should be useful without an LLM; the LLM can explain/correlate, but deterministic findings remain the evidence source.

## [3.4.0] — 2026-07-12

### Added — Operator guidance and contextual LLM
- Settings -> Diagnostics now shows guided actions inside Platform readiness with priority, likely fault domain, confidence and next step.
- Platform readiness now gives clearer update status: installed/published versions, compatibility, validation and last-check age.
- The built-in LLM receives a sanitized UI context hint, so it can understand questions like "this call", "this incident" or "what should I do now" from the current portal view.
- UI context is allowlisted and bounded; the assistant still verifies real data through read-only VoxyWatch tools.

### Fixed — Heavy job feedback
- Audio and PCAP buttons now stop duplicate clicks while the same heavy job is already being prepared, reducing operator confusion and repeated requests.

### Operations
- Engineering docs now document the new readiness guidance contract and the correct bug-hunter/test procedure for this repository.

## [3.3.1] — 2026-07-10

### Fixed — Authenticated startup
- Returning browser sessions now attach the stored JWT before early `/api/settings` and `/api/time` requests.
- Startup modules no longer send protected API requests without Bearer before the full auth wrapper is ready.
- This removes noisy 401 console errors and prevents early widgets from seeing stale pre-auth state.

### Operations
- Demo validation now includes authenticated browser startup checks in addition to API health checks.

---

## [3.3.0] — 2026-07-10

### Added — Agentic decisions UI
- Settings -> Diagnostics now includes an Agentic decisions review table with filters, detail view, audit trail and approve/reject controls.
- Approved `notify_operator` decisions reuse the existing incident notification fan-out when an `incident_id` is provided.
- Approved `snooze_incident` decisions perform an audited ack + comment with a bounded snooze window.
- The Agentic sidecar now exposes `/actions` and `/context-contract`, and analysis responses include proposal templates for policy-gated actions.

### Safety
- `notify_operator` and `snooze_incident` require a valid `incident_id`; invalid incident IDs are not reported as executed.
- Threshold changes remain recommendation/manual-apply only.

## [3.2.0] — 2026-07-10

### Added — Policy-gated agentic actions
- Added a redacted agent context API so native agents can use live readiness, traffic snapshot, runbooks, read-only tools and recent incidents without raw SIP, audio/RTP or secrets.
- Added a separate action policy catalog for operational recommendations. The read-only tool catalog remains read-only.
- Added audited agentic decisions: agents can propose actions, operators can review them, and high-risk execution requires admin approval.
- Approved `open_incident` and `mark_fraud_suspect` actions create deduplicated VoxyWatch incidents through the existing incident engine and notification path.
- The Agentic sidecar now reports policy-gated suggested actions while keeping the customer's SBC outside the control boundary.

### Security and operations
- Action decisions are stored locally with secret redaction and an audit timeline.
- Release checks now cover the new agentic action policy, context redaction and decision-store contract.

## [3.1.1] — 2026-07-10

### Fixed — Agentic dependency lifecycle
- The Agentic runtime now starts through a managed runner that uses the ADK virtual environment when installed and falls back safely when it is not.
- Signed updates now refresh Agentic Python dependencies only when the runtime was already enabled or active, so fresh installs still avoid any PyPI/network dependency.
- Settings -> Diagnostics now shows ADK availability, installed `google-adk` version, requirements hash and venv readiness.

### Operations
- Release checks now block stale Agentic manifest versions, missing runner packaging and direct system Python service launches.

## [3.1.0] — 2026-07-10

### Added — LLM provider polish and agentic runtime controls
- Settings now uses **LLM** naming for the assistant configuration and floating assistant entrypoint.
- Added **Perplexity (Sonar)** as a first-class LLM provider.
- The model picker now filters provider catalogs to useful text/chat models and hides image, audio, embedding, moderation and unrelated diagnostic models.
- Interactive LLM replies now infer language from the operator's latest message; the profile keeps the personal prompt, without a separate AI-language selector.
- Settings -> Diagnostics now shows the native agentic runtime and lets admins enable/start or stop/disable `voxywatch-agentic.service` through VoxyWatch service-control.

### Security and operations
- The agentic sidecar remains loopback-only, off by default on new installs and separated from the read-only agent tools contract.
- Release invariants now test the LLM model filter so vendor catalog changes do not pollute the diagnostic model selector.

## [3.0.1] — 2026-07-10

### Changed — Functional agent names
- Agent display names now describe each specialist's function: Task Orchestrator, SIP Signaling Analyzer, Fraud Detection Analyst, Traffic Statistics Analyst, Platform Health Monitor and Release Update Monitor.
- Technical agent IDs remain stable, so existing agentic contracts and integrations do not break.

## [3.0.0] — 2026-07-10

### Added — Native agentic runtime foundation
- VoxyWatch now ships an ADK-ready agentic sidecar as `voxywatch-agentic.service`.
- The sidecar is installed and updated with every signed VoxyWatch release, but fresh installs keep it disabled until the operator enables it.
- New authenticated agentic endpoints expose runtime status and evidence-backed analysis routing.
- The first native specialist map includes Orchestrator, SIP Expert, Fraud Guard, Traffic Analytics, NOC Health and Release Watcher.
- If the sidecar is not running yet, the portal returns a deterministic local routing plan instead of failing the operator workflow.

### Security and operations
- The sidecar binds to loopback only and never controls the customer's SBC.
- Updates preserve a prior operator opt-in: active/enabled sidecars are restarted with the new release; inactive installs stay off.
- Release invariants now block unsafe agentic defaults, missing packaging or accidental enablement on fresh installs.

## [2.161.0] — 2026-07-10

### Added — Per-user agentic chat memory
- AI Chat now stores conversation sessions per user on the server, so each operator can reopen prior chats without mixing history with other users.
- The floating chat widget can create a new chat, switch previous sessions and delete a chat history.
- LLM calls now use bounded server-side history instead of trusting the browser to resend the full conversation.
- User Profile now includes a personal AI relationship prompt and the user's AI language preference.
- New authenticated agentic endpoints expose the read-only tool catalog for built-in chat and future ADK/sidecar runtimes.

### Security and process
- Custom system prompts are admin-only; normal users configure style through their profile prompt.
- Agent tool execution is rate-limited.
- Added unit coverage for user isolation, bounded context and deletion.

## [2.160.0] — 2026-07-10

### Added — Platform readiness and operational visibility
- Settings -> Diagnostics now includes **Platform readiness**, a consolidated market-readiness view for production health, configuration gaps, update safety, heavy job activity, AI troubleshooting context and hardware fit.
- New authenticated `GET /api/platform-readiness` returns a redacted read-only readiness contract built from operational health, deployment status, onboarding, settings, heavy jobs and hardware limits.
- Heavy job snapshots now expose safe running/queued job metadata without Call-ID or dedupe keys, so operators can see that audio, PCAP and DTMF work is in progress.
- CDRs now include deterministic `quality_score`, `quality_grade` and `quality_factors` to summarize SIP/media quality per call.

### Process
- Added readiness and call-quality unit tests.
- Release invariants now verify the new readiness endpoint, Diagnostics UI anchors and safe heavy-job visibility.

## [2.159.3] — 2026-07-08

### Fixed — Public CDR zero-value contract
- Public CDR responses now preserve measured zero values for setup time, PDD, SIP disposition code, MOS, jitter, packet loss and SIP message count instead of converting them to `null`.
- This keeps API v1, Call Insight responses, exports and downstream integrations from treating valid zero metrics as missing data.

### Documentation
- The integration API guide now documents `/api/v1/calls/:id/insights`, including its privacy boundary, response shape and example request.
- The public CDR field table now reflects the shipped field names and clarifies that `0` is a valid measurement while `null` means unavailable.

## [2.159.2] — 2026-07-08

### Fixed — API v1 and anonymous share hardening
- `/api/v1/calls/:id/insights` now uses the stable public CDR projection (`mapCallToPublicCdr`) instead of the portal's internal CDR projection.
- The anonymous JSON bundle no longer exposes exact SSRC values inside `rtp_expert.metrics`; it keeps side-presence flags only.

### Process
- Added `test/call-insights-contract.test.js` to block regressions in the API v1 public CDR contract and share-safe RTP Expert output.
- Release invariants now run the new contract test.

## [2.159.1] — 2026-07-08

### Fixed — Call Insight Pack polish
- Audio/RTP Expert trends now keep `dimension` and `is_target`, so the UI shows the correct label and highlights the current-call row.
- The Audio/RTP Expert panel now ignores stale responses if the operator switches calls before the request finishes.
- The anonymous JSON bundle now masks compressed IPv6 and IPv4-mapped addresses without leaking the host part, and preserves valid zero technical values (`setup_time_ms`, `pdd_ms`, `disposition_code`).

### Process
- `test/call-insights.test.js` now covers trend labels, current target rows, IPv6/IPv4-mapped masking and zero technical values.
- `test/ui-smoke.test.js` now covers the anti-stale panel guard.

## [2.159.0] — 2026-07-08

### Added — Call Insight Pack
- Call detail now includes **Audio/RTP Expert** with deterministic analysis of packet loss, jitter, MOS, one-way media, audio reconstruction state and operational recommendations.
- New authenticated `/api/calls/:id/insights` and API v1 `/api/v1/calls/:id/insights` return CDR, Audio/RTP Expert and bounded ±24h contextual trends without raw SIP, audio or PCAP payloads.
- New `/api/calls/:id/share-bundle` downloads an anonymous JSON package for support or external AI assistance, masking numbers, IPs and Call-ID while excluding payloads, credentials and settings.
- Settings -> Diagnostics now includes **Call Insight Labs** with conservative OFF flags for transcription, WebRTC/TLS/SRTP lab work and T.38 detection.

### Process
- Added deterministic `test/call-insights.test.js` coverage and release invariants now run it.
- UI smoke now covers the new Diagnostics save path after review found the new flags had no save button in that tab.

## [2.158.1] — 2026-07-02

### Fixed — safer heap-pressure trimming on high-volume installs
- C3ntro `2.158.0` still hit Node/V8 out-of-memory restarts while capture, PostgreSQL and rollups were healthy; the heap-pressure trim retained too much working set during traffic spikes.
- VoxyWatch now trims to 25% on high heap pressure and 20% on critical pressure, while preserving the minimum useful working set and the effective hardware cap.

### Process
- Working-set trim tests now reproduce the 350k-row high-volume case and block regressions to the previously insufficient target.

## [2.158.0] — 2026-07-01

### Added — visible progress and dedupe for searches/downloads
- The main call search now shows `Searching...`, deduplicates identical requests and ignores stale responses so operators know the server is working.
- Audio/PCAP downloads show `Preparing...`, block repeated clicks and reuse the same active fetch when the user repeats the same action while it is still running.
- The heavy job queue now deduplicates identical `jobKey` work for reconstruct/audio/PCAP/DTMF and API v1, avoiding repeated process spawns from double clicks or multiple tabs.

### Process
- Added `test/heavy-job-queue.test.js` for job dedupe and the `deduped` metric.
- Release invariants now run the heavy job queue suite and UI smoke validates the visible search progress anchor.

## [2.157.0] — 2026-07-01

### Added — AI troubleshooting pack improvements
- Settings -> Diagnostics now lets operators copy the public AI pack URL and download a `voxywatch-ai-docs-pack/v1` containing the fixed allowlist of public Markdown docs.
- New authenticated `/api/ai-troubleshooting-docs-pack` returns product documentation only, with no user-provided paths and no customer data.
- Added `docs/ai/CHANGELOG_AI_CONTEXT.md` so external AI assistants can track changes to the context and docs contracts.

### Process
- Added an HTTP test with simulated auth for `/api/ai-troubleshooting-context` and `/api/ai-troubleshooting-docs-pack`.
- Release invariants now block missing AI pack build/install/publish wiring and endpoint auth/allowlist regressions.

## [2.156.0] — 2026-07-01

### Added — AI troubleshooting pack
- Added `AI_TROUBLESHOOTING.md` and `docs/ai/` so operators can load a structured English guide into an AI assistant for VoxyWatch configuration, troubleshooting and safe extension work.
- Settings -> Diagnostics now includes compact actions to open AI docs, copy/download an AI-safe context and download the support bundle.
- New authenticated `/api/ai-troubleshooting-context` returns public documentation links plus the allowlist-only support bundle, excluding secrets, raw SIP, audio, settings, logs, IPs, trunks, Call-IDs and PII.

### Process
- Build/install now ship the AI pack under `/opt/voxywatch`, and release syncs `AI_TROUBLESHOOTING.md` + `docs/ai/` to the public publish repository.
- Tests now cover AI context redaction and visible Diagnostics anchors.

## [2.155.2] — 2026-07-01

### Fixed — C3ntro capture state no longer scans compressed hypertables
- The portal no longer uses `SELECT MAX(id), MIN(id) FROM packets` to detect capture changes. On compressed TimescaleDB chunks that query can open hundreds of chunks and compete with ingestion and the portal under high traffic.
- `getDbState()` now reads the latest `id` from the newest chunk and uses `timescaledb_information.chunks` to detect retention via `minTs`, avoiding a full hypertable scan.
- Incremental purge now evicts the in-memory working set by chunk timestamp, preserving the no-full-reparse path and avoiding a second large heap copy.

### Process
- Added a release invariant that blocks reintroducing full-hypertable `MIN/MAX(id)` over `packets`.
- Updated the C3ntro diagnostic process to avoid unbounded `EXPLAIN VERBOSE` output on large compressed hypertables.

## [2.155.1] — 2026-07-01

### Fixed — heap and audio reconstruction stability
- The portal now trims its in-memory working set with more conservative targets under high or critical V8 heap pressure, leaving more room for GC and allocation spikes on high-volume installs.
- Audio reconstruction no longer scans RTP segment files when both SSRCs are `unknown` unless `.idx` metadata narrows the window to at most two candidates. Otherwise it returns a controlled “no audio” result instead of risking `MemoryError`.

### Process
- Added regression coverage for `unknown/unknown` audio reconstruction in file-backed RTP mode.
- Extended working-set trim tests for the new high-pressure heap targets.

## [2.155.0] — 2026-06-30

### Added — operational improvements for support, onboarding and SIP Expert
- Settings now shows compact visual groups for start, operation, security/integrations and support.
- Settings → Diagnostics adds **Copy evidence**, with version, health, license, services, memory, capture and key operational signals ready to paste into tickets.
- SIP Expert now includes a deterministic executive summary: what happened, likely root cause and suggested owner.
- Getting started now detects additional recommended setup items: anonymous telemetry, SNMP for NMS and retention/autopurge.

### Changed — faster dashboard experience
- The dashboard frontend now coalesces duplicate requests per range and ignores stale callbacks, avoiding stacked queries and preventing old windows from repainting after a quick filter change.

### Process
- Added a headless UI smoke test for critical Dashboard, Settings, Diagnostics and SIP Expert anchors.
- Release invariants now run onboarding and UI smoke coverage to block visible regressions before publishing.

## [2.154.1] — 2026-06-30

### Fixed — SNMP source allowlist is enforced
- The embedded SNMP agent now enforces `snmp_allow_ips` inside the process and drops requests whose source does not match exact IPv4 entries, IPv4 prefixes or IPv4 CIDR ranges.
- This fixes installations that intentionally bind SNMP on `0.0.0.0` with an allowlist configured, but were still relying only on SNMPv2c community strings and external firewalling.

### Process
- Added unit coverage for exact match, prefix, CIDR, IPv4-mapped IPv6 and the actual `net-snmp` listener wrapper.
- Release checklist now explicitly keeps inventory generation and inventory checking sequential to avoid false drift from read/write races.

## [2.154.0] — 2026-06-30

### Changed — Operational Health moved into Settings → Diagnostics
- Operational Health moved from the main navigation into **Settings → Diagnostics**.
- Diagnostics now shows snapshot-only health together with system/runtime diagnostics in one operational support tab.
- The standalone Health nav button was removed to keep support evidence and live health in the same place.

### Process
- The authenticated `/api/operational-health` contract is unchanged and remains O(1), with no SQL/process/filesystem/network I/O per request.
- Added a UI guard so the health loader exits cleanly if the settings modal nodes are not mounted yet.

## [2.153.0] — 2026-06-30

### Added — SIP Expert for full trace diagnosis
- SIP flow now includes a **SIP Expert** button that jumps to the trace diagnosis.
- The analyzer classifies the SIP case: call/dialog, REGISTER, OPTIONS, REFER, MESSAGE, SUBSCRIBE/NOTIFY or in-dialog updates.
- The panel summarizes outcome, signaling health, suspected corruption, STIR/SHAKEN Identity, authentication, SDP/media, detected RFCs and operational recommendations.
- Markdown/JSON export now includes the expert verdict together with clickable RFC findings.

### Process
- Bug-hunter found that the first expert verdict exposed backend text only in English; the release now returns ES/EN summary and recommendations and the UI selects by language.
- Added coverage for REGISTER/auth challenge, STIR/SHAKEN Identity and malformed SIP headers.
- Operating policy is updated: VoxyWatch changes publish by default through bug-hunter, signed private/public release and C3ntro validation unless Moy explicitly pauses publishing for that task.

## [2.152.0] — 2026-06-30

### Added — SIP/RFC analyzer in call flow
- SIP flow details now include an RFC compliance panel before the ladder, with verdict, prioritized findings, detected RFCs and Markdown/JSON export.
- The analyzer validates basic SIP structure, Via/From/To/Call-ID/CSeq, Content-Length, dialog ACK/BYE, PRACK/RAck, compact headers and folded headers.
- Each finding links back to the matching SIP message so operators can inspect the problem quickly.

### Process
- The deterministic analyzer now lives in `lib/sip-analysis.js` with unit coverage for healthy calls, missing ACK, compact headers, invalid Content-Length/CSeq and PRACK without RAck.
- Release invariants now run the SIP/RFC suite to prevent analyzer regressions.

## [2.151.8] — 2026-06-30

### Fixed — portal anti-OOM trim now respects the effective heap cap
- Heap-pressure trimming no longer keeps “70% of current rows” when that number is still above the reduced effective cap.
- Fixes the C3ntro `2.151.7` recurrence where the portal trimmed from ~863k to ~604k rows even though the pressure cap was much lower, then V8 crashed with `JavaScript heap out of memory`.
- Incremental trim now applies a second guard and uses `min(pressure_target, maxRows)` before rebuilding.
- Fatal `uncaughtException` logs now include the stack trace, which makes follow-up errors such as `argument must be a buffer` actionable if they reappear.

### Process
- Added executable coverage for the C3ntro case (`863105` rows, `175000` effective cap) so emergency trim cannot exceed the real cap again.

## [2.151.7] — 2026-06-29

### Fixed — PRTG standard SNMP sensors can load more MIBs
- Standard SNMP compatibility now also exposes `sysDescr`, `sysObjectID`, `sysContact`, `sysName`, `sysLocation` and `sysServices` in `SNMPv2-MIB`.
- Added `hrSystemUptime`, `hrMemorySize` and `hrProcessorLoad` for generic memory/CPU sensors that expect more than `hrStorageTable`.
- VoxyWatch enterprise OIDs under PEN 65985 are unchanged; this only expands standard NMS aliases.

### Process
- SNMP coverage now validates standard system, memory and CPU OIDs together with VoxyWatch enterprise OIDs through a local network session.

## [2.151.6] — 2026-06-29

### Added — standard SNMP compatibility for NMS tools
- The embedded SNMP agent keeps the VoxyWatch enterprise OIDs and now also exposes `SNMPv2-MIB::sysUpTime.0`.
- Added `HOST-RESOURCES-MIB::hrStorageTable` rows for physical memory, virtual memory and the root filesystem so PRTG/Zabbix/LibreNMS can use standard memory/disk sensors.
- This is additive: it does not change the configured community, SNMPv3, traps or VoxyWatch enterprise OIDs under `1.3.6.1.4.1.65985`.

### Process
- Added unit coverage and a local `net-snmp` network validation path to confirm standard and enterprise OIDs answer from the same agent.

## [2.151.5] — 2026-06-29

### Changed — second-pass UI language readiness
- Date and number locale handling now comes from the visible UI language metadata instead of hardcoded Spanish/English checks.
- Interactive Copilot calls now pass the current UI language code through to the backend when the AI engine supports that language, with English fallback.
- The update panel can now display future localized release notes from `latest.json.changelog_<language>` and falls back to the English changelog.
- The boot/loading screen reuses the persisted UI locale for numeric formatting.

### Process
- Release invariants now guard against regressions in persisted locale metadata, Copilot language pass-through and localized update changelogs.
- `docs/DESIGN_I18N_UI.md` now maps the remaining non-UI-template limits separately from the UI language selector flow.

## [2.151.4] — 2026-06-29

### Changed — UI language onboarding is ready
- Visible portal languages now come from `window.VW_UI_LANGUAGES`; Settings and Profile language selectors are generated from that list.
- Adding a new UI language is now a mechanical flow: generate the scaffold with `tools/i18n_tool.py --scaffold <code>`, translate the values, then add the selector entry with `--selector`.
- `tools/i18n_tool.py --check-selectors` fails if a visible language is incomplete, preventing accidental partial-language releases.

### Documentation
- Added `docs/DESIGN_I18N_UI.md` with the exact workflow for adding UI languages.

## [2.151.3] — 2026-06-29

### Fixed — remaining incremental rollup phases are sliced
- `incremental_ended`, `incremental_causes` and `incremental_codecs` now use the same 15-minute slicing pattern as `incremental_metrics`.
- Each slice is summed in memory and consolidated with one hourly `call_stats_hourly` upsert, preserving the existing formulas and buckets.
- This addresses the C3ntro 2.151.0 recurrence where `incremental_ended` became the dominant statement-timeout phase after the metrics fix.

### Process
- The PostgreSQL rollup test now covers sliced parity for ended counts, SIP cause families and codecs, not only the metrics counters.

## [2.151.2] — 2026-06-29

### Fixed — only login uses browser password fields
- The only remaining `type=password` input is the login field (`#login-password`), so browsers can still save the actual end-user password.
- Password change, profile and add/edit user flows now use masked text inputs with autocomplete disabled and no reveal button, preventing the admin browser from saving someone else's temporary password.

### Changed — new users must change their password
- The “Require password change at next login” checkbox is checked by default when creating a user.
- The backend enforces the same default even if the client omits the field; only `force_change:false` disables it explicitly.

### Process
- Release invariants now require `#login-password` to be the only `type=password` input and require new users to keep `force_change` enabled by default.

## [2.151.1] — 2026-06-29

### Fixed — Settings no longer triggers password-save prompts for tokens
- Operational secrets in Settings (AI API key/token, Telegram bot token, SMTP password, SSO client secret and SNMPv3 keys) no longer render as browser password fields. They use masked text inputs with autocomplete and password-manager hints disabled, so browsers should not offer to save them as site credentials.
- The reveal-eye button is no longer added to the API key/token or other operational secrets marked as non-revealable. Real login, password-change and user-management password forms keep their normal behavior.

### Process
- Release invariants now block regressions where Settings operational secrets become `type=password` again or lose the no-eye/password-manager hints.

## [2.151.0] — 2026-06-28

### Added — anonymous adoption telemetry
- The existing Settings telemetry toggle now controls both Sentry error reporting and anonymous adoption telemetry.
- VoxyWatch sends a lightweight hourly ping before the release manifest check and one daily installation JSON at 04:00 local time to `https://telemetry.voxywatch.com:8443/install-checkin`.
- The payload is intentionally minimal: version, event, anonymous install hash, license tier/status, platform, architecture, Node version and timezone. It never sends customer IPs, trunks, settings, Call-IDs, SIP/RTP payloads, CDRs, audio or credentials.

### Changed — update checks remain hourly
- The portal keeps checking `latest.json` every hour and the manual “Check now” button still works on demand.

### Process
- New tests and release invariants cover the adoption telemetry payload, hourly ping rate limit, daily JSON deduplication and privacy rules.

## [2.150.1] — 2026-06-28

### Fixed — incremental hourly rollup under real traffic peaks
- The `incremental_metrics` phase no longer processes a full hour in one statement. It scans 15-minute slices, sums the counters in memory and performs one idempotent `call_stats_hourly` upsert for the hour.
- The total, ASR/NER, duration, PDD and MOS formulas stay unchanged while each query has a smaller worst case under C3ntro-scale traffic.

### Process
- Pure and PostgreSQL tests now cover the sliced selector and slice summing path, blocking regressions to the monolithic query that could hit `statement_timeout`.

## [2.150.0] — 2026-06-27

### Added — public AI configuration assistant guide
- Added `AI_VOXYWATCH_CONFIGURATION_ASSISTANT.md`, an English guide an AI assistant can read to help customers configure VoxyWatch with the right operational data: IPs, trunks, capture sources, thresholds, retention, alerts, users and validation steps.
- Settings → Getting started now includes a bilingual prompt that links to the public GitHub guide, so users can ask their own AI assistant to consult the current VoxyWatch configuration instructions.

### Process
- The guide contains no real customer IPs, secrets or private data. It uses safe placeholders and instructs the AI to ask for missing customer-specific values instead of guessing.

## [2.149.3] — 2026-06-27

### Fixed — immediate trimming under heap pressure
- Heap pressure now forces working-set trimming even when the row-count cap has not crossed the old `1.5×` threshold, preventing V8 from aborting while waiting for that threshold.
- The path still does not reread PostgreSQL: it removes old in-memory rows and rebuilds metadata through the same `incremental-trim` flow.

### Process
- Release invariants now block both a regression to `parseCapture({ reason: 'cap-trim' })` and missing early trimming under heap pressure.

## [2.149.2] — 2026-06-27

### Fixed — portal OOM during working-set trimming
- The memory cap path no longer runs `full-parse:cap-trim`; it now removes the oldest in-memory rows and rebuilds call metadata without rereading PostgreSQL or duplicating the live working set.
- Operational Health now shows recent portal restarts from a background systemd snapshot (`service_restart_count`, `service_restart_delta`, `recent_restart`) while keeping the request O(1).

### Process
- New tests cover the trim planner and systemd snapshot parser. Release invariants block any regression where `cap-trim` calls `parseCapture` again or recent OOM/restart evidence is hidden.

## [2.149.1] — 2026-06-27

### Fixed — recurring incremental hourly-rollup timeout
- Hourly metrics now calculate duration, PDD and MOS once per call through a compact materialized projection instead of repeating JSON extraction across fifteen aggregates.
- Slow rollup logs identify the exact phase and duration, so future timeouts distinguish metrics, ended calls, causes and codecs.

### Process
- Pure and transactional PostgreSQL tests cover SQL shape, filters and exact counters. Read-only production observation isolated the previous 120-second timeout to the metrics phase.

## [2.149.0] — 2026-06-27

### Added — per-installation deployment status
- Software Update now separates the published, installed and operationally validated versions instead of treating “latest” as “validated”.
- Validation clearly reports pending, failed or completed from local capture, portal, database and rollup health; unsupported upgrade paths are identified from `min_upgrade_from`.
- Status remains local and opt-in: no customer registry, HWID, hostname, IP, settings or secrets are sent to a central service.

### Process
- Contract tests cover version states and compatibility; release invariants require viewer authentication, four separate blocks and zero I/O per request.

## [2.148.0] — 2026-06-27

### Added — bounded on-demand media jobs
- Audio, PCAP and DTMF generation now share one bounded FIFO queue, preventing uncontrolled Python processes from competing with capture, the portal or PostgreSQL.
- Concurrency, queue depth, per-job memory and timeout derive from CPU/RAM with safe settings clamps; disconnects and timeouts cancel Python and ffmpeg together.
- Operational health now exposes aggregate queue state and metrics without call IDs or PII.

### Process
- Tests cover hardware clamps, FIFO order, saturation, cancellation and timeout; release invariants enforce memory limits and the shared runner.

## [2.147.1] — 2026-06-27

### Changed — frontend modularization, phase 1
- The CSP-safe dynamic-style adapter now lives in a small autonomous runtime module, preserving the existing DOM, UX, translations and initialization order.
- The new self-hosted asset is included by pkg, the signed build and the installer; no CDN or inline script was introduced.

### Process
- A Chrome headless smoke covers initial and dynamically inserted DOM nodes under strict CSP, while release invariants enforce load order and complete asset registration.

## [2.147.0] — 2026-06-27

### Added — shared settings schema, phase 1
- Audio, trace and CDR retention thresholds now derive their defaults, validation ranges and UI metadata from one authoritative schema while preserving all existing values and limits.
- Partial settings updates, older settings files and masked-secret round trips remain backward compatible.

### Process
- A release-blocking drift detector compares the schema with UI controls and engineering documentation. Five tests cover defaults, clamps, partial updates, old files and public metadata.

## [2.146.1] — 2026-06-27

### Changed — formal, observable database migrations
- Updates now apply ordered, transactional SQL migrations after the backward-compatible `schema.sql` baseline.
  Applied versions record an immutable SHA-256 checksum, timestamp and duration; concurrent installers serialize
  through an advisory lock and reruns skip completed work.
- The safe transition starts at schema 8 without moving historical DDL, building large indexes or backfilling data.
  Fresh installs, reruns and upgrades from schema 7 use the same tested path.

### Process
- Release checks reject destructive migration SQL and blocking index creation, and verify that the runner and SQL
  files are present in both the package and installer.

## [2.146.0] — 2026-06-27

### Added — sanitized support ticket bundle
- Authenticated `GET /api/support-bundle` exports an attachable JSON snapshot with installed/published versions,
  fault domain and owner, component status, metrics, verified dependencies, and input/process/output signals.
- The bundle is allowlist-only and excludes settings, logs, secrets, credentials, PII, audio, and raw SIP.
- Adversarial tests inject tokens, email, phone, IP, SIP URIs, and connection strings and require zero leakage.

## [2.145.0] — 2026-06-26

### Added — unified operational health
- A fast, responsive Health view now combines capture, portal/heap, database, rollups, system incidents and update
  availability in one place, with English and Spanish presentation.
- Its authenticated `GET /api/operational-health` contract serves in-memory snapshots only: no database query,
  process execution, filesystem read or network request occurs while loading the view.
- Snapshot age is explicit, and missing, stale or recently failed signals degrade health instead of appearing green.

## [2.144.2] — 2026-06-26

### Changed — first backend module boundary
- Release discovery was extracted from the main server into a tested peripheral module while preserving API
  responses, update gating, cache behavior, timeout and bootstrap timer order.
- Added deterministic parity/failure coverage and an executable infrastructure-map consistency check. Capture,
  correlation, database behavior, settings and public contracts are unchanged.
- The release pipeline now verifies the publisher account's repository permission and always restores the personal
  source account, preventing partial releases caused by whichever GitHub CLI account happened to be active.

## [2.144.1] — 2026-06-26

### Fixed — portal stability during retention purge
- Incremental working-set purge is now **enabled by default** (`VW_INCR_PURGE=0` is the rollback switch). On high-volume
  installs, retention purge could trigger repeated full parses shortly after boot, pushing the V8 heap into an OOM
  restart loop. Purge now evicts/rebuilds from the in-memory window instead of re-reading the whole window from
  PostgreSQL.
- Full parses now log their reason (`boot-fast`, `boot-backfill`, `purge-full`, `cap-trim`, etc.) to make future
  diagnostics explicit.

### Security — minimal anonymous `/api/health`
- When authentication is enabled, anonymous `/api/health` now returns only minimal liveness
  `{ok, license.valid, ts}`. Capture details such as ports, workers and drops require a valid JWT.

## [2.144.0] — 2026-06-25

### Added — Configurable anti-fraud from the Fraud tab (engine on/off, threshold, velocity cap)
- **Anti-fraud engine controls in the Fraud tab** (Fraud → Configuration, admin only): a new card to **turn the engine
  on/off**, tune the **model threshold** (`score_min_critical`) and set a **global velocity cap** — no need to dig into
  Settings anymore. These now live next to the rest of the anti-fraud configuration.
- **Per-destination velocity cap** (`velocity_max_calls`, IRSF velocity): a new detector that alarms when a single
  destination exceeds N calls within the live window (traffic sweep). Ships **OFF** (0 = disabled, conservative flag);
  works from day one (no mature history needed, like the short-call storm). Severity **warn**, or **critical** if the
  destination is high-risk. Configurable globally and **per profile** (a profile can override the global cap).
- It is a **deterministic standalone rule**: it does NOT feed the trained logistic model (its production output is
  unchanged) and is NOT downgraded by the score-gate. The "what would have alerted" simulator neutralizes it (like the
  short-call storm) because it aggregates hourly while the cap is per-window.

### Notes
- Zero changes to the sniffer hot-path. With `velocity_max_calls=0` the engine behaves identically to before (covered by
  tests). Full es/en i18n.

## [2.143.0] — 2026-06-25

### Added — Fraud tab · P4 (the "what would have alerted" simulator) — tab COMPLETE
- In Fraud → Configuration: a **simulator** that runs the anti-fraud detectors against the last N days of
  history (read-only, creates no incidents) and shows how many critical/warn alerts would have fired, with
  examples. Closes the loop: configure countries/profiles → simulate against real data → trust them.
- This **completes the Fraud tab**: operational panel + assign profile to trunk + risk-country/profile editors
  + simulator.

## [2.142.0] — 2026-06-25

### Added — Fraud tab · P3c (fraud profile editor)
- In the Fraud tab → Configuration (admin) you can now **create, edit and delete fraud profiles**: name,
  destination **whitelist** (never alarm), **watchlist** (extra scrutiny), and thresholds (short-call storm,
  new destination, high-risk, international %). Empty fields inherit the global config.
- Profiles appear immediately in the "Fraud profile" selector of the Trunks catalog.
- This completes the manual config flow: risk countries + profiles + assignment to trunks. Only the
  "what would have alerted" simulator remains (next phase).

## [2.141.0] — 2026-06-25

### Added — Fraud tab · P3b (Configuration sub-view: risk-countries editor)
- The Fraud tab now has **Panel** and **Configuration** sub-tabs (the latter admin-only).
- **High-risk (IRSF) countries editor:** add/remove ISO-2 country codes as chips and save — no need to go
  through Settings. Pre-loaded with the standard IRSF list. Confirms before clearing the list (so you don't
  disable high-risk detection by accident).
- Coming next: the profile editor (create/edit) and the "what would have alerted" simulator.

## [2.140.0] — 2026-06-25

### Added — Fraud tab · P3a (assign a fraud profile to each trunk)
- The trunk editor now lets you pick the trunk's **Fraud profile** — the anti-fraud rules applied to that
  trunk. Empty = inherit the global config. (The profiles backend shipped in v2.138.)
- Coming next: editors for risk countries and profiles, and the "what would have alerted" simulator.

## [2.139.0] — 2026-06-25

### Added — Fraud tab · P2 (operational panel)
New **Fraud** tab (after Dashboard) — the visible face of anti-fraud.
- **Operational panel:** engine status, KPIs (open fraud incidents, score gate, model/AUC, trunks with a
  profile) and a table of **recent fraud events** (severity · score · event · status).
- Summary of the available **fraud profiles** and configured **high-risk countries**.
- Read-only for now; editing risk countries/profiles and assigning them to trunks arrive in the next phase.

## [2.138.0] — 2026-06-25

### Added — Fraud tab · P1 (per-trunk fraud profiles, backend)
First phase of the dedicated Fraud tab. This release is **backend only** (the UI lands in later phases); nothing
changes until a profile is assigned to a trunk.
- **Fraud profiles** assignable to trunks: a profile sets only the thresholds/lists it wants (destination
  **whitelist**, watchlist, expected international %, storm/new-destination/high-risk thresholds) and **inherits
  the rest from the global config**. Three factory profiles: *Retail/domestic*, *International wholesale*,
  *Restricted/premium*. No profile → behavior identical to today.
- The anti-fraud engine now evaluates **each trunk with its profile** (a whitelisted destination never alarms for
  that trunk — a big false-positive reducer for wholesale).

## [2.137.0] — 2026-06-25

### Changed — Robustness (maintenance release)
- **Timeout on EVERY AI call:** the copilot, the incident investigator, alarm analysis and alert translation now abort after 90s (8s on the notification path) if the AI provider stops responding — previously a hung AI provider could block those flows indefinitely. Capture was never affected.
- **`incidents.translate_alarms` can now actually be turned off** (it's persisted and honored in Settings/API; the setting used to be silently dropped).
- **Incident sub-config preserved:** the `recurrence` / `notify_throttle` / `chronic_mode` settings are no longer lost when saving other Settings changes.

## [2.136.0] — 2026-06-25

### Added — Automatic alerts in each recipient's language
- Automatic alerts/incidents (Telegram + email) are now delivered **in each recipient's language** based on their per-user preference (v2.135), not in a single global language. The global NOC room keeps the product's global language.
- The **AI diagnosis** (generated in Spanish) is **translated** to the recipient's language when it differs, **grouped by language**: a single LLM call per distinct language among recipients (cached). A single-language install (e.g. everyone in Spanish) makes **no extra calls** — same cost as before.
- Robust: translation is best-effort with a **hard time cap** (if the AI is slow or fails, the original diagnosis goes out without delaying the alert — the notification path never blocks). Configurable via `incidents.translate_alarms` (default ON).
- Note: the incident **template** (title/KPIs/recurrence) is offered in en/es; a recipient whose interface language is another one receives the template in the global language with the AI diagnosis translated. Extending the template to more languages = template i18n (on demand).

## [2.135.0] — 2026-06-25

### Added — Per-user language: interface + AI
- Each user now picks their own **interface language** and **AI language** from their Profile — it's no longer a single global setting. Handy when several people share an install, or when someone wants the AI in their language (e.g. Hindi) even if the UI is in English.
- The **interface language** is now remembered per user (it used to live only in the browser) and is applied on sign-in.
- The user's **AI language** offers "Auto" (= follow their interface language) or a specific one (any of ~40 languages, with a search box). The interactive copilot diagnostics (trace, trunk, overview) reply in the user's language.
- Fully backward-compatible: anyone who doesn't choose inherits the previous behavior (browser language / the product's global setting). The global AI language in Settings remains the **product default**.
- Note: the interface is offered in languages with a complete dictionary (en/es); more are added on demand. Automatic alerts in each recipient's language land in the next release.

## [2.134.0] — 2026-06-25

### Added — AI now speaks EVERY language (not just English/Spanish)
- The **language of AI insights** (copilot, alarm analysis, summaries) is no longer limited to English/Spanish: it now supports **any language** (Hindi, Bengali, Arabic, Chinese, etc.). The LLM is natively multilingual — it is instructed to "respond in <language>" and writes the diagnosis directly in it; technical data is passed as-is and VoIP terms (SIP codes, ASR, NER, MOS…) stay in their standard form.
- The AI language selector (Settings → AI Chat) already offered the full searchable list; the backend now honors it. `auto` follows the portal language.
- Note: this is **only the AI language**. The **interface** stays in its loaded languages; more are added on demand.

## [2.133.1] — 2026-06-25

### Changed — Onboarding: spells out what the tool needs to work well
- **"Getting started" now marks as ESSENTIAL** HEP capture receiving traffic and **labeling your SBCs' internal IPs** (IP Directory). Without your own IPs labeled, VoxyWatch attributed calls to the wrong trunk and the AI diagnosed incorrectly — the checklist now asks for it explicitly.
- **Maturity notice:** added a note that AI, patterns and anti-fraud **learn from your traffic and need ~2 weeks of data** for accurate diagnoses.
- The **IP Directory** hint now explains those are your **internal/own** IPs (not the carriers') and why it matters. Localized (5 languages).

## [2.133.0] — 2026-06-25

### Changed — Settings UI polish (more comfortable and consistent)
- **Tabs no longer disappear when scrolling:** the header and tab bar stay pinned at the top; only the panel content scrolls. The tab bar is no longer clipped by its scrollbar.
- **Settings window wider by default** (1180 px) so the tabs fit without a horizontal scrollbar. Shrinking the window brings the scrollbar back as before.
- **HEP Capture in 2 columns:** sniffer status + ports on the left, performance/capture on the right (the right half used to be empty).
- **SNMP in 2 columns:** general config on the left, SNMPv3 + traps on the right, agent status full-width at the bottom (previously stacked blocks).
- **No spinner arrows on Settings numeric fields** (traps/thresholds, alarms, SNMP…) — the operator just types the value.
- **Revamped AI language selector:** searchable menu with every language; Auto, Spanish and English pinned at the top.
- **License fully localized:** the "Need a license?" notice now follows the portal language (it used to show in Spanish even in English).

## [2.132.3] — 2026-06-25

### Changed — Installer fully in English (international customers)
- Every message the installer prints to the screen (`install.sh`: notices, errors, progress, countdown, final summary, updates section) is now in **English**. Some were still in Spanish. No logic, path, variable or color changed — only the visible text.
- `tools/get-hwid.js` (run by the customer to obtain their Hardware ID when purchasing a license): banner in English.

## [2.132.2] — 2026-06-25

### Fixed
- **Incident title now matches its severity on escalation:** an incident that opened as "warn" and rose to "critical" kept the "…warn" title (with critical severity) — confusing for the operator. On escalation/relapse the title and its i18n params are now refreshed to reflect the effective severity.
- **Portal heap: removed the placebo `NODE_OPTIONS=--max-old-space-size`.** The packaged binary (pkg/SEA) ignores that flag (V8 creates its isolate from the snapshot before reading flags), so the portal always ran on V8's default heap, not the value it appeared to set. Not a regression: the working set auto-sizes to the real heap limit and the heap self-protection (v2.132.0) trims under pressure — the historic OOM (TICKET-032) was closed by that plus moving the raw SIP out of the heap, never a larger heap. Dead config that misreported the real limit is removed.

## [2.132.1] — 2026-06-25

### Changed — Larger working set, same safety (recalibrated with real measurement after Mem#1)
- After moving the raw SIP out of the heap (v2.132.0), the per-row RAM cost of the working set was recalibrated from **8 KB → 4 KB** using a real production measurement (209k messages ⇒ ≤3.8 KB/row attributing the entire heap to SIP rows; the marginal cost is lower). The working-set ceiling rises from **250k → 350k** rows. Result: on small boxes the correlation working set nearly doubles (e.g. ~76k → ~157k rows) and large boxes gain headroom — all within the heap, never approaching OOM because the heap self-protection (v2.132.0) remains the safety net if the estimate fell short. No operator-facing change; zero hardcode.

## [2.132.0] — 2026-06-24

### Added — NOC: incident temporal pattern + chronic-mode learning
- **Temporal pattern ("usually overnight / on Mondays"):** when an incident recurs, the alert now says *when* it tends to happen — the time-of-day window (local time) and/or the day of week where it concentrates (e.g. *"🕒 Temporal pattern: mostly between 01:00 and 04:00 (100%); mostly on Mondays (83%)"*). It only asserts a pattern with real concentration (≥60% in a 3 h window or a single day) over ≥5 occurrences in 30 days — noise control: never invents a pattern from thin data.
- **Chronic mode remembers what fixed the pattern:** the structural-action proposal now cites the previous manual resolution(s) of the same pattern (*"💡 Resolved 3 times before; last time: …"*) — turning case memory into a concrete recommendation, not just "pick an action".

### Changed — Portal memory stability: OOM fixed at the root (TICKET-032 + structural)
- **Raw SIP leaves the heap (−35-40% RSS):** the working set no longer retains the full SIP text of each message (~553 B × hundreds of thousands ≈ 285 MB); it pre-extracts only the scalar fields correlation needs and serves the full SIP on demand from the database (in /flow, /lint and the copilot). The CDR is **byte-identical** (parity validated). This is the proper root-cause fix following the TICKET-032 mitigation.
- **Pre-OOM self-protection (degrade, don't crash):** the portal watches real V8 heap pressure; under pressure it trims the working set in a controlled way and opens a capacity incident with an alert, instead of dying and restarting. When pressure eases it restores capacity and closes the incident. The working-set peak adapts to real pressure (not a fixed multiple).
- **Auto-tuned V8 heap (TICKET-032):** the installer sets the portal heap limit from the box's RAM (30%, between 2 and 16 GB) and the working set is derived from the real heap, not total RAM — eliminating the OOM/restart loop under high volume. Zero hardcode, auto-adapting to any hardware.

### Fixed
- **Login: requests to `/api/settings` and `/api/time` before authenticating returned 401** in the console — the clock/header now load server data lazily (only with a session), retrying on a transient 401.

## [2.131.0] — 2026-06-24

### Added — actionable chronic mode (the bot proposes a structural fix, not just alerts)
- **Measured problem:** human intervention on incidents is <1% (45 actions vs 5,336 closures in 14 days) — almost everything auto-resolves and reopens, and alerting on every reopening doesn't fix it.
- **Solution:** when a trunk is **chronically persistent** (≥20 reopenings in 7 days across ≥4 distinct days), instead of alerting on each one, the bot sends **one** structural-action proposal over Telegram with buttons: **📊 Recalibrate thresholds** (re-derives that trunk's thresholds via auto-calibration), **🔕 Acknowledge (known degradation)** (silences that trunk for N days — still recorded and shown in the digest, reversible, auto-expires), and **🔍 Investigate**. It won't propose again until the cooldown (7 days) passes.
- **Guarantees:** the bot NEVER touches the customer's SBC (actions operate only on VoxyWatch); always human-approved; closed, audited action catalog. A `critical` incident never enters chronic mode (never silenced or downgraded — always notifies). Configurable (`incidents.chronic_mode.*`), bilingual EN/ES.

## [2.130.0] — 2026-06-24

### Added/Changed — incident messaging polish (digest, persistent noise control, title i18n)
- **Digest now lists the most recurring trunks:** the daily/weekly summary shows the trunks that reopened most in the period (`🔁 Most recurring: name (N)…`) — what noise control consolidates stays visible, not just the total.
- **Noise control survives restarts:** the per-day, per-fingerprint alert cap is now seeded from the database on startup (counting alerts already sent today), so a restart (e.g. after an update) no longer re-notifies a chronic incident already announced. The first occurrence of the day and escalations still always pass.
- **Incident titles in the client's language:** pattern and fraud alarms (and other types) now appear translated in the Telegram/email message (some previously fell back to the English text). Bilingual EN/ES.

## [2.129.1] — 2026-06-24

### Changed — update flow messages (POST /api/update) in English
- The messages shown to the admin when triggering an update from the portal are now in English (update starting, no update available, could not verify, and the "apply as root" fallback when systemd/polkit doesn't authorize it). Intended for international deployments (e.g. the public demo). The manual command and the technical `details` of the failure are preserved for diagnosis.

## [2.129.0] — 2026-06-24

### Added — common root cause (cross-entity correlation) + structured LLM diagnosis
- **"Not just this trunk" (correlation by SBC/IP):** when several trunks degrade at once, VoxyWatch now detects whether they share a common cause — the same destination IP or the same SBC concentrating the failures. Instead of N separate alarms, the incident points it out: *"🔗 Not just this trunk: 4 trunks failing to the same SBC 200.0.90.116 → check it, likely the common cause"*. Computed live over the working set (one pass, only when ≥2 trunks are in alarm) and also fed to the AI diagnosis so it targets the common peer rather than each trunk separately.
- **Structured LLM diagnosis (function-calling):** the investigator now emits the diagnosis by calling a typed tool (`report_diagnosis`) instead of asking for JSON-in-text. This eliminates the truncated/malformed diagnoses some models produced. Multi-provider (OpenAI/Anthropic/Google/OpenRouter); if a model doesn't use the tool, it falls back to the existing robust text parsing. The general chat is unaffected.

## [2.128.0] — 2026-06-24

### Changed — incident LLM diagnosis: more robust and recurrence-aware
- **Complete diagnoses (no truncation):** the auto-investigator had a fixed token cap (1100) that sometimes cut the diagnosis JSON mid-sentence (incomplete diagnoses like "…with PDD"). The budget is now dynamic: more headroom for critical or chronic incidents (2000) and enough for the rest (1400).
- **Recurrence-aware:** when investigating, the model is now told how many times the incident reopened (and its typical duration); if chronic, the diagnosis says so explicitly and steers the recommendation toward a **structural fix** rather than a temporary patch, referencing a prior manual resolution of the same pattern when one exists. Completes the bot-messaging improvement trilogy (v2.127 + v2.128).

## [2.127.0] — 2026-06-24

### Added — NOC bot messaging: plain language, recurrence memory, rich recovery, noise control
Incident notifications (Telegram/email) were redesigned so anyone can understand them and so the bot "remembers" — a direct operator request. Four improvements, all with no extra AI cost:
- **Recurrence memory:** every alert now states whether the incident happened before — `🔁 Recurring — 6× in 24 h · 15× in 7 days, ~78 min each`, or `🔁 CHRONIC — 30 reopenings in 7 days… needs a structural fix` for persistent ones (configurable `incidents.recurrence.*`). If there was a prior manual resolution, it is quoted: `💡 Last time it was resolved: "…"`. Comes from a cheap query over `incidents`; never touches `calls`.
- **Layered plain language:** a human line on top (`📉 only 1 in 10 calls answered (ASR 9.8%) · many calls fail in the network`) and the usual technical line (ASR/NER/MOS/PDD) below for the NOC. Severity as a word (🔴 CRITICAL / 🟡 WARNING) and local start time.
- **Rich, honest recovery:** on recovery it shows duration, what actually improved (`📈 Improved: NER 17.6%→36% · MOS 2.03→2.26` — only deltas in the right direction; if nothing improved it says `✔ Returned to normal range`), whether it was automatic or manual, and how many times it happened today.
- **Chronicity-based noise control:** consolidates redundant reopenings of chronic trunks (1 alert/day; the rest go to the digest) while letting sporadic ones through. NEVER silences a critical, an escalation, the first occurrence of the day, or fraud/capture/system alarms. Measured against 7 real days: −36.4% of alerts with no signal lost. Configurable and reversible (`incidents.notify_throttle.*`).
- Fully bilingual EN/ES.

## [2.126.3] — 2026-06-23

### Fixed — realistic "Simultaneous calls" concurrency: served from real sampling, not the rollup ledger
- **The concurrency series read ~170× too high at peak (measured in production: 130k–171k vs ~770 actual).** Definitive root cause: the chart was computed from the rollup `Σtotal − Σend` ledger, and at peak the rollup's `ended` undercounts due to heap-fetch (the `calls` visibility map isn't all-visible under constant writes). That debt **is not a constant offset — it grows precisely during peak hours**, so it distorts the curve's shape, not just its level (even anchoring to the live value left false ~40k spikes). The `ended` ledger is unrecoverable for peak concurrency.
- **Fix:** the "Simultaneous calls" series is now served from **real working-set sampling** — `capacity_samples.concurrent`, which counts exactly the same thing as the `active_now` KPI (calls with `call_result='active'` in RAM) but over time. The profiler is ON by default (one sample every `interval_min`, default 5min; 30-day retention) and the table is tiny → a cheap query that **doesn't touch `calls`**. MAX per bucket (= peak simultaneous) + level carry-forward for buckets without a sample. Its latest sample matches `active_now` exactly. Validated against production: a 6h range went from 130k–171k down to **776–2531** (avg 1659).
- The previous ledger remains only as a **fallback** for installs with the profiler disabled, just-booted with no samples yet, or historical ranges deeper than the sample retention.

## [2.126.2] — 2026-06-23

### Fixed — fine dashboard series under daytime peak (1-min rollup window 4h → 45min)
- **Under daytime peak (~300-500k calls/h) the recent tail of the fine series (1h/6h volume and concurrency) still showed 0.** Measured cause: the covering `idx_calls_start_cr` does NOT yield a true index-only scan — `calls`'s visibility map isn't all-visible under constant writes → ~816k heap fetches; the 1-min query over 4h took 79s+ and got cancelled by the 120s `statement_timeout` under contention. **Data-driven fix:** the real call-duration profile shows only 0.17% of calls last >15min (0.013% >45min), so the 1-min rescan window dropped from **4h to 45min**: captures 99.99% of late-arrivals, the query falls to ~30s (well within budget), timeouts gone. Long-range accuracy is covered by the hourly rollup; 1-min undercount < 0.01%.

## [2.126.1] — 2026-06-23

### Fixed — inflated concurrency ("Simultaneous calls") + startup blocked by indexes in schema.sql
- **Inflated concurrency (~24k vs ~hundreds real):** the simultaneous-calls series is a `Σstarts − Σends` ledger. The rollup's `ended` query was still slow (70s → cancelled) because the planner preferred the smaller old index `idx_calls_ended_ts` (no `call_result`) over v2.126's covering `idx_calls_ended_cr` → `ended` was **chronically undercounted** → the ledger subtracted too little and concurrency grew unbounded. **Fix:** drop `idx_calls_ended_ts` (the covering replaces it and forces the index-only scan); the rollup backfill re-populates `ended` → concurrency rebalances within hours.
- **Portal startup blocked during the v2.126 update:** the covering indexes were in `schema.sql`, which the updater applies in a BLOCKING way → creating several GB of index over the already-populated `calls` froze startup ~10 min (capture was never affected; separate service). **Fix:** large indexes are created ONLY in `ensureSearchIndex()` with `CREATE INDEX CONCURRENTLY` (not in `schema.sql`) → startup no longer blocks on large installs.

## [2.126.0] — 2026-06-22

### Fixed — covering indexes: fine dashboard series (volume + concurrency) scale under peak load
- **Completes v2.125.0:** at ~500k calls/h the per-minute rollup (`call_stats_1m`) still didn't finish within the `statement_timeout` → the short-range series (volume 1h/6h and **"Simultaneous calls"/concurrency**) stayed at 0 on the tail. Root cause measured with `EXPLAIN (ANALYZE, BUFFERS)`: not the GROUP BY but the **heap fetch for `call_result`** (247k rows → ~500k buffers, 182k read from disk, ~2 buffers/row).
- **Fix:** two **covering indexes** (`idx_calls_start_cr` on `start_ts`, `idx_calls_ended_cr` on `COALESCE(last_ts,start_ts)`, both `INCLUDE (call_result)`) → enable **index-only scan** in the aggregation: it reads only the (compact) index, never the heap → the query fits the time budget even cold under peak. Benefits volume **and** concurrency, the 1-min **and** hourly rollups. Created `CONCURRENTLY` at startup (never block capture), additive and idempotent. Keeps the 4h window (no undercount of long calls).

## [2.125.0] — 2026-06-22

### Fixed — dedicated pool for the dashboard rollup (volume charts stuck at 0 under peak load)
- **At high volume (~500k calls/h) the dashboard volume charts went to 0 on the recent tail.** Root cause: the `call_stats_hourly` and `call_stats_1m` rollups ran on the ingest pool (`getPool`, no `statement_timeout`). Under peak, an aggregation query could hang with no cap → the `await` never resolved → the busy guard was never released → every subsequent tick returned early → the rollup stayed **stuck until restart**. Capture and raw data were always intact (capture has priority); only the chart refresh froze.
- **Fix:** new **dedicated `getRollupPool()`** (`max:3`, `statement_timeout:120s`), mirroring the read pool. It gives aggregation its own lane (no longer queued behind ingest writes) and a finite timeout: if a query hangs under peak it **fails and releases the guard** → the next tick retries and, once the peak eases, it catches up by re-scanning the last 4h (no data lost). Boot-time backfills (full rebuild, 12h catch-up) intentionally stay on the untimed pool — they are long, legitimate scans and not self-healing.

## [2.124.0] — 2026-06-21

### Added — per-trunk auto-calibrated thresholds (predictive/ML)
- **Each trunk can be judged against its OWN learned normal instead of a global threshold.** New `trunk_health.auto_calibrate` (default OFF): a trunk with a mature baseline derives its thresholds (ASR/NER/5xx/MOS/loss/PDD) from `median ± k·MAD` of its history (same math as the "Suggest thresholds" button). A wholesale trunk normally at 25% ASR stops alarming at 25%; a 90% retail trunk alarms if it drops to ~80% (which a global 50/25 missed). Precedence: global < traffic profile < auto-calibration < manual override (manual always wins). Also configurable in Settings → Trunk Health. Exposes `auto_calibrated` per trunk. Ships OFF → validate before enabling.

## [2.123.1] — 2026-06-21

### Added
- **Pattern-alarm controls in the UI (operator-configurable).** Settings → Alarms now exposes the two toggles that control pattern-alarm volume: "Per-trunk pattern alarms" (`per_trunk`; OFF = global only, avoids duplicating trunk_health) and "Alarm on volume drops" (`volume_both_dirs`; OFF = spikes only). Previously API-only; now the operator tunes them directly.

## [2.123.0] — 2026-06-21

### Fixed — seasonal pattern alarm flood (FP reduction)
- **The pattern detector generated too many alarms; two causes, both fixed.** (1) The VOLUME metric did not respect `min_volume` (ASR/PDD did) → low-traffic trunks/hours fired volume drop/spike on noise; volume is now only judged when the bucket norm is ≥ `min_volume`. (2) New `pattern_alarms.per_trunk` (default true): per-trunk pattern alarms duplicated the seasonal deviations `trunk_health` already emits (`health_bl_*`, robust baseline); with `per_trunk=false` only the GLOBAL (aggregate) pattern remains, removing double-alarming the same trunk. Volume drops (`vol_low`) are controlled by `volume_both_dirs`.

## [2.122.0] — 2026-06-21

### Added — insufficient-sample KPIs greyed out (Monitoring)
- **Trunks with few calls (< `min_calls`) no longer mislead the eye.** The % of 2-3 calls is statistical noise (and does not alarm, thanks to Wilson/min_calls since v2.114) but the table still painted it red. Those rate KPIs (ASR/NER/MOS/loss/PDD/5xx) now render in GREY, no heat coloring, with the calls column marked ⚠ and an "insufficient sample" tooltip. Backend exposes `low_sample`/`min_calls` per trunk. Display only; the alarm engine is unchanged.

## [2.121.0] — 2026-06-21

### Added — fraud model score-gate (NOC ML F1: shadow → action)
- **The fraud model now REDUCES false positives.** New `fraud_alarms.score_min_critical`: if the trained model scores a fraud event below the threshold, its incident is downgraded critical→warn (not hidden — just stops paging as critical). Validated in production: `high_risk` criticals (typically transient blips) score ~4 → warn; a serious `intl_spike` scores ~53 → stays critical. 0 = off (shadow only). Model still trained off-box (Option A).

## [2.120.0] — 2026-06-21

### Fixed — `calls` autovacuum (anti-bloat lock; closes #1b)
- **Large-scale CDR counts are fast again and stay that way.** Root cause: the default autovacuum (fires at 20% dead tuples) was too slow on an 88M-row, heavily-updated table → 16M dead tuples, stale visibility map, time-bounded COUNT lost its index-only scan (24h took ~2 min). Permanent fix: `calls` lowers its autovacuum threshold to 2% (`autovacuum_vacuum_scale_factor=0.02`) — in `db/schema.sql` (new installs) + idempotent boot migration (existing installs). Keeps vacuum current so counts stay fast. (Plus a one-time cleanup VACUUM on the production box.)

## [2.119.1] — 2026-06-21

### Added
- **`anomaly_score` visible in Monitoring (shadow).** Optional "Anomaly" column + chip in the trunk detail, to watch the multi-metric score before enabling its alarm (`anomaly_alerts`). Display only (read-only).

## [2.119.0] — 2026-06-21

### Added — multi-metric anomaly (NOC ML F3)
- **Per-trunk MULTI-METRIC anomaly score.** Combines (L2 norm) the robust z-scores of metrics deviating from their seasonal baseline at the same time (ASR/NER/5xx/MOS/loss/PDD/volume) → catches "several things slightly wrong together" that no single threshold fires on. Reuses already-computed z-scores (no extra cost). Always exposed in health (`anomaly_score`, `anomaly_metrics`) in shadow mode; the `health_anomaly` alarm (warn) only if `anomaly_alerts`=1 (ships OFF) and ≥2 metrics contribute. Completes NOC ML F1/F2/F3.

## [2.118.1] — 2026-06-21

### Fixed
- **Forecast: its own maturity threshold (2) instead of the alarm one (4).** With a young baseline (~18 days), hour-of-week buckets did not reach 4 samples and the forecast came back with zero coverage. Forecast is informational and carries a confidence band → tolerates thinner buckets; improves as the baseline matures.

## [2.118.0] — 2026-06-21

### Added — per-trunk forecast (NOC ML F2)
- **Volume/ASR forecast per trunk for the next hours.** `lib/forecast.js` (pure) combines the already-learned seasonal profile (the persisted 168-bucket day-of-week×hour baseline) with the recent level (Holt-Winters-style multiplicative correction) → predicts the next H hours with a confidence band (±MAD). Reuses the baseline (no expensive recompute), honors its maturity (immature buckets → no prediction). Exposed at `GET /api/trunks/:id/forecast?metric=vol|asr&hours=24` (operator+) and as the copilot tool `forecast_trunk` to anticipate volume peaks / ASR dips (capacity planning). Read-only; inference never touches the hot path.

## [2.117.0] — 2026-06-21

### Added — trained fraud model (NOC ML F1, Option A)
- **Fraud scoring with a LEARNED model, trained off-box.** Fraud `score()` moves from heuristic weights to a **logistic-regression** model trained on real history (`tools/train_fraud_model.py`, dependency-free). Label: event persistence/seriousness (real fraud vs transient blip). On-box inference is trivial (never touches the hot path); weights live in `settings.fraud_alarms.score_weights` (official config, no hand-patch), retrainable. `score()` is now additive in log-odds (includes `sev_critical`). Still in shadow mode (reports `fraud_score`, no alarms) pending validation against rules. See `docs/DESIGN_NOC_ML.md`.

## [2.116.0] — 2026-06-21

### Added / Changed — app-improvement batch
- **Auto-calibration in the UI (#3).** Settings → Alarms: a "Suggest thresholds" button shows, per trunk with a mature baseline, current→suggested thresholds (median ± k·MAD) for ASR/5xx/MOS. Advisory; apply per trunk or via the copilot. Reuses `GET /api/trunk-health/suggest`.
- **Credible MOS (#2).** The dashboard MOS KPI shows measurement coverage in the tooltip when data exists, and "—" with the reason (e.g. low coverage with RTCP-only sources) when it is not representative — instead of a misleading number.
- **Onboarding: label SBCs/IPs (#4).** New recommended first-steps item: label your SBC/carrier IPs and the capture device. Without it CDRs show raw IPs and the "SBC IP / label" column is confusing.
- **Fraud scoring — shadow scaffold (#5).** A new 0-100 per-trunk score combining anti-fraud signals. Shadow mode for now: informational (`fraud_score` KPI on the incident + log when high), creates no alarms. Weights will be replaced by a model trained off-box and distributed signed (Option A; see `docs/DESIGN_NOC_ML.md`) — on-box inference is trivial and never touches the hot path.

## [2.115.0] — 2026-06-21

### Added — persistent per-trunk baseline (accurate alarms from boot)
- **The seasonal per-trunk baseline is now persisted to disk (gzip) and restored on boot.** It previously took ~5 min to rebuild after each update/restart (measured by the v2.114 A/B): during that gap alarms ran with no baseline (no deviations, no adaptive degradation). It is now restored instantly (`voxywatch_trunk_baselines.json.gz`, same pattern as the v2.69 working-set snapshot) and the normal refresh replaces it with fresh data once the DB is ready. Stale snapshots (> baseline_days×2) are ignored. The seasonal Map keys (168 buckets) are serialized/restored intact.

## [2.114.2] — 2026-06-21

### Changed
- **FP reduction (A/B on the production box): baseline VOLUME-deviation alarm now ships OFF (`baseline_vol_alerts`).** It is the noisiest with a young seasonal baseline (few-week buckets → unstable MAD) and the least actionable (a volume drop is not a quality problem). The operator enables it once the baseline matures. QUALITY deviations (ASR/NER/5xx/MOS/loss/PDD) remain active.

## [2.114.1] — 2026-06-21

### Fixed
- **FP reduction (A/B-validated on the production box): baseline VOLUME deviation no longer alarms in off-peak hours.** Overnight, with a young seasonal baseline (MAD floored at 1), a trivial drop (5→1 calls/h) fired `health_bl_vol_drop`/`spike` (10 false ones in the test). Volume deviation is now only evaluated when the bucket's hourly median is ≥ `min_calls` (meaningful volume). The rest of the baseline (ASR/NER/5xx/MOS/loss/PDD) is unchanged.

## [2.114.0] — 2026-06-21

### Added / Changed — trunk-alarm false-positive reduction
Attacks the root causes of FPs that manual threshold-lowering only patched.
- **F1 · Statistical confidence (Wilson).** Rate metrics (ASR/NER/5xx) are judged by the Wilson interval bound (95%): small samples have a wide interval and don't alarm (0/3 = 0% stops being noise); large samples ≈ point estimate. All absolute metrics (5xx/PDD/MOS/loss) now require `min_calls`. Flag `stat_confidence` (default 1).
- **F2 · Robust, seasonal per-trunk baseline.** Baseline moves from flat 14-day mean/σ to **median+MAD per hour-of-week** (168 buckets), built in the client timezone. "02:00 is compared against YOUR 02:00", not the daily average → kills the "every trunk alarms at night" class. Immature buckets stay silent (no fallback to the flat mean). Flags `baseline_robust` (default 1), `baseline_min_bucket` (default 4).
- **F3 · Exit hysteresis.** Incidents clear only after N consecutive ok/idle evals (`clear_sustain_evals`, default 2) — anti-flapping; respected by the reconciler too.
- **F4 · Auto-calibration (advisory).** `GET /api/trunk-health/suggest` and the copilot tool `suggest_thresholds` propose per-trunk thresholds from the learned baseline (median ± k·MAD). They change nothing: the operator applies them via the per-trunk override.

## [2.113.1] — 2026-06-21

### Fixed
- **Large-window CDR counts (production-scale follow-up to 2.113.0).** At production scale (86.9M rows) the exact 24h `COUNT(*)` takes ~65s and exceeds the budget → it previously fell back to the whole-table estimate (~85M, misleading for a 24h window whose real value is ~3.5M). Now, when the exact COUNT doesn't fit the budget (lowered to 15s to protect the read pool), the count is estimated PER WINDOW from the hourly rollup `call_stats_hourly` (≈ the window's real value), never the whole-table total. Small/medium windows still return an exact count.

## [2.113.0] — 2026-06-21

### Fixed — deep-QA findings (manual soak against the production box)
- **Large-window CDR counts no longer fall back to the estimate.** `/api/cdrs?since=<24h>` ran a `COUNT(*)` that exceeded the read-pool statement_timeout (5s) and showed the whole-table estimate (e.g. 85M for "24h"). The count now runs in a transaction with `SET LOCAL statement_timeout=25000` (same WHERE as the rows → coherent); huge ranges that still exceed it fall back to the estimate, flagged `count_exact:false`.
- **Non-numeric `?limit` no longer breaks to empty.** `?limit=abc` produced `LIMIT NaN` → empty/degraded. Inputs are now sanitized (bad `limit`→5000; bad `since/until/cursor`→null).
- **Global MOS is suppressed when measurement coverage is low.** With RTCP-only sources a tiny sample produced a misleading `avg_mos` (e.g. 1.62). The dashboard now exposes `mos_coverage_pct` and, if coverage of answered-with-MOS < 20%, leaves `avg_mos:null` with `mos_unavailable_reason:'low_coverage'`.
- **`total_with_audio` (in /api/stats) was wrong.** It counted already-reconstructed calls (audio_files.stereo) → returned 1. It now counts calls with recoverable RTP (same derivation as `has_audio`), plus a new `total_reconstructed`.
- **Clear message when listing AI models for a provider without its key.** `/api/ai/models` returned the raw SDK error ("invalid x-api-key"); it now explains the configured API key doesn't match that provider.

## [2.112.0] — 2026-06-19

### Added — AI Chat: Custom (OpenAI-compatible) provider, "Load models" in the UI, wider fields
- **"Custom (OpenAI-compatible)" provider + Base URL:** one option that covers Llama and most of the ecosystem (Groq, Together, Fireworks, DeepSeek, local Ollama, vLLM, LM Studio…). Configure it with Base URL + API key + model; `_callLLM`/`_listProviderModels` use the OpenAI format over the Base URL. Future-proof: a new OpenAI-compatible provider needs no code changes. New `ai_base_url` setting (validated http/https, admin-only; reaching localhost/LAN is intentional for local Ollama).
- **"Load models" button wired in the UI** (backend already supported it): fetches the provider's real, current models into a dropdown → **no hand-maintained model lists**. The text field stays as a fallback; picking from the dropdown fills it.
- **UI:** Token/Model/Base URL fields are now **wide** (the token used to be tiny at 180px) and the token keeps the 👁 reveal. The help text recommends "Load models" instead of listing default models.

## [2.111.0] — 2026-06-19

### Fixed — "zombie" incidents generalized to capture/system/volume (not just trunks)
v2.110 fixed zombie trunk incidents; the same pattern affected the `_incCondition`-based detectors (sniffer down, no sources, capture drops, system resource, global traffic drop): their sustain state lives in RAM and, after a restart, if the condition had already cleared, recovery never fired and the incident stayed open. Now, on the first tick after warm-up, `_incSustain` is **seeded** from the open incidents → the natural `_incCondition` recovery works again for all of those types. (sip_codes, source_silence, pattern and fraud already recovered unconditionally each tick; trunk_health is covered by the v2.110 reconciliation.)

## [2.110.0] — 2026-06-19

### Fixed — "zombie" trunk incidents (didn't auto-close after a restart)
Per-trunk alarm state lives in RAM (`_trunkAlarmState`); when the portal restarts, the recovery transition (warn→ok) isn't observed and the `trunk_health` incident stayed **open forever** even though the trunk was already ok/idle. With several restarts (e.g. a batch of updates) a backlog piled up, giving the impression that "every trunk is alarming". The engine now **reconciles every cycle** (and on the first tick after boot): it lists open `trunk_health` incidents and, for those whose trunk is now ok/idle (or has no traffic), marks them *recovered* → auto-resolve closes them after the stable window. It does not touch trunks still genuinely in warn/critical. Idempotent.

## [2.109.0] — 2026-06-19

### Fixed — CDR table "Answered"/ASR KPI now matches the dashboard
The CDR table header counted as "answered" only `call_result === 'answered'`, while the dashboard counts *answered + active* (a call in progress is already connected). That made the table show, e.g., "4 answered" while the dashboard reported ASR 12% over the same reality → confusing. The table now uses the **same definition** (answered + active) for the answered count, ASR and ACD. (No data changes: only the displayed metric; individual CDRs keep their real `call_result`.)

## [2.108.0] — 2026-06-19

### Added — CDR filters by trunk and country (phase 3)
Two new selectors in the CDR filter bar: **Trunk** (carrier) and **Country** (destination). They are populated from the values present in the loaded window (same pattern as Codec/Source), filter client-side instantly, and **the export honors them** (passed to the streaming endpoint, which applies them server-side on the projected CDR). They count toward the active-filter badge and "Clear all". Bilingual ES/EN.

## [2.107.0] — 2026-06-19

### Added — CDR table: real counts, server-side time window and full filtered export
The CDR table no longer caps at a fixed block of rows nor reports a whole-DB estimate as the total. Changes (with zero UX loss — column sort and every filter stay instant):
- **Server-side time-window load:** the table fetches the global time-range window (start_ts index), not just "the most recent rows" → the data and the count match that window.
- **Real count:** the header shows the real total for the time filter (exact COUNT when time-bounded; `~` estimate only for the full history, to avoid recounting 81M per request). `/api/cdrs` returns `count`/`count_exact`.
- **Page-size selector** is now 100/250/500/1000 (default 500).
- **Honest notice** when the real window exceeds what's loaded in the browser ("showing X of N — narrow the time range or export").
- **Full filtered CSV export via streaming** (`GET /api/cdrs/export.csv`): downloads everything matching the active filters (time + status + codec/MOS/source/trunk/number/IP/Call-ID/alerts), not just the visible page. The server pages by cursor and writes the CSV in chunks (never materializes the whole set). With a heads-up if there are many CDRs (approx size, or a suggestion to narrow if hundreds of thousands).
- ML/dashboard/alarms are unaffected: they keep querying the whole DB directly; this is only the table's view/transport.

## [2.106.0] — 2026-06-19

### Fixed — CDR table showed at most 1000 records
The keyset CDR read (`queryCallsKeyset`) had an internal **1000-row-per-page** cap that overrode the real `/api/cdrs` maximum (20000): even though the portal requested 20000, it only got 1000 back → the table read "1,000 records" regardless of how many existed (81M on the production box). The backstop was raised to 20000 (the endpoint's documented max); `/api/calls` and the public `/api/v1/cdrs` API still clamp to 1000 on their own. Not related to licensing.

### Changed — Free tier: unlimited CDRs (the limit was 1000)
The free tier (no license installed) used to lock the portal once it reached **1000 stored CDRs**, which looked like "only 1000 are saved". From now on the free tier is metered **by concurrent lines only** (50); the number of CDRs is **unlimited**. The CDR meter is removed from the usage banner and the block overlay (storage belongs to the customer). The sniffer and database never stopped capturing — only the portal locked.

## [2.105.0] — 2026-06-19

### Changed — CPU catch-up notice moves to the bell (low priority) instead of an alarming banner
After a restart/update the portal runs a *catch-up* that temporarily raises CPU (with no capture loss). The backend already told this transient state (`transient`) apart from sustained saturation, but the frontend always showed the alarming "add cores before traffic drops" banner — confusing right after updating. Now:
- **Transient high CPU (catch-up):** goes to the notification center (bell) as a **low-priority** notice ("catching up after the update; CPU clears on its own, no need to add resources"), with no banner. It clears itself once CPU normalizes.
- **Sustained (real) CPU saturation:** keeps the preventive "add cores" banner as before.

## [2.104.0] — 2026-06-19

### Fixed — CDR "SBC IP / label" column showed the trunk name
The "SBC IP / label" column identifies the equipment that received the capture (the SBC, by its IP), but it fell back to the **trunk/carrier name** when that IP had no entry in Settings → IP Labels — so the SBC appeared with the same name as the trunk (confusing). That column now resolves **only** against IP Labels (exact or prefix match); if there is no label, it shows the SBC's **raw IP** — never the trunk name. The Caller/Callee columns still fall back to the carrier name (useful there). For a friendly SBC label, set its IP in Settings → IP Labels.

## [2.103.0] — 2026-06-19

### Added — Enriched CDR fields shown in the table (columns)
The fields we added to the CDR (phases 1/2/3 + capture-source label) were already in the data/API but not shown in the portal table. They are now COLUMNS:
- **Visible by default:** `Capture src` (capture-equipment label — from Settings → Capture `HEP source label` / SIPREC `label`) and `Country` (dialed country).
- **Optional (Customize columns):** Trunk, Hung up by, Q.850, Transport, UA caller/callee, Caller/Dialed E.164, Intl, Risk (IRSF), Xfer (REFER), DTMF, Jitter max, Retx, Media IP A/B, SIP msgs.
- The "SBC IP / label" column still shows the Settings IP label (falls back to the trunk name only when that IP has no label). Use the new `Capture src` column for the explicit capture equipment (set its label in Settings → Capture/SIPREC).

## [2.102.1] — 2026-06-19

### Fixed — concurrency: last point (in-progress bucket) dropped to 0
The newest bucket of the concurrency chart is the in-progress period: its `starts` aren't inserted yet (calls land when they end/correlate, with lag) while its `ends` are → the net dipped to ~0 (a dent at the last point). Since concurrency is a level, the last COMPLETE value is now carried forward for the in-progress bucket (live windows only; past ranges keep their final bucket).

## [2.102.0] — 2026-06-19

### Fixed — Simultaneous-calls (concurrency) chart flat on 1h/6h + undercounted volume on short ranges
Two chained bugs in the fine charts (per-minute rollup):
- **Flat concurrency:** the "Simultaneous calls" series was always served at HOURLY resolution (carry-forward) → a flat line on 1h and a ~6-step staircase on 6h. Now it's computed at per-minute resolution (peak concurrency per fine bucket) showing the real intra-hour variation.
- **Root cause:** the per-minute rollup only re-scanned the last 15 min, so it never caught late-inserted calls → it undercounted ~15-30% vs the hourly rollup (this also affected volume/attempts on 1h/6h). It now re-scans 4h (same catch window as the hourly rollup). Fine charts self-correct within 4h.

## [2.101.0] — 2026-06-19

### Added — Configurable AI insight language (Settings → AI Chat)
New **"AI insight language"** selector: `Auto (follow portal)` · `English` · `Español`. One setting (`ai_lang`) now governs the language of every AI insight — per-trunk diagnosis, NOC overview, SIP trace analysis and alarm diagnosis. `es`/`en` force it; `auto` (default) follows the portal language in the UI and falls back to English for background jobs (alarms/digest).

## [2.100.3] — 2026-06-19

### Added — Bilingual portal release notes (EN/ES by portal language)
The update notes under the "Update" button now follow the portal language. `latest.json` carries `changelog` (English) and `changelog_es` (Spanish); the in-portal update checker picks the right one based on the selected language.

## [2.100.2] — 2026-06-19

### Fixed — SIPREC: el SRS no podía crear su venv (faltaba `python3-venv`)
La causa de fondo del SRS sin SRTP (confirmada en C3ntro): el paquete `python3-venv` no estaba instalado → `python3 -m venv` fallaba. `install.sh` ahora lo instala (best-effort) antes de crear el venv y lo recrea con `--clear`. Best-effort intacto (sin pylibsrtp el SRS corre con RTP en claro; la captura HEP nunca se afecta).

## [2.100.1] — 2026-06-19

### Fixed — SIPREC: el venv del SRS quedaba sin `pylibsrtp` (SRTP no disponible)
El provisioning del SRS en `install.sh` no instalaba `pylibsrtp` porque en Debian/Ubuntu el venv a veces nace sin pip. Fix: `ensurepip` + `python -m pip` + log del detalle en `/var/log/voxywatch-srs-pip.log`. Best-effort intacto (sin pylibsrtp el SRS corre con RTP en claro; la captura HEP nunca se afecta).

## [2.100.0] — 2026-06-19

### Added — CDR enriquecido Fase 3: calidad fina / red / contexto
Última fase del enriquecimiento de CDRs (aditivo, sin migración). Cierra el set para la IA/diagnóstico.
- **Calidad:** `jitter_max_ms`, `out_of_order`, `retransmissions`, `asymmetric_media` (media en un solo sentido).
- **Red:** `media_ip_caller`/`media_ip_callee` (IP de media SDP, NAT/bypass), `transport` (UDP/TCP/TLS).
- **Contexto:** `dow` (día) + `hour_local` (hora) en el timezone del portal, `sip_msg_count`.
- Reusa lo ya calculado en correlación; derivables en proyección. Sin tocar el sniffer.

> Con esto el CDR enriquecido (Fases 1+2+3) queda completo.

## [2.99.0] — 2026-06-19

### Added — Monitoreo de fuentes (HEP & SIPREC): registro persistente, panel correcto, TTL y alarma de silencio
- **Fix de los "0s":** el panel ahora muestra los contadores reales (SIP/RTP/RTCP) y persiste en disco → sobrevive reinicios (antes era volátil y leía campos equivocados).
- **RTP honesto** en modo files: actividad global de RTP en segmentos (no un 0 engañoso por fila).
- **SIPREC en el mismo panel** (sesiones/última actividad cuando el SRS está activo).
- **Columnas nuevas:** Tipo (HEP/SIPREC), Estado, Sesiones.
- **TTL de inactividad** (default 7 días, 1-90): la fuente sin tráfico desaparece del panel; el label no se borra salvo opt-in.
- **Alarma "fuente en silencio"** (nace OFF): incidente cuando una fuente conocida deja de mandar. Anti-falso-positivo: 24/7 · días+horario manual · ML aprendido (no alarma hasta madurez ni fuera de su ventana). Simulador "qué alarmaría".
- **SIPREC:** opción de heredar la allowlist de IPs de HEP.

## [2.98.0] — 2026-06-19

### Added — CDR enriquecido Fase 2: comportamiento / antifraude
Segunda fase del enriquecimiento de CDRs (aditivo, sin migración). Más señal para la IA y el antifraude.
- **`caller_id_e164` / `dialed_e164`**: origen/destino normalizados a E.164 si son plausibles; si no, `null`.
- **`caller_id_valid`**: el ANI es plausible (detección de caller-id falso).
- **`is_international`**: destino en otro país (usa el país de casa de antifraude, o compara origen vs destino).
- **`high_risk`**: país de destino en la lista IRSF editable (antifraude).
- **`call_transferred`**: hubo REFER (transferencia, RFC 3515).
- **`dtmf_count`**: nº de DTMF por SIP-INFO. Solo el conteo, JAMÁS los dígitos (PCI).
- Se calculan en proyección → cambios en la lista IRSF / país de casa aplican retroactivo.

## [2.97.0] — 2026-06-19

### Added — etiqueta de fuente configurable en el CDR (HEP source label / SIPREC label)
Completa el `hep_source` del CDR enriquecido (v2.96): la mayoría de los SBC no envían el nombre del agente de captura por HEP, así que la etiqueta de la fuente ahora se toma de **settings**.
- **`hep_source_label`** (Settings → Captura): nombre legible del SBC/sonda que envía HEP.
- **`siprec_label`** (Settings → SIPREC): nombre legible para las llamadas capturadas por el SRS.
- El CDR (`hep_source`) resuelve: SIPREC → `siprec_label` (o "SIPREC"); HEP → `hep_source_label`; si no se configuró, cae al nombre crudo del agente (omitiendo el inútil `'unknown'`). Sin hardcode, bilingüe ES/EN, aditivo.
- **API v1:** `hep_source` (introducido en v2.96.0) ahora refleja la etiqueta configurada y normaliza `'unknown'` → `null`. La clave sigue presente (cambio de valor, no de estructura).

## [2.96.0] — 2026-06-19

### Added — CDR enriquecido Fase 1: más señal estructurada para la IA
Primera fase del enriquecimiento de CDRs (más dimensiones → mejor perfilado por troncal, antifraude y diagnóstico del copiloto). **Aditivo en `calls.data` (JSONB): sin migración de esquema, no rompe el contrato del CDR ni del API; se puebla hacia adelante (CDRs viejos quedan `null`).** El enriquecimiento corre en la **correlación** del portal, NUNCA en el hot-path del sniffer — captura intacta.
- **Marca del equipo de cada lado**: `ua_caller` (User-Agent del INVITE = origen) y `ua_callee` (Server/User-Agent de la respuesta = destino) — útil para identificar SBC/PBX por extremo. Acotados a 120 chars.
- **`q850_cause`**: causa Q.850 del header `Reason:` (`cause=NN`) cuando el equipo la envía.
- **`hangup_by`**: quién colgó — `caller` / `callee` / `network` (el BYE no vino de ninguno de los dos extremos: SBC/proxy/timeout intermedio).
- **`dial_prefix`**: el prefijo de ruteo de la troncal que casó con el número marcado (separado del país).
- **`hep_source`** en el CDR: agente/sonda de captura por el que entró la llamada (CaptAgent/HEPlify/SBC).
- Parseo SIP defensivo (header ausente → `null`, jamás excepción) y barato (regex O(línea), sin ReDoS). Validado con bug-hunter.

## [2.95.0] — 2026-06-19

### Added — dashboard: orden intercalado grande/chica + reordenar gráficas arrastrando
- **Orden por defecto intercalado**: las gráficas del dashboard ya no van todas las grandes juntas y luego las chicas; ahora alternan grande/chica hasta agotar las grandes y dejan las chicas restantes. El grid usa `grid-auto-flow: row dense` para empacar sin medias filas vacías.
- **Reordenar en Personalizar**: además de prender/apagar, cada widget se puede **arrastrar (⠿) para moverlo de lugar**; el orden se guarda en `localStorage` (`voxywatch_dash_order`) y se aplica al cargar (`applyOrder`). El reorden respeta los grupos (un KPI no salta a la rejilla de gráficas). El panel pasó a lista vertical para que el arrastre sea natural; hint nuevo "clic para mostrar/ocultar · arrastra ⠿ para reordenar".

## [2.94.0] — 2026-06-19

### Fixed — Codec y Causas de desconexión también WINDOWED (cierra el set de distribuciones del dashboard)
Completa lo de v2.93: las gráficas **Codec Distribution** y **Disconnect Causes** también se calculaban del muestreo de 20k CDR (sesgado a alto volumen). Ahora salen del rollup por la ventana elegida.
- Dos JSONB por hora en `call_stats_hourly` (`codecs` {codec:conteo} · `causes` {familia SIP:conteo}, familia = answered→2xx / código líder de fail_reason / none) — poblados en AMBAS rutas de finalize con un helper compartido (`_rollupJsonbDists`, mismo `timeWhere` parametrizado → paridad).
- `GET /api/dashboard/distributions` ahora devuelve también `codecDist` y `causesDist` (merge de los JSONB sobre la ventana vía `jsonb_each_text`); el dashboard los lee con fallback al muestreo (`_distOk`). `_ROLLUP_VER` 5→6 (recálculo en sitio, sin truncate).
> Con esto las 5 distribuciones del dashboard (Duración/PDD/MOS/Codec/Causas) son windowed y correctas a cualquier volumen.

## [2.93.0] — 2026-06-19

### Fixed — gráficas de distribución (Duración/PDD/MOS) ahora WINDOWED, no de una muestra sesgada
Las gráficas "Call Duration", "PDD" y "MOS" del dashboard se calculaban en el cliente desde una muestra de los 20.000 CDR más recientes. A alto volumen (C3ntro ~330k llamadas/hora) esos 20k son **solo ~3-4 minutos** → las llamadas largas aún están en curso y casi todas caen en `<10s`, dando la impresión falsa de que "no hay llamadas de más de 1 min". La data siempre estuvo bien (en una ventana real: ~23% <10s, ~60% 10-60s, ~16% >1min).
- **Buckets de distribución en el rollup horario** (`call_stats_hourly`): duración (de answered) en <10s/10s-1m/1-5m/5-15m/>15m, PDD en 5 tramos, MOS en 6 — calculados una vez por hora en BOTH rutas de finalize (clásica + incremental), con la MISMA fórmula (paridad).
- **Endpoint windowed** `GET /api/dashboard/distributions?from&to|range` que suma los buckets del rango elegido (O(buckets), barato a cualquier volumen).
- El dashboard lee de ahí para las 3 gráficas, con **fallback** al muestreo si el endpoint no responde. `_ROLLUP_VER` sube a 5 para poblar los buckets.
- **Fix de plomería**: `stats_rollup_incremental` faltaba en la whitelist de `POST /api/settings` (el flag se descartaba en silencio); ya se acepta. Detectado al validar paridad del rollup incremental (v2.92).
> Nota: la duración ahora es de llamadas **contestadas** (una distribución de duración de llamadas fallidas no tiene sentido y metía todo en <10s). Codec + Causas de desconexión windowed → v2.94.

## [2.92.0] — 2026-06-19

### Added — rollup horario INCREMENTAL (finalize-once por hora) — flag `stats_rollup_incremental` (OFF)
Hasta ahora el rollup del dashboard (`call_stats_hourly`) se mantenía **re-escaneando una ventana móvil** de la tabla `calls` (143 GB en C3ntro): ~4 h cada 2 min + 12 h en cada arranque. Caro en disco (IO), lento al arrancar y propenso a huecos cosméticos tras ráfagas de reinicios.
- Nuevo modo **incremental** que copia el patrón ya probado del rollup por troncal: finaliza **cada hora UNA vez** cuando sus CDRs están estables (periodo de gracia) y reanuda por **cursor en `meta`** (`stats_rollup_fwd`/`back`), procesando **una hora a la vez** (la hora en curso + la anterior se refrescan en vivo para el dashboard).
- **Beneficio**: menos IO y CPU, **cero RAM extra** (procesa ~330k filas/hora en vez de re-barrer ~1.3M), **arranque en segundos** (sin re-escaneo) y **sin huecos** tras reinicios.
- **Nace detrás de flag `stats_rollup_incremental` (default OFF)** → este release no cambia el comportamiento de nadie. Se activa por cliente tras validar **paridad** (resultado idéntico al re-scan) y observación. Cambio de semántica (`_ROLLUP_VER`) sigue forzando un rebuild completo una sola vez. Ver `docs/DESIGN_ROLLUP_INCREMENTAL.md`.

## [2.91.2] — 2026-06-19

### Fixed — el rollup horario se auto-cura tras una ráfaga de reinicios (gráficas de rango largo)
Una hora de `call_stats_hourly` podía quedar **subcontada** si el refresh periódico (ventana móvil de 4 h) era interrumpido por varios reinicios seguidos y esa hora envejecía >4 h antes de recalcularse desde un `calls` ya completo — produciendo una **caída cosmética** en las gráficas de rango largo (7d/30d) aunque el tráfico y los CDRs estuvieran intactos (las gráficas de 24 h, que leen del rollup de 1 min, mostraban el valor correcto).
- El backfill horario del **arranque** ahora mira **12 h hacia atrás** (antes 2 h) y re-finaliza esas horas desde `calls`: un reinicio auto-corrige el artefacto y blinda contra futuros maratones de reinicios. Costo: un escaneo horario de 12 h en el boot (~1-2 min a alto volumen, una sola vez).
> Detectado en C3ntro tras la cadena de releases del 18-jun (8 reinicios en pocas horas dejaron las horas 14-19 UTC subcontadas). La captura nunca se afectó.

## [2.91.1] — 2026-06-18

### Fixed — el versionado del rollup 1m ya no fuerza un rebuild innecesario al adoptarse
v2.91.0 trataba la **clave ausente** (`meta.rollup_1m_ver` no existe = primer upgrade que introduce el versionado) como "rebuild completo". Pero en ese caso los datos existentes ya son de la fórmula vigente, así que el `TRUNCATE` + escaneo de 26 h era **inútil** — y en un cliente de alto volumen ese escaneo de `calls` dura ~20 min con las gráficas finas (1h/6h/24h) **vacías** mientras corre.
- Ahora el rebuild se dispara **solo si la clave EXISTE y DIFIERE** (cambio real de fórmula). Clave ausente → se **sella** la versión actual y se hace backfill incremental normal (sin TRUNCATE, sin escaneo de 26 h): adopción instantánea, sin ventana de gráficas vacías.
- Un cambio futuro real de fórmula (subir `_MIN_ROLLUP_VER`) sí rebuildea, como debe.

## [2.91.0] — 2026-06-18

### Added — versionado de semántica del rollup de 1 minuto (paridad con el horario)
El rollup horario ya rebuildea solo cuando cambia su fórmula (`meta.rollup_ver`); el rollup de 1 min no tenía ese mecanismo, así que un cambio futuro de su fórmula habría dejado buckets viejos con semántica mezclada hasta que la retención de 26 h los purgara. Ahora `call_stats_1m` tiene su propia versión (`meta.rollup_1m_ver`, constante `_MIN_ROLLUP_VER`): si cambia → `TRUNCATE` + rebuild completo de las 26 h en el siguiente arranque, sin tocar la BD a mano.
> **En el primer arranque tras este upgrade** se hace UN rebuild completo del 1m (la clave aún no existe en `meta`) — ~minutos en un cliente de alto volumen; tras eso, los reinicios vuelven a ser incrementales (solo el hueco, fix de v2.90.0). Deuda anotada en el debug de v2.90.0, ya saldada.

## [2.90.1] — 2026-06-18

### Fixed — el chequeo de actualización forzado ya no ve un manifiesto stale
El botón "Buscar ahora" y la actualización **un-clic** podían reportar "no hay actualización disponible" justo tras publicar una versión: `raw.githubusercontent.com` cachea `latest.json` ~5 min **por edge**, y el portal pegaba a la URL pelada → veía el manifiesto viejo de ese edge.
- El chequeo **forzado** (force) ahora añade un cache-buster (`?t=epoch`) → el edge hace MISS y trae el manifiesto fresco del origin. El poll horario sigue usando la URL pelada (su caché de cortesía de 5 min ya throttlea; no añade carga). Headers `Cache-Control: no-cache` + `Pragma: no-cache`.
- `POST /api/update` ahora **fuerza un chequeo fresco él mismo** antes de decidir, en vez de depender de un `GET /api/version/latest?force=1` previo → la actualización un-clic es robusta de forma independiente.
- **Fail-closed**: si esa verificación forzada no logra bajar un manifiesto fresco (GitHub caído/timeout), `POST /api/update` responde **503 "no se pudo verificar"** en vez de actuar sobre el estado viejo en RAM (`checkForUpdates` devuelve si la descarga fue fresca). `apply-update.sh` re-verifica GPG+SHA igual, pero así no se anuncia un update a una versión que pudo retirarse.


## [2.90.0] — 2026-06-18

### Fixed — pulido operativo detectado en debug de producción
- **Backfill del rollup de 1 minuto, barato en cada reinicio.** `call_stats_1m` es persistente y sobrevive al reinicio, pero el backfill de arranque re-escaneaba las **26 h completas** de `calls` cada vez (medido en C3ntro: ~18 min de `IO/DataFileRead` por reinicio, multiplicado por cada deploy del día). Ahora `backfillMinRollup` aplica el mismo patrón que el rollup horario: rellena **solo el hueco** desde el último bucket conocido (+10 min de solape); el escaneo completo de 26 h queda **solo** para tabla vacía (instalación nueva o cambio de semántica). Reinicio normal → segundos. Esto además quita la contención de IO que disparaba algún `statement timeout` aislado en `/api/calls` justo tras arrancar.
- **Reconstrucción de audio: "sin RTP" deja de ser un falso error.** Cuando una llamada no tiene RTP recuperable (el SBC no espejó media, o ya se purgó), `reconstruct_audio.py` salía con código 1 igual que un fallo real → el portal lo registraba como `[RECONSTRUCT] Command failed` y lo reportaba a Sentry como `error` (ruido para el autopilot). Ahora ese caso benigno sale con **código 2** y el portal responde **422 `no_audio`** sin log de error ni Sentry; la UI muestra un mensaje amable bilingüe (ℹ "esta llamada no tiene audio disponible") en vez del código crudo. Los fallos reales (BD, ffmpeg, decode) siguen siendo error 500 + Sentry.

## [2.89.0] — 2026-06-18

### Added — Monitoring agéntico Fase 4: métricas configurables + IA profunda por troncal (cierra el rediseño)
Última fase del rediseño del Monitoring. Dos capacidades pedidas por el NOC:
- **Métricas configurables/intercambiables.** La tabla de Monitoring deja de tener columnas fijas: un selector **⚙ Columnas** (persistido en `localStorage`) permite mostrar/ocultar cada métrica y **agregar nuevas** (tipo de tráfico, madurez del patrón) además de las clásicas (Llam./ASR/NER/ACD/MOS/Pérdida/PDD/5xx/OWA). El encabezado se reconstruye según lo elegido; siempre queda al menos una métrica visible.
- **IA profunda por troncal.** Botón **🤖 Diagnosticar con IA** en el drill-down de cada troncal → reusa `POST /api/copilot/trunk/:id` (que ya existía pero no estaba expuesto en la UI): el copiloto analiza series de 48 h + baseline + top de códigos SIP + destinos y ahora también el **tipo de tráfico y el patrón aprendido** (madurez, ventana horaria habitual, países típicos) → causa probable · acciones para el NOC · riesgo. Render markdown-lite seguro (escape + **negritas**), cacheado 5 min.
- **🤖 Resumen IA** en la cabecera del Monitoring (`POST /api/copilot/overview`): prioriza qué troncales atender primero y agrupa problemas similares.
> El copiloto IA debe estar activo (Settings → AI Chat). VoxyWatch solo observa; la IA nunca toca el SBC. Cierra las Fases 1-4 del Monitoring agéntico.

## [2.88.0] — 2026-06-18

### Added — Agentic Monitoring, Phase 3b: pattern-deviation alert (off-hours) + editable values
On top of the learned pattern (3a), VoxyWatch now **flags a trunk with traffic outside its usual hourly window**:
- **Off-hours detector** in trunk health (reason `health_pat_offhours`), **gated by the `trunk_health.pattern_alerts` flag (OFF by default) + a MATURE pattern** (~2 weeks) + the trunk not muted → anti-FP: nothing alarms without maturity or without the admin enabling it.
- **Editable per trunk**: the drill-down "Learned pattern" panel lets you adjust the active window (From/To) and mute deviations (`POST /api/trunks/:id/pattern-override`); the manual window overrides the learned one.
- Anti-loss guard for the override in the catalog replace-all. Local hour uses the portal timezone.

## [2.87.0] — 2026-06-18

### Added — Agentic Monitoring, Phase 3a: learned per-trunk pattern (maturity + hours + countries)
Each trunk learns its rhythm from the hourly rollup and shows it in the drill-down ("Learned pattern"):
- **ML maturity**: days observed vs ~14 (Saturday ≠ Wednesday) — a "Learning… N/14 days" or "Mature ✓" badge, with the note that ML needs ~2 weeks to be reliable.
- **Usual activity hours** (traffic start–end, in the portal's timezone).
- **Typical destination countries**.
Read-only/learning — no alarm change. Foundation for Phase 3b (pattern-deviation alerts — off-hours / new country / volume drop — behind a flag + simulator, with editable values).

## [2.86.2] — 2026-06-18

### Fixed — AI discovery robust to truncated replies
Gemini 2.5 spends so much on "thinking" that the JSON came back cut off at "rationale". Now maxTokens=1500 + a tolerant parser: if the JSON is incomplete, it extracts type/confidence/rationale by regex so a valid classification isn't lost.

## [2.86.1] — 2026-06-18

### Fixed — AI traffic-type discovery truncated with Gemini 2.5
`POST /api/trunks/:id/discover-type` always returned `proposal:null`: with `maxOutputTokens=250` Gemini 2.5 spends the budget on "thinking" and the JSON came back cut off. Raised to 800 tokens → the AI now classifies.

## [2.86.0] — 2026-06-18

### Added — Agentic Monitoring, Phase 2: per-trunk traffic type + AI discovery
Each trunk can have its own **traffic type**, and health respects it (a wholesale trunk at 25% ASR is normal; a retail one at 25% is critical):
- **`traffic_type` field** in the trunk catalog (wholesale termination/origination, retail/enterprise, SIP-trunk/PBX, calling-card, DID inbound, toll-free, on-net, test, unknown) + source (manual/ai/auto). Selector in the trunk drill-down; type badge in the Monitoring table.
- **Expected profile per type** adjusts health thresholds. Type-aware health sits behind the `trunk_health.profile_aware` flag (ships OFF — validate with the simulator before enabling; it changes what alarms).
- **AI discovery**: a "🤖 Discover with AI" button → `POST /api/trunks/:id/discover-type` builds a 14-day profile snapshot (direction, ASR, ACD, countries, codes, hourly pattern) and the AI **proposes** the type + confidence + rationale. The human confirms. AI proposes, never imposes; says so when there isn't enough traffic.
- Anti-loss guard: the catalog replace-all preserves `traffic_type` by id when the form omits it.

## [2.85.0] — 2026-06-18

### Added/Changed — Agentic Monitoring, Phase 1: cleanup + transparency + color
First step of the Monitoring redesign for NOC use:
- **Raw internal id `trk_xxx` removed** from the UI — the incident's "other degraded trunks" evidence now shows the trunk **name**, not the technical id.
- **More metrics on the Monitoring table**: an **OWA** (one-way audio) column (already computed) and a per-trunk **baseline-maturity badge (ML✓ / ML…)** so the NOC sees at a glance whether the model has learned that trunk's pattern yet.
- **Per-cell color heat** on ASR/NER/MOS/Loss/PDD/5xx/OWA by range — faster reading, not just the status dot.
- EN/ES i18n. Presentation only (read-pool); the alarm engine and capture hot-path are untouched. Full roadmap (traffic-type + AI discovery, learned day/hour patterns, configurable metrics, deeper AI) tracked in the engineering design doc.

## [2.84.1] — 2026-06-18

### Fixed — One-click update returned "needs_privilege" even with the grant present
The `isServiceControlEnabled()` pre-gate `stat`s `/etc/polkit-1/rules.d/` (dir `0750 root:polkitd`) which the unprivileged portal cannot read → false negative → `POST /api/update` returned 409 even though the polkit grant existed. Fix: drop the pre-gate and try `busctl StartUnit` directly (same as the sniffer restart); polkit's result is the source of truth.

## [2.84.0] — 2026-06-18

### Added/Fixed — Dashboard KPIs now follow the time window + new KPIs + chart i18n
Header KPIs came from the most-recent ~20k-call sample, so they ignored the time filter ("yesterday" showed all zeros) and "% short calls" read ~100% because it counted every call under 10s — **including unanswered (0s) ones**. Now:
- **New `/api/dashboard/kpis?from&to`** aggregates KPIs from the rollups (full history, O(buckets)): counts (Attempts/Answered/ASR/NER/Failed) from the global `call_stats_hourly`; quality (ACD/MOS/PDD/minutes) from `trunk_stats_hourly` (attributed traffic). **"yesterday"/"today"/custom are now correct.** No rollup rebuild.
- **New KPIs:** "Active now" (live in-progress calls), "Answered", and "Total calls" renamed to **"Attempts"**.
- **Short calls fixed:** now counts only **answered** calls under 10s, as a % of answered (possible false-answer) — no longer inflated to ~100%.
- **i18n** for the **Disconnect Causes** and **MOS Distribution** charts (were hardcoded Spanish → now follow the user's language).
- **MOS:** average MOS now also follows the window. The MOS *distribution* needs per-call MOS (RTCP or RTP-in-DB); on SBCs without RTCP it stays sparse — a data-source limitation, not the portal.

## [2.83.2] — 2026-06-18

### Fixed — One-click update now actually applies (D-Bus + polkit, not sudo)
The v2.83.0 mechanism (scoped sudoers) didn't work: the portal runs with `NoNewPrivileges=true`, so `sudo` cannot escalate from the portal process. Replaced with the same pattern the sniffer restart already uses: `install.sh` installs a **root one-shot** unit `voxywatch-apply-update.service` (runs the root-owned `apply-update.sh` helper), `enable-service-control.sh` adds a **polkit** grant to start only that unit, and `POST /api/update` triggers it over **D-Bus (`busctl StartUnit`)** — which works under `NoNewPrivileges`. systemd owns the one-shot, so it survives the portal restart. Without the grant it returns the manual command. The dead v2.83.0 sudoers file is removed.

## [2.83.1] — 2026-06-18

### Changed — Clearer label for calls with no final SIP response ("Ignored")
The **Disconnect Causes** chart showed "Sin código" for unanswered calls with no captured final SIP code (INVITE with no response: SBC mirroring only one leg, scanners, timeouts). It now reads **"Ignored"** — matching the term already used in the call's disposition badge. The generic reason in **Failure Reasons** also moves from "Sin respuesta" to "Ignored" so both views are consistent. Label/terminology only; classification unchanged.

## [2.83.0] — 2026-06-18

### Added — One-click portal update without manual root (scoped sudoers)
The **Settings → Update → Update now** button now actually applies the update when you enabled *Service control* at install time. Before, the portal (an unprivileged user) couldn't install into `/opt`, so the click failed silently and you had to update as root over SSH. Now `install.sh` ships a **root-owned** helper `/opt/voxywatch/apply-update.sh` (0750 root:voxywatch, not writable by the portal) and `enable-service-control.sh` adds a **sudoers entry scoped to that exact path** (`NOPASSWD: /opt/voxywatch/apply-update.sh`, validated with `visudo`) — no general root, no argument injection. The helper downloads the official signed installer and runs `--update` (GPG + SHA-256 re-verified). Without the grant, `POST /api/update` returns the exact manual command instead of failing quietly.

## [2.82.5] — 2026-06-18

### Fixed — Rangos "ayer", "hoy" y "personalizado" en las gráficas de tendencia
Las 5 gráficas de tendencia (Intentos/Contestadas/Simultáneas/CPS/ASR-NER) ya respetan los filtros de tiempo "ayer", "hoy" y "personalizado" (rango): antes "ayer" caía a las últimas 24h móviles y "personalizado" caía a "todo" (ignoraba la ventana from/to elegida). Ahora el endpoint `/api/dashboard/series` acepta `from`/`to` (epoch s) explícitos: el frontend manda la ventana real y el servidor la reparte en N=48 buckets eligiendo la fuente (rollup por minuto si la ventana cabe en la retención de 26h, horario si no). 1h/6h/24h/7d/30d/all siguen igual. Solo endpoint + frontend.

## [2.82.4] — 2026-06-18

### Fixed — Concurrencia correcta en todos los rangos (siempre del rollup horario)
La concurrencia ahora se calcula siempre del rollup horario (ledger balanceado) y se mapea a los buckets finos — antes mezclar baseline-horario con deltas-1m daba números absurdos (24h en 0 o en millones). attempts/answered/cps siguen finos del rollup por minuto; la concurrencia, al ser lenta, va a resolución horaria mapeada. Solo endpoint.

## [2.82.3] — 2026-06-18

### Fixed — Concurrencia en 24h se hundía (122 en vez de ~miles)
El cúmulo start-end con clamp a 0 perdía información en los valles de un día completo. Ahora la serie de concurrencia se calcula cruda y se desplaza para que su mínimo sea 0 → preserva forma y pico real, robusta al error de baseline (frontera horario↔1m). Solo endpoint.

## [2.82.2] — 2026-06-18

### Fixed — Concurrencia en rango 24h salía 0
El baseline de concurrencia (llamadas abiertas al inicio de la ventana) se tomaba del rollup por minuto, que con retención 26h conserva `ended` de llamadas cuyo `start` ya se purgó → baseline negativo → concurrencia clampada a 0 en 24h. Ahora el baseline sale siempre del rollup horario (historia completa y balanceada). Solo el endpoint; sin rebuild.

## [2.82.1] — 2026-06-18

### Fixed — Backfill del rollup por minuto demasiado lento en alto volumen
El backfill inicial de `call_stats_1m` (48h) tardaba >10 min en C3ntro por el filtro JSONB `is_scanner` sobre millones de filas + contención con la ingesta, dejando las gráficas de rango corto (1h/6h/24h) vacías ese rato. Fix: el rollup 1m ya NO aplica `is_scanner` (cuesta ~8×; el horario lo conserva para la historia; en clientes sin scanners es idéntico) y la retención baja a 26h (suficiente para ≤24h + baseline). Backfill ahora ~30-60 s.

## [2.82.0] — 2026-06-18

### Added — Dashboard trend charts with ~48 points on every range + new CPS chart
Trend charts (Attempts, Answered, Simultaneous, ASR/NER and the new **CPS**) now show **~48 points on any
range** (1h/6h used to have just 1-6). A new per-minute rollup powers short ranges; the hourly rollup powers
7d/30d/all. New `GET /api/dashboard/series?range=` splits the window into 48 buckets and returns
attempts/answered/concurrency/cps/asr/ner pre-aggregated (millisecond response). Also: the Simultaneous-calls
chart now follows the time filter, the ASR/NER context bar is concurrency (not total), CPS (call attempts per
second) was added, and "All" spans from the oldest retained CDR to now.

## [2.81.8] — 2026-06-18

### Changed — "Simultaneous calls" chart moved up with the main charts
The concurrency chart now sits next to Call Attempts and Answered (top row), full-width — it's the SBC
capacity metric, so it's front and center.

## [2.81.7] — 2026-06-18

### Fixed — Dashboard labels: tell "per hour" (volume) apart from "simultaneous" (concurrency)
The concurrency chart was titled "Active calls / hour", easily mistaken for an hourly volume. Renamed to
**"Simultaneous calls (concurrency)"** — the metric that matters for SBC capacity (~4-5k on C3ntro). The
Attempts and Answered charts now say **PER HOUR · not simultaneous** so hourly volume (tens of thousands)
isn't confused with concurrent calls (thousands). Labels only; the data was already correct.

## [2.81.6] — 2026-06-18

### Changed — Dashboard: "Call Attempts" (excl. LNP redirects) + new "Answered" chart + working 1h/6h range
The volume chart counted non-call transactions (3xx/LNP redirects, `lnp-*`) that inflated the number. Now:
"Call Attempts" excludes LNP redirects (keeps failed/busy/cancelled/no-answer so route failures stay
visible); a new "Answered Calls" chart shows connected calls only; and the 1h/6h/24h range buttons now
actually change the chart (they used to all show 24h). Rollup rebuilds automatically on update.

## [2.81.5] — 2026-06-18

### Fixed — Dashboard "Call Volume" chart showed only ~2h of sampled data, not real history
The volume chart (and the ASR/NER and concurrency trend charts) fell back to the recent in-memory sample
(~2h at high volume, small numbers) instead of the full `call_stats_hourly` rollup. The timeseries endpoint
now reads from the UI read-pool (not the sniffer's ingest pool, which saturates at high traffic and made the
query 503), and the frontend keeps the last good series if a single fetch fails. The chart now shows the
full real history again.

## [2.81.4] — 2026-06-17

### Added — Download a SIP-only trace (no RTP) — instant
A call's SIP flow viewer now has **two PCAP buttons**: "SIP-only PCAP" (signaling only, a few KB, downloads
instantly) and "Full PCAP" (SIP + RTP/audio, as before). Handy when a call has audio and the full capture
weighed several MB and took a while. The SIP-only export skips all RTP scanning end to end.

## [2.81.3] — 2026-06-17

### Added — Upload the SIPREC TLS certificates from the portal (besides the path)
The Settings → SIPREC tab gains an **Upload certificates** button next to the cert/key path fields:
pick the PEM files and the portal validates the pair, saves them on the server and fills the paths in
for you. You can still type the path by hand if the files are already on the box.

## [2.81.2] — 2026-06-17

### Added — SIPREC settings tab: configure ports and turn it on from the portal
A new **Settings → SIPREC** tab lets you set up and control the recording server without editing files:
- Enable/disable toggle, **configurable SIP (UDP) and RTP base ports**, TLS port + cert/key paths,
  advertised media IP, SBC allowlist (with an open-allowlist warning) and a max-sessions cap.
- Live status (off / listening / enabled-but-down) and a one-click **Save & apply** that starts or
  stops the SRS service for you. SIPREC stays **OFF by default** until you enable it here.

## [2.81.1] — 2026-06-17

### Security — El SRS SIPREC arranca apagado por default (hotfix de v2.81.0)
En v2.81.0 el servidor SIPREC podía abrir el puerto `5060` aunque no hubieras activado SIPREC. Esta
versión lo deja **apagado y deshabilitado** hasta que tú lo enciendas en Settings → SIPREC, y al
actualizar lo apaga si venía corriendo. Sin impacto si nunca activaste SIPREC. **Recomendado actualizar.**

## [2.81.0] — 2026-06-17

### Added — Grabación SIPREC nativa: cualquier SBC graba directo en VoxyWatch (sin agente HEP)
VoxyWatch ahora incluye un **SRS** (Session Recording Server, RFC 7865/7866): un SBC tier-1
(Ribbon, Oracle/ACME, AudioCodes, Cisco CUBE, Avaya…) puede **enviar su grabación SIPREC directo**
a VoxyWatch, sin necesidad de un agente HEP ni de espejo de puertos. Complementa al HEP que ya
existía → cobertura del mercado completa.
- **Cómo funciona:** el SBC (SRC) abre una sesión SIP de grabación hacia VoxyWatch; el SRS contesta,
  recibe los flujos de media de cada pata y reconstruye el **audio estéreo** (caller=izquierda,
  callee=derecha) usando la metadata `rs-metadata` para identificar la llamada y los participantes.
  La llamada aparece en el portal/CDR como cualquier otra (fuente "SIPREC"), con audio, jitter/pérdida y PCAP.
- **Transportes:** SIP por **UDP o TLS**; media **RTP en claro o SRTP** (SDES `AES_CM_128_HMAC_SHA1_80`).
- **Códecs:** PCMU/PCMA/G722/G729 + dinámicos vía `rtpmap`. **pause/resume** vía re-INVITE.
- **Seguro por diseño:** servicio **separado** del sniffer (si cae, la captura HEP sigue intacta),
  **OFF por default**, allowlist de IPs de SBC, tope de sesiones, límites anti-DoS.
- **Activación:** Settings → SIPREC (`siprec_enabled` + puertos/TLS/allowlist). Apunta tu SBC al
  host:puerto del SRS. Ver la guía de integración por vendor en la documentación.

## [2.80.2] — 2026-06-17

### Changed — Rango de tiempo por defecto: últimas 24 h (antes "Todo")
El selector de tiempo global (Dashboard, CDRs y lista de Llamadas) ahora arranca en **24h** en vez de **Todo** — vista más rápida y relevante al abrir. El rango del detalle de troncal también arranca en 24h. "Todo" y los demás rangos siguen disponibles con un clic.

## [2.80.1] — 2026-06-17

### Fixed — Migración del updater se mataba a sí misma (hotfix de 2.80.0)
Cuando un cliente con el auto-updater VIEJO se actualizaba a 2.80, el instalador corría dentro de `voxywatch-update.service` y la migración hacía `systemctl stop voxywatch-update.service` → se enviaba SIGTERM a sí mismo a media instalación y el portal quedaba abajo. Ahora la migración solo deshabilita el timer y borra los archivos de unidad (el oneshot termina solo). Si te pasó: corre el instalador una vez desde shell y queda.

## [2.80.0] — 2026-06-17

### Changed — Actualizaciones opt-in: el portal avisa, tú actualizas con un clic
VoxyWatch ya **no se actualiza solo**. Ahora tú decides cuándo — ningún cambio entra a media operación sin tu visto bueno.
1. **Verificación cada hora**: el portal revisa si hay una versión nueva (antes era a diario) y, cuando la hay, lo avisa en la **campana** 🔔 con el resumen de novedades.
2. **Actualizar con un clic**: el aviso te lleva a **Settings → Actualización**, donde ves tu versión, la última disponible y el botón **"Actualizar ahora"** (solo admin). La descarga se sigue verificando con firma GPG + SHA256.
3. **Se retiró el auto-updater de systemd** (el timer que aplicaba solo a diario) en TODOS los clientes: al instalar esta versión, el instalador deshabilita y elimina el timer/servicio viejos. Migración automática e idempotente.

## [2.79.1] — 2026-06-17

### Fixed — Audio no se reproducía en instalaciones sin ffmpeg
- El instalador ahora **instala `ffmpeg`** (dependencia dura: la reconstrucción de audio lo usa para
  convertir el RTP a WAV). Antes, en una máquina sin ffmpeg, la reconstrucción escribía el audio
  crudo pero **no generaba el WAV** → el reproductor daba 404.
- `reconstruct_audio.py` ahora **falla claro** si ffmpeg no está o si no se generó ningún WAV
  (antes reportaba "éxito" en falso y luego el player daba 404). Mensaje accionable.

## [2.79.0] — 2026-06-16

### Added — Mostrar/ocultar contraseñas (👁) y key de IA con pista de últimos caracteres
- **Ojito 👁** en todos los campos de contraseña (login, perfil, cambio de contraseña, alta de
  usuario y los secretos de Settings) para **verificar lo que escribes** antes de guardar.
- La **API key de IA** ahora, una vez guardada, muestra solo los **últimos 4 caracteres** como pista
  (`••••••3f9a`) — ni el admin recupera el valor, igual que el API token de integración. Los demás
  secretos (contraseñas, tokens, claves SNMP) siguen totalmente enmascarados; solo admin puede
  modificarlos.

## [2.78.0] — 2026-06-16

### Changed — Settings visible en solo-lectura para todos los roles
- Ahora **cualquier usuario** (viewer/operator) puede **ver** la configuración (alarmas, IA,
  integraciones, notificaciones, SNMP, PCI…) en **modo solo-lectura** — antes era admin-only y ni
  se veía. Ayuda a operadores (transparencia de cómo están configuradas las alarmas) y luce el
  producto completo en demos.
- **Solo admin puede modificar**: los guardados siguen bloqueados por RBAC en el backend; para
  no-admin la UI muestra Settings deshabilitado con un aviso "Vista de solo lectura". Todos los
  secretos (contraseñas, API keys, tokens, claves SNMP v3) siguen enmascarados para todos.

## [2.77.0] — 2026-06-16

### Added — Importar troncales desde tu configuración de Asterisk
- En **Troncales → Importar**, nueva opción **"¿Usas Asterisk?"**: sube tu `sip.conf` /
  `pjsip.conf` / `extensions.conf` y VoxyWatch **detecta solo las troncales, sus IPs y sus
  prefijos** — sin capturarlas a mano una por una. Pensado para clientes Asterisk.
- Soporta **chan_sip** (peers `host=`) y **PJSIP** (cose endpoint↔aor↔identify), plantillas `(!)`
  y herencia, y deriva los **prefijos** del dialplan siguiendo los `Dial(.../@troncal)`. Los
  hostnames se resuelven a IP automáticamente (best-effort).
- **Vista previa antes de importar**: muestra qué troncales/IPs/prefijos detectó y los avisos
  (host dinámico, sin resolver, etc.) — tú confirmas el merge. Bilingüe EN/ES.

## [2.76.0] — 2026-06-15

### Changed — La traza SIP, el análisis RFC y el copiloto SIP ahora son para TODOS los roles
- La **escalera SIP**, el **análisis de cumplimiento RFC** y el **copiloto experto en SIP** pasan de
  requerir rol *operator* a estar disponibles también para **viewer** — son funciones de
  **solo-lectura** (ver/analizar una traza), coherentes con lo que un viewer ya puede consultar en
  los CDRs. Así cualquier usuario diagnostica una llamada sin necesitar permisos elevados.
- El **audio** (reproducción/descarga/reconstrucción/PCAP) sigue siendo *operator+* (es contenido de
  llamada, más sensible). Descripciones de rol actualizadas en consecuencia.

## [2.75.1] — 2026-06-15

### Fixed — Limpieza de UI (auditoría de "botones sueltos")
- Eliminado código muerto de descarga de PCAP en el visor de reconstrucción de audio (apuntaba a
  un botón inexistente; la descarga de PCAP sigue disponible en el visor de flujo SIP).
- Agregada la traducción faltante del texto de ayuda "Límite de RAM de parseo" (se mostraba en
  inglés en los demás idiomas).

## [2.75.0] — 2026-06-15

### Added — Alarma OWA "solo baseline" (para redes con audio unidireccional estructural)
- Nuevo flag **`owa_baseline_only`** (OFF por defecto) en los umbrales de salud de troncal. Cuando
  está ON (con la alarma OWA encendida), VoxyWatch **ignora el umbral fijo de % one-way** y alerta
  **únicamente cuando una troncal se sale de SU PROPIO normal histórico** (desviación del baseline).
- Pensado para redes donde el audio unidireccional es **estructural** (media bypass / el SBC no
  espeja ambas patas de RTP a la captura): ahí el % one-way crónico es normal y un umbral fijo
  inundaría de falsos críticos. En modo solo-baseline el nivel crónico queda absorbido y solo
  alerta el **cambio** — exactamente "la asimetría crónica nunca alerta, solo el cambio".
- El % OWA se sigue midiendo y mostrando siempre; esto solo cambia cuándo **alarma**. Configurable
  global y por troncal, bilingüe.

## [2.74.1] — 2026-06-15

### Fixed — La evidencia de los incidentes de fraude/patrón salía vacía
- El recolector de evidencia (v2.74.0) comparaba el timestamp de la llamada (en **segundos**) contra
  una ventana calculada en **milisegundos**, así que descartaba TODAS las llamadas → `by_trunk`,
  `quién origina` y `llamadas de muestra` salían vacíos aunque el incidente fuera real. Corregido a
  segundos en fraude y patrón; ahora la evidencia muestra las troncales y llamadas que dispararon la
  alarma.

## [2.74.0] — 2026-06-14

### Added — Evidencia accionable en cada incidente (qué troncal, quién origina, qué llamadas)
- Los incidentes de **fraude** y **patrón** ahora muestran en el detalle la **evidencia que los
  disparó**: las **troncales que originan** el tráfico al destino sospechoso, **quién lo origina**
  (número/IP, top), y una **tabla de llamadas de muestra** (hora, origen→destino, resultado,
  duración) — antes el incidente decía "destino de alto riesgo … global" sin decir de qué troncal
  ni qué llamadas. Para incidentes de troncal también se muestran los códigos SIP de fallo, las
  rutas con más fallos y otras troncales degradadas a la vez.
- Esta evidencia ya se recolectaba para el diagnóstico de la IA pero **no se mostraba en pantalla**;
  ahora es visible para el operador, con o sin IA.

### Changed — La campana global solo avisa de incidentes del SISTEMA
- El centro de notificaciones (campana) ahora solo levanta incidentes de **salud de la plataforma**
  (captura, sistema, capacidad). Las **alarmas NOC de tráfico** (fraude, patrón estacional, salud de
  troncal, volumen) viven en la vista **Incidentes** con su propio contador — dejan de mezclarse con
  los avisos del sistema en la campana.

## [2.73.0] — 2026-06-14

### Changed — Incidentes más legibles y búsqueda en las vistas operativas
- En la lista de incidentes, la columna **Objeto** ya muestra el **nombre de la troncal** (o una
  etiqueta clara para objetos del sistema: Captura, Recepción HEP, Sistema) en lugar del id
  interno crudo tipo `trk_…` que no le decía nada al operador.
- El **detalle del incidente** presenta los KPIs como **tarjetas etiquetadas con unidad**
  (ASR %, PDD ms, MOS, Pérdida %, etc.) en vez de una sola línea con claves crípticas; el
  diagnóstico de la IA va ahora en su propio bloque destacado.
- Nuevo **buscador** en **Monitoreo** (por troncal) e **Incidentes** (por incidente o troncal),
  complementando el que ya existía en Troncales — para llegar rápido a lo que importa.

### Fixed — Texto en español filtrado en Settings → IA (inglés)
- El consejo del modelo de IA (formato OpenRouter / "dejar vacío para el modelo por defecto")
  estaba escrito a fuego en español y aparecía en inglés también. Ahora respeta el idioma del
  usuario (EN/ES).

## [2.72.0] — 2026-06-14

### Added — Tour de descubrimiento para todos los usuarios
- La primera vez que cualquier usuario entra, un **recorrido guiado** resalta una por una las
  funciones clave — Dashboard, Llamadas (escalera SIP/audio/PCAP), CDRs, Monitoreo de troncales,
  Incidentes, copiloto de IA, avisos y **cómo vincular tu Telegram/correo** — para que nadie se
  pierda lo que la herramienta puede hacer.
- **Adaptado al rol**: cada quien ve solo lo que su rol permite. Se muestra una sola vez por
  usuario (recordado en su perfil) y queda un botón **"?"** en la barra superior para repetirlo
  cuando quieras. Bilingüe EN/ES.

## [2.71.0] — 2026-06-14

### Added — Onboarding del primer admin: que no se te pase configurar nada
- Nueva pestaña **"Primeros pasos"** en Settings con una checklist que **se detecta a sí misma**:
  marca lo que ya configuraste y resalta lo que falta, con una línea de "por qué importa" y un
  botón que te lleva directo a cada sección. Barra de progreso de lo esencial.
- **Recordatorio en la campana** mientras falten los 3 esenciales — un **canal de avisos**
  (Telegram, correo o webhook), **al menos una troncal** y **al menos una alarma encendida** —;
  desaparece solo cuando los tres están listos. No bloquea el uso del portal.
- Además lista los recomendados (captura HEP recibiendo, cambiar contraseña por defecto, copiloto
  IA, grabación, HTTPS, licencia) con su estado. Bilingüe EN/ES, solo para administradores.

## [2.70.1] — 2026-06-14

### Fixed — Telemetría: dejar de gastar cuota del vendor en métricas de rendimiento
- El temporizador de operaciones (`startTimer`) mandaba un evento a Sentry CADA vez que el parse
  incremental pasaba 500 ms — que en producción de alto volumen es lo NORMAL (2-3 s por ciclo).
  Resultado: ~17 mil eventos/día de pura métrica (no errores) agotaban la cuota. La saturación
  real ya la ve el operador EN EL PRODUCTO (detector de cuello + banner); el rendimiento dejó de
  viajar como evento de error.
- **Candado durable**: rate-limiter de cliente en la telemetría — un mismo error se reporta como
  máximo 5 veces por hora; el resto se descarta antes de salir. Ninguna avalancha futura (un
  `console.error` en bucle) puede volver a llenar la cuota.

## [2.70.0] — 2026-06-12

### Added — Perfilador de capacidad: tu servidor se mide solo
- Cada 5 minutos VoxyWatch registra el par **tráfico ↔ recursos** de TU instalación: CPS,
  llamadas simultáneas, paquetes/s, tasa de escritura de grabaciones, junto con CPU (sistema,
  sniffer y portal por separado), RAM, disco (MB/s e IOPS) y red. Todo de `/proc`, costo
  despreciable, retención 30 días (`settings.capacity_profiler`, apagable).
- Export en `GET /api/capacity/samples?days=7&format=csv` — la base para dimensionar
  crecimiento con datos PROPIOS en lugar de estimaciones de folleto (alimenta la calculadora
  de sizing de VoxyWatch).

## [2.69.0] — 2026-06-12

### Added — Snapshot del working-set: la historia visible en segundos tras cada arranque
- El portal persiste periódicamente (y al detenerse) un **snapshot comprimido del working-set**
  y al arrancar lo usa para mostrar la historia completa de llamadas **de inmediato**, mientras
  el backfill normal converge contra la base de datos en segundo plano. En servidores grandes
  el "fondo" del dashboard ya no tarda minutos en aparecer tras una actualización.
- Diseño conservador: el snapshot es **solo un cache de arranque** — nada de lo restaurado se
  escribe jamás a la base de datos, lo activo/reciente siempre se reconstruye fresco desde BD,
  y un snapshot corrupto/ilegible se descarta y elimina solo (auto-sanación), cayendo al
  arranque normal. Configurable en `settings.ws_snapshot` (ON por defecto; apagable).

## [2.68.1] — 2026-06-12

### Fixed — Limpieza de deudas técnicas
- Incidentes de patrones y antifraude ahora se muestran **en tu idioma** en el portal (antes
  solo inglés); webhooks y correo conservan el texto EN como referencia estable.
- Eliminada la línea de error inofensiva del primer arranque tras actualizar (carrera entre el
  cálculo de baselines y la migración del rollup).
- OID base SNMP por defecto = **enterprises.65985** (el PEN oficial de IANA de VoxyWatch) en
  código, UI y ejemplos; instalaciones con OID configurado no cambian.
- El build ahora ofusca/minifica en un staging — los fuentes del repo jamás se tocan (elimina
  de raíz la ventana de carrera del empaquetado).

## [2.68.0] — 2026-06-12

### Added — Detección de audio de UN solo sentido (OWA) + correlación multi-leg
- **Correlación multi-leg**: los SBC B2BUA conservan el Call-ID entre el leg interno y el del
  carrier; antes el portal mezclaba el SDP de un leg con el del otro y "perdía" el segundo canal
  de audio. Ahora se rastrean TODOS los endpoints de media de la llamada y se elige el leg con
  más evidencia → **estéreo real en llamadas que antes salían con un solo canal**.
- **`media_status` por llamada** (visible en el diagnóstico): `both` (dos sentidos), `one_way`
  (un sentido fluye y el otro NO — con evidencia del índice de media, no adivinanzas) y
  `uncorrelated` (la captura no permite afirmar nada — NO se cuenta como falla). También en el
  API v1 (campos aditivos `media_status`/`owa_side`).
- **Alarma OWA por troncal** (nace OFF — `owa_enabled` en los umbrales de salud): razón
  "One-way audio X% of N evaluable" con umbral **configurable** (default warn 5% / critical 15%,
  muestra mínima 20; global y por troncal, editable en la UI de umbrales) y **baseline
  aprendido**: la asimetría crónica de una troncal (media bypass, espejado parcial) no alarma —
  solo el CAMBIO contra su propia norma. El % se mide y el baseline aprende desde ya, aunque la
  alarma esté apagada; enciéndela tras ver tus números reales. Entra al motor de incidentes con
  notificaciones, diagnóstico IA y **runbook de fábrica** (qué lado falta, NAT/firewall,
  renegociación de codecs, el fix va en el SBC del cliente).

## [2.67.1] — 2026-06-12

### Fixed — Audio recuperado en llamadas con UN solo sentido correlacionado
- Con SBCs que no etiquetan el RTP con Call-ID, muchas llamadas correlacionan solo el flujo del
  caller (callee desconocido). La reconstrucción exigía AMBOS SSRC: sin el segundo, apagaba el
  filtro, cargaba TODOS los flujos de la ventana y "adivinaba" — a alto volumen eso era audio de
  OTRA llamada, o un timeout que la UI mostraba como "sin audio" **aunque el RTP sí estuviera en
  disco**. Ahora filtra por el/los SSRC conocidos aunque sea uno solo.
- Con un solo sentido se generan igualmente los WAV mono y estéreo (canal duplicado) que el
  reproductor espera — antes no se creaban y el player decía "sin audio".
- El auto-descubrimiento (elegir los 2 flujos más grandes) queda SOLO para llamadas sin ningún
  SSRC correlacionado, y jamás pisa un SSRC conocido.

## [2.67.0] — 2026-06-12

### Added — UI de alarmas + simulador "¿qué habría alertado?" (Fase 4, cierra el sistema de 3 tipos)
- **Settings → Alertas → Alarmas**: los 3 tipos ahora se configuran desde el portal, bilingüe:
  · Tipo 1 (umbrales SIP): **editor de reglas** por clase/código con % warn/critical, filas
    agregables/eliminables, ventana, muestra mínima y vigilancia de rechazos locales (SBC).
  · Tipo 2 (patrones aprendidos): semanas de historia, sensibilidad z warn/critical, volumen mínimo.
  · Tipo 3 (antifraude): umbral de destino nuevo, **lista editable de países de alto riesgo**,
    tormenta de cortas (duración/llamadas) y país "casa" del % internacional (vacío = se aprende solo).
- **Simulador integrado**: botón "¿qué habría alertado?" reproduce tus últimos 3/7/14 días de
  historia real contra la configuración actual (read-only, no dispara nada) y muestra cuántos
  incidentes habrían sonado por tipo, con ejemplos — calibra ANTES de encender, sin sorpresas.
  Nuevo endpoint `POST /api/alarms/simulate` (admin, solo lectura).

## [2.66.0] — 2026-06-12

### Added — Detección temprana de FRAUDE (Fase 3: el caso "empezó a mandar a Cuba")
- **Destino jamás marcado**: si una troncal (o el sistema) empieza a llamar a un país que NO aparece
  en sus últimas 4 semanas de tráfico, alerta de inmediato — `warn` si es un país cualquiera,
  `critical` si está en la lista de alto riesgo. El detector que atrapa la cuenta SIP comprometida
  el primer día, no en la factura.
- **Destinos de alto riesgo (IRSF/premium)**: lista editable con default de la industria (Cuba,
  Somalia, Letonia, Maldivas, Papúa…); tráfico conocido pero MUY por encima de su ritmo típico
  por ventana → `critical`.
- **Tormenta de llamadas cortas**: N llamadas contestadas de ≤10 s al mismo destino en la ventana
  (barrido de números premium / PBX hackeada) — activo desde el día 1, no necesita historial.
- **Salto del % internacional**: la mezcla nacional/internacional de una troncal se dispara contra
  su mediana histórica (país "casa" configurable o aprendido solo del tráfico).
- Todo por el motor de incidentes (tipo `fraud`) con **runbook de fábrica** (quién origina, horario,
  cortas vs largas, bloquear EN EL SBC del cliente y disputar con el carrier — VoxyWatch nunca toca
  el SBC). Sin historial maduro los detectores históricos CALLAN (silencio honesto); nace OFF
  (`settings.fraud_alarms.enabled`).
- Calibrador `tools/simulate_fraud.js` contra los rollups reales del cliente antes de encender.

## [2.65.0] — 2026-06-12

### Added — Alarmas por patrones aprendidos (Fase 2: "tu lunes se compara con TUS lunes")
- **Baseline estacional de 168 buckets** (día de la semana × hora) por troncal y global, aprendido
  de las últimas 4 semanas de tráfico con estadística robusta (mediana/MAD — una falla histórica no
  contamina el "normal"). Detecta cuando el patrón cambia:
  · **Picos de volumen** ("martes 02:00 normal ~480 llamadas; van 2,900, z +6.1") — la firma clásica
    del toll-fraud nocturno se detecta por diseño.
  · **Silencio anómalo** (troncal que debería tener tráfico a esta hora y cayó) — ambos sentidos.
  · **ASR que cae / PDD que sube** contra el normal de ESA hora (el ASR nocturno normal difiere del
    diurno; los umbrales planos no lo saben — este baseline sí).
- **Aprendizaje honesto**: sin 2+ semanas de datos el sistema calla (jamás inventa un "normal");
  los buckets maduran solos con el tiempo. Sensibilidad configurable (z robusto warn/critical).
- Emite por el motor de incidentes (tipo `pattern`): deduplicación, investigador IA, runbooks y
  notificaciones por usuario. Nace OFF (`settings.pattern_alarms.enabled`).
- Herramienta de calibración `tools/simulate_seasonal.js`: "¿cuántas alertas habría dado la última
  semana?" contra los datos reales del cliente, antes de encender.

## [2.64.0] — 2026-06-12

### Added — Alarmas de señalización SIP (Fase 1 del sistema de alarmas de 3 tipos)
- **Tasas de fallas por clase y por código SIP**, globales y por troncal, sobre ventana configurable:
  5xx, 6xx, 4xx "útil" (excluye comportamiento de usuario: auth 401/407, ocupado 480/486, cancel 487)
  y códigos vigilados con umbrales propios (503, 403, 500, 502, 504, 483 de fábrica — lista editable).
  Ejemplo: "SIP 503 Service Unavailable: 18.2% de 240 intentos (Troncal X)".
- **¿El rechazo nació en TU SBC o en el carrier?** Nueva señal `local_reject`: VoxyWatch sabe qué IP
  emitió cada respuesta — si el rechazo final no vino de ninguna troncal del catálogo, lo generó un
  elemento local (CAC, límites, auth, ruteo del SBC). Alarma propia: "Local rejects by SBC: 12%".
- Anti-falsos-positivos heredado y propio: muestra mínima por ventana (50 intentos default),
  critical solo sostenido (2 evaluaciones), silencio honesto sin muestra suficiente.
- Todo emite por el motor de incidentes: deduplicación, timeline, investigador IA, runbooks y
  notificaciones por usuario (Telegram/correo) sin configuración extra. Nace OFF
  (`settings.sip_alarms.enabled`); reglas y umbrales 100% configurables.

## [2.63.1] — 2026-06-12

### Fixed — Notificaciones de incidentes legibles para humanos
- **El diagnóstico de IA llegaba como JSON crudo y cortado a media frase** ("🤖 {"root_cause_hypothesis": "La causa…"): el investigador tenía un presupuesto de tokens corto que truncaba la respuesta del LLM, el parser fallaba con el JSON incompleto y el texto crudo se guardaba tal cual. Triple fix: más presupuesto + prompt acotado a prosa breve, parser con rescate de JSON truncado (extrae los campos aunque venga cortado), y limpieza defensiva al mostrar — también para los diagnósticos antiguos ya guardados (Telegram, correo y portal).
- **IDs internos fuera de los mensajes**: el identificador interno de troncal (trk_…) ya no aparece ni en el título ni dentro del diagnóstico — solo el nombre real de la troncal.
- **Formato humano**: "Troncal WIND > BICD > DID" en lugar de "Trunk … warn (trk_…)"; KPIs con nombre y unidad (ASR 76.7% · MOS 3.26 · Pérdida 1.3% · PDD 3.2 s); ✅ en resueltos (antes 🟡); truncado al final de palabra, no a media frase.
- Nota: los mensajes de incidente RESUELTO no llevan botones a propósito (no hay nada que accionar); los de incidente abierto/escalado conservan Ack · Resolver · Investigar · acción propuesta.

## [2.63.0] — 2026-06-12

### Fixed — Elementos invisibles desde la CSP: menú de usuario, HEP Sources y más
- **Menú de usuario (arriba a la derecha) restaurado**: el bloque con tu usuario, Perfil y Cerrar
  sesión era invisible desde v2.52 — el JS lo "mostraba" con un mecanismo que solo funcionaba con
  los estilos antiguos. Mismo destino sufrían: el cuadro completo de **Active HEP Sources** en
  Settings (por eso se veía vacío aunque hubiera fuentes), el **ícono del sol** del botón de tema,
  el **badge de la campana** de notificaciones, el botón de SSO en el login y el panel de
  diagnóstico del detalle de llamada. Barrido completo: 16 elementos resucitados, patrón erradicado
  y candado automático para que no pueda volver a entrar.
- Las fechas de Active HEP Sources mostraban "1/1970" (timestamps en segundos tratados como
  milisegundos) — visible apenas revivió la tabla; corregido.

### Changed — Calidad de vida en la UI
- **KPIs con números grandes** (Total calls, Failed, re-INVITEs): notación compacta (41M, 154K)
  con el número exacto en tooltip — ya no se desbordan de la tarjeta.
- **La ventana de Settings ahora se puede mover y redimensionar**: arrastra el encabezado para
  moverla, estira la esquina inferior derecha para cambiar el tamaño (mínimo 720×460, máximo el
  96% de la pantalla); posición y tamaño se recuerdan, y doble clic en el encabezado restaura el
  centrado por defecto. El contenido se reacomoda al cambiar el tamaño.

## [2.62.1] — 2026-06-12

### Fixed — Modo claro legible en todo el portal
- **Inputs oscuros en tema claro** (login, chat de IA, alta de usuario y otros formularios): la
  variable `--bg-main` (fondo de campos) existía solo en el tema oscuro, y 9 variables CSS
  "fantasma" (`--bg-primary`, `--border`, `--accent`… jamás definidas) caían siempre a sus
  fallbacks oscuros. Todas mapeadas a las variables reales del design system (53 usos en CSS/JS/HTML)
  y `--bg-main` definida también en claro → campos legibles en ambos temas.
- El login ya no fuerza fondo oscuro "en ambos temas" (parche viejo): usa las variables del tema.
- El botón de cambio de tema era casi invisible en modo claro (texto terciario sobre fondo pálido) —
  ahora usa el color secundario, con buen contraste en ambos temas.

## [2.62.0] — 2026-06-11

### Fixed — Visor de flujo SIP: diagrama y estados a nivel experto
- **Flechas y colores del diagrama interactivo restaurados**: el `<style>` embebido en el SVG quedaba bloqueado por la CSP desde v2.52 → el ladder se veía sin colores ni formato. Las reglas viven ahora en la hoja de estilos del portal.
- **Estados de diálogo SIP correctos según RFC 3261**: los 6xx no estaban contemplados — un `603 Decline` se etiquetaba "en ruta". Ahora: BUSY (486) / BUSY EVERYWHERE (600) / DECLINED (603) / NOT FOUND (404/604) / REDIRECTED (3xx) / AUTH CHALLENGE (401/407 sin resolver) / SERVER ERROR (5xx) / GLOBAL FAILURE (6xx) / CANCELLED vs CANCELLED WHILE RINGING / PROCEEDING / NO RESPONSE — cada uno con su color.
- **Idiomas**: los estados salían en español fijo ("COMPLETA", "HUÉRFANO") — ahora el servidor manda claves y la UI traduce (inglés primero, español como segundo idioma), consistente con el resto del producto.
- **El `200 OK` al CANCEL contaba como llamada contestada** → una llamada cancelada mientras timbraba aparecía ACTIVE. El answer ahora exige `CSeq: INVITE`.
- **Pings OPTIONS fuera del listado de llamadas**: la respuesta `200 OK` del keep-alive creaba una "llamada" Unknown que parecía activa. El diálogo OPTIONS completo (request y respuestas) se excluye de la captura visible.

### Changed — Layout del visor
- Botón **PCAP** junto a "SIP .txt" en la barra del diagrama; **WAV** al lado izquierdo del reproductor (a la derecha lo tapaba el chat de IA). Título sin "(HEP Trace)".

## [2.61.1] — 2026-06-11

### Fixed — Login y modales invisibles (regresión de la CSP v2.52)
- La conversión CSP de estilos inline a clases (v2.52) dejó `display:…!important` en 78 clases
  generadas → **ningún elemento mostrado/ocultado por JavaScript podía aparecer**: al expirar la
  sesión, el login no se mostraba y el portal quedaba "en blanco" (dashboard en ceros, sin datos,
  sin troncales, sin gráficas); los modales de perfil y cambio de contraseña tampoco abrían.
  Fix: `display` sin `!important` en las clases generadas — el estado inicial es idéntico y el JS
  recupera el control, que era la semántica original de los estilos inline. Verificado en vivo:
  login aparece al expirar la sesión, modales abren y cierran.

## [2.61.0] — 2026-06-11

### Added — Notificaciones POR USUARIO (Telegram + correo)
- **Telegram por usuario**: un bot por instalación (wizard guiado de 2 minutos con validación en vivo del token) y cada usuario del portal vincula SU chat con un código de un solo uso `VW-XXXXXX` desde Perfil → Mis notificaciones — sin tokens ni chat IDs. Las acciones desde Telegram quedan auditadas con el username real del portal y **gateadas por rol** (viewer recibe sin botones). El chat de sala NOC global pasa a ser **opcional**.
- **Correo por usuario**: sección **SMTP global** en Settings → Alertas con presets Gmail/Microsoft 365, guía paso a paso en pantalla y correo de prueba en vivo (el error del servidor se muestra tal cual para diagnóstico). Cada usuario activa "recibir incidentes por correo" con su email del perfil; los correos llevan link al portal (`portal_url`).
- **Preferencias por usuario**: severidad mínima (critical/warn) y digest opt-in, por canal.

### Fixed
- **Regresión de assets (CSP)**: `index.html` referenciaba Chart.js desde CDN y el update-checker inline — ambos bloqueados por la CSP estricta → gráficas del dashboard sin renderizar. Restaurados `chart.umd.min.js` (verificado contra hash SRI) y `update-checker.js` self-hosted, añadidos a build/install, y check permanente post-deploy.
- `GET /api/alerts` ya no expone el token del bot de Telegram (solo devuelve la config del webhook).
- Cambiar el token del bot invalida la identidad cacheada (getMe) y resetea el offset del long-poll (antes la vinculación quedaba muerta hasta 1 h).
- `POST /api/alerts` ya no borra los campos de Telegram al guardar solo el webhook.
- `getMe` fallido se cachea 60 s — abrir "Mis notificaciones" sin salida a internet ya no cuelga 10 s por request.

## [2.60.0] — 2026-06-11

### Changed — Anti-falsos-positivos: confianza estadística antes de CRITICAL
Validado contra los 78 incidentes reales de C3ntro: **65 críticos → ~5 que de verdad ameritan despertar a alguien (−92% de ruido)**, sin perder registro ni visibilidad (las razones degradadas se conservan con flag `degraded`).
1. **Muestra escalonada**: declarar CRITICAL exige ≥ `trunk_health.min_calls_critical` (default 100) llamadas en la ventana; con menos, las razones críticas bajan a warn. *(El 83% del ruido venía de troncales con <100 llamadas.)*
2. **Severidad adaptativa por baseline**: con baseline maduro, una razón CRITICAL absoluta cuya métrica está dentro de su normal histórico (z < `baseline_z`) baja a warn — *"esa troncal siempre es así"* deja de ser incidente crítico.
3. **Cobertura de medición**: MOS/pérdida solo alarman si se midieron en ≥ `quality_min_coverage_pct` (default 30%) de las llamadas — en deployments sin RTCP la muestra sesgada ya no domina (eran el 65% de las razones).
4. **Persistencia**: el incidente de troncal nace warn y solo ESCALA a critical (y notifica) tras `incidents.crit_sustain_evals` (default 3) evaluaciones consecutivas en crítico — un pico de una ventana ya no suena.
Todo configurable (global y por troncal vía `trunk.health`); afecta severidad de alarmas/incidentes, no las métricas mostradas.

## [2.59.0] — 2026-06-11

### Added — Grabación selectiva por troncal (#31)
- `recording_scope: {mode: all|trunks, trunks:[ids]}` — con `trunks`, **solo se persiste el RTP/audio de las troncales listadas** (SIP/CDR siempre se guardan) → estira la retención de audio sin comprar disco. Reusa la supresión por SSRC del sniffer (PCI F1b) vía el mismo `pci_suppress.json` — **sin tocar ni reiniciar el sniffer**. Las llamadas sin troncal atribuida se graban (conservador). Default `all` (sin cambio).

### Added — UI de Settings → Alertas
- Nueva sub-pestaña **Alertas**: webhook (+diagnóstico IA), **Telegram de incidentes** (token/chat/severidad), motor de incidentes (on/off, presupuesto IA/h), **digest** (hora/período/umbral de retención de audio) y **grabación selectiva** — todo lo de F1-F4 y #31 configurable desde el portal, bilingüe.

### Added — Servidor MCP standalone (NOC Agéntico F6.1, `docs/MCP_SERVER.md`)
- `voxywatch-mcp.js` (Node puro, stdio, JSON-RPC/MCP 2024-11-05): expone `get_health`, `get_stats`, `get_trunks_health`, `get_cdrs`, `get_incidents`, `get_incident` como tools MCP para Claude Desktop/Code u otros agentes. **Cliente del API v1** (hereda API keys/scopes/rate-limit); read-only por diseño. Se empaqueta e instala en `/opt/voxywatch/voxywatch-mcp.js`.

## [2.58.0] — 2026-06-11

### Added — Incidentes en la API de integración (NOC Agéntico F6 parcial, `docs/DESIGN_NOC_AGENTICO.md` §8)
- **`GET /api/v1/incidents`** (lista con filtros) y **`GET /api/v1/incidents/:id`** (detalle + evidencia + diagnóstico + timeline) con **scope nuevo `incidents:read`** — el NOC/ticketing del cliente o un agente externo consume los incidentes con API key (mismo modelo problem+json del API v1).
- Pendiente F6.1 (turno propio): servidor **MCP** standalone (`voxywatch-mcp`, stdio+SSE) exponiendo las tools del copiloto + incidentes a agentes externos.

## [2.57.0] — 2026-06-11

### Added — Runbooks + memoria de casos (NOC Agéntico F5, `docs/DESIGN_NOC_AGENTICO.md` §7)
- **Runbooks**: 4 de fábrica embebidos (`trunk-asr-low`, `trunk-loss-high`, `capture-down`, `volume-drop`) + extensibles/override en `DATA_DIR/runbooks/*.json` (mismo formato `{id, match:{type, reason_prefix}, steps[], default_action}`). Cuando un incidente matchea, **el investigador sigue los pasos y los cita** en su diagnóstico; el runbook queda en la evidencia (`evidence.runbook`).
- **Memoria de casos**: al investigar, se adjuntan los últimos incidentes **resueltos por humanos** del mismo fingerprint con su resolución (`evidence.similar_cases`) y el investigador los referencia — *"esto ya pasó el día X y se arregló así"*. Las resoluciones que escribes en la UI/Telegram se convierten en conocimiento reutilizable.

## [2.56.0] — 2026-06-11

### Added — Forecast de capacidad + digest (NOC Agéntico F4, `docs/DESIGN_NOC_AGENTICO.md` §6)
- **Retención real de audio medida y expuesta**: `computeAudioRetention()` (edad del segmento más viejo + ritmo GB/h) en `/api/v1/health` (campo `audio`) y en el digest. Si cae bajo `digest.capacity_min_audio_h` (default 0 = solo informativo) se abre un **incidente `capacity`** (warn) 1×/día, con recovery automático.
- **Digest diario/semanal** (determinístico, bilingüe): incidentes del período, salud de troncales, volumen vs período anterior, retención de audio y disco. Envío programado por **Telegram y/o webhook** (`digest.enabled`, `hour`, `period`) y **on-demand**: `GET /api/reports/digest?period=day|week&lang=es|en`.
- Settings `digest{}` persistibles vía POST /api/settings. OFF por defecto.

## [2.55.0] — 2026-06-11

### Added — Telegram accionable + acciones aprobadas (NOC Agéntico F3, `docs/DESIGN_NOC_AGENTICO.md` §5)
- **Canal Telegram nativo opcional** (además del webhook): al abrir/escalar un incidente ≥ `alerts.notify_min_severity` se envía mensaje con KPIs y el 🤖 diagnóstico del investigador (la notificación espera 45 s para incluirlo), con **botones inline**: `✅ Ack` · `✔ Resolver` · `🔍 Investigar` · y la **acción propuesta aplicable**. Resolución automática también notifica.
- **Catálogo de acciones CERRADO EN CÓDIGO** (allowlist; el SBC no existe aquí): `restart_sniffer` (solo incidentes de captura; reusa el mecanismo D-Bus/polkit existente) y `refresh_baselines`. **Toda aprobación y resultado queda en el timeline** del incidente (eventos `action: approved → done|failed`).
- **Solo obedece al chat configurado** (`alerts.telegram_chat_id`); long-poll `getUpdates` con offset persistido (no re-procesa tras reinicios); token enmascarado en GET /api/settings.
- `settings.alerts` ahora **se persiste vía POST /api/settings** (webhook + telegram; antes solo editable a mano).
- OFF por defecto (`alerts.telegram_enabled=false`). Fix de robustez: el parser del diagnóstico LLM extrae el primer JSON balanceado (fences/texto alrededor ya no lo rompen).
- Pendiente F3.1: UI de Settings para configurar el canal (hoy vía API/JSON) y acciones snooze/purge.

## [2.54.0] — 2026-06-11

### Added — Investigador automático de incidentes (NOC Agéntico F2, `docs/DESIGN_NOC_AGENTICO.md` §4)
- **Al abrir/escalar un incidente, el sistema investiga solo**: `collectIncidentEvidence` junta evidencia **determinística** (sin LLM) del working-set y los rollups — llamadas de muestra afectadas, códigos SIP dominantes, rutas IP de los fallos, ¿otras troncales degradadas a la vez? (local vs carrier), última hora vs norma — y la guarda en el incidente (evento `evidence`).
- **Diagnóstico LLM opcional**: un agente investigador (3 tools nuevas: `get_incident`, `get_error_breakdown`, `compare_baseline` + las 5 del copiloto) produce un JSON estructurado `{root_cause_hypothesis, confidence, scope: carrier|cliente|local|capacidad, recommended_action, evidence_cited}` que se guarda en el incidente y se muestra en el modal (🤖 Diagnóstico IA). **Sin API key, el incidente vale igual con la evidencia cruda.**
- **Presupuesto anti-costo**: máx `incidents.ai_max_per_hour` (default 12) investigaciones/h + cache 5 min por fingerprint. Re-investigación manual: `POST /api/incidents/:id/investigate`.
- El investigador **jamás propone tocar el SBC** (charter en el prompt y sin tool para ello).

## [2.53.0] — 2026-06-11

### Added — Motor de incidentes (NOC Agéntico F1, `docs/DESIGN_NOC_AGENTICO.md` §3)
- **Toda anomalía se convierte en un incidente persistente** con ciclo de vida (open → ack → resolved), deduplicado por *fingerprint* (máx. 1 sin resolver por objeto) y con **timeline auditable** (`incidents` + `incident_events`, schema v7; el portal también crea las tablas al boot — idempotente).
- **Detectores** (señales ya existentes, ahora con memoria): transiciones de salud de troncal (`runTrunkHealthAlerts` — registra warn/critical **aunque no haya webhook**), sniffer caído, 0 fuentes HEP, pérdida de captura sostenida (drops de kernel), cuello de sistema crítico sostenido (por recurso), y **caída de tráfico global** vs la norma histórica de la misma hora (14 días).
- **Anti-flapping de 2º nivel:** la recuperación NO resuelve — marca `recovered` y el incidente se auto-resuelve tras `auto_resolve_stable_min` (default 30) estable; una recaída lo reactiva (evento `relapsed`) y una severidad mayor lo escala (evento `escalated`).
- **API** `/api/incidents` (lista con filtros), `/summary`, `/:id` (detalle+timeline), `POST /:id/ack|resolve|comment` (roles viewer/operator).
- **UI**: pestaña principal **Incidentes** (chips de resumen, filtros, tabla, modal de detalle con timeline y acciones) + **badge en el nav** + aviso en la campana. Bilingüe ES/EN (`title_key`+params — el server no fija idioma).
- El **webhook de alarmas gana `incident_id`** (retro-compatible: el payload existente no cambia).
- Settings `incidents{enabled,auto_resolve_stable_min,retention_days,volume_global_drop_pct}` — **default ON** (solo registra; notificar llega en F3). Retención de resueltos: 90 días.
- Pruebas: `test/incidents.test.js` (13 casos del ciclo de vida contra BD real).

## [2.52.0] — 2026-06-11

### Security — `style-src` sin `unsafe-inline` (#031)
- Se elimina `'unsafe-inline'` de la directiva **`style-src`** del CSP principal (antes solo `script-src` lo había logrado). El portal endurece así su política contra inyección de estilos.
- **~510 atributos `style=` inline → clases CSS** (transformación 1:1 con `!important` para preservar la especificidad del inline; **validado pixel-perfect** con Chrome headless: render idéntico salvo el reloj que avanza 1 s).
- Los **estilos con valores dinámicos** (anchos/colores calculados en runtime) se emiten como `data-vstyle="…"` (un `data-*` no lo bloquea el CSP) y un **MutationObserver** en `app.js` los aplica vía CSSOM (`el.style.cssText`, permitido por CSP) en cuanto el nodo entra al DOM — sin tocar la lógica de cada render.
- Los `<style>` inline de `index.html` y la página puente SSO reciben **nonce por respuesta** (vía header, no `<meta>`). `blocked.html` conserva su CSP propia con inline (página autónoma de error).
- Header final: `style-src 'self' 'nonce-…'`. Las asignaciones `element.style.x=` por JS (CSSOM) nunca estuvieron sujetas a `style-src`, así que no se tocaron.

## [2.51.0] — 2026-06-11

### Added — firma GPG de releases (#030)
- El tarball se firma con la clave del vendor (`releases@voxywatch.com`, `80EDE252…`) en `build.sh`/`sign-and-publish.sh` → `*.tar.gz.asc`; `latest.json` gana `linux_x64.signature`.
- `install.sh` verifica la firma con la **clave pública embebida** (ancla de confianza en el propio script), **además** del SHA-256. Retrocompatible y best-effort: sin firma o sin `gpg` → sigue con SHA; **solo una firma INVÁLIDA aborta**. Protege contra un canal/Releases comprometido (el SHA viene del mismo manifiesto; la firma requiere la clave privada OFFLINE).

### Added — Modo PCI F2: auto-pausa de grabación por DTMF (SIP INFO) + UI
- `_pciAutoTrigger` gana trigger por **DTMF vía SIP INFO** (`application/dtmf*`, RFC 2976): pausa la grabación mientras llegan dígitos (el cliente teclea su tarjeta) y **auto-reanuda** tras `dtmf_resume_sec` sin tonos. Settings `pci.dtmf_trigger` / `pci.dtmf_resume_sec`.
- POST `/api/settings` ahora **persiste el bloque `pci`** (merge con el actual → no pierde `sweep_interval_ms`; CSV→array).
- **UI** en Settings → Seguridad: habilitar PCI, conservar SIP/CDR, trigger por DTMF, ventana de seguridad, troncales/DIDs sensibles. Bilingüe (ES/EN), con clases CSS (sin `style` inline).
- `pci.enabled` sigue **OFF** por defecto. RFC 2833 (telephone-event en RTP) en modo `audio_storage='files'` queda como extensión (mismo bloqueador que el audio: RTP sin Call-ID en vivo).

## [2.50.0] — 2026-06-11

### Fixed — el audio se asocia a las trazas en modo `audio_storage='files'` (correlación por SDP)
- **Causa raíz:** con `audio_storage='files'` el RTP va a segmentos `.seg` en disco y **no entra al working-set en RAM** del portal. La correlación RTP↔llamada era *time-window-driven* sobre `_rtpStats` (RAM), que quedaba vacío → **toda llamada salía `ssrc_caller/callee='Unknown'`, `packets=0`, `has_audio=false`** aunque el audio existiera en disco (en C3ntro, 622 GB de `.seg` sin asociar a ninguna llamada).
- **Fix de fondo — correlación DETERMINISTA por el `c=/m=` del SDP (no heurística):**
  - **Sniffer (`hep_sniffer.py`):** el sidecar `.idx` pasa de "lista de SSRC" a **una línea por SSRC con `dst_ip dst_port first_ts last_ts count`** (el destino del flujo + su ventana temporal). El `.seg`/blob NO cambia (compat total con datos existentes). El SSRC sigue siendo el primer token → retrocompatible.
  - **Portal (`server.js` + nuevo `lib/segindex.js`):** deja de descartar `mediaPort` del SDP; guarda `media_ip:media_port` de cada lado (INVITE=caller, 200 OK=callee). Un índice de segmentos en RAM (cacheado por mtime, solo lee los `.idx` ligeros, nunca los GB de RTP) casa cada SSRC con su llamada por **dst_port == media_port** (y `dst_ip` si el SBC no lo reescribe) dentro de la ventana. Convención RFC 3264: el RTP que va al media del callee lo produce el caller (→ `ssrc_caller`) y viceversa. De ahí salen `ssrc_caller/callee`, `packets` y `has_audio` correctos.
  - Si el deployment envía RTCP, los SSRC correlacionados habilitan jitter/loss/MOS reales; sin RTCP **no se inventan** métricas (solo se afirma que el audio existe y de quién es).
  - `reconstruct_audio.py` ahora recibe los SSRC reales (en vez de `unknown`) → filtra exacto en vez de auto-descubrir.
- **Compat:** en modo `db` (default) el comportamiento es idéntico (la rama nueva está guardada por la presencia del índice de segmentos). Los `.idx` viejos de 1 columna y los `.seg` existentes se siguen leyendo.
- **Pruebas:** `test/segindex.test.js` (13 casos: convención caller/callee, fallback por puerto cuando el SBC reescribe la IP, ventana temporal, audio unidireccional, no doble-conteo, cache por mtime, poda por antigüedad).

## [2.49.4] — 2026-06-10

### Fixed
- **HWID estable** — `getHardwareId()` (y `tools/get-hwid.js`) ignoran las interfaces virtuales (Docker `br-*`/`veth`/VPN/contenedores) cuya MAC se regenera al reiniciar y cambiaba el HWID → invalidaba la licencia (`maquina_incorrecta`). Ahora el HWID se deriva solo de NICs físicas → estable entre reinicios.

## [2.49.3] — 2026-06-10

### Fixed (revalidación pentest v2.49.2 — tickets 026/028/029)
- **#028 — la UI ya no dispara endpoints protegidos antes de login** — el wrapper de `fetch` bloquea las llamadas `/api/*` protegidas cuando no hay sesión (devuelve 401 sintético local), dejando pasar solo las públicas (`auth`, `version`, `license/status`, `openapi`, `server-alerts`). Se acaba la ráfaga de 401 pre-login.
- **#026 — Disconnect Causes de raíz** — los **3xx (302 Moved Temporarily)** ahora son `redirected` con su razón SIP (no "Sin respuesta"); y un `no-answer` con `disposition_label` específico ya no se entierra bajo el genérico. Afecta el dato, no solo el dashboard.
- **#029 — aviso SNMP inseguro** — si v2c escucha fuera de loopback sin allowlist, se loguea un warning accionable al arrancar (no se cambia la config para no romper un NMS existente).

## [2.49.2] — 2026-06-10

### Fixed
- **#2 (BLOCKER) — login no aparecía en navegador limpio** — `/api/auth/me` sin sesión responde `200 {ok:false, authenticated:false}`, pero `checkAuth` solo contemplaba `200+ok` y `401`; el caso `200+authenticated:false` caía al retry y el overlay de login nunca se mostraba (se veía el dashboard vacío sin sesión). Ahora ese caso muestra el login. El overlay (position:fixed, z-index máximo) tapa el shell.

## [2.49.1] — 2026-06-10

### Fixed (hallazgos del debug avanzado de preventa)
- **#5 — `/api/calls?status=` valida el enum** — un valor inválido (p.ej. `bogus`) ahora responde **400** con la lista válida (`all`/`completas`/`rejected`) en vez de 200 sin filtrar; se normalizan alias comunes (`completed`→`completas`, `failed`→`rejected`).
- **#6 — Disconnect Causes no entierra causas específicas** — cuando el motivo es genérico ("Sin respuesta"/"Sin código") pero hay `disposition_label` o código SIP, el histograma agrupa por el específico (302, Ignored…) en vez del genérico.
- **#7 — SNMP seguro por defecto** — `snmp_bind_address` ahora es `127.0.0.1` (antes `0.0.0.0`); exponer a la red requiere cambiarlo explícitamente + allowlist.
- **#4 — `getDbState` (MIN/MAX(id) sobre `packets`)** — single-flight + cache de 1 s: coalesce las llamadas concurrentes que competían con la ingesta (observado en el reporte), sin cambiar la query ni la semántica.

## [2.49.0] — 2026-06-10

### Modo PCI — F1b (sniffer), F1c (probe) y F2 (auto-trigger). Sigue OFF por defecto
- **3 capas de supresión (defense-in-depth), match por SSRC (preciso):**
  - **F1c — probe (origen)** ⭐: el agente Go (`voxywatch-probe`) **no envía** el RTP del SSRC en ventana de pago → el dato nunca sale del entorno seguro (óptimo PCI). Lee `pci_suppress.json` (path `VW_PROBE_PCI_FILE`, default `/etc/voxywatch-probe/pci_suppress.json`).
  - **F1b — sniffer (universal)**: `hep_sniffer.py` no persiste el RTP de SSRC suprimidos (lee `pci_suppress.json` de DATA_DIR en caliente). Cubre cualquier fuente HEP, no solo el probe.
  - **F1 — portal**: borra el RTP que se cuele (ya en v2.48.0).
- **F2 — auto-trigger:** `pci.sensitive_trunks` / `pci.sensitive_dids` → las llamadas activas en esas troncales/DIDs se auto-pausan (toda la llamada). Triple guard (enabled + lista no vacía + match).
- Con `pci.enabled=false` (default) y sin `pci_suppress.json`, **todo el comportamiento es idéntico al actual** (set de SSRC vacío → sin efecto). Diseño en `docs/DESIGN_PCI_PAUSE_RESUME.md`.

---

## [2.48.0] — 2026-06-10

### Modo PCI / pause-resume de grabación — F1 (lado portal), OFF por defecto
- Cumplimiento **PCI-DSS**: permite suprimir el audio/RTP durante ventanas de pago (CVV) para que no se almacene. **Programable on/off** vía `settings.pci.enabled` (master switch, **OFF por defecto** → no afecta a nadie) y por **API** (el IVR/CRM lo controla por llamada).
- Nuevos endpoints (`scope recording:control`): `POST /api/v1/recording/suppress {call_id, action:pause|resume}` y `GET /api/v1/recording/suppress/status`.
- F1 (lado portal): al pausar, el RTP de la llamada se **borra de `rtp_packets`** de inmediato y en barridos cada `sweep_interval_ms`; al reanudar, barrido final de la ventana. **Auto-resume** de seguridad (`max_window_min`) si nadie llama a resume. SIP/CDR se conserva (no contiene datos de tarjeta). Auditoría en memoria + `pci_suppress.json` (que el sniffer leerá en F1b).
- **F1b (siguiente):** supresión en el **sniffer** (no-persistencia, PCI estricto — el RTP no toca disco). Diseño en `docs/DESIGN_PCI_PAUSE_RESUME.md`.

---

## [2.47.0] — 2026-06-10

### Purga incremental (VOXY-7) — detrás de flag, OFF por defecto
- **Problema:** cada purga de retención (TimescaleDB dropea el chunk más viejo → `MIN(id)` sube) disparaba un `parseCapture` **full O(N)** (~23 s a alto volumen: re-lee y re-correlaciona TODO el working-set), aunque la purga solo eliminó lo más viejo.
- **Fix:** nueva `_evictPurgedAndRebuild(newMinId)` — descarta de RAM lo purgado (`packet_num < newMinId`) y re-correlaciona desde lo que queda (`rebuildCallMetadata`), sin re-leer la BD. Convierte el O(N) de 23 s en O(purgados). Limpia el estado acumulado huérfano (`_callEvents`/`_rtpStats`/`_rtcpStats`).
- **Seguridad:** gobernado por `VW_INCR_PURGE` (**OFF por defecto** → comportamiento idéntico al actual). ⚠ Antes de activar en producción hay que **validar paridad** con datos reales (riesgo conocido: un SSRC cuyo stream RTP cruza el borde de la purga conserva `_rtpStats` con paquetes ya purgados → leve divergencia de jitter/MOS). Mecanismo de QA: comparar dumps `_maybeDumpCalls` de `purge` vs `full`.

---

## [2.46.0] — 2026-06-09

### Fix: timeout al cargar el ladder SIP on-demand (VOXY-K)
- **Síntoma:** `[flow] ladder on-demand: canceling statement due to statement timeout` al abrir el flujo/traza de algunas llamadas en capturas grandes.
- **Causa:** la query a `packets` (hypertable TimescaleDB, **chunks de 1 h**) filtraba solo por `call_id` **sin acotar `ts`** → sin exclusión de chunks, abría toda la hypertable y excedía el `statement_timeout`.
- **Fix:** se obtiene el rango temporal de la llamada (`start_ts`/`last_ts` de `calls`, indexada por `call_id`) y se acota la consulta con `ts BETWEEN start-5min AND last+1h` → TimescaleDB excluye chunks y solo lee un puñado. Fallback al rango de los mensajes en RAM si la llamada aún no está en `calls`. Aplicado en **`_loadFlowMessages`** (UI `/flow` + análisis RFC) y en **`GET /api/v1/calls/{id}/trace`** (API pública).
- *Primer bug resuelto end-to-end por el flujo Sentry-autopilot → aprobación → fix.*

---

## [2.45.0] — 2026-06-09

### Identidad de la instalación en telemetría (mapeo de cliente para soporte)
- Cada evento de telemetría que llega al Sentry del fabricante queda **mapeado a su instalación**: se adjuntan los tags `hwid`, `customer`, `tier` y `license_valid`, y se fija el *user* de Sentry (`id = HWID`, `username = cliente · hwid`).
- El **HWID es el ancla universal**: existe siempre, con o sin licencia. Con licencia válida el `customer` es el nombre del cliente y el `tier` su plan (`production`/`telco`); sin licencia es `free` (no encontrada) o `invalida`. Así **ningún error queda anónimo** y un ticket de soporte se localiza al instante por HWID o por nombre.
- La identidad se fija al arrancar y se **refresca en cada re-chequeo de licencia** (cada 6 h) por si cambia el estado. **No se envían** IP, hostname ni contenido de llamadas (sigue depurado por el scrubber). Solo telemetría; afecta al panel del fabricante, no al portal del cliente.

---

## [2.44.0] — 2026-06-09

### Selección dinámica de modelos de IA
- El campo de modelo del chat (Settings → AI Chat) deja de ser **texto libre**: ahora se elige del **catálogo real del proveedor**. Botón **"Cargar modelos"** → desplegable poblado en vivo.
- Nuevo `POST /api/ai/models`: consulta el endpoint de listado del proveedor seleccionado — OpenAI `/v1/models`, Anthropic `/v1/models`, Google `/v1beta/models` (filtrado a los que soportan `generateContent`), OpenRouter `/api/v1/models` — con la key configurada. **Server-side**: la key nunca sale al navegador. Filtra a modelos de chat y cachea ~5 min.
- **Fallback robusto:** si el listado falla (key inválida, sin salida a internet on-prem), se conserva el input de texto manual. Así no hay que hardcodear ni perseguir el modelo más nuevo — aparece solo.

---

## [2.43.0] — 2026-06-09

### Avisos unificados en la campana
- Todos los avisos que antes aparecían como **barras sueltas** ahora se consolidan en el **centro de notificaciones (la campana del header)**: cuello/CPU (`bottleneck`), capacidad de tier (`capacity`) y uso del plan gratuito (`freetier`). El sniffer ya estaba ahí.
- El aviso de CPU conserva la **severidad contextual** de v2.42.0: `info` (azul) en catch-up transitorio, `warn`/`crit` si es saturación real con pérdida.
- Las notificaciones llevan acción donde aplica (ej. *Activar licencia*, *Ver planes*). El **overlay de bloqueo** del plan gratuito se conserva (es un modal funcional, no un banner). Solo UI.

---

## [2.42.0] — 2026-06-09

### Leyenda de CPU contextual — no confundir catch-up con falta de recursos
- El aviso preventivo de CPU al límite ahora **distingue** dos situaciones para no inducir a sobre-aprovisionar hardware:
  - **Transitorio (catch-up tras arranque/actualización, sin pérdida):** banner informativo (azul) — *"El portal está procesando datos tras el arranque/actualización; el uso de CPU se normalizará al liberarse los procesos. No es necesario agregar recursos todavía."*
  - **Sostenido / con pérdida real:** el aviso de siempre (ámbar/rojo) — *"Agrega cores…"*.
- Detección en `_sampleBottleneck` vía `_cpuLoadIsWarmup()` (proceso recién arrancado, backfill del working-set en curso, o rollup/parse de fondo activo). El detector expone `transient` en `/api/bottleneck` y `/api/health.capture`; el banner del portal lo traduce (ES/EN).
- Solo UI/observabilidad; la captura no se ve afectada.

---

## [2.41.0] — 2026-06-09

### Menos CPU — guard de concurrencia del rollup del dashboard
- El rollup `call_stats_hourly` se refresca cada 2 min, pero a alto volumen (millones de filas en `calls`) cada agregado tardaba **más** que el intervalo → sin guard se **apilaban** varias ejecuciones concurrentes (se observaron 4 a la vez), saturando los cores con queries paralelas sobre toda la tabla.
- Ahora `refreshStatsRollup` tiene **guard de concurrencia** (`_statsRollupBusy`, igual que el rollup de troncales): una sola ejecución a la vez; si ya hay una en curso, el disparo se omite y el siguiente tick la recoge.
- La captura (sniffer) nunca se ve afectada.

---

## [2.40.1] — 2026-06-09

### Fix — chat de IA en modo claro
- El widget de chat flotante (ventana, input y burbujas de mensaje) usaba variables CSS **inexistentes** (`--bg-secondary`, `--bg-primary`, `--bg-tertiary`, `--border`) que caían siempre a su *fallback* oscuro → el chat se veía oscuro incluso con el **tema claro**. Ahora usa las variables reales del tema (`--bg-surface`, `--bg-surface-2`, `--border-default`, `--text-primary`), por lo que se adapta correctamente a claro/oscuro.
- Solo UI (`index.html`); sin cambios de backend.

---

## [2.40.0] — 2026-06-09

### Menos CPU del portal a alto volumen
- **Anti-deadlock en el upsert de CDRs:** el upsert incremental de `calls` ahora ordena las filas por `call_id` antes de escribir. Dos lotes que tocaban las mismas filas en orden distinto provocaban `[calls] upsert incr: deadlock detected` y reintentos que quemaban CPU; con un orden total estable, todas las transacciones bloquean en el mismo orden.
- **Throttle del full-parse por cap-RAM:** a alto volumen / durante un catch-up de backlog, el working-set excedía el límite de RAM y disparaba un *full-parse* (re-correlación completa) una y otra vez —se observaron dos en 5 s— manteniendo todos los cores al tope. Ahora hay un *cooldown* mínimo entre full-parses por cap-RAM (con hard-cap de seguridad para RAM): da respiro al CPU en lugar de re-correlacionar en bucle.
- La **captura (sniffer) nunca se ve afectada**; solo cambia el comportamiento del portal.

---

## [2.39.0] — 2026-06-09

### Alertas proactivas con IA + API de monitoreo
- **Alertas agénticas:** cuando una troncal entra en **alarma**, el copiloto NOC redacta un diagnóstico breve (causa más probable + acción recomendada) y lo adjunta al webhook como `ai_analysis`. Opcional vía `alerts.ai_summary`, best-effort (si no hay LLM configurado o falla, la alerta sale igual). Se apoya en el monitor proactivo existente (evaluación de salud de troncales cada 60 s, detección de anomalías por baseline, webhooks anti-spam por transición de estado).
- **API de Integración ampliada (monitoreo externo):** nuevo scope `metrics:read` y tres endpoints read-only para NOC/billing externos:
  - `GET /api/v1/health` — liveness + versión + estado de captura.
  - `GET /api/v1/stats` — KPIs globales (ASR/PDD/MOS, top clientes/países/troncales, causas).
  - `GET /api/v1/trunks/health` — salud por troncal/carrier (ASR/NER/ACD/MOS/pérdida/PDD/5xx + razones).
- Portal-only (capture-safe).

---

## [2.38.0] — 2026-06-09

### Arranque (warm-up) ultrarrápido en alto volumen
- La reconstrucción del working-set al arrancar ordenaba los paquetes por `id`, que **no** es la clave de partición de la hypertable. Sobre cientos de millones de filas comprimidas (TimescaleDB columnar) eso forzaba un **Sort de decenas de millones de filas** → arranques de varios minutos.
- Ahora ordena por la clave primaria `(ts, id)` → TimescaleDB usa exclusión de chunks (solo toca los recientes). Medido en un despliegue de **341 M filas**: primera carga útil **~512 s → ~17 s**. Arregla tanto el fast-boot como el backfill.
- La **captura nunca se ve afectada** (el sniffer corre independiente); solo el portal arranca mucho más rápido tras un reinicio/actualización.

---

## [2.37.0] — 2026-06-09

### Copiloto NOC agéntico (tool-calling / ReAct)
- El asistente de IA deja de responder sobre un **resumen estático** y pasa a **investigar en vivo**: usa *tool-calling* (bucle ReAct) para consultar datos reales bajo demanda y **encadenar herramientas** hasta llegar a un diagnóstico.
- **5 herramientas read-only:** panorama/KPIs (`get_overview`), salud de troncales (`get_trunk_health`), búsqueda de CDRs (`search_calls`), detalle de llamada (`get_call_detail`) y escalera SIP (`get_call_flow`).
- Multi-proveedor (OpenAI / Anthropic / Google / OpenRouter), con guardarraíles (solo lectura, tope de iteraciones). **100 % observación:** explica la causa probable y recomienda acciones para el NOC, nunca toca el SBC. Autotest en `GET /api/ai/agent-selftest`.
- Portal-only (capture-safe).

---

## [2.19.6] — 2026-06-04

### UI — re-fix tras revalidación del debugger (TICKET-008/009/010/011)
- **Pantalla stale post-login (008/009/011):** las vistas/header/widget se cargaban ANTES de tener token (fetches → 401 → en blanco) y el login no las re-hidrataba → quedaban stale hasta un refresh manual. Ahora, tras login exitoso, se **re-hidrata recargando con el token ya en localStorage** (el boot corre autenticado → header, vista activa, settings y widget IA correctos). Se preserva el flujo de force_change (sin recarga).
- **TICKET-010 alcance del KPI:** "Total calls" ahora muestra el **total histórico real** (de `/api/cdrs.total`, p.ej. 7.5M) en vez del tamaño del muestreo (~1,000 que contradecía a los millones de CDRs). Los KPIs de calidad (ASR/NER/ACD/MOS) siguen sobre la muestra reciente.
- Portal-only (capture-safe).

---

## [2.19.5] — 2026-06-04

### UI — fixes reales de la auditoría (TICKET-010 + 011); 007/008/009 fueron falsos positivos del harness
- **TICKET-010 (peak concurrent absurdo, 740k):** la concurrencia en `/api/dashboard/timeseries` sumaba los `starts` de la hora pero NO restaba sus `ended` → contaba ~una hora entera de inicios como activos. Ahora = **neto de llamadas abiertas al cierre de la hora** (cumStart−cumEnd, ambos inclusivos) → valor realista a alto volumen (starts≈ends/hora).
- **TICKET-011 (CSP bloqueaba Google Fonts):** se ELIMINA la dependencia de Google Fonts (CDN externo). On-premise/telco no debe depender de un CDN (offline, privacidad, CSP). `--font-sans`/`--font-mono` ya hacen fallback a system-ui/monospace. (NO se aflojó el CSP.)
- **007/008/009 NO eran bugs:** verificado con login real — todos los `/api/*` dan 200 con Bearer, Calls trae datos, el widget IA se revela al cargar settings. Los `401` eran del runner Playwright del audit que no propagó el JWT (el frontend ya inyecta `Authorization: Bearer` en `/api/*`).
- Portal-only (capture-safe).

---

## [2.19.4] — 2026-06-04

### Observabilidad VERIFICABLE sin auth (re-fix de TICKET-002/005/006 tras validación del debugger)
- El debugger rechazó 002/005/006 con razón: el diagnóstico estaba correcto pero **solo en `/api/bottleneck` (con auth) y en el log del portal al cambiar** → no verificable desde donde mira monitoreo/soporte.
- **`/api/health` (PÚBLICO) ahora expone `capture`:** recurso limitante, severidad, captura % global, **drops por capa (SIP/CDR vs RTP)**, **peor worker**, y **por puerto (=capa) con nº de workers y peor recv-Q**, + acción. No expone secretos/versión. Verificable con `curl http://127.0.0.1:3080/api/health`.
- **Re-log periódico:** el `[bottleneck]` se re-loguea cada 5 min mientras haya pérdida (antes solo al cambiar de recurso) → `journalctl -u voxywatch` siempre muestra el cuello actual + acción.
- Portal-only (capture-safe; no reinicia el sniffer).

---

## [2.19.3] — 2026-06-04

### Métricas honestas de captura (TICKET-002 + 005 + 006 del debugger)
- **TICKET-006:** el detector de cuello lee `/proc/net/udp[6]` por SOCKET (= por worker, SO_REUSEPORT) y por PUERTO (= capa): rx_queue + drops del kernel, con el PEOR worker. Un worker saturado se detecta aunque el promedio esté bien.
- **TICKET-002:** drops separados por CAPA (SIP/CDR vs RTP) en el warning y en `/api/bottleneck`. Se acabó el "capturando 100%" cuando hay drops: ahora dice `SIP/CDR OK/PÉRDIDA, RTP OK/PÉRDIDA [global N%]`. Pérdida real de RTP → severidad crítica.
- **TICKET-005:** el cuello nombra el recurso REAL. Clave: con 12/16 cores pegados el idle del sistema es ~25%, así que el viejo `idle<=5` nunca disparaba y caía en "ingest" genérico. Ahora *drops de socket + iowait bajo = workers saturados (CPU/hot-path)* → acción "sube vCPU o reduce costo por paquete; RSS/disco no son la causa". Se distingue recv (más workers) de net (RSS/IRQ).
- Portal-only (capture-safe; no reinicia el sniffer).

---

## [2.19.2] — 2026-06-04

### TICKET-001 — Sin hardcodes: working-set del sniffer derivado del hardware
- Nuevo `_compute_capacity()` (capacity planner) en `hep_sniffer.py`: los límites se DERIVAN de RAM, disco libre y `net.core.rmem_max`, no de constantes fijas.
  - `_DB_QUEUE_MAXSIZE`: ~3% de RAM / item (antes fijo 200k) → C3ntro ~471k; caja de 4 GB ~63k; cap 2M.
  - `_SPOOL_MAX_BYTES`: 10% del disco libre (antes fijo 2 GiB) → C3ntro ~69 GiB de buffer ante caída de BD; piso 1 GiB, techo 100 GiB.
  - `SO_RCVBUF`: pide hasta `net.core.rmem_max` (antes fijo 16 MB) → usa el máximo del SO; avisa si `rmem_max` es bajo.
  - Cap de workers: ya no se capa por debajo de los cores (escala con el host).
- **Expone los valores efectivos** en el log al arrancar (`[capacity] ...`) con el motivo. Un host mayor escala solo; uno chico baja solo. Sin números atados a un cliente.
- No se sube `rmem_max` en el instalador a propósito (host CPU-bound sin swap → un buffer mayor consumiría RAM sin arreglar drops que son por CPU). Sin cambios de captura.

---

## [2.19.1] — 2026-06-04

### Observabilidad del sniffer (TICKET-004 + TICKET-003 del debugger)
- **TICKET-004 (journald suprimía logs):** las stats del sniffer se imprimían cada N PAQUETES por worker (a ~150k pps = cientos de líneas/s/worker → journald suprimía decenas de miles). Ahora se gatean por TIEMPO: máx 1 línea cada 30 s por worker. Logs fiables bajo firehose.
- **TICKET-003 (spool=0KB mentía):** la métrica de spool solo sumaba los spools de la corrida actual. Ahora inventaría TODOS los `voxywatch_spool*` del DATA_DIR (activos + replay + huérfanos) y reporta `spool=NMB(Kf)` real. (Se reclamaron 98.5 GiB de spools huérfanos del 06-03 en el server.)
- Sin cambios de captura (solo logging/métrica). Cambia el sniffer → el update lo reinicia (breve hueco).

---

## [2.19.0] — 2026-06-04

### #7 — Almacén de RTP en ARCHIVOS append-only (audio_storage='files') + parse +46%
- **Sniffer:** nuevo modo `audio_storage='files'` — el RTP se escribe a segmentos append-only por hora/worker `audio/rtp-YYYYMMDDHH-wN-<epoch>.seg` (formato VWB1) en vez de `COPY` a Postgres → sin WAL/MVCC/índice por paquete. Default sigue `'db'` (sin cambio) hasta activarlo. fsync periódico, cierre en shutdown, fallback a spool.
- **Lector dual:** `reconstruct_audio.py`/`generate_pcap.py` leen RTP desde segmentos (glob por ventana del nombre + filtro SSRC) **y** desde `rtp_packets` (BD) → transición transparente. Retención `reliefPurgeOldestSegments` borra `.seg` viejos bajo presión de disco (umbral RTP).
- **parse_hepv3 +46%** (49deb6e, ya validado equivalente): structs precompilados + `unpack_from` → sube el techo de captura del sniffer. Se incluye (se elimina el revert del build).
- Validado: round-trip del formato, lector dual, **paridad e2e (audio desde archivo == desde BD)**. Setting `audio_storage` persistido en el portal.

---

## [2.18.3] — 2026-06-04

### Hardening — correcciones del code-review interno (v2.16.9→v2.18.2)
- **Ventana de audio/PCAP (regresión del fix anti-OOM):** llamadas sin `firstTs` daban ventana 0/0 → audio/PCAP **vacío**; llamadas activas (sin `lastTs`/BYE) daban ventana de ~7 s → PCAP **truncado**. Ahora `_callRtpWindow()` extiende `until` a *ahora* si la llamada está activa, y los scripts aplican la ventana solo si es válida (si no, filtran por SSRC + tope anti-OOM, sin ventana vacía).
- **`correlateIncremental` guard:** cuando el delta es enorme y cae a `rebuildCallMetadata`, ahora **también `upsertCalls`** (antes ese tick no persistía la tabla `calls`).
- **`correlateIncremental`** ahora invalida los MISMOS cachés que el path full (`_labelCache`/`_ipLabelsCache`, no solo dash/cdrs) y **poda `_ssrcToCid`** al borrar una llamada (sin entradas stale ni crecimiento no acotado).
- **Concurrencia del dashboard:** `ended` ahora cuenta por `COALESCE(last_ts, start_ts)` → las llamadas sin `last_ts` ya no inflan `Active Calls/Hour` monotónicamente. Auto-rebuild del rollup (`rollup_ver`→3).
- **Rollup:** el refresh periódico (120 s) espera a que el backfill cree la tabla (`_rollupReady`) → sin error de "relation does not exist" en arranque.
- Validado: paridad full≡incremental sigue exacta (3961≡3961). Sin cambios en el sniffer.

---

## [2.18.2] — 2026-06-04

### RAM — working-set derivado del hardware (sin hardcode, cualquier escala)
- **Medición previa (v2.18.1):** el portal usa ~734 MB RSS / 512 MB heap a working-set completo (250k filas, 88k SIP, 24k llamadas). El `raw` pesa solo 44 MB. El "3.7 GB" de notas viejas quedó obsoleto tras el parse incremental + #6.
- El tope del working-set se basaba en un cap obsoleto de 400 MB (era para la lectura JSONL de un solo string) → daba 250k filas FIJO en cualquier hardware. En cajas chicas (2-4 GB) eso podía saturar.
- Ahora **se deriva del hardware**: `parse_ram_pct%` de la RAM total / costo-por-fila medido (~3 KB), con techo proven-good de 250k (el historial vive en la BD; no hace falta más en RAM) y un piso para hardware muy chico. **Cero cambio en cajas grandes** (C3ntro sigue en 250k); **escala hacia abajo solo** en cajas chicas. Nivel telco, adaptable a cualquier despliegue.

---

## [2.18.1] — 2026-06-04

### Observabilidad — diagnóstico de RAM (sin cambios de comportamiento)
- Nuevo `GET /api/debug/memory` (operador): `process.memoryUsage()` + conteos por estructura (sipMessages, callMetadata, callEvents, sipByCallId, ssrc→cid, rtpStats…) + bytes de `raw` + ventana efectiva. Sin secretos.
- Log conciso `[mem]` por full-parse → leíble por `journalctl` (sin auth) para dimensionar optimizaciones de RAM con datos reales en cualquier hardware. Base para el rediseño de RAM del portal (sin adivinar).

---

## [2.18.0] — 2026-06-04

### Performance — Correlación INCREMENTAL (#6): O(llamadas tocadas) en vez de O(ventana)
- Antes, cada tick de 5 s re-correlacionaba la VENTANA COMPLETA (`rebuildCallMetadata`, hasta 250k mensajes) y re-upserteaba TODAS las llamadas (~20k) — el grueso del CPU constante del portal a alto volumen.
- Ahora `correlateIncremental` recalcula y persiste **solo los call-ids tocados por el delta** del tick, reusando `buildOneCall` (la MISMA fuente de verdad que el rebuild full → sin divergencia). Mantiene `sipByCallId` vivo, un mapa `ssrc→call_id` (para RTP/RTCP tardío), y asignación de referencia atómica por llamada (lecturas nunca ven estado a medias).
- **Guarda:** si el delta toca una fracción enorme de la ventana → cae al rebuild full. Fallback full ante purga o límite de RAM (sin cambios). Flag interno `VW_INCREMENTAL` (default ON).
- **Validado por test de PARIDAD** (`tools/parity_test.sh`) contra dataset real de C3ntro en staging: full-vs-incremental **byte-idéntico** (3961 ≡ 3961 llamadas). Deploy solo-portal (capture-safe). Sin cambios en el sniffer.

---

## [2.17.2] — 2026-06-04

### Fixed — OOM por reconstrucción de audio / PCAP (causa de 2 OOM-kills de ~20 GB)
- **`generate_pcap.py`** consultaba el RTP **sin ninguna ventana de tiempo** y hacía `fetchall()` sobre TODO `rtp_packets` (cientos de GB) → el cliente intentaba materializarlo en RAM y disparaba el OOM-killer. Ahora recibe la ventana de la llamada (argv 5/6 desde el portal) y filtra por la columna de partición `ts` (exclusión de chunks).
- **`reconstruct_audio.py`** hacía `fetchall()` sobre toda la ventana (y en auto-descubrimiento de SSRC guardaba todos los streams) → mismo riesgo.
- **Ambos** ahora usan **cursor del lado servidor** (named, `itersize=50k`) que streamea en lotes en vez de materializar todo el resultado en el cliente, + un **tope duro de 4M paquetes** en RAM (≈1.4 GB worst-case; aborta con aviso si se excede). `to_regclass` decide rtp_packets sin try/except sobre el cursor.
- **`server.js`**: pasa la ventana de tiempo también a PCAP; ambos spawns con `timeout: 240s` y `maxBuffer: 16 MB`.
- Resultado: la reconstrucción/PCAP de cualquier llamada queda acotada en RAM independientemente del tamaño de la captura. G.711/G.722/G.729/etc. sin regresión.

---

## [2.17.1] — 2026-06-03

### Fixed — Rollup del dashboard: excluir scanners (consistencia con las gráficas previas)
- Las gráficas anteriores (vía `/api/cdrs`) filtraban `is_scanner`; el rollup de 2.17.0 los incluía → inflaba volumen y sesgaba ASR/NER. Ahora `call_stats_hourly` excluye scanners (`is_scanner = true`).
- **Auto-rebuild por versión de semántica:** `meta.rollup_ver`. Al cambiar el cálculo, el portal hace TRUNCATE + backfill completo en el siguiente arranque (por el update normal), sin tocar la BD a mano.

---

## [2.17.0] — 2026-06-03

### Performance (sniffer — parseo HEP +46%)
- **`parse_hepv3` optimizado: +46% throughput por worker** (104.8k → 153.5k pkt/s/worker en benchmark local). El loop TLV hacía 3 `struct.unpack` separados + slices por CADA chunk (~34 unpack/paquete); ahora lee el header del chunk (vendor_id/type/len) en UNA pasada con `struct.Struct("!HHH").unpack_from`, y usa structs precompilados para puertos/timestamps/capture-id. Mismo output (validado). Sube el techo de captura del sniffer (~1.36M → ~2M pps con 13 workers) → más headroom ante ráfagas.
- Benchmark reproducible en `tools/bench_sniffer_parse.py`.
- **Nota de deploy:** cambia `hep_sniffer.py` → el update reinicia el sniffer (breve hueco de captura). Desplegar en VENTANA DE MANTENIMIENTO.

---

## [2.17.0] — 2026-06-03

### Fixed — Dashboard: las gráficas de tiempo mostraban "solo la última hora"
- **Causa:** el dashboard bajaba las 20.000 llamadas más recientes (`/api/cdrs?limit=20000`) y calculaba TODAS las series en el navegador. A alto volumen (p.ej. C3ntro), 20k llamadas = unos minutos de tráfico → solo el bucket más reciente se llenaba; el resto quedaba vacío. Los datos SÍ estaban en la tabla `calls` (historia completa), pero las gráficas no los leían.
- **Solución (escala sin saturar al escritor):** tabla rollup `call_stats_hourly` (1 fila/hora: total/answered/user_err/failed/ended) + endpoint `/api/dashboard/timeseries`. Las gráficas **Call Volume**, **ASR/NER Trend** y **Active Calls/Hour** ahora salen de la historia completa (24h/7d/30d), no de un muestreo reciente.
- **Mantenimiento:** backfill al arrancar (completo solo la 1ª vez; luego solo desde el último bucket) + refresh de las últimas ~4 h cada 2 min. Lecturas O(buckets) (cientos de filas/mes) → instantáneas, sin escanear el firehose ni competir con la captura.
- **Concurrencia por hora:** calculada como suma acumulada de inicios−fines (exacta, no muestreo).
- Frontend con fallback: si el endpoint no responde (servidor previo), las gráficas vuelven al cálculo desde el muestreo (sin romperse). Schema v5.

---

## [2.16.9] — 2026-06-03

### Added (fundación de codec dinámico + AMR/AMR-WB/GSM/G.723.1 — SIN VALIDAR)
- **Resolución de codec por payload-type + hint de la SDP.** El server pasa a `reconstruct_audio.py` el codec negociado (`codec_answer`); el reconstructor resuelve por PT estático (0/8/9/18/3/4) o, para PT dinámicos (96-127), por ese hint. Base para todos los códecs dinámicos.
- **AMR-NB y AMR-WB (RFC 4867, modo octet-aligned):** depaquetización RTP → formato de almacenamiento .amr → ffmpeg. **NO VALIDADO con tráfico real** (no hay encoder local ni tráfico AMR en C3ntro); pendiente de validar con pcap real. No maneja bandwidth-efficient (bit-packed) aún.
- **GSM-FR (PT3) y G.723.1 (PT4):** frame-based, decodificados con ffmpeg.
- **No-regresión:** G.711/G.722/G.729 (lo que usa C3ntro) intactos — son aditivos; AMR/Opus solo corren si la llamada los usa.

---

## [2.16.8] — 2026-06-03

### Added (reconstrucción de audio G.729 / G.729A / G.729B)
- **`reconstruct_audio.py` ahora soporta G.729 (PT 18)** — ~12% de las llamadas en C3ntro. G.729 no usa el modelo de "1 byte por tick" (sirve a G.711/G.722): es por FRAMES de 10 bytes (10 ms). Nueva ruta dedicada: concatena los frames en orden de timestamp y decodifica con `ffmpeg -f g729`. **Annex B (VAD/CNG/DTX):** descarta el frame SID de 2 bytes (al final del talkspurt) para no desalinear el demuxer; el silencio DTX queda como gap. Validado en llamada real (6408 frames → 64.08 s, 8 kHz estéreo correcto).

---

## [2.16.7] — 2026-06-03

### Fixed (audio reconstruido sonaba pésimo en llamadas G.711)
- **`reconstruct_audio.py` ahora decodifica según el payload-type real del RTP.** Antes decodificaba TODO como G.722 (`ffmpeg -f g722`), así que las llamadas **G.711 µ-law (PCMU, PT 0) y A-law (PCMA, PT 8)** —la mayoría en telefonía— se oían como ruido/garabato. Ahora mapea PT→códec (0→mulaw, 8→alaw, 9→g722) en la conversión a WAV y en la mezcla estéreo/mono, y selecciona los streams por esos PTs. Sin cambios en el sniffer.

---

## [2.16.6] — 2026-06-03

### Changed
- **Detalle de llamada: la sección de audio (reproductor) se movió al fondo, debajo del diagrama de flujo SIP** (a pedido). Orden ahora: métricas → flujo SIP (trazas) → audio.

---

## [2.16.5] — 2026-06-03

### Fixed (búsqueda de Calls daba resultados incorrectos)
- **Búsqueda de Calls acelerada con índice GIN de trigramas (pg_trgm).** La búsqueda hacía `LIKE '%term%'` sobre 7 columnas sin índice → **seq-scan de ~18 s** sobre millones de filas. A esa latencia las respuestas llegaban fuera de orden (cada tecla dispara una query) y se mostraban resultados que no correspondían a lo buscado. Ahora: una sola expresión indexable + índice `idx_calls_search` (pg_trgm, creado CONCURRENTLY en background al boot) → búsqueda en **~ms** (validado: 18 s → 0.6 ms). Además, si la query de búsqueda falla, ya NO se cae a la lista sin filtrar (devuelve vacío + flag) para no mostrar resultados engañosos.

---

## [2.16.4] — 2026-06-03

### Fixed (CDR de llamadas largas marcadas "incompletas/HUÉRFANO" con 0.0s)
- **`upsertCalls` ahora FUSIONA en vez de sobrescribir.** Una llamada larga puede correlacionarse en 2 fragmentos cuando el INVITE y el BYE están separados por más que la ventana de SIP en RAM (a alto volumen, pocos segundos): el fragmento del BYE llegaba como "huérfano" y PISABA al registro completo, dejando el CDR con duración 0.0s y badge HUÉRFANO aunque la llamada fuera real y completa (ej. una de 49s a Sinch). Ahora el ON CONFLICT toma `start_ts=LEAST`, `last_ts=GREATEST`, prefiere el fragmento NO-huérfano (o el de arranque más temprano), y recalcula firstTs/lastTs/duration del tramo unido. Validado en staging. Aplica a llamadas nuevas; las ya guardadas se corrigen al re-correlacionarse.

---

## [2.16.3] — 2026-06-03

### Changed
- **Calls: eliminado el botón "Cargar más"/"Load more"** del listado, a pedido. La lista muestra la primera página (filtros y búsqueda siguen acotando server-side).

---

## [2.16.2] — 2026-06-03

### Fixed (HOTFIX — portal en blanco/sin datos)
- **`app.js`: `window.tr` llamado durante la construcción del objeto de traducciones (bloque `es`, `lic_err_conn`)** → `Uncaught TypeError: window.tr is not a function` al cargar → **abortaba toda la inicialización del frontend** (tabs muertos, no aparecía login, ningún dato cargaba; el backend estaba sano). Introducido en commit 6b3c4033. Fix: string estático `'✗ Error de conexión'` (como en los otros 4 idiomas), sin llamar a `window.tr` en tiempo de carga. Detectado y reproducido con Chrome headless.

---

## [2.16.1] — 2026-06-03

### Changed (updates sin interrumpir la captura — "captura sagrada")
- **`install.sh`: el auto-updater ya NO reinicia el sniffer en updates de solo-portal.** Antes, cada `voxywatch-update` hacía `systemctl stop voxywatch voxywatch-sniffer` → el sniffer caía durante toda la instalación (a alto tráfico, millones de paquetes perdidos por update). Ahora compara `hep_sniffer.py` nuevo vs instalado (`cmp`): si **no cambió**, deja el sniffer corriendo y solo reinicia el portal → **captura sin interrupción (0 drops por el update)**. Si `hep_sniffer.py` cambió, sí reinicia el sniffer (necesario). Esto vuelve seguro el camino normal de actualización por línea de comando en servidores en producción con tráfico alto.

---

## [2.16.0] — 2026-06-03

### Added (arranque rápido — el portal usable en segundos tras un restart)
- **Boot en 2 fases.** Antes, al reiniciar, el portal cargaba el working-set completo (~250k filas: parse + correlación) ANTES de marcar el warm-up como listo → **pantalla de carga por ~4-5 min** a alto tráfico (160k pps). Ahora el arranque carga primero una **ventana reciente pequeña (`_FAST_BOOT_ROWS=40000`)**, marca el portal **usable en ~15 s**, y completa el working-set (250k) en **BACKGROUND** (con el lock `isParsing`, sin solaparse con el timer ni con purgas).
- `getPackets(settings, maxRowsOverride)` y `parseCapture({ maxRows })` aceptan un tope opcional de filas para la fase rápida. La captura NO se ve afectada (la hace el sniffer); el historial completo sigue sirviéndose desde la tabla `calls`. El dashboard de KPIs muestra la ventana reciente de inmediato y se completa al terminar el backfill.

---

## [2.15.0] — 2026-06-03

### Added (aviso preventivo de CPU al límite)
- **Nuevo aviso temprano de CPU saturado, ANTES de perder tráfico.** Hasta v2.14.1 el detector de cuello solo avisaba ante degradación REAL (drops > 0, spool creciendo o RAM en swap), así que un CPU clavado al 100% **sin** pérdidas todavía **no mostraba nada**. Ahora, si el CPU está saturado de forma **sostenida** (`idle ≤ 5%` o `loadavg > nº de cores` durante ≥2 muestras, ~30 s), aunque la captura siga al 100%, sale un banner amarillo: *"CPU al límite — la captura sigue completa, pero agrega cores antes de empezar a perder tráfico."*
- **Separación de niveles:** el camino crítico (ya perdiendo tráfico) tiene prioridad y mantiene su mensaje rojo; el preventivo es `warn` (amarillo) y solo aparece cuando NO hay un cuello real en curso. El campo `preventive` se expone en `/api/bottleneck`.
- **Anti-falsos-positivos:** exige ≥2 muestras seguidas de saturación (no dispara por un blip puntual de 1 intervalo). Mensaje bilingüe es/en (pt/fr/de heredan inglés).

---

## [2.14.2] — 2026-06-03

### Changed
- **Ventana de correlación en RAM acotada → menos churn de CPU en pico.** El parse incremental re-correlacionaba en RAM todo el set creciente cada tick (medido ~941k SIP). Como el historial COMPLETO ya se sirve desde `calls` (DB), la RAM solo necesita la ventana reciente: `effectiveMaxRows` se topa en **250k** filas → el parse procesa ≤250–375k/tick (antes ~941k, ~2.5× menos churn) y baja la RAM. **No limita capacidad** (captura/CDR viven en la BD, sin tope); no es un knob de cliente — es el working-set interno auto-gestionado. `total_calls` sigue siendo el historial real (estimación O(1) desde la BD).

---

## [2.14.1] — 2026-06-03

### Fixed
- **Detector de cuello: sin falsos positivos + recurso más específico.** Antes podía marcar *"cuello: write (drop 0)"* por un blip transitorio de recv-Q sin pérdida real. Ahora **solo alerta ante degradación REAL** (drops > 0, spool creciendo, o RAM en swap) y el bucket genérico "write" se separa en **disco / cpu / recv / net / ingest** (incluye `softirq` para red). Banner del GUI con i18n es/en para los recursos nuevos.

---

## [2.14.0] — 2026-06-03

### Changed (#1 de fondo — servir desde la BD SIN re-saturarla)
- **`total_calls` (en `/api/stats` y `/api/dashboard`) sale del historial REAL de `calls` (~2.7M), no de la ventana en RAM (~60k).** Usa una **estimación O(1)** vía `pg_class.reltuples` (7 ms, instantánea, la mantiene ANALYZE) en vez de `count(*)` (que sobre 2.6M tarda ~1 s y, repetido, vuelve a cargar la BD). Se expone también `total_calls_window` (las de la ventana RAM).
- **Decisión de diseño:** el dashboard de KPIs (ASR/ACD/MOS/histogramas) **se mantiene calculado en RAM** (ventana reciente, cacheado 10 s, SIN tocar la BD). Medí el agregado equivalente sobre `calls` en ~**7 s** → hacerlo por request **re-saturaría la BD y ahogaría al escritor del sniffer** (el problema original del reporte de escalabilidad). Un dashboard operativo es recienre-céntrico; la lista/CDR/flow completos ya salen de `calls`.

### Pendiente de fondo (en-proceso, sin carga de BD; requiere validación en deploy)
- **Correlación verdaderamente incremental:** hoy el parse re-correlaciona TODO el set en RAM cada tick (medido hasta ~941k SIP) — ya **no bloquea** (yields 2.11.0 + cursor 2.13.0) pero **quema CPU en pico**. Correlacionar solo las llamadas tocadas por el delta (no re-correr todo) es la optimización restante; cambia el output de correlación → se hará con validación en deploy (ya hay SSH de solo lectura).

---

## [2.13.0] — 2026-06-03

### Fixed
- **Freeze del portal — se elimina el bloque del fetch de DB (continúa el fix de 2.11.0).** El parse cargaba los paquetes con un solo `pool.query` de cientos de miles de filas → node-postgres **deserializaba TODO el result-set de forma síncrona** → bloqueo de varios segundos del event loop (el ~3.4 s residual / 20–30 s en pico). Ahora `getPackets` y el fetch del **parse incremental** traen por **cursor en tandas de 20k**, **cediendo el event loop** entre cada una. Con esto + los yields de correlación de 2.11.0, el parse (full e incremental) **ya no congela** el portal. Cursor validado contra la BD real de C3ntro (TimescaleDB).

### Pendiente (el redISeño de fondo, informado por diagnóstico SSH)
- El parse incremental **acumula en RAM y re-correlaciona todo** el set creciente cada tick (medido: hasta ~941k SIP en RAM); ya no **bloquea** (cede el hilo) pero **quema CPU en pico**. El fix de fondo (correlación verdaderamente incremental + servir dashboard/stats desde `calls`, como ya hacen calls/cdrs/flow) reduce ese costo — se hará validando contra datos reales (ya hay acceso SSH de solo lectura).

---

## [2.12.0] — 2026-06-03

### Changed
- **#8 (parcial, seguro) — `synchronous_commit = off` en la conexión del sniffer.** La captura es efímera y de altísimo volumen; no necesita esperar el fsync del WAL en cada commit. Recorta los stalls del write-path (el escritor drena más rápido bajo carga). Por sesión, no cambia la config global de Postgres; en un crash se pierde a lo sumo la última fracción de segundo de inserts (aceptable: SIP/CDR se re-capturan, RTP es efímero). Complementa los bloques RTP de v2.9.0.
- **#6 — Retención SOLO por % de disco (se elimina la purga por nº de filas).** El path por `capture_max_lines` se atascaba con un chunk legacy gigante (logueaba "ABORTADO" sin recortar) y contradecía el modelo solo-disco de v2.6.0. Quitado: el disco es el único control (suelta lo más viejo por prioridad RTP→trazas→CDR). `capture_max_lines` queda como no-op por compatibilidad.

### Pendientes que requieren validación con tráfico/BD reales (no se sueltan a ciegas)
- **#8 audio-a-archivos real / `rtp_packets` UNLOGGED:** bajaría aún más el I/O (saltar WAL), pero la interacción de UNLOGGED con la compresión nativa de TimescaleDB y el rediseño a archivos (FDs/índice) **no son verificables sin un Postgres+tráfico reales** → se harán con validación. Los bloques (2.9.0) + async-commit (este release) ya dan el grueso del alivio.
- **#5 RTCP en puerto propio:** ya es posible HOY sin código — apuntar el RTCP del SBC a un **puerto extra** (`hep_extra_udp_ports`, p.ej. 9910); el sniffer no descarta RTCP (el shed solo toca RTP), así queda fuera del firehose. Es deployment, no código.
- **RAM ~3.7 GB del portal:** rediseño del parse incremental (servir stats/dashboard desde `calls`, no retener sipMessages) — **ya NO es urgente** (el freeze, que era el síntoma grave, se eliminó en 2.11.0); 3.7 GB ≈ 12% de 30 GB.

---

## [2.11.2] — 2026-06-03

### Added
- **Banner de cuello de botella en el GUI (i18n).** El detector de v2.8.0 ya emitía warnings en log; ahora también se muestran en el portal: un banner superior lee `GET /api/bottleneck` cada 20 s y, si hay degradación, muestra *"⚠️ Capturando X% del tráfico — cuello: <recurso>. <acción>"* traducido **del lado cliente** (es/en), con color ámbar (warn) o rojo (critical). Cierra el pedido del reporte: "exponer los warnings también en el GUI, no solo en logs".

---

## [2.11.1] — 2026-06-03

### Changed
- **Los knobs internos de rendimiento ya no se muestran al cliente.** La tarjeta "Performance & Capture" del Settings (`capture_max_lines`, `parse_ram_pct`, `parse_max_rows`) queda **oculta** — son parámetros internos que el software auto-gestiona (defaults `auto`), no algo que el cliente deba tunear. Los inputs siguen en el DOM (ocultos) con sus valores auto para no romper el guardado. El recurso limitante se reporta solo vía `/api/bottleneck` ("qué subir"). `hep_workers` ya no tenía UI. (Directiva del reporte: reemplazar knobs por auto-gestión.)

---

## [2.11.0] — 2026-06-03

### Fixed
- **🔴 Se acabaron los congelamientos de 20–30 s del portal (el peor síntoma de UX).** `parseCapture`/`rebuildCallMetadata` corrían **síncronos** en el hilo de Node → al correlacionar ~548k SIP **bloqueaban el event loop** y NADA respondía (`/api/health` llegó a **30,177 ms**; el GUI se veía "todo en 0s" y solo funcionaba lo client-side). Ahora `accumulatePackets` y `rebuildCallMetadata` **ceden el event loop por tandas** (`_forEachYield`, cada 8192 elementos): el portal **responde durante la correlación**. Además se hace **swap atómico** de `callMetadata`/`sipByCallId`/`_callsSorted` al final → las lecturas ven los datos **previos completos** hasta el cambio, nunca un estado a medio construir. Resultados idénticos (misma lógica, solo cede el hilo). El parse inicial corre antes de armar el timer y los re-parses están protegidos por el lock `isParsing` → sin concurrencia.

### Notas
- Esto **elimina la necesidad** del knob `parse_max_rows` como mitigación del freeze (el usuario ya no tiene que tocarlo). Próximo paso (en curso): ocultar los knobs internos del Settings y servir Calls/stats 100% desde la tabla `calls` para reducir también la RAM del working-set.

---

## [2.10.1] — 2026-06-03

### Fixed (i18n — nada hardcodeado)
- **La pantalla de carga (warm-up) ya es bilingüe (default inglés).** Estaba toda en español hardcodeado (incluido el texto que venía del server). Ahora usa **inglés por defecto** y **español** si el usuario lo eligió (`vw_lang` en localStorage), traduciendo por código de fase (no por el texto del backend). Es la única UI servida antes de cargar el SPA.

### Notas
- **Cambiar contraseña ya está disponible para los 3 roles** (admin/operator/viewer): el endpoint `/api/auth/change-password` usa `requireAuth` (cualquier rol) y el botón de usuario del header se muestra para todos. Solo no se veía por el bug del warm-up corregido en 2.10.0. (Sin cambios de código.)
- Los strings del detector de cuello (`/api/bottleneck`) exponen un **código de recurso** (`cpu`/`disk`/`recv`/`ram`) + números → un futuro banner en el GUI debe traducirlos del lado cliente (la acción/detalle en texto son para logs).

---

## [2.10.0] — 2026-06-03

### Fixed
- **El indicador de usuario logueado + botón de cerrar sesión (arriba a la derecha) ya aparece.** Los elementos existían pero el interceptor de warm-up (v2.0.3) respondía **503 a `/api/auth/me`** durante el parse inicial, y `checkAuth` ante eso **borraba el token** y mostraba el login → el header de usuario nunca se activaba (y se perdía la sesión). Ahora los endpoints de **auth pasan durante el warm-up** (no dependen del parse) y `checkAuth` **no borra el token por un 503 transitorio** (solo en 401 real; reintenta si el portal está calentando). El header muestra el usuario activo y el botón Salir / Sign out.

### Changed (i18n)
- **Labels del header con i18n (default inglés).** El botón de cuenta tenía `title="Cuenta"` hardcodeado y el de logout/limpiar-búsqueda textos fijos → ahora con `data-i18n-title` y claves es/en (`btn_account_title`, `btn_logout`, `btn_clear_search`); el aria del bloque de plan gratuito quedó en inglés por defecto. (El resto de labels visibles ya tenían i18n; los placeholders en español eran solo fallback y se traducen en runtime.)

---

## [2.9.1] — 2026-06-03

### Changed
- **El flujo SIP (`/api/calls/:id/flow`) ahora funciona para TODO el historial (#2, P0).** Antes, una llamada fuera de la ventana en RAM (~41k) devolvía el ladder vacío (`trace_unavailable`); ahora se **reconstruye on-demand desde `packets`** por `call_id` (índice `idx_pkt_call_id` → O(log n), sin cargar nada a RAM). El detalle de cualquiera de las 1.3M+ llamadas de `calls` muestra su ladder SIP. Se conserva el fast-path de RAM para las recientes. El parseo replica exactamente la forma del mensaje que arma `accumulatePackets` (method/status/SDP/raw).

### Pendiente (#2, requiere validación)
- Reducir la RAM steady-state del portal (~3.7 GB): hoy el parse incremental retiene los mensajes SIP en RAM (`sipByCallId`) para el fast-path. Bajarlo implica rediseñar el parse incremental para que no dependa de RAM — toca todas las rutas de lectura, por eso conviene validarlo con datos reales antes de soltarlo.

---

## [2.9.0] — 2026-06-03

### Changed
- **🔴 RTP en bloques: recorta el I/O de disco que era el cuello (reporte maestro, P0).** El RTP se guardaba **fila-por-paquete** en `rtp_packets` → 5–10× el I/O necesario (WAL + heap + índice + MVCC por CADA paquete) → disco saturado (iowait 33%, util 87%) a ~334k pps. Ahora el sniffer **agrupa hasta 256 paquetes RTP en UNA fila** (blob enmarcado `VWB1` + `[1B len_ip][ip][2B len][rtp]…`), recortando ese overhead ~256× — sin file descriptors, sin archivos sueltos, reutilizando reconstrucción/retención/spool ya probados.
  - `reconstruct_audio.py` y `generate_pcap.py` **desenmarcan** los blobs (y siguen leyendo paquetes sueltos legados/spool sin cambios → migración transparente, el RTP viejo en `packets`/`rtp_packets` se sigue leyendo). El contenido RTP (SSRC/seq/ts/media) es **exacto** → audio íntegro; en PCAP los puertos de un blob son los de su primer paquete (aproximado, suficiente para diagnóstico).
  - Validado con round-trip frame→deframe (incluye media que contiene el magic, paquete suelto legado, y blob truncado sin crash).

> Nota de diseño: se eligió **agregación en Postgres** sobre archivos crudos por SSRC porque a ~6,400 streams concurrentes los archivos-por-SSRC reventarían los file descriptors y un archivo gigante por hora exigiría un índice — un sistema mucho mayor y, sin tráfico real para validar, más riesgoso. Los bloques logran el grueso del recorte de I/O (el overhead por-fila) de forma segura. Si tras esto el disco sigue siendo el cuello (lo dirá el detector de v2.8.0), el siguiente paso es archivos/tiering.

---

## [2.8.0] — 2026-06-03

### Added
- **Detección de cuello de botella en runtime + warnings accionables (reporte maestro, P1).** El portal muestrea cada 15 s las firmas del sistema (`/proc/stat` idle/iowait, `/proc/net/snmp` InDatagrams/RcvbufErrors, `/proc/net/udp` recv-Q de los puertos HEP, crecimiento del spool, `/proc/meminfo`), calcula el **% de tráfico realmente capturado** y clasifica el **recurso limitante** (CPU / disco / recepción / RAM) con una **acción concreta**. Se expone en `GET /api/bottleneck` (`{resource, severity, detail, action, capture_pct}`) y en `/api/diagnostics`, y emite un warning en log/telemetría al degradarse — p.ej. *"⚠️ Capturando 48% — cuello: disk (iowait 33%, spool creciendo). Sube IOPS/throughput del disco o activa audio-a-archivos."* Cumple el principio: el software dice **qué recurso subir**, sin hardcodes.

### Fixed
- **`hep_workers='auto'` ya no sobre-suscribe.** Antes tomaba TODOS los cores (cap 16) → 19 procesos en 16 cores, loadavg 25, peor rendimiento. Ahora `'auto'` usa **~75% de los núcleos** (deja headroom para PostgreSQL + portal + OS); un entero explícito se respeta tal cual. Si el cuello sigue siendo CPU, el detector lo dice.

---

## [2.7.2] — 2026-06-03

### Changed
- **Retención de audio: el RTP crudo se purga primero; los WAV quedan protegidos.** Antes el RTP crudo (firehose desechable) y los WAV (artefacto de audio que se quiere conservar) se purgaban en el **mismo** umbral (audio 60%), por lo que la presión de disco podía borrar WAVs valiosos junto con RTP basura. Ahora: el **RTP crudo se sacrifica primero** (umbral de audio, 60% — soltar un chunk libera muchísimo), las **trazas SIP** después (70%), y los **WAV se limpian solo bajo presión alta** (umbral CDR, 85%), junto con los CDRs huérfanos. Los WAV son la copia de largo plazo del audio (y, una vez purgado su RTP, la única) → se conservan más. **Sin settings nuevos**, reusa los umbrales que ya existen.

---

## [2.7.1] — 2026-06-03

### Fixed
- **En modo grabación ya NO se descarta audio.** La degradación adaptativa de RTP (v2.6.4) descartaba RTP también con `recording_enabled` activo → tiraba audio que sí se recibía. Ahora el shed **solo** aplica en modo métricas (grabación apagada), donde el RTP se descarta igual (ahí adelantarlo ahorra parse). Con grabación activa (default) se guarda **todo** el RTP que el host alcance a recibir.

### Notas (modelo de audio confirmado)
- **Guardar todo el audio:** el RTP capturado vive en `rtp_packets` y el WAV por llamada se reconstruye on-demand (`reconstruct_audio.py`); ambos (RTP + WAV) se **borran por el % de disco configurado en Settings** (umbral de audio 60% → trazas 70% → CDR 85%, lo más viejo primero). No hay tope por días: tú gobiernas cuánto audio se conserva con los %.
- **Capacidad en pico:** a ~335k pps el host de 8 cores no parsea todo el firehose; lo no capturado se pierde en el kernel (no por decisión del programa). Subir cores acerca a 0 pérdida — el sizing queda para después, según pediste.

---

## [2.7.0] — 2026-06-03

### Changed
- **`/api/cdrs` sirve desde la tabla `calls` (historial completo), no desde RAM (P1, #4).** Antes la lista de CDR salía de `callMetadata` en RAM (solo la ventana del último parse), por lo que el GUI mostraba datos parciales/desfasados y se perdían tras un reinicio. Ahora lee de la tabla `calls` (767k+) con los mismos filtros y keyset que `/api/calls` (status/búsqueda/tiempo/cursor), cacheando el conteo total 30 s. Respuesta **compatible** (`{total, cdrs, next}`) → el GUI no se rompe; el `total` ahora refleja el historial real y los CDR son persistentes. Fallback a RAM si la BD no está lista.

### Pendiente (P1, próximas versiones)
- Paginación/búsqueda server-side en la vista CDR del frontend para **navegar todo** el historial (hoy carga la página reciente de 20k y filtra client-side).
- Reducir la RAM del portal (~3.7 GB): que `parseCapture` no cargue todo a memoria y que `/api/stats` y `/api/dashboard` salgan de la tabla `calls`/continuous aggregates.

---

## [2.6.5] — 2026-06-03

### Fixed
- **AutoPurge ya recorta el chunk legacy (la tabla `packets` dejaba de crecer sin control).** El guard de 2.0.4 ("no borrar más del 34% del total") confundía el wipe catastrófico (incidente: `capture_max_lines=50000` → quedaban 2,300 filas) con una purga legítima del chunk viejo gigante. Ahora el guard usa un **piso de filas** (`minKeepRows` = ½ del target): bloquea el wipe a casi-cero pero **permite** dropear el chunk legacy cuando aún queda un volumen razonable (caso C3ntro: deja ~9M con target 10M). El crecimiento de `packets` queda acotado de nuevo.
- **GUI ya no se queda vacío (401) tras cada update.** El secreto JWT se regeneraba ante *cualquier* fallo de lectura, invalidando todas las sesiones en cada reinicio. Ahora: si el archivo existe se usa **siempre** (nunca se regenera por un fallo transitorio; si no se puede leer, aborta el arranque para reintentar en vez de invalidar), se genera **solo** en el primer arranque, y admite override estable por `VOXYWATCH_JWT_SECRET`.

### Changed
- **Buffer de recepción 8 MB → 16 MB** (aprovecha el `rmem_max=32M` del instalador). Más colchón para ráfagas; ayuda a que el RTCP de bajo volumen sobreviva en el socket compartido con el firehose RTP.
- **Corrección de la promesa de v2.6.4 sobre RTCP.** El RTCP **no** queda "siempre completo" cuando comparte el socket del RTP (puerto 9062): el kernel descarta ~indiscriminadamente al saturarse, antes de que la app pueda discriminar. Garantizado bajo pico = **SIP/CDR** (puerto 9060 propio); el RTCP es **best-effort** (las métricas de calidad quedan más espaciadas, no ausentes). El RTCP 100% garantizado requiere un **stream/puerto HEP dedicado desde la fuente** (decisión del emisor/SBC, no de VoxyWatch) — es un punto de sizing, no un knob de config.

---

## [2.6.4] — 2026-06-03

### Added
- **Degradación adaptativa de RTP — captura de alto tráfico sin configuración por cliente.** A volúmenes extremos de RTP (p.ej. ~335k pps), ni el multiproceso (`'auto'`) cubre el parseo en Python (límite del GIL: ~22–30k pps por core). En vez de pedir al operador que active `rtcp_only`/`recording_off` (apagaría el audio para todos), el sniffer ahora **mide los descartes UDP del kernel** (`RcvbufErrors` en `/proc/net/snmp`, ~1×/s) y, **solo cuando el kernel está perdiendo paquetes**, descarta automáticamente una fracción del **RTP crudo** ANTES de parsearlo (jamás SIP/RTCP) para drenar el socket. Conserva 1 de cada N (N sube ×2 bajo presión hasta 1/32, baja a la mitad y vuelve a 1/1 al cesar los drops). Resultado: **SIP (CDR) y RTCP (calidad: MOS/jitter/pérdida) siempre completos**, y el audio se captura íntegro en operación normal y de forma best-effort (muestreado) solo bajo pico — todo automático, cero config. Overhead nulo cuando no hay presión (el chequeo barato de RTP solo corre con descarte activo). Nuevas métricas en STATS: `RTP_shed` y `keep 1/N`.

> Nota: a escalas donde ni así alcanza, las palancas siguen disponibles (multiproceso ya por default; `rtcp_only_sources`/`recording_enabled` para quien quiera forzar). La degradación adaptativa garantiza que, pase lo que pase, la señalización y la calidad nunca se sacrifican.

---

## [2.6.3] — 2026-06-03

### Fixed
- **🔴 El multiproceso del sniffer venía apagado de fábrica → ~93% de pérdida de RTP en pico.** El supervisor `SO_REUSEPORT` (P2) estaba implementado pero `hep_workers` tenía **default = 1**, así que un solo core hacía el `recvfrom` y a ~335k pps el socket se desbordaba. Ahora el **default es `'auto'`** (= núcleos, cap 16) en el portal **y** en el sniffer (incluido el merge de `load_settings`, para que instalaciones existentes sin el campo también lo activen al reiniciar). Reparte el recv entre cores y sube el techo de pps. _Nota: a 335k pps ni 8 workers bastan solos → combinar con `rtcp_only_sources`/`recording_enabled=false` en fuentes sin audio (~50× menos pps)._
- **AutoPurge no podía recortar con chunks grandes.** `chunk_time_interval` de `packets` y `rtp_packets` baja de **6 h → 1 h** (vía `create_hypertable` + `set_chunk_time_interval` idempotente para upgrades): más chunks en la ventana de retención ⇒ el chunk más viejo es una fracción pequeña ⇒ el guard de seguridad (máx ~34% por purga) ya puede dropearlo. (Aplica a chunks NUEVOS; los chunks gigantes ya existentes envejecen por presión de disco.)
- **`/api/health` devolvía 503 durante el parse inicial** (disparaba falsas alertas en monitores/orquestadores). Ahora responde **200 `{ok:true, warming:true}`** mientras calienta: el proceso está vivo, solo cargando histórico.

---

## [2.6.2] — 2026-06-03

### Fixed (auditoría — cabos sueltos)
- **`/api/stats` mostraba `total_rtp = 0`.** El conteo de RTP venía de `rtpPackets[]` en RAM, que está vacío desde el desacople de RTP (P1.1). Ahora `total_rtp` y `total_packets` salen del conteo **real** de las hypertables (`rtp_packets` y `packets + rtp_packets`), cacheado en `_captureStats` (O(1), sin coste por request).

### Removed
- **Continuous aggregate muerto `pkt_stats_1m`.** Se creaba en el esquema (refrescaba cada minuto escaneando `packets`) pero el portal nunca lo consultaba. Se elimina del esquema con `DROP MATERIALIZED VIEW IF EXISTS` (idempotente → también lo quita, junto con su política, en instalaciones que lo tuvieran).

---

## [2.6.1] — 2026-06-03

### Fixed (auditoría de código)
- **Métricas de captura subestimadas tras separar el RTP (regresión de 2.4.0).** `capture_size`, `capture_lines` y el estado en `/api/status` medían solo la tabla `packets` y dejaban fuera `rtp_packets` (≈99% del volumen). Ahora suman **ambas** hypertables (filas y bytes), y el "último paquete" de `/api/status` toma el ts más reciente de cualquiera de las dos. El % de disco (df) ya era correcto; esto corrige solo lo que se muestra.
- **Purga de CDR bajo presión de disco podía borrar historial valioso en vano.** La versión previa borraba los CDR más viejos en bucle hasta bajar del umbral, pero la tabla `calls` es chica y `DELETE` no libera disco al instante → podía vaciar CDRs útiles sin aliviar el disco. Ahora solo borra **CDRs huérfanos** (aquellos cuyo SIP ya fue dropeado de `packets`), acotando la tabla sin destruir CDRs que aún tienen su ladder SIP.
- **`reliefPurgeOldestAudios` llamaba `df` (síncrono) por cada archivo** → posible bloqueo del event-loop con muchos WAV. Ahora re-chequea el disco cada 25 borrados.

---

## [2.6.0] — 2026-06-03

### Changed
- **Retención simplificada: ahora es ÚNICAMENTE por % de disco. Se eliminó por completo el tope de edad por días.** Tras revisarlo, los "días" no aportaban (dependen del volumen y del tamaño del disco) y solo agregaban confusión. El único control de retención es el umbral de disco por tipo: cuando el disco cruza el umbral se borra lo **más viejo** de ese tipo, por prioridad **RTP/audio (60%) → trazas SIP (70%) → CDR (85%)**.
  - Eliminados los settings `purge_audio_keep_days`, `purge_traces_keep_days`, `purge_cdr_keep_days` y sus campos en la UI (cada tarjeta de purga deja solo el umbral de disco).
  - Al arrancar, el portal **quita cualquier política de retención nativa por tiempo** que hubiera quedado de versiones previas (`stripNativeRetention`), para que únicamente mande el disco.
  - El esquema no crea políticas de retención por tiempo.

> Validado contra TimescaleDB: el esquema no crea políticas de retención; el portal elimina al arrancar cualquier política nativa heredada (queda solo el control por disco).

---

## [2.5.0] — 2026-06-03

### Changed
- **Rediseño de la política de retención: el % de disco es el control real; los "días" pasan a ser un tope de edad OPCIONAL (apagado por default).** Antes había dos mecanismos solapados y los días se usaban de forma confusa (y, tras la separación de RTP, redundante con la retención nativa): además, "días" no sirve para administrar disco porque depende del volumen de llamadas y del tamaño del disco. Ahora:
  - **Control por disco (siempre activo):** cuando el disco cruza el umbral de un tipo, se borra lo **más viejo** de ese tipo (sin importar la edad), por prioridad **RTP/audio (60%) → trazas SIP (70%) → CDR (85%)**. El RTP, lo más pesado y menos valioso, se sacrifica primero. Esto **siempre** acota el disco (antes, si todo era más nuevo que N días, el disco podía llenarse igual).
  - **Tope de edad por días = opcional, default 0 (apagado).** Solo para cumplimiento legal/privacidad ("no conservar más de N días"). Para hypertables lo aplica la retención nativa de TimescaleDB; para la tabla `calls` (no es hypertable) lo aplica el portal. `0` lo desactiva de verdad (quita la política nativa).
  - El esquema ya **no impone** un tope de edad por default; el portal reconcilia la retención nativa desde settings al arrancar y al guardar cambios.
  - UI: los campos de días aceptan `0` y se renombraron a "Tope de edad opcional (0 = sin tope)".

> Nota de upgrade: los clientes que ya tenían días configurados (p.ej. 7/30/90) los conservan (más el nuevo alivio por disco, que los hace más seguros). Para adoptar el modelo "solo disco", poner los días en `0`.

> Validado contra TimescaleDB: sin tope de edad por default; reconcile agrega/quita la política nativa según los días (0 = quitada); el alivio por disco dropea el chunk más viejo primero (RTP→trazas) y borra los CDR más viejos primero.

---

## [2.4.0] — 2026-06-03

### Added
- **RTP en hypertable propio (`rtp_packets`) → retención diferenciada real (Fase 3.2).** El RTP crudo (≈99% del volumen, solo útil a corto plazo para audio/PCAP on-demand) ahora vive en su **propia hypertable**, separado de `packets` (SIP/RTCP/LOG). Esto permite **retener el RTP poco (p.ej. 7 días) y el SIP/CDR mucho más (30+ días)** — algo imposible con una sola tabla, porque `drop_chunks` borra por TIEMPO, no por tipo de dato. El esquema crea `rtp_packets` con compresión + retención corta; `packets` pasa a retención larga.
  - **Ingesta dual en el sniffer:** el escritor rutea cada paquete a su tabla (RTP → `rtp_packets`, resto → `packets`) con COPY independiente por tabla. El **spool de resiliencia (Fase 1b) ahora es por tabla** (`voxywatch_spool.csv` + `voxywatch_spool.rtp.csv`): si la BD cae, cada flujo se vuelca a su spool y se reproduce a su tabla al recuperarse, sin pérdida ni duplicados (lo ya escrito en una tabla no se re-spoolea si la otra falla).
  - **Retención reconciliada desde settings al arrancar:** el portal fija la retención nativa de cada tabla desde `purge_traces_keep_days` (señalización) y `purge_audio_keep_days` (RTP), para que la diferenciación aplique también en upgrades. Bajo presión de disco, el umbral de audio también dropea chunks de `rtp_packets`.
  - **Lecturas de audio/PCAP transparentes a la migración:** `reconstruct_audio.py` y `generate_pcap.py` hacen `UNION` de `rtp_packets` + el RTP legado en `packets`, filtrando por `ts` (columna de partición → exclusión de chunks, clave a escala TB). En upgrades, el RTP viejo se queda en `packets` y envejece por su retención mientras el nuevo entra en `rtp_packets` — **sin backfill** (el RTP es efímero).

> Validado contra TimescaleDB: ruteo correcto (RTP→rtp_packets, SIP/RTCP→packets, 0 cruce); con la BD caída se spoolearon 80 señalización + 240 RTP con **0 pérdida**, replay a la tabla correcta al reanudar; `reconstruct_audio.py` auto-descubrió SSRC de **ambas** tablas y generó stereo/mono; reconciliación de retención cambia ambas políticas nativas.

### Notas de roadmap (Fase 3)
- Diferido a P3.3: grabaciones a archivo/S3 + tiered storage de chunks viejos a object storage (opt-in, requiere infra del cliente).

---

## [2.3.0] — 2026-06-03

### Added
- **Modo de grabación de audio (`recording_enabled`) → el mayor recorte de almacenamiento (Fase 3).** Con la grabación **desactivada**, el sniffer **deja de almacenar el RTP crudo** (conserva RTCP/RTCPXR/SIP): como el RTP es ~99% del volumen, esto reduce los datos y los pps **~50× o más**. La calidad de las llamadas (MOS, jitter, pérdida) sigue saliendo de **RTCP**; lo único que se pierde es la reconstrucción de audio. Reusa el mecanismo de filtrado por fuente (Fix5) aplicándolo a todas. **Default `true` (graba) — sin cambios para quien usa audio.** Ideal para NOCs que solo necesitan señalización + calidad. Aplica al reiniciar el sniffer.

### Fixed
- **Retención del CDR ahora acota la tabla persistente `calls` (antes crecía sin límite).** Desde la Fase 1 la vista Calls/CDR se sirve de la tabla `calls`, pero la purga por antigüedad (`purge_cdr_keep_days`) solo borraba el mapa **en RAM** — la tabla en PostgreSQL **nunca se limpiaba** y crecía indefinidamente. Ahora `purgeOldCdrs` hace `DELETE FROM calls WHERE start_ts < cutoff` (además del mapa en RAM), respetando `purge_cdr_keep_days` cuando el disco cruza `purge_cdr_threshold_pct`.

> Validado contra TimescaleDB: con grabación OFF se enviaron 800 RTP → **0 almacenados** (800 `RTP_filtrados`), SIP/RTCP intactos; con grabación ON el RTP vuelve a guardarse. Retención de CDR: borra los CDRs > N días de la tabla `calls` y conserva los recientes (límite exacto en el día N).

### Notas de roadmap (Fase 3)
- Diferido a una versión posterior: **RTP en hypertable propio** (para retener RTP más corto que el SIP **aun grabando**) y **grabaciones a archivo/S3 + tiered storage** (requiere infra de object storage del cliente → opt-in).

---

## [2.2.0] — 2026-06-03

### Added
- **Sniffer multiproceso con `SO_REUSEPORT` (Fase 2) → sube el techo de pps por encima de un solo núcleo.** Hasta ahora la captura corría en un proceso (un hilo lector bajo el GIL), con un techo de throughput limitado a un core. Con el ajuste `hep_workers` > 1 (o `"auto"`), el sniffer arranca **N procesos de captura** que comparten el mismo puerto vía `SO_REUSEPORT`; el **kernel reparte los datagramas** entre workers por 4-tupla (mismo flujo origen→destino siempre al mismo worker). Cada worker tiene su propio hilo escritor, conexión a PostgreSQL y **spool propio** (`voxywatch_spool.wN.csv`). La correlación de llamadas la sigue haciendo el portal desde la BD, así que repartir paquetes entre procesos es seguro.
  - **Supervisor** ligero: forkea los workers, **reenvía señales** para cierre limpio (cada worker drena su cola/spool antes de salir) y **respawnea** (con backoff anti crash-loop) cualquier worker que muera inesperadamente.
  - **Default `hep_workers: 1` (monoproceso)** — comportamiento idéntico al actual; el multiproceso es **opt-in** para clientes de alto volumen. Cap de 16 workers.
  - Configurable desde el portal (Settings → `hep_workers`) o en `voxywatch_settings.json`; aplica al reiniciar el sniffer.
- **Réplica de lectura (opt-in) para el portal.** Si se define `VOXYWATCH_DB_REPLICA_DSN` (env del servicio, o `install.sh --replica-dsn`), las **lecturas** de UI/métricas/CDR del portal se enrutan a una **réplica de streaming** que el cliente configura aparte; las **escrituras** (sniffer) y el **parse/ingesta** siguen en el primario. Sin la variable, lee del primario igual que antes. Tolera lag de replicación (frescura sacrificable antes que la captura).

> Validado: con `hep_workers=2` el kernel repartió la carga entre ambos workers (cada uno cruzó 1000 paquetes), **0 `queue_drop`**, todas las filas persistidas; apagado limpio (supervisor + workers, socket liberado) y respawn correcto al matar un worker. El camino monoproceso por defecto quedó intacto.

---

## [2.1.2] — 2026-06-03

### Fixed
- **La ingesta ya no pierde paquetes por atascos de la BD (spool a disco, Fase 1b).** Antes, si la BD se atrasaba/caía, la cola del sniffer se desbordaba y se descartaban paquetes (`queue_drop`). Ahora el escritor, ante una caída de conexión, **vuelca a un archivo append-only en disco** (`voxywatch_spool.csv`, mismo formato CSV que `COPY`) en vez de tirar; cuando la BD se recupera, **reproduce (replay) el spool y lo borra**. Atasco transitorio = **lag, no pérdida**.
  - El escritor siempre drena (a BD o a disco) → la cola no se queda llena → el lector deja de descartar. Detección de caída con flag + probe cada 5 s; replay oportunista en idle y al arrancar (recupera un spool dejado por un crash).
  - Cap de disco (2 GB) como **último recurso**: solo si se excede se vuelve a contar `queue_drop`. Errores de datos (lote venenoso) se descartan, no se spoolean.
  - Stats del sniffer muestran `spooled`, `replayed`, tamaño del spool y `db_down`.
  - Validado: con la BD detenida se spoolearon 200 paquetes con **0 drops**; al reanudar, los 200 se reprodujeron y el spool quedó vacío.

---

## [2.1.1] — 2026-06-03

### Changed
- **El portal deja de cargar RTP crudo (desacople, Fase 1.1) → independiente del volumen de media.** `getPackets`/parse incremental ahora excluyen `protocol_id = 4` (RTP, ~99% del volumen); con el nuevo índice parcial `idx_pkt_nonrtp_id` la carga es O(maxRows) sin importar cuánto RTP haya. La misma ventana de memoria ahora cubre **muchísimo más historial de señalización** y baja drásticamente CPU/RAM del portal por tick. La calidad global sale de **RTCP**; el jitter/loss fino y el audio se calculan **on-demand por call_id**.

### Fixed
- **Audio y PCAP sin RTP en RAM.** `reconstruct_audio.py` consulta el RTP por la **ventana de tiempo** de la llamada y **auto-descubre los SSRC** (top-2 por paquetes, priorizando G.722) — ya no depende de que el portal le pase los SSRC. El audio (stereo/mono) se sirve por **nombre determinístico** → funciona también para llamadas **históricas** (fuera de la ventana en RAM). Reconstruct/pcap obtienen la llamada de RAM **o** de la tabla `calls`.

> Validado end-to-end: el portal carga SIP/RTCP y reporta `rtp:0`; `reconstruct_audio.py` auto-descubre SSRC y genera stereo/mono con ffmpeg.

---

## [2.1.0] — 2026-06-03

### Added
- **CDR persistente + lista de Calls servida desde la BD (escalabilidad, Fase 1).** Nueva tabla **`calls`** (1 fila por llamada, columnas indexadas + JSONB con el objeto completo) y **continuous aggregate `pkt_stats_1m`** (rollups por minuto para el dashboard). El portal correla SIP en RAM como hasta ahora y hace **upsert por lote** del resultado a `calls`; la vista Calls se sirve con **keyset pagination** (sin `COUNT`/`OFFSET`) y **filtros server-side** (All/Completed/Rejected, tiempo, búsqueda) → instantánea a cualquier escala y con **historial persistente** más allá de la ventana en RAM, con botón "cargar más".
  - Detalle (`/api/calls/:id`) y ladder (`/api/calls/:id/flow`) caen a la tabla `calls` para llamadas históricas (el trace SIP completo queda disponible para llamadas dentro de la ventana cargada; se ampliará con el desacople de RTP).
  - Validado end-to-end contra TimescaleDB real (parse→correlación→upsert→keyset, filtros y paginación).

> Siguiente (v2.1.x): el portal dejará de cargar RTP crudo (99% del volumen) → calidad por RTCP + on-demand; spool de ingesta a disco; multiproceso.

---

## [2.0.8] — 2026-06-03

### Fixed
- **🔴 El portal ya no provoca pérdida de paquetes en la captura (incidente C3ntro).** Bajo uso normal, `/api/status` hacía `COUNT(*) + MAX(ts_sec)` (full seq-scan sobre el hypertable de 49 GB) en cada poll de la UI; al no haber caché/single-flight/timeout se apilaban (14+), saturaban el I/O de Postgres y **ahogaban al escritor COPY del sniffer**, cuya cola se desbordaba y tiraba ~50% de los paquetes (INVITEs y RTP). Fixes (Fase 0 del rediseño de escalabilidad):
  - `/api/status`: filas vía `approximate_row_count` (O(1)) y último timestamp vía `ORDER BY ts DESC LIMIT 1` (índice PK), con **caché 10 s + single-flight** (20 polls concurrentes → 1 sola consulta).
  - **Pool de lectura separado y acotado** (`max 4`, `statement_timeout 5 s`) para las consultas de UI/métricas → no pueden apilarse ni robar I/O sostenido a la ingesta (el sniffer usa su propia conexión).
  - `getCaptureRowCount()` (autoPurge/purga) y el `COUNT(*)` previo a los TRUNCATE de data-wipe → `approximate_row_count`.
  - El parse ya no hace `COUNT(*)`: carga siempre los últimos `maxRows` (`ORDER BY id DESC LIMIT` + reverse), acotando memoria sin escanear.

> Primera fase de un rediseño de escalabilidad por etapas (tabla `calls`/CDR dedicada, RTP solo por call_id, agregados continuos, spool de ingesta, multiproceso) para escalar a TB.

---

## [2.0.7] — 2026-06-02

### Added
- **Disposición SIP precisa en el badge del preview de Calls.** En vez del `call_result` crudo, cada llamada muestra su resultado real con reason-phrase: `200 OK`, `Active`, `486 Busy Here`, `603 Declined`, `403 Forbidden`, `404 Not Found`, `503 Service Unavailable`, `302 Moved Temporarily`, etc. Casos especiales tratados como un experto SIP: **Not Answered** (CANCEL tras 180/183), **Cancelled** (CANCEL sin timbrar), **No Answer** (timbró y timeout), **Ignored** (INVITE sin respuesta), **In Progress** (solo 100 Trying), **Partial (mid-call)** (BYE sin INVITE). Los retos 401/407 no se marcan como fallo si luego hay éxito. `call_result` se mantiene intacto (filtros/dashboard).
- `fail_reason` ahora usa la reason-phrase real (ej. "404 Not Found" en vez de "404 404").

### Fixed
- **i18n: el portal vuelve a ser 100% inglés por defecto y respeta el cambio de idioma.** Se eliminaron decenas de strings en español hardcodeados que no pasaban por el sistema de traducción (badge "VIVO", encabezados "Origen/Destino" del flujo SIP, "Sin datos", botones de reinicio/guardado/borrado, login, gestión de usuarios, data-wipe, diagnósticos, tooltips, etc.). Ahora todos usan `window.tr()` / `data-i18n`, con traducción en inglés y español.
- Formato de fecha/hora ya no forzaba `es-MX`: se adapta al idioma activo del portal.

---

## [2.0.6] — 2026-06-02

### Added
- **Filtro "Rejected" en la vista de Calls.** Junto a las pestañas **All** y **Completed** se añade **Rejected**:
  - **Completed** = llamadas con **INVITE + BYE** (`call_result` `answered`). Las de solo-BYE (sin INVITE) ya no cuentan como completadas.
  - **Rejected** = INVITE con una **respuesta final ≠ 200 OK** (4xx/5xx/6xx, busy 486, cancelled 487).
  - **All** = todas las llamadas (sin filtro).
  - Etiqueta `filter_rejected` traducida en los 5 idiomas.

---

## [2.0.5] — 2026-06-02

### Fixed
- **🔴 Throughput del sniffer: ~86% de pérdida de RTP bajo carga → desacople recv/insert.** El loop hacía `recvfrom → parse → insert en Postgres` **síncrono en el mismo hilo**; mientras esperaba cada `commit` no drenaba el socket UDP (techo ~11k pps, independiente del hardware). Ahora el **hilo lector solo drena el socket y encola** (cola acotada de 200k con backpressure → drop contado), y un **hilo escritor** vuelca con **`COPY`** (FORMAT csv, flush por 2000 filas o 200 ms). Sube el techo de ingesta muy por encima de 11k pps. Reconexión/retry y shutdown con drenado del lote final preservados.

### Added
- **Toggle "solo-RTCP" por fuente** (`rtcp_only_sources`, en Settings → Performance & Capture). Lista de IPs/nombres de fuente separados por coma, o `*` para todas: el sniffer **descarta el RTP crudo** de esas fuentes conservando RTCP/RTCPXR/SIP → recorta ~50× el ritmo de paquetes cuando no se necesita grabación de audio.
- **Tuning de kernel desde el instalador** (`/etc/sysctl.d/99-voxywatch.conf`): `net.core.rmem_max=32M`, `rmem_default=16M`, `netdev_max_backlog=10000`. El sniffer ya pedía `SO_RCVBUF` de 8 MB pero el kernel lo recortaba a 416 KB. Ayuda con ráfagas (necesario, no suficiente solo).
- Stats del sniffer ahora muestran salud del pipeline de ingesta: profundidad de cola, filas COPYadas, `queue_drop` y RTP filtrados.

---

## [2.0.4] — 2026-06-02

### Fixed
- **🔴 AutoPurge ya no puede borrar el histórico de golpe.** El límite por `capture_max_lines` llamaba a `purgeOldCaptures()`, que dropea el **chunk más viejo completo** (TimescaleDB, granularidad 6 h) ignorando el porcentaje. Si el histórico quedó en pocos chunks grandes (típico tras migrar de 1.2.x), un solo drop podía borrar casi todo (incidente C3ntro: ~2M → 2.3k filas en un arranque). Ahora un **guard de seguridad** cuenta cuántas filas eliminaría el drop y **aborta si supera ~1/3 del total** en una sola purga automática, dejando una alerta en el log en vez de borrar. Las purgas manuales (Settings) y el alivio por presión de disco no cambian.
- **Update no deja servicios caídos por solape.** Un `install.sh` manual y el `voxywatch-update.timer` corriendo casi a la vez se pisaban (uno hacía `systemctl stop` mientras el otro ya había arrancado; el segundo `install` del binario en uso fallaba y abortaba antes de re-arrancar). Ahora `install.sh` toma un **lock (`flock`)**: el segundo run sale limpio en vez de colisionar.
- **`install.sh` apto para one-liner / binario en uso.** El binario se instala a un temporal y se renombra (`mv` atómico) → no más `File exists` / `Text file busy` al reemplazarlo en caliente. Los prompts solo se piden si hay terminal real (`tty_ok`), eliminando el error `/dev/tty: No such device` en modo no-interactivo (timer/ssh sin tty).
- **Arranque robusto:** tras el update, `install.sh` **verifica que el portal y el sniffer queden `active`** (reintenta una vez y avisa dónde mirar si no).

### Changed
- El log de purga ya no muestra un "keep N%" engañoso (ese porcentaje no se aplicaba al drop por chunk).

---

## [2.0.3] — 2026-06-02

### Fixed
- **Arranque ~35 min → segundos (regresión v2.0.2)** — la correlación SIP→llamadas en `rebuildCallMetadata()` escalaba como O(llamadas × paquetes): por cada llamada re-escaneaba los ~628k paquetes RTP (detección NAT), todos los reportes RTCP y los `arrivalTimes` de cada SSRC. Ahora se precalculan índices **una sola vez** (src-IPs por SSRC, set de call-ids RTCP, `arrivalTimes` ordenados con conteo por *binary search*) → coste ~lineal. Resultados idénticos, validados con 20k casos aleatorios.

### Added
- **Pantalla de carga (warm-up)** — el portal abre el puerto 3080 de inmediato y, mientras corre el parse/correlación inicial, sirve una página "Cargando histórico…" con fase en vivo y barra de progreso (polling a `/api/boot-status`), en vez de quedar inaccesible o mostrar datos vacíos. Recarga sola al terminar. La captura de tráfico (sniffer) nunca se interrumpe.
- **`parse_max_rows`** — nuevo setting (UI en Settings → Performance) que fija un tope **absoluto** de paquetes a cargar al inicio, independiente de la RAM total (0 = auto). Útil en hosts con mucha RAM donde la heurística por `% RAM` carga de más.
- **`GET /api/boot-status`** — endpoint público con la fase y el progreso del arranque.

### Changed
- **Arranque no bloqueante** — `startHttpServer()` corre antes de `bootstrap()`; el parse inicial ocurre en segundo plano. `GET /api/stats` expone `warming_up` y el resto de `/api/*` responde `503` durante el warm-up.
- **Log de carga más claro** — el mensaje de `parseCapture` ya no dice "80% de RAM" de forma engañosa; reporta el límite efectivo real (`parse_max_rows` o `parse_ram_pct` + cap de string de Node).

---

## [1.2.19] — 2026-05-27

### Added
- **Dashboard — toggle Cliente / Proveedor** — la tabla de detalle ahora tiene dos botones para cambiar entre vista por IP/label de origen (cliente) y vista por IP/label de destino (proveedor/carrier); búsqueda y sort funcionan en ambos modos
- **Diagnostics — monitor live CPU y RAM** — nueva tarjeta "Resources" con barras animadas que actualiza cada 4 s mientras el tab está abierto; colores verde/ámbar/rojo según umbral; se detiene al cerrar settings
- **Diagnostics — botón de Update** — fila "Update" en la sección Runtime: muestra versión disponible con botón "Actualizar" que abre el modal existente, o "✓ Al día" en verde
- **HEP Capture — etiquetas inline** — la columna Label de la tabla de fuentes activas es ahora un campo editable; blur o Enter guarda en `/api/ip-labels` con confirmación visual

### Changed
- **Auto-update manual** — eliminados los timers automáticos de check (60 s y 24 h); `GET /api/version/latest` dispara el check en cada llamada; el badge solo aparece cuando el admin abre Diagnostics
- **Settings — inputs numéricos sin flechas** — eliminados los spinners de todos los `<input type="number">` en settings (Chrome, Firefox, Safari)

### Fixed
- **SIP flow — flows largos cortados** — `.sip-svg-wrap` tenía `overflow-y:hidden` y `max-height:360px` fijos; cambiado a `overflow-y:auto` y `max-height:clamp(360px,60vh,720px)` para que flows con muchos mensajes sean scrolleables sin cortar el diagrama

---

## [1.2.18] — 2026-05-27

### Fixed
- **SIP flow diagram — RTCP-as-JSON noise** — Asterisk `res_hep_rtcp.so` sends RTCP statistics as JSON inside HEP packets; these were appearing as raw JSON rows in the SIP sequence diagram. The `/api/calls/:id/flow` endpoint now filters to only include messages with a valid SIP method or status code, so INVITE/1xx/200/BYE/ACK display cleanly. RTCP data continues to be stored and used for MOS/jitter/CDR quality metrics.

---

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
