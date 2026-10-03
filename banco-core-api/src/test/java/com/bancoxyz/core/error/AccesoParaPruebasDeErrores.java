package com.bancoxyz.core.error;

import org.springframework.http.HttpStatusCode;

public final class AccesoParaPruebasDeErrores {

    private AccesoParaPruebasDeErrores() {
    }

    public static String codigo(HttpStatusCode estado) {
        return ManejadorDeErrores.codigoPorEstado(estado);
    }
}
