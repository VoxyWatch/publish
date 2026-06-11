# Changelog

All notable changes to VoxyWatch are documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [2.56.0] — 2026-06-11

### Added — Forecast de capacidad + digest (NOC Agéntico F4, `docs/DESIGN_NOC_AGENTICO.md` §6)
- **Retención real de audio medida y expuesta**: `computeAudioRetention()` (edad del segmento más viejo + ritmo GB/h) en `/api/v1/health` (campo `audio`) y en el digest. Si cae bajo `digest.capacity_min_audio_h` (default 0 = solo informativo) se abre un **incidente `capacity`** (warn) 1×/día, con recovery automático.
- **Digest diario/semanal** (determinístico, bilingüe): incidentes del período, salud de troncales, volumen vs período anterior, retención de audio y disco. Envío programado por **Telegram y/o webhook** (`digest.enabled`, `hour`, `period`) y **on-demand**: `GET /api/reports/digest?period=day|week&lang=es|en`.
- Settings `digest{}` persistibles vía POST /api/settings. OFF por defecto.

## [2.55.0] — 2026-06-11

### Added — Telegram accionable + acciones aprobadas (NOC Agéntico F3, `docs/DESIGN_NOC_AGENTICO.md` §5)
- **Canal Telegram nativo opcional** (además del webhook): al abrir/escalar un incidente ≥ `alerts.notify_min_severity` se envía mensaje con KPIs y el 🤖 diagnóstico del investigador (la notificación espera 45 s para incluirlo), con **botones inline**: `✅ Ack` · `✔ Resolver` · `🔍 Investigar` · y la **acción propuesta aplicable**. Resolución automática también notifica.
- **Catálogo de acciones CERRADO EN CÓDIGO** (allowlist; el SBC no existe aquí): `restart_sniffer` (solo incidentes de captura; reusa el mecanismo D-Bus/polkit existente) y `refresh_baselines`. **Toda aprobación y resultado queda en el timeline** del incidente (eventos `action: approved → done|failed`).
- **Solo obedece al chat configurado** (`alerts.telegram_chat_id`); long-poll `getUpdates` con offset persistido (no re-procesa tras reinicios); token enmascarado en GET /api/settings.
- `settings.alerts` ahora **se persiste vía POST /api/settings** (webhook + telegram; antes solo editable a mano).
- OFF por defecto (`alerts.telegram_enabled=false`). Fix de robustez: el parser del diagnóstico LLM extrae el primer JSON balanceado (fences/texto alrededor ya no lo rompen).
- Pendiente F3.1: UI de Settings para configurar el canal (hoy vía API/JSON) y acciones snooze/purge.

## [2.54.0] — 2026-06-11

### Added — Investigador automático de incidentes (NOC Agéntico F2, `docs/DESIGN_NOC_AGENTICO.md` §4)
- **Al abrir/escalar un incidente, el sistema investiga solo**: `collectIncidentEvidence` junta evidencia **determinística** (sin LLM) del working-set y los rollups — llamadas de muestra afectadas, códigos SIP dominantes, rutas IP de los fallos, ¿otras troncales degradadas a la vez? (local vs carrier), última hora vs norma — y la guarda en el incidente (evento `evidence`).
- **Diagnóstico LLM opcional**: un agente investigador (3 tools nuevas: `get_incident`, `get_error_breakdown`, `compare_baseline` + las 5 del copiloto) produce un JSON estructurado `{root_cause_hypothesis, confidence, scope: carrier|cliente|local|capacidad, recommended_action, evidence_cited}` que se guarda en el incidente y se muestra en el modal (🤖 Diagnóstico IA). **Sin API key, el incidente vale igual con la evidencia cruda.**
- **Presupuesto anti-costo**: máx `incidents.ai_max_per_hour` (default 12) investigaciones/h + cache 5 min por fingerprint. Re-investigación manual: `POST /api/incidents/:id/investigate`.
- El investigador **jamás propone tocar el SBC** (charter en el prompt y sin tool para ello).

## [2.53.0] — 2026-06-11

### Added — Motor de incidentes (NOC Agéntico F1, `docs/DESIGN_NOC_AGENTICO.md` §3)
- **Toda anomalía se convierte en un incidente persistente** con ciclo de vida (open → ack → resolved), deduplicado por *fingerprint* (máx. 1 sin resolver por objeto) y con **timeline auditable** (`incidents` + `incident_events`, schema v7; el portal también crea las tablas al boot — idempotente).
- **Detectores** (señales ya existentes, ahora con memoria): transiciones de salud de troncal (`runTrunkHealthAlerts` — registra warn/critical **aunque no haya webhook**), sniffer caído, 0 fuentes HEP, pérdida de captura sostenida (drops de kernel), cuello de sistema crítico sostenido (por recurso), y **caída de tráfico global** vs la norma histórica de la misma hora (14 días).
- **Anti-flapping de 2º nivel:** la recuperación NO resuelve — marca `recovered` y el incidente se auto-resuelve tras `auto_resolve_stable_min` (default 30) estable; una recaída lo reactiva (evento `relapsed`) y una severidad mayor lo escala (evento `escalated`).
- **API** `/api/incidents` (lista con filtros), `/summary`, `/:id` (detalle+timeline), `POST /:id/ack|resolve|comment` (roles viewer/operator).
- **UI**: pestaña principal **Incidentes** (chips de resumen, filtros, tabla, modal de detalle con timeline y acciones) + **badge en el nav** + aviso en la campana. Bilingüe ES/EN (`title_key`+params — el server no fija idioma).
- El **webhook de alarmas gana `incident_id`** (retro-compatible: el payload existente no cambia).
- Settings `incidents{enabled,auto_resolve_stable_min,retention_days,volume_global_drop_pct}` — **default ON** (solo registra; notificar llega en F3). Retención de resueltos: 90 días.
- Pruebas: `test/incidents.test.js` (13 casos del ciclo de vida contra BD real).

## [2.52.0] — 2026-06-11

### Security — `style-src` sin `unsafe-inline` (#031)
- Se elimina `'unsafe-inline'` de la directiva **`style-src`** del CSP principal (antes solo `script-src` lo había logrado). El portal endurece así su política contra inyección de estilos.
- **~510 atributos `style=` inline → clases CSS** (transformación 1:1 con `!important` para preservar la especificidad del inline; **validado pixel-perfect** con Chrome headless: render idéntico salvo el reloj que avanza 1 s).
- Los **estilos con valores dinámicos** (anchos/colores calculados en runtime) se emiten como `data-vstyle="…"` (un `data-*` no lo bloquea el CSP) y un **MutationObserver** en `app.js` los aplica vía CSSOM (`el.style.cssText`, permitido por CSP) en cuanto el nodo entra al DOM — sin tocar la lógica de cada render.
- Los `<style>` inline de `index.html` y la página puente SSO reciben **nonce por respuesta** (vía header, no `<meta>`). `blocked.html` conserva su CSP propia con inline (página autónoma de error).
- Header final: `style-src 'self' 'nonce-…'`. Las asignaciones `element.style.x=` por JS (CSSOM) nunca estuvieron sujetas a `style-src`, así que no se tocaron.

## [2.51.0] — 2026-06-11

### Added — firma GPG de releases (#030)
- El tarball se firma con la clave del vendor (`releases@voxywatch.com`, `80EDE252…`) en `build.sh`/`sign-and-publish.sh` → `*.tar.gz.asc`; `latest.json` gana `linux_x64.signature`.
- `install.sh` verifica la firma con la **clave pública embebida** (ancla de confianza en el propio script), **además** del SHA-256. Retrocompatible y best-effort: sin firma o sin `gpg` → sigue con SHA; **solo una firma INVÁLIDA aborta**. Protege contra un canal/Releases comprometido (el SHA viene del mismo manifiesto; la firma requiere la clave privada OFFLINE).

### Added — Modo PCI F2: auto-pausa de grabación por DTMF (SIP INFO) + UI
- `_pciAutoTrigger` gana trigger por **DTMF vía SIP INFO** (`application/dtmf*`, RFC 2976): pausa la grabación mientras llegan dígitos (el cliente teclea su tarjeta) y **auto-reanuda** tras `dtmf_resume_sec` sin tonos. Settings `pci.dtmf_trigger` / `pci.dtmf_resume_sec`.
- POST `/api/settings` ahora **persiste el bloque `pci`** (merge con el actual → no pierde `sweep_interval_ms`; CSV→array).
- **UI** en Settings → Seguridad: habilitar PCI, conservar SIP/CDR, trigger por DTMF, ventana de seguridad, troncales/DIDs sensibles. Bilingüe (ES/EN), con clases CSS (sin `style` inline).
- `pci.enabled` sigue **OFF** por defecto. RFC 2833 (telephone-event en RTP) en modo `audio_storage='files'` queda como extensión (mismo bloqueador que el audio: RTP sin Call-ID en vivo).

## [2.50.0] — 2026-06-11

### Fixed — el audio se asocia a las trazas en modo `audio_storage='files'` (correlación por SDP)
- **Causa raíz:** con `audio_storage='files'` el RTP va a segmentos `.seg` en disco y **no entra al working-set en RAM** del portal. La correlación RTP↔llamada era *time-window-driven* sobre `_rtpStats` (RAM), que quedaba vacío → **toda llamada salía `ssrc_caller/callee='Unknown'`, `packets=0`, `has_audio=false`** aunque el audio existiera en disco (en C3ntro, 622 GB de `.seg` sin asociar a ninguna llamada).
- **Fix de fondo — correlación DETERMINISTA por el `c=/m=` del SDP (no heurística):**
  - **Sniffer (`hep_sniffer.py`):** el sidecar `.idx` pasa de "lista de SSRC" a **una línea por SSRC con `dst_ip dst_port first_ts last_ts count`** (el destino del flujo + su ventana temporal). El `.seg`/blob NO cambia (compat total con datos existentes). El SSRC sigue siendo el primer token → retrocompatible.
  - **Portal (`server.js` + nuevo `lib/segindex.js`):** deja de descartar `mediaPort` del SDP; guarda `media_ip:media_port` de cada lado (INVITE=caller, 200 OK=callee). Un índice de segmentos en RAM (cacheado por mtime, solo lee los `.idx` ligeros, nunca los GB de RTP) casa cada SSRC con su llamada por **dst_port == media_port** (y `dst_ip` si el SBC no lo reescribe) dentro de la ventana. Convención RFC 3264: el RTP que va al media del callee lo produce el caller (→ `ssrc_caller`) y viceversa. De ahí salen `ssrc_caller/callee`, `packets` y `has_audio` correctos.
  - Si el deployment envía RTCP, los SSRC correlacionados habilitan jitter/loss/MOS reales; sin RTCP **no se inventan** métricas (solo se afirma que el audio existe y de quién es).
  - `reconstruct_audio.py` ahora recibe los SSRC reales (en vez de `unknown`) → filtra exacto en vez de auto-descubrir.
- **Compat:** en modo `db` (default) el comportamiento es idéntico (la rama nueva está guardada por la presencia del índice de segmentos). Los `.idx` viejos de 1 columna y los `.seg` existentes se siguen leyendo.
- **Pruebas:** `test/segindex.test.js` (13 casos: convención caller/callee, fallback por puerto cuando el SBC reescribe la IP, ventana temporal, audio unidireccional, no doble-conteo, cache por mtime, poda por antigüedad).

## [2.49.4] — 2026-06-10

### Fixed
- **HWID estable** — `getHardwareId()` (y `tools/get-hwid.js`) ignoran las interfaces virtuales (Docker `br-*`/`veth`/VPN/contenedores) cuya MAC se regenera al reiniciar y cambiaba el HWID → invalidaba la licencia (`maquina_incorrecta`). Ahora el HWID se deriva solo de NICs físicas → estable entre reinicios.

## [2.49.3] — 2026-06-10

### Fixed (revalidación pentest v2.49.2 — tickets 026/028/029)
- **#028 — la UI ya no dispara endpoints protegidos antes de login** — el wrapper de `fetch` bloquea las llamadas `/api/*` protegidas cuando no hay sesión (devuelve 401 sintético local), dejando pasar solo las públicas (`auth`, `version`, `license/status`, `openapi`, `server-alerts`). Se acaba la ráfaga de 401 pre-login.
- **#026 — Disconnect Causes de raíz** — los **3xx (302 Moved Temporarily)** ahora son `redirected` con su razón SIP (no "Sin respuesta"); y un `no-answer` con `disposition_label` específico ya no se entierra bajo el genérico. Afecta el dato, no solo el dashboard.
- **#029 — aviso SNMP inseguro** — si v2c escucha fuera de loopback sin allowlist, se loguea un warning accionable al arrancar (no se cambia la config para no romper un NMS existente).

## [2.49.2] — 2026-06-10

### Fixed
- **#2 (BLOCKER) — login no aparecía en navegador limpio** — `/api/auth/me` sin sesión responde `200 {ok:false, authenticated:false}`, pero `checkAuth` solo contemplaba `200+ok` y `401`; el caso `200+authenticated:false` caía al retry y el overlay de login nunca se mostraba (se veía el dashboard vacío sin sesión). Ahora ese caso muestra el login. El overlay (position:fixed, z-index máximo) tapa el shell.

## [2.49.1] — 2026-06-10

### Fixed (hallazgos del debug avanzado de preventa)
- **#5 — `/api/calls?status=` valida el enum** — un valor inválido (p.ej. `bogus`) ahora responde **400** con la lista válida (`all`/`completas`/`rejected`) en vez de 200 sin filtrar; se normalizan alias comunes (`completed`→`completas`, `failed`→`rejected`).
- **#6 — Disconnect Causes no entierra causas específicas** — cuando el motivo es genérico ("Sin respuesta"/"Sin código") pero hay `disposition_label` o código SIP, el histograma agrupa por el específico (302, Ignored…) en vez del genérico.
- **#7 — SNMP seguro por defecto** — `snmp_bind_address` ahora es `127.0.0.1` (antes `0.0.0.0`); exponer a la red requiere cambiarlo explícitamente + allowlist.
- **#4 — `getDbState` (MIN/MAX(id) sobre `packets`)** — single-flight + cache de 1 s: coalesce las llamadas concurrentes que competían con la ingesta (observado en el reporte), sin cambiar la query ni la semántica.

