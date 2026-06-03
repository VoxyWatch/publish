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
err()  { echo -e "${RED}  ✗${NC} $1"; exit 1; }
info() { echo -e "${CYAN}  →${NC} $1"; }
# tty_ok: ¿hay terminal interactiva para prompts? Silencioso si no la hay (timer,
# ssh sin tty, curl|bash sin terminal) — evita el ruido "/dev/tty: No such device".
tty_ok() { { true </dev/tty; } 2>/dev/null; }

echo ""
echo "══════════════════════════════════════════════"
echo "   VoxyWatch — Installer"
echo "══════════════════════════════════════════════"
echo ""

# ── Pre-flight checks ─────────────────────────────────────────────────────────
[ "$EUID" -ne 0 ] && err "Must run as root:  curl -fsSL https://raw.githubusercontent.com/${GITHUB_ORG}/${GITHUB_REPO}/main/install.sh | sudo bash"
command -v curl    &>/dev/null || err "curl is required:  apt install curl   or   yum install curl"
command -v python3 &>/dev/null || err "python3 is required:  apt install python3   or   yum install python3"

# ── Mutex de instalación (v2.0.4) ─────────────────────────────────────────────
# Evita que una instalación MANUAL y el auto-updater (voxywatch-update.timer) corran
# a la vez. Un solape provocó servicios caídos: un run hacía 'systemctl stop' mientras
# el otro ya había arrancado el portal, y el segundo 'install' del binario en uso
# fallaba (set -e → aborto antes de re-arrancar). Con el lock, el segundo sale limpio.
if command -v flock &>/dev/null; then
  exec 9>"/run/voxywatch-install.lock" 2>/dev/null || exec 9>"/tmp/voxywatch-install.lock"
  if ! flock -n 9; then
    err "Otra instalación/actualización de VoxyWatch está en curso — aborto para no colisionar. Reintenta en unos minutos."
  fi
fi

# ── Parse arguments ───────────────────────────────────────────────────────────
VERSION=""
PORT_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --port)    PORT_ARG="$2"; shift 2 ;;
    --service-control) SERVICE_CONTROL_ARG="$2"; shift 2 ;;
    --replica-dsn) REPLICA_DSN="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# P2 (opt-in): réplica de lectura. Si se pasa --replica-dsn o está la env VOXYWATCH_DB_REPLICA_DSN,
# el portal enruta sus LECTURAS (UI/métricas/CDR) a la réplica; escrituras e ingesta van al primario.
# El cliente configura la replicación streaming de PostgreSQL aparte; aquí solo se enchufa el DSN.
REPLICA_DSN="${REPLICA_DSN:-${VOXYWATCH_DB_REPLICA_DSN:-}}"
REPLICA_ENV=""
if [ -n "$REPLICA_DSN" ]; then
  REPLICA_ENV="Environment=VOXYWATCH_DB_REPLICA_DSN=${REPLICA_DSN}"
fi

# ── Fetch latest version and asset info ───────────────────────────────────────
if [ -z "$VERSION" ]; then
  info "Fetching latest version..."
  MANIFEST_JSON=$(curl -fsSL --max-time 15 "$VERSION_MANIFEST" 2>/dev/null \
    || err "Could not fetch version manifest from ${VERSION_MANIFEST}")
  VERSION=$(echo "$MANIFEST_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['version'])" 2>/dev/null \
    || err "Could not parse version from manifest")
  EXPECTED_SHA256=$(echo "$MANIFEST_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin).get('linux_x64',{}).get('sha256',''))" 2>/dev/null || echo "")
else
  # Version specified manually — fetch its sha256 from the manifest SOLO si el
  # manifiesto describe esa misma versión. El manifiesto es el canal "latest"; si
  # se pide una versión distinta (p.ej. instalar 2.0.0 mientras el canal está en
  # 1.2.x para no auto-desplegar el cambio breaking), su sha NO aplica → se omite
  # la verificación (la descarga es HTTPS desde GitHub Releases).
  MANIFEST_JSON=$(curl -fsSL --max-time 15 "$VERSION_MANIFEST" 2>/dev/null || echo "{}")
  MANIFEST_VERSION=$(echo "$MANIFEST_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin).get('version',''))" 2>/dev/null || echo "")
  if [ "$MANIFEST_VERSION" = "$VERSION" ]; then
    EXPECTED_SHA256=$(echo "$MANIFEST_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin).get('linux_x64',{}).get('sha256',''))" 2>/dev/null || echo "")
  else
    EXPECTED_SHA256=""
    info "Versión ${VERSION} difiere del canal (${MANIFEST_VERSION:-?}); se omite verificación SHA del manifiesto."
  fi
