package com.bancoxyz.notificaciones.notificacion;

import java.util.List;

import com.bancoxyz.notificaciones.seguridad.UsuarioDelToken;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** La unica API del servicio: las notificaciones del cliente dueno del token, la mas reciente primero. */
@RestController
@RequestMapping("/api/v1/notificaciones")
public class ControladorDeNotificaciones {

    private final RepositorioDeNotificaciones repositorio;

    public ControladorDeNotificaciones(RepositorioDeNotificaciones repositorio) {
        this.repositorio = repositorio;
    }

    @GetMapping
    public List<Notificacion> listar(@AuthenticationPrincipal Jwt jwt) {
        UsuarioDelToken usuario = UsuarioDelToken.desde(jwt);
        return repositorio.deCliente(usuario.clienteId());
    }
}
