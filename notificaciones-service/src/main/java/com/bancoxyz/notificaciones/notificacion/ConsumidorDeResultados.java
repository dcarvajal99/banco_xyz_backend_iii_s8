package com.bancoxyz.notificaciones.notificacion;

import com.bancoxyz.notificaciones.evento.EventoDeTransferencia;
import com.bancoxyz.notificaciones.evento.LectorDeEventos;
import com.bancoxyz.notificaciones.evento.EventoInvalido;
import com.bancoxyz.notificaciones.evento.Topicos;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

/**
 * Entrada de notificaciones-service a la saga: escucha los dos topicos cuyos eventos le interesan y delega en
 * {@link ServicioDeNotificaciones}. Un mensaje ilegible o sin los campos minimos lanza {@link EventoInvalido} y
 * termina en el topico DLT correspondiente sin reintentos (lo maneja
 * {@link com.bancoxyz.notificaciones.evento.ConfiguracionKafka#manejadorDeErroresKafka}).
 */
@Component
public class ConsumidorDeResultados {

    private final ServicioDeNotificaciones servicio;
    private final LectorDeEventos lector;

    public ConsumidorDeResultados(ServicioDeNotificaciones servicio, LectorDeEventos lector) {
        this.servicio = servicio;
        this.lector = lector;
    }

    @KafkaListener(id = "notificaciones-resultados", topics = {Topicos.RESERVAS, Topicos.TRANSFERENCIAS},
            groupId = "${spring.application.name}")
    public void resultado(ConsumerRecord<String, String> registro) {
        servicio.procesar(leer(registro));
    }

    private EventoDeTransferencia leer(ConsumerRecord<String, String> registro) {
        return lector.leer(registro);
    }
}
