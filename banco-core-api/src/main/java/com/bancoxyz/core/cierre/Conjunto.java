package com.bancoxyz.core.cierre;

/**
 * Conjunto de datos que publica el batch, con la tabla donde queda y el archivo del que salio.
 *
 * <p>Cada conjunto puede venir de una ejecucion distinta: un cierre completo los escribe los tres
 * con el mismo job_execution_id, pero una corrida individual posterior reemplaza solo el suyo.</p>
 */
public enum Conjunto {

    INTERESES("cuenta_interes", "intereses.csv"),
    MOVIMIENTOS("movimiento_anual", "cuentas_anuales.csv"),
    TRANSACCIONES("resumen_diario", "transacciones.csv");

    private final String tabla;
    private final String archivo;

    Conjunto(String tabla, String archivo) {
        this.tabla = tabla;
        this.archivo = archivo;
    }

    public String tabla() {
        return tabla;
    }

    public String archivo() {
        return archivo;
    }
}
