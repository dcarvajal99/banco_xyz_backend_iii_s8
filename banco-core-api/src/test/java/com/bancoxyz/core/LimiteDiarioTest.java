package com.bancoxyz.core;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.bancoxyz.core.error.ErrorDeNegocio;
import com.bancoxyz.core.operacion.ServicioDeRetiros;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

class LimiteDiarioTest extends PruebaDelCore {

    @Autowired
    private ServicioDeRetiros retiros;

    @Test
    @DisplayName("El limite diario se cuenta desde la medianoche de Santiago: 23:59 y 00:01 son dias distintos")
    void limiteDiarioPorDiaDeSantiago() {
        long tarjeta = tarjetaDeCuenta(105);
        reloj.fijar(LocalDateTime.of(2026, 9, 12, 23, 59));
        retiros.retirar(105, tarjeta, "ATM-001", "limite-00000001", new BigDecimal("6000"));
        assertThatThrownBy(() -> retiros.retirar(105, tarjeta, "ATM-001", "limite-00000002", new BigDecimal("5000")))
                .isInstanceOf(ErrorDeNegocio.class).extracting("codigo").isEqualTo("LIMITE_DIARIO_EXCEDIDO");

        reloj.fijar(LocalDateTime.of(2026, 9, 13, 0, 1));
        retiros.retirar(105, tarjeta, "ATM-001", "limite-00000003", new BigDecimal("5000"));
        assertThat(saldo(105)).isEqualTo("1072");
    }

    @Test
    @DisplayName("Reglas del retiro: monto invalido, cuenta que no admite giros, tarjeta de otra cuenta y conflicto de clave")
    void reglasDelRetiro() {
        long tarjeta101 = tarjetaDeCuenta(101);
        assertThatThrownBy(() -> retiros.retirar(101, tarjeta101, "ATM-001", "reglas-00000001", new BigDecimal("1000.50")))
                .extracting("codigo").isEqualTo("MONTO_INVALIDO");
        assertThatThrownBy(() -> retiros.retirar(101, tarjeta101, "ATM-001", "reglas-00000002", BigDecimal.ZERO))
                .extracting("codigo").isEqualTo("MONTO_INVALIDO");
        assertThatThrownBy(() -> retiros.retirar(102, tarjeta101, "ATM-001", "reglas-00000003", new BigDecimal("1000")))
                .extracting("codigo").isEqualTo("CUENTA_NO_ENCONTRADA");
        assertThatThrownBy(() -> retiros.retirar(999, tarjeta101, "ATM-001", "reglas-00000004", new BigDecimal("1000")))
                .extracting("codigo").isEqualTo("CUENTA_NO_ENCONTRADA");

        jdbc.sql("insert into core.tarjeta (numero_hash, ultimos4, cuenta_id, pin_hash, limite_diario) "
                + "values ('hash-prestamo', '1031', 103, 'x', 10000)").update();
        long tarjetaPrestamo = tarjetaDeCuenta(103);
        assertThatThrownBy(() -> retiros.retirar(103, tarjetaPrestamo, "ATM-001", "reglas-00000005", new BigDecimal("1000")))
                .extracting("codigo").isEqualTo("CUENTA_NO_ADMITE_RETIROS");

        retiros.retirar(101, tarjeta101, "ATM-001", "reglas-00000006", new BigDecimal("1000"));
        assertThatThrownBy(() -> retiros.retirar(101, tarjeta101, "ATM-001", "reglas-00000006", new BigDecimal("2000")))
                .extracting("codigo").isEqualTo("IDEMPOTENCIA_CONFLICTO");

        jdbc.sql("update core.tarjeta set bloqueada = true where cuenta_id = 101").update();
        assertThatThrownBy(() -> retiros.retirar(101, tarjeta101, "ATM-001", "reglas-00000007", new BigDecimal("1000")))
                .extracting("codigo").isEqualTo("TARJETA_BLOQUEADA");
    }
}
