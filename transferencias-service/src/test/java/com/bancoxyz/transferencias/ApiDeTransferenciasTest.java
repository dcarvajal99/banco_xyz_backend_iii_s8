package com.bancoxyz.transferencias;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;

/** La API de transferencias con el core simulado: seguridad, 202, idempotencia y rechazos tempranos. */
class ApiDeTransferenciasTest extends PruebaDeTransferencias {

    @Test
    @DisplayName("Sin token: 401. Con un token sin el scope transferencias.escribir (solo lectura o ninguno): 403")
    void exigeToken() throws Exception {
        mvc.perform(post("/api/v1/transferencias").contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/transferencias").with(jwt()).header("Idempotency-Key", "k")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"cuentaOrigen\":101,\"cuentaDestino\":105,\"monto\":1000}"))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/transferencias")
                        .with(jwt().authorities(new org.springframework.security.core.authority.SimpleGrantedAuthority("SCOPE_transferencias.leer")))
                        .header("Idempotency-Key", "k").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cuentaOrigen\":101,\"cuentaDestino\":105,\"monto\":1000}"))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Transferencia valida: el core recibe el token de servicio; 202 con Location, PENDIENTE, PREVIA y el evento en el outbox")
    void aceptada() throws Exception {
        core.expect(requestTo(CORE + "/cuentas/101")).andExpect(header("X-Usuario-Id", "7"))
                .andExpect(header("Authorization", "Bearer " + TOKEN_DE_SERVICIO))
                .andRespond(withSuccess("{\"cuentaId\":101}", MediaType.APPLICATION_JSON));

        String cuerpo = transferir(diana(), "clave-0001", 101, 105, "15000")
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.estado").value("PENDIENTE"))
                .andExpect(jsonPath("$.validacion").value("PREVIA"))
                .andExpect(jsonPath("$.historial[0].evento").value("TransferenciaSolicitada"))
                .andReturn().getResponse().getContentAsString();

        String id = json.readTree(cuerpo).get("id").asText();
        JsonNode evento = json.readTree(jdbc.sql("select payload from transferencias.outbox").query(String.class).single());
        assertThat(evento.get("tipo").asText()).isEqualTo("TransferenciaSolicitada");
        assertThat(evento.get("transferenciaId").asText()).isEqualTo(id);
        assertThat(evento.get("clienteId").asLong()).isEqualTo(3);
        assertThat(evento.get("usuarioId").asLong()).isEqualTo(7);
        assertThat(jdbc.sql("select clave from transferencias.outbox").query(String.class).single()).isEqualTo("101");
        core.verify();
    }

    @Test
    @DisplayName("Idempotency-Key repetida: misma transferencia (200, Idempotency-Replayed); con otro monto, 409")
    void idempotencia() throws Exception {
        core.expect(requestTo(CORE + "/cuentas/101")).andRespond(withSuccess("{}", MediaType.APPLICATION_JSON));
        String primera = transferir(diana(), "clave-0002", 101, 105, "1000").andExpect(status().isAccepted())
                .andReturn().getResponse().getContentAsString();

        String segunda = transferir(diana(), "clave-0002", 101, 105, "1000").andExpect(status().isOk())
                .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.header().string("Idempotency-Replayed", "true"))
                .andReturn().getResponse().getContentAsString();
        transferir(diana(), "clave-0002", 101, 105, "2000").andExpect(status().isConflict())
                .andExpect(jsonPath("$.codigo").value("IDEMPOTENCIA_CONFLICTO"));

        assertThat(json.readTree(segunda).get("id").asText()).isEqualTo(json.readTree(primera).get("id").asText());
        assertThat(eventosEnElOutbox()).isEqualTo(1);
    }

    @Test
    @DisplayName("Cuenta de origen ajena o inexistente (404 del core): 404 sin guardar nada ni emitir eventos")
    void cuentaAjena() throws Exception {
        core.expect(requestTo(CORE + "/cuentas/102")).andRespond(withStatus(HttpStatus.NOT_FOUND)
                .contentType(MediaType.APPLICATION_PROBLEM_JSON).body("{\"codigo\":\"CUENTA_NO_ENCONTRADA\"}"));

        transferir(diana(), "clave-0003", 102, 105, "1000").andExpect(status().isNotFound())
                .andExpect(jsonPath("$.codigo").value("CUENTA_ORIGEN_NO_ENCONTRADA"));
        assertThat(eventosEnElOutbox()).isZero();
    }

    @Test
    @DisplayName("Rechazos que no llegan al core: sin Idempotency-Key, monto invalido, misma cuenta")
    void rechazosTempranos() throws Exception {
        mvc.perform(post("/api/v1/transferencias").with(diana()).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cuentaOrigen\":101,\"cuentaDestino\":105,\"monto\":1000}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.codigo").value("IDEMPOTENCY_KEY_REQUERIDA"));
        transferir(diana(), "clave-0004", 101, 105, "-5").andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.codigo").value("SOLICITUD_INVALIDA"));
        transferir(diana(), "clave-0005", 101, 101, "1000").andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.codigo").value("MISMA_CUENTA"));
        core.verify();
        assertThat(eventosEnElOutbox()).isZero();
    }

    @Test
    @DisplayName("Cada cliente ve solo sus transferencias: la de otro cliente responde 404")
    void consultaPropia() throws Exception {
        core.expect(requestTo(CORE + "/cuentas/101")).andRespond(withSuccess("{}", MediaType.APPLICATION_JSON));
        String id = json.readTree(transferir(diana(), "clave-0006", 101, 105, "1000").andReturn().getResponse()
                .getContentAsString()).get("id").asText();

        mvc.perform(get("/api/v1/transferencias/" + id).with(diana())).andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(id));
        mvc.perform(get("/api/v1/transferencias/" + id).with(token(8, 4, "jane.smith"))).andExpect(status().isNotFound())
                .andExpect(jsonPath("$.codigo").value("TRANSFERENCIA_NO_ENCONTRADA"));
    }
}
