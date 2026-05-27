#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# VoxyWatch — Installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/VoxyWatch/publish/main/install.sh | sudo bash
#   — or —
#   sudo bash install.sh [--version 1.2.10] [--port 3080]
#
# Supports: Debian 11+, Ubuntu 20.04+, RHEL / CentOS / Rocky / AlmaLinux 8+
# ─────────────────────────────────────────────────────────────────────────────

# All logic inside main() — a partial download won't execute anything.
main() {
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
GITHUB_ORG="VoxyWatch"
GITHUB_REPO="publish"
VERSION_MANIFEST="https://raw.githubusercontent.com/${GITHUB_ORG}/${GITHUB_REPO}/main/latest.json"
INSTALL_URL="https://raw.githubusercontent.com/${GITHUB_ORG}/${GITHUB_REPO}/main/install.sh"
RELEASES_BASE="https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/releases/download"

INSTALL_DIR="/opt/voxywatch"
DATA_DIR="/var/lib/voxywatch"
CONF_DIR="/etc/voxywatch"
CONF_FILE="${CONF_DIR}/voxywatch.conf"
SERVICE_USER="voxywatch"

# ── Colors ────────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; NC=''
fi
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $1"; }
err()  { echo -e "${RED}  ✗${NC} $1"; exit 1; }
info() { echo -e "${CYAN}  →${NC} $1"; }

echo ""
echo "══════════════════════════════════════════════"
echo "   VoxyWatch — Installer"
echo "══════════════════════════════════════════════"
echo ""

# ── Pre-flight checks ─────────────────────────────────────────────────────────
[ "$EUID" -ne 0 ] && err "Must run as root:  curl -fsSL https://raw.githubusercontent.com/${GITHUB_ORG}/${GITHUB_REPO}/main/install.sh | sudo bash"
command -v curl    &>/dev/null || err "curl is required:  apt install curl   or   yum install curl"
command -v python3 &>/dev/null || err "python3 is required:  apt install python3   or   yum install python3"

# ── Parse arguments ───────────────────────────────────────────────────────────
VERSION=""
PORT_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --port)    PORT_ARG="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# ── Fetch latest version and asset info ───────────────────────────────────────
if [ -z "$VERSION" ]; then
  info "Fetching latest version..."
  MANIFEST_JSON=$(curl -fsSL --max-time 15 "$VERSION_MANIFEST" 2>/dev/null \
    || err "Could not fetch version manifest from ${VERSION_MANIFEST}")
  VERSION=$(echo "$MANIFEST_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['version'])" 2>/dev/null \
    || err "Could not parse version from manifest")
  EXPECTED_SHA256=$(echo "$MANIFEST_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin).get('linux_x64',{}).get('sha256',''))" 2>/dev/null || echo "")
else
  # Version specified manually — fetch its sha256 from the manifest anyway
  MANIFEST_JSON=$(curl -fsSL --max-time 15 "$VERSION_MANIFEST" 2>/dev/null || echo "{}")
  EXPECTED_SHA256=$(echo "$MANIFEST_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin).get('linux_x64',{}).get('sha256',''))" 2>/dev/null || echo "")
fi
ok "Version to install: v${VERSION}"

# ── Port selection ────────────────────────────────────────────────────────────
if [ -n "$PORT_ARG" ]; then
  PORT="$PORT_ARG"
else
  echo ""
  if [ -e /dev/tty ]; then
    printf "  ${BOLD}Web portal port${NC} [3080]: "
    read -r PORT_INPUT </dev/tty 2>/dev/null || PORT_INPUT=""
  else
    PORT_INPUT=""
  fi
  PORT="${PORT_INPUT:-3080}"
fi
if ! echo "$PORT" | grep -qE '^[0-9]+$' || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
  warn "Invalid port '${PORT}' — using default 3080"
  PORT="3080"
fi
ok "Web portal port: ${PORT}"
echo ""

