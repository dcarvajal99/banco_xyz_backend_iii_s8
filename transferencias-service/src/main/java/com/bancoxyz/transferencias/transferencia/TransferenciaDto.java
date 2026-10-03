package com.bancoxyz.transferencias.transferencia;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;

/** Respuesta de la API: el estado actual y la traza de la saga. */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record TransferenciaDto(String id, String estado, String motivo, String validacion, Long cuentaOrigen,
                               Long cuentaDestino, BigDecimal monto, LocalDateTime creadaEn, LocalDateTime actualizadaEn,
                               List<Paso> historial) {

    public record Paso(String evento, String detalle, LocalDateTime ocurridoEn) {
    }

    static TransferenciaDto desde(Transferencia t, List<PasoDelHistorial> pasos) {
        return new TransferenciaDto(t.getId(), t.getEstado().name(), t.getMotivo(), t.getValidacion().name(),
                t.getCuentaOrigen(), t.getCuentaDestino(), t.getMonto(), t.getCreadaEn(), t.getActualizadaEn(),
                pasos.stream().map(p -> new Paso(p.getEvento(), p.getDetalle(), p.getOcurridoEn())).toList());
    }
}
