package com.bancoxyz.core.outbox;

import java.nio.charset.StandardCharsets;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.decorators.Decorators;
import io.github.resilience4j.retry.Retry;
import io.github.resilience4j.retry.RetryRegistry;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.KafkaException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Publica el outbox en Kafka con Resilience4j aplicado como decoradores programaticos.
 *
 * <p>Cada envio pasa por {@code Retry(CircuitBreaker(envio))}: un fallo pasajero se reintenta; si Kafka sigue sin
 * responder el circuito {@code kafka} se abre y las siguientes pasadas no tocan el broker hasta que pasa el tiempo de
 * espera. Mientras tanto nada se pierde: los eventos quedan en la tabla y salen en orden cuando Kafka vuelve.</p>
 */
@Component
@ConditionalOnProperty(name = "banco.outbox.publicar", havingValue = "true", matchIfMissing = true)
public class PublicadorDeOutbox {

    private static final Logger log = LoggerFactory.getLogger(PublicadorDeOutbox.class);

    private final Outbox outbox;
    private final KafkaTemplate<String, String> kafka;
    private final TransactionTemplate transaccion;
    private final CircuitBreaker circuito;
    private final Retry reintento;

    public PublicadorDeOutbox(Outbox outbox, KafkaTemplate<String, String> kafka, TransactionTemplate transaccion,
                              CircuitBreakerRegistry circuitos, RetryRegistry reintentos) {
        this.outbox = outbox;
        this.kafka = kafka;
        this.transaccion = transaccion;
        this.circuito = circuitos.circuitBreaker("kafka");
        this.reintento = reintentos.retry("kafka");
        this.circuito.getEventPublisher().onStateTransition(evento -> log.warn("Circuito kafka: {} ({} eventos esperan en el outbox)",
                evento.getStateTransition(), outbox.contarPendientes()));
    }

    @Scheduled(fixedDelayString = "${banco.outbox.intervalo-ms:500}")
    public void publicarPendientes() {
        transaccion.executeWithoutResult(estado -> {
            for (Outbox.Pendiente pendiente : outbox.pendientes(100)) {
                try {
                    Decorators.ofRunnable(() -> enviar(pendiente))
                            .withCircuitBreaker(circuito)
                            .withRetry(reintento)
                            .decorate()
                            .run();
                    outbox.marcarPublicado(pendiente.id());
                } catch (CallNotPermittedException abierto) {
                    // Circuito abierto: no se insiste. El resto espera en orden a la proxima pasada.
                    return;
                } catch (ErrorDePublicacion error) {
                    log.warn("Outbox: {}", error.getMessage());
                    return;
                }
            }
        });
    }

    private void enviar(Outbox.Pendiente pendiente) {
        ProducerRecord<String, String> registro = new ProducerRecord<>(pendiente.topico(), pendiente.clave(),
                pendiente.payload());
        registro.headers().add("tipo", pendiente.tipo().getBytes(StandardCharsets.UTF_8));
        registro.headers().add("eventoId", pendiente.eventoId().getBytes(StandardCharsets.UTF_8));
        try {
            kafka.send(registro).get(5, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new ErrorDePublicacion(pendiente.eventoId(), e);
        } catch (ExecutionException | TimeoutException | KafkaException e) {
            throw new ErrorDePublicacion(pendiente.eventoId(), e);
        }
    }
}
