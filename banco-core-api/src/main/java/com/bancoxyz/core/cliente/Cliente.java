package com.bancoxyz.core.cliente;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** Titular con nombre del archivo legacy. El legacy no trae RUT: el nombre es la unica identidad. */
@Entity
@Table(schema = "core", name = "cliente")
public class Cliente {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 120)
    private String nombre;

    @Column(name = "creado_en", nullable = false)
    private LocalDateTime creadoEn;

    protected Cliente() {
    }

    public Cliente(String nombre, LocalDateTime creadoEn) {
        this.nombre = nombre;
        this.creadoEn = creadoEn;
    }

    public Long getId() {
        return id;
    }

    public String getNombre() {
        return nombre;
    }
}
