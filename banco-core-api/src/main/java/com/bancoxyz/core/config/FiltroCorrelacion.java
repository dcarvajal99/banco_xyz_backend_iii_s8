package com.bancoxyz.core.config;

import java.io.IOException;
import java.util.UUID;
import java.util.regex.Pattern;

import com.bancoxyz.core.seguridad.FiltroCertificadoDeCanal;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Id de correlacion leido o generado aqui, con una linea de log por solicitud (incluye el CN del certificado de cliente
 * con que entro el BFF: el mTLS de cada canal queda en el log).
 *
 * <p>Va antes que la cadena de seguridad para que tambien los 401/403 lleven el id. Con el mismo id en el log del BFF y
 * en el del core se sigue una solicitud de punta a punta. El valor recibido se valida con un patron estricto porque se
 * escribe en el log (un encabezado con saltos de linea permitiria inyectar lineas falsas). No se registra la query.</p>
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class FiltroCorrelacion extends OncePerRequestFilter {

    public static final String ENCABEZADO = "X-Correlacion-Id";
    public static final String CLAVE_MDC = "correlacion";
    private static final Pattern FORMATO = Pattern.compile("[A-Za-z0-9._-]{1,64}");
    private static final Logger log = LoggerFactory.getLogger(FiltroCorrelacion.class);

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String recibido = request.getHeader(ENCABEZADO);
        String id = recibido != null && FORMATO.matcher(recibido).matches() ? recibido : UUID.randomUUID().toString();
        MDC.put(CLAVE_MDC, id);
        response.setHeader(ENCABEZADO, id);
        long inicio = System.nanoTime();
        try {
            chain.doFilter(request, response);
        } finally {
            if (!request.getRequestURI().startsWith("/actuator")) {
                log.info("{} {} -> {} ({} ms) certificado={}", request.getMethod(), request.getRequestURI(), response.getStatus(),
                        (System.nanoTime() - inicio) / 1_000_000, FiltroCertificadoDeCanal.nombreComun(request).orElse("ninguno"));
            }
            MDC.remove(CLAVE_MDC);
        }
    }

    public static String actual() {
        return MDC.get(CLAVE_MDC);
    }
}
