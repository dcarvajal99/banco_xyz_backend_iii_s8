package com.bancoxyz.transferencias;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * API de transferencias del Banco XYZ e inicio de la saga coreografiada.
 *
 * <p>Recibe la transferencia, la guarda PENDIENTE y responde 202 de inmediato: el resultado lo deciden despues el core
 * (reserva de fondos) y antifraude, comunicandose por eventos en Kafka. Este servicio escucha esos resultados y deja la
 * transferencia en su estado final.</p>
 */
@SpringBootApplication
@ConfigurationPropertiesScan
@EnableScheduling
public class TransferenciasApplication {

    public static void main(String[] args) {
        SpringApplication.run(TransferenciasApplication.class, args);
    }
}