fi
ok "Version to install: v${VERSION}"

# ── Port selection ────────────────────────────────────────────────────────────
if [ -n "$PORT_ARG" ]; then
  PORT="$PORT_ARG"
else
  echo ""
  if tty_ok; then
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

# ── Service control permission (opt-in) ───────────────────────────────────────
# Lets the unprivileged ${SERVICE_USER} user restart its OWN services and apply
# timezone/NTP/DNS from the web portal — a scoped, non-root grant (see the
# generated enable-service-control.sh for exactly what it allows).
SERVICE_CONTROL="no"
# Preserve the previous choice on re-install / auto-update.
PREV_SC=""
[ -f "${CONF_FILE}" ] && PREV_SC=$(grep -oP '(?<=^SERVICE_CONTROL=)\S+' "${CONF_FILE}" 2>/dev/null || echo "")
if [ -n "${SERVICE_CONTROL_ARG:-}" ]; then
  case "$SERVICE_CONTROL_ARG" in yes|enabled|y) SERVICE_CONTROL="yes" ;; *) SERVICE_CONTROL="no" ;; esac
elif [ "$PREV_SC" = "enabled" ]; then
  SERVICE_CONTROL="yes"   # keep prior grant across updates
elif tty_ok; then
  echo -e "  ${BOLD}Service control${NC}"
  echo "  VoxyWatch can restart its own services (the HEP sniffer) and apply"
  echo "  timezone / NTP / DNS changes directly from the web portal."
  echo "  This is a SCOPED permission — limited to VoxyWatch's own services, not"
  echo "  general root. If you decline, the portal will instead show you the exact"
  echo "  command to run by hand each time (you can enable it later)."
  printf "  ${BOLD}Allow VoxyWatch to manage its own services?${NC} [y/N]: "
  read -r SC_INPUT </dev/tty 2>/dev/null || SC_INPUT=""
  case "$SC_INPUT" in [Yy]*) SERVICE_CONTROL="yes" ;; *) SERVICE_CONTROL="no" ;; esac
fi
if [ "$SERVICE_CONTROL" = "yes" ]; then
  ok "Service control: ENABLED (portal can restart its services)"
else
  ok "Service control: disabled (manual restarts — enable later if you want)"
fi
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
# Binario: instalar a un nombre temporal y renombrar (atómico). 'mv' reemplaza aunque
# el viejo siga mapeado/en uso, evitando 'File exists' / 'Text file busy' en updates.
install -o root -g voxywatch -m 750 "${EXTRACTED}/voxywatch-portal"   "${INSTALL_DIR}/voxywatch-portal.new"
mv -f "${INSTALL_DIR}/voxywatch-portal.new" "${INSTALL_DIR}/voxywatch-portal"
install -o root -g voxywatch -m 640 "${EXTRACTED}/hep_sniffer.py"     "${INSTALL_DIR}/hep_sniffer.py"
install -o root -g voxywatch -m 640 "${EXTRACTED}/get-hwid.js"        "${INSTALL_DIR}/get-hwid.js"
install -o root -g voxywatch -m 640 "${EXTRACTED}/migrate_to_db.js"   "${INSTALL_DIR}/migrate_to_db.js" 2>/dev/null || true
install -o root -g voxywatch -m 640 "${EXTRACTED}/generate_pcap.py"   "${INSTALL_DIR}/generate_pcap.py" 2>/dev/null || true
install -o root -g voxywatch -m 640 "${EXTRACTED}/reconstruct_audio.py" "${INSTALL_DIR}/reconstruct_audio.py" 2>/dev/null || true
install -o root -g voxywatch -m 640 "${EXTRACTED}/schema.sql"         "${INSTALL_DIR}/schema.sql" 2>/dev/null || true
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

