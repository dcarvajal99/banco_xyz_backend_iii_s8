package com.bancoxyz.auth.config;

import java.util.Map;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Inicio de sesion con GitHub (identidad federada).
 *
 * @param vinculos cuentas de GitHub vinculadas a un usuario del banco: id numerico de GitHub = usuario del banco. Se
 *                 vincula por el id y no por el login, porque un login de GitHub se puede cambiar y otra persona podria
 *                 tomar el nombre liberado. Llegan del Config Server ({@code configuracion/banco-auth.properties}).
 */
@ConfigurationProperties(prefix = "banco.auth.github")
public record PropiedadesGitHub(Map<String, String> vinculos) {

    public PropiedadesGitHub {
        vinculos = vinculos == null ? Map.of() : Map.copyOf(vinculos);
    }
}
