package com.bancoxyz.notificaciones.notificacion;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import com.bancoxyz.notificaciones.evento.EventoDeTransferencia;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Los textos en espanol de {@link ServicioDeNotificaciones#textoDe} y la deduplicacion por {@code eventoId} de
 * {@link ServicioDeNotificaciones#procesar}. Sin Spring: {@link RepositorioDeNotificaciones} se instancia a mano.
 */
class ServicioDeNotificacionesTest {

    private final RepositorioDeNotificaciones repositorio = new RepositorioDeNotificaciones();
    private final ServicioDeNotificaciones servicio = new ServicioDeNotificaciones(repositorio);

    private static EventoDeTransferencia evento(String tipo, String monto, long origen, long destino, long clienteId,
                                                 String motivo) {
        return new EventoDeTransferencia(UUID.randomUUID().toString(), tipo, UUID.randomUUID().toString(),
                Instant.now(), clienteId, 1L, origen, destino, monto == null ? null : new BigDecimal(monto), null,
                motivo, null);
    }

    @Test
    @DisplayName("TransferenciaCompletada: monto con formato chileno, cuenta de origen y de destino")
    void textoDeCompletada() {
        String texto = ServicioDeNotificaciones.textoDe(evento(EventoDeTransferencia.COMPLETADA, "15000.00", 101L,
                105L, 1L, null));
        assertThat(texto).isEqualTo("Transferencia de $15.000 desde la cuenta 101 a la cuenta 105 realizada.");
    }

    @Test
    @DisplayName("FondosRechazados: motivo conocido traducido a una frase")
    void textoDeFondosRechazados() {
        String texto = ServicioDeNotificaciones.textoDe(evento(EventoDeTransferencia.FONDOS_RECHAZADOS, "15000.00",
                101L, 105L, 1L, "SALDO_INSUFICIENTE"));
        assertThat(texto).isEqualTo("Transferencia de $15.000 desde la cuenta 101 rechazada: saldo insuficiente.");
    }

    @Test
    @DisplayName("ReservaLiberada (compensacion tras rechazo de antifraude): tambien se traduce el motivo")
    void textoDeReservaLiberada() {
        String texto = ServicioDeNotificaciones.textoDe(evento(EventoDeTransferencia.RESERVA_LIBERADA, "600000.00",
                301L, 305L, 1L, "MONTO_SOBRE_LIMITE"));
        assertThat(texto).isEqualTo("Transferencia de $600.000 desde la cuenta 301 rechazada: el monto supera el "
                + "limite permitido.");
    }

    @Test
    @DisplayName("Motivo desconocido: se muestra el codigo tal cual, no se oculta")
    void motivoDesconocidoQuedaTalCual() {
        String texto = ServicioDeNotificaciones.textoDe(evento(EventoDeTransferencia.FONDOS_RECHAZADOS, "1000.00",
                101L, 105L, 1L, "MOTIVO_NUEVO_SIN_TRADUCIR"));
        assertThat(texto).endsWith("rechazada: MOTIVO_NUEVO_SIN_TRADUCIR.");
    }

    @Test
    @DisplayName("FondosReservados no genera texto: antifraude todavia no decidio nada")
    void fondosReservadosNoGeneraTexto() {
        assertThat(ServicioDeNotificaciones.textoDe(evento(EventoDeTransferencia.FONDOS_RESERVADOS, "1000.00", 101L,
                105L, 1L, null))).isNull();
    }

    @Test
    @DisplayName("procesar() con un tipo ignorado no guarda ninguna notificacion")
    void procesarTipoIgnoradoNoGuardaNada() {
        servicio.procesar(evento(EventoDeTransferencia.FONDOS_RESERVADOS, "1000.00", 101L, 105L, 7L, null));
        assertThat(repositorio.deCliente(7L)).isEmpty();
    }

    @Test
    @DisplayName("El mismo eventoId procesado dos veces solo deja una notificacion")
    void deduplicaPorEventoId() {
        EventoDeTransferencia completada = evento(EventoDeTransferencia.COMPLETADA, "2000.00", 201L, 205L, 9L, null);
        servicio.procesar(completada);
        servicio.procesar(completada);

        List<Notificacion> notificaciones = repositorio.deCliente(9L);
        assertThat(notificaciones).hasSize(1);
        assertThat(notificaciones.get(0).transferenciaId()).isEqualTo(completada.transferenciaId());
    }

    @Test
    @DisplayName("Mas de 50 notificaciones para el mismo cliente: solo quedan las 50 mas recientes")
    void recortaAlMaximoPorCliente() {
        for (int i = 0; i < 55; i++) {
            repositorio.agregar(3L, new Notificacion(EventoDeTransferencia.COMPLETADA, "t" + i, "texto " + i,
                    Instant.now()));
        }
        List<Notificacion> notificaciones = repositorio.deCliente(3L);
        assertThat(notificaciones).hasSize(RepositorioDeNotificaciones.MAXIMO_POR_CLIENTE);
        // La mas reciente (la ultima agregada, t54) va primero.
        assertThat(notificaciones.get(0).transferenciaId()).isEqualTo("t54");
    }
}
