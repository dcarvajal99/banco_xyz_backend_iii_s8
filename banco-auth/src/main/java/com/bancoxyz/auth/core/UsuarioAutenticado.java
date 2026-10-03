package com.bancoxyz.auth.core;

/** Respuesta del core a {@code POST /autenticacion/usuarios} (contrato usuario-autenticado.json). */
public record UsuarioAutenticado(long usuarioId, Long clienteId, String usuario, String nombre, String rol) {
}
