#!/usr/bin/env bash
# Evidencia 17 - OAuth 2.0 con GitHub como proveedor de identidad (identidad federada), como en el tutorial de la guia
# (spring.io/guides/tutorials/spring-boot-oauth2): banco-auth es cliente OAuth 2.0 de GitHub ("Ingresar con GitHub") y
# sigue siendo el servidor de autorizacion del banco. El registro del cliente GitHub vive en el Config Server; el secreto
# llega por variable de entorno. Solo entran cuentas de GitHub vinculadas a un cliente del banco.
#
#   oauth2_github.sh                 lo que se comprueba sin credenciales de GitHub
#   oauth2_github.sh iniciar         prepara un flujo authorization_code + PKCE e imprime la URL para abrir en el navegador
#   oauth2_github.sh canjear <url>   canjea el codigo de la URL de vuelta (http://127.0.0.1:8099/callback?code=...)
# Requiere el ecosistema arriba y, para iniciar sesion, la aplicacion OAuth registrada en GitHub (.env).
set -uo pipefail
source "$(dirname "$0")/lib.sh"
if [ "${1:-}" = "-h" ]; then sed -n '2,10p' "$0"; exit 0; fi
USUARIO_CONFIG="${BANCO_CONFIG_USUARIO:-configuracion}"
CLAVE_CONFIG="${BANCO_CONFIG_CLAVE:-config-secreto-dev}"
FLUJO="$RAIZ_PROYECTO/evidencias/.flujo-github"   # verificador PKCE del flujo manual (no se versiona: evidencias/)

# --- Flujo manual: el usuario inicia sesion con su cuenta de GitHub en el navegador ------------------------------------
if [ "${1:-}" = "iniciar" ]; then
  mkdir -p "$(dirname "$FLUJO")"
  VERIFICADOR=$(python3 -c 'import secrets,base64;print(base64.urlsafe_b64encode(secrets.token_bytes(32)).rstrip(b"=").decode())')
  DESAFIO=$(python3 -c 'import hashlib,base64,sys;print(base64.urlsafe_b64encode(hashlib.sha256(sys.argv[1].encode()).digest()).rstrip(b"=").decode())' "$VERIFICADOR")
  printf '%s\n' "$VERIFICADOR" > "$FLUJO"
  python3 -c 'import sys,urllib.parse as u; print(sys.argv[1] + "/oauth2/authorize?" + u.urlencode({"response_type":"code","client_id":"banca-web","redirect_uri":sys.argv[2],"scope":"openid transferencias.escribir transferencias.leer notificaciones.leer","state":"github-1","code_challenge":sys.argv[3],"code_challenge_method":"S256"}))' "$AUTH" "$REDIRECCION" "$DESAFIO"
  exit 0
fi

