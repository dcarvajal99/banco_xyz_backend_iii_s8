package com.bancoxyz.transferencias.transferencia;

import java.time.LocalDateTime;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** Un evento de la saga que toco la transferencia: la traza que ve el cliente en GET /transferencias/{id}. */
@Entity
@Table(name = "historial", schema = "transferencias")
public class PasoDelHistorial {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String transferenciaId;
    private String evento;
    private String detalle;
    private LocalDateTime ocurridoEn;

    protected PasoDelHistorial() {
    }

    public PasoDelHistorial(String transferenciaId, String evento, String detalle, LocalDateTime ocurridoEn) {
        this.transferenciaId = transferenciaId;
        this.evento = evento;
        this.detalle = detalle;
        this.ocurridoEn = ocurridoEn;
    }

    public String getEvento() {
        return evento;
    }

    public String getDetalle() {
        return detalle;
    }

    public LocalDateTime getOcurridoEn() {
        return ocurridoEn;
    }
}