# ── Provision PostgreSQL + TimescaleDB ────────────────────────────────────────
# Cluster local DEDICADO en puerto no-default (5433), bindeado a localhost, con
# auth peer por socket (sin password). Aislado del stack del cliente (5432/Influx).
info "Provisioning PostgreSQL + TimescaleDB (cluster ${PG_CLUSTER} en :${PG_PORT})..."
command -v apt-get &>/dev/null || err "La BD PostgreSQL+TimescaleDB requiere Debian/Ubuntu (apt). RHEL: contactar soporte."

# 1) Repo TimescaleDB + paquetes base (postgresql-common trae pg_createcluster;
#    python3-psycopg2 = cliente del sniffer, sin pip)
if [ ! -f /etc/apt/sources.list.d/timescaledb.list ]; then
  apt-get install -y gnupg lsb-release wget ca-certificates >/dev/null 2>&1 || true
  echo "deb https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/timescaledb.list
  wget -qO- https://packagecloud.io/timescale/timescaledb/gpgkey \
    | gpg --dearmor -o /etc/apt/trusted.gpg.d/timescaledb.gpg 2>/dev/null || true
fi
apt-get update >/dev/null 2>&1 || true
apt-get install -y postgresql postgresql-common python3-psycopg2 >/dev/null 2>&1 \
  || err "No se pudo instalar postgresql / python3-psycopg2"

# Detectar la versión mayor instalada y el paquete TimescaleDB correspondiente
PG_VER="$(ls /usr/lib/postgresql/ 2>/dev/null | sort -n | tail -1)"
[ -n "$PG_VER" ] || err "No se detectó PostgreSQL instalado en /usr/lib/postgresql"
apt-get install -y "timescaledb-2-postgresql-${PG_VER}" "timescaledb-tools" >/dev/null 2>&1 \
  || err "No se pudo instalar timescaledb-2-postgresql-${PG_VER}"

# 2) Crear el cluster dedicado si no existe (puerto no-default, auth local peer)
if ! pg_lsclusters -h 2>/dev/null | awk '{print $1" "$2}' | grep -qx "${PG_VER} ${PG_CLUSTER}"; then
  pg_createcluster "${PG_VER}" "${PG_CLUSTER}" -p "${PG_PORT}" -- --auth-local=peer >/dev/null \
    || err "pg_createcluster falló"
fi
PG_CONF_DIR="/etc/postgresql/${PG_VER}/${PG_CLUSTER}"

# 3) Endurecer: solo localhost, precargar timescaledb, afinar al hardware
sed -i "s/^#\?listen_addresses.*/listen_addresses = 'localhost'/" "${PG_CONF_DIR}/postgresql.conf"
grep -q "shared_preload_libraries.*timescaledb" "${PG_CONF_DIR}/postgresql.conf" \
  || echo "shared_preload_libraries = 'timescaledb'" >> "${PG_CONF_DIR}/postgresql.conf"
command -v timescaledb-tune &>/dev/null \
  && timescaledb-tune --quiet --yes --conf-path "${PG_CONF_DIR}/postgresql.conf" >/dev/null 2>&1 || true

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

# Mantener TimescaleDB al día, atado a cada update de VoxyWatch: el apt-get install
# de arriba ya sube el PAQUETE a la última versión disponible (default_version en
# disco). Si difiere de la versión cargada en la BD (extversion en el catálogo),
# se reinicia PG para cargar la librería nueva y se migra el catálogo con
# ALTER EXTENSION ... UPDATE. Los servicios ya están parados (systemctl stop al
# inicio del install), así que el restart no interrumpe captura. Solo upgrades de
# MISMA versión mayor de PostgreSQL; saltos de mayor (17→18) quedan manuales.
INSTALLED_TS=$(${PSQL_SU} -tAc "SELECT extversion FROM pg_extension WHERE extname='timescaledb'" -d "${DB_NAME}" 2>/dev/null)
AVAILABLE_TS=$(${PSQL_SU} -tAc "SELECT default_version FROM pg_available_extensions WHERE name='timescaledb'" -d "${DB_NAME}" 2>/dev/null)
if [ -n "$INSTALLED_TS" ] && [ -n "$AVAILABLE_TS" ] && [ "$INSTALLED_TS" != "$AVAILABLE_TS" ]; then
  info "Actualizando extensión TimescaleDB ${INSTALLED_TS} → ${AVAILABLE_TS}..."
  systemctl restart "postgresql@${PG_VER}-${PG_CLUSTER}" 2>/dev/null \
    || pg_ctlcluster "${PG_VER}" "${PG_CLUSTER}" restart 2>/dev/null || true
  for i in $(seq 1 30); do pg_isready -h "${PG_SOCKET_DIR}" -p "${PG_PORT}" >/dev/null 2>&1 && break; sleep 1; done
  ${PSQL_SU} -d "${DB_NAME}" -c "ALTER EXTENSION timescaledb UPDATE;" >/dev/null 2>&1 \
    && ok "TimescaleDB actualizado a ${AVAILABLE_TS}" \
    || warn "ALTER EXTENSION timescaledb UPDATE falló — revisar a mano"
