package com.bancoxyz.auth.oauth;

import java.util.LinkedHashMap;
import java.util.Map;

import com.bancoxyz.auth.config.PropiedadesGitHub;
import com.bancoxyz.auth.core.ClienteCore;
import com.bancoxyz.auth.core.CoreNoDisponible;
import com.bancoxyz.auth.core.ErrorDeNegocioDelCore;
import com.bancoxyz.auth.core.UsuarioAutenticado;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserService;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Component;

/**
 * Regla del banco para el inicio de sesion con GitHub, como el {@code OAuth2UserService} del ejemplo del curso (que solo
 * deja pasar a miembros de una organizacion): GitHub autentica a la persona, pero solo entra si su cuenta esta vinculada
 * a un cliente del banco.
 *
 * <ol>
 *   <li>Lee el usuario de GitHub ({@code /user}, con el access token que entrego GitHub).</li>
 *   <li>Busca su id numerico en los vinculos del Config Server (o en los adicionales de {@code BANCO_GITHUB_VINCULOS}).
 *       Sin vinculo: {@code cuenta_no_vinculada}; el log muestra el id para poder vincularlo.</li>
 *   <li>El core confirma que ese cliente existe, esta activo y sin bloqueo, y entrega sus ids (canal AUTENTICACION,
 *       con Resilience4j). Los tokens que emite banco-auth llevan esos ids, igual que con el formulario.</li>
 * </ol>
 */
@Component
public class VinculacionGitHub implements OAuth2UserService<OAuth2UserRequest, OAuth2User> {

    static final String NO_VINCULADA = "cuenta_no_vinculada";
    static final String BLOQUEADO = "usuario_bloqueado";
    static final String NO_HABILITADO = "usuario_no_habilitado";
    static final String SERVICIO = "servicio_no_disponible";

    private static final Logger log = LoggerFactory.getLogger(VinculacionGitHub.class);

    private final OAuth2UserService<OAuth2UserRequest, OAuth2User> github;
    private final PropiedadesGitHub propiedades;
    private final ClienteCore core;

    @Autowired
    public VinculacionGitHub(PropiedadesGitHub propiedades, ClienteCore core) {
        this(new DefaultOAuth2UserService(), propiedades, core);
    }

    /** Para las pruebas: GitHub simulado en vez de la llamada real a api.github.com. */
    public VinculacionGitHub(OAuth2UserService<OAuth2UserRequest, OAuth2User> github, PropiedadesGitHub propiedades,
                      ClienteCore core) {
        this.github = github;
        this.propiedades = propiedades;
        this.core = core;
    }

    @Override
    public OAuth2User loadUser(OAuth2UserRequest solicitud) throws OAuth2AuthenticationException {
        OAuth2User cuenta = github.loadUser(solicitud);
        long id = ((Number) cuenta.getAttributes().get("id")).longValue();
        String login = String.valueOf(cuenta.getAttributes().get("login"));
        String usuario = propiedades.usuarioVinculado(id).orElse(null);
        if (usuario == null) {
            log.warn("GitHub {} (id {}) no esta vinculado a un cliente del banco", login, id);
            throw rechazo(NO_VINCULADA, "La cuenta de GitHub " + login + " no esta vinculada a un cliente del banco");
        }
        try {
            UsuarioAutenticado cliente = core.identificar(usuario);
            log.info("GitHub {} (id {}) inicio sesion como {}", login, id, cliente.usuario());
            return new UsuarioGitHub(new UsuarioDelBanco(cliente.usuario(), cliente.usuarioId(), cliente.clienteId(),
                    cliente.rol()), id, login, resumen(cuenta.getAttributes()));
        } catch (ErrorDeNegocioDelCore rechazo) {
            throw switch (rechazo.getEstado()) {
                case 423 -> rechazo(BLOQUEADO, "El usuario del banco vinculado esta bloqueado");
                case 403 -> rechazo(NO_HABILITADO, "El usuario del banco vinculado no puede usar la banca en linea");
                default -> rechazo(NO_VINCULADA, "La cuenta vinculada ya no existe en el banco");
            };
        } catch (CoreNoDisponible caido) {
            throw new OAuth2AuthenticationException(new OAuth2Error(SERVICIO,
                    "El servicio de autenticacion no esta disponible; intente en unos segundos", null), caido);
        }
    }

    private static OAuth2AuthenticationException rechazo(String codigo, String mensaje) {
        return new OAuth2AuthenticationException(new OAuth2Error(codigo, mensaje, null));
    }

    /** Solo lo que se muestra o va al token: el resto del perfil de GitHub no se guarda en la sesion. */
    private static Map<String, Object> resumen(Map<String, Object> atributos) {
        Map<String, Object> resumen = new LinkedHashMap<>();
        for (String clave : new String[] {"id", "login", "name", "avatar_url", "html_url"}) {
            if (atributos.get(clave) != null) {
                resumen.put(clave, atributos.get(clave));
            }
        }
        return resumen;
    }
}
