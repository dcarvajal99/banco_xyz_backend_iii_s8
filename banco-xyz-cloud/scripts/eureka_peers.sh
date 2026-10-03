#!/usr/bin/env bash
# Evidencia 14 - Observacion 2 de la semana 6, en contenedores: peers de Eureka y replicacion del registro.
# Dos nodos del compose (eureka-1:8761 y eureka-2:8762) que se registran entre si; un registro nuevo se replica; si cae
# eureka-1 los clientes siguen con eureka-2 y, al volver, eureka-1 copia el registro. Detiene y levanta eureka-1.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
if [ "${1:-}" = "-h" ]; then sed -n '2,4p' "$0"; exit 0; fi
# Aunque el script se corte a mitad de camino, el ecosistema queda como estaba.
trap '"${COMPOSE[@]}" start eureka-1 > /dev/null 2>&1' EXIT
RECURSOS="$RAIZ_PROYECTO/eureka-server/src/main/resources"

# registro URL: "APLICACION host:puerto:estado ..." por linea, ordenado (sirve para comparar los dos nodos). El host es
# el nombre del contenedor o, en antifraude (escalable, sin hostname fijo), el id del contenedor.
registro() {
  curl -s -H 'Accept: application/json' "$1/eureka/apps" | python3 -c '
import json, sys
def corto(i):
    host, _, puerto = i["instanceId"].split(":")
    return "%s:%s:%s" % (host, puerto, i["status"])
for a in sorted(json.load(sys.stdin)["applications"]["application"], key=lambda a: a["name"]):
    print(a["name"], " ".join(sorted(corto(i) for i in a["instance"])))' 2>/dev/null
}

# replicas URL CLASE: available-replicas o unavailable-replicas segun el panel de ese nodo.
replicas() {
  curl -s "$1/" | python3 -c '
import re, sys
m = re.search(r"<td>%s</td>\s*<td>(.*?)</td>" % sys.argv[1], sys.stdin.read(), re.S)
print(", ".join(u.strip() for u in (m.group(1) if m else "").split(",") if u.strip()))' "$2"
}

comparar_registros() {
  paste -d'|' <(registro "$EUREKA1") <(registro "$EUREKA2") | awk -F'|' '{
    split($1, a, " "); n1 = split($1, x, " ") - 1; n2 = split($2, y, " ") - 1
    printf "  %-24s peer1: %d instancia(s)   peer2: %d instancia(s)   %s\n", a[1], n1, n2, ($1 == $2 ? "igual" : "DISTINTO") }'
}

titulo "Evidencia 14 · Eureka con dos peers y replicación del registro (en el compose)" \
       "Observación 2 de la semana 6: el descubrimiento no depende de un solo nodo."

paso "Configuración: cada nodo usa al otro como defaultZone; los clientes conocen ambos"
for perfil in nube-peer1 nube-peer2; do
  printf '  %s: %s\n' "$perfil" "$(grep -E '^(server.port|eureka.instance.hostname|eureka.client.service-url.defaultZone)=' \
    "$RECURSOS/application-$perfil.properties" | sed 's/eureka.client.service-url.//; s/eureka.instance.//' | paste -sd' ' -)"
done
printf '  clientes (configuracion/application-nube.properties): %s\n' "$(grep '^eureka.client.service-url.defaultZone' "$RAIZ_PROYECTO/configuracion/application-nube.properties" | cut -d= -f2)"

paso "Cada nodo ve al otro como réplica disponible (panel de Eureka)"
R1=$(replicas "$EUREKA1" available-replicas); R2=$(replicas "$EUREKA2" available-replicas)
printf '  eureka-1 → available-replicas: %s\n' "$R1"
printf '  eureka-2 → available-replicas: %s\n' "$R2"
comprobar "réplica disponible de eureka-1" "$R1" "http://eureka-2:8762/eureka/"
comprobar "réplica disponible de eureka-2" "$R2" "http://eureka-1:8761/eureka/"

paso "Replicación: el registro de los dos nodos tiene las mismas aplicaciones e instancias"
comparar_registros
comprobar "registros de eureka-1 y eureka-2" "$([ "$(registro "$EUREKA1")" = "$(registro "$EUREKA2")" ] && echo iguales || echo distintos)" "iguales"

