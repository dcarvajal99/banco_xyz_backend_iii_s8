package com.bancoxyz.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.bancoxyz.auth.claves.AlmacenDeClaves;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;

/**
 * El actuator de banco-auth: en contenedores su puerto escucha en la red interna, asi que administrar las claves de firma
 * exige un token del cliente operacion-banco y lo demas es de solo lectura.
 */
@SpringBootTest
@ActiveProfiles("prueba")
@AutoConfigureMockMvc
class OperacionProtegidaTest extends PruebaOAuth {

    static final String SECRETO_OPERACION = "operacion-secreto-dev";

    @Autowired
    private AlmacenDeClaves almacen;

    @Autowired
    private CircuitBreakerRegistry circuitos;

    private String token(String cliente, String secreto, String scope) throws Exception {
        return cuerpo(mvc.perform(post("/oauth2/token").with(httpBasic(cliente, secreto))
                .param("grant_type", "client_credentials").param("scope", scope)).andExpect(status().isOk()))
                .get("access_token").asText();
    }

    @Test
    @DisplayName("Sin token no se listan, rotan ni retiran claves (401); la salud sigue abierta")
    void sinToken() throws Exception {
        mvc.perform(get("/actuator/claves")).andExpect(status().isUnauthorized());
        mvc.perform(post("/actuator/claves")).andExpect(status().isUnauthorized());
        mvc.perform(delete("/actuator/claves/" + almacen.activa().kid())).andExpect(status().isUnauthorized());
        mvc.perform(get("/actuator/health")).andExpect(status().isOk());
    }

    @Test
    @DisplayName("Un token valido de otro cliente (core.cuentas.leer) no alcanza: 403 insufficient_scope")
    void tokenDeOtroCliente() throws Exception {
        String ajeno = token("transferencias-service", SECRETO_TRANSFERENCIAS, "core.cuentas.leer");
        String activa = almacen.activa().kid();

        mvc.perform(post("/actuator/claves").header("Authorization", "Bearer " + ajeno)).andExpect(status().isForbidden());

        assertThat(almacen.activa().kid()).isEqualTo(activa);
    }

    @Test
    @DisplayName("operacion-banco con claves.administrar lista, rota y retira la clave anterior")
    void operacionAdministraLasClaves() throws Exception {
        String operacion = token("operacion-banco", SECRETO_OPERACION, "claves.administrar");
        String anterior = almacen.activa().kid();

        mvc.perform(get("/actuator/claves").header("Authorization", "Bearer " + operacion)).andExpect(status().isOk())
                .andExpect(jsonPath("$[0].kid").exists());
        mvc.perform(post("/actuator/claves").header("Authorization", "Bearer " + operacion)).andExpect(status().isOk());
        assertThat(almacen.activa().kid()).isNotEqualTo(anterior);
        // El token de operacion se firmo con la clave anterior: sigue valido mientras ella este en gracia.
        mvc.perform(delete("/actuator/claves/" + anterior).header("Authorization", "Bearer " + operacion))
                .andExpect(status().isOk()).andExpect(jsonPath("$.retirada").value(true));
    }

    @Test
    @DisplayName("Nadie puede forzar el estado de un circuito por el actuator: solo lectura")
    void circuitosDeSoloLectura() throws Exception {
        String operacion = token("operacion-banco", SECRETO_OPERACION, "claves.administrar");
        String forzar = "{\"updateState\":\"FORCE_OPEN\"}";

        mvc.perform(post("/actuator/circuitbreakers/core").contentType(MediaType.APPLICATION_JSON).content(forzar))
                .andExpect(status().isUnauthorized());
        mvc.perform(post("/actuator/circuitbreakers/core").header("Authorization", "Bearer " + operacion)
                .contentType(MediaType.APPLICATION_JSON).content(forzar)).andExpect(status().isForbidden());
        mvc.perform(get("/actuator/circuitbreakers")).andExpect(status().isOk());

        assertThat(circuitos.circuitBreaker("core").getState()).isEqualTo(CircuitBreaker.State.CLOSED);
    }

    @Test
    @DisplayName("Ningun cliente distinto de operacion-banco puede pedir claves.administrar")
    void scopeExclusivo() throws Exception {
        mvc.perform(post("/oauth2/token").with(httpBasic("transferencias-service", SECRETO_TRANSFERENCIAS))
                        .param("grant_type", "client_credentials").param("scope", "claves.administrar"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.error").value("invalid_scope"));
    }
}
