# VoxyWatch

**Self-hosted SIP capture & VoIP analysis portal.**  
Receives HEP traffic, analyzes calls, visualizes SIP flows, and reconstructs SIPREC stereo audio — all from a single binary, no cloud required.

---

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/VoxyWatch/publish/main/install.sh | sudo bash
```

Supports **Debian 11+**, **Ubuntu 20.04+**, **RHEL / CentOS / Rocky / AlmaLinux 8+**.  
The installer auto-detects your distro and installs the correct package.

After installation, open your browser at `http://YOUR-IP:3080`.

---

## What's Included

| Component | Description |
|---|---|
| `voxywatch-portal` | Node.js web portal & REST API (port 3080) |
| `hep_sniffer.py` | HEP v1/v2/v3 capture sniffer (ports 9060 UDP+TCP, 9910/9911 UDP) |
| `reconstruct_audio.py` | SIPREC stereo audio reconstruction (G.711 / G.722) |
| `generate_pcap.py` | Per-call PCAP export |
| `get-hwid.js` | Hardware ID tool for license activation |

---

## Features

- 📡 **Multi-source HEP capture** — Asterisk, Kamailio, OpenSIPS, FreeSWITCH, Oracle ACME, Sonus/Ribbon, AudioCodes, Cisco CUBE, RTPEngine, HEPlify, CaptAgent and more
- 📞 **SIP flow viewer** — full ladder diagram per call, SDP analysis, codec detection
- 📊 **Live dashboard** — ASR, NER, ACD, MOS, PDD, jitter, packet loss — all in real time
- 🗂 **CDR base** — sortable, filterable, exportable call records with caller/callee resolution
- 🔊 **Audio reconstruction** — stereo SIPREC playback directly in the browser
- 🌐 **5 languages** — ES · EN · PT · FR · DE
- 🔐 **Auth & RBAC** — JWT sessions, admin/operator/viewer roles, SSO via OIDC (Google, Microsoft, Okta, Keycloak, Auth0)
- 🏷️ **IP label directory** — map IPs and subnets to friendly names
- 💬 **AI assistant** — built-in chat proxy to OpenAI, Anthropic, Google or OpenRouter
- ♻️ **Auto-update** — update notification banner + one-click update from the portal web UI
- 🔒 **Fully self-hosted** — single binary, SQLite storage, no cloud dependency

---

## Free Tier

VoxyWatch works out of the box without a license:

| Limit | Free tier |
|---|---|
| Concurrent calls | 50 |
| CDR records | 1,000 |
| Features | All features included |

For production environments, purchase a license at **[voxywatch.com](https://voxywatch.com)**.

---

## Licensing

Licenses are hardware-bound (MAC + hostname) and available as:

| Plan | Duration |
|---|---|
| Monthly | 1 month |
| Semi-annual | 6 months |
| Annual | 1 year |
| Biennial | 2 years |

**To activate:**

```bash
# Copy your license file to the config directory
cp voxywatch.key /etc/voxywatch/license.key
chown root:voxywatch /etc/voxywatch/license.key
chmod 640 /etc/voxywatch/license.key
```

No restart required — the portal picks it up within seconds.

To get your **Hardware ID** (required when purchasing):

```bash
node /opt/voxywatch/get-hwid.js
```

Or find it in the portal under **Settings → License**.

---

## Manual Installation

If you prefer to install manually instead of using the install script:

**Debian / Ubuntu:**
```bash
curl -fsSL https://github.com/VoxyWatch/publish/releases/download/v1.2.0/voxywatch_1.2.0_amd64.deb -O
sudo dpkg -i voxywatch_1.2.0_amd64.deb
```

**RHEL / CentOS / Rocky / AlmaLinux:**
```bash
curl -fsSL https://github.com/VoxyWatch/publish/releases/download/v1.2.0/voxywatch-1.2.0-1.x86_64.rpm -O
sudo rpm -Uvh voxywatch-1.2.0-1.x86_64.rpm
```

---

## Verifying Package Integrity

Every release is signed with GPG. To verify before installing:

```bash
# Import the VoxyWatch release signing key (first time only)
curl -fsSL https://raw.githubusercontent.com/VoxyWatch/publish/main/voxywatch-release.gpg.pub | gpg --import

# Download package + signature
curl -fsSL https://github.com/VoxyWatch/publish/releases/download/v1.2.0/voxywatch_1.2.0_amd64.deb -O
curl -fsSL https://github.com/VoxyWatch/publish/releases/download/v1.2.0/voxywatch_1.2.0_amd64.deb.asc -O

# Verify
gpg --verify voxywatch_1.2.0_amd64.deb.asc voxywatch_1.2.0_amd64.deb
```

SHA-256 checksums are available in [SHA256SUMS](../../releases/download/v1.2.0/SHA256SUMS).

**Signing key fingerprint:**
```
80ED E252 3760 E622 FB97  BC15 4B21 BBC5 F215 26E3
VoxyWatch (Release Signing Key) <releases@voxywatch.com>
```

---

## Ports & Firewall

| Port | Protocol | Service |
|---|---|---|
| 3080 | TCP | Web portal |
| 9060 | UDP + TCP | HEP main capture |
| 9910 | UDP | HEP extra |
| 9911 | UDP | HEP extra |

```bash
# ufw example
ufw allow 3080/tcp
ufw allow 9060/udp && ufw allow 9060/tcp
ufw allow 9910/udp && ufw allow 9911/udp
```

---

## Upgrade

The portal shows an update banner automatically when a new version is available.  
Click **Update now** — the portal downloads, installs and restarts itself.

To upgrade manually:

```bash
curl -fsSL https://raw.githubusercontent.com/VoxyWatch/publish/main/install.sh | sudo bash
```

---

## Services

```bash
# Status
systemctl status voxywatch voxywatch-sniffer

# Logs
journalctl -fu voxywatch
journalctl -fu voxywatch-sniffer

# Restart
systemctl restart voxywatch
systemctl restart voxywatch-sniffer
```

---

## File Layout

```
/opt/voxywatch/          ← binaries & scripts (read-only)
/etc/voxywatch/          ← configuration & license key
/var/lib/voxywatch/      ← database, captures & audio (preserved on upgrade)
```

---

## Support & Licenses

→ **[voxywatch.com](https://voxywatch.com)**
