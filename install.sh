#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# VoxyWatch — Installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/VoxyWatch/publish/main/install.sh | sudo bash
#   — or —
#   sudo bash install.sh [--version 1.2.0] [--port 3080]
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
GPG_KEY_URL="https://raw.githubusercontent.com/${GITHUB_ORG}/${GITHUB_REPO}/main/voxywatch-release.gpg.pub"
RELEASES_BASE="https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/releases/download"
INSTALL_URL="https://raw.githubusercontent.com/${GITHUB_ORG}/${GITHUB_REPO}/main/install.sh"
CONF_FILE="/etc/voxywatch/voxywatch.conf"

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
[ "$EUID" -ne 0 ] && err "Must run as root:  curl -fsSL https://raw.githubusercontent.com/VoxyWatch/publish/main/install.sh | sudo bash"

command -v curl    &>/dev/null || err "curl is required:  apt install curl   or   yum install curl"
command -v python3 &>/dev/null || err "python3 is required:  apt install python3   or   yum install python3"
command -v gpg     &>/dev/null || { warn "gpg not available — package signature verification will be skipped"; GPG_AVAILABLE=false; }
GPG_AVAILABLE="${GPG_AVAILABLE:-true}"

# ── Detect distribution ───────────────────────────────────────────────────────
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_ID_LIKE="${ID_LIKE:-}"
  else
    DISTRO_ID="unknown"; DISTRO_ID_LIKE=""
  fi

  case "$DISTRO_ID" in
    debian|ubuntu|linuxmint|pop|kali|raspbian)
      PKG_TYPE="deb"
      PKG_MGR="apt-get"
      ;;
    rhel|centos|fedora|rocky|almalinux|ol|amzn)
      PKG_TYPE="rpm"
      PKG_MGR=$(command -v dnf &>/dev/null && echo "dnf" || echo "yum")
      ;;
    *)
      if echo "$DISTRO_ID_LIKE" | grep -qE "debian|ubuntu"; then
        PKG_TYPE="deb"; PKG_MGR="apt-get"
      elif echo "$DISTRO_ID_LIKE" | grep -qE "rhel|fedora|centos"; then
        PKG_TYPE="rpm"; PKG_MGR=$(command -v dnf &>/dev/null && echo "dnf" || echo "yum")
      else
        err "Unsupported distribution: ${DISTRO_ID}. Supported: Debian/Ubuntu and RHEL/CentOS/Rocky/AlmaLinux."
      fi
      ;;
  esac
  ok "Distribution detected: ${DISTRO_ID} → .${PKG_TYPE} package"
}

detect_distro

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

# ── Fetch latest version ──────────────────────────────────────────────────────
if [ -z "$VERSION" ]; then
  info "Fetching latest version..."
  VERSION=$(curl -fsSL "$VERSION_MANIFEST" \
    | python3 -c "import json,sys; print(json.load(sys.stdin)['version'])" 2>/dev/null \
    || err "Could not fetch version manifest from ${VERSION_MANIFEST}")
fi
ok "Version to install: v${VERSION}"

# ── Port selection ────────────────────────────────────────────────────────────
if [ -n "$PORT_ARG" ]; then
  PORT="$PORT_ARG"
else
  # Interactive prompt — works even when piped via curl (reads from /dev/tty)
  echo ""
  if [ -e /dev/tty ]; then
    printf "  ${BOLD}Web portal port${NC} [3080]: "
    read -r PORT_INPUT </dev/tty 2>/dev/null || PORT_INPUT=""
  else
    PORT_INPUT=""
  fi
  PORT="${PORT_INPUT:-3080}"
fi

# Validate
if ! echo "$PORT" | grep -qE '^[0-9]+$' || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
  warn "Invalid port '${PORT}' — using default 3080"
  PORT="3080"
fi
ok "Web portal port: ${PORT}"
echo ""

# ── Package filenames ─────────────────────────────────────────────────────────
if [ "$PKG_TYPE" = "deb" ]; then
  PKG_FILE="voxywatch_${VERSION}_amd64.deb"
  INSTALL_CMD="${PKG_MGR} install -y"   # apt-get resolves all dependencies automatically
else
  PKG_FILE="voxywatch-${VERSION}-1.x86_64.rpm"
  INSTALL_CMD="${PKG_MGR} install -y"   # dnf/yum resolve all dependencies automatically
fi

DOWNLOAD_URL="${RELEASES_BASE}/v${VERSION}/${PKG_FILE}"
SIG_URL="${DOWNLOAD_URL}.asc"

