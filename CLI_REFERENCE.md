# VoxyWatch local CLI reference

## First sign-in and local recovery

Fresh installations use `admin` with a unique bootstrap password, not a shared
default. The installer identifies its private local file. Read it only with
authorized local access and change it at first portal sign-in before using CLI
commands backed by protected portal routes. Do not paste credentials into
command arguments, support tickets or AI chats. Local recovery and license
installation remain available independently; use `voxywatch user --help` for
the installed recovery commands. Updates preserve configured accounts.

## Command index

Each action below is also available through static `voxywatch <command> --help`.
Use nested help for exact installed flags; commands never accept secrets on argv.

| Command | Purpose |
|---|---|
| <a id="version"></a>`version` | Inspect version (version). |
| <a id="hwid"></a>`hwid` | Inspect hwid (hwid). |
| <a id="status"></a>`status` | Inspect current state (status). |
| <a id="license-install"></a>`license install` | Inspect license install (license). |
| <a id="license-status"></a>`license status` | Inspect current state (license). |
| <a id="license-hwid"></a>`license hwid` | Inspect license hwid (license). |
| <a id="ai-key-set"></a>`ai key set` | Store a secret supplied through stdin (ai key). |
| <a id="ai-key-status"></a>`ai key status` | Inspect current state (ai key). |
| <a id="setup-status"></a>`setup status` | Inspect current state (setup). |
| <a id="setup-validate"></a>`setup validate` | Validate input without applying changes (setup). |
| <a id="setup-apply"></a>`setup apply` | Request the selected operation with explicit confirmation (setup). |
| <a id="security-recaptcha-status"></a>`security recaptcha status` | Inspect current state (security recaptcha). |
| <a id="security-recaptcha-enable"></a>`security recaptcha enable` | Enable the selected feature (security recaptcha). |
| <a id="security-recaptcha-disable"></a>`security recaptcha disable` | Disable the selected feature (security recaptcha). |
| <a id="doctor"></a>`doctor` | Inspect doctor (doctor). |
| <a id="capture-status"></a>`capture status` | Inspect current state (capture). |
| <a id="geography-status"></a>`geography status` | Inspect current state (geography). |
| <a id="geography-policies"></a>`geography policies` | Inspect geography policies (geography). |
| <a id="geography-configure"></a>`geography configure` | Validate and save a JSON configuration patch (geography). |
| <a id="geography-key-set"></a>`geography key set` | Store a secret supplied through stdin (geography key). |
| <a id="geography-key-remove"></a>`geography key remove` | Remove the selected credential or license with explicit confirmation (geography key). |
| <a id="threats-registrations"></a>`threats registrations` | Inspect threats registrations (threats). |
| <a id="threats-geography"></a>`threats geography` | Inspect threats geography (threats). |
| <a id="capture-registrations-status"></a>`capture registrations status` | Inspect current state (capture registrations). |
| <a id="capture-registrations-configure"></a>`capture registrations configure` | Save the shared REGISTER/SUBSCRIBE/NOTIFY storage switch and REGISTER retention. Reload is asynchronous; history is not deleted. |
| <a id="snmp-status"></a>`snmp status` | Inspect current state (snmp). |
| <a id="snmp-configure"></a>`snmp configure` | Validate and save a JSON configuration patch (snmp). |
| <a id="system-diagnostics"></a>`system diagnostics` | Inspect system diagnostics (system). |
| <a id="capture-filters-status"></a>`capture filters status` | Inspect current state (capture filters). |
| <a id="capture-filters-configure"></a>`capture filters configure` | Validate and save a JSON configuration patch (capture filters). |
| <a id="config-export"></a>`config export` | Export supported initial-setup configuration (config). |
| <a id="config-validate"></a>`config validate` | Validate input without applying changes (config). |
| <a id="config-import"></a>`config import` | Merge supported initial-setup configuration; not a full restore (config). |
| <a id="ai-test"></a>`ai test` | Test the configured integration (ai). |
| <a id="ai-key-remove"></a>`ai key remove` | Remove the selected credential or license with explicit confirmation (ai key). |
| <a id="notifications-test"></a>`notifications test` | Test the configured integration (notifications). |
| <a id="logs"></a>`logs` | Inspect logs (logs). |
| <a id="update-check"></a>`update check` | Check available signed update (update). |
| <a id="update-apply"></a>`update apply` | Request the selected operation with explicit confirmation (update). |
| <a id="license-remove"></a>`license remove` | Remove the selected credential or license with explicit confirmation (license). |
| <a id="security-recaptcha-keys-status"></a>`security recaptcha keys status` | Inspect current state (security recaptcha keys). |
| <a id="security-recaptcha-keys-set"></a>`security recaptcha keys set` | Store a secret supplied through stdin (security recaptcha keys). |
| <a id="security-recaptcha-keys-remove"></a>`security recaptcha keys remove` | Remove the selected credential or license with explicit confirmation (security recaptcha keys). |
| <a id="security-recaptcha-test"></a>`security recaptcha test` | Test the configured integration (security recaptcha). |
| <a id="security-recaptcha-keys-test"></a>`security recaptcha keys test` | Test the configured integration (security recaptcha keys). |
| <a id="api-token-create"></a>`api token create` | Create a scoped API credential. Read JSON from stdin; write the one-time secret to a protected --output file. |
| <a id="api-token-list"></a>`api token list` | List existing entries (api token). |
| <a id="api-token-status"></a>`api token status` | Inspect current state (api token). |
| <a id="api-token-revoke"></a>`api token revoke` | Revoke access immediately; retain metadata for audit. Requires the exact confirmation shown above. |
| <a id="api-token-update"></a>`api token update` | Edit metadata, scopes, IP restrictions, rate or expiry by ID. Omitted fields and secret stay unchanged; revoked keys cannot be revived. |
| <a id="mcp-status"></a>`mcp status` | Inspect saved MCP permissions, local endpoint and tool catalog. Does not prove remote client connectivity. |
| <a id="mcp-configure"></a>`mcp configure` | Save an MCP JSON patch. Remote, sensitive and configuration access are independent permissions; no firewall or SBC changes. |
| <a id="mcp-validate"></a>`mcp validate` | Validate MCP JSON locally without saving or contacting the portal. Does not prove remote connectivity. |
| <a id="mcp-test"></a>`mcp test` | Run the local overview tool when MCP is enabled. Does not validate a remote client token or OAuth provider. |
| <a id="mcp-tools"></a>`mcp tools` | List the MCP tool catalog and required scopes. Actual availability also depends on the client credential and settings. |
| <a id="mcp-audit"></a>`mcp audit` | Read bounded MCP audit metadata; --limit is 1..200. Never returns tool arguments or result contents. |
| <a id="web-tls-status"></a>`web tls status` | Inspect current state (web tls). |
| <a id="web-tls-validate"></a>`web tls validate` | Validate input without applying changes (web tls). |
| <a id="web-tls-import"></a>`web tls import` | Merge supported initial-setup configuration; not a full restore (web tls). |
| <a id="web-access-status"></a>`web access status` | Inspect current state (web access). |
| <a id="web-access-validate"></a>`web access validate` | Validate input without applying changes (web access). |
| <a id="web-access-apply"></a>`web access apply` | Request the selected operation with explicit confirmation (web access). |
| <a id="user-list"></a>`user list` | List existing entries (user). |
| <a id="user-create"></a>`user create` | Create an entry from the specified input (user). |
| <a id="user-role"></a>`user role` | Change the account role with explicit confirmation (user). |
| <a id="user-enable"></a>`user enable` | Enable the selected feature (user). |
| <a id="user-disable"></a>`user disable` | Disable the selected feature (user). |
| <a id="user-unlock"></a>`user unlock` | Enable the named account; does not reset shared IP rate limits (user). |
| <a id="user-reset-password"></a>`user reset-password` | Set a password from stdin; offline recovery preserves service state (user). |
| <a id="transcripts-status"></a>`transcripts status` | Inspect current state (transcripts). |
| <a id="transcripts-configure"></a>`transcripts configure` | Validate and save a JSON configuration patch (transcripts). |
| <a id="transcripts-key-set"></a>`transcripts key set` | Store a secret supplied through stdin (transcripts key). |
| <a id="transcripts-key-status"></a>`transcripts key status` | Inspect current state (transcripts key). |
| <a id="transcripts-key-remove"></a>`transcripts key remove` | Remove the selected credential or license with explicit confirmation (transcripts key). |
| <a id="transcripts-key-test"></a>`transcripts key test` | Test the configured integration (transcripts key). |
| <a id="transcripts-test"></a>`transcripts test` | Test the configured integration (transcripts). |
| <a id="transcripts-enable"></a>`transcripts enable` | Enable the selected feature (transcripts). |
| <a id="transcripts-disable"></a>`transcripts disable` | Disable the selected feature (transcripts). |
| <a id="transcripts-refinement-enable"></a>`transcripts refinement enable` | Enable the selected feature (transcripts refinement). |
| <a id="transcripts-refinement-disable"></a>`transcripts refinement disable` | Disable the selected feature (transcripts refinement). |

