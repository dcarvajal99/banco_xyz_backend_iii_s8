#!/usr/bin/env bash
# Evidencia 03 - OAuth 2.0 con Spring Authorization Server (banco-auth): discovery OpenID, flujo authorization_code con
# PKCE paso a paso (login en banco-auth, la clave la verifica el core), uso del token, refresh token rotativo y rechazos.
# Requiere el ecosistema arriba (docker compose up -d).
set -uo pipefail
source "$(dirname "$0")/lib.sh"
if [ "${1:-}" = "-h" ]; then sed -n '2,4p' "$0"; exit 0; fi
JAR=$(mktemp)
trap 'rm -f "$JAR"' EXIT
SCOPES="openid transferencias.escribir transferencias.leer notificaciones.leer"
VERIFICADOR=$(python3 -c 'import secrets,base64;print(base64.urlsafe_b64encode(secrets.token_bytes(32)).rstrip(b"=").decode())')
DESAFIO=$(python3 -c 'import hashlib,base64,sys;print(base64.urlsafe_b64encode(hashlib.sha256(sys.argv[1].encode()).digest()).rstrip(b"=").decode())' "$VERIFICADOR")
AUTORIZAR=$(python3 -c 'import sys,urllib.parse as u; print(sys.argv[1] + "/oauth2/authorize?" + u.urlencode({"response_type":"code","client_id":"banca-web","redirect_uri":sys.argv[2],"scope":sys.argv[3],"state":"x7Kq2","code_challenge":sys.argv[4],"code_challenge_method":"S256"}))' "$AUTH" "$REDIRECCION" "$SCOPES" "$DESAFIO")

titulo "Evidencia 03 · OAuth 2.0: servidor de autorización y flujo authorization_code con PKCE" \
       "Criterio 1: flujo funcional que protege datos y servicios; la clave del usuario nunca pasa por la aplicación."

paso "Descubrimiento OpenID Connect: banco-auth publica sus endpoints y lo que soporta"
SIN_CUERPO=2 llamar GET "$AUTH/.well-known/openid-configuration"
esperar 200
printf '%s' "$CUERPO" | python3 -c '
import json, sys
d = json.load(sys.stdin)
for k in ("issuer", "authorization_endpoint", "token_endpoint", "jwks_uri", "userinfo_endpoint", "revocation_endpoint",
          "introspection_endpoint"):
    print("  %-23s %s" % (k, d.get(k)))
print("  %-23s %s" % ("grant_types_supported", ", ".join(g.replace("urn:ietf:params:oauth:grant-type:", "")
                                                          for g in d["grant_types_supported"])))
print("  %-23s %s" % ("code_challenge_methods", ", ".join(d["code_challenge_methods_supported"])))'
comprobar "PKCE con S256" "$(campo code_challenge_methods_supported.0)" "S256"

paso "1) La aplicación manda al usuario a /oauth2/authorize con un code_challenge (PKCE); sin sesión, banco-auth pide login"
nota "code_verifier (secreto de la aplicación): ${VERIFICADOR:0:12}… · code_challenge = SHA-256: ${DESAFIO:0:12}…"
SIN_CUERPO=2 llamar GET "$AUTORIZAR" -c "$JAR" -b "$JAR" -H "Accept: text/html"
esperar 302
comprobar "redirige al formulario de login de banco-auth" "$(encabezado location)" "$AUTH/login"

paso "2) Login en banco-auth: la clave la verifica el core. Una clave mala no inicia sesión; la correcta vuelve a /authorize"
CSRF=$(curl -s -c "$JAR" -b "$JAR" "${TLS[@]}" "$AUTH/login" | sed -n 's/.*name="_csrf" value="\([^"]*\)".*/\1/p')
nota "formulario de login leído; token CSRF del formulario: ${CSRF:0:12}…"
SIN_CUERPO=2 llamar POST "$AUTH/login" -c "$JAR" -b "$JAR" --data-urlencode "username=diana.prince" \
  --data-urlencode "password=clave-equivocada" --data-urlencode "_csrf=$CSRF"
comprobar "clave equivocada" "$(encabezado location)" "$AUTH/login?error=credenciales"
CSRF=$(curl -s -c "$JAR" -b "$JAR" "${TLS[@]}" "$AUTH/login" | sed -n 's/.*name="_csrf" value="\([^"]*\)".*/\1/p')
SIN_CUERPO=2 llamar POST "$AUTH/login" -c "$JAR" -b "$JAR" --data-urlencode "username=diana.prince" \
  --data-urlencode "password=$CLAVE_CLIENTES" --data-urlencode "_csrf=$CSRF"
esperar 302
DESTINO=$(encabezado location)
comprobar "vuelve a la solicitud de autorización original" "$(printf '%s' "$DESTINO" | grep -c '/oauth2/authorize?')" "1"

