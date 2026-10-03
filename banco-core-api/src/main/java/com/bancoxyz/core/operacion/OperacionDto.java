package com.bancoxyz.core.operacion;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** Forma del contrato {@code operacion-retiro.json}. */
public record OperacionDto(long operacionId, long cuentaId, Long tarjetaId, String tipo, String canal,
                           BigDecimal monto, BigDecimal saldoResultante, String terminalId, LocalDateTime fechaHora) {

    public static OperacionDto desde(Operacion o) {
        return new OperacionDto(o.getId(), o.getCuentaId(), o.getTarjetaId(), o.getTipo(), o.getCanal(), o.getMonto(),
                o.getSaldoResultante(), o.getTerminalId(), o.getCreadaEn());
    }
}
