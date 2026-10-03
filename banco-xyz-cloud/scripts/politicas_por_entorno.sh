#!/usr/bin/env bash
# Evidencia 08 - Observacion 1 de la semana 7: las politicas de Resilience4j viven en el Config Server, compartidas
# entre servicios (configs + base-config) y ajustadas por entorno (application-nube.properties). Los jar no traen
# politica propia. Requiere el ecosistema arriba (docker compose up -d).
set -uo pipefail
source "$(dirname "$0")/lib.sh"
if [ "${1:-}" = "-h" ]; then sed -n '2,4p' "$0"; exit 0; fi
USUARIO_CONFIG="${BANCO_CONFIG_USUARIO:-configuracion}"
CLAVE_CONFIG="${BANCO_CONFIG_CLAVE:-config-secreto-dev}"
certificado servicios/transferencias-service

# politica SERVICIO PERFIL: valores efectivos de Resilience4j que el Config Server entrega a ese servicio en ese perfil.
politica() {
  curl -s "${TLS[@]}" "${CERT[@]}" -u "$USUARIO_CONFIG:$CLAVE_CONFIG" "$CONFIG/$1/$2" | python3 -c '
import json, sys
d = json.load(sys.stdin)
efectivo = {}
for fuente in reversed(d["propertySources"]):          # la primera fuente tiene prioridad: se aplica al final
    efectivo.update({k: v for k, v in fuente["source"].items() if k.startswith("resilience4j.")})
print(json.dumps(efectivo))'
}

# propiedad CLAVE JSON: valor de una propiedad (la clave tiene puntos: no sirve campo, que separa la ruta por puntos).
propiedad() {
  python3 -c 'import json,sys; print(json.loads(sys.argv[2]).get(sys.argv[1], ""))' "$1" "$2"
}

titulo "Evidencia 08 · Políticas de Resilience4j centralizadas y por entorno" \
       "Observación 1 de la semana 7: configuración compartida en el Config Server, con valores por entorno."

paso "Dónde vive cada parte de la política (repositorio del Config Server)"
for archivo in application.properties application-nube.properties banco-auth.properties transferencias-service.properties banco-core-api.properties; do
  # (bash 3.2 de macOS no acepta un case dentro de $( ): la descripcion se elige antes)
  case "$archivo" in
    application.properties) rol="(configs compartidas: http-interno y publicacion-kafka)" ;;
    application-nube.properties) rol="(ajustes del entorno nube)" ;;
    *) rol="(instancias con base-config y excepciones propias)" ;;
  esac
  printf '  %-50s %2s propiedades resilience4j  %s\n' "configuracion/$archivo" \
    "$(grep -c '^resilience4j\.' "$RAIZ_PROYECTO/configuracion/$archivo")" "$rol"
done
nota "las instancias solo eligen su política: resilience4j.circuitbreaker.instances.core.base-config=http-interno"

paso "Los jar no traen política propia: la reciben del Config Server (application.properties dentro de cada imagen)"
for app in banco-auth transferencias-service banco-core-api; do
  n=$(docker run --rm --entrypoint sh "banco-xyz/$app:1.0.0" -c "grep -c '^resilience4j\.' /app/BOOT-INF/classes/application.properties || true")
  printf '  %-24s %s propiedades resilience4j en su application.properties\n' "$app" "$n"
  comprobar "$app sin política propia" "$n" "0"
done

