# VoxyWatch MCP

VoxyWatch MCP gives compatible AI clients bounded access to live operational
evidence. It is optional, off by default, and never controls a customer SBC.
It does not expose audio, RTP payloads, PCAP or DTMF.

## Connection modes

- **Local:** configure the supplied local MCP launcher in the client that runs
  on the VoxyWatch host or an approved management host.
- **Remote:** connect the client to `https://<portal-domain>/mcp` only after
  HTTPS, certificate trust and remote access have been configured.

Local mode needs no new inbound firewall rule. Remote mode uses the existing
portal HTTPS path on TCP 443; never publish a local backend, capture or
monitoring port for MCP.

## Configure safely

In **Settings → MCP connections**, enable MCP, keep Remote MCP and sensitive
traffic disabled initially, then select only the needed scopes. Allow setup
changes only when an administrator has explicitly approved them. Enabling MCP
does not change DNS, firewall, certificates or an SBC.

Use a least-privilege credential supported by the installed release. SSO/OIDC
login is a roadmap item and is distinct from MCP authorization.

## Client authentication

For private automation, create a revocable API key in **Settings → API** with
`mcp:read`, adding other scopes only as needed. Keep the key in the client's
secret store or environment; portal usernames/passwords are not MCP credentials.

For a Streamable HTTP client, set the server URL to `https://YOUR-HOST/mcp`
and provide `Authorization: Bearer <your scoped token>` through its credential
settings. Replace YOUR-HOST with the actual HTTPS address and trust its certificate.
Remote access must be enabled in VoxyWatch. The client must be able to reach that
address; a cloud-hosted connector cannot reach your laptop's localhost.

For end-user OAuth clients, configure the **issuer**, **audience/resource** and
**JWKS URL** in MCP settings to match your identity provider. The provider must issue
audience-bound access tokens with the required MCP scopes. This is independent of
portal SSO. Client support for API keys versus OAuth varies; use its supported method.

Example for a local stdio client on the VoxyWatch host (Node 18+ must be available
to that client; use HTTPS mode if it is not):

```json
{
  "mcpServers": {
    "voxywatch": {
      "command": "node",
      "args": ["/opt/voxywatch/voxywatch-mcp.js"],
      "env": {
        "VW_URL": "http://127.0.0.1:3080",
        "VW_API_KEY": "REPLACE_IN_CLIENT_SECRET_STORE"
      }
    }
  }
}
```

The loopback URL is the default local endpoint only; use the effective configured
port if different. Never expose that backend. For another client host, use the
remote HTTPS method instead. JSON syntax varies by client; the URL, credential and
scope requirements do not. Never commit a populated configuration to a repository.

Save settings, press **Test**, connect the client, and ask it to list available
tools, then request current health. Verify its time range and result in the portal.
Typical uses include network health, trunk statistics, call evidence, incidents and
existing transcripts (sensitive permission required). Missing evidence must be reported
as unavailable. MCP does not create original signaling that was never captured.

Optional initial setup follows a dry-run and explicit confirmation; see
[initial setup](INITIAL_SETUP_CHANNELS.md). It does not accept credentials or delete catalogs.

## Scope and privacy

Operational evidence tools are read-only. The optional setup tool is separately
gated and does not grant general administration or SBC access.

`mcp:read` covers health and aggregate KPIs; `mcp:traffic` allows bounded call
and signaling evidence; `mcp:incidents` allows incidents; `mcp:sensitive` needs
the separate administrator sensitive-data switch; `mcp:configure` needs the
separate setup switch. Keep sensitive access off unless justified.

MCP results are bounded and redacted by default. Do not provide credentials,
raw SIP, audio, PCAP, full numbers or unredacted logs to a client. Verify a
recommendation in the portal before changing configuration.

## Troubleshooting

For remote connection failures, confirm the portal HTTPS URL, certificate trust,
TCP 443 reachability and the configured credential/scopes. For local failures,
confirm the approved launcher can reach the local portal. See
[HTTPS access](HTTPS_CONFIGURATION.md) and [AI troubleshooting](AI_TROUBLESHOOTING.md).
