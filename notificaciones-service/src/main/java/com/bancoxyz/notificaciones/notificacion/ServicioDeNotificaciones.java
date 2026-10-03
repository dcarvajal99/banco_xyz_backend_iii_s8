package com.bancoxyz.notificaciones.notificacion;

import com.bancoxyz.notificaciones.evento.EventoDeTransferencia;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

/**
 * Convierte un resultado de la saga en una notificacion en espanol, o decide que este servicio no le avisa nada al
 * cliente por ese evento. Logica pura aparte de la deduplicacion (que necesita el repositorio): se prueba sin Kafka.
 */
@Service
public class ServicioDeNotificaciones {

    private static final Logger log = LoggerFactory.getLogger(ServicioDeNotificaciones.class);

    private final RepositorioDeNotificaciones repositorio;

    public ServicioDeNotificaciones(RepositorioDeNotificaciones repositorio) {
        this.repositorio = repositorio;
    }

    /** Punto de entrada del consumidor: ignora duplicados y tipos que no generan aviso, y guarda el resto. */
    public void procesar(EventoDeTransferencia evento) {
        if (repositorio.yaProcesado(evento.eventoId())) {
            log.info("Evento {} ({}) duplicado: no se vuelve a notificar", evento.eventoId(), evento.tipo());
            return;
        }
        String texto = textoDe(evento);
        if (texto == null) {
            log.info("Evento {} ignorado: notificaciones no avisa nada por este tipo", evento.tipo());
            return;
        }
        Notificacion notificacion = new Notificacion(evento.tipo(), evento.transferenciaId(), texto, evento.ocurridoEn());
        repositorio.agregar(evento.clienteId(), notificacion);
        log.info("Notificacion cliente {} · transferencia {} · {}", evento.clienteId(), corto(evento.transferenciaId()),
                texto);
    }

    /**
     * El texto en espanol de la notificacion, o {@code null} si este tipo de evento no genera ninguna: de
     * {@code cuentas.reservas} solo importa {@code FondosRechazados} ({@code FondosReservados} lo evalua antifraude,
     * todavia no hay nada que avisar); de {@code cuentas.transferencias} importan los dos, exito y compensacion.
     */
    static String textoDe(EventoDeTransferencia evento) {
        String monto = FormateadorDeMonto.formatear(evento.monto());
        return switch (evento.tipo()) {
            case EventoDeTransferencia.COMPLETADA -> "Transferencia de " + monto + " desde la cuenta "
                    + evento.cuentaOrigen() + " a la cuenta " + evento.cuentaDestino() + " realizada.";
            case EventoDeTransferencia.FONDOS_RECHAZADOS, EventoDeTransferencia.RESERVA_LIBERADA ->
                    "Transferencia de " + monto + " desde la cuenta " + evento.cuentaOrigen() + " rechazada: "
                            + TraductorDeMotivos.traducir(evento.motivo()) + ".";
            default -> null;
        };
    }

    private static String corto(String transferenciaId) {
        return transferenciaId == null ? "?" : transferenciaId.substring(0, 8);
    }
}
