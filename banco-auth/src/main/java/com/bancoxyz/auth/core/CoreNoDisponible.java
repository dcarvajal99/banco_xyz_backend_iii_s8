package com.bancoxyz.auth.core;

/** El core no respondio o el circuito esta abierto: sin el core no se puede verificar una clave, no se emite token. */
public class CoreNoDisponible extends RuntimeException {

    public CoreNoDisponible(Throwable causa) {
        super("El core no esta disponible para verificar la clave", causa);
    }
}
