#!/usr/bin/env bash
# Funciones comunes de los scripts de demostracion del Banco XYZ (semana 8: ecosistema en contenedores).
# Imprimen cada solicitud y su respuesta de forma legible para las capturas de evidencia.
# Uso: source "$(dirname "$0")/lib.sh"
#
# Todo corre en el docker-compose.yaml de la raiz. Desde el equipo solo se alcanzan los puertos que el compose publica
# en 127.0.0.1; lo interno (el core, la base, Kafka) se consulta dentro de la red del compose. Cada llamada HTTPS valida
# el certificado contra la CA del banco (--cacert, nunca -k).

RAIZ_PROYECTO="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
RAIZ_REPO="$(cd "$RAIZ_PROYECTO/.." && pwd)"
COMPOSE=(docker compose --project-directory "$RAIZ_REPO" -f "$RAIZ_REPO/docker-compose.yaml")
# Copia local de la CA y de algunos certificados (para curl desde el equipo); la PKI vive en el volumen del compose.
CERTS="${BANCO_CERTIFICADOS:-$RAIZ_PROYECTO/certificados}"
RED="banco-xyz"
VOLUMEN_CERTIFICADOS="banco-xyz_certificados"
IMAGEN_CURL="curlimages/curl:8.11.1"
IMAGEN_KAFKA="apache/kafka:3.9.1"
# Herramientas de consola de Kafka en un contenedor propio y efimero de la red del compose, nunca dentro del broker: ahi
# comparten su limite de memoria, y cada una hereda el heap de 384 MB del broker (KAFKA_HEAP_OPTS). Cuatro lecturas en
# paralelo dejaban al broker sin memoria (lo mataba el OOM killer y Docker lo reiniciaba).
KAFKA_CLI=(docker run --rm --network "$RED" -e KAFKA_HEAP_OPTS="-Xms32m -Xmx128m" "$IMAGEN_KAFKA")
KAFKA_CLI_ENTRADA=(docker run --rm -i --network "$RED" -e KAFKA_HEAP_OPTS="-Xms32m -Xmx128m" "$IMAGEN_KAFKA")

CONFIG="https://localhost:8888"
EUREKA1="http://127.0.0.1:8761"
EUREKA2="http://127.0.0.1:8762"
AUTH="https://localhost:8081"
TRANSFERENCIAS="https://localhost:8082"
NOTIFICACIONES="https://localhost:8084"
CORE_INTERNO="https://banco-core-api:8080"
OP_CORE="http://127.0.0.1:9080"
OP_AUTH="http://127.0.0.1:9081"
OP_TRANSFERENCIAS="http://127.0.0.1:9082"
OP_NOTIFICACIONES="http://127.0.0.1:9084"
CLAVE_CLIENTES="${BANCO_CLAVE_CLIENTES:-Cliente2026!}"
SECRETO_BANCA_WEB="${BANCO_OAUTH_BANCA_WEB_SECRETO:-banca-web-secreto-dev}"
SECRETO_TRANSFERENCIAS="${BANCO_OAUTH_TRANSFERENCIAS_SECRETO:-transferencias-oauth-dev}"
SECRETO_OPERACION="${BANCO_OAUTH_OPERACION_SECRETO:-operacion-secreto-dev}"
REDIRECCION="http://127.0.0.1:8099/callback"
JSON=(-H "Content-Type: application/json")

# obtener_certificados: copia la PKI del volumen del compose a la carpeta local (la regenera la imagen pki).
obtener_certificados() {
  mkdir -p "$CERTS"
  "${COMPOSE[@]}" cp pki:/certificados/. "$CERTS/" > /dev/null 2>&1
}
[ -f "$CERTS/ca/ca.crt" ] || obtener_certificados
TLS=(--cacert "$CERTS/ca/ca.crt")

if [ -n "${NO_COLOR:-}" ]; then
  C_TIT=""; C_OK=""; C_ERR=""; C_DIM=""; C_B=""; C_AMA=""; C_0=""
else
  C_TIT=$'\033[1;36m'; C_OK=$'\033[1;32m'; C_ERR=$'\033[1;31m'; C_DIM=$'\033[2m'; C_B=$'\033[1m'; C_AMA=$'\033[1;33m'; C_0=$'\033[0m'
