package com.bancoxyz.auth.core;

import java.io.IOException;
import java.util.Map;

import com.bancoxyz.auth.config.PropiedadesCore;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.resilience4j.bulkhead.BulkheadFullException;
import io.github.resilience4j.bulkhead.annotation.Bulkhead;
import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import io.github.resilience4j.circuitbreaker.annotation.CircuitBreaker;
import io.github.resilience4j.retry.annotation.Retry;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.MediaType;
import org.springframework.http.client.support.BasicAuthenticationInterceptor;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;

/**
 * Llamadas HTTP al core para verificar usuario y clave (o identificar al cliente que entro con GitHub), protegidas
 * con Resilience4j por anotaciones.
 *
 * <p>Orden de los aspectos: {@code Retry(CircuitBreaker(llamada))}. Un corte de conexion se reintenta una vez; si el core
 * sigue sin responder, el circuito {@code core} se abre y las llamadas siguientes van directo al fallback sin esperar
 * timeouts. Las respuestas 4xx del core ({@link ErrorDeNegocioDelCore}) no cuentan como falla ni tienen fallback: el
 * cliente recibe el mismo 401, 403 o 423.</p>
 */
@Component
public class ClienteCore {

    private final RestClient http;

    public ClienteCore(RestClient.Builder builder, PropiedadesCore core, ObjectMapper json) {
        this.http = builder
                .baseUrl(core.url())
                .requestInterceptor(new BasicAuthenticationInterceptor(core.usuario(), core.clave()))
                .defaultStatusHandler(HttpStatusCode::is4xxClientError, (solicitud, respuesta) -> {
                    throw new ErrorDeNegocioDelCore(respuesta.getStatusCode().value(), codigo(respuesta.getBody().readAllBytes(), json));
                })
                .build();
    }

    @Bulkhead(name = "core")
    @CircuitBreaker(name = "core")
    @Retry(name = "core", fallbackMethod = "coreNoDisponible")
    public UsuarioAutenticado autenticar(String usuario, String clave) {
        return http.post().uri("/autenticacion/usuarios")
                .contentType(MediaType.APPLICATION_JSON)
                .body(Map.of("usuario", usuario, "password", clave))
                .retrieve()
                .body(UsuarioAutenticado.class);
    }

    /**
     * Identifica sin clave a un cliente cuya cuenta de GitHub esta vinculada a su usuario del banco (la persona ya se
     * autentico con GitHub). El core confirma que existe, que esta activo y sin bloqueo, y devuelve sus ids. Mismo
     * canal AUTENTICACION y misma proteccion que {@link #autenticar}.
     */
    @Bulkhead(name = "core")
    @CircuitBreaker(name = "core")
    @Retry(name = "core", fallbackMethod = "coreNoDisponibleAlIdentificar")
    public UsuarioAutenticado identificar(String usuario) {
        return http.get().uri("/autenticacion/usuarios/{usuario}", usuario)
                .retrieve()
                .body(UsuarioAutenticado.class);
    }

    // Fallbacks por tipo: solo las fallas de disponibilidad terminan aqui. Un ErrorDeNegocioDelCore no calza con
    // ninguno y llega tal cual al controlador.
    UsuarioAutenticado coreNoDisponible(String usuario, String clave, ResourceAccessException sinConexion) {
        throw new CoreNoDisponible(sinConexion);
    }

    UsuarioAutenticado coreNoDisponible(String usuario, String clave, HttpServerErrorException error5xx) {
        throw new CoreNoDisponible(error5xx);
    }

    UsuarioAutenticado coreNoDisponible(String usuario, String clave, CallNotPermittedException circuitoAbierto) {
        throw new CoreNoDisponible(circuitoAbierto);
    }

    /** Bulkhead lleno: ya hay demasiadas llamadas simultaneas al core; esta no espera turno. */
    UsuarioAutenticado coreNoDisponible(String usuario, String clave, BulkheadFullException lleno) {
        throw new CoreNoDisponible(lleno);
    }

    /** LoadBalancer sin instancias: el core se dio de baja en Eureka (por ejemplo, al detenerse ordenadamente). */
    UsuarioAutenticado coreNoDisponible(String usuario, String clave, IllegalStateException sinInstancias) {
        throw new CoreNoDisponible(sinInstancias);
    }

    UsuarioAutenticado coreNoDisponibleAlIdentificar(String usuario, ResourceAccessException sinConexion) {
        throw new CoreNoDisponible(sinConexion);
    }

    UsuarioAutenticado coreNoDisponibleAlIdentificar(String usuario, HttpServerErrorException error5xx) {
        throw new CoreNoDisponible(error5xx);
    }

    UsuarioAutenticado coreNoDisponibleAlIdentificar(String usuario, CallNotPermittedException circuitoAbierto) {
        throw new CoreNoDisponible(circuitoAbierto);
    }

    UsuarioAutenticado coreNoDisponibleAlIdentificar(String usuario, BulkheadFullException lleno) {
        throw new CoreNoDisponible(lleno);
    }

    UsuarioAutenticado coreNoDisponibleAlIdentificar(String usuario, IllegalStateException sinInstancias) {
        throw new CoreNoDisponible(sinInstancias);
    }

    private static String codigo(byte[] cuerpo, ObjectMapper json) {
        try {
            JsonNode nodo = cuerpo.length == 0 ? null : json.readTree(cuerpo);
            return nodo != null && nodo.path("codigo").isTextual() ? nodo.get("codigo").asText() : null;
        } catch (IOException cuerpoQueNoEsJson) {
            return null;
        }
    }
}
