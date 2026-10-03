package com.bancoxyz.core.error;

import java.net.URI;
import java.util.Locale;

import com.bancoxyz.core.config.FiltroCorrelacion;
import org.slf4j.MDC;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;

/**
 * Construye los ProblemDetail del core con la forma del contrato ({@code error-*.json}).
 *
 * <p>{@code detail} e {@code instance} se fijan siempre: ProblemDetail los omite cuando son null,
 * y entonces el conjunto de claves de un error dejaria de ser estable para los BFF.</p>
 */
public final class Problemas {

    private Problemas() {
    }

    public static ProblemDetail crear(HttpStatusCode estado, String codigo, String titulo, String detalle,
                                      String instancia) {
        ProblemDetail problema = ProblemDetail.forStatus(estado);
        problema.setType(URI.create("urn:bancoxyz:problema:" + codigo.toLowerCase(Locale.ROOT).replace('_', '-')));
        problema.setTitle(titulo);
        problema.setDetail(detalle == null ? titulo : detalle);
        problema.setInstance(URI.create(instancia == null || instancia.isBlank() ? "/" : instancia));
        problema.setProperty("codigo", codigo);
        problema.setProperty("correlacionId", MDC.get(FiltroCorrelacion.CLAVE_MDC));
        return problema;
    }
}
