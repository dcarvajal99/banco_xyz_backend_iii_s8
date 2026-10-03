package com.bancoxyz.transferencias.transferencia;

import java.math.BigDecimal;

import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record SolicitudTransferencia(@NotNull @Positive Long cuentaOrigen, @NotNull @Positive Long cuentaDestino,
                                     @NotNull @Positive @Digits(integer = 12, fraction = 2) BigDecimal monto) {
}
