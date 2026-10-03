package com.bancoxyz.core.reporte;

/** Filas del cierre que el batch dejo fuera, agrupadas. clasificacion: OMITIDO o FILTRADO. */
public record RechazadoDto(String jobNombre, String clasificacion, long cantidad) {
}
