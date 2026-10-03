package com.bancoxyz.eureka;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.server.EnableEurekaServer;

/**
 * Service Discovery del Banco XYZ.
 *
 * <p>Cada microservicio se registra aqui al arrancar y el gateway resuelve por nombre ({@code lb://MS-CUENTAS}) en vez
 * de por URL fija: se puede mover o replicar un servicio sin tocar la configuracion de quien lo llama.</p>
 */
@SpringBootApplication
@EnableEurekaServer
public class EurekaServerApplication {

    public static void main(String[] args) {
        SpringApplication.run(EurekaServerApplication.class, args);
    }
}
