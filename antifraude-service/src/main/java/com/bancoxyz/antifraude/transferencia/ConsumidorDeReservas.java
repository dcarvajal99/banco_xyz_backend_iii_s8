package com.bancoxyz.antifraude.transferencia;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.micrometer.core.instrument.MeterRegistry;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.KafkaException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

/**
 * Entrada de antifraude-service a la saga: por cada {@code FondosReservados} evalua el riesgo de la transferencia y
 * publica la decision. Los demas tipos del topico (por ejemplo {@code FondosRechazados}, que ya viene rechazada por el
 * core) se ignoran con un log, para que el core pueda agregar tipos nuevos sin romper este consumidor.
 *
 * <p>Un mensaje ilegible o sin los campos minimos lanza {@link EventoInvalido} y termina en el topico DLT sin
 * reintentos (lo maneja {@link ConfiguracionKafka#manejadorDeErroresKafka}). Si la publicacion de la decision falla, se
 * relanza como excepcion no controlada: el mismo manejador reintenta el evento completo dos veces antes de mandarlo al
 * DLT.</p>
 */
@Component
public class ConsumidorDeReservas {

    private static final Logger log = LoggerFactory.getLogger(ConsumidorDeReservas.class);

    private final ObjectMapper json;
    private final LectorDeEventos lector;
    private final KafkaTemplate<String, String> kafka;
    private final ReglasDeRiesgo reglas;
    private final MeterRegistry metricas;
    private final long demoraMs;
    private final String instancia;

    public ConsumidorDeReservas(ObjectMapper json, LectorDeEventos lector, KafkaTemplate<String, String> kafka,
                                ReglasDeRiesgo reglas,
                                MeterRegistry metricas, @Value("${banco.antifraude.demora-ms:0}") long demoraMs,
                                @Value("${HOSTNAME:${server.port}}") String instancia) {
        this.json = json;
        this.lector = lector;
        this.kafka = kafka;
        this.reglas = reglas;
        this.metricas = metricas;
        this.demoraMs = demoraMs;
        this.instancia = instancia;
    }

    @KafkaListener(id = "antifraude-reservas", topics = Topicos.RESERVAS, groupId = "${spring.application.name}")
    public void reservas(ConsumerRecord<String, String> registro) {
        EventoDeTransferencia reserva = leer(registro);
        if (!EventoDeTransferencia.FONDOS_RESERVADOS.equals(reserva.tipo())) {
            log.info("Evento {} ignorado en {}: antifraude solo evalua {}", reserva.tipo(), registro.topic(),
                    EventoDeTransferencia.FONDOS_RESERVADOS);
            return;
        }
        simularConsultaDeRiesgo();
        String motivo = reglas.evaluar(reserva).orElse(null);
        EventoDeTransferencia decision = reserva.siguiente(
                motivo == null ? EventoDeTransferencia.APROBADA : EventoDeTransferencia.RECHAZADA, Instant.now(),
                motivo, null);
        publicar(decision);
        metricas.counter("antifraude.decisiones", "resultado", motivo == null ? "aprobada" : "rechazada").increment();
        log.info("Antifraude [{}] · particion {} offset {} · transferencia {} · {}→{} ${} · {}{}", instancia,
                registro.partition(), registro.offset(), corto(reserva.transferenciaId()), reserva.cuentaOrigen(),
                reserva.cuentaDestino(), reserva.monto(), decision.tipo(), motivo == null ? "" : " " + motivo);
    }

    private void simularConsultaDeRiesgo() {
        if (demoraMs <= 0) {
            return;
        }
        try {
            Thread.sleep(demoraMs);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private void publicar(EventoDeTransferencia decision) {
        ProducerRecord<String, String> registro = new ProducerRecord<>(Topicos.DECISIONES, decision.clave(),
                aJson(decision));
        registro.headers().add("tipo", decision.tipo().getBytes(StandardCharsets.UTF_8));
        registro.headers().add("eventoId", decision.eventoId().getBytes(StandardCharsets.UTF_8));
        try {
            kafka.send(registro).get(5, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Interrumpido publicando la decision " + decision.eventoId(), e);
        } catch (ExecutionException | TimeoutException | KafkaException e) {
            throw new IllegalStateException("No se pudo publicar la decision " + decision.eventoId(), e);
        }
    }

    private EventoDeTransferencia leer(ConsumerRecord<String, String> registro) {
        return lector.leer(registro);
    }

    private String aJson(EventoDeTransferencia evento) {
        try {
            return json.writeValueAsString(evento);
        } catch (Exception e) {
            throw new IllegalStateException("No se pudo serializar la decision " + evento.eventoId(), e);
        }
    }

    private static String corto(String transferenciaId) {
        return transferenciaId == null ? "?" : transferenciaId.substring(0, 8);
    }
}