if [ "${1:-}" = "canjear" ]; then
  [ -f "$FLUJO" ] && [ -n "${2:-}" ] || { echo "Uso: $0 canjear <url de vuelta> (despues de $0 iniciar)"; exit 1; }
  titulo "Evidencia 17b · Inicio de sesión con GitHub: el código vuelve a la aplicación y banco-auth emite sus tokens" \
         "La persona se autenticó en GitHub con su cuenta; banco-auth emitió los tokens del banco para su cliente vinculado."
  paso "La aplicación recibe el código (después de GitHub, banco-auth redirigió al redirect_uri de banca-web)"
  printf '  %s\n' "$(printf '%s' "$2" | sed -E 's/(code=[^&]{12})[^&]*/\1…/')"
  CODIGO=$(python3 -c 'import sys,urllib.parse as u;print(u.parse_qs(u.urlparse(sys.argv[1]).query).get("code",[""])[0])' "$2")
  comprobar "state devuelto" "$(python3 -c 'import sys,urllib.parse as u;print(u.parse_qs(u.urlparse(sys.argv[1]).query).get("state",[""])[0])' "$2")" "github-1"
  paso "Canje en /oauth2/token con el code_verifier: access token del banco con los ids del cliente y origen github"
  SIN_CUERPO=2 llamar POST "$AUTH/oauth2/token" -u "banca-web:$SECRETO_BANCA_WEB" -d grant_type=authorization_code \
    --data-urlencode "code=$CODIGO" --data-urlencode "redirect_uri=$REDIRECCION" --data-urlencode "code_verifier=$(cat "$FLUJO")"
  esperar 200
  rm -f "$FLUJO"
  TOKEN=$(campo access_token)
  claims_jwt "$TOKEN"
  CLAIMS=$(python3 -c 'import sys,base64,json;c=sys.argv[1].split(".")[1];d=json.loads(base64.urlsafe_b64decode(c+"="*(-len(c)%4)));print(d.get("origen"), d.get("sub"), d.get("usuario_id"))' "$TOKEN")
  comprobar "origen, sujeto y usuario del banco" "$CLAIMS" "github diana.prince $(sql "select id from core.usuario where usuario='diana.prince'")"
  paso "El token sirve como cualquier token del banco: diana.prince consulta sus avisos y transfiere desde su cuenta"
  BEARER=(-H "Authorization: Bearer $TOKEN")
  SIN_CUERPO=2 llamar GET "$NOTIFICACIONES/api/v1/notificaciones" "${BEARER[@]}"
  esperar 200
  transferir 101 131 25
  esperar 202
  seguir_transferencia "$TRANSFERENCIA" > /dev/null
  comprobar "transferencia iniciada con la sesión de GitHub" "$ESTADO_TRANSFERENCIA" "COMPLETADA"
  "${COMPOSE[@]}" logs --no-log-prefix banco-auth 2>/dev/null | grep -a "inicio sesion como" | tail -1 \
    | sed -E 's/^[0-9:.]+ +INFO +\[[^]]*\] +//; s/^/  log de banco-auth: /'
  resumen_final
  exit $?
fi

# --- Lo que se comprueba sin credenciales de GitHub -----------------------------------------------------------------------
titulo "Evidencia 17 · OAuth 2.0 con GitHub como proveedor de identidad (identidad federada)" \
       "Criterio 1 y guía de la semana: banco-auth es cliente OAuth de GitHub y sigue siendo el servidor de autorización del banco."

paso "El registro del cliente GitHub vive en el Config Server (como el resto de la configuración); el secreto no pasa por él"
certificado servicios/banco-auth
CONFIG_AUTH=$(curl -s "${TLS[@]}" "${CERT[@]}" -u "$USUARIO_CONFIG:$CLAVE_CONFIG" "$CONFIG/banco-auth/nube")
printf '%s' "$CONFIG_AUTH" | python3 -c '
import json, sys
for fuente in json.load(sys.stdin)["propertySources"]:
    for clave, valor in fuente["source"].items():
        if ".registration.github." in clave or clave.startswith("banco.auth.github."):
            print("  %-70s %s" % (clave, valor))'
comprobar "client-secret de GitHub en el Config Server" \
  "$(printf '%s' "$CONFIG_AUTH" | grep -c 'registration.github.client-secret')" "0"
ESTADO_SECRETO=$("${COMPOSE[@]}" exec -T banco-auth sh -c \
  'v="$SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_GITHUB_CLIENT_SECRET"; [ -n "$v" ] && [ "$v" != sin-configurar ] && echo "configurado (${#v} caracteres)" || echo "sin configurar"')
printf '  banco-auth: client-secret de GitHub por variable de entorno: %s\n' "$ESTADO_SECRETO"

paso "El login de banco-auth ofrece \"Ingresar con GitHub\" junto al formulario"
PAGINA=$(curl -s "${TLS[@]}" "$AUTH/login")
printf '%s' "$PAGINA" | grep -oE '<a class="github" href="[^"]*">[^<]*</a>' | sed 's/^/  /'
comprobar "enlace a /oauth2/authorization/github" "$(printf '%s' "$PAGINA" | grep -c 'href="oauth2/authorization/github"')" "1"

