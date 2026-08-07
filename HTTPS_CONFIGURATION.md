# HTTPS deployment

VoxyWatch uses HTTPS on TCP 443 for browser, API and remote MCP access. The
internal Node.js listener (3080 by default) is bound to `127.0.0.1` and is not a
customer-facing port on managed installations.

Fresh installations start on the detected private IP/hostname with Caddy's
internal CA. The installer does not ask for a DNS name. This keeps installation
non-blocking and leaves the public access decision in **Settings → Web Access**.

## Public domain

Use this mode when a public DNS name points to the server and inbound TCP 80
and 443 are reachable. Caddy obtains and renews the publicly trusted
certificate and redirects HTTP to HTTPS automatically.

In **Settings → Web Access**, select **Public DNS name**, enter only the FQDN
(for example `noc.example.com`) and apply. The portal submits a bounded request
to a fixed root-owned systemd helper. The helper validates DNS, refuses to edit
an unmanaged Caddyfile, and rolls back Caddy, VoxyWatch configuration and its
service override if validation, reload or restart fails.

DNS must resolve to the server before certificate issuance. TCP 80 is required
for the normal ACME HTTP challenge and redirect; users access only TCP 443.

## Private hostname or IP

Use this mode on an isolated LAN, VPN or private address. Caddy issues the
certificate from its internal CA.

In **Settings → Web Access**, select **Private IP / hostname**, enter the
address and apply.

Each browser, API client and MCP client must trust Caddy's root certificate
once. With the official Debian package it is stored under Caddy's data
directory, normally:

```text
/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt
```

Distribute only `root.crt`; never distribute any private key. A client that
does not trust this root will correctly report a certificate trust error.

## Existing installations

A normal signed VoxyWatch update preserves the installed Caddy version and
configuration. It never adds or upgrades an external reverse proxy. Migrate an
older installation in a planned window by explicitly selecting a mode and
using the controlled dependency refresh path. The installer refuses to
overwrite an unrelated Caddy configuration.

Platform readiness classifies a backend listener outside loopback as critical.
Legacy compatibility remains reachable during an ordinary update so an unknown
external proxy topology is not broken silently, but it is not considered a
secure or market-ready state until the installation is migrated deliberately.

Automation and recovery retain the advanced installer options
`--https-mode public|internal --https-host <host>`. They are not part of the
normal interactive installation.

## Security contract

- HTTPS has no enable/disable switch in Settings.
- Web Access contains authentication/session, HTTPS/certificate state and SSO.
- TCP 443 is the effective portal port; fixed product/port facts do not occupy General.
- Caddy forwards only to the loopback VoxyWatch listener.
- Public mode uses Caddy Automatic HTTPS; private mode uses `tls internal`.
- VoxyWatch does not disable certificate verification or expose private keys.
- The portal never writes Caddy as root. It can only start
  `voxywatch-apply-web-access.service`, whose root-owned helper validates a
  two-field request and accepts only a Caddyfile marked as managed by VoxyWatch.
- `configuration_readiness.checks[].id=https` is the machine-readable security
  signal; a non-loopback HTTP backend is always critical.
