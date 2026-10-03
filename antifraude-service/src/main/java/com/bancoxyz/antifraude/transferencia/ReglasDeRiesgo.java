package com.bancoxyz.antifraude.transferencia;

import java.util.Optional;

import com.bancoxyz.antifraude.config.PropiedadesAntifraude;
import org.springframework.stereotype.Component;

/**
 * La logica de negocio del servicio, sin nada de Kafka ni de Spring alrededor: recibe la reserva y devuelve el motivo
 * de rechazo si corresponde, o vacio si la transferencia se aprueba.
 *
 * <p>Se evaluan en orden y se corta en la primera que aplique, tal como documenta el README: primero el monto, despues
 * las cuentas en observacion (origen o destino).</p>
 */
@Component
public class ReglasDeRiesgo {

    public static final String MONTO_SOBRE_LIMITE = "MONTO_SOBRE_LIMITE";
    public static final String CUENTA_EN_OBSERVACION = "CUENTA_EN_OBSERVACION";

    private final PropiedadesAntifraude propiedades;

    public ReglasDeRiesgo(PropiedadesAntifraude propiedades) {
        this.propiedades = propiedades;
    }

    /** Motivo de rechazo, o vacio si la reserva no dispara ninguna regla y la transferencia se aprueba. */
    public Optional<String> evaluar(EventoDeTransferencia reserva) {
        if (reserva.monto() != null && reserva.monto().compareTo(propiedades.montoMaximo()) > 0) {
            return Optional.of(MONTO_SOBRE_LIMITE);
        }
        if (enObservacion(reserva.cuentaOrigen()) || enObservacion(reserva.cuentaDestino())) {
            return Optional.of(CUENTA_EN_OBSERVACION);
        }
        return Optional.empty();
    }

    private boolean enObservacion(Long cuenta) {
        return cuenta != null && propiedades.cuentasEnObservacion().contains(cuenta);
    }
}
