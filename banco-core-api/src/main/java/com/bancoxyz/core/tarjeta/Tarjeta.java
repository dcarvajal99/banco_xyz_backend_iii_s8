package com.bancoxyz.core.tarjeta;

import java.math.BigDecimal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(schema = "core", name = "tarjeta")
public class Tarjeta {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "numero_hash", nullable = false, length = 64)
    private String numeroHash;

    @Column(nullable = false, length = 4)
    private String ultimos4;

    @Column(name = "cuenta_id", nullable = false)
    private Long cuentaId;

    @Column(name = "pin_hash", nullable = false, length = 100)
    private String pinHash;

    @Column(name = "intentos_fallidos", nullable = false)
    private int intentosFallidos;

    @Column(nullable = false)
    private boolean bloqueada;

    @Column(name = "limite_diario", nullable = false, precision = 18, scale = 2)
    private BigDecimal limiteDiario;

    protected Tarjeta() {
    }

    public Tarjeta(String numeroHash, String ultimos4, Long cuentaId, String pinHash, BigDecimal limiteDiario) {
        this.numeroHash = numeroHash;
        this.ultimos4 = ultimos4;
        this.cuentaId = cuentaId;
        this.pinHash = pinHash;
        this.limiteDiario = limiteDiario;
    }

    public void registrarFallo(int maximo) {
        intentosFallidos++;
        if (intentosFallidos >= maximo) {
            bloqueada = true;
        }
    }

    public void registrarExito() {
        intentosFallidos = 0;
    }

    public Long getId() {
        return id;
    }

    public String getUltimos4() {
        return ultimos4;
    }

    public Long getCuentaId() {
        return cuentaId;
    }

    public String getPinHash() {
        return pinHash;
    }

    public int getIntentosFallidos() {
        return intentosFallidos;
    }

    public boolean isBloqueada() {
        return bloqueada;
    }

    public BigDecimal getLimiteDiario() {
        return limiteDiario;
    }
}
