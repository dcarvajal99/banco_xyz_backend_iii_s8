package com.bancoxyz.antifraude.transferencia;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.math.BigDecimal;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.json.JsonMapper;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/** Version del contrato de eventos: upcasting de v1, lectura de v2, rechazo de versiones desconocidas y lector tolerante. */
class LectorDeEventosTest {

    private static final String V1 = """
            {"eventoId":"e-1","tipo":"FondosReservados","transferenciaId":"t-1","ocurridoEn":"2026-09-24T14:03:29Z",
             "clienteId":1,"usuarioId":1,"cuentaOrigen":101,"cuentaDestino":131,"monto":1500,"saldoOrigen":6540.00}""";

    private final ObjectMapper json = JsonMapper.builder().findAndAddModules().build();
    private final LectorDeEventos lector = new LectorDeEventos(json);

    @Test
    @DisplayName("Un evento v1 (semana 7, sin version ni moneda) se lee como v2 en CLP sin perder datos")
    void subeLaVersion1() {
        EventoDeTransferencia evento = lector.leer(registro(V1));

        assertThat(evento.version()).isEqualTo(2);
        assertThat(evento.moneda()).isEqualTo("CLP");
        assertThat(evento.tipo()).isEqualTo("FondosReservados");
        assertThat(evento.cuentaOrigen()).isEqualTo(101L);
        assertThat(evento.monto()).isEqualByComparingTo("1500");
    }

    @Test
    @DisplayName("Un evento v2 se lee tal cual, con su moneda")
    void leeLaVersion2() {
        EventoDeTransferencia evento = lector.leer(registro(V1.replace("{\"eventoId\"", "{\"version\":2,\"moneda\":\"USD\",\"eventoId\"")));

        assertThat(evento.version()).isEqualTo(2);
        assertThat(evento.moneda()).isEqualTo("USD");
    }

    @Test
    @DisplayName("Un campo que este servicio no conoce se ignora (lector tolerante): agregar campos no rompe consumidores")
    void ignoraCamposNuevos() {
        EventoDeTransferencia evento = lector.leer(registro(V1.replace("\"monto\":1500", "\"monto\":1500,\"canal\":\"app\"")));

        assertThat(evento.eventoId()).isEqualTo("e-1");
    }

    @Test
    @DisplayName("Una version mas nueva que la conocida (o invalida) no se adivina: VersionNoSoportada, que va a la DLT")
    void rechazaVersionesDesconocidas() {
        assertThatThrownBy(() -> lector.leer(registro(V1.replace("{\"eventoId\"", "{\"version\":3,\"eventoId\""))))
                .isInstanceOf(VersionNoSoportada.class).isInstanceOf(EventoInvalido.class)
                .hasMessageContaining("Version 3").hasMessageContaining("hasta la 2");
        assertThatThrownBy(() -> lector.leer(registro(V1.replace("{\"eventoId\"", "{\"version\":0,\"eventoId\""))))
                .isInstanceOf(VersionNoSoportada.class);
    }

    @Test
    @DisplayName("Lo que no es un evento (texto, JSON sin eventoId) es EventoInvalido")
    void rechazaLoIlegible() {
        assertThatThrownBy(() -> lector.leer(registro("esto-no-es-json"))).isInstanceOf(EventoInvalido.class)
                .isNotInstanceOf(VersionNoSoportada.class);
        assertThatThrownBy(() -> lector.leer(registro("[1,2]"))).isInstanceOf(EventoInvalido.class);
        assertThatThrownBy(() -> lector.leer(registro(V1.replace("\"eventoId\":\"e-1\",", ""))))
                .isInstanceOf(EventoInvalido.class).hasMessageContaining("sin eventoId");
    }

    @Test
    @DisplayName("Un evento nuevo se escribe en la version actual: version primero y moneda CLP")
    void escribeLaVersionActual() throws Exception {
        EventoDeTransferencia nuevo = new EventoDeTransferencia("e-2", EventoDeTransferencia.SOLICITADA, "t-2", null, 1L, 1L,
                101L, 131L, new BigDecimal("100"), "PREVIA", null, null);

        String texto = json.writeValueAsString(nuevo);

        assertThat(texto).startsWith("{\"version\":2,\"eventoId\":\"e-2\"").contains("\"moneda\":\"CLP\"");
        assertThat(nuevo.siguiente(EventoDeTransferencia.FONDOS_RESERVADOS, null, null, null).version()).isEqualTo(2);
    }

    private static ConsumerRecord<String, String> registro(String valor) {
        return new ConsumerRecord<>("cuentas.reservas", 0, 7L, "101", valor);
    }
}
