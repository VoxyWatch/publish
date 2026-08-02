# LLM credential management

VoxyWatch supports one explicit credential source per selected LLM provider. It never falls back silently to a different source.

## Sources

### Encrypted VoxyWatch store

This is the recommended choice when an administrator enters the key in the web portal. The value is encrypted with AES-256-GCM in `voxywatch_ai_credentials.json`; the independent 256-bit master key and vault are permission-restricted. `voxywatch_settings.json` stores only `ai_key_source` and never the API key. The browser receives only a masked value ending in the final four characters.

### Protected Linux credential file

The service reads `voxywatch-llm-<provider>.key` from `$CREDENTIALS_DIRECTORY` when supplied by systemd, otherwise from `/etc/voxywatch/credentials/`. The installer creates the latter directory as `root:voxywatch` mode `0750`.

Provision it without exposing the value in process arguments or shell history:

```console
sudo voxywatch-ai-key set --provider openai --stdin --source system-credential
sudo voxywatch-ai-key status --provider openai --source system-credential
```

Append `--source system-credential` to `set` to use the protected Linux file. The command selects the provider/source and restarts only the portal if it is already running.

### Environment variable

Customers that manage service configuration externally can select `Environment variable` in the portal and provide either the value or a file path:

| Provider | Value variable | File variable |
|---|---|---|
| OpenAI | `OPENAI_API_KEY` | `OPENAI_API_KEY_FILE` |
| Anthropic | `ANTHROPIC_API_KEY` | `ANTHROPIC_API_KEY_FILE` |
| Google | `GOOGLE_API_KEY` | `GOOGLE_API_KEY_FILE` |
| OpenRouter | `OPENROUTER_API_KEY` | `OPENROUTER_API_KEY_FILE` |
| OpenRouter Free | `OPENROUTER_API_KEY` | `OPENROUTER_API_KEY_FILE` |
| DeepSeek | `DEEPSEEK_API_KEY` | `DEEPSEEK_API_KEY_FILE` |
| Groq | `GROQ_API_KEY` | `GROQ_API_KEY_FILE` |
| Perplexity | `PERPLEXITY_API_KEY` | `PERPLEXITY_API_KEY_FILE` |
| Custom | `VOXYWATCH_CUSTOM_LLM_API_KEY` | `VOXYWATCH_CUSTOM_LLM_API_KEY_FILE` |

The `_FILE` form is preferred because the process environment contains only a path. Environment values must be injected into `voxywatch.service` by the customer's Linux configuration; VoxyWatch does not copy them into its settings.

## Security boundary

The portal process must use the credential in memory when authenticating an HTTPS request to the chosen provider. VoxyWatch does not send the credential to its browser, telemetry, Sentry, support bundles or its own services. Linux `root` can still inspect or replace system-level credentials. Google credentials are sent in the `x-goog-api-key` header rather than a URL query parameter. **OpenRouter Free** shares the normal OpenRouter credential and fixes the model to `openrouter/free`; it is free routing, not credential-free access.

Old plaintext `ai_api_key` settings are migrated once into the encrypted store and removed atomically from normal settings.

## Model discovery before and after credentials

Settings can show a small, release-pinned recommended catalog before a credential exists. These entries are configuration presets, not a claim that the customer's account can use them. **Show recommended models** replaces any previous list and selected model; it never carries a stale identifier into the new recommendations. After the selected provider credential is available, **Load available models** asks that provider for the models authorized for the account and marks the result as provider-verified. OpenRouter retains its public catalog. Custom servers intentionally have no catalog controls because self-hosted APIs do not consistently expose model discovery; the administrator enters the exact model name configured in Ollama, vLLM or LM Studio.

**Test connection** never treats a recommended or public catalog as proof that a credential works. A missing or rejected credential is reported in the active UI language. Administrators can always type a model identifier manually; image, audio, embedding, realtime and robotics-specialized models are excluded from the assisted NOC list.
