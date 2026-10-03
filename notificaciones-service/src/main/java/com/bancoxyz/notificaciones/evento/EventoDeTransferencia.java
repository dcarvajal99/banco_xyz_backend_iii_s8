package com.bancoxyz.notificaciones.evento;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;

/**
 * Sobre comun de los eventos de la saga. Viaja como JSON en texto, con el tipo tambien en el encabezado {@code tipo}.
 *
 * <p>Copia del registro del core: no hay libreria compartida, el acuerdo es el formato JSON (README general). Los
 * campos opcionales se omiten cuando no aplican.</p>
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonPropertyOrder({"version", "eventoId", "tipo"})
public record EventoDeTransferencia(String eventoId, String tipo, String transferenciaId, Instant ocurridoEn,
                                    Long clienteId, Long usuarioId, Long cuentaOrigen, Long cuentaDestino,
                                    BigDecimal monto, String validacion, String motivo, BigDecimal saldoOrigen,
                                    int version, String moneda) {

    /** Version del contrato que este servicio produce y la mas nueva que sabe leer (ver {@link LectorDeEventos}). */
    public static final int VERSION_ACTUAL = 2;
    /** Moneda de las cuentas del banco; los eventos v1 no la traian porque siempre era esta. */
    public static final String MONEDA_POR_OMISION = "CLP";

    public static final String SOLICITADA = "TransferenciaSolicitada";
    public static final String FONDOS_RESERVADOS = "FondosReservados";
    public static final String FONDOS_RECHAZADOS = "FondosRechazados";
    public static final String APROBADA = "TransferenciaAprobada";
    public static final String RECHAZADA = "TransferenciaRechazada";
    public static final String COMPLETADA = "TransferenciaCompletada";
    public static final String RESERVA_LIBERADA = "ReservaLiberada";

    /** Evento nuevo en la version actual del contrato y en la moneda del banco. */
    public EventoDeTransferencia(String eventoId, String tipo, String transferenciaId, Instant ocurridoEn, Long clienteId,
                                 Long usuarioId, Long cuentaOrigen, Long cuentaDestino, BigDecimal monto, String validacion,
                                 String motivo, BigDecimal saldoOrigen) {
        this(eventoId, tipo, transferenciaId, ocurridoEn, clienteId, usuarioId, cuentaOrigen, cuentaDestino, monto,
                validacion, motivo, saldoOrigen, VERSION_ACTUAL, MONEDA_POR_OMISION);
    }

    /** Evento siguiente de la misma transferencia: nuevo id, mismos datos de la transferencia. */
    public EventoDeTransferencia siguiente(String nuevoTipo, Instant ahora, String nuevoMotivo, BigDecimal saldo) {
        return new EventoDeTransferencia(UUID.randomUUID().toString(), nuevoTipo, transferenciaId, ahora, clienteId,
                usuarioId, cuentaOrigen, cuentaDestino, monto, null, nuevoMotivo, saldo, VERSION_ACTUAL, moneda);
    }

    /** Clave de Kafka: la cuenta de origen. Todos los eventos de una cuenta caen en la misma particion, en orden. */
    public String clave() {
        return String.valueOf(cuentaOrigen);
    }
}
