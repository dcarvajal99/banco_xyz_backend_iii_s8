package com.bancoxyz.notificaciones.notificacion;

import java.math.BigDecimal;

/**
 * Formato chileno de montos: punto para los miles, coma para los decimales (si los hay), sin usar
 * {@code NumberFormat} para no depender de que el JDK tenga bien cargada la configuracion regional {@code es-CL}.
 * Ejemplos: {@code 15000.00 -> "$15.000"}, {@code 1500.50 -> "$1.500,5"}.
 */
final class FormateadorDeMonto {

    private FormateadorDeMonto() {
    }

    static String formatear(BigDecimal monto) {
        if (monto == null) {
            return "$0";
        }
        BigDecimal normalizado = monto.stripTrailingZeros();
        if (normalizado.scale() < 0) {
            normalizado = normalizado.setScale(0);
        }
        String[] partes = normalizado.toPlainString().split("\\.");
        String entero = agruparMiles(partes[0]);
        if (partes.length > 1 && !partes[1].isEmpty()) {
            return "$" + entero + "," + partes[1];
        }
        return "$" + entero;
    }

    private static String agruparMiles(String numero) {
        boolean negativo = numero.startsWith("-");
        String digitos = negativo ? numero.substring(1) : numero;
        StringBuilder invertido = new StringBuilder();
        for (int i = digitos.length() - 1, contador = 0; i >= 0; i--, contador++) {
            if (contador > 0 && contador % 3 == 0) {
                invertido.append('.');
            }
            invertido.append(digitos.charAt(i));
        }
        return (negativo ? "-" : "") + invertido.reverse();
    }
}
