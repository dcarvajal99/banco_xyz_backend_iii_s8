package com.bancoxyz.core.cuenta;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** Forma del contrato {@code cuenta.json}: la cuenta completa, sin recortes de ningun canal. */
public record CuentaDto(long cuentaId, Long clienteId, String titular, String tipo, BigDecimal saldoDisponible,
                        BigDecimal saldoCierre, BigDecimal tasaMensual, BigDecimal interesCierre, boolean anomalia,
                        String observacion, long cierreJobExecutionId, LocalDateTime actualizadaEn) {

    public static CuentaDto desde(Cuenta c) {
        return new CuentaDto(c.getId(), c.getClienteId(), c.getTitular(), c.getTipo(), c.getSaldoDisponible(),
                c.getSaldoCierre(), c.getTasaMensual(), c.getInteresCierre(), c.isAnomalia(), c.getObservacion(),
                c.getCierreJobExecutionId(), c.getActualizadaEn());
    }
}
