#!/usr/bin/env bash
# Evidencia 10 - Saga coreografiada de una transferencia entre cuentas, de punta a punta sobre Kafka:
# camino feliz, rechazo de antifraude con compensacion, rechazos del core y validaciones previas a la saga.
# Requiere el ecosistema arriba (docker compose up -d). Los saldos se leen antes y despues: no se asumen.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
if [ "${1:-}" = "-h" ]; then sed -n '2,4p' "$0"; exit 0; fi

suma() { python3 -c "from decimal import Decimal as D; print(D('$1') + D('$2'))"; }

# tipos_de_eventos ID: los tipos de evento de la transferencia en orden, separados por " > ".
tipos_de_eventos() {
  eventos_de_transferencia "$1" | awk 'NR > 1 && !/^  \(/ {print $1}' | paste -sd'>' - | sed 's/>/ > /g'
}

titulo "Evidencia 10 · Saga coreografiada de transferencias sobre Kafka, en contenedores" \
       "Criterio 5: cada servicio reacciona a un evento y publica el siguiente; los tokens son OAuth 2.0."

paso "Camino feliz: diana.prince transfiere \$1.500 de su cuenta de ahorro 101 a la cuenta 131"
ORIGEN_ANTES=$(saldo 101); DESTINO_ANTES=$(saldo 131)
nota "saldo disponible antes: cuenta 101 = $ORIGEN_ANTES · cuenta 131 = $DESTINO_ANTES"
token diana.prince
COMPLETO=1 transferir 101 131 1500
esperar 202
FELIZ="$TRANSFERENCIA"
comprobar "responde antes de que termine la saga (estado inicial)" "$(campo estado)" "PENDIENTE"
comprobar "el core confirmo por HTTP que la cuenta es del usuario" "$(campo validacion)" "PREVIA"

paso "La saga termina sola: COMPLETADA, y el core movio los saldos"
seguir_transferencia "$FELIZ"
comprobar "estado final" "$ESTADO_TRANSFERENCIA" "COMPLETADA"
comprobar "saldo de la cuenta 101" "$(saldo 101)" "$(suma "$ORIGEN_ANTES" -1500)"
comprobar "saldo de la cuenta 131" "$(saldo 131)" "$(suma "$DESTINO_ANTES" 1500)"

paso "Los cuatro eventos de esa transferencia en Kafka: misma clave (cuenta 101) → misma partición → en orden"
eventos_de_transferencia "$FELIZ"
comprobar "cadena de eventos" "$(tipos_de_eventos "$FELIZ")" \
  "TransferenciaSolicitada > FondosReservados > TransferenciaAprobada > TransferenciaCompletada"
comprobar "particiones distintas usadas por la transferencia" \
  "$(eventos_de_transferencia "$FELIZ" | awk 'NR > 1 && !/^  \(/ {print $3}' | sort -u | wc -l | tr -d ' ')" "1"

paso "Antifraude rechaza (\$6.000 supera el límite de \$5.000) y el core compensa devolviendo la retención"
SALDO_137=$(saldo 137)
nota "saldo disponible antes: cuenta 137 = $SALDO_137 (steve.rogers)"
token steve.rogers
transferir 137 131 6000
esperar 202
COMPENSADA="$TRANSFERENCIA"
seguir_transferencia "$COMPENSADA"
comprobar "estado final" "$ESTADO_TRANSFERENCIA" "RECHAZADA"
comprobar "motivo" "$(sql "select motivo from transferencias.transferencia where id = '$COMPENSADA'")" "MONTO_SOBRE_LIMITE"
comprobar "saldo de la cuenta 137 despues de compensar" "$(saldo 137)" "$SALDO_137"

paso "Eventos de la compensación y estado de la reserva en el core"
eventos_de_transferencia "$COMPENSADA"
comprobar "cadena de eventos" "$(tipos_de_eventos "$COMPENSADA")" \
  "TransferenciaSolicitada > FondosReservados > TransferenciaRechazada > ReservaLiberada"