fi

OK=0
FALLAS=0

# titulo "Evidencia N - descripcion" "Criterio de la pauta que demuestra"
titulo() {
  printf '\n%s══════ %s ══════%s\n' "$C_TIT" "$1" "$C_0"
  if [ -n "${2:-}" ]; then printf '%s%s%s\n' "$C_DIM" "$2" "$C_0"; fi
}

# paso "Que se va a probar"
paso() {
  printf '\n%s▶ %s%s\n' "$C_AMA" "$1" "$C_0"
}

# nota "texto": aclaracion en gris.
nota() {
  printf '  %s%s%s\n' "$C_DIM" "$1" "$C_0"
}

# certificado RUTA: deja en CERT los argumentos de curl para presentar ese certificado de cliente
# (p. ej. servicios/banco-core-api). Arreglo y no texto: la ruta del proyecto tiene espacios.
certificado() {
  CERT=(--cert "$CERTS/$1.crt" --key "$CERTS/$1.key")
}

# dato_visible CLAVE=VALOR: el parametro de formulario como se muestra en pantalla (clave oculta, tokens recortados).
dato_visible() {
  local nombre="${1%%=*}" valor="${1#*=}"
  case "$nombre" in
    password) printf '%s=••••' "$nombre" ;;
    code|code_verifier|refresh_token|_csrf|token) printf '%s=%s…' "$nombre" "${valor:0:12}" ;;
    *) printf '%s' "$1" ;;
  esac
}

# llamar METODO URL [argumentos de curl...]
# SIN_CUERPO=1 no imprime el cuerpo (avisa que lo omite); SIN_CUERPO=2 no imprime ni el aviso.
# Deja el status en ESTADO, el cuerpo en CUERPO, los encabezados en CABECERAS y la version HTTP en VERSION_HTTP.
# Un fallo de TLS (certificado rechazado, protocolo no permitido) deja ESTADO=000 y curl explica el motivo.
llamar() {
  local metodo="$1" url="$2"
  shift 2
  local cabeceras cuerpo resultado resto
  cabeceras=$(mktemp)
  cuerpo=$(mktemp)
  printf '%s%s %s%s\n' "$C_B" "$metodo" "$url" "$C_0"
  local previo=""
  for arg in "$@"; do
    case "$previo" in
      -H)
        case "$arg" in
          Authorization:\ Bearer*) printf '  %s%s…%s\n' "$C_DIM" "${arg:0:40}" "$C_0" ;;
          Content-Type:*) ;;
          *) printf '  %s%s%s\n' "$C_DIM" "$arg" "$C_0" ;;
        esac ;;
      --data-raw) printf '  %s%s%s\n' "$C_DIM" "$arg" "$C_0" ;;
      -d|--data-urlencode) printf '  %s%s%s\n' "$C_DIM" "$(dato_visible "$arg")" "$C_0" ;;
      -u) printf '  %sBasic %s:••••%s\n' "$C_DIM" "${arg%%:*}" "$C_0" ;;
      --cert) printf '  %scertificado de cliente (mTLS): %s%s\n' "$C_DIM" "${arg#"$CERTS"/}" "$C_0" ;;
    esac
    previo="$arg"
  done
  resultado=$(curl -sS -o "$cuerpo" -D "$cabeceras" -w '%{http_code} %{size_download} %{http_version}' -X "$metodo" \
    "${TLS[@]}" "$@" "$url" 2> "$cuerpo.err" || echo "000 0 -")
  ESTADO="${resultado%% *}"
  resto="${resultado#* }"
  VERSION_HTTP="${resto##* }"
  CUERPO=$(cat "$cuerpo")
  CABECERAS=$(cat "$cabeceras")
  local color="$C_OK"
  case "$ESTADO" in 4*|5*|000) color="$C_ERR" ;; esac
  if [ "$ESTADO" = "000" ]; then
    printf '%sSin respuesta HTTP: %s%s\n' "$color" "$(tr -d '\r' < "$cuerpo.err" | head -1)" "$C_0"
  else
    printf '%sHTTP/%s %s%s\n' "$color" "$VERSION_HTTP" "$ESTADO" "$C_0"
  fi
  grep -iE '^(location|idempotency-replayed|www-authenticate):' "$cabeceras" | tr -d '\r' | sed 's/^/  /' || true
  if [ -s "$cuerpo" ] && [ -z "${SIN_CUERPO:-}" ]; then
    python3 -m json.tool --no-ensure-ascii < "$cuerpo" 2>/dev/null || head -c 400 "$cuerpo"
    printf '\n'
  elif [ -s "$cuerpo" ] && [ "$SIN_CUERPO" != "2" ]; then
    printf '  %s(cuerpo omitido en pantalla)%s\n' "$C_DIM" "$C_0"
  fi
  rm -f "$cabeceras" "$cuerpo" "$cuerpo.err"
}

