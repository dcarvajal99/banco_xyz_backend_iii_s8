package com.bancoxyz.core.cuenta;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Movimiento de una cuenta: del cierre del batch ({@code C-<id>}) o de una operacion en linea ({@code L-<id>}).
 * Los cargos llevan monto negativo, la misma convencion que usa el batch.
 */
public record MovimientoDto(String id, long cuentaId, LocalDate fecha, String tipo, BigDecimal monto,
                            String descripcion, String origen, boolean anomalia, String observacion) {
}
