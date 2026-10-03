package com.bancoxyz.core.cuenta;

import java.math.BigDecimal;
import java.time.LocalDate;

/** Forma del contrato {@code estados-anuales.json}. */
public record EstadoAnualDto(long cuentaId, int anio, long cantidadMovimientos, BigDecimal totalDepositos,
                             BigDecimal totalCargos, BigDecimal saldoNeto, LocalDate primeraFecha,
                             LocalDate ultimaFecha, long movimientosConAnomalia) {
}
