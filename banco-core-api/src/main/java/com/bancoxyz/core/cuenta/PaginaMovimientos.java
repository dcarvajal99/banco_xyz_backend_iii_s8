package com.bancoxyz.core.cuenta;

import java.util.List;

/** Forma del contrato {@code pagina-movimientos.json}. */
public record PaginaMovimientos(List<MovimientoDto> contenido, int pagina, int tamano, long totalElementos,
                                int totalPaginas) {
}
