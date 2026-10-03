package com.bancoxyz.core.transferencia;

import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

/**
 * Entrada del core a la saga: escucha las solicitudes de transferencia y las decisiones de antifraude.
 *
 * <p>Cada tipo de evento tiene un solo efecto posible en el core. Un tipo desconocido se registra y se ignora, para que
 * un productor pueda agregar eventos nuevos sin romper a este consumidor. Un mensaje ilegible lanza
 * {@link EventoInvalido} y termina en el topico DLT sin reintentos.</p>
 */
@Component
public class ConsumidorDeTransferencias {

    private static final Logger log = LoggerFactory.getLogger(ConsumidorDeTransferencias.class);

    private final ServicioDeTransferencias servicio;
    private final LectorDeEventos lector;

    public ConsumidorDeTransferencias(ServicioDeTransferencias servicio, LectorDeEventos lector) {
        this.servicio = servicio;
        this.lector = lector;
    }

    @KafkaListener(id = "core-solicitadas", topics = Topicos.SOLICITADAS, groupId = "${spring.application.name}")
    public void solicitada(ConsumerRecord<String, String> registro) {
        EventoDeTransferencia evento = leer(registro);
        if (EventoDeTransferencia.SOLICITADA.equals(evento.tipo())) {
            servicio.reservar(evento);
        } else {
            ignorar(registro, evento);
        }
    }

    @KafkaListener(id = "core-decisiones", topics = Topicos.DECISIONES, groupId = "${spring.application.name}")
    public void decision(ConsumerRecord<String, String> registro) {
        EventoDeTransferencia evento = leer(registro);
        switch (evento.tipo()) {
            case EventoDeTransferencia.APROBADA -> servicio.confirmar(evento);
            case EventoDeTransferencia.RECHAZADA -> servicio.liberar(evento);
            default -> ignorar(registro, evento);
        }
    }

    private EventoDeTransferencia leer(ConsumerRecord<String, String> registro) {
        return lector.leer(registro);
    }

    private static void ignorar(ConsumerRecord<String, String> registro, EventoDeTransferencia evento) {
        log.info("Evento {} ignorado en {}: el core no reacciona a este tipo", evento.tipo(), registro.topic());
    }
}
