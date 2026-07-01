# VoxyWatch AI Troubleshooting Pack

This file is the entry point for an AI assistant helping a VoxyWatch operator configure, debug or extend an installation.

Load this file first, then follow the links in `docs/ai/`. If you have access to the VoxyWatch portal, open Settings -> Diagnostics and use:

- Open AI docs
- Copy AI context
- Download AI context
- Download support bundle

The AI context and support bundle are intentionally safe to share with an assistant. They are allowlist-based and exclude secrets, credentials, raw SIP, audio, settings files, logs, phone numbers, IP addresses, trunks and Call-IDs.

## Start Here

- [AI README](docs/ai/README.md)
- [Troubleshooting workflow](docs/ai/TROUBLESHOOTING.md)
- [CLI operations](docs/ai/CLI_OPERATIONS.md)
- [Settings reference](docs/ai/SETTINGS_REFERENCE.md)
- [Architecture map](docs/ai/ARCHITECTURE_MAP.md)
- [Do not touch](docs/ai/DO_NOT_TOUCH.md)
- [Extending VoxyWatch](docs/ai/EXTENDING_VOXYWATCH.md)

## Runbooks

- [Capture loss](docs/ai/RUNBOOKS/capture-loss.md)
- [High CPU](docs/ai/RUNBOOKS/high-cpu.md)
- [Portal OOM](docs/ai/RUNBOOKS/portal-oom.md)
- [SNMP and PRTG](docs/ai/RUNBOOKS/snmp-prtg.md)
- [Audio reconstruction](docs/ai/RUNBOOKS/audio-reconstruction.md)
- [Update failed](docs/ai/RUNBOOKS/update-failed.md)
- [SIP analysis](docs/ai/RUNBOOKS/sip-analysis.md)
- [License and auth](docs/ai/RUNBOOKS/license-auth.md)

## Operating Rules For The Assistant

1. Read before assuming.
2. Start with read-only evidence.
3. Separate product bugs from deployment, hardware, SBC/probe behavior and provider/network behavior.
4. Never access or modify a customer SBC.
5. Never ask the operator to paste secrets, raw SIP, audio, customer CDR samples, IP lists, trunk names or credentials into chat.
6. For production VoxyWatch, use the signed release/update pipeline. Do not hand-patch installed code.
7. Prefer configuration, tests and documented runbooks over one-off commands.
