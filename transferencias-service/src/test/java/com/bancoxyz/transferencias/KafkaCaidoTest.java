package com.bancoxyz.transferencias;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.client.ExpectedCount.manyTimes;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Duration;
import java.util.concurrent.CompletableFuture;

import com.bancoxyz.transferencias.outbox.Outbox;
import com.bancoxyz.transferencias.outbox.PublicadorDeOutbox;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.retry.RetryConfig;
import io.github.resilience4j.retry.RetryRegistry;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.KafkaException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Kafka caido no detiene la API: la transferencia se acepta (202) porque el evento queda en el outbox, en la misma
 * transaccion. El publicador abre su circuito y no insiste; cuando Kafka vuelve, los eventos salen.
 */
class KafkaCaidoTest extends PruebaDeTransferencias {

    @Autowired
    private Outbox outbox;

    @Autowired
    private TransactionTemplate transaccion;

    @Autowired
    private RetryRegistry reintentos;

    @Test
    @DisplayName("Con Kafka caido la API sigue respondiendo 202; los eventos esperan en el outbox y salen cuando Kafka vuelve")
    @SuppressWarnings("unchecked")
    void kafkaCaido() throws Exception {
        core.expect(manyTimes(), requestTo(CORE + "/cuentas/101")).andRespond(withSuccess("{}", MediaType.APPLICATION_JSON));
        KafkaTemplate<String, String> kafka = mock(KafkaTemplate.class);
        when(kafka.send(any(ProducerRecord.class))).thenReturn(CompletableFuture.failedFuture(new KafkaException("broker caido")));
        CircuitBreakerRegistry circuitosDePrueba = CircuitBreakerRegistry.of(CircuitBreakerConfig
                .from(circuitos.circuitBreaker("kafka").getCircuitBreakerConfig()).waitDurationInOpenState(Duration.ofMillis(200)).build());
        PublicadorDeOutbox publicador = new PublicadorDeOutbox(outbox, kafka, transaccion, circuitosDePrueba,
                RetryRegistry.of(RetryConfig.from(reintentos.retry("kafka").getRetryConfig()).waitDuration(Duration.ofMillis(10)).build()));

        transferir(diana(), "sin-kafka-1", 101, 105, "1000").andExpect(status().isAccepted());
        transferir(diana(), "sin-kafka-2", 101, 105, "2000").andExpect(status().isAccepted());
        publicador.publicarPendientes();
        publicador.publicarPendientes();

        assertThat(circuitosDePrueba.circuitBreaker("kafka").getState()).isEqualTo(CircuitBreaker.State.OPEN);
        assertThat(outbox.contarPendientes()).isEqualTo(2);

        when(kafka.send(any(ProducerRecord.class))).thenReturn(CompletableFuture.completedFuture((SendResult<String, String>) null));
        Thread.sleep(300);
        publicador.publicarPendientes();
        assertThat(outbox.contarPendientes()).isZero();
    }
}
