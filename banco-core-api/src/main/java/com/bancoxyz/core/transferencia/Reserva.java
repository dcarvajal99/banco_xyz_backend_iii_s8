package com.bancoxyz.core.transferencia;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** Estado de una transferencia dentro del core: el monto retenido en la cuenta de origen y que paso con el. */
@Entity
@Table(name = "reserva", schema = "core")
public class Reserva {

    public enum Estado { RESERVADA, RECHAZADA, CONFIRMADA, LIBERADA }

    @Id
    @Column(name = "transferencia_id")
    private String transferenciaId;
    private Long clienteId;
    private Long cuentaOrigen;
    private Long cuentaDestino;
    private BigDecimal monto;
    @Enumerated(EnumType.STRING)
    private Estado estado;
    private String motivo;
    private LocalDateTime creadaEn;
    private LocalDateTime actualizadaEn;

    protected Reserva() {
    }

    private Reserva(EventoDeTransferencia solicitud, BigDecimal monto, Estado estado, String motivo, LocalDateTime ahora) {
        this.transferenciaId = solicitud.transferenciaId();
        this.clienteId = solicitud.clienteId();
        this.cuentaOrigen = solicitud.cuentaOrigen();
        this.cuentaDestino = solicitud.cuentaDestino();
        this.monto = monto;
        this.estado = estado;
        this.motivo = motivo;
        this.creadaEn = ahora;
        this.actualizadaEn = ahora;
    }

    static Reserva reservada(EventoDeTransferencia solicitud, BigDecimal monto, LocalDateTime ahora) {
        return new Reserva(solicitud, monto, Estado.RESERVADA, null, ahora);
    }

    static Reserva rechazada(EventoDeTransferencia solicitud, BigDecimal monto, String motivo, LocalDateTime ahora) {
        return new Reserva(solicitud, monto, Estado.RECHAZADA, motivo, ahora);
    }

    void confirmar(LocalDateTime ahora) {
        cambiar(Estado.CONFIRMADA, null, ahora);
    }

    void liberar(String motivoDeRechazo, LocalDateTime ahora) {
        cambiar(Estado.LIBERADA, motivoDeRechazo, ahora);
    }

    private void cambiar(Estado nuevo, String nuevoMotivo, LocalDateTime ahora) {
        if (estado != Estado.RESERVADA) {
            throw new IllegalStateException("La reserva " + transferenciaId + " ya esta " + estado);
        }
        estado = nuevo;
        motivo = nuevoMotivo;
        actualizadaEn = ahora;
    }

    public boolean estaReservada() {
        return estado == Estado.RESERVADA;
    }

    public String getTransferenciaId() {
        return transferenciaId;
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
}
