package com.bancoxyz.transferencias.transferencia;

import org.springframework.http.HttpStatus;

/** Rechazo de la API con estado HTTP y codigo, en el mismo formato ProblemDetail que el resto del banco. */
public class ErrorDeTransferencia extends RuntimeException {

    private final HttpStatus estado;
    private final String codigo;

    public ErrorDeTransferencia(HttpStatus estado, String codigo, String detalle) {
        super(detalle);
        this.estado = estado;
        this.codigo = codigo;
    }

    public HttpStatus getEstado() {
        return estado;
    }

    public String getCodigo() {
        return codigo;
    }
}
