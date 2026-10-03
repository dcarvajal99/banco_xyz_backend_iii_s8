package com.bancoxyz.auth.oauth;

import java.util.List;

import com.bancoxyz.auth.core.ClienteCore;
import com.bancoxyz.auth.core.CoreNoDisponible;
import com.bancoxyz.auth.core.ErrorDeNegocioDelCore;
import com.bancoxyz.auth.core.UsuarioAutenticado;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.AuthenticationServiceException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Component;

/**
 * Verifica usuario y clave del formulario de login contra el core, que es el dueno de las cuentas de usuario.
 *
 * <p>banco-auth no guarda claves: las comprueba el core (bcrypt) por el canal AUTENTICACION, con mTLS y Resilience4j
 * ({@link ClienteCore}). Cada respuesta del core se traduce a la excepcion de Spring Security que corresponde, y el
 * formulario muestra el error sin emitir nada.</p>
 */
@Component
public class ProveedorDeAutenticacionDelCore implements AuthenticationProvider {

    private final ClienteCore core;

    public ProveedorDeAutenticacionDelCore(ClienteCore core) {
        this.core = core;
    }

    @Override
    public Authentication authenticate(Authentication solicitud) throws AuthenticationException {
        String usuario = solicitud.getName();
        String clave = solicitud.getCredentials() == null ? "" : solicitud.getCredentials().toString();
        try {
            UsuarioAutenticado autenticado = core.autenticar(usuario, clave);
            UsuarioDelBanco principal = new UsuarioDelBanco(autenticado.usuario(), autenticado.usuarioId(),
                    autenticado.clienteId(), autenticado.rol());
            return UsernamePasswordAuthenticationToken.authenticated(principal, null,
                    List.of(new SimpleGrantedAuthority("ROLE_" + autenticado.rol())));
        } catch (ErrorDeNegocioDelCore rechazo) {
            throw switch (rechazo.getEstado()) {
                case 423 -> new LockedException("Usuario bloqueado");
                case 403 -> new DisabledException("El usuario no puede iniciar sesion en este canal");
                default -> new BadCredentialsException("Usuario o clave incorrectos");
            };
        } catch (CoreNoDisponible caido) {
            throw new AuthenticationServiceException("El servicio de autenticacion no esta disponible; intente en unos segundos", caido);
        }
    }

    @Override
    public boolean supports(Class<?> tipo) {
        return UsernamePasswordAuthenticationToken.class.isAssignableFrom(tipo);
    }
}
