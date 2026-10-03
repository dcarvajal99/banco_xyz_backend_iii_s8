package com.bancoxyz.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.client.ExpectedCount.never;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Instant;
import java.util.List;
import java.util.Map;

import com.bancoxyz.auth.config.PropiedadesGitHub;
import com.bancoxyz.auth.core.ClienteCore;
import com.bancoxyz.auth.oauth.UsuarioDelBanco;
import com.bancoxyz.auth.oauth.UsuarioGitHub;
import com.bancoxyz.auth.oauth.VinculacionGitHub;
import com.nimbusds.jwt.SignedJWT;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.client.AutoConfigureMockRestServiceServer;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.client.authentication.OAuth2AuthenticationToken;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.core.OAuth2AccessToken;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.user.DefaultOAuth2User;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.util.UriComponentsBuilder;

/**
 * "Ingresar con GitHub": banco-auth es cliente OAuth 2.0 de GitHub (identidad federada) y sigue siendo el servidor de
 * autorizacion del banco. GitHub autentica; solo entran cuentas vinculadas a un cliente que el core confirma; los tokens
 * llevan los ids del banco igual que con el formulario. GitHub se simula: las pruebas no salen a internet.
 */
@SpringBootTest
@ActiveProfiles("prueba")
@AutoConfigureMockMvc
@AutoConfigureMockRestServiceServer
class LoginConGitHubTest extends PruebaOAuth {

    static final long DCARVAJAL99 = 113071563L;
    static final String DIANA = "{\"usuarioId\":1,\"clienteId\":1,\"usuario\":\"diana.prince\",\"nombre\":\"Diana Prince\",\"rol\":\"CLIENTE\"}";

    @Autowired
    private MockRestServiceServer core;

    @Autowired
    private ClienteCore clienteCore;

    @Autowired
    private PropiedadesGitHub propiedades;

    @Autowired
    private ClientRegistrationRepository registros;

    @Autowired
    private CircuitBreakerRegistry circuitos;

    @BeforeEach
    void limpiar() {
        core.reset();
        circuitos.getAllCircuitBreakers().forEach(CircuitBreaker::reset);
    }

    /** VinculacionGitHub con un GitHub simulado que responde /user con ese id y login. */
    private UsuarioGitHub iniciarConGitHub(long id, String login) {
        VinculacionGitHub vinculacion = new VinculacionGitHub(solicitud -> new DefaultOAuth2User(List.of(),
                Map.of("id", id, "login", login, "name", "Diego Carvajal"), "id"), propiedades, clienteCore);
        OAuth2UserRequest solicitud = new OAuth2UserRequest(registros.findByRegistrationId("github"),
                new OAuth2AccessToken(OAuth2AccessToken.TokenType.BEARER, "token-de-github", Instant.now(),
                        Instant.now().plusSeconds(60)));
        return (UsuarioGitHub) vinculacion.loadUser(solicitud);
    }

    private static String decodificado(String url, String nombre) {
        return java.net.URLDecoder.decode(parametro(url, nombre), java.nio.charset.StandardCharsets.UTF_8);
    }

