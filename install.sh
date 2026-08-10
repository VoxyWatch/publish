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

# ── PostgreSQL + TimescaleDB (cluster local dedicado, aislado del stack del cliente) ──
PG_CLUSTER="voxywatch"           # cluster dedicado (no toca el 'main' en 5432 si existe)
PG_PORT="5433"                   # puerto no-default para no colisionar (InfluxDB/otro PG)
PG_SOCKET_DIR="/var/run/postgresql"
DB_NAME="voxywatch"
DB_USER="voxywatch"              # rol = usuario OS → auth peer por socket (sin password)
# Variables de conexión inyectadas a los servicios (libpq). Solo socket local.
DB_ENV="Environment=PGHOST=${PG_SOCKET_DIR}\nEnvironment=PGPORT=${PG_PORT}\nEnvironment=PGDATABASE=${DB_NAME}\nEnvironment=PGUSER=${DB_USER}"

# ── Colors ────────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
  CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; NC=''
fi
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $1"; }
err()  {
  echo -e "${RED}  ✗${NC} $1"
  if declare -F rollback_update >/dev/null 2>&1; then rollback_update "installer_error"; fi
  exit 1
}
info() { echo -e "${CYAN}  →${NC} $1"; }
# tty_ok: ¿hay terminal interactiva para prompts? Silencioso si no la hay (timer,
# ssh sin tty, curl|bash sin terminal) — evita el ruido "/dev/tty: No such device".
tty_ok() { { true </dev/tty; } 2>/dev/null; }

