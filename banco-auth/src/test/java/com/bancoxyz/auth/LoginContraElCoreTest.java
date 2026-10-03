package com.bancoxyz.auth;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestBuilders.formLogin;
import static org.springframework.security.test.web.servlet.response.SecurityMockMvcResultMatchers.authenticated;
import static org.springframework.security.test.web.servlet.response.SecurityMockMvcResultMatchers.unauthenticated;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.content;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrlPattern;

import com.bancoxyz.auth.oauth.UsuarioDelBanco;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.client.AutoConfigureMockRestServiceServer;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.client.MockRestServiceServer;

/** El formulario de login de banco-auth: la clave la verifica el core y su respuesta decide el inicio de sesion. */
@SpringBootTest
@ActiveProfiles("prueba")
@AutoConfigureMockMvc
@AutoConfigureMockRestServiceServer
class LoginContraElCoreTest extends PruebaOAuth {

    @Autowired
    private MockRestServiceServer core;

    @Autowired
    private CircuitBreakerRegistry circuitos;

    @BeforeEach
    void limpiar() {
        core.reset();
        circuitos.getAllCircuitBreakers().forEach(CircuitBreaker::reset);
    }

    @Test
    @DisplayName("Sin sesion, /oauth2/authorize lleva al formulario de login")
    void autorizarSinSesionPideLogin() throws Exception {
        mvc.perform(get("/oauth2/authorize").accept(MediaType.TEXT_HTML)
                        .queryParam("response_type", "code").queryParam("client_id", "banca-web")
                        .queryParam("redirect_uri", REDIRECCION).queryParam("scope", "transferencias.leer")
                        .queryParam("code_challenge", desafio(verificador())).queryParam("code_challenge_method", "S256"))
                .andExpect(redirectedUrlPattern("**/login"));
    }

    @Test
    @DisplayName("Clave correcta: el core la valida y la sesion queda con el usuario y sus ids del core")
    void claveCorrecta() throws Exception {
        core.expect(requestTo(CORE)).andExpect(method(HttpMethod.POST))
                .andExpect(content().json("{\"usuario\":\"diana.prince\",\"password\":\"Cliente2026!\"}"))
                .andRespond(withSuccess("{\"usuarioId\":1,\"clienteId\":1,\"usuario\":\"diana.prince\",\"nombre\":\"Diana\",\"rol\":\"CLIENTE\"}",
                        MediaType.APPLICATION_JSON));

        mvc.perform(formLogin().user("diana.prince").password("Cliente2026!"))
                .andExpect(authenticated().withAuthenticationPrincipal(new UsuarioDelBanco("diana.prince", 1L, 1L, "CLIENTE")))
                .andExpect(redirectedUrl("/"));
        core.verify();
    }

    @ParameterizedTest(name = "core {0} -> {2}")
    @CsvSource({"401, CREDENCIALES_INVALIDAS, credenciales", "403, ROL_NO_PERMITIDO_EN_CANAL, no-habilitado",
            "423, USUARIO_BLOQUEADO, bloqueado"})
    @DisplayName("Si el core rechaza la clave, no hay sesion y el login muestra el motivo")
    void rechazoDelCore(int estado, String codigo, String motivo) throws Exception {
        core.expect(requestTo(CORE)).andRespond(withStatus(HttpStatus.valueOf(estado))
                .contentType(MediaType.APPLICATION_PROBLEM_JSON).body("{\"codigo\":\"" + codigo + "\"}"));

        mvc.perform(formLogin().user("diana.prince").password("mala"))
                .andExpect(unauthenticated()).andExpect(redirectedUrl("/login?error=" + motivo));
    }
}
