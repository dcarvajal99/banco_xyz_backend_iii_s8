package com.bancoxyz.core.seguridad;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.springframework.core.convert.converter.Converter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;

/**
 * Autoridades de un token OAuth 2.0 de servicio (client_credentials) emitido por banco-auth.
 *
 * <p>Cada scope se vuelve {@code SCOPE_<scope>} y, ademas, el scope {@code core.cuentas.leer} da el rol del canal
 * TRANSFERENCIAS: asi {@link ControlDeAcceso} lo trata igual que antes, pero la credencial ya no es una clave Basic sino
 * un token firmado que vence en minutos. El certificado de cliente se sigue exigiendo ({@link FiltroCertificadoDeCanal}:
 * su CN debe ser el {@code sub} del token, el id del cliente OAuth).</p>
 */
public class TokensDeServicio implements Converter<Jwt, Collection<GrantedAuthority>> {

    static final String LEER_CUENTAS = "core.cuentas.leer";

    @Override
    public Collection<GrantedAuthority> convert(Jwt token) {
        List<String> scopes = token.getClaimAsStringList("scope");
        List<GrantedAuthority> autoridades = new ArrayList<>();
        if (scopes == null) {
            return autoridades;
        }
        for (String scope : scopes) {
            autoridades.add(new SimpleGrantedAuthority("SCOPE_" + scope));
        }
        if (scopes.contains(LEER_CUENTAS)) {
            autoridades.add(new SimpleGrantedAuthority("ROLE_" + Canal.TRANSFERENCIAS.rol()));
        }
        return autoridades;
    }
}
