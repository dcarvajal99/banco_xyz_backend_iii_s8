package com.bancoxyz.transferencias.evento;

import com.bancoxyz.transferencias.transferencia.ServicioDeTransferencias;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

/**
 * Resultados de la saga que cambian el estado de una transferencia: la reserva (o su rechazo) del core, y la
 * transferencia completada o compensada. Un mensaje ilegible va al DLT sin reintentos.
 */
@Component
public class ConsumidorDeResultados {

    private final ServicioDeTransferencias servicio;
    private final LectorDeEventos lector;

    public ConsumidorDeResultados(ServicioDeTransferencias servicio, LectorDeEventos lector) {
        this.servicio = servicio;
        this.lector = lector;
    }

    @KafkaListener(id = "transferencias-resultados", topics = {Topicos.RESERVAS, Topicos.TRANSFERENCIAS},
            groupId = "${spring.application.name}")
    public void resultado(ConsumerRecord<String, String> registro) {
        servicio.aplicar(leer(registro));
    }

    private EventoDeTransferencia leer(ConsumerRecord<String, String> registro) {
        return lector.leer(registro);
    }
}
