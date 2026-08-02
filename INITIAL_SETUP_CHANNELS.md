# Initial setup through Settings, CLI and MCP

VoxyWatch exposes the same initial setup outcomes through three controlled channels. The
portal remains the authority and all channels operate on the installation itself; none of
them configures or controls an SBC, PBX, firewall or carrier platform.

## Capability matrix

| Area | Settings | Local CLI | MCP assistant |
|---|---|---|---|
| Inspect Getting Started status | Yes | `voxywatch-setup status` | `get_setup_status` |
| Select LLM provider/model/key source | Yes | Validate/apply JSON on stdin | `configure_initial_setup` |
| Store an LLM credential | Encrypted store | `voxywatch-ai-key ... --stdin` | Never accepted |
| Add or update trunks | Trunks editor/import | Validate/apply JSON on stdin | Upsert only |
| Add or update IP labels | IP Directory/import | Validate/apply JSON on stdin | Upsert only |
| Delete catalogs or alter capture listeners | Existing dedicated admin UI only | Not exposed | Not exposed |

MCP configuration starts disabled. Enabling MCP read access does not enable writes. An
administrator must separately enable **Allow initial setup changes**, issue an API key or
OAuth token containing both `mcp:read` and `mcp:configure`, review a dry-run result and send
the exact confirmation `APPLY_SETUP`.

## Authentication model

Do not give a portal username and password to ChatGPT, Claude, Codex or another MCP client.
Portal credentials are interactive human credentials and are intentionally not accepted at
`/mcp`.

- The web portal uses its normal JWT session and role. Only administrators save settings.
- Local CLI application requires root because it writes protected product files.
- Local/private MCP can use a revocable VoxyWatch API key with narrow scopes, expiration,
  rate limit and optional IP allowlist.
- Remote end-user MCP should use OAuth 2.1 with an audience dedicated to the VoxyWatch MCP
  resource. The identity provider issues the scopes.

An editor for initial setup is therefore a credential with `mcp:configure`; it is not a copy
of a portal password. Revoke that key or scope after onboarding if ongoing editing is not
required.

## CLI workflow

Configuration JSON is read from stdin so it does not enter shell history:

```text
sudo voxywatch-setup status
sudo voxywatch-setup validate --stdin < setup.json
sudo voxywatch-setup apply --stdin --confirm APPLY_SETUP < setup.json
```

Example without a credential:

```json
{
  "llm": { "enabled": true, "provider": "openai", "model": "gpt-5.6-luna", "key_source": "environment" },
  "trunks": [
    { "name": "Example carrier", "direction": "both", "ips": ["192.0.2.0/24"] }
  ],
  "ip_labels": { "10.0.0.10": "Primary SBC" }
}
```

The command restarts only the VoxyWatch portal after a successful apply. It does not restart
the sniffer because the allowlisted initial setup fields do not alter capture listeners.

## MCP workflow

1. Call `get_setup_status` and review pending Getting Started items.
2. Collect missing values; never invent IPs, trunks or prefixes.
3. Call `configure_initial_setup` with `dry_run:true`.
4. Present the returned summary to the user.
5. Only after approval, repeat with `dry_run:false` and `confirm:"APPLY_SETUP"`.
6. Call `get_setup_status` again and report what remains pending.

The write tool is merge/upsert-only. An empty list cannot erase existing configuration.
Passwords, API keys, tokens, communities and other secret-shaped fields are rejected before
any write. LLM credentials continue to use Settings, Linux credentials/environment or the
dedicated secure CLI.
