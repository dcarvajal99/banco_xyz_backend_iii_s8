package com.bancoxyz.notificaciones.notificacion;

import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedDeque;

import org.springframework.stereotype.Component;

/**
 * Todo el estado del servicio: en memoria, sin base de datos. Se pierde al reiniciar, que es aceptable para un aviso
 * -no para el resultado de la saga, que sigue viviendo en el core y en transferencias-service-.
 *
 * <p>Dos estructuras concurrentes, sin bloqueos explicitos:</p>
 * <ul>
 *   <li>{@code porCliente}: la lista de notificaciones de cada cliente, la mas reciente primero, acotada a
 *       {@value #MAXIMO_POR_CLIENTE}. {@link ConcurrentHashMap#compute} garantiza que agregar y recortar es atomico
 *       por cliente, aunque lleguen eventos de varias particiones a la vez.</li>
 *   <li>{@code eventosProcesados}: el {@code eventoId} de todo lo ya notificado, para descartar la entrega duplicada
 *       de Kafka sin volver a avisar al cliente.</li>
 * </ul>
 */
@Component
public class RepositorioDeNotificaciones {

    static final int MAXIMO_POR_CLIENTE = 50;

    private final ConcurrentHashMap<Long, ConcurrentLinkedDeque<Notificacion>> porCliente = new ConcurrentHashMap<>();
    private final Set<String> eventosProcesados = ConcurrentHashMap.newKeySet();

    /** {@code true} si este evento ya se proceso antes (y por lo tanto hay que ignorarlo esta vez). */
    public boolean yaProcesado(String eventoId) {
        return !eventosProcesados.add(eventoId);
    }

    public void agregar(long clienteId, Notificacion notificacion) {
        porCliente.compute(clienteId, (id, lista) -> {
            ConcurrentLinkedDeque<Notificacion> deque = lista == null ? new ConcurrentLinkedDeque<>() : lista;
            deque.addFirst(notificacion);
            while (deque.size() > MAXIMO_POR_CLIENTE) {
                deque.removeLast();
            }
            return deque;
        });
    }

    /** Las notificaciones del cliente, la mas reciente primero. Vacia si nunca tuvo ninguna. */
    public List<Notificacion> deCliente(long clienteId) {
        ConcurrentLinkedDeque<Notificacion> deque = porCliente.get(clienteId);
        return deque == null ? List.of() : List.copyOf(deque);
    }
}
