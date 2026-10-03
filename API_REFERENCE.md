# VoxyWatch Integration API

This guide covers the stable HTTPS API for CDR search, call evidence, network
health, audio and Speech to Text Beta. The machine-readable contract is always
available from your own portal at `/api/v1/openapi.json`.

## Enable access

1. Open **Settings → Integration API**.
2. Enable the API and save the configuration.
3. Create a key with only the scopes the integration needs.
4. Add an IP allowlist and expiration whenever possible.
5. Copy the key when it is shown. VoxyWatch never displays it again.

Set these variables in your shell without storing the key in a script:

```bash
export VOXYWATCH_URL='https://voxywatch.example.com'
read -rsp 'VoxyWatch API key: ' VOXYWATCH_API_KEY; printf '\n'
vw_api() {
  printf 'Authorization: Bearer %s\n' "$VOXYWATCH_API_KEY" |
    curl --fail-with-body --header @- "$@"
}
```

The helper supplies the credential through standard input, not process arguments
or an exported environment variable. Do not use shell tracing (`set -x`) while
handling credentials. Use explicit `-d` bodies, not `--data @-`, because the helper
reserves standard input for the header. Run `unset VOXYWATCH_API_KEY` when finished.
Every authenticated request uses:

```bash
vw_api \
  "${VOXYWATCH_URL}/api/v1"
```

## Scopes

| Scope | Allows |
|---|---|
| `cdr:read` | Search CDRs, retrieve one CDR and read bounded call insights |
| `trace:read` | Retrieve the SIP signaling ladder |
| `metrics:read` | Read portal, traffic and trunk-health KPIs |
| `audio:read` | Download reconstructed WAV audio or SIP/RTP PCAP |
| `transcript:read` | Read one transcript or search stored transcripts |
| `transcript:generate` | Queue Speech to Text Beta for an eligible call |
| `transcript:export` | Create and download bounded transcript exports |

Audio, PCAP and transcript scopes expose sensitive call content. Grant them only
to authorized consumers. Speech to Text Beta must also be enabled and configured
locally before its routes can return content.

## CDRs and calls

Search by number, Call-ID or other supported text, outcome and time range:

```bash
vw_api -G \
  --data-urlencode 'q=52550001' \
  --data-urlencode 'from=2026-08-20T00:00:00Z' \
  --data-urlencode 'to=2026-08-21T00:00:00Z' \
  --data-urlencode 'limit=100' \
  "${VOXYWATCH_URL}/api/v1/cdrs"
```

The response contains `data` and, when more results exist, `next_cursor`. Pass
that opaque value as `cursor` on the next request. Use bounded time ranges and
pagination instead of attempting an unbounded browser-sized download.

For a Call-ID, URL-encode the complete identifier:

```bash
CALL_ID='complete-call-id@example-sbc'
ENCODED_ID="$(python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$CALL_ID")"

vw_api \
  "${VOXYWATCH_URL}/api/v1/cdrs/${ENCODED_ID}"
```

Related evidence uses the same encoded Call-ID:

```bash
# SIP ladder as JSON
vw_api \
  "${VOXYWATCH_URL}/api/v1/calls/${ENCODED_ID}/trace"

# Bounded Audio/RTP analysis and trends
vw_api \
  "${VOXYWATCH_URL}/api/v1/calls/${ENCODED_ID}/insights"

# Reconstructed stereo audio
vw_api \
  "${VOXYWATCH_URL}/api/v1/calls/${ENCODED_ID}/audio?channel=stereo" \
  --output call.wav

# SIP and correlated RTP evidence
vw_api \
  "${VOXYWATCH_URL}/api/v1/calls/${ENCODED_ID}/pcap" \
  --output call.pcap
```

Audio and PCAP can return `409` when eligible media is unavailable and `503`
when the protected media worker is busy. Do not retry either response in a tight
loop.

