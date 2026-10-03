package com.bancoxyz.auth;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Servidor de autorizacion OAuth 2.0 / OpenID Connect del Banco XYZ (Spring Authorization Server).
 *
 * <p>Emite tokens por dos flujos estandar: authorization_code con PKCE para la banca en linea (el usuario inicia sesion
 * aqui y el core verifica su clave) y client_credentials para los servicios. Los firma con RS256 y claves que rotan; los
 * servicios validan con el JWK Set publico ({@code /oauth2/jwks}) sin compartir ningun secreto con este proceso.</p>
 */
@SpringBootApplication
@ConfigurationPropertiesScan
@EnableScheduling
public class BancoAuthApplication {

    public static void main(String[] args) {
        SpringApplication.run(BancoAuthApplication.class, args);
    }
}