# llamar_interno METODO URL [argumentos de curl...]: como llamar, pero desde un contenedor de curl conectado a la red
# del compose, con el volumen de certificados (rutas /certificados/...). Para lo que no se publica fuera, como el core.
llamar_interno() {
  local metodo="$1" url="$2"
  shift 2
  local salida
  printf '%s%s %s%s %s(desde la red interna del compose)%s\n' "$C_B" "$metodo" "$url" "$C_0" "$C_DIM" "$C_0"
  local previo=""
  for arg in "$@"; do
    case "$previo" in
      -H) case "$arg" in Authorization:\ Bearer*) printf '  %s%s…%s\n' "$C_DIM" "${arg:0:40}" "$C_0" ;; *) printf '  %s%s%s\n' "$C_DIM" "$arg" "$C_0" ;; esac ;;
      -u) printf '  %sBasic %s:••••%s\n' "$C_DIM" "${arg%%:*}" "$C_0" ;;
      --cert) printf '  %scertificado de cliente (mTLS): %s%s\n' "$C_DIM" "${arg#/certificados/}" "$C_0" ;;
    esac
    previo="$arg"
  done
  salida=$(docker run --rm --network "$RED" --user 10001 -v "$VOLUMEN_CERTIFICADOS:/certificados:ro" "$IMAGEN_CURL" \
    -sS -i -w '\n@@ESTADO %{http_code} %{http_version}' -X "$metodo" --cacert /certificados/ca/ca.crt "$@" "$url" 2>&1)
  ESTADO=$(printf '%s' "$salida" | sed -n 's/^@@ESTADO \([0-9]*\) .*/\1/p' | tail -1)
  VERSION_HTTP=$(printf '%s' "$salida" | sed -n 's/^@@ESTADO [0-9]* \(.*\)/\1/p' | tail -1)
  CABECERAS=$(printf '%s' "$salida" | sed '/^@@ESTADO/d' | awk 'BEGIN{c=1} /^\r?$/{if(c){c=0; next}} c')
  CUERPO=$(printf '%s' "$salida" | sed '/^@@ESTADO/d' | awk 'BEGIN{c=1} /^\r?$/{if(c){c=0; next}} !c')
  [ -n "$ESTADO" ] || ESTADO=000
  local color="$C_OK"
  case "$ESTADO" in 4*|5*|000) color="$C_ERR" ;; esac
  if [ "$ESTADO" = "000" ]; then
    printf '%sSin respuesta HTTP: %s%s\n' "$color" "$(printf '%s' "$salida" | grep -m1 'curl:')" "$C_0"
  else
    printf '%sHTTP/%s %s%s\n' "$color" "$VERSION_HTTP" "$ESTADO" "$C_0"
  fi
  if [ -n "$CUERPO" ] && [ -z "${SIN_CUERPO:-}" ]; then
    printf '%s' "$CUERPO" | python3 -m json.tool --no-ensure-ascii 2>/dev/null || printf '%s\n' "${CUERPO:0:400}"
  fi
}