Use the installed local command for administrator work on the VoxyWatch host:

```sh
sudo voxywatch --help
sudo voxywatch completion bash
sudo voxywatch completion zsh
```

The command surface is allowlisted. There is no shell, global reset, purge, capture control, or SBC control. `--help` and both completion commands are static: they do not start the portal or contact a service. Use nested help for the exact installed syntax, for example:

```sh
sudo voxywatch capture filters --help
sudo voxywatch transcripts --help
sudo voxywatch user --help
```

## Privileges, input, and output

### MCP administration

Use `sudo voxywatch mcp status --json` to inspect permissions and the local endpoint, `mcp tools --json` for the tool catalog and required scopes, and `mcp audit --limit 100 --json` for bounded audit metadata (maximum 200). Administrative commands require local root access; remote MCP clients still need their own credential, permitted scopes and server-side access settings.

```sh
printf '%s\n' '{"enabled":true,"remote_enabled":false}' | \
  sudo voxywatch mcp validate --stdin --json
printf '%s\n' '{"enabled":true,"remote_enabled":false}' | \
  sudo voxywatch mcp configure --stdin --dry-run --json
printf '%s\n' '{"enabled":true,"remote_enabled":false}' | \
  sudo voxywatch mcp configure --stdin --json
sudo voxywatch mcp test --json
```

