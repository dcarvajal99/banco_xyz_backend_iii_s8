#!/usr/bin/env bash
# Evidencia 09 - Los topicos de la saga en el broker, quien los consume y como viaja un evento (version 2 del sobre).
# Requiere el ecosistema arriba (docker compose up -d) y al menos una transferencia hecha.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
if [ "${1:-}" = "-h" ]; then sed -n '2,3p' "$0"; exit 0; fi

titulo "Evidencia 09 · Kafka: tópicos, grupos de consumidores y sobre del evento" \
       "Criterio 5: la mensajería asíncrona funciona en el broker del compose; cada servicio consume en su grupo."

paso "Tópicos creados por los servicios: 3 particiones cada uno y su DLT para mensajes que fallan"
kafka_topicos --describe 2>/dev/null | awk -F'\t' '/PartitionCount/ && $1 !~ /__consumer_offsets/ {
  sub("Topic: ", "", $1); sub("PartitionCount: ", "", $3); sub("ReplicationFactor: ", "", $4);
  printf "  %-32s particiones=%s  replicas=%s\n", $1, $3, $4 }' | sort
for topico in transferencias.solicitadas cuentas.reservas antifraude.decisiones cuentas.transferencias; do
  particiones=$(kafka_topicos --describe --topic "$topico" 2>/dev/null | awk -F'\t' '/PartitionCount/ {sub("PartitionCount: ", "", $3); print $3}')
  dlt=$(kafka_topicos --list 2>/dev/null | grep -cx "$topico.DLT")
  comprobar "$topico: particiones y DLT" "$particiones particiones, DLT=$dlt" "3 particiones, DLT=1"
done
nota "auto.create.topics.enable=false en el broker: un nombre mal escrito falla en vez de crear un tópico nuevo."

paso "Grupos de consumidores: cada servicio lee sus tópicos en su propio grupo (cada grupo recibe todos los eventos)"
grupo_consumidor banco-core-api transferencias-service antifraude-service notificaciones-service
for par in banco-core-api:transferencias.solicitadas banco-core-api:antifraude.decisiones \
           transferencias-service:cuentas.reservas transferencias-service:cuentas.transferencias \
           antifraude-service:cuentas.reservas notificaciones-service:cuentas.reservas \
           notificaciones-service:cuentas.transferencias; do
  grupo=${par%%:*}; topico=${par#*:}
  n=$("${KAFKA_CLI[@]}" /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server kafka:9092 \
      --describe --group "$grupo" 2>/dev/null | awk -v t="$topico" '$2 == t' | wc -l | tr -d ' ')
  comprobar "$grupo suscrito a $topico (particiones asignadas)" "$n" "3"
done

paso "Sobre de un evento tal como viaja: clave = cuenta de origen (fija la partición), versión 2 del contrato y moneda"
ULTIMO=$("${KAFKA_CLI[@]}" /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 \
  --topic cuentas.reservas --from-beginning --timeout-ms 4000 --property print.partition=true \
  --property print.key=true --property print.headers=true 2>/dev/null | grep FondosReservados | tail -1)
printf '%s\n' "$ULTIMO" | python3 -c '
import json, sys
linea = sys.stdin.read().rstrip("\n")
particion, encabezados, clave, valor = linea.split("\t", 3)
print("  topico cuentas.reservas · %s · clave %s" % (particion.replace("Partition:", "particion "), clave))
print("  encabezados: %s" % encabezados)
for renglon in json.dumps(json.loads(valor), indent=2, ensure_ascii=False).splitlines():
    print("  " + renglon)'
comprobar "el sobre trae eventoId, tipo y transferenciaId" \
  "$(printf '%s' "${ULTIMO#*$'\t'*$'\t'*$'\t'}" | python3 -c 'import json,sys; e=json.load(sys.stdin); print(all(e.get(k) for k in ("eventoId","tipo","transferenciaId")))')" "True"

comprobar "versión del contrato en el evento" "$(printf '%s' "${ULTIMO#*$'\t'*$'\t'*$'\t'}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("version"))')" "2"

resumen_final
