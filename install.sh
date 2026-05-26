#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# VoxyWatch — Instalador
# Servido desde: https://voxywatch.com/install.sh
#
# Uso:
#   curl -fsSL https://voxywatch.com/install.sh | sudo bash
#   — ó —
#   sudo bash install.sh [--version 1.2.0]
#
# Soporta: Debian 11+, Ubuntu 20.04+, RHEL/CentOS/Rocky/Alma 8+
# ─────────────────────────────────────────────────────────────────────────────

# Toda la lógica dentro de main(). Una descarga parcial no ejecuta nada.
main() {
set -euo pipefail

# ── Configuración ─────────────────────────────────────────────────────────────
GITHUB_ORG="VoxyWatch"
GITHUB_REPO="publish"
VERSION_MANIFEST="https://raw.githubusercontent.com/${GITHUB_ORG}/${GITHUB_REPO}/main/latest.json"
GPG_KEY_URL="https://raw.githubusercontent.com/${GITHUB_ORG}/${GITHUB_REPO}/main/voxywatch-release.gpg.pub"
RELEASES_BASE="https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/releases/download"

# ── Colores ───────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; CYAN=''; NC=''
fi
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $1"; }
err()  { echo -e "${RED}  ✗${NC} $1"; exit 1; }
info() { echo -e "${CYAN}  →${NC} $1"; }

echo ""
echo "══════════════════════════════════════════════"
echo "   VoxyWatch — Instalador"
echo "══════════════════════════════════════════════"
echo ""

# ── Verificaciones previas ────────────────────────────────────────────────────
[ "$EUID" -ne 0 ] && err "Ejecutar como root: curl -fsSL https://voxywatch.com/install.sh | sudo bash"

command -v curl   &>/dev/null || err "curl es requerido: apt install curl  ó  yum install curl"
command -v gpg    &>/dev/null || { warn "gpg no disponible — se omitirá verificación de firma"; GPG_AVAILABLE=false; }
GPG_AVAILABLE="${GPG_AVAILABLE:-true}"

# ── Detectar distribución ─────────────────────────────────────────────────────
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_ID_LIKE="${ID_LIKE:-}"
  else
    DISTRO_ID="unknown"
    DISTRO_ID_LIKE=""
  fi

  case "$DISTRO_ID" in
    debian|ubuntu|linuxmint|pop|kali|raspbian)
      PKG_TYPE="deb"
      PKG_MGR="dpkg"
      ;;
    rhel|centos|fedora|rocky|almalinux|ol|amzn)
      PKG_TYPE="rpm"
      PKG_MGR="rpm"
      ;;
    *)
      # Intentar por ID_LIKE
      if echo "$DISTRO_ID_LIKE" | grep -qE "debian|ubuntu"; then
        PKG_TYPE="deb"; PKG_MGR="dpkg"
      elif echo "$DISTRO_ID_LIKE" | grep -qE "rhel|fedora|centos"; then
        PKG_TYPE="rpm"; PKG_MGR="rpm"
      else
        err "Distribución no soportada: ${DISTRO_ID}. Soportadas: Debian/Ubuntu y RHEL/CentOS/Rocky/Alma."
      fi
      ;;
  esac
  ok "Distribución detectada: ${DISTRO_ID} → paquete .${PKG_TYPE}"
}

detect_distro