paso "3) Con sesión, banco-auth redirige a la aplicación con un código de un solo uso (y el mismo state)"
SIN_CUERPO=2 llamar GET "$DESTINO" -c "$JAR" -b "$JAR"
esperar 302
CODIGO=$(python3 -c 'import sys,urllib.parse as u;print(u.parse_qs(u.urlparse(sys.argv[1]).query)["code"][0])' "$(encabezado location)")
ESTADO_OAUTH=$(python3 -c 'import sys,urllib.parse as u;print(u.parse_qs(u.urlparse(sys.argv[1]).query)["state"][0])' "$(encabezado location)")
comprobar "redirige al redirect_uri registrado" "$(encabezado location | cut -d'?' -f1)" "$REDIRECCION"
comprobar "state devuelto (protege contra CSRF en la aplicación)" "$ESTADO_OAUTH" "x7Kq2"

paso "4) La aplicación canjea el código en /oauth2/token con su secreto y el code_verifier: access, refresh e id token"
SIN_CUERPO=2 llamar POST "$AUTH/oauth2/token" -u "banca-web:$SECRETO_BANCA_WEB" -d grant_type=authorization_code \
  --data-urlencode "code=$CODIGO" --data-urlencode "redirect_uri=$REDIRECCION" --data-urlencode "code_verifier=$VERIFICADOR"
esperar 200
RESPUESTA="$CUERPO"
TOKEN=$(campo access_token "$RESPUESTA"); REFRESCO=$(campo refresh_token "$RESPUESTA"); ID_TOKEN=$(campo id_token "$RESPUESTA")
printf '  token_type %s · expires_in %s s · scope "%s"\n' "$(campo token_type "$RESPUESTA")" "$(campo expires_in "$RESPUESTA")" "$(campo scope "$RESPUESTA")"
printf '  refresh_token %s… · id_token %s…\n' "${REFRESCO:0:16}" "${ID_TOKEN:0:16}"
nota "access token (JWT RS256 firmado por banco-auth):"
claims_jwt "$TOKEN"
comprobar "el access token trae los ids del usuario en el core" \
  "$(python3 -c 'import sys,base64,json;c=sys.argv[1].split(".")[1];d=json.loads(base64.urlsafe_b64decode(c+"="*(-len(c)%4)));print(d["sub"],d["usuario_id"],d["cliente_id"])' "$TOKEN")" \
  "diana.prince $(sql "select id from core.usuario where usuario='diana.prince'") $(sql "select cliente_id from core.usuario where usuario='diana.prince'")"

paso "El token abre los servicios que lo aceptan: /userinfo (OIDC), notificaciones-service y transferencias-service"
SIN_CUERPO=2 llamar GET "$AUTH/userinfo" -H "Authorization: Bearer $TOKEN"
esperar 200
nota "userinfo: $CUERPO"
BEARER=(-H "Authorization: Bearer $TOKEN")
SIN_CUERPO=2 llamar GET "$NOTIFICACIONES/api/v1/notificaciones" "${BEARER[@]}"
esperar 200
transferir 101 131 100
esperar 202
comprobar "transferencia aceptada con validación previa contra el core" "$(campo validacion)" "PREVIA"

paso "Refresh token rotativo: entrega tokens nuevos y el refresh token usado queda invalidado"
SIN_CUERPO=2 llamar POST "$AUTH/oauth2/token" -u "banca-web:$SECRETO_BANCA_WEB" -d grant_type=refresh_token \
  --data-urlencode "refresh_token=$REFRESCO"
esperar 200
NUEVO=$(campo refresh_token)
comprobar "refresh token distinto del anterior" "$([ -n "$NUEVO" ] && [ "$NUEVO" != "$REFRESCO" ] && echo si || echo no)" "si"
llamar POST "$AUTH/oauth2/token" -u "banca-web:$SECRETO_BANCA_WEB" -d grant_type=refresh_token \
  --data-urlencode "refresh_token=$REFRESCO"
esperar 400
comprobar "reusar el refresh token anterior" "$(campo error)" "invalid_grant"

paso "El código es de un solo uso y PKCE es obligatorio: sin el code_verifier correcto no hay token"
SIN_CUERPO=2 llamar POST "$AUTH/oauth2/token" -u "banca-web:$SECRETO_BANCA_WEB" -d grant_type=authorization_code \
  --data-urlencode "code=$CODIGO" --data-urlencode "redirect_uri=$REDIRECCION" --data-urlencode "code_verifier=$VERIFICADOR"
esperar 400
comprobar "canjear el mismo código otra vez" "$(campo error)" "invalid_grant"
SIN_PKCE=$(python3 -c 'import sys,urllib.parse as u; print(sys.argv[1] + "/oauth2/authorize?" + u.urlencode({"response_type":"code","client_id":"banca-web","redirect_uri":sys.argv[2],"scope":"transferencias.leer","state":"s1"}))' "$AUTH" "$REDIRECCION")
SIN_CUERPO=2 llamar GET "$SIN_PKCE" -c "$JAR" -b "$JAR"
comprobar "autorizar sin code_challenge" "$(python3 -c 'import sys,urllib.parse as u;print(u.parse_qs(u.urlparse(sys.argv[1]).query).get("error",[""])[0])' "$(encabezado location)")" "invalid_request"

resumen_final
