# HTTPS access and certificate trust

VoxyWatch serves the portal, API and remote MCP access over HTTPS on TCP 443.
Use **Settings → Web Access** to choose the access name and review certificate
status. HTTPS is always enabled; do not expose the local application backend.

## Address policy

**Settings → Web Access → Access policy** separates permitted addresses from
certificate trust. New managed installations accept incoming hostnames and IPs
by default; login, user permissions and TLS verification still apply.
Choose **Restricted** to accept only the primary address, configured private
aliases and up to32 explicit additional hostnames/IPs. Do not use URLs, ranges
or wildcards. Existing explicit restrictions and uploaded certificates are preserved.

Allowing an address does not issue a certificate for it. Use a name covered by
your certificate; an unknown name can still produce a browser trust warning.
For command-line administration, see the [CLI reference](CLI_REFERENCE.md).

## Public DNS name

Choose **Public DNS name** when an FQDN resolves to the server and TCP 80/443
are reachable. Enter the FQDN and apply the configuration. Confirm that the
certificate is valid from an external client before granting remote access.

## Private hostname or IP

Choose **Private IP / hostname** for a LAN, VPN or isolated network. Clients
must trust the installation's root certificate once. Export and distribute only
the public root certificate through your approved endpoint-management process;
never distribute private keys.

For the built-in private CA, the public root certificate is normally at
`/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt`. An administrator
distributes that certificate through a trusted channel. API clients can use their
trusted-CA setting, such as `curl --cacert root.crt`; do not disable TLS verification.

### Additional private addresses

For private access with the built-in CA, **Additional private IPs** lets an
administrator authorize up to 16 exact LAN/VPN addresses assigned to this server.
Enter IP addresses, not ranges, wildcards or URLs. Existing installations keep
their current access addresses until an administrator explicitly changes them.
All clients must still trust the same root certificate.

Additional addresses are not available with public DNS or an uploaded certificate.
Remove them before switching certificate modes. An unconfigured address can
produce a certificate error or an explicit address-not-configured response; use
the configured portal address to review Web Access settings.

After upgrading an older installation, apply additional addresses from Web Access
if needed. The first update alone may preserve the previous routing configuration.

## Certificate upload and operation

In **Settings → Web Access**, upload the approved PEM certificate chain and its
matching private key for the configured hostname. Apply and check the result from
a second browser/client. The key belongs only in that protected form, never in chat,
email or tickets. Keep TLS verification enabled in browsers, API clients and MCP
clients. A trust warning is a client-security signal to resolve, not an error to
bypass.

Restrict TCP 443 to intended users and management networks. A public DNS name,
certificate and firewall rule are separate requirements. SSO/OIDC login is a
roadmap item, not an active Web Access setting.
