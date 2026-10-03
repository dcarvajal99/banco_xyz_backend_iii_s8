package com.bancoxyz.core.outbox;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;

import com.bancoxyz.core.transferencia.EventoDeTransferencia;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Transactional outbox del core.
 *
 * <p>{@link #registrar} se llama dentro de la transaccion que cambia los saldos: el evento queda guardado junto con el
 * cambio, o no queda ninguno de los dos. {@link PublicadorDeOutbox} lo envia a Kafka despues. Entrega al menos una vez:
 * si el publicador cae entre enviar y marcar, el evento se reenvia con el mismo {@code eventoId} y el consumidor lo
 * descarta como duplicado.</p>
 */
@Component
public class Outbox {

    /** Evento guardado a la espera de ser publicado. */
    public record Pendiente(long id, String eventoId, String topico, String clave, String tipo, String payload) {
    }

    private final JdbcClient jdbc;
    private final ObjectMapper json;
    private final Clock reloj;

    public Outbox(JdbcClient jdbc, ObjectMapper json, Clock reloj) {
        this.jdbc = jdbc;
        this.json = json;
        this.reloj = reloj;
    }

    public void registrar(String topico, EventoDeTransferencia evento) {
        jdbc.sql("""
                        insert into core.outbox (evento_id, topico, clave, tipo, payload, creado_en)
                        values (:evento, :topico, :clave, :tipo, :payload, :ahora)""")
                .param("evento", evento.eventoId())
                .param("topico", topico)
                .param("clave", evento.clave())
                .param("tipo", evento.tipo())
                .param("payload", aJson(evento))
                .param("ahora", LocalDateTime.now(reloj))
                .update();
    }

    /**
     * Los mas antiguos sin publicar, bloqueados para esta transaccion. {@code skip locked}: si corre otra instancia del
     * core, cada una toma filas distintas en vez de esperar o publicar dos veces.
     */
    public List<Pendiente> pendientes(int limite) {
        return jdbc.sql("""
                        select id, evento_id, topico, clave, tipo, payload from core.outbox
                        where publicado_en is null order by id limit :limite for update skip locked""")
                .param("limite", limite)
                .query((fila, n) -> new Pendiente(fila.getLong("id"), fila.getString("evento_id"),
                        fila.getString("topico"), fila.getString("clave"), fila.getString("tipo"), fila.getString("payload")))
                .list();
    }

    public void marcarPublicado(long id) {
        jdbc.sql("update core.outbox set publicado_en = :ahora where id = :id")
                .param("ahora", LocalDateTime.now(reloj)).param("id", id).update();
    }

    public long contarPendientes() {
        return jdbc.sql("select count(*) from core.outbox where publicado_en is null").query(Long.class).single();
    }

    private String aJson(EventoDeTransferencia evento) {
        try {
            return json.writeValueAsString(evento);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("No se pudo serializar el evento " + evento.eventoId(), e);
        }
    }
}