paso "Lo que recibe transferencias-service según el entorno (valores efectivos que entrega el Config Server)"
LOCAL=$(politica transferencias-service default)
NUBE=$(politica transferencias-service nube)
python3 - "$LOCAL" "$NUBE" <<'PY'
import json, sys
local, nube = json.loads(sys.argv[1]), json.loads(sys.argv[2])
filas = [
    ("circuito http-interno: ventana", "resilience4j.circuitbreaker.configs.http-interno.sliding-window-size"),
    ("circuito http-interno: mínimo de llamadas", "resilience4j.circuitbreaker.configs.http-interno.minimum-number-of-calls"),
    ("circuito http-interno: tiempo abierto", "resilience4j.circuitbreaker.configs.http-interno.wait-duration-in-open-state"),
    ("circuito http-interno: llamadas de prueba", "resilience4j.circuitbreaker.configs.http-interno.permitted-number-of-calls-in-half-open-state"),
    ("circuito http-interno: llamada lenta desde", "resilience4j.circuitbreaker.configs.http-interno.slow-call-duration-threshold"),
    ("reintento http-interno: intentos", "resilience4j.retry.configs.http-interno.max-attempts"),
    ("reintento http-interno: espera", "resilience4j.retry.configs.http-interno.wait-duration"),
    ("reintento http-interno: exponencial", "resilience4j.retry.configs.http-interno.enable-exponential-backoff"),
    ("bulkhead http-interno: llamadas simultáneas", "resilience4j.bulkhead.configs.http-interno.max-concurrent-calls"),
    ("circuito publicacion-kafka: ventana", "resilience4j.circuitbreaker.configs.publicacion-kafka.sliding-window-size"),
    ("circuito publicacion-kafka: tiempo abierto", "resilience4j.circuitbreaker.configs.publicacion-kafka.wait-duration-in-open-state"),
    ("reintento publicacion-kafka: intentos", "resilience4j.retry.configs.publicacion-kafka.max-attempts"),
    ("instancia core: base-config", "resilience4j.circuitbreaker.instances.core.base-config"),
    ("instancia kafka: base-config", "resilience4j.circuitbreaker.instances.kafka.base-config"),
]
print("  %-44s %-19s %s" % ("PARÁMETRO", "LOCAL", "NUBE (perfil nube)"))
for nombre, clave in filas:
    print("  %-44s %-19s %s" % (nombre, local.get(clave, "-"), nube.get(clave, "-")))
PY
comprobar "mínimo de llamadas del circuito core en la nube" \
  "$(propiedad resilience4j.circuitbreaker.configs.http-interno.minimum-number-of-calls "$NUBE")" "5"

paso "La misma política la usan los dos clientes HTTP del core: banco-auth recibe http-interno con los mismos valores"
AUTH_NUBE=$(politica banco-auth nube)
mismos=$(python3 - "$NUBE" "$AUTH_NUBE" <<'PY'
import json, sys
a, b = json.loads(sys.argv[1]), json.loads(sys.argv[2])
claves = [k for k in a if ".configs.http-interno." in k]
print(sum(1 for k in claves if a[k] == b.get(k)), "de", len(claves))
PY
)
printf '  parámetros de http-interno iguales en transferencias-service y banco-auth: %s\n' "$mismos"
comprobar "política compartida idéntica" "$(echo "$mismos" | awk '{print ($1 == $3) ? "si" : "no"}')" "si"
printf '  excepciones que el circuito core ignora en banco-auth: %s\n' "$(propiedad resilience4j.circuitbreaker.instances.core.ignore-exceptions "$AUTH_NUBE" | tr ',' '\n' | sed 's/.*\.//' | paste -sd',' - | sed 's/,/, /g')"

paso "En ejecución, transferencias-service ya usa la política del entorno nube (estado de los circuitos en el actuator)"
curl -s "$OP_TRANSFERENCIAS/actuator/circuitbreakers" | python3 -c '
import json, sys
for nombre, c in json.load(sys.stdin)["circuitBreakers"].items():
    print("  circuito %-6s estado=%-7s umbral de fallas=%s · umbral de lentitud=%s" % (nombre, c["state"], c["failureRateThreshold"], c["slowCallRateThreshold"]))'
comprobar "umbral de llamadas lentas del circuito core (solo existe en la política nube)" \
  "$(curl -s "$OP_TRANSFERENCIAS/actuator/circuitbreakers" | python3 -c 'import json,sys;print(json.load(sys.stdin)["circuitBreakers"]["core"]["slowCallRateThreshold"])')" "80.0%"

resumen_final
