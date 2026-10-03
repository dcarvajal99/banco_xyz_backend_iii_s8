package com.bancoxyz.antifraude.transferencia;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.ObjectReader;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.stereotype.Component;

/**
 * Lee el sobre de un evento aceptando todas las versiones del contrato que este servicio conoce.
 *
 * <p>Convencion de evolucion de los eventos del banco:</p>
 * <ul>
 *   <li>{@code version} es la version del contrato del sobre. Sube solo cuando los consumidores deben entender algo
 *       nuevo; un campo opcional agregado no la sube (los consumidores ignoran campos desconocidos).</li>
 *   <li>v1 (semana 7): sin {@code version} ni {@code moneda}; los montos eran siempre pesos chilenos.</li>
 *   <li>v2 (semana 8): {@code version} explicita y {@code moneda} (ISO 4217) junto al monto.</li>
 *   <li>Un evento de una version anterior se lleva a la actual antes de usarlo (upcasting): un v1 queda como v2 en CLP.
 *       Asi un consumidor nuevo procesa sin cambios lo que quedo en los topicos antes del despliegue.</li>
 *   <li>Una version mas nueva que la que este servicio entiende no se adivina: va a la DLT
 *       ({@link VersionNoSoportada}) y se reprocesa cuando el consumidor se actualiza. Por eso se despliegan primero los
 *       consumidores y despues los productores.</li>
 * </ul>
 *
 * <p>Cada servicio guarda su copia de esta clase y del sobre; {@code verificar_coherencia.sh} comprueba que sean iguales.</p>
 */
@Component
public class LectorDeEventos {

    private final ObjectMapper json;
    /** Lector tolerante explicito: un campo nuevo en el sobre no rompe a este consumidor, sea cual sea el ObjectMapper. */
    private final ObjectReader lectorTolerante;

    public LectorDeEventos(ObjectMapper json) {
        this.json = json;
        this.lectorTolerante = json.readerFor(EventoDeTransferencia.class)
                .without(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES);
    }

    public EventoDeTransferencia leer(ConsumerRecord<String, String> registro) {
        String origen = registro.topic() + "-" + registro.partition() + "@" + registro.offset();
        JsonNode nodo;
        try {
            nodo = json.readTree(registro.value());
        } catch (Exception ilegible) {
            throw new EventoInvalido("Mensaje ilegible en " + origen, ilegible);
        }
        if (nodo == null || !nodo.isObject()) {
            throw new EventoInvalido("Mensaje ilegible en " + origen, null);
        }
        ObjectNode sobre = (ObjectNode) nodo;
        int version = sobre.path("version").asInt(1);
        if (version < 1 || version > EventoDeTransferencia.VERSION_ACTUAL) {
            throw new VersionNoSoportada(version, origen);
        }
        if (version == 1) {
            sobre.put("version", EventoDeTransferencia.VERSION_ACTUAL);
        }
        if (!sobre.hasNonNull("moneda")) {
            sobre.put("moneda", EventoDeTransferencia.MONEDA_POR_OMISION);
        }
        EventoDeTransferencia evento;
        try {
            evento = lectorTolerante.readValue(sobre);
        } catch (Exception malFormado) {
            throw new EventoInvalido("Evento con campos invalidos en " + origen, malFormado);
        }
        if (evento.eventoId() == null || evento.tipo() == null || evento.transferenciaId() == null) {
            throw new EventoInvalido("Evento sin eventoId, tipo o transferenciaId en " + origen, null);
        }
        return evento;
    }
}
