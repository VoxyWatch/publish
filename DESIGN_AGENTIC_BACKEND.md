# Agentic Backend Design

VoxyWatch uses an evidence-first agentic architecture. The capture, parser, database,
CDR projection, SIP analysis, RTP metrics, fraud rules and incident engine remain
deterministic. LLMs and agent runtimes explain and orchestrate read-only tools; they do
not own the hot path and never touch the customer's SBC.

## Layers

1. **Deterministic core**
   - HEP/SIP/RTP capture and storage.
   - CDR, quality score, fraud, trunk health, incidents, readiness and support bundles.
   - This layer works without AI.

2. **Read-only tool contract**
   - `GET /api/ai/agent-tools` lists allowlisted tools.
   - `POST /api/ai/agent-tools/:name/run` executes one read-only tool.
   - Tool execution is rate-limited like AI chat to avoid accidental loops or cost/CPU storms.
   - Built-in chat, future ADK sidecars, MCP bridges and support automations should use
     this contract instead of scraping internal functions or database tables.

3. **Conversation memory**
   - Chat sessions are stored per user in `voxywatch_ai_chats.json`.
   - The browser sends only the new message plus `chat_id`.
   - The server loads a bounded context window before calling the LLM.
   - Users can create, reopen and delete their own chat sessions.

4. **User profile behavior**
   - `users[].ai_lang` controls the user's AI language.
   - `users[].ai_prompt` stores how the AI should work with that user.
   - Profile preferences are lower priority than safety, privacy, technical evidence and
     VoxyWatch's rule that it only observes the customer's network.

5. **Future ADK sidecar**
   - ADK can run as a separate service/process and call the agent-tools API.
   - The sidecar may orchestrate domain agents such as SIP Expert, Fraud Analyst,
     RTP/Audio Expert, Capacity Advisor and Release Validator.
   - ADK should not receive direct database credentials or filesystem access unless a
     future design explicitly scopes and audits that access.

## Recommended Domain Agents

| Agent | Inputs | Output |
|-------|--------|--------|
| SIP Expert | SIP flow, CDR, SIP compliance analysis | RFC/signaling diagnosis and likely responsible side. |
| Fraud Analyst | Fraud rules, countries, trunks, originators, call velocity | Fraud suspicion, evidence and escalation guidance. |
| RTP/Audio Expert | MOS, jitter, loss, SSRC/media status, audio reconstruction status | Voice quality diagnosis and capture-vs-network distinction. |
| Traffic Statistics | Rollups, trunk health, baseline, active calls | Trend explanation and capacity/business summary. |
| Incident Investigator | Incident evidence, runbooks, similar cases | Root-cause hypothesis, confidence, scope and recommended action. |
| Platform Readiness | Operational health, deployment, onboarding, heavy jobs, hardware | Market/deployment readiness summary. |
| Release Validator | Version, latest manifest, signatures, deployment status | Update safety and validation status. |

## Guardrails

- Tools are read-only by default.
- No tool may control the customer's SBC.
- Any tool that starts a service, changes settings or performs a deploy must be explicitly
  separated from the read-only catalog and role-gated.
- LLM output is advisory; incidents, alarms and metrics must be backed by deterministic
  evidence.
- Context sent to LLMs must be bounded and redacted. Do not include secrets, API keys,
  license material, raw RTP payloads or full settings.
- Custom system prompts are admin-only. Normal users configure style through the lower
  priority profile prompt.
