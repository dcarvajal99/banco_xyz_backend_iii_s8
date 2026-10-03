package com.bancoxyz.core.transferencia;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.HexFormat;
import java.util.Objects;
import java.util.Optional;

import com.bancoxyz.core.cuenta.Cuenta;
import com.bancoxyz.core.cuenta.RepositorioCuentas;
import com.bancoxyz.core.operacion.Operacion;
import com.bancoxyz.core.operacion.RepositorioOperaciones;
import com.bancoxyz.core.outbox.Outbox;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Los tres pasos del core en la saga de transferencias. Cada uno es una transaccion local que cambia saldos y guarda en
 * el outbox el evento que avisa el resultado.
 *
 * <ol>
 *   <li>{@link #reservar}: TransferenciaSolicitada → retiene el monto en la cuenta de origen → FondosReservados, o
 *       FondosRechazados con el motivo.</li>
 *   <li>{@link #confirmar}: TransferenciaAprobada (antifraude) → acredita el destino y registra los dos movimientos →
 *       TransferenciaCompletada.</li>
 *   <li>{@link #liberar}: TransferenciaRechazada (antifraude) → <b>compensacion</b>: devuelve el monto retenido →
 *       ReservaLiberada.</li>
 * </ol>
 *
 * <p>Idempotencia: un evento ya procesado ({@code evento_procesado}) se ignora, y una reserva que ya no esta RESERVADA
 * no se vuelve a confirmar ni a liberar. Kafka puede entregar un evento dos veces; el saldo cambia una sola vez.</p>
 */
@Service
public class ServicioDeTransferencias {

    private static final Logger log = LoggerFactory.getLogger(ServicioDeTransferencias.class);

    private final RepositorioCuentas cuentas;
    private final RepositorioReservas reservas;
    private final RepositorioEventosProcesados procesados;
    private final RepositorioOperaciones operaciones;
    private final Outbox outbox;
    private final Clock reloj;

    public ServicioDeTransferencias(RepositorioCuentas cuentas, RepositorioReservas reservas,
                                    RepositorioEventosProcesados procesados, RepositorioOperaciones operaciones,
                                    Outbox outbox, Clock reloj) {
        this.cuentas = cuentas;
        this.reservas = reservas;
        this.procesados = procesados;
        this.operaciones = operaciones;
        this.outbox = outbox;
        this.reloj = reloj;
    }

    @Transactional
    public Optional<EventoDeTransferencia> reservar(EventoDeTransferencia solicitud) {
        if (!primeraVez(solicitud) || reservas.existsById(solicitud.transferenciaId())) {
            return Optional.empty();
        }
        LocalDateTime ahora = ahora();
        BigDecimal monto = solicitud.monto();
        String motivo = motivoDeRechazo(solicitud);
        Optional<Cuenta> origen = motivo == null ? cuentas.buscarParaActualizar(solicitud.cuentaOrigen()) : Optional.empty();
        if (motivo == null && origen.isEmpty()) {
            motivo = "CUENTA_ORIGEN_INEXISTENTE";
        } else if (motivo == null) {
            Cuenta cuenta = origen.get();
            if (!Objects.equals(cuenta.getClienteId(), solicitud.clienteId())) {
                motivo = "CUENTA_AJENA";
            } else if (!cuenta.esAhorro()) {
                motivo = "CUENTA_NO_ADMITE_RETIROS";
            } else if (!cuentas.existsById(solicitud.cuentaDestino())) {
                motivo = "CUENTA_DESTINO_INEXISTENTE";
            } else if (cuenta.getSaldoDisponible().compareTo(monto) < 0) {
                motivo = "SALDO_INSUFICIENTE";
            }
        }
        EventoDeTransferencia resultado;
        if (motivo == null) {
            Cuenta cuenta = origen.get();
            cuenta.descontar(monto, ahora);
            reservas.save(Reserva.reservada(solicitud, monto, ahora));
            resultado = solicitud.siguiente(EventoDeTransferencia.FONDOS_RESERVADOS, instante(), null,
                    cuenta.getSaldoDisponible());
        } else {
            if (monto != null && monto.signum() > 0) {
                reservas.save(Reserva.rechazada(solicitud, monto, motivo, ahora));
            }
            resultado = solicitud.siguiente(EventoDeTransferencia.FONDOS_RECHAZADOS, instante(), motivo, null);
        }
        outbox.registrar(Topicos.RESERVAS, resultado);
        log.info("Saga {} · {} {}→{} ${} → {}{}", corto(solicitud), solicitud.tipo(), solicitud.cuentaOrigen(),
                solicitud.cuentaDestino(), monto, resultado.tipo(), motivo == null ? " (saldo origen " +
                        resultado.saldoOrigen() + ")" : " " + motivo);
        return Optional.of(resultado);
    }

    @Transactional
    public Optional<EventoDeTransferencia> confirmar(EventoDeTransferencia aprobada) {
        Optional<Reserva> vigente = reservaVigente(aprobada);
        if (vigente.isEmpty()) {
            return Optional.empty();
        }
        Reserva reserva = vigente.get();
        LocalDateTime ahora = ahora();
        // Las dos cuentas se bloquean siempre en el mismo orden (id ascendente): dos transferencias cruzadas no se
        // bloquean mutuamente.
        long primera = Math.min(reserva.getCuentaOrigen(), reserva.getCuentaDestino());
        long segunda = Math.max(reserva.getCuentaOrigen(), reserva.getCuentaDestino());
        Cuenta cuentaPrimera = cuentas.buscarParaActualizar(primera).orElseThrow();
        Cuenta cuentaSegunda = cuentas.buscarParaActualizar(segunda).orElseThrow();
        Cuenta origen = Objects.equals(cuentaPrimera.getId(), reserva.getCuentaOrigen()) ? cuentaPrimera : cuentaSegunda;
        Cuenta destino = origen == cuentaPrimera ? cuentaSegunda : cuentaPrimera;

        destino.acreditar(reserva.getMonto(), ahora);
        reserva.confirmar(ahora);
        String huella = huella(reserva);
        operaciones.save(Operacion.deTransferencia(origen.getId(), Operacion.TIPO_TRANSFERENCIA_ENVIADA,
                reserva.getMonto(), origen.getSaldoDisponible(), reserva.getTransferenciaId(), huella, ahora));
        operaciones.save(Operacion.deTransferencia(destino.getId(), Operacion.TIPO_TRANSFERENCIA_RECIBIDA,
                reserva.getMonto(), destino.getSaldoDisponible(), reserva.getTransferenciaId(), huella, ahora));

        EventoDeTransferencia completada = aprobada.siguiente(EventoDeTransferencia.COMPLETADA, instante(), null,
                origen.getSaldoDisponible());
        outbox.registrar(Topicos.TRANSFERENCIAS, completada);
        log.info("Saga {} · {} → acreditado ${} en {} → {}", corto(aprobada), aprobada.tipo(), reserva.getMonto(),
                destino.getId(), completada.tipo());
        return Optional.of(completada);
    }

    @Transactional
    public Optional<EventoDeTransferencia> liberar(EventoDeTransferencia rechazada) {
        Optional<Reserva> vigente = reservaVigente(rechazada);
        if (vigente.isEmpty()) {
            return Optional.empty();
        }
        Reserva reserva = vigente.get();
        LocalDateTime ahora = ahora();
        Cuenta origen = cuentas.buscarParaActualizar(reserva.getCuentaOrigen()).orElseThrow();
        origen.acreditar(reserva.getMonto(), ahora);
        reserva.liberar(rechazada.motivo(), ahora);

        EventoDeTransferencia liberada = rechazada.siguiente(EventoDeTransferencia.RESERVA_LIBERADA, instante(),
                rechazada.motivo(), origen.getSaldoDisponible());
        outbox.registrar(Topicos.TRANSFERENCIAS, liberada);
        log.info("Saga {} · {} {} → compensacion: devuelto ${} a {} → {}", corto(rechazada), rechazada.tipo(),
                rechazada.motivo(), reserva.getMonto(), origen.getId(), liberada.tipo());
        return Optional.of(liberada);
    }

    /** La reserva de la transferencia, solo si sigue RESERVADA y el evento no se habia procesado. */
    private Optional<Reserva> reservaVigente(EventoDeTransferencia decision) {
        if (!primeraVez(decision)) {
            return Optional.empty();
        }
        Optional<Reserva> reserva = reservas.buscarParaActualizar(decision.transferenciaId());
        if (reserva.isEmpty() || !reserva.get().estaReservada()) {
            log.warn("Saga {} · {} ignorada: la reserva {}", corto(decision), decision.tipo(),
                    reserva.map(r -> "ya esta " + r.getEstado()).orElse("no existe"));
            return Optional.empty();
        }
        return reserva;
    }

    /** Registra el evento como procesado; falso si ya lo estaba (entrega repetida de Kafka). */
    private boolean primeraVez(EventoDeTransferencia evento) {
        if (procesados.existsById(evento.eventoId())) {
            log.info("Saga {} · {} duplicado (evento {}): se ignora", corto(evento), evento.tipo(), evento.eventoId());
            return false;
        }
        procesados.save(new EventoProcesado(evento.eventoId(), evento.tipo(), ahora()));
        return true;
    }

    private static String motivoDeRechazo(EventoDeTransferencia solicitud) {
        BigDecimal monto = solicitud.monto();
        if (monto == null || monto.signum() <= 0 || monto.stripTrailingZeros().scale() > 2) {
            return "MONTO_INVALIDO";
        }
        if (Objects.equals(solicitud.cuentaOrigen(), solicitud.cuentaDestino())) {
            return "MISMA_CUENTA";
        }
        // Evento v2: el monto viene con su moneda. Las cuentas del banco son en pesos chilenos.
        if (!EventoDeTransferencia.MONEDA_POR_OMISION.equals(solicitud.moneda())) {
            return "MONEDA_NO_SOPORTADA";
        }
        return null;
    }

    private static String huella(Reserva reserva) {
        String texto = reserva.getTransferenciaId() + "|" + reserva.getCuentaOrigen() + "|" + reserva.getCuentaDestino()
                + "|" + reserva.getMonto().toPlainString();
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(texto.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    private static String corto(EventoDeTransferencia evento) {
        return evento.transferenciaId() == null ? "?" : evento.transferenciaId().substring(0, 8);
    }

    private LocalDateTime ahora() {
        return LocalDateTime.now(reloj).truncatedTo(ChronoUnit.SECONDS);
    }

    private Instant instante() {
        return reloj.instant().truncatedTo(ChronoUnit.MILLIS);
    }
}
