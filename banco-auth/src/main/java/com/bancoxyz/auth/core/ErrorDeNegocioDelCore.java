package com.bancoxyz.auth.core;

/**
 * Respuesta 4xx del core (clave incorrecta, usuario bloqueado, rol no permitido). Es una respuesta valida: no abre el
 * circuito ni se reintenta; el formulario de login la muestra como credenciales invalidas, usuario bloqueado o no habilitado.
 */
public class ErrorDeNegocioDelCore extends RuntimeException {

    private final int estado;
    private final String codigo;

    public ErrorDeNegocioDelCore(int estado, String codigo) {
        super("El core respondio " + estado + " " + codigo);
        this.estado = estado;
        this.codigo = codigo;
    }

    public int getEstado() {
        return estado;
    }

    public String getCodigo() {
        return codigo;
    }
}
