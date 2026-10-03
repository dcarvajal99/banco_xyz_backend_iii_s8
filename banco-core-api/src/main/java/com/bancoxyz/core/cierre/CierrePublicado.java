package com.bancoxyz.core.cierre;

import java.time.LocalDateTime;

/**
 * Ejecucion del batch que el core publica para un conjunto de datos.
 *
 * @param calidad {@code DEGRADADA} si esa ejecucion paso por la cuarentena de aviso; si no, {@code ACEPTABLE}
 */
public record CierrePublicado(Conjunto conjunto, long jobExecutionId, String jobNombre, String estado,
                              String calidad, LocalDateTime finalizadoEn) {
}
