<div align="center">

<img src="assets/voxywatch-wordmark.png" alt="VoxyWatch" width="520">

### Voice-network observability, under your control

</div>

VoxyWatch is a self-hosted operations platform for passive SIP/HEP evidence,
CDRs, health, incidents and permitted media analysis. It observes the network;
it never configures or controls a customer SBC.

## Install and first access

```bash
curl -fsSL https://raw.githubusercontent.com/VoxyWatch/publish/main/install.sh | sudo bash
```

Signed releases support Debian 12/13, Ubuntu 22.04/24.04 LTS and Amazon Linux
2023 on x86_64 and ARM64. Open `https://YOUR-HOST`, change the initial
administrator password, and complete the visible setup checks before admitting
live traffic.

Fresh installations use a private certificate authority. Trust its root on each
browser/API/MCP client, or configure a public hostname or your own certificate
in **Settings → Web Access**. See the [HTTPS guide](HTTPS_CONFIGURATION.md).

**Initial credentials:** **admin** / **voxywatch**. Change this password immediately in
**Settings → Security → Users** and restrict access to your management network.

## Capture choices

- **HEP** receives approved SIP/RTP/RTCP exporters on UDP or TCP 9060 by default.
- **SIPREC** is optional and off by default; configure its source and port range
  explicitly.
- **Passive Mirror Capture** is opt-in for a read-only SPAN/RSPAN/ERSPAN/VXLAN
  copy when an exporter is unavailable.

| Input | What you can analyze | Important limit |
|---|---|---|
| HEP | Original signaling and any exported media | Audio requires RTP actually exported and correlated |
| SIPREC | Recorded sessions, supplied metadata and eligible audio/transcripts | Metadata does not recreate original SIP messages or commercial ASR/NER/PDD |
| Mirror | Visible signaling/media from the mirrored interface | Mirroring cannot decode encrypted SIP/media |

Restrict capture inputs to approved source networks. The HTTPS portal uses TCP
443; do not expose its local backend.

## Operator guides

- [Platform and capture validation](PLATFORM_AND_CAPTURE_VALIDATION.md)
- [SIPREC validation](PLATFORM_AND_CAPTURE_VALIDATION.md#siprec-validation)
- [Passive Mirror Capture](PASSIVE_MIRROR_CAPTURE.md)
- [HTTPS access and certificate trust](HTTPS_CONFIGURATION.md)
- [Initial setup channels](INITIAL_SETUP_CHANNELS.md)
- [Integration API](API_REFERENCE.md)
- [MCP connection](MCP_SERVER.md)
- [Speech to Text Beta](SPEECH_TO_TEXT_BETA.md)
- [LLM credentials](AI_CREDENTIALS.md)
- [Reports](REPORTS.md) and [available features](FEATURES.md)

AI, MCP and transcription are optional and require explicit administrator
configuration. VoxyWatch does not automatically send raw SIP, RTP/audio or
credentials to an external provider.

## Updates

Updates are administrator initiated and verify the signed public release
manifest before installation. This repository contains operator documentation;
private engineering records and recovery procedures are not distributed here.

Support: [support@voxywatch.com](mailto:support@voxywatch.com) ·
[WhatsApp +52 55 9221 7665](https://wa.me/525592217665) ·
[Plans and trial licenses](https://voxywatch.com/pricing/)
