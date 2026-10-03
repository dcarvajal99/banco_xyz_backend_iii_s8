package com.bancoxyz.core.autenticacion;

/** Forma del contrato {@code usuario-autenticado.json}. */
public record UsuarioAutenticadoDto(long usuarioId, Long clienteId, String usuario, String nombre, String rol) {
}
