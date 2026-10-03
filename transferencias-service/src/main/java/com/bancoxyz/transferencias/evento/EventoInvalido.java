package com.bancoxyz.transferencias.evento;

/** Mensaje que no es un evento de transferencia legible. No se reintenta: va directo al topico DLT. */
public class EventoInvalido extends RuntimeException {

    public EventoInvalido(String detalle, Throwable causa) {
        super(detalle, causa);
    }
}
