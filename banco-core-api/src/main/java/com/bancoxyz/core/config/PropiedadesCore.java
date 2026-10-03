package com.bancoxyz.core.config;

import java.math.BigDecimal;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Propiedades del core bajo {@code banco.core}.
 *
 * @param zonaHoraria          zona con la que se calcula "hoy" para el limite diario
 * @param sincronizarAlIniciar abrir las cuentas del cierre publicado al arrancar
 * @param canales              clave Basic de cada canal con usuario de servicio (BFF y banco-auth); transferencias-service
 *                             entra con un token OAuth 2.0 (ver {@code TokensDeServicio})
 * @param seguridad            pepper de tarjetas y costo de BCrypt
 * @param datosDemo            credenciales de demostracion creadas al sincronizar
 * @param cajero               reglas del retiro que el core aplica a todos los cajeros
 */
@ConfigurationProperties(prefix = "banco.core")
public record PropiedadesCore(String zonaHoraria, boolean sincronizarAlIniciar, Canales canales,
                              Seguridad seguridad, DatosDemo datosDemo, Cajero cajero) {

    public record Canales(Canal web, Canal movil, Canal cajero, Canal autenticacion) {
    }

    public record Canal(String clave) {
    }

    public record Seguridad(String pepperTarjetas, int bcryptFuerza) {
    }

    public record DatosDemo(boolean habilitados, String claveClientes, String claveEjecutivo, String pin) {
    }

    public record Cajero(BigDecimal limiteDiario) {
    }
}