# ── Download package & signature ──────────────────────────────────────────────
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

info "Downloading ${PKG_FILE}..."
curl -fsSL --progress-bar "$DOWNLOAD_URL" -o "${TMPDIR}/${PKG_FILE}" \
  || err "Failed to download ${DOWNLOAD_URL}"
ok "Download complete: $(du -sh "${TMPDIR}/${PKG_FILE}" | cut -f1)"

# ── Verify SHA-256 checksum ───────────────────────────────────────────────────
info "Verifying SHA-256 checksum..."
curl -fsSL "${RELEASES_BASE}/v${VERSION}/SHA256SUMS" -o "${TMPDIR}/SHA256SUMS" 2>/dev/null || {
  warn "SHA256SUMS not available — skipping checksum verification"
}

if [ -f "${TMPDIR}/SHA256SUMS" ]; then
  cd "$TMPDIR"
  if grep "$PKG_FILE" SHA256SUMS | sha256sum --check --status; then
    ok "SHA-256 checksum verified"
  else
    err "SHA-256 checksum FAILED — package may be corrupted or tampered with"
  fi
  cd - > /dev/null
fi

# ── Verify GPG signature ──────────────────────────────────────────────────────
if [ "$GPG_AVAILABLE" = "true" ]; then
  info "Verifying GPG signature..."
  curl -fsSL "$GPG_KEY_URL" -o "${TMPDIR}/voxywatch.gpg.pub" 2>/dev/null && \
  curl -fsSL "$SIG_URL"     -o "${TMPDIR}/${PKG_FILE}.asc"   2>/dev/null || {
    warn "Could not download GPG signature — skipping verification"
    GPG_AVAILABLE=false
  }
fi

if [ "$GPG_AVAILABLE" = "true" ]; then
  GPG_KEYRING="${TMPDIR}/voxywatch-keyring.gpg"
  gpg --no-default-keyring --keyring "$GPG_KEYRING" \
      --import "${TMPDIR}/voxywatch.gpg.pub" &>/dev/null
  if gpg --no-default-keyring --keyring "$GPG_KEYRING" \
         --verify "${TMPDIR}/${PKG_FILE}.asc" "${TMPDIR}/${PKG_FILE}" &>/dev/null; then
    ok "GPG signature verified"
  else
    err "GPG signature INVALID — aborting installation. Download may be compromised."
  fi
fi

# ── Install package ───────────────────────────────────────────────────────────
info "Installing VoxyWatch v${VERSION}..."
$INSTALL_CMD "${TMPDIR}/${PKG_FILE}"
ok "Package installed"

# ── Apply port configuration ──────────────────────────────────────────────────
# Always write config file (used by auto-updater too)
mkdir -p /etc/voxywatch
# Asegurar que el usuario de servicio pueda escribir licencias desde la GUI
if id voxywatch &>/dev/null; then
  chown root:voxywatch /etc/voxywatch
  chmod 775 /etc/voxywatch
fi
cat > "$CONF_FILE" << EOF
# VoxyWatch configuration
# Generated by installer on $(date -u '+%Y-%m-%d %H:%M UTC')
PORT=${PORT}
VERSION=${VERSION}
EOF

# If port differs from service default (3080), create a systemd drop-in override
if [ "$PORT" != "3080" ]; then
  info "Applying port override → ${PORT}..."
  mkdir -p /etc/systemd/system/voxywatch.service.d
  cat > /etc/systemd/system/voxywatch.service.d/port.conf << EOF
[Service]
Environment=PORT=${PORT}
EOF
  systemctl daemon-reload
  ok "Port override applied"
fi

