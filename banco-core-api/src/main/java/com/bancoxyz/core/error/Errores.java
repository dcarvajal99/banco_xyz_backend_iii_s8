package com.bancoxyz.core.error;

import org.springframework.http.HttpStatus;

/** Catalogo de errores del core (seccion 12.1 de la especificacion). Un metodo por codigo. */
public final class Errores {

    private Errores() {
    }

    public static ErrorDeNegocio solicitudInvalida(String detalle) {
        return new ErrorDeNegocio(HttpStatus.BAD_REQUEST, "SOLICITUD_INVALIDA", "Solicitud invalida", detalle);
    }

    public static ErrorDeNegocio identidadRequerida(String encabezado) {
        return new ErrorDeNegocio(HttpStatus.BAD_REQUEST, "IDENTIDAD_REQUERIDA", "Identidad requerida",
                "Falta o es invalido el encabezado " + encabezado);
    }

    public static ErrorDeNegocio montoInvalido() {
        return new ErrorDeNegocio(HttpStatus.BAD_REQUEST, "MONTO_INVALIDO", "Monto invalido",
                "El monto debe ser mayor que cero y sin decimales");
    }

    public static ErrorDeNegocio credencialesInvalidas() {
        return new ErrorDeNegocio(HttpStatus.UNAUTHORIZED, "CREDENCIALES_INVALIDAS", "Credenciales invalidas",
                "Usuario o clave incorrectos");
    }

    public static ErrorDeNegocio tarjetaInvalida() {
        return new ErrorDeNegocio(HttpStatus.UNAUTHORIZED, "TARJETA_INVALIDA", "Tarjeta invalida",
                "La tarjeta no es valida");
    }

    public static ErrorDeNegocio pinIncorrecto(int intentosRestantes) {
        return new ErrorDeNegocio(HttpStatus.UNAUTHORIZED, "PIN_INCORRECTO", "PIN incorrecto",
                "El PIN no corresponde a la tarjeta").con("intentosRestantes", intentosRestantes);
    }

    public static ErrorDeNegocio accesoDenegado() {
        return new ErrorDeNegocio(HttpStatus.FORBIDDEN, "ACCESO_DENEGADO", "Acceso denegado",
                "El canal o el usuario no tienen permiso sobre este recurso");
    }

    public static ErrorDeNegocio rolNoPermitidoEnCanal() {
        return new ErrorDeNegocio(HttpStatus.FORBIDDEN, "ROL_NO_PERMITIDO_EN_CANAL", "Rol no permitido en el canal",
                "Este tipo de usuario no puede operar por este canal");
    }

    /** No distingue entre inexistente y ajena: responder 403 confirmaria que la cuenta existe. */
    public static ErrorDeNegocio cuentaNoEncontrada() {
        return new ErrorDeNegocio(HttpStatus.NOT_FOUND, "CUENTA_NO_ENCONTRADA", "Cuenta no encontrada",
                "La cuenta no existe o no pertenece al usuario");
    }

    public static ErrorDeNegocio clienteNoEncontrado() {
        return new ErrorDeNegocio(HttpStatus.NOT_FOUND, "CLIENTE_NO_ENCONTRADO", "Cliente no encontrado",
                "El cliente no existe o no corresponde al usuario");
    }

    public static ErrorDeNegocio idempotenciaConflicto() {
        return new ErrorDeNegocio(HttpStatus.CONFLICT, "IDEMPOTENCIA_CONFLICTO", "Clave de idempotencia en conflicto",
                "La clave de idempotencia ya se uso con otra solicitud");
    }

    public static ErrorDeNegocio saldoInsuficiente() {
        return new ErrorDeNegocio(HttpStatus.UNPROCESSABLE_ENTITY, "SALDO_INSUFICIENTE", "Saldo insuficiente",
                "El saldo disponible no alcanza para el monto solicitado");
    }

    public static ErrorDeNegocio limiteDiarioExcedido() {
        return new ErrorDeNegocio(HttpStatus.UNPROCESSABLE_ENTITY, "LIMITE_DIARIO_EXCEDIDO", "Limite diario excedido",
                "El retiro supera el limite diario de la tarjeta");
    }

    public static ErrorDeNegocio cuentaNoAdmiteRetiros() {
        return new ErrorDeNegocio(HttpStatus.UNPROCESSABLE_ENTITY, "CUENTA_NO_ADMITE_RETIROS",
                "La cuenta no admite retiros", "Solo las cuentas de ahorro admiten giros en cajero");
    }

    public static ErrorDeNegocio usuarioBloqueado() {
        return new ErrorDeNegocio(HttpStatus.LOCKED, "USUARIO_BLOQUEADO", "Usuario bloqueado",
                "Demasiados intentos fallidos. Intente mas tarde");
    }

    public static ErrorDeNegocio tarjetaBloqueada() {
        return new ErrorDeNegocio(HttpStatus.LOCKED, "TARJETA_BLOQUEADA", "Tarjeta bloqueada",
                "La tarjeta esta bloqueada");
    }

    public static ErrorDeNegocio sinCierrePublicado() {
        return new ErrorDeNegocio(HttpStatus.SERVICE_UNAVAILABLE, "SIN_CIERRE_PUBLICADO", "Sin cierre publicado",
                "Todavia no hay un cierre del batch publicado");
    }

    public static ErrorDeNegocio cuentaOcupada() {
        return new ErrorDeNegocio(HttpStatus.SERVICE_UNAVAILABLE, "CUENTA_OCUPADA", "Cuenta ocupada",
                "La cuenta esta siendo modificada por otra operacion. Reintente con la misma clave");
    }
}
