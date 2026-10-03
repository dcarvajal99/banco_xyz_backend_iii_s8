#!/usr/bin/env bash
# Evidencia 04 - Proteccion de datos y servicios con OAuth 2.0: cada operacion exige su scope, los tokens se validan
# contra el JWK Set y, servicio a servicio, transferencias-service llega al core con un token client_credentials (sin
# clave Basic) mas su certificado. Requiere el ecosistema arriba (docker compose up -d).
set -uo pipefail
source "$(dirname "$0")/lib.sh"
if [ "${1:-}" = "-h" ]; then sed -n '2,4p' "$0"; exit 0; fi

titulo "Evidencia 04 · Protección de datos y servicios con OAuth 2.0" \
       "Criterio 1: scopes por operación, validación del token y client_credentials entre servicios."

paso "Scopes por operación: un token pedido solo con transferencias.leer consulta, pero no transfiere ni lee avisos"
token diana.prince "transferencias.leer"
nota "token de diana.prince con scope: $(python3 -c 'import sys,base64,json;c=sys.argv[1].split(".")[1];print(" ".join(json.loads(base64.urlsafe_b64decode(c+"="*(-len(c)%4)))["scope"]))' "$TOKEN")"
TRANSFERENCIA_ANTERIOR=$(sql "select id from transferencias.transferencia where cliente_id = $(sql "select cliente_id from core.usuario where usuario='diana.prince'") order by creada_en desc limit 1")
SIN_CUERPO=2 llamar GET "$TRANSFERENCIAS/api/v1/transferencias/$TRANSFERENCIA_ANTERIOR" "${BEARER[@]}"
esperar 200
SIN_CUERPO=2 llamar POST "$TRANSFERENCIAS/api/v1/transferencias" "${BEARER[@]}" "${JSON[@]}" -H "Idempotency-Key: $(uuid)" \
  --data-raw '{"cuentaOrigen":101,"cuentaDestino":131,"monto":100}'
esperar 403
comprobar "motivo del rechazo" "$(encabezado www-authenticate | grep -o 'error="[a-z_]*"')" 'error="insufficient_scope"'
SIN_CUERPO=2 llamar GET "$NOTIFICACIONES/api/v1/notificaciones" "${BEARER[@]}"
esperar 403

paso "Sin token, con la firma alterada o con alg=none: 401 en transferencias-service"
token diana.prince
SIN_CUERPO=2 llamar GET "$TRANSFERENCIAS/api/v1/transferencias/$TRANSFERENCIA_ANTERIOR"
esperar 401
ALTERADO=$(python3 - "$TOKEN" <<'PY'
import base64, json, sys
h, c, f = sys.argv[1].split(".")
d = json.loads(base64.urlsafe_b64decode(c + "=" * (-len(c) % 4)))
d["cliente_id"] = 6  # se hace pasar por otro cliente
print(h + "." + base64.urlsafe_b64encode(json.dumps(d).encode()).decode().rstrip("=") + "." + f)
PY
)
SIN_FIRMA=$(python3 -c 'import sys,base64;c=sys.argv[1].split(".")[1];print(base64.urlsafe_b64encode(b"{\"alg\":\"none\"}").decode().rstrip("=")+"."+c+".")' "$TOKEN")
comprobar "token con cliente_id cambiado" "$(curl -s -o /dev/null -w '%{http_code}' "${TLS[@]}" -H "Authorization: Bearer $ALTERADO" "$TRANSFERENCIAS/api/v1/transferencias/$TRANSFERENCIA_ANTERIOR")" "401"
comprobar "token sin firma (alg=none)" "$(curl -s -o /dev/null -w '%{http_code}' "${TLS[@]}" -H "Authorization: Bearer $SIN_FIRMA" "$TRANSFERENCIAS/api/v1/transferencias/$TRANSFERENCIA_ANTERIOR")" "401"

paso "Servicio a servicio: transferencias-service pide su token con client_credentials (sin usuario) para leer el core"
SIN_CUERPO=2 llamar POST "$AUTH/oauth2/token" -u "transferencias-service:$SECRETO_TRANSFERENCIAS" -d grant_type=client_credentials \
  -d scope=core.cuentas.leer
esperar 200
TOKEN_SERVICIO=$(campo access_token)
claims_jwt "$TOKEN_SERVICIO"
comprobar "sujeto del token: el cliente, no un usuario" "$(python3 -c 'import sys,base64,json;c=sys.argv[1].split(".")[1];d=json.loads(base64.urlsafe_b64decode(c+"="*(-len(c)%4)));print(d["sub"], "usuario_id" in d)' "$TOKEN_SERVICIO")" "transferencias-service False"

