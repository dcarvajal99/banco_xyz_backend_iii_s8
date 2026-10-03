#!/usr/bin/env bash
# Evidencia 11 - Eventos versionados y entrega "al menos una vez" (observacion 2 de la semana 7).
# Duplicados (mismo y otro eventoId) sin efecto doble; un evento v1 (productor de la semana 7, sin version ni moneda) se
# procesa como v2; una version futura y un mensaje ilegible van a la DLT. Requiere el ecosistema arriba.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
if [ "${1:-}" = "-h" ]; then sed -n '2,4p' "$0"; exit 0; fi

titulo "Evidencia 11 · Eventos versionados: duplicados, versiones anteriores, versiones futuras y la DLT" \
       "Criterio 5 y observación 2 de la semana 7: el contrato del evento evoluciona sin romper a los consumidores."

paso "Transferencia de referencia: diana.prince envía \$100 de la cuenta 101 a la 131 y la saga termina"
token diana.prince
transferir 101 131 100
REFERENCIA="$TRANSFERENCIA"
seguir_transferencia "$REFERENCIA" > /dev/null
comprobar "estado final" "$ESTADO_TRANSFERENCIA" "COMPLETADA"
SOLICITUD=$(leer_topico transferencias.solicitadas | grep "$REFERENCIA" | head -1 | cut -f4-)
EVENTO_ID=$(campo eventoId "$SOLICITUD")
nota "evento original en transferencias.solicitadas: eventoId $EVENTO_ID · version $(campo version "$SOLICITUD")"
SALDO_101=$(saldo 101); SALDO_131=$(saldo 131)
nota "saldo disponible después de la saga: cuenta 101 = $SALDO_101 · cuenta 131 = $SALDO_131"

paso "Se publica de nuevo el MISMO evento (mismo eventoId): el core lo reconoce y no vuelve a retener"
publicar_crudo transferencias.solicitadas 101 "$SOLICITUD"
nota "publicado otra vez en transferencias.solicitadas con clave 101"
sleep 3
"${COMPOSE[@]}" logs --no-log-prefix banco-core-api 2>/dev/null | grep -a "duplicado (evento $EVENTO_ID)" | tail -1 \
  | sed -E 's/^[0-9:.]+ +INFO +\[[^]]*\] +(\[\] +)?//; s/^/  log del core: /' | cut -c1-140
comprobar "veces registrado en core.evento_procesado" "$(sql "select count(*) from core.evento_procesado where evento_id = '$EVENTO_ID'")" "1"
comprobar "reservas de la transferencia" "$(sql "select count(*) from core.reserva where transferencia_id = '$REFERENCIA'")" "1"
comprobar "saldo de la cuenta 101 sin cambios" "$(saldo 101)" "$SALDO_101"

paso "Se publica la misma transferencia con OTRO eventoId (reintento del productor): tampoco se duplica"
NUEVO_ID=$(uuid)
OTRO=$(printf '%s' "$SOLICITUD" | python3 -c "import json,sys; e=json.load(sys.stdin); e['eventoId']='$NUEVO_ID'; print(json.dumps(e))")
publicar_crudo transferencias.solicitadas 101 "$OTRO"
nota "eventoId nuevo $NUEVO_ID, mismo transferenciaId ${REFERENCIA:0:8}"
sleep 3
comprobar "el core registró el evento nuevo" "$(sql "select count(*) from core.evento_procesado where evento_id = '$NUEVO_ID'")" "1"
comprobar "pero la reserva sigue siendo una (clave primaria = transferenciaId)" \
  "$(sql "select count(*) from core.reserva where transferencia_id = '$REFERENCIA'")" "1"
comprobar "saldo de la cuenta 101 sin cambios" "$(saldo 101)" "$SALDO_101"
comprobar "saldo de la cuenta 131 sin cambios" "$(saldo 131)" "$SALDO_131"
comprobar "estado de la transferencia" "$(sql "select estado from transferencias.transferencia where id = '$REFERENCIA'")" "COMPLETADA"

