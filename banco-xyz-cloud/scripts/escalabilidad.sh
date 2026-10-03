#!/usr/bin/env bash
# Evidencia 12 - Escalabilidad horizontal del consumidor mas lento de la saga (antifraude, 200 ms por evento) con
# docker compose --scale: la misma carga (48 transferencias repartidas en las 3 particiones de cuentas.reservas) con 1 y
# con 3 contenedores del mismo grupo, y la caida abrupta de un contenedor durante la carga (Docker lo reinicia solo).
set -uo pipefail
source "$(dirname "$0")/lib.sh"
if [ "${1:-}" = "-h" ]; then sed -n '2,4p' "$0"; exit 0; fi
# Aunque el script se corte a mitad de camino, el ecosistema queda como estaba.
trap '"${COMPOSE[@]}" up -d --scale antifraude-service=1 --no-recreate antifraude-service > /dev/null 2>&1' EXIT

USUARIOS=(steve.rogers alice.brown bob.johnson charlie.green)
# indice del usuario:cuenta. Dos cuentas por particion (murmur2 de la clave, como el particionador de Kafka):
# particion 0 = 137 y 144, particion 1 = 127 y 129, particion 2 = 139 y 147.
PARES=("0:137" "1:144" "2:127" "0:129" "3:139" "1:147")
POR_CUENTA=8
DESTINO=102
TOKENS=()

contenedores_antifraude() { "${COMPOSE[@]}" ps -q antifraude-service | sort; }

consumidores_antifraude() {
  "${KAFKA_CLI[@]}" /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server kafka:9092 \
    --describe --group antifraude-service 2>/dev/null | awk '$2 == "cuentas.reservas" && $7 != "-" {print $7}' | sort -u | wc -l | tr -d ' '
}

esperar_consumidores() {
  for _ in $(seq 1 90); do [ "$(consumidores_antifraude)" = "$1" ] && return 0; sleep 1; done
  return 1
}

# decisiones CONTENEDOR: contador antifraude.decisiones de esa instancia (actuator dentro del contenedor).
decisiones() {
  en_contenedor "$1" http://127.0.0.1:9083/actuator/metrics/antifraude.decisiones \
    | python3 -c 'import sys,json; print(int(json.load(sys.stdin)["measurements"][0]["value"]))' 2>/dev/null || echo 0
}

nombre_corto() { docker inspect -f '{{.Name}}' "$1" | sed 's#^/##'; }

