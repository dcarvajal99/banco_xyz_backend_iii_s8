#!/usr/bin/env bash
# Evidencia 07 - Resilience4j con decoradores programaticos (Decorators: CircuitBreaker + Retry) en la publicacion del
# outbox. Se detiene el broker: la API sigue aceptando, los eventos esperan en el outbox y el circuito "kafka" abre.
# Al volver el broker el outbox se vacia en orden y la saga termina. Detiene y vuelve a levantar el contenedor kafka
# del compose; la politica es la del entorno nube (Config Server).
set -uo pipefail
source "$(dirname "$0")/lib.sh"
if [ "${1:-}" = "-h" ]; then sed -n '2,4p' "$0"; exit 0; fi
# Aunque el script se corte a mitad de camino, el ecosistema queda como estaba.
trap '"${COMPOSE[@]}" start kafka > /dev/null 2>&1' EXIT
LOG_TRANSFERENCIAS="$RAIZ_PROYECTO/evidencias/logs/transferencias-service.log"

pendientes() { sql "select count(*) from transferencias.outbox where publicado_en is null"; }

eventos_reintento() {
  curl -s "http://127.0.0.1:$1/actuator/retryevents/$2" | python3 -c "
import sys, json
for e in json.load(sys.stdin)['retryEvents'][-${3:-4}:]:
    print('  %s %-6s intento %s  %s' % (e['creationTime'][11:23], e['type'], e['numberOfAttempts'], (e.get('errorMessage') or '')[:80]))"
}

titulo "Evidencia 07 · Resilience4j en la publicación a Kafka (decoradores programáticos)" \
       "Criterio 4: sin broker no se pierde ninguna transferencia; el outbox las guarda y el circuito evita insistir."

paso "Estado inicial: circuito 'kafka' cerrado y outbox de transferencias-service sin pendientes"
mostrar_circuito 9082 kafka transferencias-service
comprobar "circuito kafka" "$(circuito 9082 kafka)" "CLOSED"
comprobar "eventos pendientes en transferencias.outbox" "$(pendientes)" "0"
token steve.rogers
SALDO_140=$(saldo 140)
nota "token de steve.rogers emitido · saldo disponible de la cuenta 140 = $SALDO_140"

paso "Se detiene el broker Kafka"
"${COMPOSE[@]}" stop kafka 2>&1 | grep -E "Stopped" | sed "s/^ */  /"
KAFKA_ID=$("${COMPOSE[@]}" ps -a -q kafka)
comprobar "contenedor kafka" "$(docker inspect -f '{{.State.Status}}' "$KAFKA_ID")" "exited"

paso "La API sigue aceptando: cada transferencia y su evento se guardan en la misma transacción (outbox)"
KAFKA_CAIDO=()
for monto in 110 120 130; do
  transferir 140 131 "$monto"
  KAFKA_CAIDO+=("$TRANSFERENCIA")
done
comprobar "respuestas 202 con Kafka caído" "$(for id in "${KAFKA_CAIDO[@]}"; do [ -n "$id" ] && echo x; done | wc -l | tr -d ' ')" "3"
tabla_sql "select id, topico, clave, tipo, creado_en, publicado_en from transferencias.outbox where publicado_en is null order by id"
comprobar "eventos pendientes en transferencias.outbox" "$(pendientes)" "3"

paso "El publicador reintenta (Retry) y el circuito 'kafka' abre: mientras está abierto no insiste"
for _ in $(seq 1 30); do [ "$(circuito 9082 kafka)" = "OPEN" ] && break; sleep 1; done
mostrar_circuito 9082 kafka transferencias-service
comprobar "circuito kafka" "$(circuito 9082 kafka)" "OPEN"
nota "/actuator/retryevents/kafka (últimos):"
eventos_reintento 9082 kafka 3
nota "/actuator/circuitbreakerevents/kafka (últimos):"
eventos_circuito 9082 kafka 5
grep -a "Circuito kafka" "$LOG_TRANSFERENCIAS" | tail -1 | cut -c1-140 | sed 's/^/  log: /'
for id in "${KAFKA_CAIDO[@]}"; do
  comprobar "estado de ${id:0:8} mientras Kafka está caído" "$(sql "select estado from transferencias.transferencia where id = '$id'")" "PENDIENTE"
done

paso "Vuelve Kafka: el circuito deja pasar una prueba (HALF_OPEN), se cierra y el outbox se vacía en orden"
"${COMPOSE[@]}" start kafka > /dev/null 2>&1
for _ in $(seq 1 60); do
  [ "$(docker inspect -f '{{.State.Health.Status}}' "$KAFKA_ID")" = "healthy" ] && break
  sleep 1
done
nota "broker de vuelta: $(docker inspect -f '{{.State.Health.Status}}' "$KAFKA_ID")"
for _ in $(seq 1 60); do [ "$(pendientes)" = "0" ] && break; sleep 1; done
comprobar "eventos pendientes en transferencias.outbox" "$(pendientes)" "0"
for id in "${KAFKA_CAIDO[@]}"; do
  seguir_transferencia "$id" 60 > /dev/null
  comprobar "transferencia ${id:0:8}" "$ESTADO_TRANSFERENCIA" "COMPLETADA"
done
comprobar "saldo de la cuenta 140" "$(saldo 140)" "$(python3 -c "from decimal import Decimal as D; print(D('$SALDO_140') - 360)")"
eventos_circuito 9082 kafka 30 | grep STATE_TRANSITION | tail -3
comprobar "circuito kafka" "$(circuito 9082 kafka)" "CLOSED"

resumen_final