# ── Download tarball ──────────────────────────────────────────────────────────
TARBALL_NAME="voxywatch-v${VERSION}-linux-x64.tar.gz"
TARBALL_DIR="voxywatch-v${VERSION}-linux-x64"
DOWNLOAD_URL="${RELEASES_BASE}/v${VERSION}/${TARBALL_NAME}"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

info "Downloading ${TARBALL_NAME}..."
curl -fsSL --progress-bar "$DOWNLOAD_URL" -o "${TMPDIR}/${TARBALL_NAME}" \
  || err "Failed to download ${DOWNLOAD_URL}"
ok "Download complete: $(du -sh "${TMPDIR}/${TARBALL_NAME}" | cut -f1)"

# ── Verify SHA-256 ────────────────────────────────────────────────────────────
ACTUAL_SHA256=$(python3 -c "import hashlib; print(hashlib.sha256(open('${TMPDIR}/${TARBALL_NAME}','rb').read()).hexdigest())")
if [ -n "$EXPECTED_SHA256" ] && [ "$EXPECTED_SHA256" != "$ACTUAL_SHA256" ]; then
  err "SHA-256 mismatch — package may be corrupted or tampered with.
    Expected: ${EXPECTED_SHA256}
    Got:      ${ACTUAL_SHA256}"
fi
ok "SHA-256 verified: ${ACTUAL_SHA256:0:16}…"

# ── Extract ───────────────────────────────────────────────────────────────────
info "Extracting..."
tar -xzf "${TMPDIR}/${TARBALL_NAME}" -C "$TMPDIR"
EXTRACTED="${TMPDIR}/${TARBALL_DIR}"
[ -d "$EXTRACTED" ] || err "Unexpected tarball layout — expected directory: ${TARBALL_DIR}"
ok "Extracted OK"

# ── Create service user ───────────────────────────────────────────────────────
if ! id "$SERVICE_USER" &>/dev/null; then
  info "Creating system user '${SERVICE_USER}'..."
  useradd --system --no-create-home --shell /usr/sbin/nologin "$SERVICE_USER"
  ok "User '${SERVICE_USER}' created"
else
  ok "User '${SERVICE_USER}' already exists"
fi

# ── Stop existing services (ignore errors if not installed yet) ───────────────
systemctl stop voxywatch voxywatch-sniffer 2>/dev/null || true

# ── Create directories ────────────────────────────────────────────────────────
info "Setting up directories..."
mkdir -p "$INSTALL_DIR" "$DATA_DIR" "$CONF_DIR"

# INSTALL_DIR: root owns, readable by voxywatch
chown root:voxywatch "$INSTALL_DIR"
chmod 750 "$INSTALL_DIR"

# DATA_DIR: voxywatch owns (binario escribe capturas, DB, settings aquí)
chown voxywatch:voxywatch "$DATA_DIR"
chmod 750 "$DATA_DIR"

# CONF_DIR: root:voxywatch — el proceso puede escribir license.key desde la GUI
chown root:voxywatch "$CONF_DIR"
chmod 775 "$CONF_DIR"
ok "Directories ready"

# ── Install files ─────────────────────────────────────────────────────────────
info "Installing files to ${INSTALL_DIR}..."
install -o root -g voxywatch -m 750 "${EXTRACTED}/voxywatch-portal"   "${INSTALL_DIR}/voxywatch-portal"
install -o root -g voxywatch -m 640 "${EXTRACTED}/hep_sniffer.py"     "${INSTALL_DIR}/hep_sniffer.py"
install -o root -g voxywatch -m 640 "${EXTRACTED}/get-hwid.js"        "${INSTALL_DIR}/get-hwid.js"
install -o root -g voxywatch -m 640 "${EXTRACTED}/migrate_to_db.js"   "${INSTALL_DIR}/migrate_to_db.js" 2>/dev/null || true
install -o root -g voxywatch -m 640 "${EXTRACTED}/generate_pcap.py"   "${INSTALL_DIR}/generate_pcap.py" 2>/dev/null || true
install -o root -g voxywatch -m 640 "${EXTRACTED}/reconstruct_audio.py" "${INSTALL_DIR}/reconstruct_audio.py" 2>/dev/null || true
install -o root -g root      -m 644 "${EXTRACTED}/WIKI_INTEGRATION.md" "${INSTALL_DIR}/WIKI_INTEGRATION.md" 2>/dev/null || true

