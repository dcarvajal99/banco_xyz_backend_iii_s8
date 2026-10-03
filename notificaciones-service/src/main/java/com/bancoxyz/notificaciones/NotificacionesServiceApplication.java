package com.bancoxyz.notificaciones;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

/**
 * Consumidor final de la saga coreografiada de transferencias del Banco XYZ.
 *
 * <p>Escucha los resultados que le importan al cliente -una reserva rechazada por el core, una transferencia
 * completada o una compensacion tras el rechazo de antifraude- y arma una notificacion en espanol. No es dueno de
 * ningun dato de negocio: guarda las notificaciones en memoria, por cliente, y las expone en su propia API
 * (protegida con el mismo JWT que emite banco-auth).</p>
 */
@SpringBootApplication
@ConfigurationPropertiesScan
public class NotificacionesServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(NotificacionesServiceApplication.class, args);
    }
}
