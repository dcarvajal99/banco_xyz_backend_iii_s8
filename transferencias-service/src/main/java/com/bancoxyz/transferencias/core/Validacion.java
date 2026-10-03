package com.bancoxyz.transferencias.core;

/**
 * Como se valido la cuenta de origen antes de aceptar la transferencia.
 *
 * <p>PREVIA: el core confirmo que la cuenta existe y es del usuario. DIFERIDA: el core no respondio (circuito abierto o
 * sin conexion) y la transferencia se acepto igual; el core la valida al reservar los fondos, que es la validacion que
 * manda. Asi una caida del core no impide recibir transferencias: quedan en Kafka y se procesan cuando vuelve.</p>
 */
public enum Validacion {
    PREVIA, DIFERIDA
}
