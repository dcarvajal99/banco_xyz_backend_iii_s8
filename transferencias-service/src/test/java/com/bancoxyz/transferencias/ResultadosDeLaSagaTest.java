package com.bancoxyz.transferencias;

import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

import com.bancoxyz.transferencias.evento.EventoDeTransferencia;
import com.bancoxyz.transferencias.transferencia.ServicioDeTransferencias;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

/** Como los resultados de la saga mueven el estado: avanzar, rechazar, ignorar repetidos y no retroceder. */
class ResultadosDeLaSagaTest extends PruebaDeTransferencias {

    @Autowired
    private ServicioDeTransferencias servicio;

    private String id;

    @BeforeEach
    void transferenciaPendiente() throws Exception {
        core.expect(requestTo(CORE + "/cuentas/101")).andRespond(withSuccess("{}", MediaType.APPLICATION_JSON));
        id = json.readTree(transferir(diana(), "saga-" + UUID.randomUUID(), 101, 105, "1000").andReturn().getResponse()
                .getContentAsString()).get("id").asText();
    }

    @Test
    @DisplayName("FondosReservados y TransferenciaCompletada: PENDIENTE → FONDOS_RESERVADOS → COMPLETADA, con historial")
    void caminoFeliz() throws Exception {
        servicio.aplicar(evento(EventoDeTransferencia.FONDOS_RESERVADOS, null));
        estado("FONDOS_RESERVADOS");
        servicio.aplicar(evento(EventoDeTransferencia.COMPLETADA, null));

        mvc.perform(get("/api/v1/transferencias/" + id).with(diana())).andExpect(status().isOk())
                .andExpect(jsonPath("$.estado").value("COMPLETADA"))
                .andExpect(jsonPath("$.historial.length()").value(3))
                .andExpect(jsonPath("$.historial[2].evento").value("TransferenciaCompletada"));
    }

    @Test
    @DisplayName("ReservaLiberada (antifraude rechazo): RECHAZADA con el motivo")
    void compensada() throws Exception {
        servicio.aplicar(evento(EventoDeTransferencia.FONDOS_RESERVADOS, null));
        servicio.aplicar(evento(EventoDeTransferencia.RESERVA_LIBERADA, "MONTO_SOBRE_LIMITE"));
        mvc.perform(get("/api/v1/transferencias/" + id).with(diana()))
                .andExpect(jsonPath("$.estado").value("RECHAZADA")).andExpect(jsonPath("$.motivo").value("MONTO_SOBRE_LIMITE"));
    }

    @Test
    @DisplayName("Un evento repetido se ignora y uno atrasado (reserva despues de completada) no hace retroceder el estado")
    void repetidosYAtrasados() throws Exception {
        EventoDeTransferencia completada = evento(EventoDeTransferencia.COMPLETADA, null);
        servicio.aplicar(completada);
        servicio.aplicar(completada);
        servicio.aplicar(evento(EventoDeTransferencia.FONDOS_RESERVADOS, null));

        mvc.perform(get("/api/v1/transferencias/" + id).with(diana()))
                .andExpect(jsonPath("$.estado").value("COMPLETADA"))
                .andExpect(jsonPath("$.historial.length()").value(3))
                .andExpect(jsonPath("$.historial[2].detalle").value(" (llego tarde: no cambia el estado)"));
    }

    private EventoDeTransferencia evento(String tipo, String motivo) {
        return new EventoDeTransferencia(UUID.randomUUID().toString(), tipo, id, Instant.now(), 3L, 7L, 101L, 105L,
                new BigDecimal("1000"), null, motivo, null);
    }

    private void estado(String esperado) throws Exception {
        mvc.perform(get("/api/v1/transferencias/" + id).with(diana())).andExpect(jsonPath("$.estado").value(esperado));
    }
}
