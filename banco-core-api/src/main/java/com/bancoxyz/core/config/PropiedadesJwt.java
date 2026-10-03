package com.bancoxyz.core.config;

import java.time.Duration;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * @param emisor       {@code iss} esperado (banco-auth)
 * @param audiencia    {@code aud} esperada
 * @param jwkSetUri    JWK Set de banco-auth
 * @param cacheJwks    cuanto se guarda la copia del JWK Set; una clave desconocida fuerza a consultarlo antes
 */
@ConfigurationProperties(prefix = "banco.jwt")
public record PropiedadesJwt(String emisor, String audiencia, String jwkSetUri, Duration cacheJwks) {
}