A signaling trace exceeding the installed safety limits returns `413`
(`trace_too_large`), not a partial ladder presented as complete. The current
limits are 5,000 messages and an 8 MiB payload budget per trace. SIPREC evidence
describes the recording session and metadata; it does not recreate unobserved
original signaling.

## Network metrics

```bash
vw_api "${VOXYWATCH_URL}/api/v1/health"
vw_api "${VOXYWATCH_URL}/api/v1/stats"
vw_api "${VOXYWATCH_URL}/api/v1/trunks/health"
```

These routes provide capture liveness, global KPIs and trunk health. They do not
control a customer SBC.

## Transcripts — Speech to Text Beta

Retrieve an existing transcript or queue generation:

```bash
vw_api \
  "${VOXYWATCH_URL}/api/v1/calls/${ENCODED_ID}/transcript"

vw_api -X POST \
  "${VOXYWATCH_URL}/api/v1/calls/${ENCODED_ID}/transcript"
```

A generation request returns `202 Accepted`; read the persistent identifier from
`body.job.id` in the JSON response and poll the canonical job route with
gradual backoff rather than rapid polling:

```bash
vw_api \
  "${VOXYWATCH_URL}/api/v1/transcription/jobs/${JOB_ID}"
```

Use the `transcript:generate` scope for this request. Some installed versions return
the portal-session URL `/api/transcription/jobs/...` in `Location`; an API-key client
must instead use the versioned route above with the returned `job.id`. Job polling
returns `{ "data": { ... }, "beta": true }`. A queued job is not a finished transcript.

Search stored transcripts by range, source, destination or Call-ID:

```bash
vw_api -G \
  --data-urlencode 'from=2026-08-20T00:00:00Z' \
  --data-urlencode 'to=2026-08-21T00:00:00Z' \
  --data-urlencode 'source=52550001' \
  --data-urlencode 'include=full' \
  --data-urlencode 'limit=25' \
  "${VOXYWATCH_URL}/api/v1/transcripts"
```

Replace `source` with `destination` or `call_id` as needed. `include=metadata`
avoids returning transcript text. Results use cursor pagination.

For a bounded bulk JSONL or CSV export, supply a required time range of at most
31 days and no more than 10,000 records:

```bash
vw_api -X POST \
  -H 'Content-Type: application/json' \
  -d '{"from":"2026-08-20T00:00:00Z","to":"2026-08-21T00:00:00Z","format":"csv","max_records":10000}' \
  "${VOXYWATCH_URL}/api/v1/transcript-exports"
```

The response is asynchronous. Set `EXPORT_ID` from `body.data.id`, then poll the
export route below using `transcript:export`. Export jobs are separate from
transcription-generation jobs and do not use `/api/v1/transcription/jobs`.

```bash
vw_api \
  "${VOXYWATCH_URL}/api/v1/transcript-exports/${EXPORT_ID}"

# Only after data.status is completed; use a new local filename.
vw_api \
  "${VOXYWATCH_URL}/api/v1/transcript-exports/${EXPORT_ID}/download" \
  --output transcripts-export.csv
```

Use `.jsonl` for a JSONL export. Files expire after 24 hours. The original export
request may also include `source`, `destination`, or `call_id`. A 404 can mean the
result is not ready, unavailable or expired; inspect the export job status first.

## Errors, limits and compatibility

- Errors use an HTTP status and a structured problem response. Handle `401`,
  `403`, `404`, `409`, `413`, `429`, `503` and timeouts explicitly.
- Respect rate-limit and retry headers. Use exponential backoff with jitter for
  transient responses.
- Never log keys, full transcripts, audio, phone numbers or Call-IDs.
- Keep TLS verification enabled. Rotate and revoke keys from Settings.
- Treat additive response fields as compatible and ignore unknown fields.
- Use `/api/v1/openapi.json` for the exact schema shipped by the installed
  version. The portal's local `/api/docs` explorer does not submit requests.

For help, contact `support@voxywatch.com`.