# esperar STATUS [CODIGO]: compara el ultimo status (y el campo codigo si se indica).
esperar() {
  local esperado="$1" codigo="${2:-}"
  local recibido_codigo=""
  if [ -n "$codigo" ]; then recibido_codigo=$(campo codigo); fi
  if [ "$ESTADO" = "$esperado" ] && { [ -z "$codigo" ] || [ "$recibido_codigo" = "$codigo" ]; }; then
    printf '%s✔ esperado %s %s%s\n' "$C_OK" "$esperado" "$codigo" "$C_0"
    OK=$((OK + 1))
  else
    printf '%s✘ esperado %s %s, recibido %s %s%s\n' "$C_ERR" "$esperado" "$codigo" "$ESTADO" "$recibido_codigo" "$C_0"
    FALLAS=$((FALLAS + 1))
  fi
}

# comprobar "que se verifica" OBTENIDO ESPERADO
comprobar() {
  if [ "$2" = "$3" ]; then
    printf '%s✔ %s: %s%s\n' "$C_OK" "$1" "$2" "$C_0"
    OK=$((OK + 1))
  else
    printf '%s✘ %s: obtenido "%s", esperado "%s"%s\n' "$C_ERR" "$1" "$2" "$3" "$C_0"
    FALLAS=$((FALLAS + 1))
  fi
}

# encabezado NOMBRE: valor de un encabezado de la ultima respuesta (vacio si no vino).
encabezado() {
  printf '%s\n' "$CABECERAS" | tr -d '\r' | awk -v n="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" \
    'BEGIN{FS=": "} tolower($1)==n {sub(/^[^:]*: /, ""); print; exit}'
}

# campo RUTA [JSON]: lee un campo del ultimo cuerpo JSON (o del JSON indicado) con ruta a.b.0.c. Vacio si no existe.
campo() {
  python3 - "$1" "${2:-$CUERPO}" <<'PY'
import json, sys
ruta, texto = sys.argv[1], sys.argv[2]
try:
    valor = json.loads(texto)
    for parte in ruta.split('.'):
        valor = valor[int(parte)] if isinstance(valor, list) else valor[parte]
    print(valor if not isinstance(valor, (dict, list)) else json.dumps(valor, ensure_ascii=False))
except Exception:
    print('')
PY
}

uuid() {
  python3 -c 'import uuid; print(uuid.uuid4())'
}

# token USUARIO [SCOPES]: flujo OAuth 2.0 authorization_code + PKCE completo, como lo haria la banca en linea:
#   1) /oauth2/authorize sin sesion -> el servidor de autorizacion pide login; 2) formulario de login (con su token CSRF);
#   3) vuelve a /oauth2/authorize con sesion -> redireccion al cliente con el codigo; 4) /oauth2/token con el codigo y el
#   code_verifier. Deja TOKEN (access token), REFRESCO, ID_TOKEN, KID y BEARER. Sin salida en pantalla.
token() {
  local usuario="$1" scopes="${2:-openid transferencias.escribir transferencias.leer notificaciones.leer}"
  local jar verificador desafio csrf destino codigo respuesta
  jar=$(mktemp)
  verificador=$(python3 -c 'import secrets,base64;print(base64.urlsafe_b64encode(secrets.token_bytes(32)).rstrip(b"=").decode())')
  desafio=$(python3 -c 'import hashlib,base64,sys;print(base64.urlsafe_b64encode(hashlib.sha256(sys.argv[1].encode()).digest()).rstrip(b"=").decode())' "$verificador")
  curl -s -o /dev/null -c "$jar" -b "$jar" "${TLS[@]}" -G "$AUTH/oauth2/authorize" -H "Accept: text/html" \
    --data-urlencode "response_type=code" --data-urlencode "client_id=banca-web" --data-urlencode "redirect_uri=$REDIRECCION" \
    --data-urlencode "scope=$scopes" --data-urlencode "state=estado-$RANDOM" \
    --data-urlencode "code_challenge=$desafio" --data-urlencode "code_challenge_method=S256"
  csrf=$(curl -s -c "$jar" -b "$jar" "${TLS[@]}" "$AUTH/login" | sed -n 's/.*name="_csrf" value="\([^"]*\)".*/\1/p')
  destino=$(curl -s -o /dev/null -w '%{redirect_url}' -c "$jar" -b "$jar" "${TLS[@]}" "$AUTH/login" \
    --data-urlencode "username=$usuario" --data-urlencode "password=$CLAVE_CLIENTES" --data-urlencode "_csrf=$csrf")
  destino=$(curl -s -o /dev/null -w '%{redirect_url}' -c "$jar" -b "$jar" "${TLS[@]}" "$destino")
  codigo=$(python3 -c 'import sys,urllib.parse as u;print((u.parse_qs(u.urlparse(sys.argv[1]).query).get("code") or [""])[0])' "$destino")
  rm -f "$jar"
  respuesta=$(curl -s "${TLS[@]}" -u "banca-web:$SECRETO_BANCA_WEB" "$AUTH/oauth2/token" -d grant_type=authorization_code \
    --data-urlencode "code=$codigo" --data-urlencode "redirect_uri=$REDIRECCION" --data-urlencode "code_verifier=$verificador")
  TOKEN=$(campo access_token "$respuesta")
  REFRESCO=$(campo refresh_token "$respuesta")
  ID_TOKEN=$(campo id_token "$respuesta")
  KID=$(python3 -c 'import sys,base64,json;h=sys.argv[1].split(".")[0];print(json.loads(base64.urlsafe_b64decode(h+"="*(-len(h)%4))).get("kid",""))' "$TOKEN" 2>/dev/null)
  BEARER=(-H "Authorization: Bearer $TOKEN")
  [ -n "$TOKEN" ] || { printf '%sNo se obtuvo token para %s: %s%s\n' "$C_ERR" "$usuario" "$respuesta" "$C_0"; return 1; }
}

