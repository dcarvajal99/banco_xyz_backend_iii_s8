#!/usr/bin/env bash
# Evidencia 06 - Resilience4j con anotaciones (@Bulkhead + @CircuitBreaker + @Retry con fallback) en las llamadas HTTP al
# core, con la politica del entorno nube que entrega el Config Server (minimo 5 llamadas, 15 s abierto, 3 de prueba).
# Se detiene el contenedor banco-core-api: transferencias-service sigue aceptando (validacion DIFERIDA) y el login de
# banco-auth avisa que el servicio no esta disponible; ambos circuitos abren. Al volver el core, la saga procesa lo que
# espero en Kafka y los circuitos se cierran solos.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
if [ "${1:-}" = "-h" ]; then sed -n '2,6p' "$0"; exit 0; fi
# Aunque el script se corte a mitad de camino, el core queda arriba (start no hace nada si ya corre).
trap '"${COMPOSE[@]}" start banco-core-api > /dev/null 2>&1' EXIT

lag_core() {
  "${KAFKA_CLI[@]}" /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server kafka:9092 --describe \
    --group banco-core-api 2>/dev/null | awk '$2 == "transferencias.solicitadas" && $6 ~ /^[0-9]+$/ {s += $6} END {print s + 0}'
}

# login_directo USUARIO: solo el formulario de banco-auth (sin el resto del flujo); deja el destino de la redireccion.
login_directo() {
  local jar csrf
  jar=$(mktemp)
  csrf=$(curl -s -c "$jar" -b "$jar" "${TLS[@]}" "$AUTH/login" | sed -n 's/.*name="_csrf" value="\([^"]*\)".*/\1/p')
  DESTINO_LOGIN=$(curl -s -o /dev/null -w '%{redirect_url}' -c "$jar" -b "$jar" "${TLS[@]}" "$AUTH/login" \
    --data-urlencode "username=$1" --data-urlencode "password=$CLAVE_CLIENTES" --data-urlencode "_csrf=$csrf")
  rm -f "$jar"
}

titulo "Evidencia 06 · Resilience4j en las llamadas HTTP al core (anotaciones), política del entorno nube" \
       "Criterio 4: el sistema sigue respondiendo con el core caído y se recupera solo cuando vuelve."

paso "Estado inicial: circuitos core cerrados. Los clientes obtienen su token mientras el core está arriba"
token diana.prince; TOKEN_DIANA=("${BEARER[@]}")
token steve.rogers; TOKEN_STEVE=("${BEARER[@]}")
nota "tokens OAuth de diana.prince y steve.rogers emitidos (se validan con el JWK Set, sin consultar al core)"
mostrar_circuito 9082 core transferencias-service
mostrar_circuito 9081 core banco-auth
comprobar "circuito core en transferencias-service" "$(circuito 9082 core)" "CLOSED"
comprobar "circuito core en banco-auth" "$(circuito 9081 core)" "CLOSED"

paso "Se detiene el contenedor banco-core-api: se da de baja en Eureka y deja de responder"
"${COMPOSE[@]}" stop banco-core-api 2>&1 | grep -E "Stopped" | sed 's/^ */  /'
for _ in $(seq 1 30); do
  instancias=$(curl -s -H 'Accept: application/json' "$EUREKA1/eureka/apps/BANCO-CORE-API" | grep -c '"instanceId"')
  [ "$instancias" = "0" ] && break
  sleep 1
done
comprobar "instancias de banco-core-api en Eureka" "$instancias" "0"
sleep 11
nota "11 s después: las copias del catálogo (5 s) y de LoadBalancer (5 s) de los clientes tampoco lo ven"

paso "transferencias-service acepta igual (fallback: validación DIFERIDA); a la quinta falla el circuito abre"
BEARER=("${TOKEN_STEVE[@]}")
DIFERIDAS=()
for monto in 101 102 103 104 105 106; do
  SIN_CUERPO=2 llamar POST "$TRANSFERENCIAS/api/v1/transferencias" "${BEARER[@]}" "${JSON[@]}" -H "Idempotency-Key: $(uuid)" \
    --data-raw "{\"cuentaOrigen\":137,\"cuentaDestino\":131,\"monto\":$monto}" > /dev/null
  DIFERIDAS+=("$(campo id)")
  printf '  POST $%s → HTTP %s · validacion %s · circuito %s\n' "$monto" "$ESTADO" "$(campo validacion)" "$(circuito 9082 core)"