Validation and dry-run are offline and do not save. Configure applies a partial patch: omitted keys keep their values. Test runs only the local overview tool with MCP enabled; it does not validate remote connectivity or an OAuth login. No command opens firewall ports or changes an SBC.

Supported JSON keys: boolean `enabled`, `remote_enabled`, `allow_api_keys`, `allow_sensitive`, `allow_configuration`; integer `max_result_bytes` from 4096 to 262144; `allowed_origins` (up to 30 exact HTTPS origins without a path); `allowed_tools` (up to 50 tool names from the catalog); and `oauth_issuer`, `oauth_audience`, `oauth_jwks_uri`. OAuth URLs require HTTPS and cannot contain credentials. An empty OAuth string clears that value. Unknown keys and coerced booleans such as `"enabled":"yes"` are rejected. Sensitive/configuration access requires both the corresponding server setting and the client's scopes.

### Edit an API credential without rotating its secret

Obtain the ID from `sudo voxywatch api token list --json`, then apply a patch:

```sh
printf '%s\n' '{"name":"monitoring","scopes":["metrics:read","mcp:read"]}' | \
  sudo voxywatch api token update --id k_0123456789abcdef --stdin --dry-run --json
```

Replace the example ID with the existing ID and omit `--dry-run` to apply. Supported fields are `name`, `scopes`, `ips`, `rate_per_min`, `expires_at`. Omitted fields, ID and secret stay unchanged. `ips` accepts exact IPv4/IPv6, IPv4 CIDR or a trailing-dot IPv4 prefix; IPv6 CIDR is not supported. Rate is 1..100000 or `null`; expiry is a future date-time or `null`. Revoked credentials cannot be revived. The command never displays or generates a replacement secret. Narrow scopes rather than granting unnecessary access.

