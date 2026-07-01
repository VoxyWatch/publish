# Extending VoxyWatch

## Development Principles

- Read existing code and module docs first.
- Preserve current patterns and contracts.
- Keep behavior configurable, bilingual and hardware-adaptive.
- Add new settings through the server-side whitelist and UI load/save paths.
- Prefer deterministic analysis for telecom workflows; use AI as explanation and assistance, not as the only decision source.

## Tests

Add focused tests for:

- New parser/analysis behavior.
- Settings merge/sanitize behavior.
- Public API contracts.
- UI anchors for visible features.
- Release/build packaging when adding served assets.

## Packaging

If a file must exist in installed systems, include it in:

- `build.sh` tarball staging.
- `install.sh` copy step.
- `package.json.pkg.assets` only if it must be served from the pkg virtual filesystem.

If a document must be public for customer AI assistants, sync it to the public publish repository during release.

## Release

Customer-facing changes require:

- Source changelog.
- Public changelog.
- Tests and invariants.
- Signed release.
- `latest.json` update.
- Public docs sync when docs changed.
