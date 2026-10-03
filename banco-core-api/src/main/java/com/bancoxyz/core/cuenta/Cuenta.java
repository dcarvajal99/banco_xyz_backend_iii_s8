package com.bancoxyz.core.cuenta;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;

/**
 * Cuenta abierta en el core a partir del cierre publicado. Su saldo disponible es el que modifican
 * los retiros en linea; el saldo al cierre queda como referencia del batch.
 */
@Entity
@Table(schema = "core", name = "cuenta")
public class Cuenta {

    public static final String TIPO_AHORRO = "ahorro";

    @Id
    private Long id;

    @Column(name = "cliente_id")
    private Long clienteId;

    @Column(nullable = false, length = 120)
    private String titular;

    @Column(nullable = false, length = 20)
    private String tipo;

    @Column(name = "saldo_disponible", nullable = false, precision = 18, scale = 2)
    private BigDecimal saldoDisponible;

    @Column(name = "saldo_cierre", nullable = false, precision = 18, scale = 2)
    private BigDecimal saldoCierre;

    @Column(name = "tasa_mensual", nullable = false, precision = 8, scale = 5)
    private BigDecimal tasaMensual;

    @Column(name = "interes_cierre", nullable = false, precision = 18, scale = 2)
    private BigDecimal interesCierre;

    @Column(nullable = false)
    private boolean anomalia;

    @Column(length = 255)
    private String observacion;

    @Column(name = "cierre_job_execution_id", nullable = false)
    private Long cierreJobExecutionId;

    @Version
    @Column(nullable = false)
    private long version;

    @Column(name = "actualizada_en", nullable = false)
    private LocalDateTime actualizadaEn;

    protected Cuenta() {
    }

    public Cuenta(Long id, Long clienteId, String titular, String tipo, BigDecimal saldo, BigDecimal tasaMensual,
                  BigDecimal interes, boolean anomalia, String observacion, long cierreJobExecutionId,
                  LocalDateTime ahora) {
        this.id = id;
        this.clienteId = clienteId;
        this.titular = titular;
        this.tipo = tipo;
        this.saldoDisponible = saldo;
        this.saldoCierre = saldo;
        this.tasaMensual = tasaMensual;
        this.interesCierre = interes;
        this.anomalia = anomalia;
        this.observacion = observacion;
        this.cierreJobExecutionId = cierreJobExecutionId;
        this.actualizadaEn = ahora;
    }

    /** Retiro en cajero o retencion de una transferencia: siempre con la fila bloqueada y las reglas verificadas. */
    public void descontar(BigDecimal monto, LocalDateTime ahora) {
        if (saldoDisponible.compareTo(monto) < 0) {
            throw new IllegalStateException("Descuento sobre saldo insuficiente en la cuenta " + id);
        }
        saldoDisponible = saldoDisponible.subtract(monto);
        actualizadaEn = ahora;
    }

    /** Abono de una transferencia, o devolucion de un monto retenido cuando la saga se compensa. */
    public void acreditar(BigDecimal monto, LocalDateTime ahora) {
        saldoDisponible = saldoDisponible.add(monto);
        actualizadaEn = ahora;
    }

    public boolean esAhorro() {
        return TIPO_AHORRO.equals(tipo);
    }

    public Long getId() {
        return id;
    }

    public Long getClienteId() {
        return clienteId;
    }

    public String getTitular() {
        return titular;
    }

    public String getTipo() {
        return tipo;
    }

    public BigDecimal getSaldoDisponible() {
        return saldoDisponible;
    }

    public BigDecimal getSaldoCierre() {
        return saldoCierre;
    }

    public BigDecimal getTasaMensual() {
        return tasaMensual;
    }

    public BigDecimal getInteresCierre() {
        return interesCierre;
    }

    public boolean isAnomalia() {
        return anomalia;
    }

    public String getObservacion() {
        return observacion;
    }

    public Long getCierreJobExecutionId() {
        return cierreJobExecutionId;
    }

    public LocalDateTime getActualizadaEn() {
        return actualizadaEn;
    }
}
