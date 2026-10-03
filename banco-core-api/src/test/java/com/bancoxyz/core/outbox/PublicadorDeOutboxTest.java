package com.bancoxyz.core.outbox;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;

import com.bancoxyz.core.PruebaDelCore;
import com.bancoxyz.core.transferencia.EventoDeTransferencia;
import com.bancoxyz.core.transferencia.Topicos;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.retry.RetryConfig;
import io.github.resilience4j.retry.RetryRegistry;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.KafkaException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * El publicador del outbox con los decoradores de Resilience4j: Kafka arriba, Kafka caido (reintento y circuito
 * abierto, sin perder eventos) y recuperacion. El broker se simula; la tabla outbox es la real.
 */
class PublicadorDeOutboxTest extends PruebaDelCore {

    @Autowired
    private Outbox outbox;

    @Autowired
    private TransactionTemplate transaccion;

    @Autowired
    private CircuitBreakerRegistry circuitosDeLaAplicacion;

    @Autowired
    private RetryRegistry reintentosDeLaAplicacion;

    @SuppressWarnings("unchecked")
    private final KafkaTemplate<String, String> kafka = mock(KafkaTemplate.class);

    private CircuitBreakerRegistry circuitos;

    private PublicadorDeOutbox publicador;

    @BeforeEach
    void publicadorConEsperaCorta() {
        // La politica de produccion, con 200 ms de circuito abierto en vez de 10 s para no esperar en la prueba.
        CircuitBreakerConfig produccion = circuitosDeLaAplicacion.circuitBreaker("kafka").getCircuitBreakerConfig();
        circuitos = CircuitBreakerRegistry.of(CircuitBreakerConfig.from(produccion)
                .waitDurationInOpenState(Duration.ofMillis(200)).build());
        RetryConfig reintento = RetryConfig.from(reintentosDeLaAplicacion.retry("kafka").getRetryConfig())
                .waitDuration(Duration.ofMillis(10)).build();
        publicador = new PublicadorDeOutbox(outbox, kafka, transaccion, circuitos, RetryRegistry.of(reintento));
    }

    @Test
    @DisplayName("La politica del circuito kafka y del reintento es la configurada: ventana 4, minimo 2, 50 %, 10 s; 3 intentos")
    void politicaConfigurada() {
        CircuitBreakerConfig circuito = circuitosDeLaAplicacion.circuitBreaker("kafka").getCircuitBreakerConfig();
        assertThat(circuito.getSlidingWindowSize()).isEqualTo(4);
        assertThat(circuito.getMinimumNumberOfCalls()).isEqualTo(2);
        assertThat(circuito.getFailureRateThreshold()).isEqualTo(50f);
        assertThat(circuito.getWaitIntervalFunctionInOpenState().apply(1)).isEqualTo(10_000L);
        assertThat(reintentosDeLaAplicacion.retry("kafka").getRetryConfig().getMaxAttempts()).isEqualTo(3);
    }

    @Test
    @DisplayName("Kafka arriba: cada evento sale con su topico, la cuenta como clave y el tipo en el encabezado, y queda publicado")
    @SuppressWarnings("unchecked")
    void publicaYMarca() {
        when(kafka.send(any(ProducerRecord.class))).thenReturn(CompletableFuture.completedFuture((SendResult<String, String>) null));
        registrar(101);
        registrar(105);

        publicador.publicarPendientes();

        ArgumentCaptor<ProducerRecord<String, String>> enviados = ArgumentCaptor.forClass(ProducerRecord.class);
        verify(kafka, times(2)).send(enviados.capture());
        List<ProducerRecord<String, String>> registros = enviados.getAllValues();
        assertThat(registros).extracting(ProducerRecord::key).containsExactly("101", "105");
        assertThat(registros.get(0).topic()).isEqualTo(Topicos.RESERVAS);
        assertThat(new String(registros.get(0).headers().lastHeader("tipo").value(), StandardCharsets.UTF_8))
                .isEqualTo("FondosReservados");
        assertThat(outbox.contarPendientes()).isZero();
    }

    @Test
    @DisplayName("Kafka caido: reintenta, abre el circuito y deja de insistir; el evento sigue pendiente y sale cuando Kafka vuelve")
    @SuppressWarnings("unchecked")
    void kafkaCaidoYRecuperacion() throws Exception {
        when(kafka.send(any(ProducerRecord.class))).thenReturn(CompletableFuture.failedFuture(new KafkaException("broker caido")));
        registrar(101);

        publicador.publicarPendientes();
        CircuitBreaker circuito = circuitos.circuitBreaker("kafka");
        assertThat(circuito.getState()).isEqualTo(CircuitBreaker.State.OPEN);
        verify(kafka, times(2)).send(any(ProducerRecord.class));

        // El Retry envuelve al CircuitBreaker: dos fallos abrieron el circuito y el tercer intento ya no salio
        // (1 llamada no permitida). La segunda pasada tampoco toca el broker (2 no permitidas, ningun envio nuevo).
        publicador.publicarPendientes();
        verify(kafka, times(2)).send(any(ProducerRecord.class));
        assertThat(circuito.getMetrics().getNumberOfNotPermittedCalls()).isEqualTo(2);
        assertThat(outbox.contarPendientes()).isEqualTo(1);

        when(kafka.send(any(ProducerRecord.class))).thenReturn(CompletableFuture.completedFuture((SendResult<String, String>) null));
        Thread.sleep(300);
        publicador.publicarPendientes();
        assertThat(circuito.getState()).isEqualTo(CircuitBreaker.State.CLOSED);
        assertThat(outbox.contarPendientes()).isZero();
    }

    private void registrar(long cuenta) {
        transaccion.executeWithoutResult(estado -> outbox.registrar(Topicos.RESERVAS, new EventoDeTransferencia(
                UUID.randomUUID().toString(), EventoDeTransferencia.FONDOS_RESERVADOS, UUID.randomUUID().toString(),
                Instant.now(), 1L, 1L, cuenta, 102L, new BigDecimal("1000.00"), null, null, null)));
    }
}
