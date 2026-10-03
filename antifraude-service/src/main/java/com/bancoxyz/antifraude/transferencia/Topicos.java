package com.bancoxyz.antifraude.transferencia;

/** Topicos de la saga de transferencias que le importan a antifraude-service. */
public final class Topicos {

    /** Lo produce el core: FondosReservados, FondosRechazados. Antifraude consume solo el primero. */
    public static final String RESERVAS = "cuentas.reservas";
    /** Lo produce antifraude-service: TransferenciaAprobada, TransferenciaRechazada. */
    public static final String DECISIONES = "antifraude.decisiones";

    private Topicos() {
    }
}
