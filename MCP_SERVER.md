# VoxyWatch MCP Gateway

> Security boundary (v3.57.2): tool results redact phone numbers, display names,
> Call-IDs, signaling lines and IP addresses unless the token has `mcp:sensitive`.
> Opaque Call-ID references remain usable by later tool calls. When a custom LLM
> credential already exists, changing its base URL through MCP requires local
> credential approval so a remote setup caller cannot redirect that secret.

VoxyWatch exposes live NOC evidence to ChatGPT, Claude, Codex and other MCP
clients. It also offers an optional, separately gated initial-setup tool. The
gateway never controls the SBC and never exposes audio, RTP payloads, PCAP or DTMF.

## Architecture

Both transports use the same tool catalog, authorization scopes, redaction,
rate limits, result bounds and local audit:

- **Local MCP (stdio):** the client launches `/opt/voxywatch/voxywatch-mcp.js`.
  The bridge forwards JSON-RPC to `http://127.0.0.1:3080/mcp`.
- **Remote MCP (Streamable HTTP):** the client calls
  `https://<portal-domain>/mcp`.

The HTTP implementation uses the official `@modelcontextprotocol/sdk` server
and stateless JSON-response Streamable HTTP with MCP protocol `2025-11-25`.
VoxyWatch continues to own authorization, scopes, redaction, result bounds and
content-free audit. It reuses the portal listener; it does not open a new port
or run another service.

## Network and ports

| Mode | Destination | Firewall change |
|---|---|---|
| Local stdio | `127.0.0.1:3080/mcp` | None |
| Existing portal HTTPS | TCP 443 reverse proxy → portal | Only the existing HTTPS publication |
| Native portal HTTPS | TCP 3443 by default | Allow only if deliberately used instead of a reverse proxy |
| OpenAI Secure MCP Tunnel | Outbound TCP 443 to OpenAI | No inbound port |
| Claude remote connector | Public TCP 443 from Anthropic infrastructure | Allowlist current Anthropic ranges when required |

Never publish TCP 3080 directly to the Internet. Never expose PostgreSQL 5433,
HEP 9060/9062, SNMP 161 or the agentic sidecar 3081 for MCP.

Recommended deployment:

```text
ChatGPT / Claude
       |
       | HTTPS 443 + OAuth 2.1
       v
Caddy / secure tunnel
       |
       | loopback HTTP
       v
127.0.0.1:3080/mcp -> live evidence + gated setup tools
```

## Enable and configure

In **Settings → AI connections**:

1. Enable MCP.
2. Keep Remote MCP off for local-only usage, or enable it after HTTPS is ready.
3. Keep sensitive traffic off initially.
4. Keep **Allow initial setup changes** off unless an assistant must configure the installation.
5. Configure the maximum result size; 120000 bytes is the default.
6. Add browser origins only when a browser-based client sends `Origin`.
7. For end-user remote access, configure an OAuth issuer, audience/resource and
   JWKS URL from an established identity provider.

Risky behavior is off by default. Enabling Remote MCP does not modify the
firewall, reverse proxy or DNS.

## Authentication and scopes

Local/private automation may use a VoxyWatch API key. Remote end users should
use OAuth 2.1 access tokens issued specifically for the MCP audience.

| Scope | Data |
|---|---|
| `mcp:read` | Platform health, KPIs, trunks, baselines and forecasts |
| `mcp:traffic` | Live/recent CDR metadata and SIP ladder evidence |
| `mcp:incidents` | Incidents and their deterministic evidence |
| `mcp:sensitive` | Full numbers, IPs and Call-IDs, only when the global sensitive switch is also on |
| `mcp:configure` | Initial LLM selection, trunk upserts and IP-label upserts, only when the configuration switch is also on |

`mcp:sensitive` alone is insufficient. The administrator must also enable
**Allow sensitive traffic data**. Without both conditions, numbers retain only
their last four digits, IPs become subnets and Call-IDs become installation-local
opaque hashes. Those opaque references remain usable by the same authenticated
actor for drill-down calls for 30 minutes and are never persisted.

OAuth tokens are validated for signature, algorithm, issuer, audience,
expiration and scopes using the configured JWKS. Protected resource metadata is
available at:

