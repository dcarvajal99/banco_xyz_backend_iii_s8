package com.bancoxyz.transferencias;

import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

import com.bancoxyz.transferencias.evento.EventoDeTransferencia;
import com.bancoxyz.transferencias.evento.Topicos;
import com.fasterxml.jackson.databind.JsonNode;
import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.test.EmbeddedKafkaBroker;
import org.springframework.kafka.test.context.EmbeddedKafka;
import org.springframework.kafka.test.utils.KafkaTestUtils;
import org.springframework.test.context.TestPropertySource;

/** Con un Kafka embebido: la solicitud sale por el outbox al topico y los resultados de la saga cierran la transferencia. */
@EmbeddedKafka(partitions = 3, topics = {Topicos.SOLICITADAS, Topicos.RESERVAS, Topicos.TRANSFERENCIAS,
        Topicos.RESERVAS + ".DLT", Topicos.TRANSFERENCIAS + ".DLT"})
@TestPropertySource(properties = {"spring.kafka.bootstrap-servers=${spring.embedded.kafka.brokers}",
        "spring.kafka.listener.auto-startup=true", "banco.outbox.publicar=true", "banco.outbox.intervalo-ms=100"})
class SagaEnKafkaTest extends PruebaDeTransferencias {

    @Autowired
    private KafkaTemplate<String, String> kafka;

    @Autowired
    private EmbeddedKafkaBroker broker;

    @Test
    @DisplayName("POST → TransferenciaSolicitada en el topico; FondosReservados y TransferenciaCompletada → COMPLETADA")
    void sagaVistaDesdeTransferencias() throws Exception {
        core.expect(requestTo(CORE + "/cuentas/101")).andRespond(withSuccess("{}", MediaType.APPLICATION_JSON));
        String id = json.readTree(transferir(diana(), "kafka-" + UUID.randomUUID(), 101, 105, "3000").andReturn()
                .getResponse().getContentAsString()).get("id").asText();

        Map<String, Object> propiedades = KafkaTestUtils.consumerProps("prueba-" + UUID.randomUUID(), "false", broker);
        propiedades.put("auto.offset.reset", "earliest");
        try (Consumer<String, String> consumidor = new DefaultKafkaConsumerFactory<>(propiedades, new StringDeserializer(),
                new StringDeserializer()).createConsumer()) {
            broker.consumeFromAnEmbeddedTopic(consumidor, Topicos.SOLICITADAS);
            ConsumerRecord<String, String> solicitada = buscar(consumidor, id);
            JsonNode evento = json.readTree(solicitada.value());
            org.assertj.core.api.Assertions.assertThat(evento.get("tipo").asText()).isEqualTo("TransferenciaSolicitada");
            org.assertj.core.api.Assertions.assertThat(solicitada.key()).isEqualTo("101");
        }

        kafka.send(Topicos.RESERVAS, "101", json.writeValueAsString(evento(id, EventoDeTransferencia.FONDOS_RESERVADOS))).get();
        kafka.send(Topicos.TRANSFERENCIAS, "101", json.writeValueAsString(evento(id, EventoDeTransferencia.COMPLETADA))).get();

        long limite = System.currentTimeMillis() + 20_000;
        String estado = "";
        while (!"COMPLETADA".equals(estado) && System.currentTimeMillis() < limite) {
            Thread.sleep(200);
            estado = json.readTree(mvc.perform(get("/api/v1/transferencias/" + id).with(diana())).andReturn().getResponse()
                    .getContentAsString()).get("estado").asText();
        }
        mvc.perform(get("/api/v1/transferencias/" + id).with(diana())).andExpect(jsonPath("$.estado").value("COMPLETADA"));
    }

    private static ConsumerRecord<String, String> buscar(Consumer<String, String> consumidor, String texto) {
        long limite = System.currentTimeMillis() + 20_000;
        while (System.currentTimeMillis() < limite) {
            for (ConsumerRecord<String, String> registro : consumidor.poll(Duration.ofMillis(500))) {
                if (registro.value().contains(texto)) {
                    return registro;
                }
            }
        }
        throw new AssertionError("No llego la solicitud " + texto);
    }

    private static EventoDeTransferencia evento(String id, String tipo) {
        return new EventoDeTransferencia(UUID.randomUUID().toString(), tipo, id, Instant.now(), 3L, 7L, 101L, 105L,
                new BigDecimal("3000"), null, null, null);
    }
}