# carga: 48 POST en paralelo; espera a que todas terminen y deja en DURACION los segundos entre la primera solicitud y
# la ultima transferencia terminada (medidos en la base, no en el script), y los ids en IDS.
carga() {
  local dir par usuario cuenta i
  dir=$(mktemp -d)
  for par in "${PARES[@]}"; do
    usuario=${par%%:*}; cuenta=${par#*:}
    for i in $(seq 1 "$POR_CUENTA"); do
      curl -s "${TLS[@]}" -H "Authorization: Bearer ${TOKENS[$usuario]}" "${JSON[@]}" -H "Idempotency-Key: $(uuid)" \
        --data-raw "{\"cuentaOrigen\":$cuenta,\"cuentaDestino\":$DESTINO,\"monto\":1}" \
        "$TRANSFERENCIAS/api/v1/transferencias" > "$dir/$cuenta-$i.json" &
    done
  done
  wait
  IDS=$(python3 -c 'import json,os,sys; d=sys.argv[1]; print(",".join(chr(39) + json.load(open(os.path.join(d, n)))["id"] + chr(39) for n in sorted(os.listdir(d))))' "$dir")
  rm -rf "$dir"
  ACEPTADAS=$(printf '%s' "$IDS" | tr ',' '\n' | grep -c .)
  for _ in $(seq 1 120); do
    TERMINADAS=$(sql "select count(*) from transferencias.transferencia where id in ($IDS) and estado in ('COMPLETADA','RECHAZADA')")
    [ "$TERMINADAS" = "$ACEPTADAS" ] && break
    sleep 0.5
  done
  DURACION=$(sql "select round(extract(epoch from max(actualizada_en) - min(creada_en))::numeric, 2) from transferencias.transferencia where id in ($IDS)")
  COMPLETADAS=$(sql "select count(*) from transferencias.transferencia where id in ($IDS) and estado = 'COMPLETADA'")
}

titulo "Evidencia 12 · Escalabilidad con docker compose --scale: más contenedores de antifraude en el mismo grupo" \
       "Criterio 5: Kafka reparte las particiones entre los contenedores; la misma carga se procesa en menos tiempo."

for i in "${!USUARIOS[@]}"; do token "${USUARIOS[$i]}" && TOKENS[$i]="$TOKEN"; done

paso "Un contenedor de antifraude: un solo consumidor tiene las 3 particiones de cuentas.reservas"
"${COMPOSE[@]}" up -d --scale antifraude-service=1 --no-recreate antifraude-service > /dev/null 2>&1
esperar_consumidores 1
grupo_consumidor antifraude-service
comprobar "consumidores en el grupo antifraude-service" "$(consumidores_antifraude)" "1"
nota "antifraude simula 200 ms de consulta al modelo de riesgo por evento (banco.antifraude.demora-ms del Config Server)"

paso "Carga: 48 transferencias en paralelo desde 6 cuentas, 16 por partición (clave = cuenta de origen)"
UNICO=$(contenedores_antifraude)
ANTES_1=$(decisiones "$UNICO")
carga
DURACION_1="$DURACION"
printf '  aceptadas %s · completadas %s · de la primera solicitud a la última completada: %s s\n' "$ACEPTADAS" "$COMPLETADAS" "$DURACION_1"
printf '  decisiones de %s: %s\n' "$(nombre_corto "$UNICO")" "$(( $(decisiones "$UNICO") - ANTES_1 ))"
comprobar "transferencias completadas con 1 contenedor" "$COMPLETADAS" "48"

paso "docker compose up -d --scale antifraude-service=3: el grupo se rebalancea y cada contenedor toma una partición"
"${COMPOSE[@]}" up -d --scale antifraude-service=3 --no-recreate --wait antifraude-service 2>&1 | grep -E 'antifraude' | awk '{ if (!visto[$0]++) print "  " $0 }' | sed 's/^ *  */  /'
esperar_consumidores 3
grupo_consumidor antifraude-service
comprobar "consumidores en el grupo antifraude-service" "$(consumidores_antifraude)" "3"

paso "La misma carga con tres contenedores"
CONTENEDORES=($(contenedores_antifraude))
ANTES=(); for c in "${CONTENEDORES[@]}"; do ANTES+=("$(decisiones "$c")"); done
carga
DURACION_3="$DURACION"
printf '  aceptadas %s · completadas %s · de la primera solicitud a la última completada: %s s\n' "$ACEPTADAS" "$COMPLETADAS" "$DURACION_3"
REPARTO=""
for i in "${!CONTENEDORES[@]}"; do
  hechas=$(( $(decisiones "${CONTENEDORES[$i]}") - ANTES[$i] ))
  printf '  decisiones de %s: %s\n' "$(nombre_corto "${CONTENEDORES[$i]}")" "$hechas"
  REPARTO="$REPARTO $hechas"
done
comprobar "transferencias completadas con 3 contenedores" "$COMPLETADAS" "48"
comprobar "cada contenedor procesó una partición (16 decisiones)" "$(echo $REPARTO | tr ' ' '\n' | sort | paste -sd' ' -)" "16 16 16"

paso "Comparación de la misma carga"
python3 - "$DURACION_1" "$DURACION_3" <<'PY'
import sys
t1, t3 = float(sys.argv[1]), float(sys.argv[2])
print("  %-12s %-15s %-10s %s" % ("CONTENEDORES", "TRANSFERENCIAS", "SEGUNDOS", "TRANSFERENCIAS/S"))
print("  %-12s %-15s %-10.2f %.1f" % (1, 48, t1, 48 / t1))
print("  %-12s %-15s %-10.2f %.1f" % (3, 48, t3, 48 / t3))
print("  aceleración: %.1fx (el tope es 3x: un contenedor por partición)" % (t1 / t3))
PY
comprobar "3 contenedores terminan antes que 1" \
  "$(python3 -c "print('si' if float('$DURACION_3') < float('$DURACION_1') else 'no')")" "si"

paso "Un contenedor muere sin avisar (SIGKILL) en plena carga: su partición pasa a otro y Docker lo reinicia solo"
VICTIMA="${CONTENEDORES[2]}"
REINICIOS=$(docker inspect -f '{{.RestartCount}}' "$VICTIMA")
PID=$(docker inspect -f '{{.State.Pid}}' "$VICTIMA")
( sleep 1.5; colima ssh -- sudo kill -9 "$PID" ) &
carga
wait
printf '  aceptadas %s · completadas %s · de la primera solicitud a la última completada: %s s\n' "$ACEPTADAS" "$COMPLETADAS" "$DURACION"
nota "a los 1,5 s se mató el proceso Java de $(nombre_corto "$VICTIMA"); Kafka lo dio por caído a los 10 s (session.timeout.ms)"
comprobar "transferencias completadas pese a la caída" "$COMPLETADAS" "48"
for _ in $(seq 1 90); do [ "$(docker inspect -f '{{.State.Health.Status}}' "$VICTIMA")" = "healthy" ] && break; sleep 2; done
comprobar "Docker reinició el contenedor caído" "$(( $(docker inspect -f '{{.RestartCount}}' "$VICTIMA") > REINICIOS ))" "1"
esperar_consumidores 3
grupo_consumidor antifraude-service
comprobar "consumidores en el grupo antifraude-service (el reiniciado volvió)" "$(consumidores_antifraude)" "3"

"${COMPOSE[@]}" up -d --scale antifraude-service=1 --no-recreate antifraude-service > /dev/null 2>&1
esperar_consumidores 1
resumen_final