paso "Un contenedor nuevo (--scale antifraude-service=2) se registra en un nodo y aparece en el otro por replicación"
ANTES=$("${COMPOSE[@]}" ps -q antifraude-service | sort)
"${COMPOSE[@]}" up -d --scale antifraude-service=2 --no-recreate --wait antifraude-service > /dev/null 2>&1
NUEVO=$(comm -13 <(printf '%s\n' "$ANTES") <("${COMPOSE[@]}" ps -q antifraude-service | sort) | head -1)
HOST_NUEVO=$(docker inspect -f '{{.Config.Hostname}}' "$NUEVO")
for _ in $(seq 1 30); do registro "$EUREKA1" | grep -q "$HOST_NUEVO" && registro "$EUREKA2" | grep -q "$HOST_NUEVO" && break; sleep 1; done
# El cliente se registra en uno de los dos nodos (replication=false); el otro lo recibe del primero (replication=true).
for nodo in eureka-1 eureka-2; do
  "${COMPOSE[@]}" logs --no-log-prefix "$nodo" 2>/dev/null | grep -a "Registered instance ANTIFRAUDE-SERVICE/$HOST_NUEVO" | tail -1 \
    | sed -E 's/ INFO +AbstractInstanceRegistry - / /' | sed "s/^/  log $nodo: /"
done
comprobar "el contenedor nuevo visible en eureka-1 y en eureka-2" \
  "$(registro "$EUREKA1" | grep -c "$HOST_NUEVO") $(registro "$EUREKA2" | grep -c "$HOST_NUEVO")" "1 1"
comprobar "un nodo lo recibió directo y el otro por replicación" \
  "$(for nodo in eureka-1 eureka-2; do "${COMPOSE[@]}" logs --no-log-prefix "$nodo" 2>/dev/null \
       | grep -a "Registered instance ANTIFRAUDE-SERVICE/$HOST_NUEVO" | tail -1 | grep -o 'replication=[a-z]*'; done | sort | paste -sd' ' -)" \
  "replication=false replication=true"
"${COMPOSE[@]}" up -d --scale antifraude-service=1 --no-recreate antifraude-service > /dev/null 2>&1
for _ in $(seq 1 40); do registro "$EUREKA1" | grep -q "$HOST_NUEVO" || registro "$EUREKA2" | grep -q "$HOST_NUEVO" || break; sleep 1; done
comprobar "la baja también se replica (ya no está en ninguno de los dos)" \
  "$(registro "$EUREKA1" | grep -c "$HOST_NUEVO") $(registro "$EUREKA2" | grep -c "$HOST_NUEVO")" "0 0"

paso "Cae eureka-1: los clientes renuevan con eureka-2 y el descubrimiento sigue funcionando"
"${COMPOSE[@]}" stop eureka-1 2>&1 | grep -E "Stopped" | sed 's/^ */  /'
sleep 20
nota "20 s después (4 renovaciones de 5 s; una instancia sin renovar expira a los 15 s)"
registro "$EUREKA2" | grep -v EUREKA-SERVER | sed -E 's/ [0-9a-f]{12}:/ <contenedor>:/; s/^/  eureka-2: /'
comprobar "instancias UP en eureka-2 (5 servicios + eureka-2)" "$(registro "$EUREKA2" | tr ' ' '\n' | grep -c ':UP$')" "6"
printf '  eureka-2 → unavailable-replicas: %s\n' "$(replicas "$EUREKA2" unavailable-replicas)"
token steve.rogers
transferir 137 131 10
esperar 202
comprobar "transferencias-service encontró al core con eureka-1 caído" "$(campo validacion)" "PREVIA"

paso "Vuelve eureka-1: copia el registro desde eureka-2 al arrancar y los dos quedan iguales otra vez"
"${COMPOSE[@]}" start eureka-1 > /dev/null 2>&1
EUREKA1_ID=$("${COMPOSE[@]}" ps -q eureka-1)
for _ in $(seq 1 60); do [ "$(docker inspect -f '{{.State.Health.Status}}' "$EUREKA1_ID")" = "healthy" ] && break; sleep 2; done
for _ in $(seq 1 60); do [ "$(registro "$EUREKA1")" = "$(registro "$EUREKA2")" ] && break; sleep 1; done
"${COMPOSE[@]}" logs --no-log-prefix --since 2m eureka-1 2>/dev/null | grep -a "Got [0-9]* instances from neighboring DS node" | tail -1 \
  | sed -E 's/ INFO +PeerAwareInstanceRegistryImpl - / /; s/^/  log eureka-1: /'
comparar_registros
comprobar "registros de eureka-1 y eureka-2" "$([ "$(registro "$EUREKA1")" = "$(registro "$EUREKA2")" ] && echo iguales || echo distintos)" "iguales"

resumen_final
