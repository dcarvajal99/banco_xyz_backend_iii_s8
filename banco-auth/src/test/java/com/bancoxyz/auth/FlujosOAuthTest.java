package com.bancoxyz.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.Map;

import com.bancoxyz.auth.claves.AlmacenDeClaves;
import com.fasterxml.jackson.databind.JsonNode;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.crypto.RSASSAVerifier;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jwt.SignedJWT;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

/** Los flujos OAuth 2.0 de banco-auth de punta a punta (sin core: el usuario llega ya autenticado). */
@SpringBootTest
@ActiveProfiles("prueba")
@AutoConfigureMockMvc
class FlujosOAuthTest extends PruebaOAuth {

    @Autowired
    private AlmacenDeClaves almacen;

    @Test
    @DisplayName("OpenID discovery publica emisor, endpoints, PKCE S256 y los grant types soportados")
    void descubrimiento() throws Exception {
        mvc.perform(get("/.well-known/openid-configuration")).andExpect(status().isOk())
                .andExpect(jsonPath("$.issuer").value("https://localhost:8081"))
                .andExpect(jsonPath("$.token_endpoint").value("https://localhost:8081/oauth2/token"))
                .andExpect(jsonPath("$.jwks_uri").value("https://localhost:8081/oauth2/jwks"))
                .andExpect(jsonPath("$.code_challenge_methods_supported[0]").value("S256"));
    }

    @Test
    @DisplayName("authorization_code + PKCE: codigo, canje con code_verifier, access token RS256 con claims del usuario")
    void codigoDeAutorizacionConPkce() throws Exception {
        String verificador = verificador();
        String redireccion = autorizar("openid transferencias.escribir transferencias.leer", desafio(verificador))
                .andExpect(status().is3xxRedirection()).andReturn().getResponse().getRedirectedUrl();
        assertThat(redireccion).startsWith(REDIRECCION);
        assertThat(parametro(redireccion, "state")).isEqualTo("estado-1");

        JsonNode tokens = cuerpo(canjear(parametro(redireccion, "code"), verificador).andExpect(status().isOk()));

        assertThat(tokens.get("token_type").asText()).isEqualTo("Bearer");
        assertThat(tokens.has("refresh_token")).isTrue();
        assertThat(tokens.has("id_token")).isTrue();
        SignedJWT acceso = SignedJWT.parse(tokens.get("access_token").asText());
        assertThat(acceso.getHeader().getAlgorithm()).isEqualTo(JWSAlgorithm.RS256);
        assertThat(acceso.getHeader().getKeyID()).isEqualTo(almacen.activa().kid());
        JWKSet publico = JWKSet.parse(mvc.perform(get("/oauth2/jwks")).andReturn().getResponse().getContentAsString());
        assertThat(acceso.verify(new RSASSAVerifier((RSAKey) publico.getKeyByKeyId(acceso.getHeader().getKeyID())))).isTrue();
        Map<String, Object> claims = acceso.getJWTClaimsSet().getClaims();
        assertThat(claims).containsEntry("sub", "diana.prince").containsEntry("usuario_id", 1L)
                .containsEntry("cliente_id", 1L).containsEntry("rol", "CLIENTE").containsEntry("iss", "https://localhost:8081");
        assertThat(acceso.getJWTClaimsSet().getAudience()).containsExactly("banco-xyz");
        assertThat(acceso.getJWTClaimsSet().getStringListClaim("scope"))
                .containsExactlyInAnyOrder("openid", "transferencias.escribir", "transferencias.leer");
    }

