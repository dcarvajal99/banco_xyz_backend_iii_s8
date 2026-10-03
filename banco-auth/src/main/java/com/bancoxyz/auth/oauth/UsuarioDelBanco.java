package com.bancoxyz.auth.oauth;

import java.io.Serializable;

import org.springframework.security.core.AuthenticatedPrincipal;

/**
 * Usuario que inicio sesion en banco-auth, con los ids del core que van al token para que los servicios autoricen
 * (transferir solo desde cuentas propias, ver solo los avisos propios).
 */
public record UsuarioDelBanco(String usuario, long usuarioId, Long clienteId, String rol)
        implements AuthenticatedPrincipal, Serializable {

    @Override
    public String getName() {
        return usuario;
    }
}