# Frontend assets — van junto al binario en INSTALL_DIR.
# El binario los sirve desde path.dirname(process.execPath) = /opt/voxywatch/
install -o root -g voxywatch -m 640 "${EXTRACTED}/styles.css" "${INSTALL_DIR}/styles.css" 2>/dev/null || true
install -o root -g voxywatch -m 640 "${EXTRACTED}/app.js"     "${INSTALL_DIR}/app.js"     2>/dev/null || true
ok "Files installed"

# ── Write config file ─────────────────────────────────────────────────────────
cat > "$CONF_FILE" << EOF
# VoxyWatch configuration
# Generated by installer on $(date -u '+%Y-%m-%d %H:%M UTC')
PORT=${PORT}
VERSION=${VERSION}
EOF
chown root:voxywatch "$CONF_FILE"
chmod 640 "$CONF_FILE"
ok "Config written: ${CONF_FILE}"

# ── Install systemd unit files ────────────────────────────────────────────────
info "Installing systemd units..."

cat > /etc/systemd/system/voxywatch.service << EOF
[Unit]
Description=VoxyWatch SIP Capture Portal
Documentation=https://voxywatch.com/docs
After=network.target voxywatch-sniffer.service

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_USER}
WorkingDirectory=${DATA_DIR}
ExecStart=${INSTALL_DIR}/voxywatch-portal
Environment=PORT=${PORT}
Environment=VOXYWATCH_DATA_DIR=${DATA_DIR}
Restart=always
RestartSec=5
LimitNOFILE=65536
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths=${DATA_DIR} ${CONF_DIR} /tmp
PrivateTmp=yes
StandardOutput=journal
StandardError=journal
SyslogIdentifier=voxywatch

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/voxywatch-sniffer.service << EOF
[Unit]
Description=VoxyWatch HEP Sniffer (HEPv1/v2/v3)
Documentation=https://voxywatch.com/docs
After=network.target
Before=voxywatch.service

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_USER}
WorkingDirectory=${DATA_DIR}
ExecStart=/usr/bin/python3 -u ${INSTALL_DIR}/hep_sniffer.py --quiet
Environment=VOXYWATCH_DATA_DIR=${DATA_DIR}
Restart=always
RestartSec=5
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths=${DATA_DIR}
StandardOutput=journal
StandardError=journal
SyslogIdentifier=voxywatch-sniffer

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable voxywatch voxywatch-sniffer
ok "Systemd units installed and enabled"

# ── Install auto-updater ──────────────────────────────────────────────────────
info "Setting up auto-updater..."

cat > "${INSTALL_DIR}/voxywatch-update.sh" << 'UPDATER_SCRIPT'
#!/bin/bash
# VoxyWatch Auto-Updater — called daily by voxywatch-update.timer
set -euo pipefail

MANIFEST_URL="https://raw.githubusercontent.com/VoxyWatch/publish/main/latest.json"
INSTALL_URL="https://raw.githubusercontent.com/VoxyWatch/publish/main/install.sh"
CONF_FILE="/etc/voxywatch/voxywatch.conf"
LOG_TAG="voxywatch-update"

log()  { echo "[$LOG_TAG] $*"; logger -t "$LOG_TAG" "$*" 2>/dev/null || true; }
warn() { echo "[$LOG_TAG] WARNING: $*"; logger -t "$LOG_TAG" "WARNING: $*" 2>/dev/null || true; }

PORT="3080"
CURRENT_VERSION=""
if [ -f "$CONF_FILE" ]; then
  PORT=$(grep -oP '(?<=^PORT=)\S+' "$CONF_FILE" 2>/dev/null || echo "3080")
  CURRENT_VERSION=$(grep -oP '(?<=^VERSION=)\S+' "$CONF_FILE" 2>/dev/null || echo "")
