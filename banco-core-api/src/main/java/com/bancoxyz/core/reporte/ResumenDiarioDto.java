package com.bancoxyz.core.reporte;

import java.math.BigDecimal;
import java.time.LocalDate;

/** Forma del contrato {@code resumen-diario.json}. */
public record ResumenDiarioDto(LocalDate fecha, long cantidadTransacciones, BigDecimal totalDebitos,
                               BigDecimal totalCreditos, BigDecimal montoMaximo, long cantidadAnomalias,
                               long jobExecutionId) {
}
