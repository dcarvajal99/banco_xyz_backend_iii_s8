package com.bancoxyz.antifraude.transferencia;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.test.EmbeddedKafkaBroker;
import org.springframework.kafka.test.context.EmbeddedKafka;
import org.springframework.kafka.test.utils.KafkaTestUtils;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;

/**
 * antifraude-service con un Kafka real (embebido): consume {@code FondosReservados} de {@code cuentas.reservas} y
 * publica la decision en {@code antifraude.decisiones}. Un {@code FondosRechazados} se ignora, y un mensaje ilegible
 * termina en {@code cuentas.reservas.DLT}.
 */
@SpringBootTest
@ActiveProfiles("prueba")
@EmbeddedKafka(partitions = 3, topics = {Topicos.RESERVAS, Topicos.DECISIONES, Topicos.RESERVAS + ".DLT"})
@TestPropertySource(properties = {"spring.kafka.bootstrap-servers=${spring.embedded.kafka.brokers}",
        "spring.kafka.listener.auto-startup=true"})
class AntifraudeEnKafkaTest {

    @Autowired
    private KafkaTemplate<String, String> kafka;

    @Autowired
    private EmbeddedKafkaBroker broker;

    @Autowired
    private ObjectMapper json;

    private Consumer<String, String> consumidor;

    @BeforeEach
    void consumidorDePrueba() {
        Map<String, Object> propiedades = KafkaTestUtils.consumerProps("prueba-" + UUID.randomUUID(), "false", broker);
        propiedades.put("auto.offset.reset", "earliest");
        consumidor = new DefaultKafkaConsumerFactory<>(propiedades, new StringDeserializer(), new StringDeserializer())
                .createConsumer();
        broker.consumeFromEmbeddedTopics(consumidor, Topicos.DECISIONES, Topicos.RESERVAS + ".DLT");
    }

    @AfterEach
    void cerrar() {
        consumidor.close();
    }

    /** El primer registro del topico que contiene el texto, buscado con reintentos hasta un timeout. */
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

    /** Ningun registro del topico trae el texto dentro de la ventana: sirve para probar que algo NO se produjo. */
    private boolean nuncaLlega(String topico, String texto, long ventanaMs) {
        long limite = System.currentTimeMillis() + ventanaMs;
        while (System.currentTimeMillis() < limite) {
            for (ConsumerRecord<String, String> registro : consumidor.poll(Duration.ofMillis(300)).records(topico)) {
                if (registro.value().contains(texto)) {
                    return false;
                }
            }
        }
        return true;
    }

    private static EventoDeTransferencia fondosReservados(String monto, long origen, long destino) {
        return new EventoDeTransferencia(UUID.randomUUID().toString(), EventoDeTransferencia.FONDOS_RESERVADOS,
                UUID.randomUUID().toString(), Instant.now(), 1L, 1L, origen, destino, new BigDecimal(monto), null,
                null, null);
    }

    @Test
    @DisplayName("FondosReservados chico -> TransferenciaAprobada, mismo transferenciaId y clave = cuenta de origen")
    void reservaChicaSeAprueba() throws Exception {
        EventoDeTransferencia reserva = fondosReservados("2000.00", 201L, 205L);
        kafka.send(Topicos.RESERVAS, reserva.clave(), json.writeValueAsString(reserva)).get();

        ConsumerRecord<String, String> decision = esperar(Topicos.DECISIONES, reserva.transferenciaId());
        JsonNode nodo = json.readTree(decision.value());
        assertThat(nodo.get("tipo").asText()).isEqualTo(EventoDeTransferencia.APROBADA);
        assertThat(nodo.get("transferenciaId").asText()).isEqualTo(reserva.transferenciaId());
        assertThat(decision.key()).isEqualTo("201");
        assertThat(decision.headers().lastHeader("tipo")).isNotNull();
        assertThat(new String(decision.headers().lastHeader("tipo").value())).isEqualTo(EventoDeTransferencia.APROBADA);
        assertThat(decision.headers().lastHeader("eventoId")).isNotNull();
    }

    @Test
    @DisplayName("FondosReservados sobre el limite -> TransferenciaRechazada MONTO_SOBRE_LIMITE")
    void reservaSobreElLimiteSeRechaza() throws Exception {
        EventoDeTransferencia reserva = fondosReservados("600000.00", 301L, 305L);
        kafka.send(Topicos.RESERVAS, reserva.clave(), json.writeValueAsString(reserva)).get();

        ConsumerRecord<String, String> decision = esperar(Topicos.DECISIONES, reserva.transferenciaId());
        JsonNode nodo = json.readTree(decision.value());
        assertThat(nodo.get("tipo").asText()).isEqualTo(EventoDeTransferencia.RECHAZADA);
        assertThat(nodo.get("motivo").asText()).isEqualTo(ReglasDeRiesgo.MONTO_SOBRE_LIMITE);
    }

    @Test
    @DisplayName("FondosRechazados no dispara ninguna decision: antifraude solo evalua FondosReservados")
    void fondosRechazadosNoProduceDecision() throws Exception {
        EventoDeTransferencia rechazados = fondosReservados("1000.00", 401L, 405L)
                .siguiente(EventoDeTransferencia.FONDOS_RECHAZADOS, Instant.now(), "SALDO_INSUFICIENTE", null);
        kafka.send(Topicos.RESERVAS, rechazados.clave(), json.writeValueAsString(rechazados)).get();

        assertThat(nuncaLlega(Topicos.DECISIONES, rechazados.transferenciaId(), 5_000)).isTrue();
    }

    @Test
    @DisplayName("Un mensaje ilegible no frena la particion: va al topico cuentas.reservas.DLT con el error")
    void mensajeIlegibleAlDlt() throws Exception {
        kafka.send(new ProducerRecord<>(Topicos.RESERVAS, "999", "esto no es un evento")).get();

        ConsumerRecord<String, String> muerto = esperar(Topicos.RESERVAS + ".DLT", "esto no es un evento");
        assertThat(muerto.value()).isEqualTo("esto no es un evento");
        assertThat(new String(muerto.headers().lastHeader("kafka_dlt-exception-message").value()))
                .contains("Mensaje ilegible");
    }
}
