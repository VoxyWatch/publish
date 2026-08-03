# HTTPS deployment

VoxyWatch uses HTTPS on TCP 443 for browser, API and remote MCP access. The
internal Node.js listener (3080 by default) is bound to `127.0.0.1` and is not a
customer-facing port on managed installations.

## Public domain

Use this mode when a public DNS name points to the server and inbound TCP 80
and 443 are reachable. Caddy obtains and renews the publicly trusted
certificate and redirects HTTP to HTTPS automatically.

```text
install.sh --https-mode public --https-host noc.example.com
```

DNS must resolve to the server before certificate issuance. TCP 80 is required
for the normal ACME HTTP challenge and redirect; users access only TCP 443.

## Private hostname or IP

Use this mode on an isolated LAN, VPN or private address. Caddy issues the
certificate from its internal CA.

```text
install.sh --https-mode internal --https-host voxywatch.example.internal
```

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

## Security contract

- HTTPS has no enable/disable switch in Settings.
- TCP 443 is the effective portal port shown in General and Diagnostics.
- Caddy forwards only to the loopback VoxyWatch listener.
- Public mode uses Caddy Automatic HTTPS; private mode uses `tls internal`.
- VoxyWatch does not disable certificate verification or expose private keys.
