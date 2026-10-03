package com.bancoxyz.transferencias.core;

/** Respuesta 4xx del core (cuenta inexistente o ajena). No abre el circuito, no se reintenta y no tiene fallback. */
public class ErrorDeNegocioDelCore extends RuntimeException {

    private final int estado;

    public ErrorDeNegocioDelCore(int estado) {
        super("El core respondio " + estado);
        this.estado = estado;
    }

    public int getEstado() {
        return estado;
    }
}
