# First installation: from a new server to your first call

Start here: an LLM, AI subscription or MCP is not required for capture, statistics or reports.

1. [Check prerequisites](#1-check-prerequisites).
2. [Choose your capture method](#2-choose-your-capture-method).
3. [Install and sign in](#3-install-and-sign-in).
4. [Complete the minimum configuration](#4-complete-the-minimum-configuration).
5. [Verify your first result](#5-verify-your-first-result).
6. [Prepare for everyday operation](#6-prepare-for-everyday-operation).

## 1. Check prerequisites

Use a supported Linux server with administrator/root access. Current platforms:

| Linux | Architecture |
|---|---|
| Debian 12 or 13 | x86_64 or ARM64 |
| Ubuntu 22.04 or 24.04 LTS | x86_64 or ARM64 |
| Amazon Linux 2023 | x86_64 or ARM64 |
| Rocky Linux 10.2 (from VoxyWatch 4.7.3) | x86_64 only; Rocky ARM64 is not supported |

A dedicated server or VM is recommended. Before sharing a host, review services,
ports and resources; do not disable other services. Other platforms need compatibility review.

Have the server address, capture source, internal SBC addresses, external trunks
and permission to inspect/record traffic ready. Allow outbound HTTPS to download
the installer, signed release and required packages. Keep system time synchronized.
Allow portal HTTPS from your management network and only the capture traffic you
actually use; ask your network administrator to apply host/cloud firewall rules.

Size CPU, RAM and disk for call rate, history, recording and transcription. Check
**Settings → Diagnostics** with representative traffic; agree sizing before full load.
Installation success is not a capacity guarantee. See [platform/network details](PLATFORM_AND_CAPTURE_VALIDATION.md).

## 2. Choose your capture method

| Method | Choose it when | What it provides and its limits |
|---|---|---|
| HEP | Your SBC or capture agent exports HEP | Original signaling and any exported media. Signaling alone does not provide audio; RTP must be exported and correlated. |
| SIPREC | Your SBC provides recording sessions | Supplied session metadata and recording media. It cannot recreate original SIP messages or establish original-call ASR, NER or PDD from metadata alone. |
| Passive Mirror Capture (Sniffer) | You can mirror the monitored interface | Only packets visible on the selected capture interface. It cannot decode encrypted SIP or media merely because packets arrive. |

Select your method under **Settings → Capture Sources → HEP / SIPREC / Sniffer**.
Configure the sender/mirror separately: VoxyWatch never controls the SBC, switch or firewall.
Start with one capture path; duplicate copies can complicate validation.
For SIPREC, check the advertised media address and negotiated recording-port range.
For a mirror, select the receiving interface, not just the management interface.
Follow the [capture validation guide](PLATFORM_AND_CAPTURE_VALIDATION.md) or
[mirror guide](PASSIVE_MIRROR_CAPTURE.md) for method-specific network requirements.

## 3. Install and sign in

On the supported host, with `curl` and `sudo` available, run the official command:

```bash
curl -fsSL https://raw.githubusercontent.com/VoxyWatch/publish/main/install.sh | sudo bash
```

When already logged in as root, use `bash` instead of `sudo bash`.
The installer verifies the signed release and displays progress; wait for its success
message. Timing depends on the host/downloads. Follow prompts shown by your version.
On failure, retain the diagnostic-log location and error ID for support; never disable signature checks.

Open the **Web portal** HTTPS address printed at the end. Initial private
certificates require trusting the installation's root certificate on your client,
or configuring a trusted certificate/hostname in **Settings → Web Access**.
Follow the [HTTPS guide](HTTPS_CONFIGURATION.md); do not disable certificate
verification or assume an arbitrary DNS name is covered by the certificate.

**Initial credentials:** username `admin`, password `voxywatch` on fresh installs.
Change the password at first sign-in before using protected functionality.
Reinstalling/updating preserves existing users and passwords; it is not a password
reset. For administrator recovery, consult `sudo voxywatch user --help` and the
[CLI reference](CLI_REFERENCE.md). Keep management access restricted.

## 4. Complete the minimum configuration

Open **Settings → Getting started** as an administrator. Its checklist reflects
saved configuration and observed sources, not a live end-to-end acceptance test.
Some setup items concern optional notifications; they do not prevent capture.

| Priority | Configure | Expected result |
|---|---|---|
| Required | **Settings → Capture Sources** and the external sender/mirror | The intended traffic reaches the enabled capture method. |
| Required for correct attribution | **Configuration → IP Directory** | Your own SBC/device endpoints have recognizable names, including ports where needed. |
| Required for trunk statistics | **Configuration → Trunks** | External carrier rules match observed endpoints/ports/prefixes; resolve duplicate-rule errors. |
| Recommended | **Settings → Data** (Advanced if hidden) | Review separate retention/disk thresholds before collecting recordings and history. |
| Optional | **Settings → Notifications** plus recipient profile | Configure SMTP/Telegram and use its test; saving does not prove delivery. |
| Optional | **Settings → LLM**, transcription, MCP and SNMP | Enable only what you need, with appropriate credentials, privacy and cost controls. |

Do not invent prefixes or label a carrier as your own SBC; see [catalog imports](#trunk-catalog-imports).
Capture/statistics/reports do not require AI. Record only authorized calls.

## 5. Verify your first result

Make an authorized, identifiable test call through the monitored path, answer it,
speak briefly if recording is permitted, and hang up. Note its time and time zone.
In **Calls** or **CDR Base**, choose that time range and clear unrelated filters.
Check the call's participants, timestamps, result and trunk/IP names.
With original signaling, inspect the call flow; with SIPREC, inspect the supplied
recording-session evidence instead of expecting the original signaling exchange.

If audio is expected, confirm media availability on that same call, reconstruct
and play it. Transcription additionally needs usable audio and its own enabled
provider/settings. A completed call or active service alone proves neither.

| Observation | What to check next |
|---|---|
| Portal does not open | Printed URL, service state, DNS/routing, HTTPS trust and firewall; do not bypass TLS checks. |
| Service running, no calls | Actual sender destination, capture method/interface, source restrictions, time range and filters. A listening port is not reception evidence. |
| Calls visible, names missing | Internal IP Directory vs external Trunks, observed ports/prefixes and catalog warnings. |
| Calls visible, no audio | Exported/recorded RTP, capture policy, matching media evidence, codec availability and retention. |
| No ASR/PDD with SIPREC alone | Expected coverage limit: original-call signaling is required for those metrics. |
| Notifications configured, none received | Run the channel test and check recipient profile/preferences; configuration is not delivery evidence. |

Read-only local checks: `sudo voxywatch status`, `sudo voxywatch capture status`,
and `sudo voxywatch doctor`. Use each command's `--help` for its coverage.
Configuration, service health, reception and first-call verification are separate; unknown is not a healthy zero.

## 6. Prepare for everyday operation

Review **Settings → Data** retention and **Settings → Diagnostics** resource usage
under representative traffic. Recordings and transcripts need separate privacy
and storage decisions. Review licensing in **Settings → License**; the free tier
does not require buying a key to begin. Share the displayed HWID only when needed
for a license; [plans and trial licenses](https://voxywatch.com/pricing/).

Updates are administrator-initiated: use the update controls at the top of Settings
or `sudo voxywatch update --help`. Plan a maintenance window and retain an approved
server backup/snapshot beforehand. `sudo voxywatch config export` covers supported
initial-setup settings only; it is not a complete server backup and omits secrets.
After updating, check the installed version, access and another test call.

For help, email [support@voxywatch.com](mailto:support@voxywatch.com) or use
[WhatsApp](https://wa.me/525592217665). Include installed version, Linux/architecture,
capture method, exact symptom, expected result, time/time zone and a redacted
screenshot or relevant log excerpt using `sudo voxywatch logs --help`.
Never include passwords, API tokens, private keys, raw customer audio or transcripts.
Review files before sharing; send call identifiers only through approved support channels. [CLI help](CLI_REFERENCE.md).

## Other setup channels: CLI and MCP

Run `sudo voxywatch setup status`, then `sudo voxywatch setup validate --stdin < setup.json` before applying reviewed
input with `sudo voxywatch setup apply --stdin --confirm APPLY_SETUP < setup.json`.
Example `setup.json` (replace these documentation-only addresses with your own):
```json
{
  "trunks": [{"name":"Example carrier","direction":"both","ips":["198.51.100.20"]}],
  "ip_labels": {"192.0.2.10":"Example SBC"}
}
```
Apply restarts only the portal unless `--no-restart` is specified; plan for a brief
portal interruption. It does not restart capture. See [CLI_REFERENCE.md](CLI_REFERENCE.md).
Setup merges supported settings/trunks/IP labels; no catalog erasure, secrets or capture-listener changes. Legacy aliases remain supported.

MCP is optional and initially disabled. Follow [MCP_SERVER.md](MCP_SERVER.md) and the
[AI setup guide](AI_VOXYWATCH_CONFIGURATION_ASSISTANT.md). `get_setup_status` reads setup;
`configure_initial_setup` requires separately enabled configuration access,
`mcp:read` plus `mcp:configure`, a reviewed dry run and explicit `APPLY_SETUP`.
Never give an AI assistant your portal password or a secret to put into setup JSON.

## Trunk catalog imports

In **Configuration → Trunks**, download the current import template and review the
combined-catalog preview before applying. CSV/JSON exports include the saved catalog.
Names merge case-insensitively; omitted existing rows remain. Shared IPs require
distinguishable endpoint/port/prefix rules. Fix flagged duplicates; do not remove
them blindly. If Apply loses its response, inspect the saved catalog before retrying.
Voice endpoints use IP addresses/CIDRs, not DNS names (default port5060).
Registration rules use type `registration`, empty `ips`/`prefixes`, and
`registration_field` (`aor_domain`, `registrar` or `realm`) with its observed value.
Domain wildcard `*.example.net` matches subdomains, not `example.net`; realms are
exact and case-sensitive, without wildcards. A voice DNS name is not a registration rule.
