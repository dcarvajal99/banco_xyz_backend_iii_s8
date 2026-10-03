package com.bancoxyz.antifraude.config;

import java.math.BigDecimal;
import java.util.Set;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Reglas de riesgo del servicio, entregadas por el Config Server (respaldo local en {@code application.properties}).
 *
 * <p>Es un record comun, sin nada de Spring en su logica: {@link ReglasDeRiesgo} lo recibe por constructor y se prueba
 * sin arrancar el contexto. {@code cuentas-en-observacion} es una lista separada por comas; vacia significa ninguna.</p>
 */
@ConfigurationProperties(prefix = "banco.antifraude")
public record PropiedadesAntifraude(BigDecimal montoMaximo, Set<Long> cuentasEnObservacion, long demoraMs) {
}
