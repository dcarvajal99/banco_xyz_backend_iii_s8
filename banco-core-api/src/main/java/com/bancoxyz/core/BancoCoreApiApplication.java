package com.bancoxyz.core;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

/**
 * Backend principal del Banco XYZ.
 *
 * <p>Es el unico duenno de los datos y de las reglas que deben cumplirse sin importar el canal:
 * no sobregirar, limite diario por tarjeta, bloqueo por PIN. No sabe nada de pantallas: entrega
 * datos completos y neutros, y cada BFF (web, movil, cajero) los adapta a su frontend.</p>
 *
 * <p>Lo llaman solo los tres BFF, cada uno con su propia credencial de servicio.</p>
 */
@SpringBootApplication
@ConfigurationPropertiesScan
public class BancoCoreApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(BancoCoreApiApplication.class, args);
    }
}
