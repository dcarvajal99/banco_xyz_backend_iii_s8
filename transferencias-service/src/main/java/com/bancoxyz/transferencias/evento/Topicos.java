package com.bancoxyz.transferencias.evento;

/** Topicos de la saga de transferencias. Cada servicio es dueno de los topicos que produce. */
public final class Topicos {

    /** Lo produce transferencias-service: TransferenciaSolicitada. */
    public static final String SOLICITADAS = "transferencias.solicitadas";
    /** Lo produce el core: FondosReservados, FondosRechazados. */
    public static final String RESERVAS = "cuentas.reservas";
    /** Lo produce antifraude-service: TransferenciaAprobada, TransferenciaRechazada. */
    public static final String DECISIONES = "antifraude.decisiones";
    /** Lo produce el core: TransferenciaCompletada, ReservaLiberada. */
    public static final String TRANSFERENCIAS = "cuentas.transferencias";

    private Topicos() {
    }
}
