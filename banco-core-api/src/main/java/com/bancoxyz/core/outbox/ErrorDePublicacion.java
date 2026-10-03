package com.bancoxyz.core.outbox;

/** Kafka no confirmo el envio de un evento del outbox (broker caido, tiempo agotado). El evento sigue pendiente. */
public class ErrorDePublicacion extends RuntimeException {

    public ErrorDePublicacion(String eventoId, Throwable causa) {
        super("Kafka no confirmo el evento " + eventoId + ": " + causa.getMessage(), causa);
    }
}
