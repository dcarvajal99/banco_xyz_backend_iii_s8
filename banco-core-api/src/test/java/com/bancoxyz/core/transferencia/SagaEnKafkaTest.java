package com.bancoxyz.core.transferencia;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

import com.bancoxyz.core.PruebaDelCore;
import com.fasterxml.jackson.databind.JsonNode;
import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.test.EmbeddedKafkaBroker;
import org.springframework.kafka.test.context.EmbeddedKafka;
import org.springframework.kafka.test.utils.KafkaTestUtils;
import org.springframework.test.context.TestPropertySource;

/**
 * El core en la saga con un Kafka real (embebido): consume la solicitud del topico, reserva, publica FondosReservados
 * por el outbox; consume la aprobacion de antifraude, acredita y publica TransferenciaCompletada. Un mensaje ilegible
 * termina en el topico DLT.
 */
@EmbeddedKafka(partitions = 3, topics = {Topicos.SOLICITADAS, Topicos.RESERVAS, Topicos.DECISIONES, Topicos.TRANSFERENCIAS,
        Topicos.SOLICITADAS + ".DLT", Topicos.DECISIONES + ".DLT"})
@TestPropertySource(properties = {"spring.kafka.bootstrap-servers=${spring.embedded.kafka.brokers}",
        "spring.kafka.listener.auto-startup=true", "banco.outbox.publicar=true", "banco.outbox.intervalo-ms=100"})
class SagaEnKafkaTest extends PruebaDelCore {

    @Autowired
    private KafkaTemplate<String, String> kafka;

    @Autowired
    private EmbeddedKafkaBroker broker;

    private Consumer<String, String> consumidor;

    @BeforeEach
    void consumidorDePrueba() {
        Map<String, Object> propiedades = KafkaTestUtils.consumerProps("prueba-" + UUID.randomUUID(), "false", broker);
        propiedades.put("auto.offset.reset", "earliest");
        consumidor = new DefaultKafkaConsumerFactory<>(propiedades, new StringDeserializer(), new StringDeserializer())
                .createConsumer();
        broker.consumeFromEmbeddedTopics(consumidor, Topicos.RESERVAS, Topicos.TRANSFERENCIAS, Topicos.DECISIONES + ".DLT");
    }

    @AfterEach
    void cerrar() {
        consumidor.close();
    }

    /**
     * El primer registro del topico que contiene el texto. La base H2 en memoria la comparten todas las clases de prueba,
     * asi que el outbox puede publicar eventos de pruebas anteriores: se busca el propio en vez de exigir uno solo.
     */
    private ConsumerRecord<String, String> esperar(String topico, String texto) {
        long limite = System.currentTimeMillis() + 20_000;
        while (System.currentTimeMillis() < limite) {
            for (ConsumerRecord<String, String> registro : consumidor.poll(Duration.ofMillis(500)).records(topico)) {
                if (registro.value().contains(texto)) {
                    return registro;
                }
            }
        }
        throw new AssertionError("No llego a " + topico + " un registro con " + texto);
    }

    @Test
    @DisplayName("Solicitud → FondosReservados → aprobacion → TransferenciaCompletada, todo por topicos de Kafka")
    void sagaCompleta() throws Exception {
        EventoDeTransferencia solicitud = new EventoDeTransferencia(UUID.randomUUID().toString(),
                EventoDeTransferencia.SOLICITADA, UUID.randomUUID().toString(), Instant.now(), clienteId("Diana Prince"), 1L,
                101L, 105L, new BigDecimal("2000.00"), "PREVIA", null, null);
        kafka.send(Topicos.SOLICITADAS, "101", json.writeValueAsString(solicitud)).get();

        ConsumerRecord<String, String> reservado = esperar(Topicos.RESERVAS, solicitud.transferenciaId());
        JsonNode fondos = json.readTree(reservado.value());
        assertThat(fondos.get("tipo").asText()).isEqualTo("FondosReservados");
        assertThat(reservado.key()).isEqualTo("101");
        assertThat(saldo(101)).isEqualTo("6040");

        EventoDeTransferencia aprobada = solicitud.siguiente(EventoDeTransferencia.APROBADA, Instant.now(), null, null);
        kafka.send(Topicos.DECISIONES, "101", json.writeValueAsString(aprobada)).get();

        ConsumerRecord<String, String> completada = esperar(Topicos.TRANSFERENCIAS, solicitud.transferenciaId());
        assertThat(json.readTree(completada.value()).get("tipo").asText()).isEqualTo("TransferenciaCompletada");
        assertThat(saldo(105)).isEqualTo("14072");
    }

    @Test
    @DisplayName("Un mensaje ilegible no frena la particion: va al topico antifraude.decisiones.DLT con el error")
    void mensajeIlegibleAlDlt() throws Exception {
        kafka.send(new ProducerRecord<>(Topicos.DECISIONES, "101", "esto no es un evento")).get();

        ConsumerRecord<String, String> muerto = esperar(Topicos.DECISIONES + ".DLT", "esto no es un evento");
        assertThat(muerto.value()).isEqualTo("esto no es un evento");
        assertThat(new String(muerto.headers().lastHeader("kafka_dlt-exception-message").value()))
                .contains("Mensaje ilegible");
    }
}