# token_servicio CLIENTE SECRETO SCOPE: flujo client_credentials (servicio a servicio). Deja TOKEN_SERVICIO.
token_servicio() {
  local respuesta
  respuesta=$(curl -s "${TLS[@]}" -u "$1:$2" "$AUTH/oauth2/token" -d grant_type=client_credentials --data-urlencode "scope=$3")
  TOKEN_SERVICIO=$(campo access_token "$respuesta")
}

# claims_jwt TOKEN: encabezado y claims de un JWT, en dos lineas (la firma no se muestra).
claims_jwt() {
  python3 - "$1" <<'PY'
import base64, json, sys
partes = sys.argv[1].split(".")
dec = lambda s: json.loads(base64.urlsafe_b64decode(s + "=" * (-len(s) % 4)))
print("  encabezado: " + json.dumps(dec(partes[0]), ensure_ascii=False))
claims = dec(partes[1])
for k in ("iat", "nbf", "jti", "sid", "auth_time", "azp", "at_hash"):
    claims.pop(k, None)
print("  claims:     " + json.dumps(claims, ensure_ascii=False))
PY
}

# transferencia_breve: resume la transferencia del ultimo cuerpo en pocas lineas (estado, cuentas, historial).
transferencia_breve() {
  python3 - "$CUERPO" <<'PY'
import json, sys
try:
    t = json.loads(sys.argv[1], parse_float=str)
except ValueError:
    sys.exit(0)
print("  id %s · estado %s · validacion %s · %s → %s · $%s" % (t.get("id"), t.get("estado"), t.get("validacion"),
      t.get("cuentaOrigen"), t.get("cuentaDestino"), t.get("monto")))
def hora(texto):
    hms, _, fraccion = texto[11:].partition(".")
    return "%s.%s" % (hms, (fraccion + "000")[:3])
for i, h in enumerate(t.get("historial", [])):
    print("  %s %s %-24s %s" % ("historial:" if i == 0 else "          ", hora(h["ocurridoEn"]), h["evento"], h.get("detalle") or ""))
PY
}

# transferir ORIGEN DESTINO MONTO [CLAVE_IDEMPOTENCIA]: POST a transferencias-service con el TOKEN vigente.
# Muestra la respuesta resumida (COMPLETO=1 la muestra entera) y deja el id en TRANSFERENCIA (vacio si no se acepto).
transferir() {
  local clave="${4:-$(uuid)}"
  if [ -n "${COMPLETO:-}" ]; then
    llamar POST "$TRANSFERENCIAS/api/v1/transferencias" "${BEARER[@]}" "${JSON[@]}" -H "Idempotency-Key: $clave" \
      --data-raw "{\"cuentaOrigen\":$1,\"cuentaDestino\":$2,\"monto\":$3}"
  else
    SIN_CUERPO=2 llamar POST "$TRANSFERENCIAS/api/v1/transferencias" "${BEARER[@]}" "${JSON[@]}" \
      -H "Idempotency-Key: $clave" --data-raw "{\"cuentaOrigen\":$1,\"cuentaDestino\":$2,\"monto\":$3}"
    case "$ESTADO" in
      2*) transferencia_breve ;;
      *) printf '%s\n' "$CUERPO" | python3 -m json.tool --no-ensure-ascii 2>/dev/null | sed 's/^/  /' ;;
    esac
  fi
  TRANSFERENCIA=$(campo id)
}

