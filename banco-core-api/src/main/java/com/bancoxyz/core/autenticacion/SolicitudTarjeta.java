package com.bancoxyz.core.autenticacion;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record SolicitudTarjeta(@NotBlank @Size(max = 19) String numeroTarjeta, @NotBlank @Size(max = 12) String pin) {
}
