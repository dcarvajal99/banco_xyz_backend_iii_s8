package com.bancoxyz.core.autenticacion;

import java.time.Duration;
import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** Usuario de los canales web y movil. Los cajeros autentican tarjetas, no usuarios. */
@Entity
@Table(schema = "core", name = "usuario")
public class Usuario {

    public static final String ROL_CLIENTE = "CLIENTE";
    public static final String ROL_EJECUTIVO = "EJECUTIVO";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 60)
    private String usuario;

    @Column(name = "password_hash", nullable = false, length = 100)
    private String passwordHash;

    @Column(nullable = false, length = 20)
    private String rol;

    @Column(name = "cliente_id")
    private Long clienteId;

    @Column(nullable = false)
    private boolean activo;

    @Column(name = "intentos_fallidos", nullable = false)
    private int intentosFallidos;

    @Column(name = "bloqueado_hasta")
    private LocalDateTime bloqueadoHasta;

    protected Usuario() {
    }

    private Usuario(String usuario, String passwordHash, String rol, Long clienteId) {
        this.usuario = usuario;
        this.passwordHash = passwordHash;
        this.rol = rol;
        this.clienteId = clienteId;
        this.activo = true;
    }

    public static Usuario cliente(String usuario, String passwordHash, long clienteId) {
        return new Usuario(usuario, passwordHash, ROL_CLIENTE, clienteId);
    }

    public static Usuario ejecutivo(String usuario, String passwordHash) {
        return new Usuario(usuario, passwordHash, ROL_EJECUTIVO, null);
    }

    public boolean bloqueadoEn(LocalDateTime ahora) {
        return bloqueadoHasta != null && bloqueadoHasta.isAfter(ahora);
    }

    /** Un bloqueo vencido se limpia ANTES de evaluar la clave; si no, cada fallo posterior volveria a bloquear. */
    public void liberarBloqueoVencido(LocalDateTime ahora) {
        if (bloqueadoHasta != null && !bloqueadoHasta.isAfter(ahora)) {
            bloqueadoHasta = null;
            intentosFallidos = 0;
        }
    }

    public void registrarFallo(LocalDateTime ahora, int maximo, Duration bloqueo) {
        intentosFallidos++;
        if (intentosFallidos >= maximo) {
            bloqueadoHasta = ahora.plus(bloqueo);
        }
    }

    public void registrarExito() {
        intentosFallidos = 0;
        bloqueadoHasta = null;
    }

    public boolean esEjecutivo() {
        return ROL_EJECUTIVO.equals(rol);
    }

    public Long getId() {
        return id;
    }

    public String getUsuario() {
        return usuario;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public String getRol() {
        return rol;
    }

    public Long getClienteId() {
        return clienteId;
    }

    public boolean isActivo() {
        return activo;
    }

    public int getIntentosFallidos() {
        return intentosFallidos;
    }
}
