package com.bancoxyz.auth.oauth;

import java.io.Serializable;
import java.util.Collection;
import java.util.List;
import java.util.Map;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.core.user.OAuth2User;

/**
 * Persona que inicio sesion con GitHub y cuya cuenta esta vinculada a un cliente del banco. El nombre del principal es
 * el usuario del banco (es el {@code sub} de los tokens), no el login de GitHub: los servicios autorizan con los ids del
 * core igual que con el formulario.
 *
 * @param banco       el cliente del banco, con los ids que confirmo el core
 * @param githubId    id numerico de la cuenta de GitHub (el que se vincula)
 * @param githubLogin login de GitHub, solo informativo (va al token como {@code github_login})
 * @param atributos   lo que devolvio GitHub en /user, reducido a lo que se muestra
 */
public record UsuarioGitHub(UsuarioDelBanco banco, long githubId, String githubLogin, Map<String, Object> atributos)
        implements OAuth2User, Serializable {

    @Override
    public Map<String, Object> getAttributes() {
        return atributos;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + banco.rol()));
    }

    @Override
    public String getName() {
        return banco.usuario();
    }
}