    @Test
    @DisplayName("PKCE obligatorio: sin code_challenge no hay codigo, y un codigo sin code_verifier no se canjea")
    void pkceObligatorio() throws Exception {
        String sinDesafio = autorizar("transferencias.leer", null).andExpect(status().is3xxRedirection())
                .andReturn().getResponse().getRedirectedUrl();
        assertThat(parametro(sinDesafio, "error")).isEqualTo("invalid_request");

        String redireccion = autorizar("transferencias.leer", desafio(verificador())).andReturn().getResponse().getRedirectedUrl();
        canjear(parametro(redireccion, "code"), null).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("invalid_grant"));
        canjear(parametro(redireccion, "code"), verificador()).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("invalid_grant"));
    }

    @Test
    @DisplayName("banca-web no puede pedir el scope del core: un usuario nunca recibe core.cuentas.leer")
    void scopeAjenoAlCliente() throws Exception {
        String redireccion = autorizar("core.cuentas.leer", desafio(verificador())).andReturn().getResponse().getRedirectedUrl();
        assertThat(parametro(redireccion, "error")).isEqualTo("invalid_scope");
    }

    @Test
    @DisplayName("Refresh token rotativo: entrega tokens nuevos y el refresh token usado deja de valer")
    void refrescoRotativo() throws Exception {
        String verificador = verificador();
        String redireccion = autorizar("transferencias.leer", desafio(verificador)).andReturn().getResponse().getRedirectedUrl();
        JsonNode primeros = cuerpo(canjear(parametro(redireccion, "code"), verificador));
        String refresco = primeros.get("refresh_token").asText();

        JsonNode segundos = cuerpo(mvc.perform(post("/oauth2/token").with(httpBasic("banca-web", SECRETO_WEB))
                .param("grant_type", "refresh_token").param("refresh_token", refresco)).andExpect(status().isOk()));
        assertThat(segundos.get("refresh_token").asText()).isNotEqualTo(refresco);
        assertThat(SignedJWT.parse(segundos.get("access_token").asText()).getJWTClaimsSet().getClaim("usuario_id")).isEqualTo(1L);

        mvc.perform(post("/oauth2/token").with(httpBasic("banca-web", SECRETO_WEB))
                        .param("grant_type", "refresh_token").param("refresh_token", refresco))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.error").value("invalid_grant"));
    }

    @Test
    @DisplayName("client_credentials: token de servicio con scope core.cuentas.leer, sin datos de usuario")
    void credencialesDeCliente() throws Exception {
        JsonNode token = cuerpo(mvc.perform(post("/oauth2/token").with(httpBasic("transferencias-service", SECRETO_TRANSFERENCIAS))
                .param("grant_type", "client_credentials").param("scope", "core.cuentas.leer")).andExpect(status().isOk()));

        SignedJWT jwt = SignedJWT.parse(token.get("access_token").asText());
        assertThat(jwt.getJWTClaimsSet().getSubject()).isEqualTo("transferencias-service");
        assertThat(jwt.getJWTClaimsSet().getStringListClaim("scope")).containsExactly("core.cuentas.leer");
        assertThat(jwt.getJWTClaimsSet().getClaims()).doesNotContainKeys("usuario_id", "cliente_id");
        assertThat(token.has("refresh_token")).isFalse();
    }

    @Test
    @DisplayName("client_credentials con secreto incorrecto (401) o con un scope no permitido (400)")
    void credencialesInvalidas() throws Exception {
        mvc.perform(post("/oauth2/token").with(httpBasic("transferencias-service", "otro-secreto"))
                        .param("grant_type", "client_credentials").param("scope", "core.cuentas.leer"))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.error").value("invalid_client"));
        mvc.perform(post("/oauth2/token").with(httpBasic("transferencias-service", SECRETO_TRANSFERENCIAS))
                        .param("grant_type", "client_credentials").param("scope", "transferencias.escribir"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.error").value("invalid_scope"));
    }

    @Test
    @DisplayName("Al rotar la clave, los tokens nuevos llevan el kid nuevo y /oauth2/jwks publica las dos claves publicas")
    void rotacion() throws Exception {
        String anterior = almacen.activa().kid();
        String nueva = almacen.rotar().kid();

        JsonNode token = cuerpo(mvc.perform(post("/oauth2/token").with(httpBasic("transferencias-service", SECRETO_TRANSFERENCIAS))
                .param("grant_type", "client_credentials").param("scope", "core.cuentas.leer")));
        assertThat(SignedJWT.parse(token.get("access_token").asText()).getHeader().getKeyID()).isEqualTo(nueva);
        mvc.perform(get("/oauth2/jwks")).andExpect(status().isOk())
                .andExpect(jsonPath("$.keys.length()").value(2))
                .andExpect(jsonPath("$.keys[?(@.kid=='" + anterior + "')]").exists())
                .andExpect(jsonPath("$.keys[0].d").doesNotExist())
                .andExpect(jsonPath("$.keys[0].p").doesNotExist());
    }
}
