package com.bancoxyz.notificaciones.notificacion;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

import com.bancoxyz.notificaciones.evento.EventoDeTransferencia;
import com.bancoxyz.notificaciones.evento.Topicos;
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
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.test.EmbeddedKafkaBroker;
import org.springframework.kafka.test.context.EmbeddedKafka;
import org.springframework.kafka.test.utils.KafkaTestUtils;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

/**
 * notificaciones-service con un Kafka real (embebido) y su API protegida por JWT: consume
 * {@code TransferenciaCompletada}/{@code ReservaLiberada} de {@code cuentas.transferencias} y
 * {@code FondosRechazados} de {@code cuentas.reservas}, y las expone en {@code GET /api/v1/notificaciones} solo al
 * cliente dueno del token.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("prueba")
@EmbeddedKafka(partitions = 3, topics = {Topicos.RESERVAS, Topicos.TRANSFERENCIAS, Topicos.RESERVAS + ".DLT",
        Topicos.TRANSFERENCIAS + ".DLT"})
@TestPropertySource(properties = {"spring.kafka.bootstrap-servers=${spring.embedded.kafka.brokers}",
        "spring.kafka.listener.auto-startup=true"})
class NotificacionesEnKafkaTest {

    @Autowired
    private MockMvc mvc;

    @Autowired
    private KafkaTemplate<String, String> kafka;

    @Autowired
    private EmbeddedKafkaBroker broker;

    @Autowired
    private ObjectMapper json;

    private Consumer<String, String> consumidorDlt;

    @BeforeEach
    void consumidorDePrueba() {
        Map<String, Object> propiedades = KafkaTestUtils.consumerProps("prueba-" + UUID.randomUUID(), "false", broker);
        propiedades.put("auto.offset.reset", "earliest");
        consumidorDlt = new DefaultKafkaConsumerFactory<>(propiedades, new StringDeserializer(), new StringDeserializer())
                .createConsumer();
        broker.consumeFromEmbeddedTopics(consumidorDlt, Topicos.TRANSFERENCIAS + ".DLT");
    }

    @AfterEach
    void cerrar() {
        consumidorDlt.close();
    }

    private static RequestPostProcessor token(long clienteId) {
        return jwt()
                .jwt(j -> j.claim("cliente_id", clienteId).claim("usuario_id", 1).subject("cliente-" + clienteId))
                .authorities(new SimpleGrantedAuthority("SCOPE_notificaciones.leer"));
    }

    private static EventoDeTransferencia evento(String tipo, String monto, long origen, long destino, long clienteId,
                                                 String motivo) {
        return new EventoDeTransferencia(UUID.randomUUID().toString(), tipo, UUID.randomUUID().toString(),
                Instant.now(), clienteId, 1L, origen, destino, new BigDecimal(monto), null, motivo, null);
    }

    private JsonNode notificacionesDe(long clienteId) throws Exception {
        String cuerpo = mvc.perform(get("/api/v1/notificaciones").with(token(clienteId)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return json.readTree(cuerpo);
    }

    private boolean contiene(JsonNode lista, String transferenciaId) {
        for (JsonNode nodo : lista) {
            if (nodo.get("transferenciaId").asText().equals(transferenciaId)) {
                return true;
            }
        }
        return false;
    }

    private int contar(JsonNode lista, String transferenciaId) {
        int veces = 0;
        for (JsonNode nodo : lista) {
            if (nodo.get("transferenciaId").asText().equals(transferenciaId)) {
                veces++;
            }
        }
        return veces;
    }

    /** Reintenta el GET hasta que la notificacion aparece, con un timeout: el consumo de Kafka es asincrono. */
    private JsonNode esperarNotificacion(long clienteId, String transferenciaId) throws Exception {
        long limite = System.currentTimeMillis() + 20_000;
        while (System.currentTimeMillis() < limite) {
            JsonNode lista = notificacionesDe(clienteId);
            for (JsonNode nodo : lista) {
                if (nodo.get("transferenciaId").asText().equals(transferenciaId)) {
                    return nodo;
                }
            }
            Thread.sleep(300);
        }
        throw new AssertionError("La notificacion de " + transferenciaId + " no llego para el cliente " + clienteId);
    }

    private ConsumerRecord<String, String> esperarEnDlt(String texto) {
        long limite = System.currentTimeMillis() + 20_000;
        while (System.currentTimeMillis() < limite) {
            for (ConsumerRecord<String, String> registro : consumidorDlt.poll(Duration.ofMillis(500))
                    .records(Topicos.TRANSFERENCIAS + ".DLT")) {
                if (registro.value().contains(texto)) {
                    return registro;
                }
            }
        }
        throw new AssertionError("No llego a " + Topicos.TRANSFERENCIAS + ".DLT un registro con " + texto);
    }

    @Test
    @DisplayName("TransferenciaCompletada aparece para el cliente del evento, con el texto en espanol")
    void completadaApareceParaElClienteDueno() throws Exception {
        EventoDeTransferencia completada = evento(EventoDeTransferencia.COMPLETADA, "15000.00", 101L, 105L, 501L, null);
        kafka.send(Topicos.TRANSFERENCIAS, completada.clave(), json.writeValueAsString(completada)).get();

        JsonNode notificacion = esperarNotificacion(501L, completada.transferenciaId());
        assertThat(notificacion.get("tipo").asText()).isEqualTo(EventoDeTransferencia.COMPLETADA);
        assertThat(notificacion.get("texto").asText())
                .isEqualTo("Transferencia de $15.000 desde la cuenta 101 a la cuenta 105 realizada.");
    }

    @Test
    @DisplayName("La notificacion de un cliente no aparece en la lista de otro cliente")
    void noApareceParaOtroCliente() throws Exception {
        EventoDeTransferencia completada = evento(EventoDeTransferencia.COMPLETADA, "3000.00", 111L, 115L, 502L, null);
        kafka.send(Topicos.TRANSFERENCIAS, completada.clave(), json.writeValueAsString(completada)).get();
        esperarNotificacion(502L, completada.transferenciaId());

        assertThat(contiene(notificacionesDe(999L), completada.transferenciaId())).isFalse();
    }

    @Test
    @DisplayName("El mismo evento entregado dos veces por Kafka deja una sola notificacion")
    void eventoDuplicadoUnaSolaNotificacion() throws Exception {
        EventoDeTransferencia completada = evento(EventoDeTransferencia.COMPLETADA, "5000.00", 121L, 125L, 503L, null);
        String cuerpo = json.writeValueAsString(completada);
        kafka.send(Topicos.TRANSFERENCIAS, completada.clave(), cuerpo).get();
        kafka.send(Topicos.TRANSFERENCIAS, completada.clave(), cuerpo).get();

        esperarNotificacion(503L, completada.transferenciaId());
        // Se espera un poco mas para dar tiempo a que, si el duplicado fuera a notificar de nuevo, ya lo haya hecho.
        Thread.sleep(2_000);
        assertThat(contar(notificacionesDe(503L), completada.transferenciaId())).isEqualTo(1);
    }

    @Test
    @DisplayName("FondosReservados no genera ninguna notificacion: antifraude todavia no decidio")
    void fondosReservadosNoNotifica() throws Exception {
        EventoDeTransferencia reservados = evento(EventoDeTransferencia.FONDOS_RESERVADOS, "1000.00", 131L, 135L,
                504L, null);
        kafka.send(Topicos.RESERVAS, reservados.clave(), json.writeValueAsString(reservados)).get();

        long limite = System.currentTimeMillis() + 5_000;
        while (System.currentTimeMillis() < limite) {
            assertThat(contiene(notificacionesDe(504L), reservados.transferenciaId())).isFalse();
            Thread.sleep(300);
        }
    }

    @Test
    @DisplayName("Un mensaje ilegible no frena la particion: va al topico cuentas.transferencias.DLT con el error")
    void mensajeIlegibleAlDlt() throws Exception {
        kafka.send(new ProducerRecord<>(Topicos.TRANSFERENCIAS, "999", "esto no es un evento")).get();

        ConsumerRecord<String, String> muerto = esperarEnDlt("esto no es un evento");
        assertThat(muerto.value()).isEqualTo("esto no es un evento");
        assertThat(new String(muerto.headers().lastHeader("kafka_dlt-exception-message").value()))
                .contains("Mensaje ilegible");
    }

    @Test
    @DisplayName("Sin token no se puede consultar las notificaciones")
    void sinTokenResponde401() throws Exception {
        mvc.perform(get("/api/v1/notificaciones")).andExpect(status().isUnauthorized());
    }
}