### Shared non-call signaling storage

`capture registrations configure --stdin` accepts `save_registers` as the one shared switch for REGISTER, SUBSCRIBE, NOTIFY and their SIP responses across capture modes. False omits new storage; it does not delete history, discard INVITE/BYE signaling or disable RTP. Malformed/unclassified input is retained rather than guessed. REGISTER retention remains separate; it does not imply a new subscription-history database. Saved policy reload is asynchronous.

```sh
printf '%s\n' '{"save_registers":false}' | \
  sudo voxywatch capture registrations configure --stdin --json
sudo voxywatch capture registrations status --json
```

Administrative commands require `sudo`. Secrets, passwords, certificates and JSON use `stdin`, never a command argument. Do not put a secret in a shell variable or command history. `--json` returns a versioned object with `schema_version: 1`; it contains bounded metadata, not credentials or a claim that an external action succeeded.

| Exit | Meaning |
|---:|---|
| 0 | Requested local operation completed. |
| 1 | Operation could not be verified or failed. |
| 2 | Command syntax or arguments were rejected. |
| 3 | Root privilege is required. |

Syntax and privilege errors are structured when `--json` is present. Invalid stdin payload is an operation failure (exit 1), not a syntax result. A saved state is not proof that a running service has applied it; inspect the relevant status after an apply.

## Read-only checks

```sh
sudo voxywatch version --json
sudo voxywatch hwid --json
sudo voxywatch status --json
sudo voxywatch doctor --json
sudo voxywatch capture status --json
sudo voxywatch capture filters status --json
sudo voxywatch config export --json
```

`doctor` does not start the portal. If the portal is unavailable, it returns a bounded set of actionable local checks. `unknown` means not verified, never a successful health assertion. `config export` is a portable, non-secret initial setup document, not a full backup. Except `config export --json`, which emits that portable document without a `schema_version` envelope.

`security recaptcha status --json` is also read-only. On a valid fresh VoxyWatch data directory with no settings file it reports saved reCAPTCHA as disabled and live state as `unknown`; it does not create settings, lock or audit state, and does not start or query the portal.

## Preview before changing state

Supported mutations accept `--dry-run`. A preview reads and validates its input locally but does not write, send, restart, lock, audit, or contact a provider, and returns `dry_run: true` with `effective: "unknown"`. It needs no confirmation. `--dry-run` and `--confirm` cannot be combined; apply revalidates all input.

```sh
printf '%s\n' '{"trusted_prefixes":[]}' | \
  sudo voxywatch capture filters configure --stdin --dry-run --json
printf '%s\n' '{"provider":"local","model":"base"}' | \
  sudo voxywatch transcripts configure --stdin --dry-run --json
sudo voxywatch user disable --username operator1 --dry-run --json
sudo voxywatch update apply --dry-run --json
```

Without `--dry-run`, only commands whose help shows `--confirm` require its exact confirmation; capture-filter and transcription configuration commands do not. An accepted TLS import or update request is not proof that a certificate or update is live.

## Capture filters

`capture filters configure --stdin` accepts JSON with only `trusted_prefixes`, `siprec_allow`, and `mirror_trusted_cidrs`. Empty values mean open/all: `[]`, `""`, and `""` respectively. HEP prefixes remain legacy analysis hints, not a sender ACL; SIPREC and mirror values are IP/CIDR restrictions. The result reports saved values, `restart_required`, and `effective: "unknown"`; this CLI never restarts capture.

## Transcription and AI credentials

Speech-to-text is separate from the general LLM credential. Use `transcripts key set --stdin`, `transcripts key status`, and `transcripts key remove` for the STT credential; it is never an AI-key provider argument. Expert transcript refinement uses the separately configured general LLM after a base transcript exists. Observability credentials are configured in Settings, not through the general AI key command.

