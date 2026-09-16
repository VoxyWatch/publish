# VoxyWatch local CLI reference

Use the installed local command for administrator work on the VoxyWatch host:

```sh
sudo voxywatch --help
sudo voxywatch completion bash
sudo voxywatch completion zsh
```

The command surface is allowlisted. There is no shell, global reset, purge,
capture control, or SBC control. `--help` and both completion commands are
static: they do not start the portal or contact a service. Use nested help for
the exact installed syntax, for example:

```sh
sudo voxywatch capture filters --help
sudo voxywatch transcripts --help
sudo voxywatch user --help
```

## Privileges, input, and output

Administrative commands require `sudo`. Secrets, passwords, certificates and
JSON use `stdin`, never a command argument. Do not put a secret in a shell
variable or command history. `--json` returns a versioned object with
`schema_version: 1`; it contains bounded metadata, not credentials or a claim
that an external action succeeded.

| Exit | Meaning |
|---:|---|
| 0 | Requested local operation completed. |
| 1 | Operation could not be verified or failed. |
| 2 | Command syntax or arguments were rejected. |
| 3 | Root privilege is required. |

Syntax and privilege errors are structured when `--json` is present. Invalid
stdin payload is an operation failure (exit 1), not a syntax result. A saved
state is not proof that a running service has applied it; inspect the relevant
status after an apply.

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

`doctor` does not start the portal. If the portal is unavailable, it returns a
bounded set of actionable local checks. `unknown` means not verified, never a
successful health assertion. `config export` is a portable, non-secret initial
setup document, not a full backup. Except `config export --json`, which emits
that portable document without a `schema_version` envelope.

`security recaptcha status --json` is also read-only. On a valid fresh
VoxyWatch data directory with no settings file it reports saved reCAPTCHA as
disabled and live state as `unknown`; it does not create settings, lock or
audit state, and does not start or query the portal.

## Preview before changing state

Supported mutations accept `--dry-run`. A preview reads and validates its input
locally but does not write, send, restart, lock, audit, or contact a provider,
and returns
`dry_run: true` with `effective: "unknown"`. It needs no confirmation.
`--dry-run` and `--confirm` cannot be combined; apply revalidates all input.

```sh
printf '%s\n' '{"trusted_prefixes":[]}' | \
  sudo voxywatch capture filters configure --stdin --dry-run --json
printf '%s\n' '{"provider":"local","model":"base"}' | \
  sudo voxywatch transcripts configure --stdin --dry-run --json
sudo voxywatch user disable --username operator1 --dry-run --json
sudo voxywatch update apply --dry-run --json
```

Without `--dry-run`, only commands whose help shows `--confirm` require its
exact confirmation; capture-filter and transcription configuration commands do
not. An accepted TLS import or update request is not proof that a certificate
or update is live.

## Capture filters

`capture filters configure --stdin` accepts JSON with only
`trusted_prefixes`, `siprec_allow`, and `mirror_trusted_cidrs`. Empty values
mean open/all: `[]`, `""`, and `""` respectively. HEP prefixes remain legacy
analysis hints, not a sender ACL; SIPREC and mirror values are IP/CIDR
restrictions. The result reports saved values, `restart_required`, and
`effective: "unknown"`; this CLI never restarts capture.

## Transcription and AI credentials

Speech-to-text is separate from the general LLM credential. Use
`transcripts key set --stdin`, `transcripts key status`, and
`transcripts key remove` for the STT credential; it is never an AI-key provider
argument. Expert transcript refinement uses the separately configured general
LLM after a base transcript exists. Observability credentials are configured in
Settings, not through the general AI key command.

```sh
printf '%s\n' '{"provider":"openai","model":"whisper-1","language":"en"}' | \
  sudo voxywatch transcripts configure --stdin --dry-run --json
sudo voxywatch transcripts enable --mode all --dry-run --json
sudo voxywatch transcripts refinement enable --dry-run --json
```

`transcripts test --file FILE --confirm SEND_AUDIO` sends the selected bounded
WAV to the configured engine. It is not a preview and does not retain a test
transcript.

## Other bounded administration

| Family | Exact actions | Purpose |
|---|---|---|
| Setup | `setup status`, `setup validate`, `setup apply`; `config export`, `config validate`, `config import` | Bounded initial setup only. |
| AI and notifications | `ai test`, `ai key remove`; `notifications test` | Test configured AI or an explicit delivery channel. |
| Security | `security recaptcha keys status`, `set`, `remove`, `test`; `security recaptcha test` | Manage or check reCAPTCHA material without exposing it. |
| Operations | `logs`, `update check`, `update apply` | Bounded journal metadata and signed-update request/preview. |

- `web tls validate --stdin` and `web tls import --stdin` accept JSON with
  `cert_pem` and `key_pem`; use dry-run before import.
- `user create` and `user reset-password` read the password from stdin.
  Usernames and roles are explicit; an offline password reset preserves the
  portal active/inactive state and never touches capture.
- `api token create --stdin --output FILE` writes its one-time token only to
  the selected protected output file. Token input JSON supports `name`,
  `scopes`, `ips`, `rate_per_min`, and `expires_at`.
- `license install` accepts a file or `--stdin`; `license remove` supports a
  preview. Legacy `voxywatch-license`, `voxywatch-ai-key`, and
  `voxywatch-setup` remain available for compatibility.

Run `sudo voxywatch <group> --help` before applying any command. This guide
describes local administration only; it does not authorize a build, release,
deployment, or action on network equipment.

For reCAPTCHA, `disable` may create the initial protected settings file with
only `recaptcha_enabled: false`. `enable` still needs the persistent local
credential vault before any change. A malformed, linked, unsafe, oversized or
concurrently appearing settings file is rejected without overwriting it.
