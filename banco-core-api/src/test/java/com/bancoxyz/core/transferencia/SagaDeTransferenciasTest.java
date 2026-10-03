package com.bancoxyz.core.transferencia;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import com.bancoxyz.core.PruebaDelCore;
import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.beans.factory.annotation.Autowired;

/**
 * Los tres pasos del core en la saga (reservar, confirmar, compensar) contra la base: saldos, reservas, movimientos y
 * el evento que queda en el outbox para Kafka. Datos: cuentas de ahorro 101 (8.040) y 105 (12.072) de Diana Prince,
 * 102 de ahorro y 103 de prestamo de Jane Smith.
 */
class SagaDeTransferenciasTest extends PruebaDelCore {

    @Autowired
    private ServicioDeTransferencias saga;

    @Test
    @DisplayName("Reservar: retiene el monto en la cuenta de origen y deja FondosReservados en el outbox, con la cuenta como clave")
    void reservaRetieneElMonto() throws Exception {
        EventoDeTransferencia solicitud = solicitud(101, 105, "1000.00", "Diana Prince");

        saga.reservar(solicitud);

        assertThat(saldo(101)).isEqualTo("7040");
        assertThat(saldo(105)).isEqualTo("12072");
        assertThat(estadoReserva(solicitud)).isEqualTo("RESERVADA");
        JsonNode evento = unicoEventoDelOutbox(Topicos.RESERVAS);
        assertThat(evento.get("tipo").asText()).isEqualTo("FondosReservados");
        assertThat(evento.get("transferenciaId").asText()).isEqualTo(solicitud.transferenciaId());
        assertThat(evento.get("eventoId").asText()).isNotEqualTo(solicitud.eventoId());
        assertThat(evento.get("saldoOrigen").decimalValue()).isEqualByComparingTo("7040");
        assertThat(jdbc.sql("select clave from core.outbox").query(String.class).single()).isEqualTo("101");
    }

    @ParameterizedTest(name = "{4}")
    @CsvSource({
            "101, 105, 99999.00, Diana Prince, SALDO_INSUFICIENTE",
            "101, 105, 1000.00, Jane Smith, CUENTA_AJENA",
            "101, 999, 1000.00, Diana Prince, CUENTA_DESTINO_INEXISTENTE",
            "999, 105, 1000.00, Diana Prince, CUENTA_ORIGEN_INEXISTENTE",
            "101, 101, 1000.00, Diana Prince, MISMA_CUENTA",
            "103, 102, 1000.00, Jane Smith, CUENTA_NO_ADMITE_RETIROS",
            "101, 105, 0, Diana Prince, MONTO_INVALIDO"})
    @DisplayName("Reservar rechaza sin tocar saldos y avisa el motivo con FondosRechazados")
    void rechazos(long origen, long destino, String monto, String cliente, String motivo) throws Exception {
        saga.reservar(solicitud(origen, destino, monto, cliente));

        assertThat(saldo(101)).isEqualTo("8040");
        assertThat(saldo(105)).isEqualTo("12072");
        JsonNode evento = unicoEventoDelOutbox(Topicos.RESERVAS);
        assertThat(evento.get("tipo").asText()).isEqualTo("FondosRechazados");
        assertThat(evento.get("motivo").asText()).isEqualTo(motivo);
    }

    @Test
    @DisplayName("Evento v2 en otra moneda: el core lo rechaza con MONEDA_NO_SOPORTADA sin tocar saldos (sus cuentas son en CLP)")
    void monedaNoSoportada() throws Exception {
        EventoDeTransferencia pesos = solicitud(101, 105, "1000.00", "Diana Prince");
        EventoDeTransferencia dolares = new EventoDeTransferencia(pesos.eventoId(), pesos.tipo(), pesos.transferenciaId(),
                pesos.ocurridoEn(), pesos.clienteId(), pesos.usuarioId(), pesos.cuentaOrigen(), pesos.cuentaDestino(),
                pesos.monto(), pesos.validacion(), null, null, EventoDeTransferencia.VERSION_ACTUAL, "USD");

        saga.reservar(dolares);

        assertThat(saldo(101)).isEqualTo("8040");
        JsonNode evento = unicoEventoDelOutbox(Topicos.RESERVAS);
        assertThat(evento.get("tipo").asText()).isEqualTo("FondosRechazados");
        assertThat(evento.get("motivo").asText()).isEqualTo("MONEDA_NO_SOPORTADA");
        assertThat(evento.get("version").asInt()).isEqualTo(2);
    }