# seguir_transferencia ID [SEGUNDOS]: consulta la transferencia hasta que llegue a COMPLETADA o RECHAZADA y muestra
# el resultado resumido con su historial. Deja el estado final en ESTADO_TRANSFERENCIA.
seguir_transferencia() {
  local id="$1" limite="${2:-30}" respuesta=""
  ESTADO_TRANSFERENCIA=""
  for _ in $(seq 1 $((limite * 2))); do
    respuesta=$(curl -sS "${TLS[@]}" "${BEARER[@]}" "$TRANSFERENCIAS/api/v1/transferencias/$id")
    ESTADO_TRANSFERENCIA=$(campo estado "$respuesta")
    case "$ESTADO_TRANSFERENCIA" in COMPLETADA|RECHAZADA) break ;; esac
    sleep 0.5
  done
  SIN_CUERPO=2 llamar GET "$TRANSFERENCIAS/api/v1/transferencias/$id" "${BEARER[@]}"
  transferencia_breve
}

# sql "consulta": ejecuta en la base de la semana 7 y devuelve filas sin formato (columnas separadas por |).
sql() {
  "${COMPOSE[@]}" exec -T db psql -U banco -d banco_xyz -tAc "$1"
}

# tabla_sql "consulta": igual que sql, con encabezados y columnas alineadas para la captura.
tabla_sql() {
  "${COMPOSE[@]}" exec -T db psql -U banco -d banco_xyz -P footer=off -c "$1" | sed 's/^/  /'
}

saldo() {
  sql "select saldo_disponible from core.cuenta where id = $1"
}

# circuito PUERTO_OPERACION NOMBRE: estado del circuit breaker de Resilience4j (CLOSED, OPEN, HALF_OPEN).
circuito() {
  curl -s "http://127.0.0.1:$1/actuator/circuitbreakers" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['circuitBreakers']['$2']['state'])" 2>/dev/null
}

# mostrar_circuito PUERTO_OPERACION NOMBRE [SERVICIO]: estado y metricas del circuito, en una linea.
mostrar_circuito() {
  curl -s "http://127.0.0.1:$1/actuator/circuitbreakers" | python3 -c "
import sys, json
c = json.load(sys.stdin)['circuitBreakers']['$2']
print('  %-22s circuito %-5s estado=%-9s tasa_de_fallas=%-6s fallidas=%s no_permitidas=%s' % ('${3:-}', '$2', c['state'],
      c['failureRate'], c['failedCalls'], c['notPermittedCalls']))"
}

# eventos_circuito PUERTO_OPERACION NOMBRE [N]: ultimos N eventos del circuito (actuator/circuitbreakerevents).
eventos_circuito() {
  curl -s "http://127.0.0.1:$1/actuator/circuitbreakerevents/$2" | python3 -c "
import sys, json
eventos = json.load(sys.stdin)['circuitBreakerEvents'][-${3:-8}:]
for e in eventos:
    detalle = e.get('stateTransition') or (e.get('errorMessage') or '')
    print('  %s %-22s %s' % (e['creationTime'][11:23], e['type'], detalle[:88]))"
}

# en_contenedor CONTENEDOR URL: GET a un endpoint de operacion desde dentro del contenedor (wget de la imagen).
en_contenedor() {
  docker exec "$1" wget -qO- "$2" 2>/dev/null
}

# kafka_topicos ARGUMENTOS: kafka-topics.sh dentro del contenedor de Kafka.
kafka_topicos() {
  "${KAFKA_CLI[@]}" /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 "$@"
}

