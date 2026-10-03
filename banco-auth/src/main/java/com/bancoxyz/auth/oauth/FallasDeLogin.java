package com.bancoxyz.auth.oauth;

import java.io.IOException;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.AuthenticationServiceException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.authentication.AuthenticationFailureHandler;

/**
 * Traduce el motivo del rechazo a un codigo en la URL del login, sin exponer el mensaje interno: la pagina muestra un
 * texto fijo por codigo. Clave mala y usuario inexistente comparten codigo para no revelar que usuarios existen.
 */
class FallasDeLogin implements AuthenticationFailureHandler {

    @Override
    public void onAuthenticationFailure(HttpServletRequest solicitud, HttpServletResponse respuesta,
                                        AuthenticationException excepcion) throws IOException {
        String codigo = "credenciales";
        if (excepcion instanceof AuthenticationServiceException) {
            codigo = "servicio";
        } else if (excepcion instanceof LockedException) {
            codigo = "bloqueado";
        } else if (excepcion instanceof DisabledException) {
            codigo = "no-habilitado";
        }
        respuesta.sendRedirect(solicitud.getContextPath() + "/login?error=" + codigo);
    }
}
