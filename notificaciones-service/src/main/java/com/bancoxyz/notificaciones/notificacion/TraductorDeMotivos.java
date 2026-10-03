package com.bancoxyz.notificaciones.notificacion;

import java.util.Map;

/**
 * Los motivos de rechazo de la saga (los pone el core al no reservar, o antifraude al rechazar y que el core
 * compensa) son codigos internos; el cliente recibe una frase. Un motivo que no esta en la tabla se muestra tal cual,
 * para no ocultar un caso nuevo que todavia no se tradujo.
 */
final class TraductorDeMotivos {

    private static final Map<String, String> FRASES = Map.ofEntries(
            Map.entry("SALDO_INSUFICIENTE", "saldo insuficiente"),
            Map.entry("CUENTA_AJENA", "la cuenta de origen no le pertenece"),
            Map.entry("CUENTA_ORIGEN_INEXISTENTE", "la cuenta de origen no existe"),
            Map.entry("CUENTA_DESTINO_INEXISTENTE", "la cuenta de destino no existe"),
            Map.entry("MISMA_CUENTA", "la cuenta de origen y la de destino son la misma"),
            Map.entry("CUENTA_NO_ADMITE_RETIROS", "la cuenta de origen no admite retiros"),
            Map.entry("MONTO_INVALIDO", "el monto no es valido"),
            Map.entry("MONTO_SOBRE_LIMITE", "el monto supera el limite permitido"),
            Map.entry("CUENTA_EN_OBSERVACION", "una de las cuentas esta en observacion"));

    private TraductorDeMotivos() {
    }

    static String traducir(String motivo) {
        if (motivo == null) {
            return "motivo no informado";
        }
        return FRASES.getOrDefault(motivo, motivo);
    }
}
