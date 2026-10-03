package com.bancoxyz.core;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;

/** Reloj que las pruebas pueden fijar en un instante (23:59 y 00:01 del limite diario, bloqueos vencidos). */
public class RelojAjustable extends Clock {

    private final ZoneId zona;
    private volatile Instant fijo;

    public RelojAjustable(ZoneId zona) {
        this.zona = zona;
    }

    public void fijar(LocalDateTime enLaZona) {
        this.fijo = enLaZona.atZone(zona).toInstant();
    }

    public void volverAlPresente() {
        this.fijo = null;
    }

    @Override
    public ZoneId getZone() {
        return zona;
    }

    @Override
    public Clock withZone(ZoneId otraZona) {
        RelojAjustable copia = new RelojAjustable(otraZona);
        copia.fijo = fijo;
        return copia;
    }

    @Override
    public Instant instant() {
        Instant instante = fijo;
        return instante != null ? instante : Instant.now();
    }
}
