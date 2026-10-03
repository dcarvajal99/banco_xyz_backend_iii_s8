package com.bancoxyz.notificaciones.notificacion;

import java.time.Instant;

/**
 * Una notificacion ya armada para el cliente. Es a la vez el modelo interno y la forma que devuelve la API: no hay
 * nada que traducir entre uno y otro.
 */
public record Notificacion(String tipo, String transferenciaId, String texto, Instant ocurridoEn) {
}