## [2.49.0] — 2026-06-10

### Modo PCI — F1b (sniffer), F1c (probe) y F2 (auto-trigger). Sigue OFF por defecto
- **3 capas de supresión (defense-in-depth), match por SSRC (preciso):**
  - **F1c — probe (origen)** ⭐: el agente Go (`voxywatch-probe`) **no envía** el RTP del SSRC en ventana de pago → el dato nunca sale del entorno seguro (óptimo PCI). Lee `pci_suppress.json` (path `VW_PROBE_PCI_FILE`, default `/etc/voxywatch-probe/pci_suppress.json`).
  - **F1b — sniffer (universal)**: `hep_sniffer.py` no persiste el RTP de SSRC suprimidos (lee `pci_suppress.json` de DATA_DIR en caliente). Cubre cualquier fuente HEP, no solo el probe.
  - **F1 — portal**: borra el RTP que se cuele (ya en v2.48.0).
- **F2 — auto-trigger:** `pci.sensitive_trunks` / `pci.sensitive_dids` → las llamadas activas en esas troncales/DIDs se auto-pausan (toda la llamada). Triple guard (enabled + lista no vacía + match).
- Con `pci.enabled=false` (default) y sin `pci_suppress.json`, **todo el comportamiento es idéntico al actual** (set de SSRC vacío → sin efecto). Diseño en `docs/DESIGN_PCI_PAUSE_RESUME.md`.

---

## [2.48.0] — 2026-06-10

### Modo PCI / pause-resume de grabación — F1 (lado portal), OFF por defecto
- Cumplimiento **PCI-DSS**: permite suprimir el audio/RTP durante ventanas de pago (CVV) para que no se almacene. **Programable on/off** vía `settings.pci.enabled` (master switch, **OFF por defecto** → no afecta a nadie) y por **API** (el IVR/CRM lo controla por llamada).
- Nuevos endpoints (`scope recording:control`): `POST /api/v1/recording/suppress {call_id, action:pause|resume}` y `GET /api/v1/recording/suppress/status`.
- F1 (lado portal): al pausar, el RTP de la llamada se **borra de `rtp_packets`** de inmediato y en barridos cada `sweep_interval_ms`; al reanudar, barrido final de la ventana. **Auto-resume** de seguridad (`max_window_min`) si nadie llama a resume. SIP/CDR se conserva (no contiene datos de tarjeta). Auditoría en memoria + `pci_suppress.json` (que el sniffer leerá en F1b).
- **F1b (siguiente):** supresión en el **sniffer** (no-persistencia, PCI estricto — el RTP no toca disco). Diseño en `docs/DESIGN_PCI_PAUSE_RESUME.md`.

---

## [2.47.0] — 2026-06-10

### Purga incremental (VOXY-7) — detrás de flag, OFF por defecto
- **Problema:** cada purga de retención (TimescaleDB dropea el chunk más viejo → `MIN(id)` sube) disparaba un `parseCapture` **full O(N)** (~23 s a alto volumen: re-lee y re-correlaciona TODO el working-set), aunque la purga solo eliminó lo más viejo.
- **Fix:** nueva `_evictPurgedAndRebuild(newMinId)` — descarta de RAM lo purgado (`packet_num < newMinId`) y re-correlaciona desde lo que queda (`rebuildCallMetadata`), sin re-leer la BD. Convierte el O(N) de 23 s en O(purgados). Limpia el estado acumulado huérfano (`_callEvents`/`_rtpStats`/`_rtcpStats`).
- **Seguridad:** gobernado por `VW_INCR_PURGE` (**OFF por defecto** → comportamiento idéntico al actual). ⚠ Antes de activar en producción hay que **validar paridad** con datos reales (riesgo conocido: un SSRC cuyo stream RTP cruza el borde de la purga conserva `_rtpStats` con paquetes ya purgados → leve divergencia de jitter/MOS). Mecanismo de QA: comparar dumps `_maybeDumpCalls` de `purge` vs `full`.

---

## [2.46.0] — 2026-06-09

### Fix: timeout al cargar el ladder SIP on-demand (VOXY-K)
- **Síntoma:** `[flow] ladder on-demand: canceling statement due to statement timeout` al abrir el flujo/traza de algunas llamadas en capturas grandes.
- **Causa:** la query a `packets` (hypertable TimescaleDB, **chunks de 1 h**) filtraba solo por `call_id` **sin acotar `ts`** → sin exclusión de chunks, abría toda la hypertable y excedía el `statement_timeout`.
- **Fix:** se obtiene el rango temporal de la llamada (`start_ts`/`last_ts` de `calls`, indexada por `call_id`) y se acota la consulta con `ts BETWEEN start-5min AND last+1h` → TimescaleDB excluye chunks y solo lee un puñado. Fallback al rango de los mensajes en RAM si la llamada aún no está en `calls`. Aplicado en **`_loadFlowMessages`** (UI `/flow` + análisis RFC) y en **`GET /api/v1/calls/{id}/trace`** (API pública).
- *Primer bug resuelto end-to-end por el flujo Sentry-autopilot → aprobación → fix.*

---

## [2.45.0] — 2026-06-09

### Identidad de la instalación en telemetría (mapeo de cliente para soporte)
- Cada evento de telemetría que llega al Sentry del fabricante queda **mapeado a su instalación**: se adjuntan los tags `hwid`, `customer`, `tier` y `license_valid`, y se fija el *user* de Sentry (`id = HWID`, `username = cliente · hwid`).
- El **HWID es el ancla universal**: existe siempre, con o sin licencia. Con licencia válida el `customer` es el nombre del cliente y el `tier` su plan (`production`/`telco`); sin licencia es `free` (no encontrada) o `invalida`. Así **ningún error queda anónimo** y un ticket de soporte se localiza al instante por HWID o por nombre.
- La identidad se fija al arrancar y se **refresca en cada re-chequeo de licencia** (cada 6 h) por si cambia el estado. **No se envían** IP, hostname ni contenido de llamadas (sigue depurado por el scrubber). Solo telemetría; afecta al panel del fabricante, no al portal del cliente.

---

## [2.44.0] — 2026-06-09

### Selección dinámica de modelos de IA
- El campo de modelo del chat (Settings → AI Chat) deja de ser **texto libre**: ahora se elige del **catálogo real del proveedor**. Botón **"Cargar modelos"** → desplegable poblado en vivo.
- Nuevo `POST /api/ai/models`: consulta el endpoint de listado del proveedor seleccionado — OpenAI `/v1/models`, Anthropic `/v1/models`, Google `/v1beta/models` (filtrado a los que soportan `generateContent`), OpenRouter `/api/v1/models` — con la key configurada. **Server-side**: la key nunca sale al navegador. Filtra a modelos de chat y cachea ~5 min.
- **Fallback robusto:** si el listado falla (key inválida, sin salida a internet on-prem), se conserva el input de texto manual. Así no hay que hardcodear ni perseguir el modelo más nuevo — aparece solo.

---

## [2.43.0] — 2026-06-09

### Avisos unificados en la campana
- Todos los avisos que antes aparecían como **barras sueltas** ahora se consolidan en el **centro de notificaciones (la campana del header)**: cuello/CPU (`bottleneck`), capacidad de tier (`capacity`) y uso del plan gratuito (`freetier`). El sniffer ya estaba ahí.
- El aviso de CPU conserva la **severidad contextual** de v2.42.0: `info` (azul) en catch-up transitorio, `warn`/`crit` si es saturación real con pérdida.
- Las notificaciones llevan acción donde aplica (ej. *Activar licencia*, *Ver planes*). El **overlay de bloqueo** del plan gratuito se conserva (es un modal funcional, no un banner). Solo UI.

---

## [2.42.0] — 2026-06-09

### Leyenda de CPU contextual — no confundir catch-up con falta de recursos
- El aviso preventivo de CPU al límite ahora **distingue** dos situaciones para no inducir a sobre-aprovisionar hardware:
  - **Transitorio (catch-up tras arranque/actualización, sin pérdida):** banner informativo (azul) — *"El portal está procesando datos tras el arranque/actualización; el uso de CPU se normalizará al liberarse los procesos. No es necesario agregar recursos todavía."*
  - **Sostenido / con pérdida real:** el aviso de siempre (ámbar/rojo) — *"Agrega cores…"*.
- Detección en `_sampleBottleneck` vía `_cpuLoadIsWarmup()` (proceso recién arrancado, backfill del working-set en curso, o rollup/parse de fondo activo). El detector expone `transient` en `/api/bottleneck` y `/api/health.capture`; el banner del portal lo traduce (ES/EN).
- Solo UI/observabilidad; la captura no se ve afectada.

---

## [2.41.0] — 2026-06-09

### Menos CPU — guard de concurrencia del rollup del dashboard
- El rollup `call_stats_hourly` se refresca cada 2 min, pero a alto volumen (millones de filas en `calls`) cada agregado tardaba **más** que el intervalo → sin guard se **apilaban** varias ejecuciones concurrentes (se observaron 4 a la vez), saturando los cores con queries paralelas sobre toda la tabla.
- Ahora `refreshStatsRollup` tiene **guard de concurrencia** (`_statsRollupBusy`, igual que el rollup de troncales): una sola ejecución a la vez; si ya hay una en curso, el disparo se omite y el siguiente tick la recoge.
- La captura (sniffer) nunca se ve afectada.

---

## [2.40.1] — 2026-06-09

### Fix — chat de IA en modo claro
- El widget de chat flotante (ventana, input y burbujas de mensaje) usaba variables CSS **inexistentes** (`--bg-secondary`, `--bg-primary`, `--bg-tertiary`, `--border`) que caían siempre a su *fallback* oscuro → el chat se veía oscuro incluso con el **tema claro**. Ahora usa las variables reales del tema (`--bg-surface`, `--bg-surface-2`, `--border-default`, `--text-primary`), por lo que se adapta correctamente a claro/oscuro.
- Solo UI (`index.html`); sin cambios de backend.

---

## [2.40.0] — 2026-06-09

### Menos CPU del portal a alto volumen
- **Anti-deadlock en el upsert de CDRs:** el upsert incremental de `calls` ahora ordena las filas por `call_id` antes de escribir. Dos lotes que tocaban las mismas filas en orden distinto provocaban `[calls] upsert incr: deadlock detected` y reintentos que quemaban CPU; con un orden total estable, todas las transacciones bloquean en el mismo orden.
- **Throttle del full-parse por cap-RAM:** a alto volumen / durante un catch-up de backlog, el working-set excedía el límite de RAM y disparaba un *full-parse* (re-correlación completa) una y otra vez —se observaron dos en 5 s— manteniendo todos los cores al tope. Ahora hay un *cooldown* mínimo entre full-parses por cap-RAM (con hard-cap de seguridad para RAM): da respiro al CPU en lugar de re-correlacionar en bucle.
- La **captura (sniffer) nunca se ve afectada**; solo cambia el comportamiento del portal.

---

## [2.39.0] — 2026-06-09

### Alertas proactivas con IA + API de monitoreo
- **Alertas agénticas:** cuando una troncal entra en **alarma**, el copiloto NOC redacta un diagnóstico breve (causa más probable + acción recomendada) y lo adjunta al webhook como `ai_analysis`. Opcional vía `alerts.ai_summary`, best-effort (si no hay LLM configurado o falla, la alerta sale igual). Se apoya en el monitor proactivo existente (evaluación de salud de troncales cada 60 s, detección de anomalías por baseline, webhooks anti-spam por transición de estado).
- **API de Integración ampliada (monitoreo externo):** nuevo scope `metrics:read` y tres endpoints read-only para NOC/billing externos:
  - `GET /api/v1/health` — liveness + versión + estado de captura.
  - `GET /api/v1/stats` — KPIs globales (ASR/PDD/MOS, top clientes/países/troncales, causas).
  - `GET /api/v1/trunks/health` — salud por troncal/carrier (ASR/NER/ACD/MOS/pérdida/PDD/5xx + razones).
- Portal-only (capture-safe).

---

## [2.38.0] — 2026-06-09

### Arranque (warm-up) ultrarrápido en alto volumen
- La reconstrucción del working-set al arrancar ordenaba los paquetes por `id`, que **no** es la clave de partición de la hypertable. Sobre cientos de millones de filas comprimidas (TimescaleDB columnar) eso forzaba un **Sort de decenas de millones de filas** → arranques de varios minutos.
- Ahora ordena por la clave primaria `(ts, id)` → TimescaleDB usa exclusión de chunks (solo toca los recientes). Medido en un despliegue de **341 M filas**: primera carga útil **~512 s → ~17 s**. Arregla tanto el fast-boot como el backfill.
- La **captura nunca se ve afectada** (el sniffer corre independiente); solo el portal arranca mucho más rápido tras un reinicio/actualización.

---

## [2.37.0] — 2026-06-09

### Copiloto NOC agéntico (tool-calling / ReAct)
- El asistente de IA deja de responder sobre un **resumen estático** y pasa a **investigar en vivo**: usa *tool-calling* (bucle ReAct) para consultar datos reales bajo demanda y **encadenar herramientas** hasta llegar a un diagnóstico.
- **5 herramientas read-only:** panorama/KPIs (`get_overview`), salud de troncales (`get_trunk_health`), búsqueda de CDRs (`search_calls`), detalle de llamada (`get_call_detail`) y escalera SIP (`get_call_flow`).
- Multi-proveedor (OpenAI / Anthropic / Google / OpenRouter), con guardarraíles (solo lectura, tope de iteraciones). **100 % observación:** explica la causa probable y recomienda acciones para el NOC, nunca toca el SBC. Autotest en `GET /api/ai/agent-selftest`.
- Portal-only (capture-safe).

