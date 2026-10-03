#!/usr/bin/env bash
# Evidencia 02 - docker-compose.yaml: levanta todo el ecosistema con un comando, en orden y por salud, y lo deja
# observable (estado, red, volumenes, puertos) y con reinicio automatico. Requiere las imagenes construidas.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
if [ "${1:-}" = "-h" ]; then sed -n '2,3p' "$0"; exit 0; fi
SERVICIOS_JAVA="config-server eureka-1 eureka-2 banco-core-api banco-auth transferencias-service antifraude-service notificaciones-service"

titulo "Evidencia 02 · docker-compose.yaml: todo el ecosistema con un solo comando" \
       "Criterio 3: orquesta todos los componentes de forma funcional (orden por salud, red interna, reinicio)."

paso "docker compose up -d --wait: crea red y volúmenes y arranca cada contenedor cuando sus dependencias están sanas"
inicio=$(date +%s)
# Se muestran la red y los volumenes creados y, por contenedor, cuando arranco, cuando quedo sano y la PKI al terminar
# (sin las lineas intermedias Creating/Created/Starting/Waiting).
"${COMPOSE[@]}" up -d --wait 2>&1 | sed -E 's/^ *//' | grep -E '^(Network|Volume) .*Created|^Container .* (Started|Healthy|Exited)' \
  | awk '{ if (!visto[$0]++) print "  " $0 }'
fin=$(date +%s)
nota "listo en $((fin - inicio)) s"
obtener_certificados

paso "Estado: once contenedores; los diez con healthcheck, sanos, y la PKI terminada"
"${COMPOSE[@]}" ps -a --format '{{.Service}}\t{{.State}}\t{{.Health}}\t{{.Status}}' | sort | awk -F'\t' '
  BEGIN {printf "  %-24s %-9s %-10s %s\n", "SERVICIO", "ESTADO", "SALUD", "DETALLE"}
  {printf "  %-24s %-9s %-10s %s\n", $1, $2, ($3 == "" ? "-" : $3), $4}'
sanos=$("${COMPOSE[@]}" ps --format '{{.Service}} {{.Health}}' | grep -c ' healthy')
comprobar "contenedores sanos (los diez que tienen healthcheck)" "$sanos" "10"
comprobar "pki terminó bien (genera la PKI y sale)" "$("${COMPOSE[@]}" ps -a --format '{{.Service}} {{.Status}}' | awk '$1=="pki"{print $2, $3}')" "Exited (0)"

paso "Orden real de arranque (docker inspect): cada nivel empezó cuando el anterior estaba sano"
for contenedor in $("${COMPOSE[@]}" ps -a -q); do
  docker inspect -f '{{.State.StartedAt}} {{index .Config.Labels "com.docker.compose.service"}}' "$contenedor"
done | sort | awk '{split($1, t, "T"); printf "  %s  %s\n", substr(t[2], 1, 12), $2}'

paso "Red interna y volúmenes: los servicios se encuentran por nombre; datos, Kafka y certificados persisten"
printf '  red %s: %s contenedores conectados\n' "$RED" "$(docker network inspect "$RED" --format '{{len .Containers}}')"
docker volume ls --filter name=banco-xyz_ --format '{{.Name}}' | sed 's/^/  volumen /'
publicados=$("${COMPOSE[@]}" ps --format '{{.Ports}}' | tr ',' '\n' | grep -o '[0-9.]*:[0-9]*->[0-9]*/tcp' | sort -t: -k2 -n -u)
printf '  puertos publicados en el equipo: %s\n' "$(printf '%s\n' "$publicados" | sed 's#/tcp##' | paste -sd' ' -)"
comprobar "puertos publicados" "$(printf '%s\n' "$publicados" | grep -c .)" "10"
comprobar "puertos publicados fuera de 127.0.0.1" "$(printf '%s\n' "$publicados" | grep -vc '^127.0.0.1:')" "0"
nota "banco-core-api (8080), la base, Kafka y antifraude no se publican: solo se alcanzan dentro de la red banco-xyz"

paso "Cada servicio Java tomó su configuración del Config Server (entorno nube) y se registró en Eureka"
for servicio in banco-core-api banco-auth transferencias-service antifraude-service notificaciones-service; do
  # La ultima linea: la primera es la consulta sin perfil y la ultima la del perfil activo (tls,nube).
  linea=$("${COMPOSE[@]}" logs --no-log-prefix "$servicio" 2>/dev/null | grep 'Located environment: name=' | tail -1 | grep -o 'name=[^,]*, profiles=\[[^]]*\]')
  printf '  %-24s %s\n' "$servicio" "$linea"
done
curl -s -H 'Accept: application/json' "$EUREKA1/eureka/apps" | python3 -c '
import json, sys
apps = json.load(sys.stdin)["applications"]["application"]
print("  Eureka: " + ", ".join(sorted("%s (%d)" % (a["name"], len(a["instance"])) for a in apps)))'
comprobar "aplicaciones registradas en Eureka (5 servicios + el servidor)" \
  "$(curl -s -H 'Accept: application/json' "$EUREKA1/eureka/apps" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)["applications"]["application"]))')" "6"

paso "Reinicio automático (restart: unless-stopped): si el proceso de un servicio muere, Docker lo levanta de nuevo"
CONTENEDOR=$("${COMPOSE[@]}" ps -q notificaciones-service)
antes=$(docker inspect -f '{{.RestartCount}}' "$CONTENEDOR")
pid=$(docker inspect -f '{{.State.Pid}}' "$CONTENEDOR")
nota "se mata con SIGKILL el proceso Java de notificaciones-service (pid $pid en la máquina virtual de Docker)"
colima ssh -- sudo kill -9 "$pid"
# Primero el reinicio (al reiniciar, el contador sube un instante antes de que la salud vuelva a "starting"), despues
# la salud.
for _ in $(seq 1 60); do
  [ "$(docker inspect -f '{{.RestartCount}}' "$CONTENEDOR")" -gt "$antes" ] \
    && [ "$(docker inspect -f '{{.State.Health.Status}}' "$CONTENEDOR")" = "starting" ] && break
  sleep 0.5
done
for _ in $(seq 1 90); do [ "$(docker inspect -f '{{.State.Health.Status}}' "$CONTENEDOR")" = "healthy" ] && break; sleep 2; done
docker inspect -f '  reinicios: {{.RestartCount}} · estado: {{.State.Status}} · salud: {{.State.Health.Status}} · iniciado de nuevo: {{.State.StartedAt}}' "$CONTENEDOR"
comprobar "Docker lo reinició solo" "$(( $(docker inspect -f '{{.RestartCount}}' "$CONTENEDOR") > antes ))" "1"
comprobar "y volvió a estar sano" "$(docker inspect -f '{{.State.Health.Status}}' "$CONTENEDOR")" "healthy"

resumen_final