# grupo_consumidor GRUPO...: por cada particion, que consumidor la tiene, hasta donde leyo (OFFSET), cuantos mensajes
# tiene el topico (FIN) y cuantos le faltan (LAG). Resume la salida de kafka-consumer-groups.sh --describe.
grupo_consumidor() {
  local grupo
  for grupo in "$@"; do
    "${KAFKA_CLI[@]}" /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server kafka:9092 \
      --describe --group "$grupo" 2>/dev/null
  done | python3 -c '
import sys
filas = []
for linea in sys.stdin:
    c = linea.split()
    if len(c) >= 9 and c[0] != "GROUP" and c[2].isdigit():
        cliente = c[8] if c[8] != "-" else "(sin consumidor)"
        filas.append((c[0], c[1], int(c[2]), c[3], c[4], c[5], cliente.replace("consumer-", "")))
filas.sort()
print("  %-22s %-27s %-4s %-6s %-5s %-4s %s" % ("GRUPO", "TOPICO", "PART", "OFFSET", "FIN", "LAG", "CONSUMIDOR"))
for f in filas:
    print("  %-22s %-27s %-4s %-6s %-5s %-4s %s" % f)'
}

# publicar_crudo TOPICO CLAVE MENSAJE: escribe un mensaje tal cual en un topico (para simular duplicados o basura).
publicar_crudo() {
  printf '%s|%s\n' "$2" "$3" | "${KAFKA_CLI_ENTRADA[@]}" /opt/kafka/bin/kafka-console-producer.sh \
    --bootstrap-server kafka:9092 --topic "$1" --property parse.key=true --property key.separator='|' 2>/dev/null
}

# leer_topico TOPICO [SEGUNDOS]: todos los mensajes del topico desde el principio, con particion, offset y clave.
leer_topico() {
  "${KAFKA_CLI[@]}" /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 \
    --topic "$1" --from-beginning --timeout-ms "$(( ${2:-4} * 1000 ))" --property print.partition=true \
    --property print.offset=true --property print.key=true 2>/dev/null
}

# eventos_de_transferencia ID: los eventos de esa transferencia en los cuatro topicos de la saga, en orden de
# ocurrencia, con topico, particion, offset y clave. Lee cada topico desde el principio, sin grupo propio.
eventos_de_transferencia() {
  local id="$1" dir topico
  dir=$(mktemp -d)
  for topico in transferencias.solicitadas cuentas.reservas antifraude.decisiones cuentas.transferencias; do
    leer_topico "$topico" > "$dir/$topico" &
  done
  wait
  python3 - "$id" "$dir" <<'PY'
import json, os, re, sys
buscado, carpeta = sys.argv[1], sys.argv[2]
filas = []
for topico in os.listdir(carpeta):
    for linea in open(os.path.join(carpeta, topico), encoding="utf-8"):
        m = re.match(r"Partition:(\d+)\tOffset:(\d+)\t(\S*)\t(.*)$", linea.rstrip("\n"))
        if not m:
            continue
        try:
            evento = json.loads(m[4], parse_float=str)
        except ValueError:
            continue
        if evento.get("transferenciaId") == buscado:
            filas.append((evento.get("ocurridoEn", ""), topico, int(m[1]), int(m[2]), m[3], evento))
filas.sort(key=lambda f: (f[0], f[3]))
print("  %-24s %-27s %-4s %-6s %-6s %s" % ("EVENTO", "TOPICO", "PART", "OFFSET", "CLAVE", "DATOS"))
for _, topico, particion, offset, clave, e in filas:
    datos = ["%s=%s" % (c, e[c]) for c in ("monto", "validacion", "motivo", "saldoOrigen") if e.get(c) is not None]
    print("  %-24s %-27s %-4s %-6s %-6s %s" % (e.get("tipo"), topico, particion, offset, clave, " ".join(datos)))
print("  (%d eventos con transferenciaId %s)" % (len(filas), buscado))
PY
  rm -rf "$dir"
}

resumen_final() {
  printf '\n%s── Resultado: %s verificaciones correctas, %s fallas ──%s\n' "$C_B" "$OK" "$FALLAS" "$C_0"
  [ "$FALLAS" -eq 0 ]
}
