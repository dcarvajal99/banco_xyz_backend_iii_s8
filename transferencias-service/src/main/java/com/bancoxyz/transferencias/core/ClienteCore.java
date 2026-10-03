package com.bancoxyz.transferencias.core;

import com.bancoxyz.transferencias.config.PropiedadesCore;
import io.github.resilience4j.bulkhead.BulkheadFullException;
import io.github.resilience4j.bulkhead.annotation.Bulkhead;
import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatusCode;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClientManager;
import org.springframework.security.oauth2.core.OAuth2AuthorizationException;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;

/**
 * Prevalidacion de la cuenta de origen contra el core, protegida con Resilience4j por anotaciones:
 * {@code Retry(CircuitBreaker(GET /cuentas/{id}))}.
 *
 * <p>Si el core responde, se sabe al instante si la cuenta es del usuario (404 si no). Si no responde, el fallback no
 * rechaza: devuelve {@link Validacion#DIFERIDA} y la transferencia se acepta, porque el core vuelve a validar todo al
 * reservar los fondos. Con el circuito abierto ese fallback es inmediato: el cliente no espera timeouts.</p>
 */
@Component
public class ClienteCore {

    private static final Logger log = LoggerFactory.getLogger(ClienteCore.class);
    static final String ENCABEZADO_USUARIO = "X-Usuario-Id";

    private final RestClient http;

    public ClienteCore(RestClient.Builder builder, PropiedadesCore core, OAuth2AuthorizedClientManager gestorDeTokens) {
        this.http = builder
                .baseUrl(core.url())
                .requestInterceptor(TokenDeServicio.interceptor(gestorDeTokens))
                .defaultStatusHandler(HttpStatusCode::is4xxClientError, (solicitud, respuesta) -> {
                    throw new ErrorDeNegocioDelCore(respuesta.getStatusCode().value());
                })
                .build();
    }

    @Bulkhead(name = "core")
    @CircuitBreaker(name = "core")
    @Retry(name = "core", fallbackMethod = "validacionDiferida")
    public Validacion validarCuentaDeOrigen(long usuarioId, long cuentaOrigen) {
        http.get().uri("/cuentas/{id}", cuentaOrigen)
                .header(ENCABEZADO_USUARIO, String.valueOf(usuarioId))
                .retrieve()
                .toBodilessEntity();
        return Validacion.PREVIA;
    }

    Validacion validacionDiferida(long usuarioId, long cuentaOrigen, ResourceAccessException sinConexion) {
        return diferida(cuentaOrigen, "sin conexion");
    }

    Validacion validacionDiferida(long usuarioId, long cuentaOrigen, HttpServerErrorException error5xx) {
        return diferida(cuentaOrigen, "respondio " + error5xx.getStatusCode().value());
    }

    Validacion validacionDiferida(long usuarioId, long cuentaOrigen, CallNotPermittedException circuitoAbierto) {
        return diferida(cuentaOrigen, "circuito abierto");
    }

    /** banco-auth no entrego el token de servicio (caido o rechazo el cliente): sin token no se puede consultar el core. */
    Validacion validacionDiferida(long usuarioId, long cuentaOrigen, OAuth2AuthorizationException sinToken) {
        return diferida(cuentaOrigen, "sin token de servicio: " + sinToken.getError().getErrorCode());
    }

    /** Bulkhead lleno: ya hay demasiadas llamadas simultaneas al core; esta no espera turno. */
    Validacion validacionDiferida(long usuarioId, long cuentaOrigen, BulkheadFullException lleno) {
        return diferida(cuentaOrigen, "bulkhead lleno");
    }

    /** LoadBalancer sin instancias: el core se dio de baja en Eureka (por ejemplo, al detenerse ordenadamente). */
    Validacion validacionDiferida(long usuarioId, long cuentaOrigen, IllegalStateException sinInstancias) {
        return diferida(cuentaOrigen, sinInstancias.getMessage());
    }

    private static Validacion diferida(long cuentaOrigen, String causa) {
        log.warn("Core no disponible ({}): la cuenta {} se valida en la saga (validacion DIFERIDA)", causa, cuentaOrigen);
        return Validacion.DIFERIDA;
    }
}