    @Test
    @DisplayName("Kafka entrega la misma solicitud dos veces: el monto se retiene una sola vez")
    void solicitudDuplicada() {
        EventoDeTransferencia solicitud = solicitud(101, 105, "1000.00", "Diana Prince");

        assertThat(saga.reservar(solicitud)).isPresent();
        assertThat(saga.reservar(solicitud)).isEmpty();

        assertThat(saldo(101)).isEqualTo("7040");
        assertThat(jdbc.sql("select count(*) from core.outbox").query(Long.class).single()).isEqualTo(1);
    }

    @Test
    @DisplayName("Aprobada: acredita el destino, registra los dos movimientos y deja TransferenciaCompletada")
    void aprobadaAcredita() throws Exception {
        EventoDeTransferencia solicitud = solicitud(101, 105, "1500.00", "Diana Prince");
        saga.reservar(solicitud);

        saga.confirmar(decision(solicitud, EventoDeTransferencia.APROBADA, null));

        assertThat(saldo(101)).isEqualTo("6540");
        assertThat(saldo(105)).isEqualTo("13572");
        assertThat(estadoReserva(solicitud)).isEqualTo("CONFIRMADA");
        assertThat(jdbc.sql("select tipo from core.operacion order by cuenta_id").query(String.class).list())
                .containsExactly("TRANSF_ENVIADA", "TRANSF_RECIBIDA");
        JsonNode completada = unicoEventoDelOutbox(Topicos.TRANSFERENCIAS);
        assertThat(completada.get("tipo").asText()).isEqualTo("TransferenciaCompletada");
        assertThat(completada.get("saldoOrigen").decimalValue()).isEqualByComparingTo("6540");
    }

    @Test
    @DisplayName("Rechazada por antifraude: compensacion, el monto retenido vuelve a la cuenta de origen")
    void rechazadaCompensa() throws Exception {
        EventoDeTransferencia solicitud = solicitud(101, 105, "1500.00", "Diana Prince");
        saga.reservar(solicitud);
        assertThat(saldo(101)).isEqualTo("6540");

        saga.liberar(decision(solicitud, EventoDeTransferencia.RECHAZADA, "MONTO_SOBRE_LIMITE"));

        assertThat(saldo(101)).isEqualTo("8040");
        assertThat(saldo(105)).isEqualTo("12072");
        assertThat(estadoReserva(solicitud)).isEqualTo("LIBERADA");
        assertThat(jdbc.sql("select count(*) from core.operacion").query(Long.class).single()).isZero();
        JsonNode liberada = unicoEventoDelOutbox(Topicos.TRANSFERENCIAS);
        assertThat(liberada.get("tipo").asText()).isEqualTo("ReservaLiberada");
        assertThat(liberada.get("motivo").asText()).isEqualTo("MONTO_SOBRE_LIMITE");
    }

    @Test
    @DisplayName("Una decision sobre una reserva ya resuelta se ignora: nada se acredita ni se devuelve dos veces")
    void decisionRepetida() {
        EventoDeTransferencia solicitud = solicitud(101, 105, "1000.00", "Diana Prince");
        saga.reservar(solicitud);

        assertThat(saga.confirmar(decision(solicitud, EventoDeTransferencia.APROBADA, null))).isPresent();
        assertThat(saga.confirmar(decision(solicitud, EventoDeTransferencia.APROBADA, null))).isEmpty();
        assertThat(saga.liberar(decision(solicitud, EventoDeTransferencia.RECHAZADA, "MONTO_SOBRE_LIMITE"))).isEmpty();

        assertThat(saldo(101)).isEqualTo("7040");
        assertThat(saldo(105)).isEqualTo("13072");
    }

    private EventoDeTransferencia solicitud(long origen, long destino, String monto, String cliente) {
        return new EventoDeTransferencia(UUID.randomUUID().toString(), EventoDeTransferencia.SOLICITADA,
                UUID.randomUUID().toString(), Instant.now(), clienteId(cliente), 1L, origen, destino, new BigDecimal(monto),
                "PREVIA", null, null);
    }

    private static EventoDeTransferencia decision(EventoDeTransferencia solicitud, String tipo, String motivo) {
        return solicitud.siguiente(tipo, Instant.now(), motivo, null);
    }

    private String estadoReserva(EventoDeTransferencia solicitud) {
        return jdbc.sql("select estado from core.reserva where transferencia_id = :t")
                .param("t", solicitud.transferenciaId()).query(String.class).single();
    }

    private JsonNode unicoEventoDelOutbox(String topico) throws Exception {
        List<String> payloads = jdbc.sql("select payload from core.outbox where topico = :t").param("t", topico)
                .query(String.class).list();
        assertThat(payloads).hasSize(1);
        return json.readTree(payloads.get(0));
    }
}
