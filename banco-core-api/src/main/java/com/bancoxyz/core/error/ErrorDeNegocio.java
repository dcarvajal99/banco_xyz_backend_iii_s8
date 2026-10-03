package com.bancoxyz.core.error;

import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;

import org.springframework.http.HttpStatus;

/**
 * Error esperable del negocio que se entrega al BFF como ProblemDetail con un {@code codigo}.
 *
 * <p>El codigo es el contrato: los BFF traducen por codigo, no por el texto del detalle.</p>
 */
public class ErrorDeNegocio extends RuntimeException {

    private final HttpStatus estado;
    private final String codigo;
    private final String titulo;
    private final Map<String, Object> extras = new LinkedHashMap<>();

    public ErrorDeNegocio(HttpStatus estado, String codigo, String titulo, String detalle) {
        super(detalle);
        this.estado = estado;
        this.codigo = codigo;
        this.titulo = titulo;
    }

    /** Agrega una propiedad extra al ProblemDetail, por ejemplo {@code intentosRestantes}. */
    public ErrorDeNegocio con(String clave, Object valor) {
        extras.put(clave, valor);
        return this;
    }

    public HttpStatus getEstado() {
        return estado;
    }

    public String getCodigo() {
        return codigo;
    }

    public String getTitulo() {
        return titulo;
    }

    public Map<String, Object> getExtras() {
        return Collections.unmodifiableMap(extras);
    }
}
