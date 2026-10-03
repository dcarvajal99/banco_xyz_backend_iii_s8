package com.bancoxyz.config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.config.server.EnableConfigServer;

/**
 * Configuracion centralizada del Banco XYZ.
 *
 * <p>Sirve los archivos de {@code configuracion/} a los microservicios y al gateway: lo que cambia por entorno
 * (direccion del discovery, timeouts, umbrales de los circuitos, limites del negocio) deja de estar repetido en cada
 * servicio. Backend {@code native} (sistema de archivos) para que el ecosistema arranque sin depender de un repositorio
 * remoto; en produccion el mismo servidor apunta a un repositorio git.</p>
 */
@SpringBootApplication
@EnableConfigServer
public class ConfigServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(ConfigServerApplication.class, args);
    }
}
