package com.bancoxyz.transferencias.transferencia;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.bancoxyz.transferencias.core.Validacion;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Una transferencia vista por el cliente. Su estado solo avanza: PENDIENTE → FONDOS_RESERVADOS → COMPLETADA o
 * RECHAZADA. Los estados finales no cambian mas: un evento atrasado (llega por otro topico, en otro orden) no los pisa.
 */
@Entity
@Table(name = "transferencia", schema = "transferencias")
public class Transferencia {

    public enum Estado {
        PENDIENTE, FONDOS_RESERVADOS, COMPLETADA, RECHAZADA;

        boolean esFinal() {
            return this == COMPLETADA || this == RECHAZADA;
        }
    }

    @Id
    private String id;
    private Long clienteId;
    private Long usuarioId;
    private Long cuentaOrigen;
    private Long cuentaDestino;
    private BigDecimal monto;
    @Enumerated(EnumType.STRING)
    private Estado estado;
    private String motivo;
    @Enumerated(EnumType.STRING)
    private Validacion validacion;
    private String claveIdempotencia;
    private LocalDateTime creadaEn;
    private LocalDateTime actualizadaEn;

    protected Transferencia() {
    }

    public Transferencia(String id, long clienteId, long usuarioId, long cuentaOrigen, long cuentaDestino,
                         BigDecimal monto, Validacion validacion, String claveIdempotencia, LocalDateTime ahora) {
        this.id = id;
        this.clienteId = clienteId;
        this.usuarioId = usuarioId;
        this.cuentaOrigen = cuentaOrigen;
        this.cuentaDestino = cuentaDestino;
        this.monto = monto;
        this.estado = Estado.PENDIENTE;
        this.validacion = validacion;
        this.claveIdempotencia = claveIdempotencia;
        this.creadaEn = ahora;
        this.actualizadaEn = ahora;
    }

    /** Aplica el nuevo estado si hace avanzar la transferencia; falso si llego tarde o repetido. */
    boolean avanzarA(Estado nuevo, String nuevoMotivo, LocalDateTime ahora) {
        if (estado.esFinal() || (nuevo.ordinal() <= estado.ordinal() && !nuevo.esFinal())) {
            return false;
        }
        estado = nuevo;
        motivo = nuevoMotivo;
        actualizadaEn = ahora;
        return true;
    }

    /** Misma solicitud que la original (para decidir si una clave idempotente repetida es un reintento o un conflicto). */
    public boolean mismaSolicitud(long origen, long destino, BigDecimal otroMonto) {
        return cuentaOrigen == origen && cuentaDestino == destino && monto.compareTo(otroMonto) == 0;
    }

    public String getId() {
        return id;
    }

    public Long getClienteId() {
        return clienteId;
    }

    public Long getUsuarioId() {
        return usuarioId;
    }

    public Long getCuentaOrigen() {
        return cuentaOrigen;
    }

    public Long getCuentaDestino() {
        return cuentaDestino;
    }

    public BigDecimal getMonto() {
        return monto;
    }

    public Estado getEstado() {
        return estado;
    }

    public String getMotivo() {
        return motivo;
    }

    public Validacion getValidacion() {
        return validacion;
    }

    public LocalDateTime getCreadaEn() {
        return creadaEn;
    }

    public LocalDateTime getActualizadaEn() {
        return actualizadaEn;
    }
}
