package com.bancoxyz.core.operacion;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** Operacion en linea sobre una cuenta. Hoy solo retiros en cajero. */
@Entity
@Table(schema = "core", name = "operacion")
public class Operacion {

    public static final String TIPO_RETIRO = "RETIRO";
    public static final String CANAL_CAJERO = "CAJERO";
    public static final String TIPO_TRANSFERENCIA_ENVIADA = "TRANSF_ENVIADA";
    public static final String TIPO_TRANSFERENCIA_RECIBIDA = "TRANSF_RECIBIDA";
    public static final String CANAL_TRANSFERENCIAS = "TRANSFERENCIAS";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "cuenta_id", nullable = false)
    private Long cuentaId;

    @Column(name = "tarjeta_id")
    private Long tarjetaId;

    @Column(nullable = false, length = 20)
    private String tipo;

    @Column(nullable = false, length = 20)
    private String canal;

    @Column(nullable = false, precision = 18, scale = 2)
    private BigDecimal monto;

    @Column(name = "saldo_resultante", nullable = false, precision = 18, scale = 2)
    private BigDecimal saldoResultante;

    @Column(name = "terminal_id", length = 40)
    private String terminalId;

    @Column(name = "clave_idempotencia", nullable = false, length = 80)
    private String claveIdempotencia;

    @Column(name = "huella_solicitud", nullable = false, length = 64)
    private String huellaSolicitud;

    @Column(name = "creada_en", nullable = false)
    private LocalDateTime creadaEn;

    protected Operacion() {
    }

    public static Operacion retiroEnCajero(Long cuentaId, Long tarjetaId, String terminalId, BigDecimal monto,
                                           BigDecimal saldoResultante, String claveIdempotencia, String huella,
                                           LocalDateTime creadaEn) {
        Operacion op = new Operacion();
        op.cuentaId = cuentaId;
        op.tarjetaId = tarjetaId;
        op.tipo = TIPO_RETIRO;
        op.canal = CANAL_CAJERO;
        op.monto = monto;
        op.saldoResultante = saldoResultante;
        op.terminalId = terminalId;
        op.claveIdempotencia = claveIdempotencia;
        op.huellaSolicitud = huella;
        op.creadaEn = creadaEn;
        return op;
    }

    /**
     * Movimiento de una transferencia confirmada. La clave idempotente es la transferencia mas el lado (debito o
     * credito): el {@code unique (canal, clave)} impide registrar dos veces el mismo lado.
     */
    public static Operacion deTransferencia(Long cuentaId, String tipo, BigDecimal monto, BigDecimal saldoResultante,
                                            String transferenciaId, String huella, LocalDateTime creadaEn) {
        Operacion op = new Operacion();
        op.cuentaId = cuentaId;
        op.tipo = tipo;
        op.canal = CANAL_TRANSFERENCIAS;
        op.monto = monto;
        op.saldoResultante = saldoResultante;
        op.claveIdempotencia = transferenciaId + (TIPO_TRANSFERENCIA_ENVIADA.equals(tipo) ? ":debito" : ":credito");
        op.huellaSolicitud = huella;
        op.creadaEn = creadaEn;
        return op;
    }

    public Long getId() {
        return id;
    }

    public Long getCuentaId() {
        return cuentaId;
    }

    public Long getTarjetaId() {
        return tarjetaId;
    }

    public String getTipo() {
        return tipo;
    }

    public String getCanal() {
        return canal;
    }

    public BigDecimal getMonto() {
        return monto;
    }

    public BigDecimal getSaldoResultante() {
        return saldoResultante;
    }

    public String getTerminalId() {
        return terminalId;
    }

    public String getHuellaSolicitud() {
        return huellaSolicitud;
    }

    public LocalDateTime getCreadaEn() {
        return creadaEn;
    }
}
