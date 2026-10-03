#!/usr/bin/env bash
# Evidencia 05 - Observacion 4 de la semana 6 con OAuth 2.0: los tokens del servidor de autorizacion se firman con
# claves RSA (RS256) que rotan, publicadas como JWK Set (/oauth2/jwks).
# banco-auth firma con la clave privada; transferencias-service y notificaciones-service validan con las claves publicas
# del JWK Set. Se rota la clave, el token anterior sigue valido en su periodo de gracia y deja de valer al retirarla.
# Rotar y retirar exige un token client_credentials del cliente operacion-banco (scope claves.administrar).
# Requiere el ecosistema arriba (docker compose up -d). Tarda unos 45 s (espera la cache del JWK Set).
set -uo pipefail
source "$(dirname "$0")/lib.sh"
if [ "${1:-}" = "-h" ]; then sed -n '2,5p' "$0"; exit 0; fi

# partes_jwt TOKEN: encabezado y claims decodificados (la firma no se muestra).
partes_jwt() {
  python3 - "$1" <<'PY'
import base64, json, sys
def parte(texto):
    return json.loads(base64.urlsafe_b64decode(texto + "=" * (-len(texto) % 4)))
cabecera, claims, firma = sys.argv[1].split(".")
print("  encabezado: " + json.dumps(parte(cabecera), ensure_ascii=False))
c = parte(claims)
print("  claims:     " + json.dumps({k: c[k] for k in ("iss", "aud", "sub", "usuario_id", "cliente_id", "rol", "scope") if k in c}, ensure_ascii=False))
print("  vigencia:   exp - iat = %d s · firma: %d bytes (RSA 2048)" % (c["exp"] - c["iat"], len(base64.urlsafe_b64decode(firma + "=" * (-len(firma) % 4)))))
PY
}

# estado_con TOKEN [URL]: status HTTP de una consulta protegida con ese token.
estado_con() {
  curl -s -o /dev/null -w '%{http_code}' "${TLS[@]}" -H "Authorization: Bearer $1" "${2:-$TRANSFERENCIAS/api/v1/transferencias/$REFERENCIA}"
}

mostrar_jwks() {
  curl -s "${TLS[@]}" "$AUTH/oauth2/jwks" | python3 -c '
import json, sys, base64
claves = json.load(sys.stdin)["keys"]
for k in claves:
    bits = len(base64.urlsafe_b64decode(k["n"] + "=" * (-len(k["n"]) % 4))) * 8
    privadas = [p for p in ("d", "p", "q", "dp", "dq", "qi") if p in k]
    print("  kid %-34s kty=%s alg=%s use=%s e=%s n=%s… (%d bits) privados=%s" % (k["kid"], k["kty"], k.get("alg"), k.get("use"), k["e"], k["n"][:12], bits, privadas or "ninguno"))
print("  (%d clave(s) publicada(s))" % len(claves))'
}

titulo "Evidencia 05 · Tokens OAuth 2.0 firmados RS256: JWK Set y rotación de claves" \
       "Observación 4 de la semana 6: claves asimétricas con kid, publicadas como JWK Set y rotadas sin cortar el servicio."

token steve.rogers
transferir 137 131 5 > /dev/null
REFERENCIA="$TRANSFERENCIA"

paso "El access token de banco-auth va firmado con su clave privada RSA; el encabezado dice qué clave (kid) usó"
token steve.rogers
TOKEN_VIEJO="$TOKEN"; KID_VIEJO="$KID"
nota "token de steve.rogers obtenido por authorization_code + PKCE (ver evidencia 03)"
partes_jwt "$TOKEN_VIEJO"
comprobar "algoritmo" "$(campo alg "$(python3 -c "import base64,sys; t=sys.argv[1].split('.')[0]; print(base64.urlsafe_b64decode(t + '=' * (-len(t) % 4)).decode())" "$TOKEN_VIEJO")")" "RS256"

paso "JWK Set público: solo claves públicas RSA con su kid; la clave privada nunca sale de banco-auth"
nota "GET $AUTH/oauth2/jwks (el jwks_uri del discovery)"
mostrar_jwks
comprobar "kid del token publicado en el JWK Set" \
  "$(curl -s "${TLS[@]}" "$AUTH/oauth2/jwks" | grep -c "\"kid\":\"$KID_VIEJO\"")" "1"

