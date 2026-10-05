package com.bancoxyz.auth.config;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Inicio de sesion con GitHub (identidad federada).
 *
 * @param vinculos            cuentas de GitHub vinculadas a un usuario del banco: id numerico de GitHub = usuario del
 *                            banco. Se vincula por el id y no por el login, porque un login de GitHub se puede cambiar y
 *                            otra persona podria tomar el nombre liberado. Llegan del Config Server
 *                            ({@code configuracion/banco-auth.properties}).
 * @param vinculosAdicionales vinculos que agrega quien levanta el ecosistema, sin tocar el Config Server: variable
 *                            {@code BANCO_GITHUB_VINCULOS} del {@code .env}, con el formato {@code id=usuario,id=usuario}.
 */
@ConfigurationProperties(prefix = "banco.auth.github")
public record PropiedadesGitHub(Map<String, String> vinculos, String vinculosAdicionales) {

    public PropiedadesGitHub {
        vinculos = vinculos == null ? Map.of() : Map.copyOf(vinculos);
        vinculosAdicionales = vinculosAdicionales == null ? "" : vinculosAdicionales;
    }

    /** Usuario del banco vinculado a esa cuenta de GitHub: primero los vinculos centrales, despues los adicionales. */
    public Optional<String> usuarioVinculado(long githubId) {
        String clave = String.valueOf(githubId);
        return Optional.ofNullable(vinculos.get(clave)).or(() -> Optional.ofNullable(adicionales().get(clave)));
    }

    /** Los vinculos adicionales leidos de {@code id=usuario,id=usuario}; una entrada mal escrita se ignora. */
    public Map<String, String> adicionales() {
        Map<String, String> resultado = new LinkedHashMap<>();
        for (String entrada : vinculosAdicionales.split(",")) {
            String[] partes = entrada.trim().split("=", 2);
            if (partes.length == 2 && partes[0].trim().matches("\\d+") && !partes[1].isBlank()) {
                resultado.put(partes[0].trim(), partes[1].trim());
            }
        }
        return resultado;
    }
}