tabla_sql "select left(transferencia_id, 8) as transferencia, cuenta_origen, monto, estado, motivo
           from core.reserva where transferencia_id in ('$FELIZ', '$COMPENSADA') order by creada_en"
comprobar "reserva compensada" "$(sql "select estado from core.reserva where transferencia_id = '$COMPENSADA'")" "LIBERADA"

paso "Antifraude rechaza por cuenta en observación (destino 104, regla leída del Config Server)"
SALDO_141=$(saldo 141)
transferir 141 104 800
OBSERVADA="$TRANSFERENCIA"
seguir_transferencia "$OBSERVADA"
comprobar "motivo" "$(sql "select estado || ' ' || motivo from transferencias.transferencia where id = '$OBSERVADA'")" \
  "RECHAZADA CUENTA_EN_OBSERVACION"
comprobar "saldo de la cuenta 141 sin cambios" "$(saldo 141)" "$SALDO_141"

paso "El core rechaza sin retener nada: saldo insuficiente y cuenta de préstamo (no admite retiros)"
token diana.prince
transferir 101 131 90000
SIN_SALDO="$TRANSFERENCIA"
transferir 103 131 100
PRESTAMO="$TRANSFERENCIA"
seguir_transferencia "$SIN_SALDO" > /dev/null
seguir_transferencia "$PRESTAMO" > /dev/null
tabla_sql "select left(id, 8) as transferencia, cuenta_origen, monto, estado, motivo
           from transferencias.transferencia where id in ('$SIN_SALDO', '$PRESTAMO') order by creada_en"
comprobar "saldo insuficiente: eventos (antifraude no interviene)" "$(tipos_de_eventos "$SIN_SALDO")" \
  "TransferenciaSolicitada > FondosRechazados"
comprobar "cuenta de préstamo" "$(sql "select motivo from transferencias.transferencia where id = '$PRESTAMO'")" \
  "CUENTA_NO_ADMITE_RETIROS"

paso "Validaciones antes de la saga: cuenta ajena, misma cuenta, sin token e Idempotency-Key repetida"
transferir 137 131 100
esperar 404 CUENTA_ORIGEN_NO_ENCONTRADA
transferir 101 101 100
esperar 422 MISMA_CUENTA
SIN_CUERPO=1 llamar POST "$TRANSFERENCIAS/api/v1/transferencias" "${JSON[@]}" -H "Idempotency-Key: $(uuid)" \
  --data-raw '{"cuentaOrigen":101,"cuentaDestino":131,"monto":100}'
esperar 401
CLAVE=$(uuid)
transferir 101 131 200 "$CLAVE"
PRIMERA="$TRANSFERENCIA"
transferir 101 131 200 "$CLAVE"
esperar 200
comprobar "reintento con la misma clave devuelve la misma transferencia" "$TRANSFERENCIA" "$PRIMERA"
comprobar "Idempotency-Replayed" "$(encabezado Idempotency-Replayed)" "true"
comprobar "transferencias guardadas con esa clave" \
  "$(sql "select count(*) from transferencias.transferencia where clave_idempotencia = '$CLAVE'")" "1"

paso "notificaciones-service avisó a cada cliente del resultado (consume cuentas.reservas y cuentas.transferencias)"
seguir_transferencia "$PRIMERA" > /dev/null
token steve.rogers
SIN_CUERPO=2 llamar GET "$NOTIFICACIONES/api/v1/notificaciones" "${BEARER[@]}"
printf '%s' "$CUERPO" | python3 -c '
import json, sys
for n in json.load(sys.stdin):
    print("  %-24s %s" % (n["tipo"], n["texto"]))'
AVISADAS=$(printf '%s' "$CUERPO" | grep -oE "$COMPENSADA|$OBSERVADA" | sort -u | wc -l | tr -d ' ')
comprobar "avisos de steve.rogers sobre sus dos transferencias rechazadas" "$AVISADAS" "2"

resumen_final