    @Test
    @DisplayName("El login ofrece 'Ingresar con GitHub' junto al formulario y explica el rechazo de una cuenta sin vincular")
    void paginaDeLogin() throws Exception {
        mvc.perform(get("/login")).andExpect(status().isOk())
                .andExpect(content().string(org.hamcrest.Matchers.containsString("href=\"oauth2/authorization/github\"")));
        mvc.perform(get("/login").queryParam("error", "github-no-vinculado"))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("no esta vinculada a un cliente del banco")));
    }

    @Test
    @DisplayName("/oauth2/authorization/github redirige a GitHub con client_id, scopes, redirect_uri y state")
    void redirigeAGitHub() throws Exception {
        String destino = mvc.perform(get("/oauth2/authorization/github")).andExpect(status().is3xxRedirection())
                .andReturn().getResponse().getRedirectedUrl();
        var uri = UriComponentsBuilder.fromUriString(destino).build();

        assertThat(destino).startsWith("https://github.com/login/oauth/authorize?");
        assertThat(uri.getQueryParams().getFirst("response_type")).isEqualTo("code");
        assertThat(uri.getQueryParams().getFirst("client_id")).isEqualTo("cliente-github-prueba");
        assertThat(decodificado(destino, "scope")).isEqualTo("read:user user:email");
        assertThat(decodificado(destino, "redirect_uri")).isEqualTo("http://localhost/login/oauth2/code/github");
        assertThat(uri.getQueryParams().getFirst("state")).isNotBlank();
    }

    @Test
    @DisplayName("Cuenta de GitHub vinculada: el core confirma al cliente y la sesion queda con sus ids del banco")
    void cuentaVinculada() {
        core.expect(requestTo(CORE + "/diana.prince")).andExpect(method(HttpMethod.GET))
                .andRespond(withSuccess(DIANA, MediaType.APPLICATION_JSON));

        UsuarioGitHub usuario = iniciarConGitHub(DCARVAJAL99, "dcarvajal99");

        core.verify();
        assertThat(usuario.getName()).isEqualTo("diana.prince");
        assertThat(usuario.banco()).isEqualTo(new UsuarioDelBanco("diana.prince", 1L, 1L, "CLIENTE"));
        assertThat(usuario.githubLogin()).isEqualTo("dcarvajal99");
        assertThat(usuario.getAuthorities()).extracting(Object::toString).containsExactly("ROLE_CLIENTE");
    }

    @Test
    @DisplayName("Cuenta de GitHub sin vincular: rechazo cuenta_no_vinculada, sin consultar al core")
    void cuentaNoVinculada() {
        core.expect(never(), requestTo(org.hamcrest.Matchers.startsWith(CORE)));

        assertThatThrownBy(() -> iniciarConGitHub(583231L, "octocat"))
                .isInstanceOf(OAuth2AuthenticationException.class)
                .extracting(e -> ((OAuth2AuthenticationException) e).getError().getErrorCode())
                .isEqualTo("cuenta_no_vinculada");
        core.verify();
    }

    @Test
    @DisplayName("Vinculada a un usuario que el core tiene bloqueado (423): rechazo usuario_bloqueado")
    void usuarioBloqueado() {
        core.expect(requestTo(CORE + "/diana.prince")).andRespond(withStatus(HttpStatus.LOCKED)
                .contentType(MediaType.APPLICATION_PROBLEM_JSON).body("{\"codigo\":\"USUARIO_BLOQUEADO\"}"));

        assertThatThrownBy(() -> iniciarConGitHub(DCARVAJAL99, "dcarvajal99"))
                .isInstanceOf(OAuth2AuthenticationException.class)
                .extracting(e -> ((OAuth2AuthenticationException) e).getError().getErrorCode())
                .isEqualTo("usuario_bloqueado");
    }

    @Test
    @DisplayName("Una respuesta de GitHub con un state que no corresponde a ninguna solicitud vuelve al login con error")
    void stateDesconocido() throws Exception {
        mvc.perform(get("/login/oauth2/code/github").queryParam("code", "codigo-de-github").queryParam("state", "inventado"))
                .andExpect(redirectedUrl("/login?error=github"));
    }

    @Test
    @DisplayName("Con la sesion de GitHub, banco-auth emite su access token con los ids del banco y origen=github")
    void tokenConDatosDelBanco() throws Exception {
        UsuarioGitHub usuario = new UsuarioGitHub(new UsuarioDelBanco("diana.prince", 1L, 1L, "CLIENTE"), DCARVAJAL99,
                "dcarvajal99", Map.of("id", DCARVAJAL99, "login", "dcarvajal99"));
        OAuth2AuthenticationToken sesion = new OAuth2AuthenticationToken(usuario, usuario.getAuthorities(), "github");
        String verificador = verificador();
        String redireccion = mvc.perform(get("/oauth2/authorize")
                        .queryParam("response_type", "code").queryParam("client_id", "banca-web")
                        .queryParam("redirect_uri", REDIRECCION).queryParam("scope", "openid transferencias.escribir")
                        .queryParam("state", "estado-1").queryParam("code_challenge", desafio(verificador))
                        .queryParam("code_challenge_method", "S256").with(authentication(sesion)))
                .andExpect(status().is3xxRedirection()).andReturn().getResponse().getRedirectedUrl();

        var tokens = cuerpo(canjear(parametro(redireccion, "code"), verificador).andExpect(status().isOk()));
        Map<String, Object> claims = SignedJWT.parse(tokens.get("access_token").asText()).getJWTClaimsSet().getClaims();

        assertThat(claims).containsEntry("sub", "diana.prince").containsEntry("usuario_id", 1L)
                .containsEntry("cliente_id", 1L).containsEntry("origen", "github").containsEntry("github_login", "dcarvajal99");
    }
}
