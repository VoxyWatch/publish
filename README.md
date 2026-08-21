<div align="center">

<img src="assets/voxywatch-wordmark.png" alt="VoxyWatch" width="520">

### The agentic NOC for your voice network

VoxyWatch turns passive voice-network evidence into searchable calls,
operational health, incidents and carrier-ready diagnostics. It is self-hosted,
keeps customer data under customer control and never configures or controls the
customer's SBC.

</div>

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/VoxyWatch/publish/main/install.sh | sudo bash
```

Supported platforms:

- Debian 12/13
- Ubuntu 22.04/24.04 LTS
- Amazon Linux 2023
- x86_64 and ARM64

The installer selects the native signed artifact for the detected architecture,
verifies its SHA-256 and mandatory GPG signature, and configures the required
local services. Open `https://YOUR-HOST` after installation.

Initial credentials:

| Field | Value |
|---|---|
| Username | `admin` |
| Password | `voxywatch` |

Change the default password immediately in **Settings → Security → Users**.

## Capture inputs

VoxyWatch supports native HEP, optional SIPREC and opt-in Passive Mirror Capture.
HEP listens on UDP/TCP 9060 by default; restrict network access to approved
capture sources. The portal is served through HTTPS on TCP 443 and its local
backend port must not be exposed directly.

Configuration guides:

- [Platform and HEP validation](PLATFORM_AND_CAPTURE_VALIDATION.md)
- [Passive Mirror Capture](PASSIVE_MIRROR_CAPTURE.md)
- [HTTPS access](HTTPS_CONFIGURATION.md)
- [Initial setup channels](INITIAL_SETUP_CHANNELS.md)

## Optional integrations

- [MCP connection](MCP_SERVER.md)
- [LLM credential management](AI_CREDENTIALS.md)
- [Speech to text Beta](SPEECH_TO_TEXT_BETA.md)
- [Flash Call detection](FLASH_CALL_DETECTION.md)
- [Reports](REPORTS.md)

Optional integrations start disabled or require explicit administrator
configuration. VoxyWatch does not send raw SIP, RTP/audio or credentials to an
external AI automatically.

## Updates

VoxyWatch checks the signed public release manifest and shows the available
version inside the application. Updates are administrator initiated and
signature verification fails closed.

Detailed engineering history, architecture and internal implementation records
are not part of this public distribution repository.

Purchase and product information: https://voxywatch.com

Support: support@voxywatch.com
WhatsApp: https://wa.me/525592217665
