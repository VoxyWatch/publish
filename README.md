<div align="center">

<img src="assets/voxywatch-wordmark.png" alt="VoxyWatch" width="520">

### Voice-network observability, under your control

</div>

VoxyWatch is a self-hosted operations platform for call evidence, CDRs, statistics,
incidents, reports and permitted media analysis. It observes your network; it never
configures or controls your SBC. AI is optional, not a requirement to get started.

## Start here — your first installation

**[Open the six-step installation and setup guide](https://github.com/VoxyWatch/publish/blob/main/INITIAL_SETUP_CHANNELS.md)**

Prerequisites → capture → installation → minimum setup → first call → daily operation.

## Install and first access

Use the [official installation command](INITIAL_SETUP_CHANNELS.md#3-install-and-sign-in)
after checking the [supported platforms](INITIAL_SETUP_CHANNELS.md#1-check-prerequisites).
Open the HTTPS **Web portal** address printed by the installer;
see the [HTTPS guide](HTTPS_CONFIGURATION.md) for certificate trust and hostname setup.

**Initial credentials:** `admin` / `voxywatch` on fresh installations. Change the
password at first sign-in. Updates preserve existing accounts and passwords.
Keep portal access restricted to your intended management users/networks.

## Choose what your network can provide

- **HEP:** signaling and exported RTP/RTCP; signaling alone does not provide audio.
- **SIPREC:** supplied recording metadata/media, not the original SIP exchange or original-call ASR/NER/PDD.
- **Sniffer:** a mirrored interface; visible packets only, not automatic decryption.

Configure **Settings → Capture Sources** and your sender/mirror, then verify a test call.

## Operator guides

- [First installation and setup](INITIAL_SETUP_CHANNELS.md)
- [Platform and capture validation](PLATFORM_AND_CAPTURE_VALIDATION.md)
- [SIPREC validation](PLATFORM_AND_CAPTURE_VALIDATION.md#siprec-validation)
- [Passive Mirror Capture](PASSIVE_MIRROR_CAPTURE.md)
- [HTTPS access](HTTPS_CONFIGURATION.md) and [local CLI](CLI_REFERENCE.md)
- [API](API_REFERENCE.md) and [MCP connection](MCP_SERVER.md)
- [Speech to Text Beta](SPEECH_TO_TEXT_BETA.md) and [LLM credentials](AI_CREDENTIALS.md)
- [Reports](REPORTS.md) and [available features](FEATURES.md)

AI, MCP, recording and transcription need appropriate administrator configuration
and permission to process the selected data. Review privacy before enabling external providers.
Updates are administrator-initiated and verify signed releases.

Support: [support@voxywatch.com](mailto:support@voxywatch.com) ·
[WhatsApp +52 55 9221 7665](https://wa.me/525592217665) ·
[Plans and trial licenses](https://voxywatch.com/pricing/)
