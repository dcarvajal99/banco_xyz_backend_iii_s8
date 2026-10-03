package com.bancoxyz.auth.oauth;

/**
 * Scopes del banco. Cada servicio exige el suyo: un token solo sirve para lo que el cliente pidio y tenia permitido.
 */
public final class Alcances {

    /** Iniciar transferencias (POST en transferencias-service). */
    public static final String TRANSFERENCIAS_ESCRIBIR = "transferencias.escribir";
    /** Consultar el estado de las transferencias propias. */
    public static final String TRANSFERENCIAS_LEER = "transferencias.leer";
    /** Leer los avisos de notificaciones-service. */
    public static final String NOTIFICACIONES_LEER = "notificaciones.leer";
    /** Servicio a servicio: transferencias-service consulta una cuenta en el core. Ningun usuario lo recibe. */
    public static final String CORE_CUENTAS_LEER = "core.cuentas.leer";
    /** Operacion: rotar y retirar las claves de firma ({@code /actuator/claves}). Solo el cliente operacion-banco. */
    public static final String CLAVES_ADMINISTRAR = "claves.administrar";

    private Alcances() {
    }
}