```sh
printf '%s\n' '{"provider":"openai","model":"whisper-1","language":"en"}' | \
  sudo voxywatch transcripts configure --stdin --dry-run --json
sudo voxywatch transcripts enable --mode all --dry-run --json
sudo voxywatch transcripts refinement enable --dry-run --json
```

`transcripts test --file FILE --confirm SEND_AUDIO` sends the selected bounded WAV to the configured engine. It is not a preview and does not retain a test transcript.

## Other bounded administration

| Family | Exact actions | Purpose |
|---|---|---|
| Setup | `setup status`, `setup validate`, `setup apply`; `config export`, `config validate`, `config import` | Bounded initial setup only. |
| AI and notifications | `ai test`, `ai key remove`; `notifications test` | Test configured AI or an explicit delivery channel. |
| Security | `security recaptcha keys status`, `set`, `remove`, `test`; `security recaptcha test` | Manage or check reCAPTCHA material without exposing it. |
| Operations | `logs`, `update check`, `update apply` | Bounded journal metadata and signed-update request/preview. |
| Registration capture | `capture registrations status`; `capture registrations configure --stdin` | Inspect or validate storage/retention policy; disabling new storage does not erase prior evidence. |
| Participant geography | `geography status`, `geography policies`; `geography configure --stdin` | Passive country policy using the same portal validation and revision checks. |
| Threat evidence | `threats registrations`, `threats geography` | Read bounded observations; never block traffic or control the SBC. |
| SNMP | `snmp status`; `snmp configure --stdin` | Inspect state or validate configuration with the portal's shared rules. |
| System | `system diagnostics` | Bounded instantaneous system/hardware summary, without charts. |

- `web tls validate --stdin` and `web tls import --stdin` accept JSON with
  `cert_pem` and `key_pem`; use dry-run before import.
- `web access status --json` reports host routing separately from TLS.
  `web access validate --stdin` validates JSON using the authenticated portal;
  `web access apply --stdin --confirm=APPLY_WEB_ACCESS` requests the scoped helper.
  JSON: `mode` (`internal`/`public`), `host`, optional `aliases`, `access_policy`
  (`open` default/`restricted`) and `allowed_hosts` (up to 32 exact IPs/DNS names).
  Omitted lists preserve installed values. `--dry-run` validates input locally;
  it does not prove live readiness. Accepted does not mean applied or verified.
  Open routing preserves login and TLS verification; it does not make an
  untrusted certificate or mismatched name trusted. See HTTPS_CONFIGURATION.md.
- `user create` and `user reset-password` read the password from stdin.
  Usernames and roles are explicit; an offline password reset preserves the
  portal active/inactive state and never touches capture.
- `api token create --stdin --output FILE` writes its one-time token only to
  the selected protected output file. Token input JSON supports `name`,
  `scopes`, `ips`, `rate_per_min`, and `expires_at`.
- `api token list`, `api token status --id ID` and
  `api token revoke --id ID --confirm REVOKE_TOKEN` inspect/revoke existing
  credentials without revealing their values.
- `geography key set --stdin` stores the dedicated provider credential;
  `geography key remove --confirm REMOVE_GEO_KEY` removes it. Do not pass keys
  as command-line arguments. Provider setup is admin-only; policy editing uses
  the permissions of the authenticated portal identity.
- For Google/Gemini transcription, use `provider: "google"` in transcription
  configuration JSON. Its STT credential is separate from the chat provider;
  `transcripts test --file FILE --confirm SEND_AUDIO` still sends selected audio.
- `license install` accepts a file or `--stdin`; `license remove` supports a
  preview. Legacy `voxywatch-license`, `voxywatch-ai-key`, and
  `voxywatch-setup` remain available for compatibility.

Run `sudo voxywatch <group> --help` before applying any command. This guide describes local administration only; it does not authorize a build, release, deployment, or action on network equipment.

For reCAPTCHA, `disable` may create the initial protected settings file with only `recaptcha_enabled: false`. `enable` still needs the persistent local credential vault before any change. A malformed, linked, unsafe, oversized or concurrently appearing settings file is rejected without overwriting it.
