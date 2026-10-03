package com.bancoxyz.core.cierre;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/** Expone a las pruebas de otros paquetes los metodos package-private del sincronizador. */
public final class AccesoParaPruebas {

    private AccesoParaPruebas() {
    }

    public static String nombreDeUsuario(String nombre) {
        return SincronizadorDeCierre.nombreDeUsuario(nombre);
    }

    public static Map<Long, String> titularesCanonicosTodasRepetidas() {
        String marca = SincronizadorDeCierre.MARCA_CUENTA_REPETIDA;
        List<SincronizadorDeCierre.FilaInteres> filas = List.of(
                new SincronizadorDeCierre.FilaInteres(9, 200, "Segunda", "ahorro", BigDecimal.TEN, BigDecimal.ZERO, BigDecimal.ZERO, true, marca),
                new SincronizadorDeCierre.FilaInteres(3, 200, "Primera", "ahorro", BigDecimal.ONE, BigDecimal.ZERO, BigDecimal.ZERO, true, marca));
        return SincronizadorDeCierre.canonicas(filas).entrySet().stream()
                .collect(Collectors.toMap(Map.Entry::getKey, e -> e.getValue().nombre()));
    }
}
