package com.bancoxyz.auth;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.List;

import com.bancoxyz.auth.oauth.UsuarioDelBanco;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.web.util.UriComponentsBuilder;

/** Ayudas comunes de las pruebas del servidor de autorizacion: clientes, PKCE y un usuario ya autenticado. */
abstract class PruebaOAuth {

    static final String CORE = "https://localhost:8080/api/v1/autenticacion/usuarios";
    static final String REDIRECCION = "http://127.0.0.1:8099/callback";
    static final String SECRETO_WEB = "banca-web-secreto-dev";
    static final String SECRETO_TRANSFERENCIAS = "transferencias-oauth-dev";

    @Autowired
    protected MockMvc mvc;

    @Autowired
    protected ObjectMapper json;

    static UsernamePasswordAuthenticationToken diana() {
        return UsernamePasswordAuthenticationToken.authenticated(new UsuarioDelBanco("diana.prince", 1L, 1L, "CLIENTE"),
                null, List.of(new SimpleGrantedAuthority("ROLE_CLIENTE")));
    }

    static String verificador() {
        byte[] azar = new byte[32];
        new java.security.SecureRandom().nextBytes(azar);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(azar);
    }

    static String desafio(String verificador) throws Exception {
        byte[] hash = MessageDigest.getInstance("SHA-256").digest(verificador.getBytes(StandardCharsets.US_ASCII));
        return Base64.getUrlEncoder().withoutPadding().encodeToString(hash);
    }

    /** Pide un codigo de autorizacion como lo haria el navegador ya autenticado; devuelve la URL de redireccion. */
    ResultActions autorizar(String scopes, String desafio) throws Exception {
        // El servidor lee la solicitud de autorizacion desde la query string, como la arma el navegador.
        var solicitud = get("/oauth2/authorize")
                .queryParam("response_type", "code").queryParam("client_id", "banca-web").queryParam("redirect_uri", REDIRECCION)
                .queryParam("scope", scopes).queryParam("state", "estado-1")
                .with(authentication(diana()));
        if (desafio != null) {
            solicitud.queryParam("code_challenge", desafio).queryParam("code_challenge_method", "S256");
        }
        return mvc.perform(solicitud);
    }

    static String parametro(String url, String nombre) {
        return UriComponentsBuilder.fromUriString(url).build().getQueryParams().getFirst(nombre);
    }

    ResultActions canjear(String codigo, String verificador) throws Exception {
        var solicitud = post("/oauth2/token").with(httpBasic("banca-web", SECRETO_WEB))
                .param("grant_type", "authorization_code").param("code", codigo).param("redirect_uri", REDIRECCION);
        if (verificador != null) {
            solicitud.param("code_verifier", verificador);
        }
        return mvc.perform(solicitud);
    }

    JsonNode cuerpo(ResultActions resultado) throws Exception {
        return json.readTree(resultado.andReturn().getResponse().getContentAsString());
    }
}