---

## [2.19.6] — 2026-06-04

### UI — re-fix tras revalidación del debugger (TICKET-008/009/010/011)
- **Pantalla stale post-login (008/009/011):** las vistas/header/widget se cargaban ANTES de tener token (fetches → 401 → en blanco) y el login no las re-hidrataba → quedaban stale hasta un refresh manual. Ahora, tras login exitoso, se **re-hidrata recargando con el token ya en localStorage** (el boot corre autenticado → header, vista activa, settings y widget IA correctos). Se preserva el flujo de force_change (sin recarga).
- **TICKET-010 alcance del KPI:** "Total calls" ahora muestra el **total histórico real** (de `/api/cdrs.total`, p.ej. 7.5M) en vez del tamaño del muestreo (~1,000 que contradecía a los millones de CDRs). Los KPIs de calidad (ASR/NER/ACD/MOS) siguen sobre la muestra reciente.
- Portal-only (capture-safe).

---

## [2.19.5] — 2026-06-04

### UI — fixes reales de la auditoría (TICKET-010 + 011); 007/008/009 fueron falsos positivos del harness
- **TICKET-010 (peak concurrent absurdo, 740k):** la concurrencia en `/api/dashboard/timeseries` sumaba los `starts` de la hora pero NO restaba sus `ended` → contaba ~una hora entera de inicios como activos. Ahora = **neto de llamadas abiertas al cierre de la hora** (cumStart−cumEnd, ambos inclusivos) → valor realista a alto volumen (starts≈ends/hora).
- **TICKET-011 (CSP bloqueaba Google Fonts):** se ELIMINA la dependencia de Google Fonts (CDN externo). On-premise/telco no debe depender de un CDN (offline, privacidad, CSP). `--font-sans`/`--font-mono` ya hacen fallback a system-ui/monospace. (NO se aflojó el CSP.)
- **007/008/009 NO eran bugs:** verificado con login real — todos los `/api/*` dan 200 con Bearer, Calls trae datos, el widget IA se revela al cargar settings. Los `401` eran del runner Playwright del audit que no propagó el JWT (el frontend ya inyecta `Authorization: Bearer` en `/api/*`).
- Portal-only (capture-safe).

---

## [2.19.4] — 2026-06-04

### Observabilidad VERIFICABLE sin auth (re-fix de TICKET-002/005/006 tras validación del debugger)
- El debugger rechazó 002/005/006 con razón: el diagnóstico estaba correcto pero **solo en `/api/bottleneck` (con auth) y en el log del portal al cambiar** → no verificable desde donde mira monitoreo/soporte.
- **`/api/health` (PÚBLICO) ahora expone `capture`:** recurso limitante, severidad, captura % global, **drops por capa (SIP/CDR vs RTP)**, **peor worker**, y **por puerto (=capa) con nº de workers y peor recv-Q**, + acción. No expone secretos/versión. Verificable con `curl http://127.0.0.1:3080/api/health`.
- **Re-log periódico:** el `[bottleneck]` se re-loguea cada 5 min mientras haya pérdida (antes solo al cambiar de recurso) → `journalctl -u voxywatch` siempre muestra el cuello actual + acción.
- Portal-only (capture-safe; no reinicia el sniffer).

---

## [2.19.3] — 2026-06-04

### Métricas honestas de captura (TICKET-002 + 005 + 006 del debugger)
- **TICKET-006:** el detector de cuello lee `/proc/net/udp[6]` por SOCKET (= por worker, SO_REUSEPORT) y por PUERTO (= capa): rx_queue + drops del kernel, con el PEOR worker. Un worker saturado se detecta aunque el promedio esté bien.
- **TICKET-002:** drops separados por CAPA (SIP/CDR vs RTP) en el warning y en `/api/bottleneck`. Se acabó el "capturando 100%" cuando hay drops: ahora dice `SIP/CDR OK/PÉRDIDA, RTP OK/PÉRDIDA [global N%]`. Pérdida real de RTP → severidad crítica.
- **TICKET-005:** el cuello nombra el recurso REAL. Clave: con 12/16 cores pegados el idle del sistema es ~25%, así que el viejo `idle<=5` nunca disparaba y caía en "ingest" genérico. Ahora *drops de socket + iowait bajo = workers saturados (CPU/hot-path)* → acción "sube vCPU o reduce costo por paquete; RSS/disco no son la causa". Se distingue recv (más workers) de net (RSS/IRQ).
- Portal-only (capture-safe; no reinicia el sniffer).

---

## [2.19.2] — 2026-06-04

### TICKET-001 — Sin hardcodes: working-set del sniffer derivado del hardware
- Nuevo `_compute_capacity()` (capacity planner) en `hep_sniffer.py`: los límites se DERIVAN de RAM, disco libre y `net.core.rmem_max`, no de constantes fijas.
  - `_DB_QUEUE_MAXSIZE`: ~3% de RAM / item (antes fijo 200k) → C3ntro ~471k; caja de 4 GB ~63k; cap 2M.
  - `_SPOOL_MAX_BYTES`: 10% del disco libre (antes fijo 2 GiB) → C3ntro ~69 GiB de buffer ante caída de BD; piso 1 GiB, techo 100 GiB.
  - `SO_RCVBUF`: pide hasta `net.core.rmem_max` (antes fijo 16 MB) → usa el máximo del SO; avisa si `rmem_max` es bajo.
  - Cap de workers: ya no se capa por debajo de los cores (escala con el host).
- **Expone los valores efectivos** en el log al arrancar (`[capacity] ...`) con el motivo. Un host mayor escala solo; uno chico baja solo. Sin números atados a un cliente.
- No se sube `rmem_max` en el instalador a propósito (host CPU-bound sin swap → un buffer mayor consumiría RAM sin arreglar drops que son por CPU). Sin cambios de captura.

---

## [2.19.1] — 2026-06-04

### Observabilidad del sniffer (TICKET-004 + TICKET-003 del debugger)
- **TICKET-004 (journald suprimía logs):** las stats del sniffer se imprimían cada N PAQUETES por worker (a ~150k pps = cientos de líneas/s/worker → journald suprimía decenas de miles). Ahora se gatean por TIEMPO: máx 1 línea cada 30 s por worker. Logs fiables bajo firehose.
- **TICKET-003 (spool=0KB mentía):** la métrica de spool solo sumaba los spools de la corrida actual. Ahora inventaría TODOS los `voxywatch_spool*` del DATA_DIR (activos + replay + huérfanos) y reporta `spool=NMB(Kf)` real. (Se reclamaron 98.5 GiB de spools huérfanos del 06-03 en el server.)
- Sin cambios de captura (solo logging/métrica). Cambia el sniffer → el update lo reinicia (breve hueco).

---

## [2.19.0] — 2026-06-04

### #7 — Almacén de RTP en ARCHIVOS append-only (audio_storage='files') + parse +46%
- **Sniffer:** nuevo modo `audio_storage='files'` — el RTP se escribe a segmentos append-only por hora/worker `audio/rtp-YYYYMMDDHH-wN-<epoch>.seg` (formato VWB1) en vez de `COPY` a Postgres → sin WAL/MVCC/índice por paquete. Default sigue `'db'` (sin cambio) hasta activarlo. fsync periódico, cierre en shutdown, fallback a spool.
- **Lector dual:** `reconstruct_audio.py`/`generate_pcap.py` leen RTP desde segmentos (glob por ventana del nombre + filtro SSRC) **y** desde `rtp_packets` (BD) → transición transparente. Retención `reliefPurgeOldestSegments` borra `.seg` viejos bajo presión de disco (umbral RTP).
- **parse_hepv3 +46%** (49deb6e, ya validado equivalente): structs precompilados + `unpack_from` → sube el techo de captura del sniffer. Se incluye (se elimina el revert del build).
- Validado: round-trip del formato, lector dual, **paridad e2e (audio desde archivo == desde BD)**. Setting `audio_storage` persistido en el portal.

---

## [2.18.3] — 2026-06-04

### Hardening — correcciones del code-review interno (v2.16.9→v2.18.2)
- **Ventana de audio/PCAP (regresión del fix anti-OOM):** llamadas sin `firstTs` daban ventana 0/0 → audio/PCAP **vacío**; llamadas activas (sin `lastTs`/BYE) daban ventana de ~7 s → PCAP **truncado**. Ahora `_callRtpWindow()` extiende `until` a *ahora* si la llamada está activa, y los scripts aplican la ventana solo si es válida (si no, filtran por SSRC + tope anti-OOM, sin ventana vacía).
- **`correlateIncremental` guard:** cuando el delta es enorme y cae a `rebuildCallMetadata`, ahora **también `upsertCalls`** (antes ese tick no persistía la tabla `calls`).
- **`correlateIncremental`** ahora invalida los MISMOS cachés que el path full (`_labelCache`/`_ipLabelsCache`, no solo dash/cdrs) y **poda `_ssrcToCid`** al borrar una llamada (sin entradas stale ni crecimiento no acotado).
- **Concurrencia del dashboard:** `ended` ahora cuenta por `COALESCE(last_ts, start_ts)` → las llamadas sin `last_ts` ya no inflan `Active Calls/Hour` monotónicamente. Auto-rebuild del rollup (`rollup_ver`→3).
- **Rollup:** el refresh periódico (120 s) espera a que el backfill cree la tabla (`_rollupReady`) → sin error de "relation does not exist" en arranque.
- Validado: paridad full≡incremental sigue exacta (3961≡3961). Sin cambios en el sniffer.

---

## [2.18.2] — 2026-06-04

### RAM — working-set derivado del hardware (sin hardcode, cualquier escala)
- **Medición previa (v2.18.1):** el portal usa ~734 MB RSS / 512 MB heap a working-set completo (250k filas, 88k SIP, 24k llamadas). El `raw` pesa solo 44 MB. El "3.7 GB" de notas viejas quedó obsoleto tras el parse incremental + #6.
- El tope del working-set se basaba en un cap obsoleto de 400 MB (era para la lectura JSONL de un solo string) → daba 250k filas FIJO en cualquier hardware. En cajas chicas (2-4 GB) eso podía saturar.
- Ahora **se deriva del hardware**: `parse_ram_pct%` de la RAM total / costo-por-fila medido (~3 KB), con techo proven-good de 250k (el historial vive en la BD; no hace falta más en RAM) y un piso para hardware muy chico. **Cero cambio en cajas grandes** (C3ntro sigue en 250k); **escala hacia abajo solo** en cajas chicas. Nivel telco, adaptable a cualquier despliegue.

---

## [2.18.1] — 2026-06-04

### Observabilidad — diagnóstico de RAM (sin cambios de comportamiento)
- Nuevo `GET /api/debug/memory` (operador): `process.memoryUsage()` + conteos por estructura (sipMessages, callMetadata, callEvents, sipByCallId, ssrc→cid, rtpStats…) + bytes de `raw` + ventana efectiva. Sin secretos.
- Log conciso `[mem]` por full-parse → leíble por `journalctl` (sin auth) para dimensionar optimizaciones de RAM con datos reales en cualquier hardware. Base para el rediseño de RAM del portal (sin adivinar).

---

## [2.18.0] — 2026-06-04

### Performance — Correlación INCREMENTAL (#6): O(llamadas tocadas) en vez de O(ventana)
- Antes, cada tick de 5 s re-correlacionaba la VENTANA COMPLETA (`rebuildCallMetadata`, hasta 250k mensajes) y re-upserteaba TODAS las llamadas (~20k) — el grueso del CPU constante del portal a alto volumen.
- Ahora `correlateIncremental` recalcula y persiste **solo los call-ids tocados por el delta** del tick, reusando `buildOneCall` (la MISMA fuente de verdad que el rebuild full → sin divergencia). Mantiene `sipByCallId` vivo, un mapa `ssrc→call_id` (para RTP/RTCP tardío), y asignación de referencia atómica por llamada (lecturas nunca ven estado a medias).
- **Guarda:** si el delta toca una fracción enorme de la ventana → cae al rebuild full. Fallback full ante purga o límite de RAM (sin cambios). Flag interno `VW_INCREMENTAL` (default ON).
- **Validado por test de PARIDAD** (`tools/parity_test.sh`) contra dataset real de C3ntro en staging: full-vs-incremental **byte-idéntico** (3961 ≡ 3961 llamadas). Deploy solo-portal (capture-safe). Sin cambios en el sniffer.

---

## [2.17.2] — 2026-06-04

### Fixed — OOM por reconstrucción de audio / PCAP (causa de 2 OOM-kills de ~20 GB)
- **`generate_pcap.py`** consultaba el RTP **sin ninguna ventana de tiempo** y hacía `fetchall()` sobre TODO `rtp_packets` (cientos de GB) → el cliente intentaba materializarlo en RAM y disparaba el OOM-killer. Ahora recibe la ventana de la llamada (argv 5/6 desde el portal) y filtra por la columna de partición `ts` (exclusión de chunks).
- **`reconstruct_audio.py`** hacía `fetchall()` sobre toda la ventana (y en auto-descubrimiento de SSRC guardaba todos los streams) → mismo riesgo.
- **Ambos** ahora usan **cursor del lado servidor** (named, `itersize=50k`) que streamea en lotes en vez de materializar todo el resultado en el cliente, + un **tope duro de 4M paquetes** en RAM (≈1.4 GB worst-case; aborta con aviso si se excede). `to_regclass` decide rtp_packets sin try/except sobre el cursor.
- **`server.js`**: pasa la ventana de tiempo también a PCAP; ambos spawns con `timeout: 240s` y `maxBuffer: 16 MB`.
- Resultado: la reconstrucción/PCAP de cualquier llamada queda acotada en RAM independientemente del tamaño de la captura. G.711/G.722/G.729/etc. sin regresión.

