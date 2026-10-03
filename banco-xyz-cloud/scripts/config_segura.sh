#!/usr/bin/env bash
# Evidencia 13 - Observacion 1 de la semana 6, ahora en contenedores: Config Server protegido con TLS y autenticacion.
# Solo HTTPS, certificado de cliente obligatorio (firmado por la CA del banco) y usuario/clave (Basic). Un servicio con
# la clave equivocada no arranca (fail-fast). Requiere el ecosistema arriba (docker compose up -d).
set -uo pipefail
source "$(dirname "$0")/lib.sh"
if [ "${1:-}" = "-h" ]; then sed -n '2,4p' "$0"; exit 0; fi
USUARIO_CONFIG="${BANCO_CONFIG_USUARIO:-configuracion}"
CLAVE_CONFIG="${BANCO_CONFIG_CLAVE:-config-secreto-dev}"
RECURSO="$CONFIG/banco-core-api/default"

titulo "Evidencia 13 · Config Server con TLS, certificado de cliente y usuario/clave (en el compose)" \
       "Observación 1 de la semana 6: la configuración central ya no se entrega a cualquiera ni en texto plano."

paso "HTTP sin cifrar: el puerto 8888 solo habla TLS"
SIN_CUERPO=2 llamar GET "http://localhost:8888/banco-core-api/default"
nota "respuesta de Tomcat: $(printf '%s' "$CUERPO" | tr -d '\r' | grep -o 'This combination[^<]*' | head -1)"
esperar 400

paso "HTTPS con usuario y clave pero SIN certificado de cliente: el servidor corta el handshake (client-auth=need)"
llamar GET "$RECURSO" -u "$USUARIO_CONFIG:$CLAVE_CONFIG"
esperar 000

paso "Certificado de un servicio del banco pero sin credenciales, o con la clave equivocada: 401"
certificado servicios/banco-core-api
SIN_CUERPO=2 llamar GET "$RECURSO" "${CERT[@]}"
esperar 401
SIN_CUERPO=2 llamar GET "$RECURSO" "${CERT[@]}" -u "$USUARIO_CONFIG:clave-equivocada"
esperar 401

paso "Certificado emitido por una CA ajena, aunque traiga las credenciales correctas: rechazado en el handshake"
certificado intruso/transferencias-service-falso
llamar GET "$RECURSO" "${CERT[@]}" -u "$USUARIO_CONFIG:$CLAVE_CONFIG"
esperar 000

paso "Certificado del banco + usuario y clave correctos: 200 con la configuración (se listan solo sus fuentes)"
certificado servicios/banco-core-api
SIN_CUERPO=2 llamar GET "$RECURSO" "${CERT[@]}" -u "$USUARIO_CONFIG:$CLAVE_CONFIG"
esperar 200
printf '%s' "$CUERPO" | python3 -c '
import json, sys
d = json.load(sys.stdin)
print("  aplicación %s · perfiles %s" % (d["name"], d["profiles"]))
for f in d["propertySources"]:
    print("  fuente %-58s %2d propiedades" % (f["name"].split("configuracion/")[-1], len(f["source"])))'
comprobar "fuentes entregadas (propias del servicio + comunes)" \
  "$(printf '%s' "$CUERPO" | python3 -c 'import json,sys; print(" + ".join(f["name"].split("/")[-1] for f in json.load(sys.stdin)["propertySources"]))')" \
  "banco-core-api.properties + application.properties"

paso "Un servicio con la clave de Config equivocada NO arranca (fail-fast): no corre con los valores de su jar"
nota "docker compose run --rm --no-deps -e BANCO_CONFIG_CLAVE=clave-equivocada antifraude-service"
SALIDA=$("${COMPOSE[@]}" run --rm --no-deps -e BANCO_CONFIG_CLAVE=clave-equivocada antifraude-service 2>&1)
CODIGO=$?
printf '%s\n' "$SALIDA" | grep -aoE 'ConfigClientFailFastException: .*|Unauthorized: 401 +on GET request for "[^"]*"' \
  | sort -u | sed 's/^/  log: /'
comprobar "el contenedor terminó con error (código de salida distinto de 0)" "$([ "$CODIGO" -ne 0 ] && echo si || echo no)" "si"
comprobar "motivo: el Config Server respondió 401" "$(printf '%s' "$SALIDA" | grep -c 'Unauthorized: 401' | awk '{print ($1 > 0) ? "si" : "no"}')" "si"

paso "Los servicios en ejecución leyeron su configuración por HTTPS al arrancar, con el perfil nube (log de cada uno)"
for servicio in banco-core-api banco-auth transferencias-service antifraude-service notificaciones-service; do
  linea=$("${COMPOSE[@]}" logs --no-log-prefix "$servicio" 2>/dev/null | grep -a "Located environment: name=$servicio" | tail -1)
  printf '  %-23s %s\n' "$servicio" "$(printf '%s' "$linea" | grep -o 'Located environment: name=[^,]*, profiles=\[[a-z,]*\]')"
  comprobar "$servicio tomó la configuración del Config Server" "$([ -n "$linea" ] && echo si || echo no)" "si"
done
nota "URL usada por todos: $("${COMPOSE[@]}" logs --no-log-prefix banco-core-api 2>/dev/null | grep -a 'Fetching config from server at' | tail -1 | grep -o 'https://[^ ]*')"

resumen_final
