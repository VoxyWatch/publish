# Runbook: Audio Reconstruction

## Symptoms

- Audio button reports no audio.
- Reconstruction job fails.
- PCAP/audio/DTMF jobs are slow or queued.
- One-way or missing RTP appears in a call.

## First Checks

- Whether RTP was sent with usable Call-ID correlation.
- Segment index availability.
- Heavy job queue status.
- Retention settings.
- Whether capture path saw RTP for both legs.

## Likely Domains

- `integration-source`: SBC/probe did not send Call-ID in HEP RTP, SSRC mapping is incomplete or media is absent.
- `configuration`: retention or recording scope excludes needed media.
- `product-code`: reconstruction parser or job handling bug.

## Validation

A product fix should include controlled failure behavior for unknown SSRC cases and must not scan unbounded segment files.
