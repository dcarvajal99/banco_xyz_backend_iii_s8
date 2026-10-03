package com.bancoxyz.core.cierre;

import org.springframework.beans.factory.SmartInitializingSingleton;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * Sincroniza el cierre publicado durante el arranque, ANTES de que el servidor acepte solicitudes.
 *
 * <p>Con un {@code ApplicationRunner} el puerto ya estaba abierto y {@code /actuator/health} respondia
 * UP mientras las cuentas todavia se estaban abriendo: un BFF que llegara en ese segundo veia un banco
 * sin cuentas. {@link SmartInitializingSingleton} corre cuando todos los beans (Flyway, JPA,
 * transacciones) estan listos, pero antes de que arranque Tomcat.</p>
 *
 * <p>Se apaga en las pruebas ({@code banco.core.sincronizar-al-iniciar=false}): alli la
 * sincronizacion la dispara cada prueba sobre sus propios datos.</p>
 */
@Component
@ConditionalOnProperty(name = "banco.core.sincronizar-al-iniciar", havingValue = "true")
public class ArranqueConSincronizacion implements SmartInitializingSingleton {

    private final SincronizadorDeCierre sincronizador;

    public ArranqueConSincronizacion(SincronizadorDeCierre sincronizador) {
        this.sincronizador = sincronizador;
    }

    @Override
    public void afterSingletonsInstantiated() {
        sincronizador.sincronizar();
    }
}