```text
/.well-known/oauth-protected-resource
/.well-known/oauth-protected-resource/mcp
```

The identity provider remains responsible for authorization-code + PKCE,
consent, client registration and token issuance.

## Tool catalog

VoxyWatch exposes 13 read-only tools and one separately gated setup tool.
Availability is limited by caller scopes and global administrative switches.

| Tool | Scope | Purpose |
|---|---|---|
| `get_overview` | `mcp:read` | Global KPIs, top traffic, trunk and capture summary |
| `get_realtime_traffic` | `mcp:traffic` | Active/recent calls with a client-selected 5 s–30 min refresh preference |
| `get_trunk_health` | `mcp:read` | Current trunk status, quality metrics and reasons |
| `search_calls` | `mcp:traffic` | Bounded CDR search by result, country, client and quality/SIP filters |
| `get_call_detail` | `mcp:traffic` | One call's redacted CDR and quality alerts |
| `get_call_flow` | `mcp:traffic` | Bounded, redacted SIP ladder for one call |
| `get_incident` | `mcp:incidents` | Incident state, deterministic evidence and recent timeline |
| `get_error_breakdown` | `mcp:incidents` | Recent SIP failure distribution for a trunk |
| `get_flash_call_overview` | `mcp:read` | Passive Flash Call pattern evidence with hashed source IDs |
| `compare_baseline` | `mcp:read` | Current trunk metrics compared with learned history |
| `suggest_thresholds` | `mcp:read` | Read-only threshold recommendations; never applies them |
| `forecast_trunk` | `mcp:read` | Bounded volume or ASR forecast for a trunk |
| `get_setup_status` | `mcp:read` | Redacted Getting Started, LLM, trunk/IP-label and MCP readiness |
| `configure_initial_setup` | `mcp:configure` | Dry-run then confirmed merge/upsert of non-secret initial setup fields |

There is no generic SQL, shell, network or remediation tool. The single setup
tool has a fixed schema, rejects secrets, never deletes catalogs, starts in
dry-run mode and requires both an administrative switch and `APPLY_SETUP`.
Tool responses are bounded by both per-tool limits and the configured maximum
result size.

## Local client configuration

Create an API key with `mcp:read`, plus `mcp:traffic` and/or `mcp:incidents`.
Add `mcp:configure` only for a temporary or explicitly approved setup editor.
Then configure the client:

```json
{
  "mcpServers": {
    "voxywatch": {
      "command": "node",
      "args": ["/opt/voxywatch/voxywatch-mcp.js"],
      "env": {
        "VW_URL": "http://127.0.0.1:3080",
        "VW_API_KEY": "vw_live_REPLACE_ON_CLIENT"
      }
    }
  }
}
```

Do not place real keys in tickets, screenshots or documentation.

## Remote client configuration

Use:

```text
https://<portal-domain>/mcp
```

- ChatGPT/OpenAI private deployments can use Secure MCP Tunnel without an
  inbound firewall rule.
- Claude remote connectors originate from Anthropic infrastructure, even when
  configured from Claude Desktop. The HTTPS endpoint must therefore be
  reachable from that infrastructure.
- API integrations may attach `Authorization: Bearer <token>` directly.

### ChatGPT and OpenAI

Use the remote HTTPS endpoint with OAuth 2.1 when connecting an end-user ChatGPT
or OpenAI client. For private deployments that cannot accept inbound traffic,
use OpenAI Secure MCP Tunnel over outbound TCP 443. The VoxyWatch portal remains
the protected resource; an external identity provider issues audience-bound
tokens.

### Claude

Claude Desktop can use the local stdio configuration above. A remote Claude
connector uses `https://<portal-domain>/mcp` and reaches it from Anthropic
infrastructure, so localhost, a private LAN address or a client-side VPN alone
is not sufficient. Publish only TCP 443 and apply the identity-provider and
network allowlist policy appropriate to the deployment.

### Codex and other MCP clients

Clients that support stdio can launch `/opt/voxywatch/voxywatch-mcp.js`. Clients
that support Streamable HTTP can use the remote endpoint. Keep credentials in
the client's secret/environment facility, not in a repository or prompt.