fi
# El SQL se pasa por STDIN (lo lee el shell de root); así voxywatch NO necesita
# permiso de lectura sobre el archivo en el TMPDIR de root (mktemp es 700).
sudo -u "${SERVICE_USER}" psql -h "${PG_SOCKET_DIR}" -p "${PG_PORT}" -d "${DB_NAME}" \
     -v ON_ERROR_STOP=1 -f - < "${EXTRACTED}/schema.sql" >/dev/null \
  || err "No se pudo aplicar el esquema (schema.sql)"
ok "PostgreSQL + TimescaleDB listo (cluster ${PG_VER}/${PG_CLUSTER}, :${PG_PORT}, socket peer)"

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
  && ok "Kernel buffers aplicados (rmem_max=32M)" \
  || warn "No se pudieron aplicar los sysctl ahora (se aplicarán al reiniciar)"

# ── Install systemd unit files ────────────────────────────────────────────────
info "Installing systemd units..."

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
ProtectSystem=strict
ReadWritePaths=${DATA_DIR} ${CONF_DIR} /tmp ${PG_SOCKET_DIR}
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

# ── Service-control scripts (opt-in privilege grant) ──────────────────────────
# Generated ALWAYS so the admin can enable/disable later without reinstalling.
# Executed now only if the admin opted in above. The grant is scoped via a polkit
# rule (works with NoNewPrivileges=true — busctl/systemctl only send a D-Bus
# message; systemd performs the action after polkit authorizes it) plus a tiny
# drop-in that allows writing ONLY the two OS files NTP/DNS need.
cat > "${INSTALL_DIR}/enable-service-control.sh" << 'ENABLE_EOF'
#!/bin/bash
# VoxyWatch — grant the portal permission to manage ONLY its own services.
# Usage (as root):  sudo /opt/voxywatch/enable-service-control.sh
set -euo pipefail
[ "$EUID" -ne 0 ] && { echo "Must run as root:  sudo $0"; exit 1; }
SERVICE_USER="voxywatch"
CONF_FILE="/etc/voxywatch/voxywatch.conf"

# 1) polkit rule — scoped to VoxyWatch's own units + time settings only
mkdir -p /etc/polkit-1/rules.d
cat > /etc/polkit-1/rules.d/49-voxywatch.rules << RULE
// VoxyWatch: allow ${SERVICE_USER} to manage ONLY its own services / time settings.
polkit.addRule(function(action, subject) {
    if (subject.user != "${SERVICE_USER}") return;
    if (action.id == "org.freedesktop.systemd1.manage-units") {
        var u = action.lookup("unit");
        if (u == "voxywatch-sniffer.service" || u == "systemd-timesyncd.service")
            return polkit.Result.YES;
    }
    if (action.id == "org.freedesktop.timedate1.set-timezone" ||
        action.id == "org.freedesktop.timedate1.set-ntp")
        return polkit.Result.YES;
});
RULE
chmod 644 /etc/polkit-1/rules.d/49-voxywatch.rules

# 2) systemd drop-in — allow writing ONLY the OS files NTP/DNS need
mkdir -p /etc/systemd/system/voxywatch.service.d
cat > /etc/systemd/system/voxywatch.service.d/service-control.conf << DROPIN
[Service]
ReadWritePaths=/etc/resolv.conf /etc/systemd /etc/systemd/timesyncd.conf
DROPIN

