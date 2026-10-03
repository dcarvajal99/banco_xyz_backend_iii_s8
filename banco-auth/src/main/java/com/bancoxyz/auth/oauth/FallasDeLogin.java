package com.bancoxyz.auth.oauth;

import java.io.IOException;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.AuthenticationServiceException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.web.authentication.AuthenticationFailureHandler;

/**
 * Traduce el motivo del rechazo a un codigo en la URL del login, sin exponer el mensaje interno: la pagina muestra un
 * texto fijo por codigo. Clave mala y usuario inexistente comparten codigo para no revelar que usuarios existen. Sirve
 * para el formulario y para "Ingresar con GitHub" (los rechazos de {@link VinculacionGitHub} y los de GitHub mismo,
 * como un state que no calza o el usuario que no autoriza la aplicacion).
 */
class FallasDeLogin implements AuthenticationFailureHandler {

    @Override
    public void onAuthenticationFailure(HttpServletRequest solicitud, HttpServletResponse respuesta,
                                        AuthenticationException excepcion) throws IOException {
        String codigo = "credenciales";
        if (excepcion instanceof OAuth2AuthenticationException oauth2) {
            String error = oauth2.getError().getErrorCode();
            codigo = VinculacionGitHub.NO_VINCULADA.equals(error) ? "github-no-vinculado"
                    : VinculacionGitHub.BLOQUEADO.equals(error) ? "bloqueado"
                    : VinculacionGitHub.NO_HABILITADO.equals(error) ? "no-habilitado"
                    : VinculacionGitHub.SERVICIO.equals(error) ? "servicio"
                    : "github";
        } else if (excepcion instanceof AuthenticationServiceException) {
            codigo = "servicio";
        } else if (excepcion instanceof LockedException) {
            codigo = "bloqueado";
        } else if (excepcion instanceof DisabledException) {
            codigo = "no-habilitado";
        }
        respuesta.sendRedirect(solicitud.getContextPath() + "/login?error=" + codigo);
    }
}
