# Runbook: Update Failed

## Symptoms

- Settings -> Update says the update must be done by CLI.
- Update button fails.
- Installer succeeds but portal cannot start the apply-update service.
- Signature or SHA verification fails.

## First Checks

- Installed version and latest manifest version.
- Service-control enabled state.
- Polkit/systemd authorization for VoxyWatch units.
- Release asset URL, SHA and signature.
- Network egress to GitHub raw and release downloads.

## Likely Domains

- `packaging-release`: bad manifest, missing asset, SHA/signature mismatch.
- `deployment-os`: systemd/polkit permission or network egress.
- `configuration`: service-control not enabled.

## Validation

The update path is healthy when the portal can start the scoped update unit and the installer verifies the published tarball and signature.
