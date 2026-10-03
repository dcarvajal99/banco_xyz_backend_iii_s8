package com.bancoxyz.transferencias.transferencia;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import java.util.UUID;

import com.bancoxyz.transferencias.core.ClienteCore;
import com.bancoxyz.transferencias.core.ErrorDeNegocioDelCore;
import com.bancoxyz.transferencias.core.Validacion;
import com.bancoxyz.transferencias.evento.EventoDeTransferencia;
import com.bancoxyz.transferencias.evento.Topicos;
import com.bancoxyz.transferencias.outbox.Outbox;
import com.bancoxyz.transferencias.seguridad.UsuarioDelToken;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Inicio de la saga y seguimiento de su resultado.
 *
 * <p>{@link #solicitar}: prevalida la cuenta de origen con el core (fuera de la transaccion: no se retiene una conexion
 * a la base esperando a otro servicio), y guarda la transferencia PENDIENTE con su evento TransferenciaSolicitada en el
 * outbox, en la misma transaccion. {@link #aplicar}: cada resultado de la saga mueve la transferencia a su estado.</p>
 */
@Service
public class ServicioDeTransferencias {

    private static final Logger log = LoggerFactory.getLogger(ServicioDeTransferencias.class);

    /** Resultado de una solicitud: la transferencia y si era un reintento con la misma clave. */
    public record Resultado(TransferenciaDto transferencia, boolean repetida) {
    }

    private final RepositorioTransferencias transferencias;
    private final RepositorioHistorial historial;
    private final RepositorioEventosProcesados procesados;
    private final ClienteCore core;
    private final Outbox outbox;
    private final TransactionTemplate transaccion;
    private final Clock reloj;

    ServicioDeTransferencias(RepositorioTransferencias transferencias, RepositorioHistorial historial,
                             RepositorioEventosProcesados procesados, ClienteCore core, Outbox outbox,
                             TransactionTemplate transaccion, Clock reloj) {
        this.transferencias = transferencias;
        this.historial = historial;
        this.procesados = procesados;
        this.core = core;
        this.outbox = outbox;
        this.transaccion = transaccion;
        this.reloj = reloj;
    }

    public Resultado solicitar(UsuarioDelToken usuario, SolicitudTransferencia solicitud, String clave) {
        Optional<Resultado> previa = repetida(usuario, solicitud, clave);
        if (previa.isPresent()) {
            return previa.get();
        }
        if (solicitud.cuentaOrigen().equals(solicitud.cuentaDestino())) {
            throw new ErrorDeTransferencia(HttpStatus.UNPROCESSABLE_ENTITY, "MISMA_CUENTA",
                    "La cuenta de origen y la de destino son la misma");
        }
        Validacion validacion;
        try {
            validacion = core.validarCuentaDeOrigen(usuario.usuarioId(), solicitud.cuentaOrigen());
        } catch (ErrorDeNegocioDelCore error) {
            // 404 del core: la cuenta no existe o no es del usuario (el core no distingue, para no confirmar que existe).
            throw new ErrorDeTransferencia(HttpStatus.NOT_FOUND, "CUENTA_ORIGEN_NO_ENCONTRADA",
                    "La cuenta de origen no existe o no es suya");
        }
        return transaccion.execute(estado -> {
            Optional<Resultado> carrera = repetida(usuario, solicitud, clave);
            if (carrera.isPresent()) {
                return carrera.get();
            }
            LocalDateTime ahora = ahora();
            Transferencia nueva = transferencias.save(new Transferencia(UUID.randomUUID().toString(), usuario.clienteId(),
                    usuario.usuarioId(), solicitud.cuentaOrigen(), solicitud.cuentaDestino(), solicitud.monto(),
                    validacion, clave, ahora));
            EventoDeTransferencia evento = new EventoDeTransferencia(UUID.randomUUID().toString(),
                    EventoDeTransferencia.SOLICITADA, nueva.getId(), instante(), usuario.clienteId(), usuario.usuarioId(),
                    solicitud.cuentaOrigen(), solicitud.cuentaDestino(), solicitud.monto(), validacion.name(), null, null);
            outbox.registrar(Topicos.SOLICITADAS, evento);
            historial.save(new PasoDelHistorial(nueva.getId(), EventoDeTransferencia.SOLICITADA,
                    "validacion " + validacion.name(), ahora));
            log.info("Transferencia {} solicitada: {}→{} ${} (validacion {})", nueva.getId().substring(0, 8),
                    solicitud.cuentaOrigen(), solicitud.cuentaDestino(), solicitud.monto(), validacion);
            return new Resultado(dto(nueva), false);
        });
    }

    @Transactional(readOnly = true)
    public TransferenciaDto consultar(UsuarioDelToken usuario, String id) {
        return transferencias.findById(id)
                .filter(t -> t.getClienteId() == usuario.clienteId())
                .map(this::dto)
                .orElseThrow(() -> new ErrorDeTransferencia(HttpStatus.NOT_FOUND, "TRANSFERENCIA_NO_ENCONTRADA",
                        "No existe una transferencia suya con ese id"));
    }

    /** Aplica un resultado de la saga. Idempotente: un evento repetido o atrasado no cambia nada. */
    @Transactional
    public void aplicar(EventoDeTransferencia evento) {
        if (procesados.existsById(evento.eventoId())) {
            log.info("Transferencia {} · {} duplicado: se ignora", corto(evento), evento.tipo());
            return;
        }
        procesados.save(new EventoProcesado(evento.eventoId(), evento.tipo(), ahora()));
        Transferencia.Estado nuevo = switch (evento.tipo()) {
            case EventoDeTransferencia.FONDOS_RESERVADOS -> Transferencia.Estado.FONDOS_RESERVADOS;
            case EventoDeTransferencia.COMPLETADA -> Transferencia.Estado.COMPLETADA;
            case EventoDeTransferencia.FONDOS_RECHAZADOS, EventoDeTransferencia.RESERVA_LIBERADA -> Transferencia.Estado.RECHAZADA;
            default -> null;
        };
        if (nuevo == null) {
            return;
        }
        Optional<Transferencia> transferencia = transferencias.buscarParaActualizar(evento.transferenciaId());
        if (transferencia.isEmpty()) {
            log.warn("Transferencia {} · {} de una transferencia desconocida: se ignora", corto(evento), evento.tipo());
            return;
        }
        LocalDateTime ahora = ahora();
        boolean avanzo = transferencia.get().avanzarA(nuevo, evento.motivo(), ahora);
        historial.save(new PasoDelHistorial(evento.transferenciaId(), evento.tipo(),
                (evento.motivo() == null ? "" : evento.motivo()) + (avanzo ? "" : " (llego tarde: no cambia el estado)"), ahora));
        log.info("Transferencia {} · {}{} → estado {}", corto(evento), evento.tipo(),
                evento.motivo() == null ? "" : " " + evento.motivo(), transferencia.get().getEstado());
    }

    private Optional<Resultado> repetida(UsuarioDelToken usuario, SolicitudTransferencia solicitud, String clave) {
        return transferencias.findByClienteIdAndClaveIdempotencia(usuario.clienteId(), clave).map(previa -> {
            if (!previa.mismaSolicitud(solicitud.cuentaOrigen(), solicitud.cuentaDestino(), solicitud.monto())) {
                throw new ErrorDeTransferencia(HttpStatus.CONFLICT, "IDEMPOTENCIA_CONFLICTO",
                        "Esa clave de idempotencia ya se uso con otra transferencia");
            }
            return new Resultado(dto(previa), true);
        });
    }

    private TransferenciaDto dto(Transferencia transferencia) {
        return TransferenciaDto.desde(transferencia, historial.findByTransferenciaIdOrderByIdAsc(transferencia.getId()));
    }

    private static String corto(EventoDeTransferencia evento) {
        return evento.transferenciaId().substring(0, Math.min(8, evento.transferenciaId().length()));
    }

    private LocalDateTime ahora() {
        return LocalDateTime.now(reloj).truncatedTo(ChronoUnit.MILLIS);
    }

    private Instant instante() {
        return reloj.instant().truncatedTo(ChronoUnit.MILLIS);
    }
}