fi

if [ -z "$CURRENT_VERSION" ]; then
  warn "Could not determine installed version. Skipping update check."
  exit 0
fi

LATEST_VERSION=$(curl -fsSL --max-time 15 "$MANIFEST_URL" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['version'])" 2>/dev/null || echo "")

if [ -z "$LATEST_VERSION" ]; then
  warn "Could not fetch version manifest. Skipping update check."
  exit 0
fi

log "Installed: v${CURRENT_VERSION} | Latest: v${LATEST_VERSION}"

if [ "$(printf '%s\n%s' "$CURRENT_VERSION" "$LATEST_VERSION" | sort -V | tail -1)" = "$CURRENT_VERSION" ]; then
  log "Already up to date (v${CURRENT_VERSION})."
  exit 0
fi

log "New version available: v${LATEST_VERSION} — starting update..."
curl -fsSL --max-time 60 "$INSTALL_URL" | bash -s -- --version "$LATEST_VERSION" --port "$PORT"
log "Update to v${LATEST_VERSION} completed successfully."
UPDATER_SCRIPT

chmod 755 "${INSTALL_DIR}/voxywatch-update.sh"

cat > /etc/systemd/system/voxywatch-update.service << 'EOF'
[Unit]
Description=VoxyWatch Auto-Updater
Documentation=https://voxywatch.com/docs
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/opt/voxywatch/voxywatch-update.sh
StandardOutput=journal
StandardError=journal
SyslogIdentifier=voxywatch-update
EOF

cat > /etc/systemd/system/voxywatch-update.timer << 'EOF'
[Unit]
Description=VoxyWatch Daily Update Check
Documentation=https://voxywatch.com/docs

[Timer]
OnCalendar=daily
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now voxywatch-update.timer
ok "Auto-updater installed (daily check)"

# ── Start services ────────────────────────────────────────────────────────────
info "Starting services..."
systemctl start voxywatch-sniffer
systemctl start voxywatch
ok "Services started"

# ── Get HWID ──────────────────────────────────────────────────────────────────
SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "YOUR-IP")
HWID=""
if command -v node &>/dev/null && [ -f "${INSTALL_DIR}/get-hwid.js" ]; then
  HWID=$(node "${INSTALL_DIR}/get-hwid.js" 2>/dev/null | grep -oP '[0-9a-f]{32}' | head -1 || true)
fi

# ── Final summary ─────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════"
echo -e "  ${GREEN}✓ VoxyWatch v${VERSION} installed successfully${NC}"
echo "══════════════════════════════════════════════"
echo ""
echo -e "  ${BOLD}Web portal:${NC}"
echo -e "  ${CYAN}http://${SERVER_IP}:${PORT}${NC}"
echo ""
echo -e "  ${BOLD}Default credentials:${NC}"
echo "    Username: admin"
echo "    Password: voxywatch"
echo -e "  ${YELLOW}  ⚠  Change the default password: Settings → Security → Users${NC}"
echo ""
if [ -n "$HWID" ]; then
  echo -e "  ${BOLD}Hardware ID${NC} (needed to purchase a license):"
  echo -e "  ${CYAN}${HWID}${NC}"
  echo ""
fi
echo -e "  ${BOLD}License${NC} (optional — free tier works without one):"
echo -e "  Purchase: ${CYAN}https://voxywatch.com${NC}"
echo "    Once received, upload from the portal: Settings → License"
echo "    Or manually: cp your_license.key ${CONF_DIR}/license.key"
echo ""
echo -e "  ${BOLD}Service logs:${NC}"
echo "    journalctl -fu voxywatch"
echo "    journalctl -fu voxywatch-sniffer"
echo ""
echo -e "  ${BOLD}Auto-updates:${NC} enabled — daily check via systemd timer"
echo "    Status:  systemctl status voxywatch-update.timer"
echo "    Run now: systemctl start voxywatch-update.service"
echo ""

} # end of main()

main "$@"