# Keep the first impression polished for people, but concise for timers,
# systemd and captured CI logs. The splash is deliberately dependency-free:
# a fresh/minimal server must not need figlet, tput or a working network to
# identify the installer it is about to run.
_vw_banner_full() {
  printf '\n%b' "${CYAN}${BOLD}"
  cat <<'VWBANNER'
          ╭──────────────────────────────────────────────╮
          │                                              │
          │  ───────────╲╱────────╲╱╲╱────────╲╱───────  │
          │                                              │
          │             V O X Y W A T C H                │
          ╰──────────────────────────────────────────────╯

 __     __                 __        __    _       _
 \ \   / /__  __  ___   _ \ \      / /_ _| |_ ___| |__
  \ \ / / _ \ \ \/ / | | | \ \ /\ / / _` | __/ __| '_ \
   \ V / (_) | >  <| |_| |  \ V  V / (_| | || (__| | | |
    \_/ \___/ /_/\_\\__, |   \_/\_/ \__,_|\__\___|_| |_|
                    |___/
VWBANNER
  printf '%b\n' "$NC"
  printf '             %bVOICE INTELLIGENCE. CLEAR EVIDENCE.%b\n' "$BOLD" "$NC"
  printf '                    Secure signed installer\n\n'
}

print_banner() {
  if [ -t 1 ]; then
    _vw_banner_full
  else
    printf '\n=== VoxyWatch | Secure signed installer ===\n\n'
  fi
}

# GPG is a mandatory trust dependency, not an optional media/UI helper. Install it
# before fetching the release metadata or the 42 MB artifact so a minimal host does
# not waste bandwidth and then fail. Package-manager trust remains the OS boundary;
# the VoxyWatch tarball is still verified independently with the embedded vendor key.
ensure_gpg() {
  command -v gpg >/dev/null 2>&1 && return 0
  info "GnuPG not found — installing the mandatory signature verifier..."
  if command -v apt-get >/dev/null 2>&1; then
    DEBIAN_FRONTEND=noninteractive apt-get update >/dev/null 2>&1 \
      || warn "Could not refresh apt metadata; trying the existing package cache"
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends gnupg >/dev/null 2>&1 \
      || err "Could not install mandatory GnuPG with apt. Fix the OS repositories and retry."
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y gnupg2 >/dev/null 2>&1 \
      || err "Could not install mandatory GnuPG with dnf. Fix the OS repositories and retry."
  elif command -v yum >/dev/null 2>&1; then
    yum install -y gnupg2 >/dev/null 2>&1 \
      || err "Could not install mandatory GnuPG with yum. Fix the OS repositories and retry."
  else
    err "gpg is required to authenticate VoxyWatch releases, and no supported package manager (apt, dnf or yum) was found. Install GnuPG and retry."
  fi
  command -v gpg >/dev/null 2>&1 \
    || err "gpg is required to authenticate VoxyWatch releases, but it is still unavailable after package installation."
  ok "GnuPG available — signed release verification enabled"
}

# Clave pública GPG del vendor (VoxyWatch Release Signing Key, 80EDE252…). Embebida AQUÍ a
# propósito: la confianza se ancla en este install.sh (que el operador revisa al instalar),
# no en un archivo descargable del mismo repo. Se usa para verificar la firma del tarball.
_vw_release_pubkey() {
cat <<'VWPUBKEY'
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
hjRBqQi7zxDox8s=
=Gmjb
-----END PGP PUBLIC KEY BLOCK-----
VWPUBKEY
}

print_banner

# ── Pre-flight checks ─────────────────────────────────────────────────────────
[ "$EUID" -ne 0 ] && err "Must run as root:  curl -fsSL https://raw.githubusercontent.com/${GITHUB_ORG}/${GITHUB_REPO}/main/install.sh | sudo bash"
command -v curl    &>/dev/null || err "curl is required:  apt install curl   or   yum install curl"
command -v python3 &>/dev/null || err "python3 is required:  apt install python3   or   yum install python3"
# sudo se usa para correr psql como los roles postgres/voxywatch (auth peer). Sin él, el
# provisioning fallaría A MITAD (cluster creado, sin esquema) → chequeo fail-fast aquí.
command -v sudo    &>/dev/null || err "sudo is required:  apt install sudo   or   yum install sudo"

# ── Mutex de instalación (v2.0.4) ─────────────────────────────────────────────
# Evita que dos instalaciones/actualizaciones corran a la vez (p.ej. un update lanzado
# desde el portal —POST /api/update— y una instalación manual simultánea).
# Un solape provocó servicios caídos: un run hacía 'systemctl stop' mientras
# el otro ya había arrancado el portal, y el segundo 'install' del binario en uso
# fallaba (set -e → aborto antes de re-arrancar). Con el lock, el segundo sale limpio.
if command -v flock &>/dev/null; then
  exec 9>"/run/voxywatch-install.lock" 2>/dev/null || exec 9>"/tmp/voxywatch-install.lock"
  if ! flock -n 9; then
    err "Another VoxyWatch install/update is already running — aborting to avoid a clash. Retry in a few minutes."
  fi
fi

# ── Parse arguments ───────────────────────────────────────────────────────────
VERSION=""
PORT_ARG=""
HTTPS_MODE_ARG=""
HTTPS_HOST_ARG=""
UPDATE_MODE=0
REFRESH_EXTERNAL_DEPS=0
PREVIOUS_VERSION=""
EXISTING_INSTALL=0
_need_arg() {
  [ $# -ge 2 ] && [ -n "${2:-}" ] && [[ "$2" != --* ]] \
    || err "Option $1 requires a value"
}
while [ $# -gt 0 ]; do
  case "$1" in
    --update)  UPDATE_MODE=1; shift ;;
    --refresh-external-dependencies) REFRESH_EXTERNAL_DEPS=1; shift ;;
    --version) _need_arg "$@"; VERSION="$2"; shift 2 ;;
    --port)    _need_arg "$@"; PORT_ARG="$2"; shift 2 ;;
    --https-mode) _need_arg "$@"; HTTPS_MODE_ARG="$2"; shift 2 ;;
    --https-host) _need_arg "$@"; HTTPS_HOST_ARG="$2"; shift 2 ;;
    --service-control) _need_arg "$@"; SERVICE_CONTROL_ARG="$2"; shift 2 ;;
    --replica-dsn) _need_arg "$@"; REPLICA_DSN="$2"; shift 2 ;;
    *) err "Unknown option: $1" ;;
  esac
done
[ "$REFRESH_EXTERNAL_DEPS" = "0" ] || [ "$UPDATE_MODE" = "1" ] \
  || err "--refresh-external-dependencies requires --update and a planned maintenance window"
[ -z "$HTTPS_MODE_ARG" ] || [ "$UPDATE_MODE" = "0" ] || [ "$REFRESH_EXTERNAL_DEPS" = "1" ] \
  || err "Changing HTTPS mode during an update requires --refresh-external-dependencies"
[ -z "$HTTPS_HOST_ARG" ] || [ -n "$HTTPS_MODE_ARG" ] \
  || err "--https-host requires --https-mode public or --https-mode internal"
[ "$HTTPS_MODE_ARG" != "legacy" ] || err "--https-mode accepts only public or internal"

# Read the installed version as data before replacing any files. This is used
# only for the update completion summary; never source the root-owned config.
if [ "$UPDATE_MODE" = "1" ] && [ -f "$CONF_FILE" ]; then
  EXISTING_INSTALL=1
  PREVIOUS_VERSION="$(grep -oE '^VERSION=[0-9]+\.[0-9]+\.[0-9]+$' "$CONF_FILE" 2>/dev/null | tail -1 | cut -d= -f2 || true)"
fi

# P2 (opt-in): réplica de lectura. Si se pasa --replica-dsn o está la env VOXYWATCH_DB_REPLICA_DSN,
# el portal enruta sus LECTURAS (UI/métricas/CDR) a la réplica; escrituras e ingesta van al primario.
# El cliente configura la replicación streaming de PostgreSQL aparte; aquí solo se enchufa el DSN.
REPLICA_DSN="${REPLICA_DSN:-${VOXYWATCH_DB_REPLICA_DSN:-}}"
REPLICA_ENV=""
if [ -n "$REPLICA_DSN" ]; then
  REPLICA_ENV="Environment=VOXYWATCH_DB_REPLICA_DSN=${REPLICA_DSN}"
fi

# Install the mandatory verifier only after arguments and the install mutex have
# been validated, but before any release metadata or artifact is downloaded.
ensure_gpg

# ── Fetch latest version and asset info ───────────────────────────────────────
info "Fetching signed release metadata..."
MANIFEST_JSON=$(curl -fsSL --max-time 15 "$VERSION_MANIFEST" 2>/dev/null \
  || err "Could not fetch version manifest from ${VERSION_MANIFEST}")
MANIFEST_VERSION=$(echo "$MANIFEST_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['version'])" 2>/dev/null \
  || err "Could not parse version from manifest")
EXPECTED_SHA256=$(echo "$MANIFEST_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['linux_x64']['sha256'])" 2>/dev/null \
  || err "Manifest has no linux_x64.sha256")
EXPECTED_SIG_URL=$(echo "$MANIFEST_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['linux_x64']['signature'])" 2>/dev/null \
  || err "Manifest has no linux_x64.signature")
[ -n "$VERSION" ] || VERSION="$MANIFEST_VERSION"
[ "$VERSION" = "$MANIFEST_VERSION" ] \
  || err "Version ${VERSION} is not the authenticated channel version (${MANIFEST_VERSION}). Refusing unsigned manual install."
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || err "Invalid release version in manifest: ${VERSION}"
[[ "$EXPECTED_SHA256" =~ ^[0-9a-fA-F]{64}$ ]] || err "Invalid or missing SHA-256 in manifest"
[[ "$EXPECTED_SIG_URL" =~ ^https:// ]] || err "Invalid or missing HTTPS signature URL in manifest"
ok "Version to install: v${VERSION}"

# ── Internal backend port ─────────────────────────────────────────────────────
# Fresh installs always use the safe loopback default. It is not an operator-facing
# choice: users enter through Caddy on HTTPS/443. --port remains an advanced option
# for automation and updates preserve an existing installation.
if [ -n "$PORT_ARG" ]; then
  PORT="$PORT_ARG"
elif [ "$UPDATE_MODE" = "1" ] && [ -f "$CONF_FILE" ]; then
  # Preserve the installed listener unless the operator explicitly migrates it
  # with --port. Parse the root-owned config as data; never source shell code.
  PORT="$(grep -oE '^PORT=[0-9]+$' "$CONF_FILE" 2>/dev/null | tail -1 | cut -d= -f2 || true)"
  PORT="${PORT:-3080}"
else
  PORT="3080"
fi
if ! echo "$PORT" | grep -qE '^[0-9]+$' || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
  warn "Invalid port '${PORT}' — using default 3080"
  PORT="3080"
fi
[ -z "$PORT_ARG" ] || ok "Advanced internal backend port: ${PORT} (HTTPS remains on 443)"

# Public domains use Caddy Automatic HTTPS. Private hostnames/IPs use Caddy's
# internal CA. HTTPS is not optional on fresh installs; PORT remains a loopback
# backend and is never the operator-facing URL.
_valid_https_host() {
  [[ "$1" =~ ^([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9.-]*[A-Za-z0-9])$ ]] \
    && [[ "$1" != *..* ]] && [[ "$1" != http://* ]] && [[ "$1" != https://* ]]
}
_valid_public_https_host() {
  _valid_https_host "$1" \
    && [[ "$1" == *.* ]] \
    && [[ ! "$1" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]
}
_detected_private_host() {
  local candidate
  candidate="$(hostname -I 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i ~ /\./ && $i !~ /^127\./) {print $i; exit}}')"
  _valid_https_host "$candidate" && { printf '%s' "$candidate"; return; }
  candidate="$(hostname -f 2>/dev/null || true)"
  _valid_https_host "$candidate" && [ "$candidate" != localhost ] && { printf '%s' "$candidate"; return; }
}
_read_tty_line() {
  local prompt="$1" default_value="${2:-}" input=""
  printf "  %s" "$prompt" >&2
  IFS= read -r input </dev/tty 2>/dev/null || return 1
  printf '%s' "${input:-$default_value}"
}

HTTPS_MODE=""
HTTPS_HOST=""
if [ "$UPDATE_MODE" = "1" ] && [ -f "$CONF_FILE" ] && [ -z "$HTTPS_MODE_ARG" ]; then
  HTTPS_MODE="$(sed -n 's/^HTTPS_MODE=//p' "$CONF_FILE" | tail -1)"
  HTTPS_HOST="$(sed -n 's/^HTTPS_HOST=//p' "$CONF_FILE" | tail -1)"
elif [ -n "$HTTPS_MODE_ARG" ]; then
  HTTPS_MODE="$HTTPS_MODE_ARG"
  HTTPS_HOST="$HTTPS_HOST_ARG"
else
  HTTPS_MODE="internal"
  HTTPS_HOST="$HTTPS_HOST_ARG"
  # Fresh installs must be immediately reachable without asking the operator to
  # make a DNS/certificate decision mid-install. Start with the detected private
  # address and Caddy's internal CA; public-domain access is configured later in
  # Settings → Web Access. Automation may still opt in explicitly with
  # --https-mode public --https-host <fqdn>.
  [ -n "$HTTPS_HOST" ] || HTTPS_HOST="$(_detected_private_host)"
  [ -n "$HTTPS_HOST" ] \
    || err "Could not detect a private hostname/IP; rerun with --https-mode internal --https-host <address>"
fi
[ -n "$HTTPS_MODE" ] || HTTPS_MODE="legacy"
case "$HTTPS_MODE" in public|internal|legacy) ;; *) err "Invalid HTTPS mode '${HTTPS_MODE}': use public or internal" ;; esac
if [ "$UPDATE_MODE" = "1" ] && [ -n "$PORT_ARG" ] && [ "$HTTPS_MODE" != "legacy" ] \
   && [ "$REFRESH_EXTERNAL_DEPS" != "1" ]; then
  err "Changing the internal portal port behind managed HTTPS requires --refresh-external-dependencies"
fi
if [ "$HTTPS_MODE" != "legacy" ]; then
  if [ -z "$HTTPS_HOST" ] && [ "$HTTPS_MODE" = "public" ]; then
    err "Public HTTPS requires --https-host with a DNS name that points to this server"
  fi
  [ -n "$HTTPS_HOST" ] || HTTPS_HOST="$(_detected_private_host)"
  _valid_https_host "$HTTPS_HOST" || err "Invalid HTTPS hostname/IP '${HTTPS_HOST}'"
  if [ "$HTTPS_MODE" = "public" ]; then
    _valid_public_https_host "$HTTPS_HOST" \
      || err "Public HTTPS requires a fully-qualified DNS name, not an IP address"
    ok "Portal URL: https://${HTTPS_HOST} (publicly trusted certificate)"
    info "Before opening it: point DNS to this server and allow inbound TCP 80 and 443"
  else
    ok "Portal URL: https://${HTTPS_HOST} (private Caddy certificate)"
    info "Before opening it: allow inbound TCP 443 and trust Caddy's root certificate on each client"
  fi
else
  warn "Legacy HTTPS compatibility is preserved for this update. The HTTP backend may remain network-accessible until you migrate to --https-mode public or internal. Diagnostics will report this as critical when the listener is not loopback-only."
fi
echo ""

# ── Service control permission (enabled by default per install/update) ────────
# Lets the unprivileged ${SERVICE_USER} user restart its OWN services and apply
# signed updates from the web portal — a scoped, non-root grant (see the generated
# enable-service-control.sh for exactly what it allows).
_service_control_choice() {
  case "${1:-yes}" in
    yes|enabled|y) printf 'yes' ;;
    no|disabled|n) printf 'no' ;;
    *) return 2 ;;
  esac
}

SERVICE_CONTROL="yes"
if [ -n "${SERVICE_CONTROL_ARG:-}" ]; then
  SERVICE_CONTROL="$(_service_control_choice "$SERVICE_CONTROL_ARG")" \
    || err "--service-control accepts only yes or no"
fi
if [ "$SERVICE_CONTROL" = "yes" ]; then
  ok "Portal service control: enabled (scoped restarts and signed updates)"

  # systemd delegates unprivileged D-Bus authorization to polkit. Minimal Debian
  # images may have systemd but no polkit daemon at all; merely writing a rule
  # then looks configured while every busctl StartUnit is rejected as denied.
  # Install it before touching product files so an apt failure cannot leave a
  # half-updated VoxyWatch installation.
  command -v apt-get &>/dev/null \
    || err "Service control requires polkit on a Debian/Ubuntu host (apt-get not found)"
  if ! command -v pkaction &>/dev/null; then
    info "Installing polkit for scoped portal service control..."
    apt-get update >/dev/null 2>&1 || true
    apt-get install -y polkitd >/dev/null 2>&1 \
      || apt-get install -y policykit-1 >/dev/null 2>&1 \
      || err "Could not install polkit; disable service control or install polkit manually"
  fi
  command -v pkaction &>/dev/null \
    || err "Service control was requested but polkit is not available"
  ok "polkit available for scoped D-Bus authorization"
else
  ok "Portal service control: disabled by advanced option (manual restarts and updates)"
fi
echo ""

# ── Download tarball ──────────────────────────────────────────────────────────
TARBALL_NAME="voxywatch-v${VERSION}-linux-x64.tar.gz"
TARBALL_DIR="voxywatch-v${VERSION}-linux-x64"
DOWNLOAD_URL="${RELEASES_BASE}/v${VERSION}/${TARBALL_NAME}"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

info "Downloading ${TARBALL_NAME}..."
curl -fsSL --connect-timeout 15 --max-time 600 --retry 2 --progress-bar \
  "$DOWNLOAD_URL" -o "${TMPDIR}/${TARBALL_NAME}" \
  || err "Failed to download ${DOWNLOAD_URL}"
ok "Download complete: $(du -sh "${TMPDIR}/${TARBALL_NAME}" | cut -f1)"

# ── Verify SHA-256 ────────────────────────────────────────────────────────────
ACTUAL_SHA256=$(python3 - "${TMPDIR}/${TARBALL_NAME}" <<'PY'
import hashlib
import sys

digest = hashlib.sha256()
with open(sys.argv[1], "rb") as source:
    for chunk in iter(lambda: source.read(1024 * 1024), b""):
        digest.update(chunk)
print(digest.hexdigest())
PY
)
if [ "$EXPECTED_SHA256" != "$ACTUAL_SHA256" ]; then
  err "SHA-256 mismatch — package may be corrupted or tampered with.
    Expected: ${EXPECTED_SHA256}
    Got:      ${ACTUAL_SHA256}"
fi
ok "SHA-256 verified: ${ACTUAL_SHA256:0:16}…"

# ── Verify GPG signature (defensa en profundidad, más allá del SHA del manifiesto) ────────────
# El SHA viene del MISMO manifiesto que la URL → no protege si el canal se compromete. La firma
# GPG (clave privada del vendor, OFFLINE) sí: quien controle el repo/Releases no puede re-firmar.
# La firma es obligatoria y fail-closed: ausencia de URL, gpg, descarga o verificación aborta.
command -v gpg >/dev/null 2>&1 \
  || err "gpg is required to authenticate VoxyWatch releases. Install gnupg and retry."
if [ -n "${EXPECTED_SIG_URL:-}" ]; then
  if command -v gpg >/dev/null 2>&1; then
    info "Verifying GPG signature..."
    if curl -fsSL --max-time 30 "$EXPECTED_SIG_URL" -o "${TMPDIR}/${TARBALL_NAME}.asc" 2>/dev/null; then
      GNUPGHOME_TMP=$(mktemp -d); chmod 700 "$GNUPGHOME_TMP"
      _vw_release_pubkey | GNUPGHOME="$GNUPGHOME_TMP" gpg --quiet --import 2>/dev/null \
        || err "Could not import the embedded release signing key"
      if GNUPGHOME="$GNUPGHOME_TMP" gpg --quiet --verify "${TMPDIR}/${TARBALL_NAME}.asc" "${TMPDIR}/${TARBALL_NAME}" 2>/dev/null; then
        ok "GPG signature verified (VoxyWatch Release Signing Key)"
      else
        rm -rf "$GNUPGHOME_TMP"
        err "GPG signature INVALID — package tampered or wrong signing key. Aborting install."
      fi
      rm -rf "$GNUPGHOME_TMP"
    else
      err "Could not download the mandatory release signature"
    fi
  else
    err "gpg is required to authenticate VoxyWatch releases"
  fi
fi

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

# ── Transactional file rollback for updates ──────────────────────────────────
# Database migrations are additive and remain applied; old binaries must stay
# forward-compatible with additive schema. Customer data is never copied,
# deleted or restored here. The snapshot contains only product files, config,
# units and kernel tuning, under a root-only directory.
ROLLBACK_READY=0
ROLLBACK_ARCHIVE=""
ROLLBACK_ROOT="/var/backups/voxywatch"
LICENSE_CLI_LINK_WAS_PRESENT=0
AI_KEY_CLI_LINK_WAS_PRESENT=0
SETUP_CLI_LINK_WAS_PRESENT=0
CADDY_CONFIG_WAS_PRESENT=0
CADDY_WAS_ACTIVE=0
CADDY_WAS_INSTALLED=0
command -v caddy >/dev/null 2>&1 && CADDY_WAS_INSTALLED=1 || true
rollback_update() {
  local reason="${1:-unexpected_error}"
  [ "$ROLLBACK_READY" = "1" ] || return 0
  ROLLBACK_READY=0
  trap - ERR
  warn "Update failed (${reason}); restoring the previous VoxyWatch files..."
  systemctl stop voxywatch voxywatch-sniffer 2>/dev/null || true
  if tar -xzf "$ROLLBACK_ARCHIVE" -C /; then
    [ "$LICENSE_CLI_LINK_WAS_PRESENT" = "1" ] || rm -f /usr/local/sbin/voxywatch-license
    [ "$AI_KEY_CLI_LINK_WAS_PRESENT" = "1" ] || rm -f /usr/local/sbin/voxywatch-ai-key
    [ "$SETUP_CLI_LINK_WAS_PRESENT" = "1" ] || rm -f /usr/local/sbin/voxywatch-setup
    [ "$CADDY_CONFIG_WAS_PRESENT" = "1" ] || rm -f /etc/caddy/Caddyfile
    if [ "$CADDY_WAS_ACTIVE" = "1" ]; then
      systemctl reload-or-restart caddy 2>/dev/null || true
    else
      systemctl disable --now caddy 2>/dev/null || true
    fi
    systemctl daemon-reload 2>/dev/null || true
    systemctl start voxywatch-sniffer 2>/dev/null || true
    systemctl start voxywatch 2>/dev/null || true
    if systemctl is-active --quiet voxywatch && systemctl is-active --quiet voxywatch-sniffer; then
      ok "Previous VoxyWatch files restored; core services are active"
    else
      warn "Previous files restored, but a core service needs manual inspection"
    fi
  else
    warn "Automatic rollback extraction failed; backup preserved at ${ROLLBACK_ARCHIVE}"
  fi
}
rollback_unexpected() {
  local rc=$?
  trap - ERR
  rollback_update "unexpected_command_failure"
  exit "$rc"
}

if [ "$UPDATE_MODE" = "1" ] && [ -d "$INSTALL_DIR" ] && [ -f "$CONF_FILE" ]; then
  systemctl is-active --quiet caddy 2>/dev/null && CADDY_WAS_ACTIVE=1 || true
  if [ -e /usr/local/sbin/voxywatch-license ] || [ -L /usr/local/sbin/voxywatch-license ]; then
    LICENSE_CLI_LINK_WAS_PRESENT=1
  fi
  if [ -e /usr/local/sbin/voxywatch-ai-key ] || [ -L /usr/local/sbin/voxywatch-ai-key ]; then
    AI_KEY_CLI_LINK_WAS_PRESENT=1
  fi
  if [ -e /usr/local/sbin/voxywatch-setup ] || [ -L /usr/local/sbin/voxywatch-setup ]; then
    SETUP_CLI_LINK_WAS_PRESENT=1
  fi
  PREVIOUS_VERSION=$(sed -n 's/^VERSION=//p' "$CONF_FILE" | head -1)
  ROLLBACK_STAMP=$(date -u '+%Y%m%dT%H%M%SZ')
  ROLLBACK_DIR="${ROLLBACK_ROOT}/${PREVIOUS_VERSION:-unknown}-${ROLLBACK_STAMP}"
  install -d -o root -g root -m 700 "$ROLLBACK_ROOT" "$ROLLBACK_DIR"
  ROLLBACK_ARCHIVE="${ROLLBACK_DIR}/system-files.tar.gz"
  _rollback_paths=(opt/voxywatch etc/voxywatch)
  for _p in \
    etc/systemd/system/voxywatch.service \
    etc/systemd/system/voxywatch-sniffer.service \
    etc/systemd/system/voxywatch-srs.service \
    etc/systemd/system/voxywatch-agentic.service \
    etc/systemd/system/voxywatch-apply-update.service \
    etc/systemd/system/voxywatch-apply-web-access.service \
    etc/sysctl.d/99-voxywatch.conf \
    usr/local/sbin/voxywatch-license \
    usr/local/sbin/voxywatch-ai-key; do
    [ -e "/${_p}" ] && _rollback_paths+=("$_p")
  done
  [ -e /usr/local/sbin/voxywatch-setup ] && _rollback_paths+=("usr/local/sbin/voxywatch-setup")
  if [ -e /etc/caddy/Caddyfile ]; then
    CADDY_CONFIG_WAS_PRESENT=1
    _rollback_paths+=("etc/caddy/Caddyfile")
  fi
  tar --exclude='opt/voxywatch/agentic/.venv' --exclude='opt/voxywatch/srs-venv' \
    -C / -czf "$ROLLBACK_ARCHIVE" "${_rollback_paths[@]}" \
    || err "Could not create the pre-update rollback snapshot"
  chmod 600 "$ROLLBACK_ARCHIVE"
  printf 'previous_version=%s\ncreated_at=%s\nschema_policy=additive-forward-compatible\n' \
    "${PREVIOUS_VERSION:-unknown}" "$ROLLBACK_STAMP" > "${ROLLBACK_DIR}/manifest"
  chmod 600 "${ROLLBACK_DIR}/manifest"
  ROLLBACK_READY=1
  trap rollback_unexpected ERR
  ok "Pre-update rollback snapshot ready (${PREVIOUS_VERSION:-unknown})"
fi

# ── Stop existing services (ignore errors if not installed yet) ───────────────
# v2.16.1 (captura sagrada): reiniciar el SNIFFER SOLO si hep_sniffer.py cambió.
# En un update de solo-portal (lo más común: el binario del portal cambia pero el
# sniffer no), dejar el sniffer corriendo → la captura NO se interrumpe (cero drops
# por el update). El portal (voxywatch) sí se reinicia siempre: no captura tráfico.
# `systemctl start voxywatch-sniffer` más abajo es no-op si el sniffer sigue activo.
SNIFFER_CHANGED=1
if [ -f "${INSTALL_DIR}/hep_sniffer.py" ] && cmp -s "${EXTRACTED}/hep_sniffer.py" "${INSTALL_DIR}/hep_sniffer.py" 2>/dev/null; then
  SNIFFER_CHANGED=0
fi
if [ "$SNIFFER_CHANGED" = "1" ]; then
  systemctl stop voxywatch voxywatch-sniffer 2>/dev/null || true
else
  info "hep_sniffer.py unchanged → the sniffer keeps capturing (not restarted)"
  systemctl stop voxywatch 2>/dev/null || true
fi

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
# Binario: instalar a un nombre temporal y renombrar (atómico). 'mv' reemplaza aunque
# el viejo siga mapeado/en uso, evitando 'File exists' / 'Text file busy' en updates.
install -o root -g voxywatch -m 750 "${EXTRACTED}/voxywatch-portal"   "${INSTALL_DIR}/voxywatch-portal.new"
mv -f "${INSTALL_DIR}/voxywatch-portal.new" "${INSTALL_DIR}/voxywatch-portal"
install -o root -g voxywatch -m 640 "${EXTRACTED}/hep_sniffer.py"     "${INSTALL_DIR}/hep_sniffer.py"
install -o root -g voxywatch -m 640 "${EXTRACTED}/get-hwid.js"        "${INSTALL_DIR}/get-hwid.js"
[ -f "${EXTRACTED}/voxywatch-mcp.js" ] && install -o root -g voxywatch -m 644 "${EXTRACTED}/voxywatch-mcp.js" "${INSTALL_DIR}/voxywatch-mcp.js"
install -o root -g voxywatch -m 640 "${EXTRACTED}/migrate_to_db.js"   "${INSTALL_DIR}/migrate_to_db.js" 2>/dev/null || true
install -o root -g voxywatch -m 750 "${EXTRACTED}/apply-web-access.py" "${INSTALL_DIR}/apply-web-access.py"
# Helpers que el portal invoca directamente: si falta uno, la instalación está incompleta
# y debe abortar en lugar de anunciar éxito con Audio/PCAP/DTMF rotos.
install -o root -g voxywatch -m 640 "${EXTRACTED}/generate_pcap.py"     "${INSTALL_DIR}/generate_pcap.py"
install -o root -g voxywatch -m 640 "${EXTRACTED}/reconstruct_audio.py" "${INSTALL_DIR}/reconstruct_audio.py"
install -o root -g voxywatch -m 640 "${EXTRACTED}/extract_dtmf.py"      "${INSTALL_DIR}/extract_dtmf.py"
install -o root -g voxywatch -m 640 "${EXTRACTED}/voxywatch_srs.py"   "${INSTALL_DIR}/voxywatch_srs.py" 2>/dev/null || true   # SIPREC SRS (proceso aparte, OFF por default)
install -o root -g voxywatch -m 640 "${EXTRACTED}/schema.sql"         "${INSTALL_DIR}/schema.sql" 2>/dev/null || true
install -o root -g voxywatch -m 640 "${EXTRACTED}/repair-ownership.sql" "${INSTALL_DIR}/repair-ownership.sql" 2>/dev/null || true
install -o root -g voxywatch -m 750 "${EXTRACTED}/migrate.sh"         "${INSTALL_DIR}/migrate.sh" 2>/dev/null || true
install -d -o root -g voxywatch -m 750 "${INSTALL_DIR}/migrations"
for migration in "${EXTRACTED}"/migrations/*.sql; do
  [ -e "$migration" ] || continue
  install -o root -g voxywatch -m 640 "$migration" "${INSTALL_DIR}/migrations/$(basename "$migration")"
done
install -o root -g root      -m 644 "${EXTRACTED}/WIKI_INTEGRATION.md" "${INSTALL_DIR}/WIKI_INTEGRATION.md" 2>/dev/null || true
install -o root -g voxywatch -m 640 "${EXTRACTED}/AI_TROUBLESHOOTING.md" "${INSTALL_DIR}/AI_TROUBLESHOOTING.md" 2>/dev/null || true
if [ -d "${EXTRACTED}/agentic" ]; then
  install -d -o root -g voxywatch -m 750 "${INSTALL_DIR}/agentic"
  install -o root -g voxywatch -m 640 "${EXTRACTED}/agentic/manifest.json" "${INSTALL_DIR}/agentic/manifest.json" 2>/dev/null || true
  install -o root -g voxywatch -m 640 "${EXTRACTED}/agentic/requirements.txt" "${INSTALL_DIR}/agentic/requirements.txt" 2>/dev/null || true
  install -o root -g voxywatch -m 640 "${EXTRACTED}/agentic/requirements.lock.txt" "${INSTALL_DIR}/agentic/requirements.lock.txt" 2>/dev/null || true
  install -o root -g voxywatch -m 750 "${EXTRACTED}/agentic/voxywatch_agentic.py" "${INSTALL_DIR}/agentic/voxywatch_agentic.py" 2>/dev/null || true
  install -o root -g voxywatch -m 640 "${EXTRACTED}/agentic/adk_workflow.py" "${INSTALL_DIR}/agentic/adk_workflow.py" 2>/dev/null || true
  install -o root -g voxywatch -m 750 "${EXTRACTED}/agentic/install-agentic-deps.sh" "${INSTALL_DIR}/agentic/install-agentic-deps.sh" 2>/dev/null || true
  install -o root -g voxywatch -m 750 "${EXTRACTED}/agentic/run-agentic.sh" "${INSTALL_DIR}/agentic/run-agentic.sh" 2>/dev/null || true
  install -o root -g voxywatch -m 640 "${EXTRACTED}/agentic/voxywatch-agentic.service" "${INSTALL_DIR}/agentic/voxywatch-agentic.service" 2>/dev/null || true
fi
install -o root -g voxywatch -m 640 "${EXTRACTED}/external-dependencies.json" "${INSTALL_DIR}/external-dependencies.json"
if [ -d "${EXTRACTED}/docs/ai" ]; then
  install -d -o root -g voxywatch -m 750 "${INSTALL_DIR}/docs" "${INSTALL_DIR}/docs/ai"
  find "${EXTRACTED}/docs/ai" -type d | while read -r d; do
    rel="${d#${EXTRACTED}/docs/ai}"
    install -d -o root -g voxywatch -m 750 "${INSTALL_DIR}/docs/ai${rel}"
  done
  find "${EXTRACTED}/docs/ai" -type f -name '*.md' | while read -r f; do
    rel="${f#${EXTRACTED}/docs/ai/}"
    install -o root -g voxywatch -m 640 "$f" "${INSTALL_DIR}/docs/ai/${rel}"
  done
fi
for operational_doc in FLASH_CALL_DETECTION.md MCP_SERVER.md INITIAL_SETUP_CHANNELS.md IMPLEMENTED_FEATURES.md LICENSE_CLI.md AI_CREDENTIALS.md HTTPS_CONFIGURATION.md; do
  [ -f "${EXTRACTED}/docs/${operational_doc}" ] || continue
  install -d -o root -g voxywatch -m 750 "${INSTALL_DIR}/docs"
  install -o root -g voxywatch -m 640 "${EXTRACTED}/docs/${operational_doc}" \
    "${INSTALL_DIR}/docs/${operational_doc}"
done

# Frontend assets — van junto al binario en INSTALL_DIR.
# El binario los sirve desde path.dirname(process.execPath) = /opt/voxywatch/
install -o root -g voxywatch -m 640 "${EXTRACTED}/styles.css" "${INSTALL_DIR}/styles.css" 2>/dev/null || true
install -o root -g voxywatch -m 640 "${EXTRACTED}/app.js"     "${INSTALL_DIR}/app.js"     2>/dev/null || true
# TICKET-021: Chart.js self-hosted + update-checker externalizado (la CSP bloquea CDN/inline)
install -o root -g voxywatch -m 640 "${EXTRACTED}/chart.umd.min.js"  "${INSTALL_DIR}/chart.umd.min.js"  2>/dev/null || true
install -o root -g voxywatch -m 640 "${EXTRACTED}/frontend-runtime.js" "${INSTALL_DIR}/frontend-runtime.js" 2>/dev/null || true
install -o root -g voxywatch -m 640 "${EXTRACTED}/frontend-shell.js" "${INSTALL_DIR}/frontend-shell.js"
install -o root -g voxywatch -m 640 "${EXTRACTED}/product-ux.js" "${INSTALL_DIR}/product-ux.js"
install -o root -g voxywatch -m 640 "${EXTRACTED}/update-checker.js" "${INSTALL_DIR}/update-checker.js" 2>/dev/null || true
# Root-owned updater entrypoint delivered by the verified, signed tarball.
install -o root -g root -m 750 "${EXTRACTED}/install.sh" "${INSTALL_DIR}/install.sh"
cat > "${INSTALL_DIR}/voxywatch-license" << 'LICENSE_CLI_EOF'
#!/bin/sh
exec /opt/voxywatch/voxywatch-portal license "$@"
LICENSE_CLI_EOF
chown root:root "${INSTALL_DIR}/voxywatch-license"
chmod 755 "${INSTALL_DIR}/voxywatch-license"
install -d -o root -g root -m 755 /usr/local/sbin
ln -sfn "${INSTALL_DIR}/voxywatch-license" /usr/local/sbin/voxywatch-license
cat > "${INSTALL_DIR}/voxywatch-ai-key" << 'AI_KEY_CLI_EOF'
#!/bin/sh
exec /opt/voxywatch/voxywatch-portal ai-key "$@"
AI_KEY_CLI_EOF
chown root:root "${INSTALL_DIR}/voxywatch-ai-key"
chmod 755 "${INSTALL_DIR}/voxywatch-ai-key"
ln -sfn "${INSTALL_DIR}/voxywatch-ai-key" /usr/local/sbin/voxywatch-ai-key
cat > "${INSTALL_DIR}/voxywatch-setup" << 'SETUP_CLI_EOF'
#!/bin/sh
exec /opt/voxywatch/voxywatch-portal setup "$@"
SETUP_CLI_EOF
chown root:root "${INSTALL_DIR}/voxywatch-setup"
chmod 755 "${INSTALL_DIR}/voxywatch-setup"
ln -sfn "${INSTALL_DIR}/voxywatch-setup" /usr/local/sbin/voxywatch-setup
install -d -o root -g voxywatch -m 750 "${CONF_DIR}/credentials"
ok "Files installed"

# ── Write config file ─────────────────────────────────────────────────────────
cat > "$CONF_FILE" << EOF
# VoxyWatch configuration
# Generated by installer on $(date -u '+%Y-%m-%d %H:%M UTC')
PORT=${PORT}
HTTPS_MODE=${HTTPS_MODE}
HTTPS_HOST=${HTTPS_HOST}
VERSION=${VERSION}
EOF
chown root:voxywatch "$CONF_FILE"
chmod 640 "$CONF_FILE"
ok "Config written: ${CONF_FILE}"

# ── Provision PostgreSQL + TimescaleDB ────────────────────────────────────────
# Cluster local DEDICADO en puerto no-default (5433), bindeado a localhost, con
# auth peer por socket (sin password). Aislado del stack del cliente (5432/Influx).
info "Provisioning PostgreSQL + TimescaleDB (cluster ${PG_CLUSTER} on :${PG_PORT})..."
command -v apt-get &>/dev/null || err "The PostgreSQL+TimescaleDB database requires Debian/Ubuntu (apt). RHEL: contact support."

# 1) External software policy. A normal product update must not turn into an OS,
# PostgreSQL, TimescaleDB or Python upgrade. Fresh installs provision dependencies;
# an operator may refresh them only with the explicit maintenance flag.
PG_VER=""
if [ "$UPDATE_MODE" = "1" ]; then
  PG_VER="$(pg_lsclusters -h 2>/dev/null | awk -v c="$PG_CLUSTER" '$2 == c { print $1; exit }')"
  [ -n "$PG_VER" ] || PG_VER="$(ls /usr/lib/postgresql/ 2>/dev/null | sort -n | tail -1)"
fi

if [ "$UPDATE_MODE" = "0" ] || [ "$REFRESH_EXTERNAL_DEPS" = "1" ]; then
  if [ ! -f /etc/apt/sources.list.d/timescaledb.list ]; then
    apt-get install -y --no-install-recommends gnupg lsb-release wget ca-certificates >/dev/null 2>&1 || true
    echo "deb https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -cs) main" \
      > /etc/apt/sources.list.d/timescaledb.list
    wget -qO- https://packagecloud.io/timescale/timescaledb/gpgkey \
      | gpg --dearmor -o /etc/apt/trusted.gpg.d/timescaledb.gpg 2>/dev/null || true
  fi
  apt-get update >/dev/null 2>&1 || err "Could not refresh package metadata for the controlled dependency operation"
  if [ "$HTTPS_MODE" != "legacy" ]; then
    CADDY_VERSION="2.11.4"
    if [ ! -f /usr/share/keyrings/caddy-stable-archive-keyring.gpg ]; then
      curl -1fsSL 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
        | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg \
        || err "Could not install the official Caddy repository key"
      curl -1fsSL 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
        -o /etc/apt/sources.list.d/caddy-stable.list \
        || err "Could not install the official Caddy repository definition"
      chmod 644 /usr/share/keyrings/caddy-stable-archive-keyring.gpg /etc/apt/sources.list.d/caddy-stable.list
      apt-get update >/dev/null 2>&1 || err "Could not refresh metadata after adding the official Caddy repository"
    fi
    CADDY_PACKAGE_VERSION="$(apt-cache madison caddy 2>/dev/null | awk -v v="$CADDY_VERSION" '$3 ~ ("^" v "([+~-]|$)") {print $3; exit}')"
    [ -n "$CADDY_PACKAGE_VERSION" ] || err "Validated Caddy ${CADDY_VERSION} is unavailable from the configured repository"
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "caddy=${CADDY_PACKAGE_VERSION}" >/dev/null 2>&1 \
      || err "Could not install validated Caddy ${CADDY_VERSION}"
    ok "Caddy ${CADDY_VERSION} installed for managed HTTPS"
  fi
  if [ "$UPDATE_MODE" = "1" ]; then
    [ -n "$PG_VER" ] || err "Could not identify the existing PostgreSQL major version"
    # Never install the postgresql meta-package during a refresh: that could add
    # a new major and create an empty cluster. Refresh only the installed major.
    apt-get install -y --no-install-recommends "postgresql-${PG_VER}" postgresql-common python3-psycopg2 ffmpeg \
      "timescaledb-2-postgresql-${PG_VER}" timescaledb-tools >/dev/null 2>&1 \
      || err "Controlled external dependency refresh failed"
  else
    apt-get install -y --no-install-recommends postgresql postgresql-common python3-psycopg2 >/dev/null 2>&1 \
      || err "Could not install postgresql / python3-psycopg2"
  fi
else
  info "Preserving installed external dependency versions (normal VoxyWatch update)"
  command -v pg_lsclusters >/dev/null 2>&1 || err "postgresql-common is missing; run a controlled external dependency refresh"
  python3 -c 'import psycopg2' >/dev/null 2>&1 || err "python3-psycopg2 is missing; run a controlled external dependency refresh"
fi

# ffmpeg: REQUERIDO para reconstruir/reproducir audio (reconstruct_audio.py lo usa para
# convertir el RTP crudo a WAV). Sin él, la reconstrucción escribe el .g722 pero NO genera
# el WAV → el player da 404. Es una dependencia dura del audio, no opcional.
if [ "$UPDATE_MODE" = "0" ]; then
  command -v ffmpeg &>/dev/null || apt-get install -y --no-install-recommends ffmpeg >/dev/null 2>&1 || true
fi
command -v ffmpeg &>/dev/null || warn "ffmpeg NOT available — audio playback will not work until you install it (apt-get install ffmpeg)."

# Detectar la versión mayor instalada y el paquete TimescaleDB correspondiente
PG_VER="${PG_VER:-$(ls /usr/lib/postgresql/ 2>/dev/null | sort -n | tail -1)}"
[ -n "$PG_VER" ] || err "No PostgreSQL installation detected in /usr/lib/postgresql"
if [ "$UPDATE_MODE" = "0" ]; then
  apt-get install -y --no-install-recommends "timescaledb-2-postgresql-${PG_VER}" "timescaledb-tools" >/dev/null 2>&1 \
    || err "Could not install timescaledb-2-postgresql-${PG_VER}"
fi

# 2) Crear el cluster dedicado si no existe (puerto no-default, auth local peer)
if ! pg_lsclusters -h 2>/dev/null | awk '{print $1" "$2}' | grep -qx "${PG_VER} ${PG_CLUSTER}"; then
  pg_createcluster "${PG_VER}" "${PG_CLUSTER}" -p "${PG_PORT}" -- --auth-local=peer >/dev/null \
    || err "pg_createcluster failed"
fi
PG_CONF_DIR="/etc/postgresql/${PG_VER}/${PG_CLUSTER}"

# 3) Endurecer: solo localhost, precargar timescaledb, afinar al hardware
sed -i "s/^#\?listen_addresses.*/listen_addresses = 'localhost'/" "${PG_CONF_DIR}/postgresql.conf"
grep -q "shared_preload_libraries.*timescaledb" "${PG_CONF_DIR}/postgresql.conf" \
  || echo "shared_preload_libraries = 'timescaledb'" >> "${PG_CONF_DIR}/postgresql.conf"
if [ "$UPDATE_MODE" = "0" ] || [ "$REFRESH_EXTERNAL_DEPS" = "1" ]; then
  command -v timescaledb-tune &>/dev/null \
    && timescaledb-tune --quiet --yes --conf-path "${PG_CONF_DIR}/postgresql.conf" >/dev/null 2>&1 || true
fi

systemctl enable --now "postgresql@${PG_VER}-${PG_CLUSTER}" >/dev/null 2>&1 \
  || pg_ctlcluster "${PG_VER}" "${PG_CLUSTER}" start >/dev/null 2>&1 || true

# 4) Esperar readiness del cluster
for i in $(seq 1 30); do
  pg_isready -h "${PG_SOCKET_DIR}" -p "${PG_PORT}" >/dev/null 2>&1 && break
  sleep 1
done

# 5) Rol + base de datos + extensión (postgres) + esquema (voxywatch, dueño)
PSQL_SU="sudo -u postgres psql -h ${PG_SOCKET_DIR} -p ${PG_PORT} -v ON_ERROR_STOP=1"
${PSQL_SU} -tAc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" 2>/dev/null | grep -q 1 \
  || ${PSQL_SU} -c "CREATE ROLE ${DB_USER} LOGIN;" >/dev/null
${PSQL_SU} -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" 2>/dev/null | grep -q 1 \
  || ${PSQL_SU} -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};" >/dev/null
# La extensión la crea el superusuario; el esquema (tabla/hypertable/políticas) lo
# crea el rol voxywatch para que sea su dueño y pueda drop_chunks/TRUNCATE.
${PSQL_SU} -d "${DB_NAME}" -c "CREATE EXTENSION IF NOT EXISTS timescaledb;" >/dev/null

# TimescaleDB software/catalog upgrades are never part of a normal product update.
# They run only on fresh provisioning or an explicit controlled refresh.
INSTALLED_TS=$(${PSQL_SU} -tAc "SELECT extversion FROM pg_extension WHERE extname='timescaledb'" -d "${DB_NAME}" 2>/dev/null)
AVAILABLE_TS=$(${PSQL_SU} -tAc "SELECT default_version FROM pg_available_extensions WHERE name='timescaledb'" -d "${DB_NAME}" 2>/dev/null)
if { [ "$UPDATE_MODE" = "0" ] || [ "$REFRESH_EXTERNAL_DEPS" = "1" ]; } \
   && [ -n "$INSTALLED_TS" ] && [ -n "$AVAILABLE_TS" ] && [ "$INSTALLED_TS" != "$AVAILABLE_TS" ]; then
  info "Updating TimescaleDB extension ${INSTALLED_TS} → ${AVAILABLE_TS}..."
  systemctl restart "postgresql@${PG_VER}-${PG_CLUSTER}" 2>/dev/null \
    || pg_ctlcluster "${PG_VER}" "${PG_CLUSTER}" restart 2>/dev/null || true
  for i in $(seq 1 30); do pg_isready -h "${PG_SOCKET_DIR}" -p "${PG_PORT}" >/dev/null 2>&1 && break; sleep 1; done
  ${PSQL_SU} -d "${DB_NAME}" -c "ALTER EXTENSION timescaledb UPDATE;" >/dev/null 2>&1 \
    && ok "TimescaleDB updated to ${AVAILABLE_TS}" \
    || warn "ALTER EXTENSION timescaledb UPDATE failed — check manually"
fi
# Reparar drift de propiedad ANTES del baseline. CREATE TABLE IF NOT EXISTS no
# cambia el dueño de objetos heredados; sin esto fallan CDR, rollups y los
# índices CONCURRENTLY del portal aunque el rol/base actuales sean correctos.
${PSQL_SU} -d "${DB_NAME}" -v vw_owner="${DB_USER}" \
  < "${EXTRACTED}/repair-ownership.sql" >/dev/null \
  || err "Could not repair PostgreSQL ownership and privileges"
# El SQL se pasa por STDIN (lo lee el shell de root); así voxywatch NO necesita
# permiso de lectura sobre el archivo en el TMPDIR de root (mktemp es 700).
sudo -u "${SERVICE_USER}" psql -h "${PG_SOCKET_DIR}" -p "${PG_PORT}" -d "${DB_NAME}" \
     -v ON_ERROR_STOP=1 -f - < "${EXTRACTED}/schema.sql" >/dev/null \
  || err "Could not apply the schema (schema.sql)"
VW_MIGRATIONS_DIR="${INSTALL_DIR}/migrations" \
  sudo -u "${SERVICE_USER}" "${INSTALL_DIR}/migrate.sh" \
    -h "${PG_SOCKET_DIR}" -p "${PG_PORT}" -d "${DB_NAME}" \
  || err "Could not apply versioned database migrations"
ok "PostgreSQL + TimescaleDB ready (cluster ${PG_VER}/${PG_CLUSTER}, :${PG_PORT}, peer socket)"

# ── Kernel network tuning (v2.0.5) ────────────────────────────────────────────
# El sniffer pide SO_RCVBUF de 8 MB, pero el kernel lo recorta a net.core.rmem_max
# (default de fábrica 212992 ≈ 416 KB). Subimos los límites para absorber ráfagas de
# RTP. NOTA: esto ayuda con picos, NO sustituye el desacople recv/insert del sniffer.
info "Applying kernel network tuning..."
cat > /etc/sysctl.d/99-voxywatch.conf << 'EOF'
# VoxyWatch — buffers de recepción UDP para captura HEP/RTP de alto volumen
net.core.rmem_max = 33554432
net.core.rmem_default = 16777216
net.core.netdev_max_backlog = 10000
EOF
sysctl -p /etc/sysctl.d/99-voxywatch.conf >/dev/null 2>&1 \
  && ok "Kernel buffers applied (rmem_max=32M)" \
  || warn "Could not apply sysctl now (they will apply on reboot)"

# ── Install systemd unit files ────────────────────────────────────────────────
info "Installing systemd units..."
AGENTIC_WAS_ACTIVE=0
AGENTIC_WAS_ENABLED=0
systemctl is-active --quiet voxywatch-agentic.service 2>/dev/null && AGENTIC_WAS_ACTIVE=1 || true
systemctl is-enabled --quiet voxywatch-agentic.service 2>/dev/null && AGENTIC_WAS_ENABLED=1 || true

# Heap V8 del portal: el binario pkg/SEA IGNORA --max-old-space-size (probado 2026-06-25) — vía NODE_OPTIONS
# o vía argv da igual: V8 crea su isolate desde el snapshot del binario ANTES de leer cualquier flag, y
# v8.setFlagsFromString() en runtime tampoco eleva heap_size_limit. Así que el portal corre con el heap
# DEFAULT de V8, que YA escala con la RAM física de la caja (~4 GB en cajas grandes). NO es un problema:
#   1) el working-set se auto-dimensiona al heap REAL (effectiveMaxRows usa v8.getHeapStatistics().heap_size_limit);
#   2) la auto-protección de heap poda el working-set bajo presión antes del OOM (Mem #2);
#   3) con el raw SIP fuera del heap (Mem #1) el uso típico es ~1/3 del default.
# El OOM histórico (TICKET-032) lo cerró ese dimensionamiento al heap real + Mem #1 — NUNCA un
# --max-old-space-size más alto (que jamás surtió efecto en el binario). NO reponer NODE_OPTIONS de heap:
# es placebo y miente sobre el límite real. Un valor fijo horneado en pkg sería inseguro en cajas chicas.

cat > /etc/systemd/system/voxywatch.service << EOF
[Unit]
Description=VoxyWatch SIP Capture Portal
Documentation=https://voxywatch.com/docs
After=network.target postgresql@${PG_VER}-${PG_CLUSTER}.service voxywatch-sniffer.service
Wants=postgresql@${PG_VER}-${PG_CLUSTER}.service

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_USER}
WorkingDirectory=${DATA_DIR}
# Readiness: systemd After= no garantiza que PG acepte queries.
ExecStartPre=/usr/bin/pg_isready -h ${PG_SOCKET_DIR} -p ${PG_PORT} -t 30
ExecStart=${INSTALL_DIR}/voxywatch-portal
Environment=PORT=${PORT}
# Legacy updates preserve their historical listener for compatibility. Platform readiness marks
# a non-loopback backend as critical until the operator performs a controlled managed-HTTPS migration.
Environment=VOXYWATCH_BIND_HOST=$([ "$HTTPS_MODE" = "legacy" ] && printf '' || printf '127.0.0.1')
Environment=VOXYWATCH_HTTPS_MODE=$([ "$HTTPS_MODE" = "legacy" ] && printf '' || printf '%s' "$HTTPS_MODE")
Environment=VOXYWATCH_HTTPS_HOST=$([ "$HTTPS_MODE" = "legacy" ] && printf '' || printf '%s' "$HTTPS_HOST")
Environment=VOXYWATCH_DATA_DIR=${DATA_DIR}
Environment=PGHOST=${PG_SOCKET_DIR}
Environment=PGPORT=${PG_PORT}
Environment=PGDATABASE=${DB_NAME}
Environment=PGUSER=${DB_USER}
${REPLICA_ENV}
Restart=always
RestartSec=5
LimitNOFILE=65536
NoNewPrivileges=true
# SNMP: permitir bindear puertos privilegiados (161 estándar) corriendo como usuario no-root.
# Compatible con NoNewPrivileges=true (la capability la otorga systemd al exec, no por setuid).
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
ProtectSystem=strict
ReadWritePaths=${DATA_DIR} ${CONF_DIR} /tmp ${PG_SOCKET_DIR}
PrivateTmp=yes
StandardOutput=journal
StandardError=journal
SyslogIdentifier=voxywatch

[Install]
WantedBy=multi-user.target
EOF

# A few pre-managed demo/early installs used the exact VoxyWatch reverse-proxy
# shape before the ownership marker existed. Recognize only that narrow shape;
# any extra site/directive remains unmanaged and fails closed.
_caddy_is_legacy_voxywatch() {
  local file="${1:-/etc/caddy/Caddyfile}" normalized expected
  [ -f "$file" ] || return 1
  normalized="$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$file")"
  for backend in "localhost:${PORT}" "127.0.0.1:${PORT}"; do
    expected="$(printf '%s {\nreverse_proxy %s\n}' "$HTTPS_HOST" "$backend")"
    [ "$normalized" = "$expected" ] && return 0
    expected="$(printf '%s {\nreverse_proxy %s\nencode zstd gzip\n}' "$HTTPS_HOST" "$backend")"
    [ "$normalized" = "$expected" ] && return 0
  done
  return 1
}

# Manage Caddy only for a fresh install or an explicitly requested dependency
# refresh. Normal signed product updates preserve the installed proxy/version.
if [ "$HTTPS_MODE" != "legacy" ] && { [ "$UPDATE_MODE" = "0" ] || [ "$REFRESH_EXTERNAL_DEPS" = "1" ]; }; then
  install -d -o root -g caddy -m 750 /etc/caddy
  if [ "$CADDY_WAS_INSTALLED" = "1" ] && [ -s /etc/caddy/Caddyfile ] \
     && ! grep -q '^# Managed by VoxyWatch installer$' /etc/caddy/Caddyfile \
     && ! _caddy_is_legacy_voxywatch /etc/caddy/Caddyfile; then
    err "An unmanaged Caddy configuration already exists; VoxyWatch will not overwrite it"
  fi
  {
    echo '# Managed by VoxyWatch installer'
    echo "${HTTPS_HOST} {"
    [ "$HTTPS_MODE" = "internal" ] && echo '  tls internal'
    echo "  reverse_proxy 127.0.0.1:${PORT}"
    echo '  encode zstd gzip'
    echo '}'
  } > /etc/caddy/Caddyfile
  chown root:caddy /etc/caddy/Caddyfile
  chmod 640 /etc/caddy/Caddyfile
  caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile >/dev/null \
    || err "Generated Caddy HTTPS configuration is invalid"
fi

cat > /etc/systemd/system/voxywatch-sniffer.service << EOF
[Unit]
Description=VoxyWatch HEP Sniffer (HEPv1/v2/v3)
Documentation=https://voxywatch.com/docs
After=network.target postgresql@${PG_VER}-${PG_CLUSTER}.service
Wants=postgresql@${PG_VER}-${PG_CLUSTER}.service
Before=voxywatch.service

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_USER}
WorkingDirectory=${DATA_DIR}
ExecStartPre=/usr/bin/pg_isready -h ${PG_SOCKET_DIR} -p ${PG_PORT} -t 30
ExecStart=/usr/bin/python3 -u ${INSTALL_DIR}/hep_sniffer.py --quiet
Environment=VOXYWATCH_DATA_DIR=${DATA_DIR}
Environment=PGHOST=${PG_SOCKET_DIR}
Environment=PGPORT=${PG_PORT}
Environment=PGDATABASE=${DB_NAME}
Environment=PGUSER=${DB_USER}
Restart=always
RestartSec=5
NoNewPrivileges=true
ProtectSystem=strict
ReadWritePaths=${DATA_DIR} ${PG_SOCKET_DIR}
StandardOutput=journal
StandardError=journal
SyslogIdentifier=voxywatch-sniffer

[Install]
WantedBy=multi-user.target
EOF

# ── Update applier (oneshot, root) — lo dispara el portal por D-Bus+polkit (one-click update) ──
# El portal corre con NoNewPrivileges=true → NO puede sudo. En su lugar le pide a systemd (vía
# polkit) que arranque ESTE unit, que corre como root el helper root-owned apply-update.sh.
# Nunca se habilita: se arranca on-demand. systemd es su dueño → sobrevive al reinicio del portal.
cat > /etc/systemd/system/voxywatch-apply-update.service << EOF
[Unit]
Description=VoxyWatch — apply signed update (one-shot, triggered from the portal)
[Service]
Type=oneshot
ExecStart=${INSTALL_DIR}/apply-update.sh
# Root a propósito: instala el binario en /opt, units y reinicia servicios (lo que el update exige).
StandardOutput=journal
StandardError=journal
SyslogIdentifier=voxywatch-apply-update
EOF

# ── Web access applier (oneshot, root) ───────────────────────────────────────
# The portal only writes a bounded JSON request. This fixed root-owned helper
# validates the mode/host, refuses unmanaged Caddyfiles and rolls back Caddy,
# config and the systemd override if reload or portal restart fails.
cat > /etc/systemd/system/voxywatch-apply-web-access.service << EOF
[Unit]
Description=VoxyWatch — apply managed HTTPS web access (one-shot)
After=caddy.service
[Service]
Type=oneshot
ExecStart=${INSTALL_DIR}/apply-web-access.py
UMask=0027
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
StandardOutput=journal
StandardError=journal
SyslogIdentifier=voxywatch-apply-web-access
EOF

# ── SIPREC SRS (grabación directa desde SBC) — proceso APARTE, OFF por default ──
# v2.81: el SRS recibe SIPREC del SBC y escribe al MISMO almacén .seg/.idx que el sniffer.
# Se instala DORMANTE y NI SIQUIERA se habilita/arranca: el unit queda en disco, detenido y
# disabled. El admin lo activa explícitamente al prender SIPREC (siprec_enabled=true en
# Settings → SIPREC  +  systemctl enable --now voxywatch-srs). Doble candado: aunque alguien
# lo arranque, el flag siprec_enabled=false (default) hace que salga sin abrir puertos.
# Así una instalación previa (cuyo settings.json no trae la clave) JAMÁS expone el 5060.
# Si el SRS cae, la captura HEP NO se ve afectada (proceso separado). SRTP: pylibsrtp (best-effort).
if [ -f "${INSTALL_DIR}/voxywatch_srs.py" ]; then
  info "Provisioning SIPREC SRS (OFF by default)..."
  # Una instalación nueva queda dormida. En una actualización, preservar el opt-in solo si
  # coinciden las dos fuentes de verdad: unit previamente enabled + flag persistido true.
  # Esto evita apagar grabación SIPREC en cada release sin revivir el bug histórico default-ON.
  SRS_RESTORE_ENABLED=0
  if systemctl is-enabled --quiet voxywatch-srs.service 2>/dev/null \
     && python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); raise SystemExit(0 if d.get("siprec_enabled") is True else 1)' \
          "${DATA_DIR}/voxywatch_settings.json" 2>/dev/null; then
    SRS_RESTORE_ENABLED=1
  fi
  systemctl stop voxywatch-srs.service >/dev/null 2>&1 || true
  # The isolated SRTP environment is preserved on normal product updates.
  # It is created on first install and refreshed only in an explicit external
  # dependency maintenance run. The approved pylibsrtp version is exact.
  SRS_PY="/usr/bin/python3"
  if [ -x "${INSTALL_DIR}/srs-venv/bin/python" ] \
     && [ "$REFRESH_EXTERNAL_DEPS" = "0" ]; then
    SRS_PY="${INSTALL_DIR}/srs-venv/bin/python"
    ok "SRS: preserving installed pylibsrtp environment"
  elif [ "$UPDATE_MODE" = "0" ] || [ "$REFRESH_EXTERNAL_DEPS" = "1" ]; then
    if command -v apt-get >/dev/null 2>&1 && ! python3 -m ensurepip --version >/dev/null 2>&1; then
      apt-get install -y --no-install-recommends python3-venv >/dev/null 2>&1 || true
    fi
    if python3 -m venv --clear "${INSTALL_DIR}/srs-venv" >/dev/null 2>&1; then
    SRS_VPY="${INSTALL_DIR}/srs-venv/bin/python"
    [ -x "${INSTALL_DIR}/srs-venv/bin/pip" ] || "$SRS_VPY" -m ensurepip >/dev/null 2>&1 || true
    if "$SRS_VPY" -m pip install --quiet --disable-pip-version-check 'pylibsrtp==1.0.0' > /var/log/voxywatch-srs-pip.log 2>&1; then
      SRS_PY="$SRS_VPY"
      ok "SRS: approved pylibsrtp 1.0.0 installed (SRTP available)"
    else
      warn "SRS: pylibsrtp could not be installed → SRTP unavailable (cleartext RTP still works). Details: /var/log/voxywatch-srs-pip.log"
    fi
    chown -R "${SERVICE_USER}:${SERVICE_USER}" "${INSTALL_DIR}/srs-venv" 2>/dev/null || true
    else
      warn "SRS: could not create venv (install python3-venv) → SRS will run with the system python, without SRTP."
    fi
  else
    warn "SRS dependency environment is missing; normal updates do not install external software. Run a controlled refresh to enable SRTP."
  fi
  cat > /etc/systemd/system/voxywatch-srs.service << EOF
[Unit]
Description=VoxyWatch SRS (SIPREC Session Recording Server)
Documentation=https://voxywatch.com/docs
After=network-online.target postgresql@${PG_VER}-${PG_CLUSTER}.service voxywatch.service
Wants=network-online.target

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_USER}
WorkingDirectory=${DATA_DIR}
ExecStart=${SRS_PY} ${INSTALL_DIR}/voxywatch_srs.py
Environment=VOXYWATCH_DATA_DIR=${DATA_DIR}
Environment=PGHOST=${PG_SOCKET_DIR}
Environment=PGPORT=${PG_PORT}
Environment=PGDATABASE=${DB_NAME}
Environment=PGUSER=${DB_USER}
Restart=on-failure
RestartSec=5
UMask=0027
NoNewPrivileges=true
ProtectSystem=full
PrivateTmp=true
ReadWritePaths=${DATA_DIR} ${PG_SOCKET_DIR}
StandardOutput=journal
StandardError=journal
SyslogIdentifier=voxywatch-srs

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload 2>/dev/null || true
  if [ "$SRS_RESTORE_ENABLED" = "1" ]; then
    systemctl enable --now voxywatch-srs.service >/dev/null 2>&1 \
      || warn "SRS was opted in but could not be restarted; check systemctl status voxywatch-srs"
    ok "SIPREC SRS updated and prior explicit opt-in restored"
  else
    systemctl disable --now voxywatch-srs.service >/dev/null 2>&1 || true
    ok "SIPREC SRS installed (DORMANT and disabled; enable it with siprec_enabled=true + systemctl enable --now voxywatch-srs)"
  fi
fi

# ── Agentic runtime (ADK sidecar) — proceso APARTE, loopback, OFF por default ─
# v3.0: el runtime agéntico viaja con cada update, pero no abre puertos externos ni
# controla el SBC. Si ya estaba activo/habilitado antes del update, preservamos ese
# estado; en instalaciones nuevas queda instalado y apagado hasta opt-in.
if [ -f "${INSTALL_DIR}/agentic/voxywatch_agentic.py" ]; then
  info "Provisioning VoxyWatch Agentic runtime (ADK sidecar, loopback)..."
  if [ -f "${INSTALL_DIR}/agentic/voxywatch-agentic.service" ]; then
    install -o root -g root -m 644 "${INSTALL_DIR}/agentic/voxywatch-agentic.service" /etc/systemd/system/voxywatch-agentic.service
  else
    cat > /etc/systemd/system/voxywatch-agentic.service << EOF
[Unit]
Description=VoxyWatch Agentic Runtime (ADK sidecar)
After=network-online.target voxywatch.service
Wants=network-online.target

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_USER}
WorkingDirectory=${INSTALL_DIR}/agentic
EnvironmentFile=-${CONF_FILE}
Environment=VOXYWATCH_AGENTIC_HOST=127.0.0.1
Environment=VOXYWATCH_AGENTIC_PORT=3081
ExecStart=${INSTALL_DIR}/agentic/run-agentic.sh
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${DATA_DIR}
CapabilityBoundingSet=
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
SyslogIdentifier=voxywatch-agentic

[Install]
WantedBy=multi-user.target
EOF
  fi
  systemctl daemon-reload 2>/dev/null || true
  if [ "$REFRESH_EXTERNAL_DEPS" = "1" ] \
     && { [ "$AGENTIC_WAS_ENABLED" = "1" ] || [ "$AGENTIC_WAS_ACTIVE" = "1" ] \
          || [ -x "${INSTALL_DIR}/agentic/.venv/bin/python" ]; }; then
    if [ -x "${INSTALL_DIR}/agentic/install-agentic-deps.sh" ]; then
      info "Installing controlled Agentic Python dependency lock (explicit refresh)..."
      if "${INSTALL_DIR}/agentic/install-agentic-deps.sh" >/var/log/voxywatch-agentic-deps.log 2>&1; then
        ok "Agentic dependencies updated"
      else
        warn "Agentic dependencies could not be updated; sidecar will keep deterministic fallback. Details: /var/log/voxywatch-agentic-deps.log"
      fi
    fi
  elif [ "$AGENTIC_WAS_ENABLED" = "1" ] || [ "$AGENTIC_WAS_ACTIVE" = "1" ]; then
    info "Preserving installed Agentic Python dependencies (normal VoxyWatch update)"
  fi
  if [ "$AGENTIC_WAS_ENABLED" = "1" ]; then
    systemctl enable voxywatch-agentic.service >/dev/null 2>&1 || true
  else
    systemctl disable voxywatch-agentic.service >/dev/null 2>&1 || true
  fi
  if [ "$AGENTIC_WAS_ACTIVE" = "1" ]; then
    systemctl restart voxywatch-agentic.service >/dev/null 2>&1 || warn "Could not restart voxywatch-agentic"
    ok "Agentic runtime updated and restarted"
  else
    systemctl stop voxywatch-agentic.service >/dev/null 2>&1 || true
    ok "Agentic runtime installed (disabled until enabled)"
  fi
fi

# ── Service-control scripts (opt-in privilege grant) ──────────────────────────
# Generated ALWAYS so the admin can enable/disable later without reinstalling.
# Executed now only if the admin opted in above. The grant is scoped via a polkit
# rule (works with NoNewPrivileges=true — busctl/systemctl only send a D-Bus
# message; systemd performs the action after polkit authorizes it).
cat > "${INSTALL_DIR}/enable-service-control.sh" << 'ENABLE_EOF'
#!/bin/bash
# VoxyWatch — grant the portal permission to manage ONLY its own services.
# Usage (as root):  sudo /opt/voxywatch/enable-service-control.sh
set -euo pipefail
[ "$EUID" -ne 0 ] && { echo "Must run as root:  sudo $0"; exit 1; }
SERVICE_USER="voxywatch"
CONF_FILE="/etc/voxywatch/voxywatch.conf"

# Never claim success by writing a rule that no authorization daemon can load.
command -v pkaction >/dev/null 2>&1 || {
  echo "polkit is required for service control. Install package 'polkitd' and retry." >&2
  exit 1
}

# 1) polkit rule — scoped to VoxyWatch's own units only
mkdir -p /etc/polkit-1/rules.d
cat > /etc/polkit-1/rules.d/49-voxywatch.rules << RULE
// VoxyWatch: allow ${SERVICE_USER} to manage ONLY its own services.
polkit.addRule(function(action, subject) {
    if (subject.user != "${SERVICE_USER}") return;
    if (action.id == "org.freedesktop.systemd1.manage-units") {
        var u = action.lookup("unit");
        if (u == "voxywatch-sniffer.service" || u == "voxywatch-srs.service" ||
            u == "voxywatch-agentic.service" ||
            u == "voxywatch-apply-update.service" ||
            u == "voxywatch-apply-web-access.service")
            return polkit.Result.YES;
    }
    // enable/disable persistente SOLO del SRS (la pestaña Settings → SIPREC lo activa en boot).
    if (action.id == "org.freedesktop.systemd1.manage-unit-files") {
        var uf = action.lookup("unit");
        if (uf == "voxywatch-srs.service" || uf == "voxywatch-agentic.service")
            return polkit.Result.YES;
    }
});
RULE
chmod 644 /etc/polkit-1/rules.d/49-voxywatch.rules

# Remove the historical OS-settings write grant. Timezone, NTP and DNS are
# diagnostic/read-only in current VoxyWatch releases.
rm -f /etc/systemd/system/voxywatch.service.d/service-control.conf

# 2b) limpiar el sudoers de update de v2.83.0 (inútil bajo NoNewPrivileges=true: sudo no puede
# escalar desde el portal). El one-click update ahora va por D-Bus+polkit (manage-units del
# unit voxywatch-apply-update.service, ya cubierto por la regla de arriba) — no por sudo.
rm -f /etc/sudoers.d/voxywatch-update

# 3) persist state + reload
if grep -q '^SERVICE_CONTROL=' "$CONF_FILE" 2>/dev/null; then
    grep -v '^SERVICE_CONTROL=' "$CONF_FILE" > "${CONF_FILE}.tmp" && mv "${CONF_FILE}.tmp" "$CONF_FILE"
fi
echo "SERVICE_CONTROL=enabled" >> "$CONF_FILE"
systemctl reload polkit 2>/dev/null || systemctl restart polkit 2>/dev/null || true
systemctl daemon-reload
systemctl restart voxywatch 2>/dev/null || true
echo "✓ Service control ENABLED — the portal can restart VoxyWatch services and apply signed updates with one click."
ENABLE_EOF
chmod 750 "${INSTALL_DIR}/enable-service-control.sh"
chown root:voxywatch "${INSTALL_DIR}/enable-service-control.sh" 2>/dev/null || true

cat > "${INSTALL_DIR}/disable-service-control.sh" << 'DISABLE_EOF'
#!/bin/bash
# VoxyWatch — revoke the portal's permission to manage services.
# Usage (as root):  sudo /opt/voxywatch/disable-service-control.sh
set -euo pipefail
[ "$EUID" -ne 0 ] && { echo "Must run as root:  sudo $0"; exit 1; }
CONF_FILE="/etc/voxywatch/voxywatch.conf"
rm -f /etc/polkit-1/rules.d/49-voxywatch.rules
rm -f /etc/polkit-1/rules.d/49-voxywatch-sniffer.rules
rm -f /etc/systemd/system/voxywatch.service.d/service-control.conf
rm -f /etc/sudoers.d/voxywatch-update
if grep -q '^SERVICE_CONTROL=' "$CONF_FILE" 2>/dev/null; then
    grep -v '^SERVICE_CONTROL=' "$CONF_FILE" > "${CONF_FILE}.tmp" && mv "${CONF_FILE}.tmp" "$CONF_FILE"
fi
echo "SERVICE_CONTROL=disabled" >> "$CONF_FILE"
systemctl reload polkit 2>/dev/null || systemctl restart polkit 2>/dev/null || true
systemctl daemon-reload
systemctl restart voxywatch 2>/dev/null || true
echo "✓ Service control DISABLED — the portal will now show manual commands instead."
DISABLE_EOF
chmod 750 "${INSTALL_DIR}/disable-service-control.sh"
chown root:voxywatch "${INSTALL_DIR}/disable-service-control.sh" 2>/dev/null || true

# ── Privileged update helper (root-owned) ─────────────────────────────────────
# Installed ALWAYS. Root-owned, group-executable by voxywatch but NOT writable by it
# (0750 root:voxywatch). Lets the portal apply a one-click update through the scoped
# systemd/polkit unit WITHOUT granting general root. It only ever
# runs the OFFICIAL signed installer in --update mode — the unprivileged caller cannot
# inject a target (no arguments are honored), and install.sh re-verifies GPG + SHA-256
# before touching anything. This is the single privileged operation the portal can run.
cat > "${INSTALL_DIR}/apply-update.sh" << UPDHELPER
#!/bin/bash
# VoxyWatch — privileged update helper. DO NOT add arguments here: the polkit grant is
# scoped to the fixed systemd unit, so the caller can only ask for the official latest.
set -euo pipefail
LOG=/var/log/voxywatch-update.log
exec >> "\$LOG" 2>&1
echo "[\$(date -Is)] apply-update invoked (euid=\$EUID)"
if [ "\$EUID" -ne 0 ]; then echo "ERROR: must run as root"; exit 1; fi
TRUSTED_INSTALLER="${INSTALL_DIR}/install.sh"
if [ ! -f "\$TRUSTED_INSTALLER" ] || [ ! -O "\$TRUSTED_INSTALLER" ]; then
  echo "ERROR: trusted root-owned installer is missing"; exit 1
fi
if find "\$TRUSTED_INSTALLER" -maxdepth 0 -perm /022 -print -quit | grep -q .; then
  echo "ERROR: trusted installer is writable by group or others"; exit 1
fi
echo "[\$(date -Is)] running trusted local install.sh --update"
# Reemplaza el proceso del helper. El instalador sobrescribe apply-update.sh durante
# el upgrade; si Bash siguiera leyendo este archivo después, podría mezclar bytes de
# ambas versiones y terminar con un falso error de sintaxis aunque el update concluyera.
exec bash "\$TRUSTED_INSTALLER" --update
UPDHELPER
chmod 750 "${INSTALL_DIR}/apply-update.sh"
# Ownership is SECURITY-CRITICAL (must be root-owned so voxywatch can't rewrite what it sudo-runs).
# No `|| true` here: with set -e a failed chown aborts the install — fail closed.
chown root:voxywatch "${INSTALL_DIR}/apply-update.sh"
ok "Service-control scripts installed"

# Clean up any legacy unconditional rule from earlier installs
rm -f /etc/polkit-1/rules.d/49-voxywatch-sniffer.rules 2>/dev/null || true

if [ "$SERVICE_CONTROL" = "yes" ]; then
  info "Enabling service control (opted in)..."
  bash "${INSTALL_DIR}/enable-service-control.sh" || warn "Could not enable service control automatically"
else
  # Make sure no stale grant remains when the admin opted out
  rm -f /etc/polkit-1/rules.d/49-voxywatch.rules /etc/systemd/system/voxywatch.service.d/service-control.conf /etc/sudoers.d/voxywatch-update 2>/dev/null || true
  systemctl reload polkit 2>/dev/null || true
fi

systemctl daemon-reload
systemctl enable voxywatch voxywatch-sniffer
ok "Systemd units installed and enabled"

# ── Updates: aviso en el portal, NO auto-aplicar (v2.80) ────────────────────────
# A partir de v2.80 VoxyWatch NO se auto-actualiza. El portal verifica cada hora si
# hay una versión nueva y la avisa en la campana; el admin aplica con un clic desde
# Settings → Actualización (POST /api/update, firmado + SHA256). Esto le da control
# total al operador (nada cambia solo a media operación).
#
# MIGRACIÓN: si esta instalación venía con el auto-updater viejo (timer/servicio
# diario que aplicaba solo), lo retiramos aquí. Idempotente: si no existe, no hace nada.
# ⚠ OJO (lección v2.80.1): cuando el updater VIEJO dispara este install.sh, lo corre DENTRO
# de `voxywatch-update.service`. Por eso NUNCA hacemos `systemctl stop voxywatch-update.service`
# aquí — nos mataríamos a nosotros mismos (SIGTERM) a media instalación. Basta con deshabilitar
# el TIMER (corta disparos futuros) y BORRAR los archivos de unidad: el oneshot en curso termina
# solo y `daemon-reload` no mata procesos vivos.
info "Removing legacy auto-updater (updates are now opt-in from the portal)..."
systemctl disable --now voxywatch-update.timer >/dev/null 2>&1 || true
rm -f /etc/systemd/system/voxywatch-update.timer \
      /etc/systemd/system/voxywatch-update.service \
      "${INSTALL_DIR}/voxywatch-update.sh" 2>/dev/null || true
systemctl daemon-reload
ok "Updates: opt-in — the portal notifies you, the admin applies with one click"

# ── Start services ────────────────────────────────────────────────────────────
info "Starting services..."
systemctl start voxywatch-sniffer
systemctl start voxywatch
if [ "$HTTPS_MODE" != "legacy" ]; then
  systemctl enable caddy >/dev/null 2>&1 || err "Caddy could not be enabled"
  systemctl reload-or-restart caddy >/dev/null 2>&1 || err "Caddy could not load managed HTTPS"
  systemctl is-active --quiet caddy || err "Caddy HTTPS service is not active"
  ok "caddy active (${HTTPS_MODE} HTTPS)"
fi

# v2.0.4: verificar que ambos quedaron activos (un update no debe dejar el sistema
# abajo). Si alguno no levantó, reintentar una vez y avisar dónde mirar.
sleep 1
SERVICE_START_FAILED=0
for _svc in voxywatch-sniffer voxywatch; do
  if systemctl is-active --quiet "$_svc"; then
    ok "${_svc} active"
  else
    warn "${_svc} did not come up — retrying..."
    systemctl restart "$_svc" 2>/dev/null || true
    sleep 1
    if systemctl is-active --quiet "$_svc"; then
      ok "${_svc} active (after retry)"
    else
      warn "${_svc} is NOT active — check: journalctl -u ${_svc} -n 50 --no-pager"
      SERVICE_START_FAILED=1
    fi
  fi
done
[ "$SERVICE_START_FAILED" = "0" ] \
  || err "Installation files were applied, but one or more core services failed health verification"

# The new release is healthy. Keep the root-only snapshot for an explicit
# operator rollback, but disarm automatic restoration before final reporting.
ROLLBACK_READY=0
trap - ERR

# ── Get HWID ──────────────────────────────────────────────────────────────────
SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "YOUR-IP")
HWID=""
if command -v node &>/dev/null && [ -f "${INSTALL_DIR}/get-hwid.js" ]; then
  HWID=$(node "${INSTALL_DIR}/get-hwid.js" 2>/dev/null | grep -oP '[0-9a-f]{32}' | head -1 || true)
fi

# ── Final summary ─────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════"
if [ "$UPDATE_MODE" = "1" ] && [ "$EXISTING_INSTALL" = "1" ]; then
  echo -e "  ${GREEN}✓ VoxyWatch updated successfully${NC}"
  if [ -n "$PREVIOUS_VERSION" ] && [ "$PREVIOUS_VERSION" != "$VERSION" ]; then
    echo "    Version: v${PREVIOUS_VERSION} → v${VERSION}"
  else
    echo "    Version: v${VERSION}"
  fi
  echo "    Existing configuration and user credentials were preserved."
else
  echo -e "  ${GREEN}✓ VoxyWatch v${VERSION} installed successfully${NC}"
fi
echo "══════════════════════════════════════════════"
echo ""
echo -e "  ${BOLD}Web portal:${NC}"
if [ "$HTTPS_MODE" = "legacy" ]; then
  echo -e "  ${CYAN}Use the existing HTTPS endpoint${NC}"
else
  echo -e "  ${CYAN}https://${HTTPS_HOST}${NC}"
  [ "$HTTPS_MODE" = "internal" ] && echo "  Private CA: clients must trust Caddy's root certificate once."
fi
if [ "$UPDATE_MODE" = "0" ] || [ "$EXISTING_INSTALL" = "0" ]; then
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
  echo "    Or securely from the command line:"
  echo "      sudo ${INSTALL_DIR}/voxywatch-portal license install /path/to/license.key"
  echo "      sudo ${INSTALL_DIR}/voxywatch-portal license install --stdin < license.key"
  echo "    Convenience alias (fresh install or after this installer has run): voxywatch-license"
  echo ""
  echo -e "  ${BOLD}LLM credential${NC} (optional, never pass the value as an argument):"
  echo "      sudo voxywatch-ai-key set --provider openai --stdin"
  echo "    Or select a customer-managed system credential/environment in Settings → LLM"
  echo ""
  echo -e "  ${BOLD}Initial setup CLI${NC} (LLM selection, trunks and IP directory; no secrets):"
  echo "      sudo voxywatch-setup status"
  echo "      sudo voxywatch-setup validate --stdin < setup.json"
fi
echo ""
echo -e "  ${BOLD}Service logs:${NC}"
echo "    journalctl -fu voxywatch"
echo "    journalctl -fu voxywatch-sniffer"
echo ""
echo -e "  ${BOLD}Updates:${NC} opt-in — the portal checks hourly and notifies you in the bell 🔔"
echo "    Apply with one click from:  Settings → Update → Update now"
echo "    (no longer auto-updates — you decide when)"
echo ""

} # end of main()

main "$@"