paso "Los servidores de recursos validan la firma contra el JWK Set: token válido 200; alterado o sin firma 401"
comprobar "transferencias-service con el token válido" "$(estado_con "$TOKEN_VIEJO")" "200"
comprobar "notificaciones-service con el mismo token" "$(estado_con "$TOKEN_VIEJO" "$NOTIFICACIONES/api/v1/notificaciones")" "200"
ALTERADO=$(python3 - "$TOKEN_VIEJO" <<'PY'
import base64, json, sys
h, c, f = sys.argv[1].split(".")
claims = json.loads(base64.urlsafe_b64decode(c + "=" * (-len(c) % 4)))
claims["cliente_id"] = 1  # se hace pasar por diana.prince
print(h + "." + base64.urlsafe_b64encode(json.dumps(claims).encode()).decode().rstrip("=") + "." + f)
PY
)
SIN_FIRMA=$(python3 - "$TOKEN_VIEJO" <<'PY'
import base64, sys
h, c, f = sys.argv[1].split(".")
print(base64.urlsafe_b64encode(b'{"alg":"none"}').decode().rstrip("=") + "." + c + ".")
PY
)
comprobar "token con cliente_id cambiado (firma ya no calza)" "$(estado_con "$ALTERADO")" "401"
comprobar "token con alg=none y sin firma" "$(estado_con "$SIN_FIRMA")" "401"

paso "La administración de claves exige OAuth: sin token 401, con un token de otro cliente 403 (falta claves.administrar)"
nota "el puerto de operación escucha en la red de los contenedores: estar en él no basta para rotar claves"
SIN_CUERPO=2 llamar POST "$OP_AUTH/actuator/claves"
esperar 401
token_servicio transferencias-service "$SECRETO_TRANSFERENCIAS" core.cuentas.leer
SIN_CUERPO=2 llamar POST "$OP_AUTH/actuator/claves" -H "Authorization: Bearer $TOKEN_SERVICIO"
esperar 403
comprobar "motivo" "$(encabezado www-authenticate | grep -o 'error="[a-z_]*"')" 'error="insufficient_scope"'
token_servicio operacion-banco "$SECRETO_OPERACION" claves.administrar
TOKEN_OPERACION="$TOKEN_SERVICIO"
nota "token del cliente operacion-banco (client_credentials, el único que puede pedir claves.administrar):"
claims_jwt "$TOKEN_OPERACION"

paso "Rotación: POST /actuator/claves crea una clave nueva; la anterior deja de firmar pero sigue publicada (gracia)"
curl -s -X POST -H "Authorization: Bearer $TOKEN_OPERACION" "$OP_AUTH/actuator/claves" | python3 -c '
import json, sys
r = json.load(sys.stdin)
print("  POST %s/actuator/claves → activa %s" % (sys.argv[1], r["activa"]))
for c in r["claves"]:
    print("  %-34s %-9s retirarEn %s" % (c["kid"], c["estado"], c["retirarEn"]))' "$OP_AUTH"
token steve.rogers
TOKEN_NUEVO="$TOKEN"; KID_NUEVO="$KID"
nota "token nuevo firmado con $KID_NUEVO"
mostrar_jwks
comprobar "el token nuevo usa otra clave" "$([ "$KID_NUEVO" != "$KID_VIEJO" ] && echo si || echo no)" "si"
comprobar "token nuevo en transferencias-service (kid desconocido → vuelve a leer el JWK Set)" "$(estado_con "$TOKEN_NUEVO")" "200"
comprobar "token anterior durante la gracia" "$(estado_con "$TOKEN_VIEJO")" "200"

paso "Retiro: DELETE /actuator/claves/{kid}; cuando vence la copia del JWK Set (30 s) el token anterior ya no vale"
token_servicio operacion-banco "$SECRETO_OPERACION" claves.administrar
nota "nuevo token de operacion-banco (firmado con $KID_NUEVO): el anterior se firmó con la clave que se retira"
curl -s -X DELETE -H "Authorization: Bearer $TOKEN_SERVICIO" "$OP_AUTH/actuator/claves/$KID_VIEJO" | sed 's/^/  DELETE \/actuator\/claves\/{kid anterior} → /'
echo
mostrar_jwks
comprobar "token anterior justo después del retiro (la copia en caché aún tiene la clave)" "$(estado_con "$TOKEN_VIEJO")" "200"
sleep 32
nota "32 s después (banco.jwt.cache-jwks = 30 s en transferencias-service)"
SIN_CUERPO=2 llamar GET "$TRANSFERENCIAS/api/v1/transferencias/$REFERENCIA" -H "Authorization: Bearer $TOKEN_VIEJO"
esperar 401
comprobar "token nuevo" "$(estado_con "$TOKEN_NUEVO")" "200"

resumen_final