---

## [2.17.1] — 2026-06-03

### Fixed — Rollup del dashboard: excluir scanners (consistencia con las gráficas previas)
- Las gráficas anteriores (vía `/api/cdrs`) filtraban `is_scanner`; el rollup de 2.17.0 los incluía → inflaba volumen y sesgaba ASR/NER. Ahora `call_stats_hourly` excluye scanners (`is_scanner = true`).
- **Auto-rebuild por versión de semántica:** `meta.rollup_ver`. Al cambiar el cálculo, el portal hace TRUNCATE + backfill completo en el siguiente arranque (por el update normal), sin tocar la BD a mano.

---

## [2.17.0] — 2026-06-03

### Performance (sniffer — parseo HEP +46%)
- **`parse_hepv3` optimizado: +46% throughput por worker** (104.8k → 153.5k pkt/s/worker en benchmark local). El loop TLV hacía 3 `struct.unpack` separados + slices por CADA chunk (~34 unpack/paquete); ahora lee el header del chunk (vendor_id/type/len) en UNA pasada con `struct.Struct("!HHH").unpack_from`, y usa structs precompilados para puertos/timestamps/capture-id. Mismo output (validado). Sube el techo de captura del sniffer (~1.36M → ~2M pps con 13 workers) → más headroom ante ráfagas.
- Benchmark reproducible en `tools/bench_sniffer_parse.py`.
- **Nota de deploy:** cambia `hep_sniffer.py` → el update reinicia el sniffer (breve hueco de captura). Desplegar en VENTANA DE MANTENIMIENTO.

---

## [2.17.0] — 2026-06-03

### Fixed — Dashboard: las gráficas de tiempo mostraban "solo la última hora"
- **Causa:** el dashboard bajaba las 20.000 llamadas más recientes (`/api/cdrs?limit=20000`) y calculaba TODAS las series en el navegador. A alto volumen (p.ej. C3ntro), 20k llamadas = unos minutos de tráfico → solo el bucket más reciente se llenaba; el resto quedaba vacío. Los datos SÍ estaban en la tabla `calls` (historia completa), pero las gráficas no los leían.
- **Solución (escala sin saturar al escritor):** tabla rollup `call_stats_hourly` (1 fila/hora: total/answered/user_err/failed/ended) + endpoint `/api/dashboard/timeseries`. Las gráficas **Call Volume**, **ASR/NER Trend** y **Active Calls/Hour** ahora salen de la historia completa (24h/7d/30d), no de un muestreo reciente.
- **Mantenimiento:** backfill al arrancar (completo solo la 1ª vez; luego solo desde el último bucket) + refresh de las últimas ~4 h cada 2 min. Lecturas O(buckets) (cientos de filas/mes) → instantáneas, sin escanear el firehose ni competir con la captura.
- **Concurrencia por hora:** calculada como suma acumulada de inicios−fines (exacta, no muestreo).
- Frontend con fallback: si el endpoint no responde (servidor previo), las gráficas vuelven al cálculo desde el muestreo (sin romperse). Schema v5.

---

## [2.16.9] — 2026-06-03

### Added (fundación de codec dinámico + AMR/AMR-WB/GSM/G.723.1 — SIN VALIDAR)
- **Resolución de codec por payload-type + hint de la SDP.** El server pasa a `reconstruct_audio.py` el codec negociado (`codec_answer`); el reconstructor resuelve por PT estático (0/8/9/18/3/4) o, para PT dinámicos (96-127), por ese hint. Base para todos los códecs dinámicos.
- **AMR-NB y AMR-WB (RFC 4867, modo octet-aligned):** depaquetización RTP → formato de almacenamiento .amr → ffmpeg. **NO VALIDADO con tráfico real** (no hay encoder local ni tráfico AMR en C3ntro); pendiente de validar con pcap real. No maneja bandwidth-efficient (bit-packed) aún.
- **GSM-FR (PT3) y G.723.1 (PT4):** frame-based, decodificados con ffmpeg.
- **No-regresión:** G.711/G.722/G.729 (lo que usa C3ntro) intactos — son aditivos; AMR/Opus solo corren si la llamada los usa.

---

## [2.16.8] — 2026-06-03

### Added (reconstrucción de audio G.729 / G.729A / G.729B)
- **`reconstruct_audio.py` ahora soporta G.729 (PT 18)** — ~12% de las llamadas en C3ntro. G.729 no usa el modelo de "1 byte por tick" (sirve a G.711/G.722): es por FRAMES de 10 bytes (10 ms). Nueva ruta dedicada: concatena los frames en orden de timestamp y decodifica con `ffmpeg -f g729`. **Annex B (VAD/CNG/DTX):** descarta el frame SID de 2 bytes (al final del talkspurt) para no desalinear el demuxer; el silencio DTX queda como gap. Validado en llamada real (6408 frames → 64.08 s, 8 kHz estéreo correcto).

---

## [2.16.7] — 2026-06-03

### Fixed (audio reconstruido sonaba pésimo en llamadas G.711)
- **`reconstruct_audio.py` ahora decodifica según el payload-type real del RTP.** Antes decodificaba TODO como G.722 (`ffmpeg -f g722`), así que las llamadas **G.711 µ-law (PCMU, PT 0) y A-law (PCMA, PT 8)** —la mayoría en telefonía— se oían como ruido/garabato. Ahora mapea PT→códec (0→mulaw, 8→alaw, 9→g722) en la conversión a WAV y en la mezcla estéreo/mono, y selecciona los streams por esos PTs. Sin cambios en el sniffer.

---

## [2.16.6] — 2026-06-03

### Changed
- **Detalle de llamada: la sección de audio (reproductor) se movió al fondo, debajo del diagrama de flujo SIP** (a pedido). Orden ahora: métricas → flujo SIP (trazas) → audio.

---

## [2.16.5] — 2026-06-03

### Fixed (búsqueda de Calls daba resultados incorrectos)
- **Búsqueda de Calls acelerada con índice GIN de trigramas (pg_trgm).** La búsqueda hacía `LIKE '%term%'` sobre 7 columnas sin índice → **seq-scan de ~18 s** sobre millones de filas. A esa latencia las respuestas llegaban fuera de orden (cada tecla dispara una query) y se mostraban resultados que no correspondían a lo buscado. Ahora: una sola expresión indexable + índice `idx_calls_search` (pg_trgm, creado CONCURRENTLY en background al boot) → búsqueda en **~ms** (validado: 18 s → 0.6 ms). Además, si la query de búsqueda falla, ya NO se cae a la lista sin filtrar (devuelve vacío + flag) para no mostrar resultados engañosos.

---

## [2.16.4] — 2026-06-03

### Fixed (CDR de llamadas largas marcadas "incompletas/HUÉRFANO" con 0.0s)
- **`upsertCalls` ahora FUSIONA en vez de sobrescribir.** Una llamada larga puede correlacionarse en 2 fragmentos cuando el INVITE y el BYE están separados por más que la ventana de SIP en RAM (a alto volumen, pocos segundos): el fragmento del BYE llegaba como "huérfano" y PISABA al registro completo, dejando el CDR con duración 0.0s y badge HUÉRFANO aunque la llamada fuera real y completa (ej. una de 49s a Sinch). Ahora el ON CONFLICT toma `start_ts=LEAST`, `last_ts=GREATEST`, prefiere el fragmento NO-huérfano (o el de arranque más temprano), y recalcula firstTs/lastTs/duration del tramo unido. Validado en staging. Aplica a llamadas nuevas; las ya guardadas se corrigen al re-correlacionarse.

---

## [2.16.3] — 2026-06-03

### Changed
- **Calls: eliminado el botón "Cargar más"/"Load more"** del listado, a pedido. La lista muestra la primera página (filtros y búsqueda siguen acotando server-side).

---

## [2.16.2] — 2026-06-03

### Fixed (HOTFIX — portal en blanco/sin datos)
- **`app.js`: `window.tr` llamado durante la construcción del objeto de traducciones (bloque `es`, `lic_err_conn`)** → `Uncaught TypeError: window.tr is not a function` al cargar → **abortaba toda la inicialización del frontend** (tabs muertos, no aparecía login, ningún dato cargaba; el backend estaba sano). Introducido en commit 6b3c4033. Fix: string estático `'✗ Error de conexión'` (como en los otros 4 idiomas), sin llamar a `window.tr` en tiempo de carga. Detectado y reproducido con Chrome headless.

---

## [2.16.1] — 2026-06-03

### Changed (updates sin interrumpir la captura — "captura sagrada")
- **`install.sh`: el auto-updater ya NO reinicia el sniffer en updates de solo-portal.** Antes, cada `voxywatch-update` hacía `systemctl stop voxywatch voxywatch-sniffer` → el sniffer caía durante toda la instalación (a alto tráfico, millones de paquetes perdidos por update). Ahora compara `hep_sniffer.py` nuevo vs instalado (`cmp`): si **no cambió**, deja el sniffer corriendo y solo reinicia el portal → **captura sin interrupción (0 drops por el update)**. Si `hep_sniffer.py` cambió, sí reinicia el sniffer (necesario). Esto vuelve seguro el camino normal de actualización por línea de comando en servidores en producción con tráfico alto.

---

## [2.16.0] — 2026-06-03

### Added (arranque rápido — el portal usable en segundos tras un restart)
- **Boot en 2 fases.** Antes, al reiniciar, el portal cargaba el working-set completo (~250k filas: parse + correlación) ANTES de marcar el warm-up como listo → **pantalla de carga por ~4-5 min** a alto tráfico (160k pps). Ahora el arranque carga primero una **ventana reciente pequeña (`_FAST_BOOT_ROWS=40000`)**, marca el portal **usable en ~15 s**, y completa el working-set (250k) en **BACKGROUND** (con el lock `isParsing`, sin solaparse con el timer ni con purgas).
- `getPackets(settings, maxRowsOverride)` y `parseCapture({ maxRows })` aceptan un tope opcional de filas para la fase rápida. La captura NO se ve afectada (la hace el sniffer); el historial completo sigue sirviéndose desde la tabla `calls`. El dashboard de KPIs muestra la ventana reciente de inmediato y se completa al terminar el backfill.

---

## [2.15.0] — 2026-06-03

### Added (aviso preventivo de CPU al límite)
- **Nuevo aviso temprano de CPU saturado, ANTES de perder tráfico.** Hasta v2.14.1 el detector de cuello solo avisaba ante degradación REAL (drops > 0, spool creciendo o RAM en swap), así que un CPU clavado al 100% **sin** pérdidas todavía **no mostraba nada**. Ahora, si el CPU está saturado de forma **sostenida** (`idle ≤ 5%` o `loadavg > nº de cores` durante ≥2 muestras, ~30 s), aunque la captura siga al 100%, sale un banner amarillo: *"CPU al límite — la captura sigue completa, pero agrega cores antes de empezar a perder tráfico."*
- **Separación de niveles:** el camino crítico (ya perdiendo tráfico) tiene prioridad y mantiene su mensaje rojo; el preventivo es `warn` (amarillo) y solo aparece cuando NO hay un cuello real en curso. El campo `preventive` se expone en `/api/bottleneck`.
- **Anti-falsos-positivos:** exige ≥2 muestras seguidas de saturación (no dispara por un blip puntual de 1 intervalo). Mensaje bilingüe es/en (pt/fr/de heredan inglés).

---

## [2.14.2] — 2026-06-03

### Changed
- **Ventana de correlación en RAM acotada → menos churn de CPU en pico.** El parse incremental re-correlacionaba en RAM todo el set creciente cada tick (medido ~941k SIP). Como el historial COMPLETO ya se sirve desde `calls` (DB), la RAM solo necesita la ventana reciente: `effectiveMaxRows` se topa en **250k** filas → el parse procesa ≤250–375k/tick (antes ~941k, ~2.5× menos churn) y baja la RAM. **No limita capacidad** (captura/CDR viven en la BD, sin tope); no es un knob de cliente — es el working-set interno auto-gestionado. `total_calls` sigue siendo el historial real (estimación O(1) desde la BD).

---

## [2.14.1] — 2026-06-03

### Fixed
- **Detector de cuello: sin falsos positivos + recurso más específico.** Antes podía marcar *"cuello: write (drop 0)"* por un blip transitorio de recv-Q sin pérdida real. Ahora **solo alerta ante degradación REAL** (drops > 0, spool creciendo, o RAM en swap) y el bucket genérico "write" se separa en **disco / cpu / recv / net / ingest** (incluye `softirq` para red). Banner del GUI con i18n es/en para los recursos nuevos.

---

## [2.14.0] — 2026-06-03

### Changed (#1 de fondo — servir desde la BD SIN re-saturarla)
- **`total_calls` (en `/api/stats` y `/api/dashboard`) sale del historial REAL de `calls` (~2.7M), no de la ventana en RAM (~60k).** Usa una **estimación O(1)** vía `pg_class.reltuples` (7 ms, instantánea, la mantiene ANALYZE) en vez de `count(*)` (que sobre 2.6M tarda ~1 s y, repetido, vuelve a cargar la BD). Se expone también `total_calls_window` (las de la ventana RAM).
- **Decisión de diseño:** el dashboard de KPIs (ASR/ACD/MOS/histogramas) **se mantiene calculado en RAM** (ventana reciente, cacheado 10 s, SIN tocar la BD). Medí el agregado equivalente sobre `calls` en ~**7 s** → hacerlo por request **re-saturaría la BD y ahogaría al escritor del sniffer** (el problema original del reporte de escalabilidad). Un dashboard operativo es recienre-céntrico; la lista/CDR/flow completos ya salen de `calls`.