# 3) persist state + reload
if grep -q '^SERVICE_CONTROL=' "$CONF_FILE" 2>/dev/null; then
    grep -v '^SERVICE_CONTROL=' "$CONF_FILE" > "${CONF_FILE}.tmp" && mv "${CONF_FILE}.tmp" "$CONF_FILE"
fi
echo "SERVICE_CONTROL=enabled" >> "$CONF_FILE"
systemctl reload polkit 2>/dev/null || systemctl restart polkit 2>/dev/null || true
systemctl daemon-reload
systemctl restart voxywatch 2>/dev/null || true
echo "✓ Service control ENABLED — the portal can now restart its services and apply timezone/NTP/DNS."
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
ok "Service-control scripts installed"

# Clean up any legacy unconditional rule from earlier installs
rm -f /etc/polkit-1/rules.d/49-voxywatch-sniffer.rules 2>/dev/null || true

if [ "$SERVICE_CONTROL" = "yes" ]; then
  info "Enabling service control (opted in)..."
  bash "${INSTALL_DIR}/enable-service-control.sh" || warn "Could not enable service control automatically"
else
  # Make sure no stale grant remains when the admin opted out
  rm -f /etc/polkit-1/rules.d/49-voxywatch.rules /etc/systemd/system/voxywatch.service.d/service-control.conf 2>/dev/null || true
  systemctl reload polkit 2>/dev/null || true
fi

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

MANIFEST_JSON=$(curl -fsSL --max-time 15 "$MANIFEST_URL" 2>/dev/null || echo "")
LATEST_VERSION=$(printf '%s' "$MANIFEST_JSON" \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['version'])" 2>/dev/null || echo "")
# min_upgrade_from: versión mínima desde la que se permite auto-actualizar. Para
# releases con cambios de infra (p.ej. 2.0.0 instala un servidor de BD) se fija a
# la propia versión para CORTAR el auto-update silencioso desde 1.x — esos saltos
# requieren instalación supervisada/asistida.
MIN_UPGRADE_FROM=$(printf '%s' "$MANIFEST_JSON" \
  | python3 -c "import json,sys; print(json.load(sys.stdin).get('min_upgrade_from','0.0.0'))" 2>/dev/null || echo "0.0.0")

if [ -z "$LATEST_VERSION" ]; then
  warn "Could not fetch version manifest. Skipping update check."
  exit 0
fi

log "Installed: v${CURRENT_VERSION} | Latest: v${LATEST_VERSION} | min_upgrade_from: v${MIN_UPGRADE_FROM}"

if [ "$(printf '%s\n%s' "$CURRENT_VERSION" "$LATEST_VERSION" | sort -V | tail -1)" = "$CURRENT_VERSION" ]; then
  log "Already up to date (v${CURRENT_VERSION})."
  exit 0
fi

# Cortar el auto-update si la versión instalada es anterior a min_upgrade_from:
# requiere actualización MANUAL/supervisada (cambio de infraestructura).
if [ "$(printf '%s\n%s' "$CURRENT_VERSION" "$MIN_UPGRADE_FROM" | sort -V | head -1)" = "$CURRENT_VERSION" ] \
   && [ "$CURRENT_VERSION" != "$MIN_UPGRADE_FROM" ]; then
  warn "v${LATEST_VERSION} requiere actualización MANUAL desde v${CURRENT_VERSION} (min_upgrade_from=v${MIN_UPGRADE_FROM}). Omitiendo auto-update."
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

# v2.0.4: verificar que ambos quedaron activos (un update no debe dejar el sistema
# abajo). Si alguno no levantó, reintentar una vez y avisar dónde mirar.
sleep 1
for _svc in voxywatch-sniffer voxywatch; do
  if systemctl is-active --quiet "$_svc"; then
    ok "${_svc} activo"
  else
    warn "${_svc} no quedó activo — reintentando..."
    systemctl restart "$_svc" 2>/dev/null || true
    sleep 1
    if systemctl is-active --quiet "$_svc"; then
      ok "${_svc} activo (tras reintento)"
    else
      warn "${_svc} NO está activo — revisa: journalctl -u ${_svc} -n 50 --no-pager"
    fi
  fi
done

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