done
BEARER=("${TOKEN_DIANA[@]}")
SIN_CUERPO=2 llamar POST "$TRANSFERENCIAS/api/v1/transferencias" "${BEARER[@]}" "${JSON[@]}" -H "Idempotency-Key: $(uuid)" \
  --data-raw '{"cuentaOrigen":137,"cuentaDestino":131,"monto":700}' > /dev/null
AJENA=$(campo id)
printf '  diana.prince usa la cuenta 137 de steve.rogers → HTTP %s · validacion %s (sin core no se puede comprobar ahora)\n' "$ESTADO" "$(campo validacion)"
mostrar_circuito 9082 core transferencias-service
comprobar "circuito core en transferencias-service" "$(circuito 9082 core)" "OPEN"
comprobar "solicitudes aceptadas con validación DIFERIDA" "$(sql "select count(*) from transferencias.transferencia where validacion='DIFERIDA' and id in ($(printf "'%s'," "${DIFERIDAS[@]}" "$AJENA" | sed 's/,$//'))")" "7"

paso "Eventos del circuito de transferencias-service (/actuator/circuitbreakerevents/core)"
eventos_circuito 9082 core 9
comprobar "solicitudes esperando en transferencias.solicitadas (lag del grupo banco-core-api)" "$(lag_core)" "7"

paso "banco-auth sin core no puede verificar claves: el login avisa servicio no disponible y su circuito abre"
for i in 1 2 3 4 5 6; do
  login_directo steve.rogers
  printf '  login %s → %s · circuito %s\n' "$i" "${DESTINO_LOGIN#"$AUTH"}" "$(circuito 9081 core)"
done
comprobar "destino del último intento" "${DESTINO_LOGIN#"$AUTH"}" "/login?error=servicio"
comprobar "circuito core en banco-auth" "$(circuito 9081 core)" "OPEN"
eventos_circuito 9081 core 3

paso "Vuelve el core: lee de Kafka las solicitudes que esperaban y las valida en la saga"
"${COMPOSE[@]}" start banco-core-api > /dev/null 2>&1
CORE_ID=$("${COMPOSE[@]}" ps -q banco-core-api)
for _ in $(seq 1 90); do [ "$(docker inspect -f '{{.State.Health.Status}}' "$CORE_ID")" = "healthy" ] && break; sleep 2; done
nota "banco-core-api: $(docker inspect -f '{{.State.Health.Status}}' "$CORE_ID")"
BEARER=("${TOKEN_STEVE[@]}")
completadas=0
for id in "${DIFERIDAS[@]}"; do
  seguir_transferencia "$id" 60 > /dev/null
  [ "$ESTADO_TRANSFERENCIA" = "COMPLETADA" ] && completadas=$((completadas + 1))
done
printf '  transferencias diferidas completadas: %s de %s\n' "$completadas" "${#DIFERIDAS[@]}"
comprobar "diferidas completadas" "$completadas" "6"
BEARER=("${TOKEN_DIANA[@]}")
seguir_transferencia "$AJENA" 60 > /dev/null
comprobar "la de cuenta ajena la rechaza el core en la saga" \
  "$(sql "select estado || ' ' || motivo from transferencias.transferencia where id = '$AJENA'")" "RECHAZADA CUENTA_AJENA"
comprobar "lag del grupo banco-core-api" "$(lag_core)" "0"

paso "Los circuitos se cierran solos: pasado el tiempo de espera (15 s) dejan pasar 3 llamadas de prueba"
sleep 6
BEARER=("${TOKEN_STEVE[@]}")
for i in 1 2 3; do
  SIN_CUERPO=2 llamar POST "$TRANSFERENCIAS/api/v1/transferencias" "${BEARER[@]}" "${JSON[@]}" -H "Idempotency-Key: $(uuid)" \
    --data-raw '{"cuentaOrigen":137,"cuentaDestino":131,"monto":10}' > /dev/null
  printf '  prueba %s → HTTP %s · validacion %s · circuito %s\n' "$i" "$ESTADO" "$(campo validacion)" "$(circuito 9082 core)"
done
for i in 1 2 3; do login_directo steve.rogers; done
nota "banco-auth: tres inicios de sesión de prueba → ${DESTINO_LOGIN#"$AUTH"}"
mostrar_circuito 9082 core transferencias-service
mostrar_circuito 9081 core banco-auth
eventos_circuito 9082 core 40 | grep STATE_TRANSITION | tail -3
comprobar "circuito core en transferencias-service" "$(circuito 9082 core)" "CLOSED"
comprobar "circuito core en banco-auth" "$(circuito 9081 core)" "CLOSED"

resumen_final
