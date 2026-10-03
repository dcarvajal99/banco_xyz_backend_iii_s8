package com.bancoxyz.core.cliente;

/** Forma del contrato {@code clientes.json}. */
public record ClienteDto(long clienteId, String nombre, String usuario, long cantidadCuentas) {
}