### Pendiente de fondo (en-proceso, sin carga de BD; requiere validación en deploy)
- **Correlación verdaderamente incremental:** hoy el parse re-correlaciona TODO el set en RAM cada tick (medido hasta ~941k SIP) — ya **no bloquea** (yields 2.11.0 + cursor 2.13.0) pero **quema CPU en pico**. Correlacionar solo las llamadas tocadas por el delta (no re-correr todo) es la optimización restante; cambia el output de correlación → se hará con validación en deploy (ya hay SSH de solo lectura).

---

## [2.13.0] — 2026-06-03

### Fixed
- **Freeze del portal — se elimina el bloque del fetch de DB (continúa el fix de 2.11.0).** El parse cargaba los paquetes con un solo `pool.query` de cientos de miles de filas → node-postgres **deserializaba TODO el result-set de forma síncrona** → bloqueo de varios segundos del event loop (el ~3.4 s residual / 20–30 s en pico). Ahora `getPackets` y el fetch del **parse incremental** traen por **cursor en tandas de 20k**, **cediendo el event loop** entre cada una. Con esto + los yields de correlación de 2.11.0, el parse (full e incremental) **ya no congela** el portal. Cursor validado contra la BD real de C3ntro (TimescaleDB).

### Pendiente (el redISeño de fondo, informado por diagnóstico SSH)
- El parse incremental **acumula en RAM y re-correlaciona todo** el set creciente cada tick (medido: hasta ~941k SIP en RAM); ya no **bloquea** (cede el hilo) pero **quema CPU en pico**. El fix de fondo (correlación verdaderamente incremental + servir dashboard/stats desde `calls`, como ya hacen calls/cdrs/flow) reduce ese costo — se hará validando contra datos reales (ya hay acceso SSH de solo lectura).

---

## [2.12.0] — 2026-06-03

### Changed
- **#8 (parcial, seguro) — `synchronous_commit = off` en la conexión del sniffer.** La captura es efímera y de altísimo volumen; no necesita esperar el fsync del WAL en cada commit. Recorta los stalls del write-path (el escritor drena más rápido bajo carga). Por sesión, no cambia la config global de Postgres; en un crash se pierde a lo sumo la última fracción de segundo de inserts (aceptable: SIP/CDR se re-capturan, RTP es efímero). Complementa los bloques RTP de v2.9.0.
- **#6 — Retención SOLO por % de disco (se elimina la purga por nº de filas).** El path por `capture_max_lines` se atascaba con un chunk legacy gigante (logueaba "ABORTADO" sin recortar) y contradecía el modelo solo-disco de v2.6.0. Quitado: el disco es el único control (suelta lo más viejo por prioridad RTP→trazas→CDR). `capture_max_lines` queda como no-op por compatibilidad.

### Pendientes que requieren validación con tráfico/BD reales (no se sueltan a ciegas)
- **#8 audio-a-archivos real / `rtp_packets` UNLOGGED:** bajaría aún más el I/O (saltar WAL), pero la interacción de UNLOGGED con la compresión nativa de TimescaleDB y el rediseño a archivos (FDs/índice) **no son verificables sin un Postgres+tráfico reales** → se harán con validación. Los bloques (2.9.0) + async-commit (este release) ya dan el grueso del alivio.
- **#5 RTCP en puerto propio:** ya es posible HOY sin código — apuntar el RTCP del SBC a un **puerto extra** (`hep_extra_udp_ports`, p.ej. 9910); el sniffer no descarta RTCP (el shed solo toca RTP), así queda fuera del firehose. Es deployment, no código.
- **RAM ~3.7 GB del portal:** rediseño del parse incremental (servir stats/dashboard desde `calls`, no retener sipMessages) — **ya NO es urgente** (el freeze, que era el síntoma grave, se eliminó en 2.11.0); 3.7 GB ≈ 12% de 30 GB.

---

## [2.11.2] — 2026-06-03

### Added
- **Banner de cuello de botella en el GUI (i18n).** El detector de v2.8.0 ya emitía warnings en log; ahora también se muestran en el portal: un banner superior lee `GET /api/bottleneck` cada 20 s y, si hay degradación, muestra *"⚠️ Capturando X% del tráfico — cuello: <recurso>. <acción>"* traducido **del lado cliente** (es/en), con color ámbar (warn) o rojo (critical). Cierra el pedido del reporte: "exponer los warnings también en el GUI, no solo en logs".

---

## [2.11.1] — 2026-06-03

### Changed
- **Los knobs internos de rendimiento ya no se muestran al cliente.** La tarjeta "Performance & Capture" del Settings (`capture_max_lines`, `parse_ram_pct`, `parse_max_rows`) queda **oculta** — son parámetros internos que el software auto-gestiona (defaults `auto`), no algo que el cliente deba tunear. Los inputs siguen en el DOM (ocultos) con sus valores auto para no romper el guardado. El recurso limitante se reporta solo vía `/api/bottleneck` ("qué subir"). `hep_workers` ya no tenía UI. (Directiva del reporte: reemplazar knobs por auto-gestión.)

---

## [2.11.0] — 2026-06-03

### Fixed
- **🔴 Se acabaron los congelamientos de 20–30 s del portal (el peor síntoma de UX).** `parseCapture`/`rebuildCallMetadata` corrían **síncronos** en el hilo de Node → al correlacionar ~548k SIP **bloqueaban el event loop** y NADA respondía (`/api/health` llegó a **30,177 ms**; el GUI se veía "todo en 0s" y solo funcionaba lo client-side). Ahora `accumulatePackets` y `rebuildCallMetadata` **ceden el event loop por tandas** (`_forEachYield`, cada 8192 elementos): el portal **responde durante la correlación**. Además se hace **swap atómico** de `callMetadata`/`sipByCallId`/`_callsSorted` al final → las lecturas ven los datos **previos completos** hasta el cambio, nunca un estado a medio construir. Resultados idénticos (misma lógica, solo cede el hilo). El parse inicial corre antes de armar el timer y los re-parses están protegidos por el lock `isParsing` → sin concurrencia.

### Notas
- Esto **elimina la necesidad** del knob `parse_max_rows` como mitigación del freeze (el usuario ya no tiene que tocarlo). Próximo paso (en curso): ocultar los knobs internos del Settings y servir Calls/stats 100% desde la tabla `calls` para reducir también la RAM del working-set.

---

## [2.10.1] — 2026-06-03

### Fixed (i18n — nada hardcodeado)
- **La pantalla de carga (warm-up) ya es bilingüe (default inglés).** Estaba toda en español hardcodeado (incluido el texto que venía del server). Ahora usa **inglés por defecto** y **español** si el usuario lo eligió (`vw_lang` en localStorage), traduciendo por código de fase (no por el texto del backend). Es la única UI servida antes de cargar el SPA.

### Notas
- **Cambiar contraseña ya está disponible para los 3 roles** (admin/operator/viewer): el endpoint `/api/auth/change-password` usa `requireAuth` (cualquier rol) y el botón de usuario del header se muestra para todos. Solo no se veía por el bug del warm-up corregido en 2.10.0. (Sin cambios de código.)
- Los strings del detector de cuello (`/api/bottleneck`) exponen un **código de recurso** (`cpu`/`disk`/`recv`/`ram`) + números → un futuro banner en el GUI debe traducirlos del lado cliente (la acción/detalle en texto son para logs).

---

## [2.10.0] — 2026-06-03

### Fixed
- **El indicador de usuario logueado + botón de cerrar sesión (arriba a la derecha) ya aparece.** Los elementos existían pero el interceptor de warm-up (v2.0.3) respondía **503 a `/api/auth/me`** durante el parse inicial, y `checkAuth` ante eso **borraba el token** y mostraba el login → el header de usuario nunca se activaba (y se perdía la sesión). Ahora los endpoints de **auth pasan durante el warm-up** (no dependen del parse) y `checkAuth` **no borra el token por un 503 transitorio** (solo en 401 real; reintenta si el portal está calentando). El header muestra el usuario activo y el botón Salir / Sign out.

### Changed (i18n)
- **Labels del header con i18n (default inglés).** El botón de cuenta tenía `title="Cuenta"` hardcodeado y el de logout/limpiar-búsqueda textos fijos → ahora con `data-i18n-title` y claves es/en (`btn_account_title`, `btn_logout`, `btn_clear_search`); el aria del bloque de plan gratuito quedó en inglés por defecto. (El resto de labels visibles ya tenían i18n; los placeholders en español eran solo fallback y se traducen en runtime.)

---

## [2.9.1] — 2026-06-03

