package com.bancoxyz.auth.config;

import java.time.Duration;
import java.util.List;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * @param emisor           valor del claim {@code iss}: la URL con que los servicios conocen a banco-auth
 * @param audiencia        valor del claim {@code aud}: los servicios del banco solo aceptan tokens emitidos para ellos
 * @param duracionToken    vida del access token; tambien es el tiempo de gracia de una clave retirada en el JWK Set
 * @param duracionRefresco vida del refresh token (se renueva en cada uso)
 * @param bancaWeb         aplicacion de banca en linea: authorization_code + PKCE + refresh token
 * @param transferencias   transferencias-service como cliente: client_credentials para consultar el core
 * @param operacion        la operacion del banco: client_credentials para administrar las claves de firma
 */
@ConfigurationProperties(prefix = "banco.auth")
public record PropiedadesAuth(String emisor, String audiencia, Duration duracionToken, Duration duracionRefresco,
                              Cliente bancaWeb, Cliente transferencias, Cliente operacion) {

    /** Un cliente OAuth registrado: id, secreto (llega por variable de entorno) y, si aplica, sus redirect URIs. */
    public record Cliente(String id, String secreto, List<String> redirectUris) {
    }
}
