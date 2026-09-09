# LLM credential management

VoxyWatch supports one explicit credential source per selected LLM provider. It never falls back silently to a different source.

Open **Settings → LLM**, choose the provider (or Custom), select a credential
source, enter the required fields, Save, and use **Test connection**. Only
administrators change these system-wide settings.

## Sources

### Encrypted VoxyWatch store

This is the recommended choice when an administrator enters the key in the web portal. VoxyWatch stores it securely and never returns the value to the browser; the UI shows only a masked confirmation.

### Advanced CLI compatibility

Existing system-managed credential integrations can use the secure CLI. This is
not an additional credential-source option in the simplified web menu.

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

VoxyWatch uses a selected credential only for the chosen provider connection. It never sends credentials to the browser, telemetry, support material or another provider. **OpenRouter Free** uses the normal OpenRouter credential; it is not credential-free access.

## Model discovery before and after credentials

Recommended models are configuration suggestions, not proof of account access.
**Show recommended models** replaces the previous list; **Load available models**
queries the selected connection when supported. Custom endpoints may expose a
compatible model catalog; otherwise enter the exact model identifier supplied by
your server. Supply its API base URL, not merely a web-chat page. Test the same
URL, model and credential that you intend to save. For Custom-model knowledge
materials, contact support@voxywatch.com without sending credentials.

**Test connection** never treats a recommended or public catalog as proof that a
credential works. The provider and installed release determine compatible models.
Speech-to-text credentials are configured separately in **Settings → Transcription**;
optional expert interpretation uses the main LLM connection.
