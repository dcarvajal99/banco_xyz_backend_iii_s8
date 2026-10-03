package com.bancoxyz.notificaciones.evento;

/** Topicos de la saga de transferencias que le importan a notificaciones-service. */
public final class Topicos {

    /** Lo produce el core: FondosReservados, FondosRechazados. Notificaciones solo reacciona al segundo. */
    public static final String RESERVAS = "cuentas.reservas";
    /** Lo produce el core: TransferenciaCompletada, ReservaLiberada (compensacion). */
    public static final String TRANSFERENCIAS = "cuentas.transferencias";

    private Topicos() {
    }
}
