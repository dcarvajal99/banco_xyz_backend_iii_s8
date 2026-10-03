package com.bancoxyz.transferencias.seguridad;

import org.springframework.security.oauth2.jwt.Jwt;

/** Lo que este servicio usa del JWT de banco-auth: quien es el usuario y de que cliente es. */
public record UsuarioDelToken(long usuarioId, long clienteId, String usuario) {

    public static UsuarioDelToken desde(Jwt jwt) {
        Number usuarioId = jwt.getClaim("usuario_id");
        Number clienteId = jwt.getClaim("cliente_id");
        if (usuarioId == null || clienteId == null) {
            throw new IllegalArgumentException("El token no trae usuario_id y cliente_id");
        }
        return new UsuarioDelToken(usuarioId.longValue(), clienteId.longValue(), jwt.getSubject());
    }
}