# ── Obtener versión a instalar ────────────────────────────────────────────────
# --version X.Y.Z en argv sobreescribe la versión del manifest
VERSION=""
while [ $# -gt 0 ]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -z "$VERSION" ]; then
  info "Obteniendo versión más reciente..."
  VERSION=$(curl -fsSL "$VERSION_MANIFEST" \
    | python3 -c "import json,sys; print(json.load(sys.stdin)['version'])" 2>/dev/null \
    || err "No se pudo obtener el manifest de versiones desde ${VERSION_MANIFEST}")
fi
ok "Versión a instalar: v${VERSION}"

# ── Nombres de archivo por tipo de paquete ────────────────────────────────────
if [ "$PKG_TYPE" = "deb" ]; then
  PKG_FILE="voxywatch_${VERSION}_amd64.deb"
  INSTALL_CMD_PREFIX="dpkg -i"
  POST_INSTALL_CMD="apt-get install -f -y"  # resolver dependencias si las hay
else
  PKG_FILE="voxywatch-${VERSION}-1.x86_64.rpm"
  INSTALL_CMD_PREFIX="rpm -Uvh"
  POST_INSTALL_CMD=""
fi

DOWNLOAD_URL="${RELEASES_BASE}/v${VERSION}/${PKG_FILE}"
SIG_URL="${DOWNLOAD_URL}.asc"

# ── Descargar paquete y firma ─────────────────────────────────────────────────
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

info "Descargando ${PKG_FILE}..."
curl -fsSL --progress-bar "$DOWNLOAD_URL" -o "${TMPDIR}/${PKG_FILE}" \
  || err "Fallo al descargar ${DOWNLOAD_URL}"
ok "Descarga completa: $(du -sh "${TMPDIR}/${PKG_FILE}" | cut -f1)"

# ── Verificar checksum contra SHA256SUMS ─────────────────────────────────────
info "Verificando checksum SHA-256..."
curl -fsSL "${RELEASES_BASE}/v${VERSION}/SHA256SUMS" -o "${TMPDIR}/SHA256SUMS" 2>/dev/null || {
  warn "SHA256SUMS no disponible — omitiendo verificación de checksum"
}

if [ -f "${TMPDIR}/SHA256SUMS" ]; then
  cd "$TMPDIR"
  if grep "$PKG_FILE" SHA256SUMS | sha256sum --check --status; then
    ok "Checksum SHA-256 verificado"
  else
    err "Checksum SHA-256 FALLÓ — el paquete puede estar corrupto o modificado"
  fi
  cd - > /dev/null
fi

# ── Verificar firma GPG ───────────────────────────────────────────────────────
if [ "$GPG_AVAILABLE" = "true" ]; then
  info "Verificando firma GPG..."
  curl -fsSL "$GPG_KEY_URL" -o "${TMPDIR}/voxywatch.gpg.pub" 2>/dev/null && \
  curl -fsSL "$SIG_URL"     -o "${TMPDIR}/${PKG_FILE}.asc"   2>/dev/null || {
    warn "No se pudo descargar la firma GPG — omitiendo verificación"
    GPG_AVAILABLE=false
  }
fi

if [ "$GPG_AVAILABLE" = "true" ]; then
  GPG_KEYRING="${TMPDIR}/voxywatch-keyring.gpg"
  gpg --no-default-keyring --keyring "$GPG_KEYRING" \
      --import "${TMPDIR}/voxywatch.gpg.pub" &>/dev/null
  if gpg --no-default-keyring --keyring "$GPG_KEYRING" \
         --verify "${TMPDIR}/${PKG_FILE}.asc" "${TMPDIR}/${PKG_FILE}" &>/dev/null; then
    ok "Firma GPG verificada"
  else
    err "Firma GPG INVÁLIDA — abortando instalación. Descarga comprometida."
  fi
fi

# ── Instalar paquete ──────────────────────────────────────────────────────────
info "Instalando voxywatch v${VERSION}..."
$INSTALL_CMD_PREFIX "${TMPDIR}/${PKG_FILE}"
[ -n "$POST_INSTALL_CMD" ] && $POST_INSTALL_CMD || true
ok "Paquete instalado"

# ── Obtener IP del servidor ───────────────────────────────────────────────────
SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "TU-IP")

# ── HWID ─────────────────────────────────────────────────────────────────────
HWID=""
if command -v node &>/dev/null && [ -f /opt/voxywatch/get-hwid.js ]; then
  HWID=$(node /opt/voxywatch/get-hwid.js 2>/dev/null | grep -oP '[0-9a-f]{32}' | head -1 || true)
fi

# ── Resumen final ─────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════"
echo -e "  ${GREEN}✓ VoxyWatch v${VERSION} instalado${NC}"
echo "══════════════════════════════════════════════"
echo ""
echo "  Portal web:"
echo -e "  ${CYAN}http://${SERVER_IP}:3080${NC}"
echo ""
echo "  Credenciales por defecto:"
echo "    Usuario:    admin"
echo "    Contraseña: (sin contraseña — auth desactivada por defecto)"
echo "    Activa auth en: Settings → Seguridad → Autenticación del portal"
echo ""
if [ -n "$HWID" ]; then
  echo "  Hardware ID (para activar licencia):"
  echo -e "  ${CYAN}${HWID}${NC}"
  echo ""
fi
echo "  Instala la licencia (opcional — el free tier funciona sin ella):"
echo -e "  ${CYAN}cp tu_licencia.key /etc/voxywatch/license.key${NC}"
echo -e "  ${CYAN}chown root:voxywatch /etc/voxywatch/license.key && chmod 640 /etc/voxywatch/license.key${NC}"
echo ""
echo "  Logs:"
echo -e "  ${CYAN}journalctl -fu voxywatch${NC}"
echo -e "  ${CYAN}journalctl -fu voxywatch-sniffer${NC}"
echo ""

} # fin de main()

main "$@"
