package com.bancoxyz.core.operacion;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Clock;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.HexFormat;
import java.util.Objects;
import java.util.Optional;

import com.bancoxyz.core.cuenta.Cuenta;
import com.bancoxyz.core.cuenta.RepositorioCuentas;
import com.bancoxyz.core.error.Errores;
import com.bancoxyz.core.tarjeta.RepositorioTarjetas;
import com.bancoxyz.core.tarjeta.Tarjeta;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Retiro en cajero: la operacion donde un error cuesta dinero real.
 *
 * <h2>El orden importa</h2>
 * <ol>
 *   <li><b>Bloquear la cuenta primero.</b> Dos retiros sobre la misma cuenta, aunque lleguen desde
 *       cajeros distintos, se ejecutan uno despues del otro.</li>
 *   <li><b>Idempotencia despues del bloqueo.</b> Si dos reintentos con la misma clave llegan a la vez,
 *       el segundo espera el bloqueo y, cuando entra, ya ve la operacion del primero. Mirar la clave
 *       antes de bloquear dejaria pasar a los dos.</li>
 *   <li><b>Reglas</b>: tarjeta de la cuenta y no bloqueada, cuenta de ahorro, limite diario, saldo.</li>
 *   <li><b>Descontar y registrar</b> en la misma transaccion.</li>
 * </ol>
 * <p>Ademas, la base tiene {@code check (saldo_disponible >= 0)} y {@code unique (canal, clave)}.</p>
 */
@Service
public class ServicioDeRetiros {

    private final RepositorioCuentas cuentas;
    private final RepositorioTarjetas tarjetas;
    private final RepositorioOperaciones operaciones;
    private final Clock reloj;

    public ServicioDeRetiros(RepositorioCuentas cuentas, RepositorioTarjetas tarjetas,
                             RepositorioOperaciones operaciones, Clock reloj) {
        this.cuentas = cuentas;
        this.tarjetas = tarjetas;
        this.operaciones = operaciones;
        this.reloj = reloj;
    }

    @Transactional
    public ResultadoRetiro retirar(long cuentaId, long tarjetaId, String terminalId, String claveIdempotencia,
                                   BigDecimal monto) {
        if (monto == null || monto.signum() <= 0 || monto.stripTrailingZeros().scale() > 0) {
            throw Errores.montoInvalido();
        }
        BigDecimal importe = monto.setScale(2);
        String huella = sha256Hex(cuentaId + "|" + tarjetaId + "|" + terminalId + "|" + importe.toPlainString());

        Cuenta cuenta = cuentas.buscarParaActualizar(cuentaId).orElseThrow(Errores::cuentaNoEncontrada);

        Optional<Operacion> previa = operaciones.findByCanalAndClaveIdempotencia(Operacion.CANAL_CAJERO,
                claveIdempotencia);
        if (previa.isPresent()) {
            if (previa.get().getHuellaSolicitud().equals(huella)) {
                return new ResultadoRetiro(previa.get(), true);
            }
            throw Errores.idempotenciaConflicto();
        }

        Tarjeta tarjeta = tarjetas.findById(tarjetaId)
                .filter(t -> Objects.equals(t.getCuentaId(), cuentaId))
                .orElseThrow(Errores::cuentaNoEncontrada);
        if (tarjeta.isBloqueada()) {
            throw Errores.tarjetaBloqueada();
        }
        if (!cuenta.esAhorro()) {
            throw Errores.cuentaNoAdmiteRetiros();
        }
        LocalDateTime inicioDelDia = LocalDate.now(reloj).atStartOfDay();
        BigDecimal retiradoHoy = operaciones.sumarRetirosDesde(tarjetaId, inicioDelDia);
        if (retiradoHoy.add(importe).compareTo(tarjeta.getLimiteDiario()) > 0) {
            throw Errores.limiteDiarioExcedido();
        }
        if (cuenta.getSaldoDisponible().compareTo(importe) < 0) {
            throw Errores.saldoInsuficiente();
        }

        LocalDateTime ahora = LocalDateTime.now(reloj).truncatedTo(ChronoUnit.SECONDS);
        cuenta.descontar(importe, ahora);
        Operacion operacion = operaciones.save(Operacion.retiroEnCajero(cuentaId, tarjetaId, terminalId, importe,
                cuenta.getSaldoDisponible(), claveIdempotencia, huella, ahora));
        return new ResultadoRetiro(operacion, false);
    }

    static String sha256Hex(String texto) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256")
                    .digest(texto.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
