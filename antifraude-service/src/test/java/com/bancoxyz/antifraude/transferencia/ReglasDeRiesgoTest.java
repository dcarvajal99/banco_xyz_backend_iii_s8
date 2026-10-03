package com.bancoxyz.antifraude.transferencia;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Set;
import java.util.UUID;

import com.bancoxyz.antifraude.config.PropiedadesAntifraude;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Reglas de riesgo puras, sin Spring: se instancia {@link PropiedadesAntifraude} a mano y se prueba
 * {@link ReglasDeRiesgo} directamente.
 */
class ReglasDeRiesgoTest {

    private static final BigDecimal MONTO_MAXIMO = new BigDecimal("500000");

    private final ReglasDeRiesgo reglas = new ReglasDeRiesgo(
            new PropiedadesAntifraude(MONTO_MAXIMO, Set.of(104L), 0));

    @Test
    @DisplayName("Bajo el limite y sin cuentas en observacion: se aprueba")
    void apruebaBajoElLimite() {
        assertThat(reglas.evaluar(reserva("200000.00", 101L, 105L))).isEmpty();
    }

    @Test
    @DisplayName("Sobre el limite: se rechaza con MONTO_SOBRE_LIMITE")
    void rechazaSobreElLimite() {
        assertThat(reglas.evaluar(reserva("500000.01", 101L, 105L))).contains(ReglasDeRiesgo.MONTO_SOBRE_LIMITE);
    }

    @Test
    @DisplayName("Exactamente en el limite: se aprueba, el limite es inclusive")
    void enElLimiteExactoAprueba() {
        assertThat(reglas.evaluar(reserva("500000.00", 101L, 105L))).isEmpty();
    }

    @Test
    @DisplayName("Cuenta de origen en observacion: se rechaza con CUENTA_EN_OBSERVACION")
    void rechazaOrigenEnObservacion() {
        assertThat(reglas.evaluar(reserva("1000.00", 104L, 105L))).contains(ReglasDeRiesgo.CUENTA_EN_OBSERVACION);
    }

    @Test
    @DisplayName("Cuenta de destino en observacion: se rechaza con CUENTA_EN_OBSERVACION")
    void rechazaDestinoEnObservacion() {
        assertThat(reglas.evaluar(reserva("1000.00", 101L, 104L))).contains(ReglasDeRiesgo.CUENTA_EN_OBSERVACION);
    }

    private static EventoDeTransferencia reserva(String monto, long origen, long destino) {
        return new EventoDeTransferencia(UUID.randomUUID().toString(), EventoDeTransferencia.FONDOS_RESERVADOS,
                UUID.randomUUID().toString(), Instant.now(), 1L, 1L, origen, destino, new BigDecimal(monto), null,
                null, null);
    }
}
