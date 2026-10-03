package com.bancoxyz.transferencias;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.client.ExpectedCount.times;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withException;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.net.ConnectException;

import io.github.resilience4j.bulkhead.Bulkhead;
import io.github.resilience4j.bulkhead.BulkheadRegistry;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;

/**
 * @CircuitBreaker y @Retry de ClienteCore en ejecucion. Con el core caido la API no falla: acepta la transferencia con
 * validacion DIFERIDA (el core la valida en la saga) y, con el circuito abierto, ni siquiera intenta llamarlo.
 */
class CircuitoDelCoreTest extends PruebaDeTransferencias {

    @org.springframework.beans.factory.annotation.Autowired
    private BulkheadRegistry bulkheads;

    @Test
    @DisplayName("Core caido: 202 con validacion DIFERIDA; a la tercera falla el circuito abre y las siguientes no llaman al core")
    void coreCaidoAceptaDiferida() throws Exception {
        core.expect(times(3), requestTo(CORE + "/cuentas/101")).andRespond(withException(new ConnectException("core caido")));

        transferir(diana(), "diferida-1", 101, 105, "1000").andExpect(status().isAccepted())
                .andExpect(jsonPath("$.validacion").value("DIFERIDA"));
        transferir(diana(), "diferida-2", 101, 105, "1000").andExpect(status().isAccepted())
                .andExpect(jsonPath("$.validacion").value("DIFERIDA"));
        assertThat(circuito().getState()).isEqualTo(CircuitBreaker.State.OPEN);

        transferir(diana(), "diferida-3", 101, 105, "1000").andExpect(status().isAccepted())
                .andExpect(jsonPath("$.validacion").value("DIFERIDA"));
        core.verify();
        assertThat(circuito().getMetrics().getNumberOfNotPermittedCalls()).isEqualTo(2);
        assertThat(eventosEnElOutbox()).isEqualTo(3);
    }

    @Test
    @DisplayName("Core dado de baja en Eureka (LoadBalancer sin instancias): tambien 202 con validacion DIFERIDA, sin reintento")
    void sinInstanciasAceptaDiferida() throws Exception {
        core.expect(times(1), requestTo(CORE + "/cuentas/101")).andRespond(solicitud -> {
            throw new IllegalStateException("No instances available for banco-core-api");
        });

        transferir(diana(), "sin-instancias", 101, 105, "1000").andExpect(status().isAccepted())
                .andExpect(jsonPath("$.validacion").value("DIFERIDA"));
        core.verify();
    }

    @Test
    @DisplayName("Cuentas ajenas (404) no son fallas del core: el circuito sigue cerrado y no hay reintentos")
    void ajenasNoAbren() throws Exception {
        core.expect(times(4), requestTo(CORE + "/cuentas/102")).andRespond(withStatus(HttpStatus.NOT_FOUND)
                .contentType(MediaType.APPLICATION_PROBLEM_JSON).body("{\"codigo\":\"CUENTA_NO_ENCONTRADA\"}"));

        for (int i = 0; i < 4; i++) {
            transferir(diana(), "ajena-" + i, 102, 105, "1000").andExpect(status().isNotFound());
        }
        core.verify();
        assertThat(circuito().getState()).isEqualTo(CircuitBreaker.State.CLOSED);
    }

    @Test
    @DisplayName("Bulkhead lleno (20 llamadas simultaneas al core): 202 con validacion DIFERIDA sin llamar al core, y el circuito no lo cuenta como falla")
    void bulkheadLleno() throws Exception {
        Bulkhead bulkhead = bulkheads.bulkhead("core");
        int ocupadas = 0;
        while (bulkhead.tryAcquirePermission()) {
            ocupadas++;
        }
        try {
            transferir(diana(), "bulkhead-1", 101, 105, "1000").andExpect(status().isAccepted())
                    .andExpect(jsonPath("$.validacion").value("DIFERIDA"));
            core.verify();
            assertThat(ocupadas).isEqualTo(20);
            assertThat(circuito().getMetrics().getNumberOfFailedCalls()).isZero();
        } finally {
            for (int i = 0; i < ocupadas; i++) {
                bulkhead.onComplete();
            }
        }
    }

    @Test
    @DisplayName("El actuator es de solo lectura: nadie puede forzar el estado del circuito, ni con un token del banco")
    void circuitoNoSeFuerzaDesdeElActuator() throws Exception {
        String forzar = "{\"updateState\":\"FORCE_OPEN\"}";

        mvc.perform(post("/actuator/circuitbreakers/core").contentType(MediaType.APPLICATION_JSON).content(forzar))
                .andExpect(status().isUnauthorized());
        mvc.perform(post("/actuator/circuitbreakers/core").with(diana()).contentType(MediaType.APPLICATION_JSON).content(forzar))
                .andExpect(status().isForbidden());
        mvc.perform(get("/actuator/circuitbreakers")).andExpect(status().isOk());

        assertThat(circuito().getState()).isEqualTo(CircuitBreaker.State.CLOSED);
    }

    private CircuitBreaker circuito() {
        return circuitos.circuitBreaker("core");
    }
}