paso "Evento v1 de un productor sin actualizar (sin version ni moneda): antifraude lo lee como v2 y publica su decisión en v2"
V1_ID=$(uuid)
V1=$(python3 -c 'import json,sys,uuid; print(json.dumps({"eventoId":str(uuid.uuid4()),"tipo":"FondosReservados","transferenciaId":sys.argv[1],"ocurridoEn":"2026-09-24T14:03:29Z","clienteId":7,"usuarioId":7,"cuentaOrigen":141,"cuentaDestino":131,"monto":100,"saldoOrigen":7940.00}))' "$V1_ID")
publicar_crudo cuentas.reservas 141 "$V1"
nota "publicado en cuentas.reservas: $V1" 
sleep 4
DECISION=$(leer_topico antifraude.decisiones | grep "$V1_ID" | tail -1 | cut -f4-)
printf '  decisión de antifraude: tipo %s · version %s · moneda %s · transferenciaId %s…\n' "$(campo tipo "$DECISION")" \
  "$(campo version "$DECISION")" "$(campo moneda "$DECISION")" "${V1_ID:0:8}"
comprobar "antifraude procesó el v1 y respondió en la versión actual" "$(campo tipo "$DECISION") v$(campo version "$DECISION") $(campo moneda "$DECISION")" "TransferenciaAprobada v2 CLP"
nota "el core ignora la decisión: esa reserva no existe (era solo para mostrar la lectura del v1)"

paso "Evento de una versión futura (v3) o ilegible: va a la DLT sin reintentos y la partición sigue avanzando"
ANTES_DLT=$(leer_topico transferencias.solicitadas.DLT 3 | grep -c "Partition:")
V3=$(printf '%s' "$SOLICITUD" | python3 -c "import json,sys,uuid; e=json.load(sys.stdin); e['version']=3; e['eventoId']=str(uuid.uuid4()); print(json.dumps(e))")
publicar_crudo transferencias.solicitadas 101 "$V3"
publicar_crudo transferencias.solicitadas 101 "esto-no-es-json"
nota "publicados con clave 101: un TransferenciaSolicitada con version 3 y el texto 'esto-no-es-json'"
sleep 4
"${KAFKA_CLI[@]}" /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 \
  --topic transferencias.solicitadas.DLT --from-beginning --timeout-ms 4000 --property print.headers=true \
  --property print.partition=true --property print.offset=true 2>/dev/null | python3 -c '
import re, sys
# El stacktrace viaja en un encabezado y trae saltos de linea: cada registro empieza con "Partition:N<tab>Offset:M".
registros = [r for r in re.split(r"(?m)^(?=Partition:\d+\tOffset:\d+\t)", sys.stdin.read()) if r.startswith("Partition:")]
for registro in registros[-2:]:
    particion, offset, resto = registro.rstrip("\n").split("\t", 2)
    valor = resto.rsplit("\t", 1)[1]
    m = re.search(r"kafka_dlt-exception-cause-fqcn:([^,\n]*)", resto)
    print("  DLT %s %s · causa %s" % (particion.replace("Partition:", "partición "), offset.replace("Offset:", "offset "),
          (m.group(1) if m else "-").rsplit(".", 1)[-1]))
    print("      valor: %s" % (valor[:96] + ("…" if len(valor) > 96 else "")))'
comprobar "mensajes nuevos en la DLT" "$(( $(leer_topico transferencias.solicitadas.DLT 3 | grep -c "Partition:") - ANTES_DLT ))" "2"
"${COMPOSE[@]}" logs --no-log-prefix banco-core-api 2>/dev/null | grep -aoE "Version 3 del evento no soportada[^:]*: este servicio entiende hasta la [0-9]" | tail -1 | sed 's/^/  log del core: /'
transferir 101 131 50
seguir_transferencia "$TRANSFERENCIA" > /dev/null
comprobar "una transferencia posterior por la misma partición se completa" "$ESTADO_TRANSFERENCIA" "COMPLETADA"

resumen_final
