package com.bancoxyz.transferencias;

import java.time.Instant;
import java.util.Set;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClient;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClientManager;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.security.oauth2.core.OAuth2AccessToken;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.client.AutoConfigureMockRestServiceServer;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.JwtRequestPostProcessor;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

/** Base de las pruebas: el core simulado con MockRestServiceServer, tokens de prueba y tablas limpias. */
@SpringBootTest
@ActiveProfiles("prueba")
@Import(PruebaDeTransferencias.TokenDeServicioDePrueba.class)
@AutoConfigureMockMvc
@AutoConfigureMockRestServiceServer
public abstract class PruebaDeTransferencias {

    protected static final String CORE = "https://localhost:8080/api/v1";
    /** Token de servicio que el gestor simulado entrega en lugar de pedirlo a banco-auth. */
    protected static final String TOKEN_DE_SERVICIO = "token-de-servicio-de-prueba";

    @Autowired
    protected MockMvc mvc;

    @Autowired
    protected MockRestServiceServer core;

    @Autowired
    protected JdbcClient jdbc;

    @Autowired
    protected ObjectMapper json;

    @Autowired
    protected CircuitBreakerRegistry circuitos;

    @BeforeEach
    void limpiar() {
        core.reset();
        circuitos.getAllCircuitBreakers().forEach(CircuitBreaker::reset);
        jdbc.sql("delete from transferencias.historial").update();
        jdbc.sql("delete from transferencias.transferencia").update();
        jdbc.sql("delete from transferencias.evento_procesado").update();
        jdbc.sql("delete from transferencias.outbox").update();
    }

    /** JWT de banco-auth ya validado: usuario 7 (diana.prince) del cliente 3, con los scopes de transferencias. */
    protected static JwtRequestPostProcessor diana() {
        return token(7, 3, "diana.prince");
    }

    protected static JwtRequestPostProcessor token(long usuarioId, long clienteId, String usuario) {
        return jwt().jwt(j -> j.subject(usuario).claim("usuario_id", usuarioId).claim("cliente_id", clienteId))
                .authorities(new SimpleGrantedAuthority("SCOPE_transferencias.escribir"),
                        new SimpleGrantedAuthority("SCOPE_transferencias.leer"));
    }

    protected ResultActions transferir(JwtRequestPostProcessor token, String clave, long origen, long destino, String monto)
            throws Exception {
        return mvc.perform(post("/api/v1/transferencias").with(token).header("Idempotency-Key", clave)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"cuentaOrigen\":" + origen + ",\"cuentaDestino\":" + destino + ",\"monto\":" + monto + "}"));
    }

    /**
     * Gestor de tokens que no llama a banco-auth: entrega siempre el mismo token de servicio (client_credentials). Las
     * pruebas verifican que el core lo recibe como {@code Authorization: Bearer}.
     */
    @TestConfiguration
    static class TokenDeServicioDePrueba {

        @Bean
        @Primary
        OAuth2AuthorizedClientManager gestorDeTokensDePrueba(ClientRegistrationRepository registros) {
            return solicitud -> new OAuth2AuthorizedClient(registros.findByRegistrationId(solicitud.getClientRegistrationId()),
                    solicitud.getPrincipal().getName(), new OAuth2AccessToken(OAuth2AccessToken.TokenType.BEARER,
                    TOKEN_DE_SERVICIO, Instant.now(), Instant.now().plusSeconds(300), Set.of("core.cuentas.leer")));
        }
    }

    protected long eventosEnElOutbox() {
        return jdbc.sql("select count(*) from transferencias.outbox").query(Long.class).single();
    }
}