Client capability and configuration syntax may change independently of
VoxyWatch. Follow the client's current official documentation while preserving
the VoxyWatch endpoint, scope and redaction requirements in this guide.

## Live traffic semantics

`get_realtime_traffic` reads the current in-memory working set. It accepts:

- `window_sec`: 30–1800 seconds.
- `limit`: 1–100 calls.
- `active_only`: return only calls still active.
- `refresh_sec`: 5–1800 seconds; returned as the client's polling preference.

The preference does not create a background LLM job. The client decides when to
ask again, which preserves the user's desired balance between real-time answers,
token cost and server load.

All responses include generation time, freshness and whether redaction or
truncation was applied. Tool results use both `structuredContent` and a
backwards-compatible serialized text block.

## Audit and operations

MCP audit records are stored locally in
`voxywatch_mcp_audit.json` with mode `0600`. They contain actor, tool, time,
latency, result size, redaction mode and outcome. They never contain arguments,
tokens, numbers, IPs, Call-IDs or returned traffic.

Useful portal endpoints:

- `GET /api/mcp/status` — configuration, transport, tool catalog and audit health.
- `GET /api/mcp/audit` — admin-only bounded audit.
- `POST /api/mcp/test` — admin-only live deterministic tool test.

Tool arguments are validated against their JSON Schemas before execution.
Validation errors contain paths and rule names but never echo submitted values.
Configuration audit records identify actor, tool, result, duration and size but
never preserve submitted trunks, IP labels, tokens or returned content.

## Recommended rollout

1. Start locally with `mcp:read` only.
2. Run the built-in test and inspect the local audit record.
3. Add `mcp:traffic` or `mcp:incidents` only for an explicit use case.
4. Verify redacted call IDs, numbers and IPs before remote publication.
5. Publish the existing portal through HTTPS 443; never expose 3080.
6. Configure OAuth issuer, audience and JWKS for remote end users.
7. Restrict Origins and network sources where applicable.
8. Keep `mcp:sensitive` and the global sensitive switch off unless raw
   identifiers are operationally required and approved.
9. Review rate-limit, maximum result size and `voxywatch_mcp_audit.json`.
10. If setup editing is needed, enable it temporarily, dry-run every change,
    confirm only after human review, then revoke the scope or disable the switch.

## Troubleshooting

| Symptom | Check |
|---|---|
| `403` or MCP disabled | Enable Integration API and MCP; enable Remote MCP only for HTTP clients outside the host |
| Authentication failure | Confirm token/API-key type, audience, issuer, expiry and required tool scope |
| Tool missing | Check `/api/mcp/status`, the caller scope and the client's cached tool catalog |
| Browser Origin rejected | Add the exact HTTPS Origin; do not use a wildcard for convenience |
| Remote client cannot connect | Confirm DNS, certificate and TCP 443; do not open 3080 |
| Local stdio cannot connect | Confirm Node.js, bridge path, loopback portal health and secret environment variables |
| Redacted identifiers | Expected unless both `mcp:sensitive` and the global sensitive-data switch are enabled |
| Result reports truncation | Narrow the time window/limit or raise the configured byte cap cautiously |
| Repeated token/cost use | Increase the client's `refresh_sec`; VoxyWatch does not create a background LLM polling job |
| Audit unhealthy | Check file ownership/permissions and disk health; never replace mode `0600` with a public file |
| Setup tool missing | Enable initial setup changes and include both `mcp:read` and `mcp:configure`; refresh the client's tool catalog |
| Setup asks for a credential | Do not send it. Use Settings, a Linux credential/environment or `voxywatch-ai-key --stdin` |

For Flash Call tool semantics and detector limitations, see
[Flash Call Detection](FLASH_CALL_DETECTION.md).

## Deliberate exclusions

- No generic write tools; only the fixed, opt-in, merge-only initial setup tool.
- No SBC control.
- No arbitrary SQL or arbitrary URL fetching.
- No raw SIP bodies, RTP/audio, PCAP or DTMF.
- No automatic firewall, DNS, certificate or reverse-proxy changes.
- No OAuth authorization server implemented inside VoxyWatch; use an established
  identity provider.