paso "Ingresar con GitHub: banco-auth redirige a GitHub con su client_id, los scopes, el redirect_uri y un state"
JAR=$(mktemp); trap 'rm -f "$JAR"' EXIT
SIN_CUERPO=2 llamar GET "$AUTH/oauth2/authorization/github" -c "$JAR" -b "$JAR" > /dev/null
GITHUB_URL=$(encabezado location)
printf '%s' "$GITHUB_URL" | python3 -c '
import sys, urllib.parse as u
url = sys.stdin.read()
p = u.urlparse(url)
print("  %s://%s%s" % (p.scheme, p.netloc, p.path))
for clave, valor in u.parse_qsl(p.query):
    print("    %-14s %s" % (clave, valor[:12] + "…" if clave == "state" else valor))'
comprobar "destino" "$(printf '%s' "$GITHUB_URL" | cut -d'?' -f1)" "https://github.com/login/oauth/authorize"
comprobar "redirect_uri registrado en GitHub" \
  "$(python3 -c 'import sys,urllib.parse as u;print(u.parse_qs(u.urlparse(sys.argv[1]).query)["redirect_uri"][0])' "$GITHUB_URL")" \
  "https://localhost:8081/login/oauth2/code/github"

paso "GitHub reconoce la aplicación registrada: sin sesión de GitHub, pide iniciar sesión para continuar a ella"
LOGIN_GITHUB=$(curl -s -o /dev/null -w '%{redirect_url}' "$GITHUB_URL")
printf '  GitHub → %s\n' "$(printf '%s' "$LOGIN_GITHUB" | cut -c1-110)…"
APLICACION=$(curl -sL "$LOGIN_GITHUB" | python3 -c '
import re, sys, html
texto = sys.stdin.read()
m = re.search(r"to continue to\s*(?:<[^>]+>\s*)*([^<]+)<", texto)
print(html.unescape(m.group(1)).strip() if m else "")')
printf '  página de GitHub: "Sign in to GitHub to continue to %s"\n' "${APLICACION:-?}"
comprobar "GitHub conoce la aplicación OAuth (client_id registrado)" "$([ -n "$APLICACION" ] && echo si || echo no)" "si"

paso "Si GitHub devuelve un código con un state que no corresponde a una solicitud de banco-auth, se rechaza"
SIN_CUERPO=2 llamar GET "$AUTH/login/oauth2/code/github?code=codigo-falso&state=inventado" -c "$JAR" -b "$JAR"
comprobar "vuelve al login con error" "$(encabezado location)" "$AUTH/login?error=github"

paso "Solo entran cuentas de GitHub vinculadas a un cliente del banco: el core las confirma por el canal AUTENTICACION"
printf '%s' "$CONFIG_AUTH" | python3 -c '
import json, sys
for fuente in json.load(sys.stdin)["propertySources"]:
    for clave, valor in fuente["source"].items():
        if clave.startswith("banco.auth.github.vinculos."):
            print("  cuenta de GitHub %s → usuario del banco %s" % (clave.rsplit(".", 1)[1], valor))'
llamar_interno GET "$CORE_INTERNO/api/v1/autenticacion/usuarios/diana.prince" -u "banco-auth:${BANCO_CANAL_AUTENTICACION_CLAVE:-autenticacion-secreto-dev}" \
  --cert /certificados/servicios/banco-auth.crt --key /certificados/servicios/banco-auth.key
esperar 200
comprobar "el core identifica al cliente vinculado" "$(campo usuario) $(campo rol)" "diana.prince CLIENTE"
SIN_CUERPO=2 llamar_interno GET "$CORE_INTERNO/api/v1/autenticacion/usuarios/diana.prince" \
  -H "Authorization: Bearer $(token_servicio transferencias-service "$SECRETO_TRANSFERENCIAS" core.cuentas.leer; printf '%s' "$TOKEN_SERVICIO")" \
  --cert /certificados/servicios/transferencias-service.crt --key /certificados/servicios/transferencias-service.key
esperar 403
nota "identificar sin clave es exclusivo del canal AUTENTICACION (banco-auth): ningún otro servicio puede hacerlo"

resumen_final