### Changed
- **El flujo SIP (`/api/calls/:id/flow`) ahora funciona para TODO el historial (#2, P0).** Antes, una llamada fuera de la ventana en RAM (~41k) devolvía el ladder vacío (`trace_unavailable`); ahora se **reconstruye on-demand desde `packets`** por `call_id` (índice `idx_pkt_call_id` → O(log n), sin cargar nada a RAM). El detalle de cualquiera de las 1.3M+ llamadas de `calls` muestra su ladder SIP. Se conserva el fast-path de RAM para las recientes. El parseo replica exactamente la forma del mensaje que arma `accumulatePackets` (method/status/SDP/raw).

### Pendiente (#2, requiere validación)
- Reducir la RAM steady-state del portal (~3.7 GB): hoy el parse incremental retiene los mensajes SIP en RAM (`sipByCallId`) para el fast-path. Bajarlo implica rediseñar el parse incremental para que no dependa de RAM — toca todas las rutas de lectura, por eso conviene validarlo con datos reales antes de soltarlo.

---

## [2.9.0] — 2026-06-03

### Changed
- **🔴 RTP en bloques: recorta el I/O de disco que era el cuello (reporte maestro, P0).** El RTP se guardaba **fila-por-paquete** en `rtp_packets` → 5–10× el I/O necesario (WAL + heap + índice + MVCC por CADA paquete) → disco saturado (iowait 33%, util 87%) a ~334k pps. Ahora el sniffer **agrupa hasta 256 paquetes RTP en UNA fila** (blob enmarcado `VWB1` + `[1B len_ip][ip][2B len][rtp]…`), recortando ese overhead ~256× — sin file descriptors, sin archivos sueltos, reutilizando reconstrucción/retención/spool ya probados.
  - `reconstruct_audio.py` y `generate_pcap.py` **desenmarcan** los blobs (y siguen leyendo paquetes sueltos legados/spool sin cambios → migración transparente, el RTP viejo en `packets`/`rtp_packets` se sigue leyendo). El contenido RTP (SSRC/seq/ts/media) es **exacto** → audio íntegro; en PCAP los puertos de un blob son los de su primer paquete (aproximado, suficiente para diagnóstico).
  - Validado con round-trip frame→deframe (incluye media que contiene el magic, paquete suelto legado, y blob truncado sin crash).

> Nota de diseño: se eligió **agregación en Postgres** sobre archivos crudos por SSRC porque a ~6,400 streams concurrentes los archivos-por-SSRC reventarían los file descriptors y un archivo gigante por hora exigiría un índice — un sistema mucho mayor y, sin tráfico real para validar, más riesgoso. Los bloques logran el grueso del recorte de I/O (el overhead por-fila) de forma segura. Si tras esto el disco sigue siendo el cuello (lo dirá el detector de v2.8.0), el siguiente paso es archivos/tiering.

---

## [2.8.0] — 2026-06-03

### Added
- **Detección de cuello de botella en runtime + warnings accionables (reporte maestro, P1).** El portal muestrea cada 15 s las firmas del sistema (`/proc/stat` idle/iowait, `/proc/net/snmp` InDatagrams/RcvbufErrors, `/proc/net/udp` recv-Q de los puertos HEP, crecimiento del spool, `/proc/meminfo`), calcula el **% de tráfico realmente capturado** y clasifica el **recurso limitante** (CPU / disco / recepción / RAM) con una **acción concreta**. Se expone en `GET /api/bottleneck` (`{resource, severity, detail, action, capture_pct}`) y en `/api/diagnostics`, y emite un warning en log/telemetría al degradarse — p.ej. *"⚠️ Capturando 48% — cuello: disk (iowait 33%, spool creciendo). Sube IOPS/throughput del disco o activa audio-a-archivos."* Cumple el principio: el software dice **qué recurso subir**, sin hardcodes.

### Fixed
- **`hep_workers='auto'` ya no sobre-suscribe.** Antes tomaba TODOS los cores (cap 16) → 19 procesos en 16 cores, loadavg 25, peor rendimiento. Ahora `'auto'` usa **~75% de los núcleos** (deja headroom para PostgreSQL + portal + OS); un entero explícito se respeta tal cual. Si el cuello sigue siendo CPU, el detector lo dice.

---

## [2.7.2] — 2026-06-03

### Changed
- **Retención de audio: el RTP crudo se purga primero; los WAV quedan protegidos.** Antes el RTP crudo (firehose desechable) y los WAV (artefacto de audio que se quiere conservar) se purgaban en el **mismo** umbral (audio 60%), por lo que la presión de disco podía borrar WAVs valiosos junto con RTP basura. Ahora: el **RTP crudo se sacrifica primero** (umbral de audio, 60% — soltar un chunk libera muchísimo), las **trazas SIP** después (70%), y los **WAV se limpian solo bajo presión alta** (umbral CDR, 85%), junto con los CDRs huérfanos. Los WAV son la copia de largo plazo del audio (y, una vez purgado su RTP, la única) → se conservan más. **Sin settings nuevos**, reusa los umbrales que ya existen.

---

## [2.7.1] — 2026-06-03

### Fixed
- **En modo grabación ya NO se descarta audio.** La degradación adaptativa de RTP (v2.6.4) descartaba RTP también con `recording_enabled` activo → tiraba audio que sí se recibía. Ahora el shed **solo** aplica en modo métricas (grabación apagada), donde el RTP se descarta igual (ahí adelantarlo ahorra parse). Con grabación activa (default) se guarda **todo** el RTP que el host alcance a recibir.

### Notas (modelo de audio confirmado)
- **Guardar todo el audio:** el RTP capturado vive en `rtp_packets` y el WAV por llamada se reconstruye on-demand (`reconstruct_audio.py`); ambos (RTP + WAV) se **borran por el % de disco configurado en Settings** (umbral de audio 60% → trazas 70% → CDR 85%, lo más viejo primero). No hay tope por días: tú gobiernas cuánto audio se conserva con los %.
- **Capacidad en pico:** a ~335k pps el host de 8 cores no parsea todo el firehose; lo no capturado se pierde en el kernel (no por decisión del programa). Subir cores acerca a 0 pérdida — el sizing queda para después, según pediste.

---

## [2.7.0] — 2026-06-03

### Changed
- **`/api/cdrs` sirve desde la tabla `calls` (historial completo), no desde RAM (P1, #4).** Antes la lista de CDR salía de `callMetadata` en RAM (solo la ventana del último parse), por lo que el GUI mostraba datos parciales/desfasados y se perdían tras un reinicio. Ahora lee de la tabla `calls` (767k+) con los mismos filtros y keyset que `/api/calls` (status/búsqueda/tiempo/cursor), cacheando el conteo total 30 s. Respuesta **compatible** (`{total, cdrs, next}`) → el GUI no se rompe; el `total` ahora refleja el historial real y los CDR son persistentes. Fallback a RAM si la BD no está lista.

### Pendiente (P1, próximas versiones)
- Paginación/búsqueda server-side en la vista CDR del frontend para **navegar todo** el historial (hoy carga la página reciente de 20k y filtra client-side).
- Reducir la RAM del portal (~3.7 GB): que `parseCapture` no cargue todo a memoria y que `/api/stats` y `/api/dashboard` salgan de la tabla `calls`/continuous aggregates.

---

## [2.6.5] — 2026-06-03

### Fixed
- **AutoPurge ya recorta el chunk legacy (la tabla `packets` dejaba de crecer sin control).** El guard de 2.0.4 ("no borrar más del 34% del total") confundía el wipe catastrófico (incidente: `capture_max_lines=50000` → quedaban 2,300 filas) con una purga legítima del chunk viejo gigante. Ahora el guard usa un **piso de filas** (`minKeepRows` = ½ del target): bloquea el wipe a casi-cero pero **permite** dropear el chunk legacy cuando aún queda un volumen razonable (caso C3ntro: deja ~9M con target 10M). El crecimiento de `packets` queda acotado de nuevo.
- **GUI ya no se queda vacío (401) tras cada update.** El secreto JWT se regeneraba ante *cualquier* fallo de lectura, invalidando todas las sesiones en cada reinicio. Ahora: si el archivo existe se usa **siempre** (nunca se regenera por un fallo transitorio; si no se puede leer, aborta el arranque para reintentar en vez de invalidar), se genera **solo** en el primer arranque, y admite override estable por `VOXYWATCH_JWT_SECRET`.

### Changed
- **Buffer de recepción 8 MB → 16 MB** (aprovecha el `rmem_max=32M` del instalador). Más colchón para ráfagas; ayuda a que el RTCP de bajo volumen sobreviva en el socket compartido con el firehose RTP.
- **Corrección de la promesa de v2.6.4 sobre RTCP.** El RTCP **no** queda "siempre completo" cuando comparte el socket del RTP (puerto 9062): el kernel descarta ~indiscriminadamente al saturarse, antes de que la app pueda discriminar. Garantizado bajo pico = **SIP/CDR** (puerto 9060 propio); el RTCP es **best-effort** (las métricas de calidad quedan más espaciadas, no ausentes). El RTCP 100% garantizado requiere un **stream/puerto HEP dedicado desde la fuente** (decisión del emisor/SBC, no de VoxyWatch) — es un punto de sizing, no un knob de config.

---

## [2.6.4] — 2026-06-03

### Added
- **Degradación adaptativa de RTP — captura de alto tráfico sin configuración por cliente.** A volúmenes extremos de RTP (p.ej. ~335k pps), ni el multiproceso (`'auto'`) cubre el parseo en Python (límite del GIL: ~22–30k pps por core). En vez de pedir al operador que active `rtcp_only`/`recording_off` (apagaría el audio para todos), el sniffer ahora **mide los descartes UDP del kernel** (`RcvbufErrors` en `/proc/net/snmp`, ~1×/s) y, **solo cuando el kernel está perdiendo paquetes**, descarta automáticamente una fracción del **RTP crudo** ANTES de parsearlo (jamás SIP/RTCP) para drenar el socket. Conserva 1 de cada N (N sube ×2 bajo presión hasta 1/32, baja a la mitad y vuelve a 1/1 al cesar los drops). Resultado: **SIP (CDR) y RTCP (calidad: MOS/jitter/pérdida) siempre completos**, y el audio se captura íntegro en operación normal y de forma best-effort (muestreado) solo bajo pico — todo automático, cero config. Overhead nulo cuando no hay presión (el chequeo barato de RTP solo corre con descarte activo). Nuevas métricas en STATS: `RTP_shed` y `keep 1/N`.

> Nota: a escalas donde ni así alcanza, las palancas siguen disponibles (multiproceso ya por default; `rtcp_only_sources`/`recording_enabled` para quien quiera forzar). La degradación adaptativa garantiza que, pase lo que pase, la señalización y la calidad nunca se sacrifican.

---

## [2.6.3] — 2026-06-03

### Fixed
- **🔴 El multiproceso del sniffer venía apagado de fábrica → ~93% de pérdida de RTP en pico.** El supervisor `SO_REUSEPORT` (P2) estaba implementado pero `hep_workers` tenía **default = 1**, así que un solo core hacía el `recvfrom` y a ~335k pps el socket se desbordaba. Ahora el **default es `'auto'`** (= núcleos, cap 16) en el portal **y** en el sniffer (incluido el merge de `load_settings`, para que instalaciones existentes sin el campo también lo activen al reiniciar). Reparte el recv entre cores y sube el techo de pps. _Nota: a 335k pps ni 8 workers bastan solos → combinar con `rtcp_only_sources`/`recording_enabled=false` en fuentes sin audio (~50× menos pps)._
- **AutoPurge no podía recortar con chunks grandes.** `chunk_time_interval` de `packets` y `rtp_packets` baja de **6 h → 1 h** (vía `create_hypertable` + `set_chunk_time_interval` idempotente para upgrades): más chunks en la ventana de retención ⇒ el chunk más viejo es una fracción pequeña ⇒ el guard de seguridad (máx ~34% por purga) ya puede dropearlo. (Aplica a chunks NUEVOS; los chunks gigantes ya existentes envejecen por presión de disco.)
- **`/api/health` devolvía 503 durante el parse inicial** (disparaba falsas alertas en monitores/orquestadores). Ahora responde **200 `{ok:true, warming:true}`** mientras calienta: el proceso está vivo, solo cargando histórico.

---

## [2.6.2] — 2026-06-03

### Fixed (auditoría — cabos sueltos)
- **`/api/stats` mostraba `total_rtp = 0`.** El conteo de RTP venía de `rtpPackets[]` en RAM, que está vacío desde el desacople de RTP (P1.1). Ahora `total_rtp` y `total_packets` salen del conteo **real** de las hypertables (`rtp_packets` y `packets + rtp_packets`), cacheado en `_captureStats` (O(1), sin coste por request).

### Removed
- **Continuous aggregate muerto `pkt_stats_1m`.** Se creaba en el esquema (refrescaba cada minuto escaneando `packets`) pero el portal nunca lo consultaba. Se elimina del esquema con `DROP MATERIALIZED VIEW IF EXISTS` (idempotente → también lo quita, junto con su política, en instalaciones que lo tuvieran).

---

## [2.6.1] — 2026-06-03

### Fixed (auditoría de código)
- **Métricas de captura subestimadas tras separar el RTP (regresión de 2.4.0).** `capture_size`, `capture_lines` y el estado en `/api/status` medían solo la tabla `packets` y dejaban fuera `rtp_packets` (≈99% del volumen). Ahora suman **ambas** hypertables (filas y bytes), y el "último paquete" de `/api/status` toma el ts más reciente de cualquiera de las dos. El % de disco (df) ya era correcto; esto corrige solo lo que se muestra.
- **Purga de CDR bajo presión de disco podía borrar historial valioso en vano.** La versión previa borraba los CDR más viejos en bucle hasta bajar del umbral, pero la tabla `calls` es chica y `DELETE` no libera disco al instante → podía vaciar CDRs útiles sin aliviar el disco. Ahora solo borra **CDRs huérfanos** (aquellos cuyo SIP ya fue dropeado de `packets`), acotando la tabla sin destruir CDRs que aún tienen su ladder SIP.
- **`reliefPurgeOldestAudios` llamaba `df` (síncrono) por cada archivo** → posible bloqueo del event-loop con muchos WAV. Ahora re-chequea el disco cada 25 borrados.

---

## [2.6.0] — 2026-06-03

### Changed
- **Retención simplificada: ahora es ÚNICAMENTE por % de disco. Se eliminó por completo el tope de edad por días.** Tras revisarlo, los "días" no aportaban (dependen del volumen y del tamaño del disco) y solo agregaban confusión. El único control de retención es el umbral de disco por tipo: cuando el disco cruza el umbral se borra lo **más viejo** de ese tipo, por prioridad **RTP/audio (60%) → trazas SIP (70%) → CDR (85%)**.
  - Eliminados los settings `purge_audio_keep_days`, `purge_traces_keep_days`, `purge_cdr_keep_days` y sus campos en la UI (cada tarjeta de purga deja solo el umbral de disco).
  - Al arrancar, el portal **quita cualquier política de retención nativa por tiempo** que hubiera quedado de versiones previas (`stripNativeRetention`), para que únicamente mande el disco.
  - El esquema no crea políticas de retención por tiempo.

> Validado contra TimescaleDB: el esquema no crea políticas de retención; el portal elimina al arrancar cualquier política nativa heredada (queda solo el control por disco).

---

## [2.5.0] — 2026-06-03

### Changed
- **Rediseño de la política de retención: el % de disco es el control real; los "días" pasan a ser un tope de edad OPCIONAL (apagado por default).** Antes había dos mecanismos solapados y los días se usaban de forma confusa (y, tras la separación de RTP, redundante con la retención nativa): además, "días" no sirve para administrar disco porque depende del volumen de llamadas y del tamaño del disco. Ahora:
  - **Control por disco (siempre activo):** cuando el disco cruza el umbral de un tipo, se borra lo **más viejo** de ese tipo (sin importar la edad), por prioridad **RTP/audio (60%) → trazas SIP (70%) → CDR (85%)**. El RTP, lo más pesado y menos valioso, se sacrifica primero. Esto **siempre** acota el disco (antes, si todo era más nuevo que N días, el disco podía llenarse igual).
  - **Tope de edad por días = opcional, default 0 (apagado).** Solo para cumplimiento legal/privacidad ("no conservar más de N días"). Para hypertables lo aplica la retención nativa de TimescaleDB; para la tabla `calls` (no es hypertable) lo aplica el portal. `0` lo desactiva de verdad (quita la política nativa).
  - El esquema ya **no impone** un tope de edad por default; el portal reconcilia la retención nativa desde settings al arrancar y al guardar cambios.
  - UI: los campos de días aceptan `0` y se renombraron a "Tope de edad opcional (0 = sin tope)".

> Nota de upgrade: los clientes que ya tenían días configurados (p.ej. 7/30/90) los conservan (más el nuevo alivio por disco, que los hace más seguros). Para adoptar el modelo "solo disco", poner los días en `0`.

> Validado contra TimescaleDB: sin tope de edad por default; reconcile agrega/quita la política nativa según los días (0 = quitada); el alivio por disco dropea el chunk más viejo primero (RTP→trazas) y borra los CDR más viejos primero.

---

## [2.4.0] — 2026-06-03

### Added
- **RTP en hypertable propio (`rtp_packets`) → retención diferenciada real (Fase 3.2).** El RTP crudo (≈99% del volumen, solo útil a corto plazo para audio/PCAP on-demand) ahora vive en su **propia hypertable**, separado de `packets` (SIP/RTCP/LOG). Esto permite **retener el RTP poco (p.ej. 7 días) y el SIP/CDR mucho más (30+ días)** — algo imposible con una sola tabla, porque `drop_chunks` borra por TIEMPO, no por tipo de dato. El esquema crea `rtp_packets` con compresión + retención corta; `packets` pasa a retención larga.
  - **Ingesta dual en el sniffer:** el escritor rutea cada paquete a su tabla (RTP → `rtp_packets`, resto → `packets`) con COPY independiente por tabla. El **spool de resiliencia (Fase 1b) ahora es por tabla** (`voxywatch_spool.csv` + `voxywatch_spool.rtp.csv`): si la BD cae, cada flujo se vuelca a su spool y se reproduce a su tabla al recuperarse, sin pérdida ni duplicados (lo ya escrito en una tabla no se re-spoolea si la otra falla).
  - **Retención reconciliada desde settings al arrancar:** el portal fija la retención nativa de cada tabla desde `purge_traces_keep_days` (señalización) y `purge_audio_keep_days` (RTP), para que la diferenciación aplique también en upgrades. Bajo presión de disco, el umbral de audio también dropea chunks de `rtp_packets`.
  - **Lecturas de audio/PCAP transparentes a la migración:** `reconstruct_audio.py` y `generate_pcap.py` hacen `UNION` de `rtp_packets` + el RTP legado en `packets`, filtrando por `ts` (columna de partición → exclusión de chunks, clave a escala TB). En upgrades, el RTP viejo se queda en `packets` y envejece por su retención mientras el nuevo entra en `rtp_packets` — **sin backfill** (el RTP es efímero).

> Validado contra TimescaleDB: ruteo correcto (RTP→rtp_packets, SIP/RTCP→packets, 0 cruce); con la BD caída se spoolearon 80 señalización + 240 RTP con **0 pérdida**, replay a la tabla correcta al reanudar; `reconstruct_audio.py` auto-descubrió SSRC de **ambas** tablas y generó stereo/mono; reconciliación de retención cambia ambas políticas nativas.

### Notas de roadmap (Fase 3)
- Diferido a P3.3: grabaciones a archivo/S3 + tiered storage de chunks viejos a object storage (opt-in, requiere infra del cliente).

---

## [2.3.0] — 2026-06-03

### Added
- **Modo de grabación de audio (`recording_enabled`) → el mayor recorte de almacenamiento (Fase 3).** Con la grabación **desactivada**, el sniffer **deja de almacenar el RTP crudo** (conserva RTCP/RTCPXR/SIP): como el RTP es ~99% del volumen, esto reduce los datos y los pps **~50× o más**. La calidad de las llamadas (MOS, jitter, pérdida) sigue saliendo de **RTCP**; lo único que se pierde es la reconstrucción de audio. Reusa el mecanismo de filtrado por fuente (Fix5) aplicándolo a todas. **Default `true` (graba) — sin cambios para quien usa audio.** Ideal para NOCs que solo necesitan señalización + calidad. Aplica al reiniciar el sniffer.

### Fixed
- **Retención del CDR ahora acota la tabla persistente `calls` (antes crecía sin límite).** Desde la Fase 1 la vista Calls/CDR se sirve de la tabla `calls`, pero la purga por antigüedad (`purge_cdr_keep_days`) solo borraba el mapa **en RAM** — la tabla en PostgreSQL **nunca se limpiaba** y crecía indefinidamente. Ahora `purgeOldCdrs` hace `DELETE FROM calls WHERE start_ts < cutoff` (además del mapa en RAM), respetando `purge_cdr_keep_days` cuando el disco cruza `purge_cdr_threshold_pct`.

> Validado contra TimescaleDB: con grabación OFF se enviaron 800 RTP → **0 almacenados** (800 `RTP_filtrados`), SIP/RTCP intactos; con grabación ON el RTP vuelve a guardarse. Retención de CDR: borra los CDRs > N días de la tabla `calls` y conserva los recientes (límite exacto en el día N).

### Notas de roadmap (Fase 3)
- Diferido a una versión posterior: **RTP en hypertable propio** (para retener RTP más corto que el SIP **aun grabando**) y **grabaciones a archivo/S3 + tiered storage** (requiere infra de object storage del cliente → opt-in).

---

## [2.2.0] — 2026-06-03

### Added
- **Sniffer multiproceso con `SO_REUSEPORT` (Fase 2) → sube el techo de pps por encima de un solo núcleo.** Hasta ahora la captura corría en un proceso (un hilo lector bajo el GIL), con un techo de throughput limitado a un core. Con el ajuste `hep_workers` > 1 (o `"auto"`), el sniffer arranca **N procesos de captura** que comparten el mismo puerto vía `SO_REUSEPORT`; el **kernel reparte los datagramas** entre workers por 4-tupla (mismo flujo origen→destino siempre al mismo worker). Cada worker tiene su propio hilo escritor, conexión a PostgreSQL y **spool propio** (`voxywatch_spool.wN.csv`). La correlación de llamadas la sigue haciendo el portal desde la BD, así que repartir paquetes entre procesos es seguro.
  - **Supervisor** ligero: forkea los workers, **reenvía señales** para cierre limpio (cada worker drena su cola/spool antes de salir) y **respawnea** (con backoff anti crash-loop) cualquier worker que muera inesperadamente.
  - **Default `hep_workers: 1` (monoproceso)** — comportamiento idéntico al actual; el multiproceso es **opt-in** para clientes de alto volumen. Cap de 16 workers.
  - Configurable desde el portal (Settings → `hep_workers`) o en `voxywatch_settings.json`; aplica al reiniciar el sniffer.
- **Réplica de lectura (opt-in) para el portal.** Si se define `VOXYWATCH_DB_REPLICA_DSN` (env del servicio, o `install.sh --replica-dsn`), las **lecturas** de UI/métricas/CDR del portal se enrutan a una **réplica de streaming** que el cliente configura aparte; las **escrituras** (sniffer) y el **parse/ingesta** siguen en el primario. Sin la variable, lee del primario igual que antes. Tolera lag de replicación (frescura sacrificable antes que la captura).

> Validado: con `hep_workers=2` el kernel repartió la carga entre ambos workers (cada uno cruzó 1000 paquetes), **0 `queue_drop`**, todas las filas persistidas; apagado limpio (supervisor + workers, socket liberado) y respawn correcto al matar un worker. El camino monoproceso por defecto quedó intacto.

---

## [2.1.2] — 2026-06-03

### Fixed
- **La ingesta ya no pierde paquetes por atascos de la BD (spool a disco, Fase 1b).** Antes, si la BD se atrasaba/caía, la cola del sniffer se desbordaba y se descartaban paquetes (`queue_drop`). Ahora el escritor, ante una caída de conexión, **vuelca a un archivo append-only en disco** (`voxywatch_spool.csv`, mismo formato CSV que `COPY`) en vez de tirar; cuando la BD se recupera, **reproduce (replay) el spool y lo borra**. Atasco transitorio = **lag, no pérdida**.
  - El escritor siempre drena (a BD o a disco) → la cola no se queda llena → el lector deja de descartar. Detección de caída con flag + probe cada 5 s; replay oportunista en idle y al arrancar (recupera un spool dejado por un crash).
  - Cap de disco (2 GB) como **último recurso**: solo si se excede se vuelve a contar `queue_drop`. Errores de datos (lote venenoso) se descartan, no se spoolean.
  - Stats del sniffer muestran `spooled`, `replayed`, tamaño del spool y `db_down`.
  - Validado: con la BD detenida se spoolearon 200 paquetes con **0 drops**; al reanudar, los 200 se reprodujeron y el spool quedó vacío.

---

## [2.1.1] — 2026-06-03

### Changed
- **El portal deja de cargar RTP crudo (desacople, Fase 1.1) → independiente del volumen de media.** `getPackets`/parse incremental ahora excluyen `protocol_id = 4` (RTP, ~99% del volumen); con el nuevo índice parcial `idx_pkt_nonrtp_id` la carga es O(maxRows) sin importar cuánto RTP haya. La misma ventana de memoria ahora cubre **muchísimo más historial de señalización** y baja drásticamente CPU/RAM del portal por tick. La calidad global sale de **RTCP**; el jitter/loss fino y el audio se calculan **on-demand por call_id**.

### Fixed
- **Audio y PCAP sin RTP en RAM.** `reconstruct_audio.py` consulta el RTP por la **ventana de tiempo** de la llamada y **auto-descubre los SSRC** (top-2 por paquetes, priorizando G.722) — ya no depende de que el portal le pase los SSRC. El audio (stereo/mono) se sirve por **nombre determinístico** → funciona también para llamadas **históricas** (fuera de la ventana en RAM). Reconstruct/pcap obtienen la llamada de RAM **o** de la tabla `calls`.

> Validado end-to-end: el portal carga SIP/RTCP y reporta `rtp:0`; `reconstruct_audio.py` auto-descubre SSRC y genera stereo/mono con ffmpeg.

---

## [2.1.0] — 2026-06-03

### Added
- **CDR persistente + lista de Calls servida desde la BD (escalabilidad, Fase 1).** Nueva tabla **`calls`** (1 fila por llamada, columnas indexadas + JSONB con el objeto completo) y **continuous aggregate `pkt_stats_1m`** (rollups por minuto para el dashboard). El portal correla SIP en RAM como hasta ahora y hace **upsert por lote** del resultado a `calls`; la vista Calls se sirve con **keyset pagination** (sin `COUNT`/`OFFSET`) y **filtros server-side** (All/Completed/Rejected, tiempo, búsqueda) → instantánea a cualquier escala y con **historial persistente** más allá de la ventana en RAM, con botón "cargar más".
  - Detalle (`/api/calls/:id`) y ladder (`/api/calls/:id/flow`) caen a la tabla `calls` para llamadas históricas (el trace SIP completo queda disponible para llamadas dentro de la ventana cargada; se ampliará con el desacople de RTP).
  - Validado end-to-end contra TimescaleDB real (parse→correlación→upsert→keyset, filtros y paginación).

> Siguiente (v2.1.x): el portal dejará de cargar RTP crudo (99% del volumen) → calidad por RTCP + on-demand; spool de ingesta a disco; multiproceso.

---

## [2.0.8] — 2026-06-03

### Fixed
- **🔴 El portal ya no provoca pérdida de paquetes en la captura (incidente C3ntro).** Bajo uso normal, `/api/status` hacía `COUNT(*) + MAX(ts_sec)` (full seq-scan sobre el hypertable de 49 GB) en cada poll de la UI; al no haber caché/single-flight/timeout se apilaban (14+), saturaban el I/O de Postgres y **ahogaban al escritor COPY del sniffer**, cuya cola se desbordaba y tiraba ~50% de los paquetes (INVITEs y RTP). Fixes (Fase 0 del rediseño de escalabilidad):
  - `/api/status`: filas vía `approximate_row_count` (O(1)) y último timestamp vía `ORDER BY ts DESC LIMIT 1` (índice PK), con **caché 10 s + single-flight** (20 polls concurrentes → 1 sola consulta).
  - **Pool de lectura separado y acotado** (`max 4`, `statement_timeout 5 s`) para las consultas de UI/métricas → no pueden apilarse ni robar I/O sostenido a la ingesta (el sniffer usa su propia conexión).
  - `getCaptureRowCount()` (autoPurge/purga) y el `COUNT(*)` previo a los TRUNCATE de data-wipe → `approximate_row_count`.
  - El parse ya no hace `COUNT(*)`: carga siempre los últimos `maxRows` (`ORDER BY id DESC LIMIT` + reverse), acotando memoria sin escanear.

> Primera fase de un rediseño de escalabilidad por etapas (tabla `calls`/CDR dedicada, RTP solo por call_id, agregados continuos, spool de ingesta, multiproceso) para escalar a TB.

---

## [2.0.7] — 2026-06-02

### Added
- **Disposición SIP precisa en el badge del preview de Calls.** En vez del `call_result` crudo, cada llamada muestra su resultado real con reason-phrase: `200 OK`, `Active`, `486 Busy Here`, `603 Declined`, `403 Forbidden`, `404 Not Found`, `503 Service Unavailable`, `302 Moved Temporarily`, etc. Casos especiales tratados como un experto SIP: **Not Answered** (CANCEL tras 180/183), **Cancelled** (CANCEL sin timbrar), **No Answer** (timbró y timeout), **Ignored** (INVITE sin respuesta), **In Progress** (solo 100 Trying), **Partial (mid-call)** (BYE sin INVITE). Los retos 401/407 no se marcan como fallo si luego hay éxito. `call_result` se mantiene intacto (filtros/dashboard).
- `fail_reason` ahora usa la reason-phrase real (ej. "404 Not Found" en vez de "404 404").

### Fixed
- **i18n: el portal vuelve a ser 100% inglés por defecto y respeta el cambio de idioma.** Se eliminaron decenas de strings en español hardcodeados que no pasaban por el sistema de traducción (badge "VIVO", encabezados "Origen/Destino" del flujo SIP, "Sin datos", botones de reinicio/guardado/borrado, login, gestión de usuarios, data-wipe, diagnósticos, tooltips, etc.). Ahora todos usan `window.tr()` / `data-i18n`, con traducción en inglés y español.
- Formato de fecha/hora ya no forzaba `es-MX`: se adapta al idioma activo del portal.

---

## [2.0.6] — 2026-06-02

### Added
- **Filtro "Rejected" en la vista de Calls.** Junto a las pestañas **All** y **Completed** se añade **Rejected**:
  - **Completed** = llamadas con **INVITE + BYE** (`call_result` `answered`). Las de solo-BYE (sin INVITE) ya no cuentan como completadas.
  - **Rejected** = INVITE con una **respuesta final ≠ 200 OK** (4xx/5xx/6xx, busy 486, cancelled 487).
  - **All** = todas las llamadas (sin filtro).
  - Etiqueta `filter_rejected` traducida en los 5 idiomas.

---

## [2.0.5] — 2026-06-02

### Fixed
- **🔴 Throughput del sniffer: ~86% de pérdida de RTP bajo carga → desacople recv/insert.** El loop hacía `recvfrom → parse → insert en Postgres` **síncrono en el mismo hilo**; mientras esperaba cada `commit` no drenaba el socket UDP (techo ~11k pps, independiente del hardware). Ahora el **hilo lector solo drena el socket y encola** (cola acotada de 200k con backpressure → drop contado), y un **hilo escritor** vuelca con **`COPY`** (FORMAT csv, flush por 2000 filas o 200 ms). Sube el techo de ingesta muy por encima de 11k pps. Reconexión/retry y shutdown con drenado del lote final preservados.

### Added
- **Toggle "solo-RTCP" por fuente** (`rtcp_only_sources`, en Settings → Performance & Capture). Lista de IPs/nombres de fuente separados por coma, o `*` para todas: el sniffer **descarta el RTP crudo** de esas fuentes conservando RTCP/RTCPXR/SIP → recorta ~50× el ritmo de paquetes cuando no se necesita grabación de audio.
- **Tuning de kernel desde el instalador** (`/etc/sysctl.d/99-voxywatch.conf`): `net.core.rmem_max=32M`, `rmem_default=16M`, `netdev_max_backlog=10000`. El sniffer ya pedía `SO_RCVBUF` de 8 MB pero el kernel lo recortaba a 416 KB. Ayuda con ráfagas (necesario, no suficiente solo).
- Stats del sniffer ahora muestran salud del pipeline de ingesta: profundidad de cola, filas COPYadas, `queue_drop` y RTP filtrados.

---

## [2.0.4] — 2026-06-02

### Fixed
- **🔴 AutoPurge ya no puede borrar el histórico de golpe.** El límite por `capture_max_lines` llamaba a `purgeOldCaptures()`, que dropea el **chunk más viejo completo** (TimescaleDB, granularidad 6 h) ignorando el porcentaje. Si el histórico quedó en pocos chunks grandes (típico tras migrar de 1.2.x), un solo drop podía borrar casi todo (incidente C3ntro: ~2M → 2.3k filas en un arranque). Ahora un **guard de seguridad** cuenta cuántas filas eliminaría el drop y **aborta si supera ~1/3 del total** en una sola purga automática, dejando una alerta en el log en vez de borrar. Las purgas manuales (Settings) y el alivio por presión de disco no cambian.
- **Update no deja servicios caídos por solape.** Un `install.sh` manual y el `voxywatch-update.timer` corriendo casi a la vez se pisaban (uno hacía `systemctl stop` mientras el otro ya había arrancado; el segundo `install` del binario en uso fallaba y abortaba antes de re-arrancar). Ahora `install.sh` toma un **lock (`flock`)**: el segundo run sale limpio en vez de colisionar.
- **`install.sh` apto para one-liner / binario en uso.** El binario se instala a un temporal y se renombra (`mv` atómico) → no más `File exists` / `Text file busy` al reemplazarlo en caliente. Los prompts solo se piden si hay terminal real (`tty_ok`), eliminando el error `/dev/tty: No such device` en modo no-interactivo (timer/ssh sin tty).
- **Arranque robusto:** tras el update, `install.sh` **verifica que el portal y el sniffer queden `active`** (reintenta una vez y avisa dónde mirar si no).

### Changed
- El log de purga ya no muestra un "keep N%" engañoso (ese porcentaje no se aplicaba al drop por chunk).

---

## [2.0.3] — 2026-06-02

### Fixed
- **Arranque ~35 min → segundos (regresión v2.0.2)** — la correlación SIP→llamadas en `rebuildCallMetadata()` escalaba como O(llamadas × paquetes): por cada llamada re-escaneaba los ~628k paquetes RTP (detección NAT), todos los reportes RTCP y los `arrivalTimes` de cada SSRC. Ahora se precalculan índices **una sola vez** (src-IPs por SSRC, set de call-ids RTCP, `arrivalTimes` ordenados con conteo por *binary search*) → coste ~lineal. Resultados idénticos, validados con 20k casos aleatorios.

### Added
- **Pantalla de carga (warm-up)** — el portal abre el puerto 3080 de inmediato y, mientras corre el parse/correlación inicial, sirve una página "Cargando histórico…" con fase en vivo y barra de progreso (polling a `/api/boot-status`), en vez de quedar inaccesible o mostrar datos vacíos. Recarga sola al terminar. La captura de tráfico (sniffer) nunca se interrumpe.
- **`parse_max_rows`** — nuevo setting (UI en Settings → Performance) que fija un tope **absoluto** de paquetes a cargar al inicio, independiente de la RAM total (0 = auto). Útil en hosts con mucha RAM donde la heurística por `% RAM` carga de más.
- **`GET /api/boot-status`** — endpoint público con la fase y el progreso del arranque.

### Changed
- **Arranque no bloqueante** — `startHttpServer()` corre antes de `bootstrap()`; el parse inicial ocurre en segundo plano. `GET /api/stats` expone `warming_up` y el resto de `/api/*` responde `503` durante el warm-up.
- **Log de carga más claro** — el mensaje de `parseCapture` ya no dice "80% de RAM" de forma engañosa; reporta el límite efectivo real (`parse_max_rows` o `parse_ram_pct` + cap de string de Node).

---

## [1.2.19] — 2026-05-27

### Added
- **Dashboard — toggle Cliente / Proveedor** — la tabla de detalle ahora tiene dos botones para cambiar entre vista por IP/label de origen (cliente) y vista por IP/label de destino (proveedor/carrier); búsqueda y sort funcionan en ambos modos
- **Diagnostics — monitor live CPU y RAM** — nueva tarjeta "Resources" con barras animadas que actualiza cada 4 s mientras el tab está abierto; colores verde/ámbar/rojo según umbral; se detiene al cerrar settings
- **Diagnostics — botón de Update** — fila "Update" en la sección Runtime: muestra versión disponible con botón "Actualizar" que abre el modal existente, o "✓ Al día" en verde
- **HEP Capture — etiquetas inline** — la columna Label de la tabla de fuentes activas es ahora un campo editable; blur o Enter guarda en `/api/ip-labels` con confirmación visual

### Changed
- **Auto-update manual** — eliminados los timers automáticos de check (60 s y 24 h); `GET /api/version/latest` dispara el check en cada llamada; el badge solo aparece cuando el admin abre Diagnostics
- **Settings — inputs numéricos sin flechas** — eliminados los spinners de todos los `<input type="number">` en settings (Chrome, Firefox, Safari)

### Fixed
- **SIP flow — flows largos cortados** — `.sip-svg-wrap` tenía `overflow-y:hidden` y `max-height:360px` fijos; cambiado a `overflow-y:auto` y `max-height:clamp(360px,60vh,720px)` para que flows con muchos mensajes sean scrolleables sin cortar el diagrama

---

## [1.2.18] — 2026-05-27

### Fixed
- **SIP flow diagram — RTCP-as-JSON noise** — Asterisk `res_hep_rtcp.so` sends RTCP statistics as JSON inside HEP packets; these were appearing as raw JSON rows in the SIP sequence diagram. The `/api/calls/:id/flow` endpoint now filters to only include messages with a valid SIP method or status code, so INVITE/1xx/200/BYE/ACK display cleanly. RTCP data continues to be stored and used for MOS/jitter/CDR quality metrics.

---

## [1.2.17] — 2026-05-27

### Fixed
- **Sniffer service name auto-detection** — `server.js` hardcoded `voxywatch-sniffer.service` everywhere; the service is now detected at startup by probing `voxywatch-sniffer.service` first (production package installs) and falling back to `hep-sniffer.service` (source/dev installs); all status, restart, and diagnostics calls use the detected name
- **Sniffer restart fallback** — `POST /api/sniffer/restart` now tries `busctl` D-Bus first (required when `NoNewPrivileges=true`); if `busctl` fails due to a missing polkit rule, it automatically falls back to `sudo systemctl restart`, so the button works on both production and development environments

---

## [1.2.16] — 2026-05-27

### Added
- Support and contact email links in the Settings footer (visible from any settings tab):
  - `support@voxywatch.com` — technical support tickets
  - `contact@voxywatch.com` — commercial inquiries and licensing

---

## [1.2.15] — 2026-05-27

### Security
- **VULN-001** Stored XSS via `portal_title` — HTML special characters (`<>"'\``) are now stripped at save time; `escHtml()` applied at render time in the `<title>` tag
- **VULN-002** Mass-assignment bypass for `auth_enabled` — toggling this field via `POST /api/settings` now requires the admin's current password in `_confirm_password`
- **VULN-003** Auto-update without integrity verification — the tarball SHA-256 from the manifest is verified with `sha256sum` before extraction; updates without a valid 64-character hex hash are aborted
- **VULN-004** Router path traversal (`../` segments) — `path.posix.normalize()` middleware applied to every incoming URL before route matching
- **VULN-005** No rate limiting on login — in-memory rate limiter: max 10 failed attempts per IP per 15-minute window; counter resets on successful login; returns HTTP 429 with a wait hint
- **VULN-006** Sensitive data on unauthenticated endpoints — `/api/health` now returns only `{ok, license.valid, ts}`; `customer` field in `/api/license/status` is only included for authenticated callers
- **VULN-007** Excessive JWT session duration — `session_duration_hours` maximum capped at 168 h (7 days), down from 720 h (30 days)
- **VULN-008** `X-Powered-By: Express` header removed via `app.disable('x-powered-by')`

### Added
- `voxywatch.com/pricing` links throughout all license-related UI surfaces:
  - Blocked page — each error case (expired, HWID mismatch, invalid signature, no license)
  - Free Tier usage banner
  - Free Tier limit-reached overlay
  - Settings → License tab (load license section)
  - Settings → License tab (invalid license status card)

---

## [1.2.14] — 2026-05-27

### Fixed
- **Sniffer restart** — `POST /api/sniffer/restart` was returning HTTP 500 with *"sudo: The 'no new privileges' flag is set"*; replaced `sudo systemctl` with a `busctl` D-Bus call (`org.freedesktop.systemd1.Manager.RestartUnit`); polkit rule added in `postinst.sh` granting the `voxywatch` user permission to restart `voxywatch-sniffer.service`
- **PCAP / audio download** — files were downloaded as JSON because browser `<a download>` requests bypass the patched `fetch()` and send no `Authorization` header; replaced with a programmatic `_authDownload()` function using the patched `fetch()` so the JWT is always included
- **Call classification** — calls with a 200 OK but no BYE were incorrectly classified as "Completed"; they now appear as "Active" (`call_result = 'active'`); ASR/NER statistics still count active calls as answered
- **Calls list scroll reset** — the call list no longer appended a truncation message and scrolled down when changing filters; the list now scrolls to the top on every filter change
- **Diagnostics i18n** — the license status label "Válida" was always rendered in Spanish regardless of the selected UI language
- **systemd service documentation links** — `Documentation=` URL in both service files corrected to the GitHub repository

### Added
- `--reset-admin` CLI flag: stops the portal, resets all admin accounts to the default password (`voxywatch`), sets `force_change: true` so a new password is required on next login, then exits; no data is modified
- `GET /api/calls/active` — returns calls with `call_result = 'active'`; registered before `GET /api/calls/:id` to prevent the literal string `"active"` from being interpreted as a call ID
- `POST /api/auth/logout` — returns `{ok: true}` for stateless JWT clients; token invalidation is handled client-side
- polkit rule deployed by `postinst.sh` at `/etc/polkit-1/rules.d/50-voxywatch.rules`

### Changed
- `call_result` now uses six distinct values: `answered`, `active`, `busy`, `cancelled`, `failed`, `no-answer`
- Completed ES / EN translation keys for: CDR filter labels, pagination strings, sniffer status badges, default-password warning banner

---

## [1.2.8] — 2026-05-27

### Added
- **SQLite WAL backend** — `hep_capture.db` replaces the JSONL flat file; ~47 % storage reduction; concurrent-read safe; indices on `call_id`, `ts_sec`, `protocol_id`, `sender_ip`
- **Incremental parse** — `parseIncrementalCapture()` ingests only new rows (`id > _lastParsedMaxId`) without reloading the full database; full-parse is triggered only after purge events
- **Granular data wipe** — separate controls to delete audio files, SIP traces, or CDR records independently; CDR snapshot preserved on wipe
- **AI assistant** — built-in chat proxy supporting OpenAI, Anthropic Claude, Google Gemini, and OpenRouter; rate-limited to prevent API key abuse

### Security (43 issues resolved across two audit cycles)
- Command injection in PCAP export, audio serve, purge, and timezone handlers → `execFile()` / `execFileSync()` with separate argument arrays
- Path traversal in audio serving → `safeAudioPath()` validates that the resolved path is inside `__dirname` and has a `.wav` / `.g722` extension
- Race condition between parse and purge → `isParsing` lock prevents concurrent execution
- API key and admin password masked in `GET /api/settings` responses (`••••••••`)
- `express.static` blocked for `.jsonl`, `.json`, `.key` file extensions
- JWT `alg:none` attack rejected
- XSS: license banner fields escaped with `escHtml()`
- Security headers added: `Content-Security-Policy`, `X-Frame-Options: SAMEORIGIN`, `Referrer-Policy`, `X-XSS-Protection`, `Permissions-Policy`
- CSRF middleware: `Origin` / `Referer` validated against `Host` for all mutating methods
- TCP receive buffer capped at 10 MB per connection in the sniffer
- `/api/ai/chat` rate-limited (prevents runaway API costs)

---

## [1.2.7] — 2026-05-27

### Added
- **SSO / OIDC** — single sign-on via Google, Microsoft Entra ID, Okta, Keycloak, Auth0, and any standards-compliant provider; configurable from Settings → Security; optional auto-provisioning of new users with a default role; domain restriction filter
- **CDR base** — searchable, sortable, paginated call-detail records with caller/callee label resolution, duration, codec, MOS, and CSV export
- **Dashboard KPIs** — live ASR, NER, ACD, MOS, PDD cards with per-source and per-codec breakdown; 10-second cache to minimize recalculation

---

## [1.2.0] — 2026-05-26

### Initial public release

- HEP v1 / v2 / v3 capture sniffer (`hep_sniffer.py`) — UDP + TCP, ports 9060 / 9910 / 9911
- SIP flow viewer — full ladder diagram per call with SDP analysis and codec detection
- SIPREC stereo audio reconstruction (G.711 µ-law / G.722) with in-browser playback
- Per-call PCAP export (`generate_pcap.py`)
- Hardware-bound RSA license system (offline validation, no cloud call-home)
- JWT authentication with RBAC roles: `admin`, `operator`, `viewer`
- IP label directory — map IPs and CIDR prefixes to friendly names; CSV / JSON import/export
- Source tracking — groups HEP senders by source IP, shows active sources and packet counts
- Settings: disk auto-purge, HEP port configuration, HTTPS / TLS certificate upload, timezone, NTP, DNS
- Diagnostics page — system info, service status, license state, OS/Node/Python versions
- Dark theme UI; English and Spanish language support
- Compatible sources at launch: Asterisk, Kamailio, OpenSIPS, FreeSWITCH, RTPEngine, CaptAgent, HEPlify, Avaya SM, Oracle ACME, AudioCodes, Ribbon/Sonus, Cisco CUBE, custom SBCs