paso "El core (no publicado: se llama dentro de la red) acepta ese token junto al certificado de transferencias-service"
DIANA=$(sql "select id from core.usuario where usuario='diana.prince'")
llamar_interno GET "$CORE_INTERNO/api/v1/cuentas/101" -H "Authorization: Bearer $TOKEN_SERVICIO" -H "X-Usuario-Id: $DIANA" \
  --cert /certificados/servicios/transferencias-service.crt --key /certificados/servicios/transferencias-service.key
esperar 200
comprobar "cuenta leída" "$(campo cuentaId)" "101"

paso "El core rechaza: la antigua clave Basic (401), un token de usuario (403), sin certificado (401) y el certificado de otro servicio (403)"
SIN_CUERPO=2 llamar_interno GET "$CORE_INTERNO/api/v1/cuentas/101" -u "transferencias-service:transferencias-secreto-dev" \
  -H "X-Usuario-Id: $DIANA" --cert /certificados/servicios/transferencias-service.crt --key /certificados/servicios/transferencias-service.key
esperar 401
SIN_CUERPO=2 llamar_interno GET "$CORE_INTERNO/api/v1/cuentas/101" -H "Authorization: Bearer $TOKEN" -H "X-Usuario-Id: $DIANA" \
  --cert /certificados/servicios/transferencias-service.crt --key /certificados/servicios/transferencias-service.key
esperar 403
SIN_CUERPO=2 llamar_interno GET "$CORE_INTERNO/api/v1/cuentas/101" -H "Authorization: Bearer $TOKEN_SERVICIO" -H "X-Usuario-Id: $DIANA"
esperar 401 CERTIFICADO_REQUERIDO
SIN_CUERPO=2 llamar_interno GET "$CORE_INTERNO/api/v1/cuentas/101" -H "Authorization: Bearer $TOKEN_SERVICIO" -H "X-Usuario-Id: $DIANA" \
  --cert /certificados/servicios/antifraude-service.crt --key /certificados/servicios/antifraude-service.key
esperar 403 CERTIFICADO_NO_CORRESPONDE

paso "Operación protegida: el actuator es de solo lectura y las claves de firma no se ven ni se tocan sin token"
nota "en contenedores el puerto de operación escucha en la red interna: cualquier contenedor de la red llega a él"
SIN_CUERPO=2 llamar POST "$OP_TRANSFERENCIAS/actuator/circuitbreakers/core" "${JSON[@]}" --data-raw '{"updateState":"FORCE_OPEN"}'
esperar 401
SIN_CUERPO=2 llamar POST "$OP_AUTH/actuator/circuitbreakers/core" "${JSON[@]}" --data-raw '{"updateState":"FORCE_OPEN"}'
esperar 401
SIN_CUERPO=2 llamar_interno GET "http://banco-auth:9081/actuator/claves"
esperar 401
comprobar "circuito core de transferencias-service sin cambios" "$(circuito 9082 core)" "CLOSED"
comprobar "circuito core de banco-auth sin cambios" "$(circuito 9081 core)" "CLOSED"
nota "listar, rotar o retirar claves exige el token de operacion-banco con claves.administrar (evidencia 05)"

paso "Cada cliente solo obtiene sus scopes y con su secreto"
comprobar "banca-web pidiendo core.cuentas.leer" "$(python3 -c 'import sys,urllib.parse as u;print(u.parse_qs(u.urlparse(sys.argv[1]).query).get("error",[""])[0])' \
  "$(curl -s -o /dev/null -w '%{redirect_url}' "${TLS[@]}" -b <(printf '') -G "$AUTH/oauth2/authorize" --data-urlencode response_type=code \
     --data-urlencode client_id=banca-web --data-urlencode "redirect_uri=$REDIRECCION" --data-urlencode scope=core.cuentas.leer \
     --data-urlencode code_challenge=abc --data-urlencode code_challenge_method=S256)")" "invalid_scope"
SIN_CUERPO=2 llamar POST "$AUTH/oauth2/token" -u "transferencias-service:$SECRETO_TRANSFERENCIAS" -d grant_type=client_credentials \
  -d scope=transferencias.escribir
esperar 400
comprobar "transferencias-service pidiendo un scope de usuario" "$(campo error)" "invalid_scope"
SIN_CUERPO=2 llamar POST "$AUTH/oauth2/token" -u "transferencias-service:secreto-equivocado" -d grant_type=client_credentials \
  -d scope=core.cuentas.leer
esperar 401
comprobar "secreto equivocado" "$(campo error)" "invalid_client"

resumen_final
