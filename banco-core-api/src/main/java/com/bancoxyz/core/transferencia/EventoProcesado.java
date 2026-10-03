package com.bancoxyz.core.transferencia;

import java.time.LocalDateTime;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** Registro de un evento ya aplicado: la base de la idempotencia del consumidor. */
@Entity
@Table(name = "evento_procesado", schema = "core")
public class EventoProcesado {

    @Id
    private String eventoId;
    private String tipo;
    private LocalDateTime procesadoEn;

    protected EventoProcesado() {
    }

    public EventoProcesado(String eventoId, String tipo, LocalDateTime procesadoEn) {
        this.eventoId = eventoId;
        this.tipo = tipo;
        this.procesadoEn = procesadoEn;
    }
}
