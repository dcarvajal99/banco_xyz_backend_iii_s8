package com.bancoxyz.core.cierre;

/** Lo que hizo una sincronizacion del cierre. Se imprime al arrancar y lo usan las pruebas. */
public record ResumenSincronizacion(boolean hayCierre, Long jobExecutionId, String calidad, int cuentasNuevas,
                                    int cuentasExistentes, int clientesNuevos, int usuariosNuevos,
                                    int tarjetasNuevas) {

    static ResumenSincronizacion sinCierre() {
        return new ResumenSincronizacion(false, null, null, 0, 0, 0, 0, 0);
    }
}
