# Extending VoxyWatch safely

Extensions should use the documented HTTPS API or MCP interface and must respect
scopes, role checks, rate limits and privacy controls. Do not depend on private
files, internal services or undocumented endpoints.

Start with the installed API contract at `/api/v1/openapi.json`, use a least-
privilege API key, and keep TLS verification enabled. Treat response fields as
additive and ignore unknown fields for forward compatibility.

An extension must not configure a customer SBC, bypass access controls, export
credentials, or assume that audio, transcripts or traffic identifiers are
available. For MCP, see [MCP Server](../../MCP_SERVER.md).
