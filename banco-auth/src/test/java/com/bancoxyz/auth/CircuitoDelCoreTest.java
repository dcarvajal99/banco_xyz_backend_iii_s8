package com.bancoxyz.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestBuilders.formLogin;
import static org.springframework.security.test.web.servlet.response.SecurityMockMvcResultMatchers.unauthenticated;
import static org.springframework.test.web.client.ExpectedCount.times;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withException;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;

import java.net.ConnectException;

import io.github.resilience4j.bulkhead.Bulkhead;
import io.github.resilience4j.bulkhead.BulkheadRegistry;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import org.hamcrest.Matchers;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.client.AutoConfigureMockRestServiceServer;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.test.web.servlet.ResultActions;

/**
 * Las anotaciones @Retry y @CircuitBreaker de ClienteCore actuando en el login: un corte de conexion se reintenta, el
 * circuito abre con el core caido y el formulario avisa que el servicio no esta disponible sin llamar al core; una
 * clave incorrecta no abre el circuito.
 */
@SpringBootTest
@ActiveProfiles("prueba")
@AutoConfigureMockMvc
@AutoConfigureMockRestServiceServer
class CircuitoDelCoreTest extends PruebaOAuth {

    @Autowired
    private MockRestServiceServer core;

    @Autowired
    private CircuitBreakerRegistry circuitos;

    @Autowired
    private BulkheadRegistry bulkheads;

    @BeforeEach
    void limpiar() {
        core.reset();
        circuito().reset();
    }

    @Test
    @DisplayName("Core caido: el primer login reintenta una vez; a la tercera falla el circuito abre y los siguientes no llaman al core")
    void circuitoAbre() throws Exception {
        core.expect(times(3), requestTo(CORE)).andRespond(withException(new ConnectException("core caido")));

        iniciarSesion().andExpect(unauthenticated()).andExpect(redirectedUrl("/login?error=servicio"));
        iniciarSesion().andExpect(unauthenticated());
        assertThat(circuito().getState()).isEqualTo(CircuitBreaker.State.OPEN);

        // Tres llamadas reales al core: dos del primer login (con su reintento) y una del segundo, que abrio el circuito.
        // El reintento del segundo login y el tercer login ya no salen: 2 llamadas no permitidas.
        iniciarSesion().andExpect(unauthenticated());
        core.verify();
        assertThat(circuito().getMetrics().getNumberOfNotPermittedCalls()).isEqualTo(2);
    }

    @Test
    @DisplayName("Con el core caido el formulario explica que el servicio no esta disponible (no dice clave incorrecta)")
    void mensajeDeServicioNoDisponible() throws Exception {
        core.expect(times(2), requestTo(CORE)).andRespond(withException(new ConnectException("core caido")));

        String destino = iniciarSesion().andReturn().getResponse().getRedirectedUrl();
        mvc.perform(get(destino)).andExpect(content().string(Matchers.containsString("no esta disponible")))
                .andExpect(content().string(Matchers.not(Matchers.containsString("incorrectos"))));
    }

    @Test
    @DisplayName("Cinco claves incorrectas: una sola llamada por intento, el circuito sigue cerrado")
    void clavesIncorrectasNoAbren() throws Exception {
        core.expect(times(5), requestTo(CORE)).andRespond(withStatus(HttpStatus.UNAUTHORIZED)
                .contentType(MediaType.APPLICATION_PROBLEM_JSON).body("{\"codigo\":\"CREDENCIALES_INVALIDAS\"}"));

        for (int i = 0; i < 5; i++) {
            iniciarSesion().andExpect(unauthenticated());
        }
        core.verify();
        assertThat(circuito().getState()).isEqualTo(CircuitBreaker.State.CLOSED);
    }

    @Test
    @DisplayName("Core dado de baja en Eureka (LoadBalancer sin instancias): servicio no disponible, sin reintento")
    void sinInstancias() throws Exception {
        core.expect(times(1), requestTo(CORE)).andRespond(solicitud -> {
            throw new IllegalStateException("No instances available for banco-core-api");
        });

        iniciarSesion().andExpect(unauthenticated()).andExpect(redirectedUrl("/login?error=servicio"));
        core.verify();
    }

    @Test
    @DisplayName("Bulkhead lleno: el login responde servicio no disponible sin llamar al core ni abrir el circuito")
    void bulkheadLleno() throws Exception {
        Bulkhead bulkhead = bulkheads.bulkhead("core");
        int ocupadas = 0;
        while (bulkhead.tryAcquirePermission()) {
            ocupadas++;
        }
        try {
            iniciarSesion().andExpect(unauthenticated()).andExpect(redirectedUrl("/login?error=servicio"));
            core.verify();
            assertThat(circuito().getMetrics().getNumberOfFailedCalls()).isZero();
        } finally {
            for (int i = 0; i < ocupadas; i++) {
                bulkhead.onComplete();
            }
        }
    }

    private ResultActions iniciarSesion() throws Exception {
        return mvc.perform(formLogin().user("diana.prince").password("Cliente2026!"));
    }

    private CircuitBreaker circuito() {
        return circuitos.circuitBreaker("core");
    }
}
