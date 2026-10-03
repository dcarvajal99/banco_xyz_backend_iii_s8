package com.bancoxyz.antifraude;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

/**
 * Participante de la saga coreografiada de transferencias del Banco XYZ.
 *
 * <p>No es dueno de ningun dato: consume {@code FondosReservados} del topico {@code cuentas.reservas}, evalua reglas de
 * riesgo (monto maximo, cuentas en observacion) y publica en {@code antifraude.decisiones} la aprobacion o el rechazo.
 * Es stateless -no tiene base de datos- y se puede escalar corriendo dos instancias en el mismo grupo de consumidores:
 * Kafka reparte las particiones del topico entre ellas.</p>
 */
@SpringBootApplication
@ConfigurationPropertiesScan
public class AntifraudeServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(AntifraudeServiceApplication.class, args);
    }
}