# ── Install auto-updater ──────────────────────────────────────────────────────
install_autoupdater() {
  info "Setting up auto-updater..."

  # Update script — runs daily via systemd timer
  cat > /opt/voxywatch/voxywatch-update.sh << 'UPDATER_SCRIPT'
#!/bin/bash
# VoxyWatch Auto-Updater — called daily by voxywatch-update.timer
set -euo pipefail

MANIFEST_URL="https://raw.githubusercontent.com/VoxyWatch/publish/main/latest.json"
INSTALL_URL="https://raw.githubusercontent.com/VoxyWatch/publish/main/install.sh"
CONF_FILE="/etc/voxywatch/voxywatch.conf"
LOG_TAG="voxywatch-update"

log()  { echo "[$LOG_TAG] $*"; logger -t "$LOG_TAG" "$*" 2>/dev/null || true; }
warn() { echo "[$LOG_TAG] WARNING: $*"; logger -t "$LOG_TAG" "WARNING: $*" 2>/dev/null || true; }

# Read current configuration
PORT="3080"
CURRENT_VERSION=""
if [ -f "$CONF_FILE" ]; then
  PORT=$(grep -oP '(?<=^PORT=)\S+' "$CONF_FILE" 2>/dev/null || echo "3080")
  CURRENT_VERSION=$(grep -oP '(?<=^VERSION=)\S+' "$CONF_FILE" 2>/dev/null || echo "")
fi

# Fallback: query package manager
if [ -z "$CURRENT_VERSION" ]; then
  if command -v dpkg &>/dev/null; then
    CURRENT_VERSION=$(dpkg -l voxywatch 2>/dev/null | awk '/^ii/{print $3}' | head -1 || echo "")
  elif command -v rpm &>/dev/null; then
    CURRENT_VERSION=$(rpm -q --queryformat '%{VERSION}' voxywatch 2>/dev/null || echo "")
  fi
fi

if [ -z "$CURRENT_VERSION" ]; then
  warn "Could not determine installed version. Skipping update check."
  exit 0
fi

# Fetch latest version from manifest
LATEST_VERSION=$(curl -fsSL --max-time 15 "$MANIFEST_URL" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['version'])" 2>/dev/null || echo "")

if [ -z "$LATEST_VERSION" ]; then
  warn "Could not fetch version manifest. Skipping update check."
  exit 0
fi

log "Installed: v${CURRENT_VERSION} | Latest: v${LATEST_VERSION}"

# Compare versions using sort -V (handles semver correctly)
if [ "$(printf '%s\n%s' "$CURRENT_VERSION" "$LATEST_VERSION" | sort -V | tail -1)" = "$CURRENT_VERSION" ]; then
  log "Already up to date (v${CURRENT_VERSION})."
  exit 0
fi

log "New version available: v${LATEST_VERSION} — starting update..."
curl -fsSL --max-time 60 "$INSTALL_URL" | bash -s -- --version "$LATEST_VERSION" --port "$PORT"
log "Update to v${LATEST_VERSION} completed successfully."
UPDATER_SCRIPT

  chmod 755 /opt/voxywatch/voxywatch-update.sh

  # Systemd service (one-shot, runs the update script)
  cat > /etc/systemd/system/voxywatch-update.service << 'EOF'
[Unit]
Description=VoxyWatch Auto-Updater
Documentation=https://voxywatch.com/wiki/
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/opt/voxywatch/voxywatch-update.sh
StandardOutput=journal
StandardError=journal
SyslogIdentifier=voxywatch-update
EOF

  # Systemd timer — runs daily with up to 1h random delay to spread load
  cat > /etc/systemd/system/voxywatch-update.timer << 'EOF'
[Unit]
Description=VoxyWatch Daily Update Check
Documentation=https://voxywatch.com/wiki/

[Timer]
OnCalendar=daily
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF

  systemctl daemon-reload
  systemctl enable --now voxywatch-update.timer
  ok "Auto-updater installed (daily check, randomized delay up to 1h)"
}

install_autoupdater

# ── Get server IP and Hardware ID ─────────────────────────────────────────────
SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "YOUR-IP")
HWID=""
if command -v node &>/dev/null && [ -f /opt/voxywatch/get-hwid.js ]; then
  HWID=$(node /opt/voxywatch/get-hwid.js 2>/dev/null | grep -oP '[0-9a-f]{32}' | head -1 || true)
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
echo "    Install once received:"
echo "    cp your_license.key /etc/voxywatch/license.key"
echo "    chown root:voxywatch /etc/voxywatch/license.key && chmod 640 /etc/voxywatch/license.key"
echo ""
echo -e "  ${BOLD}Documentation & Wiki:${NC}"
echo -e "  ${CYAN}https://voxywatch.com/wiki/${NC}"
echo ""
echo -e "  ${BOLD}Auto-updates:${NC} enabled — daily check via systemd timer"
echo "    Status:  systemctl status voxywatch-update.timer"
echo "    Run now: systemctl start voxywatch-update.service"
echo ""
echo -e "  ${BOLD}Service logs:${NC}"
echo "    journalctl -fu voxywatch"
echo "    journalctl -fu voxywatch-sniffer"
echo ""

} # end of main()

main "$@"
