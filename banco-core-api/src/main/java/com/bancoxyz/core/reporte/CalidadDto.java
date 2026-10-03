package com.bancoxyz.core.reporte;

import java.util.List;

import com.bancoxyz.core.cierre.CierrePublicado;

/** Forma del contrato {@code calidad.json}. */
public record CalidadDto(List<CierrePublicado> cierres, List<RechazadoDto> rechazados) {
}
