package com.bancoxyz.core;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

import com.bancoxyz.core.error.ErrorDeNegocio;
import com.bancoxyz.core.operacion.ResultadoRetiro;
import com.bancoxyz.core.operacion.ServicioDeRetiros;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

/**
 * La prueba que justifica el bloqueo pesimista. NO es @Transactional: cada hilo debe tener su propia
 * transaccion y competir de verdad por la fila de la cuenta.
 */
class RetirosConcurrentesTest extends PruebaDelCore {

    @Autowired
    private ServicioDeRetiros retiros;

    @Test
    @DisplayName("20 retiros simultaneos de 1.000 sobre 5.000: exactamente 5 aprobados y el saldo nunca queda negativo")
    void veinteRetirosSimultaneosNoSobregiran() throws Exception {
        long tarjeta = tarjetaDeCuenta(102);
        List<String> resultados = enParalelo(20, i -> {
            try {
                retiros.retirar(102, tarjeta, "ATM-00" + (i % 2 + 1), "concurrente-%05d".formatted(i), new BigDecimal("1000"));
                return "APROBADO";
            } catch (ErrorDeNegocio e) {
                return e.getCodigo();
            }
        });

        Map<String, Long> conteo = resultados.stream().collect(Collectors.groupingBy(r -> r, Collectors.counting()));
        assertThat(conteo).containsEntry("APROBADO", 5L).containsEntry("SALDO_INSUFICIENTE", 15L).hasSize(2);
        assertThat(saldo(102)).isEqualTo("0");
        assertThat(jdbc.sql("select count(*) from core.operacion where cuenta_id = 102").query(Long.class).single())
                .isEqualTo(5L);
    }

    @Test
    @DisplayName("10 reintentos simultaneos con la misma clave descuentan una sola vez y devuelven el mismo comprobante")
    void mismaClaveEnParaleloDescuentaUnaVez() throws Exception {
        long tarjeta = tarjetaDeCuenta(101);
        List<ResultadoRetiro> resultados = enParalelo(10, i ->
                retiros.retirar(101, tarjeta, "ATM-001", "reintento-de-red-01", new BigDecimal("1000")));

        assertThat(resultados).extracting(r -> r.operacion().getId()).containsOnly(resultados.get(0).operacion().getId());
        assertThat(resultados).filteredOn(r -> !r.repetida()).hasSize(1);
        assertThat(saldo(101)).isEqualTo("7040");
        assertThat(jdbc.sql("select count(*) from core.operacion").query(Long.class).single()).isEqualTo(1L);
    }

    private interface Tarea<T> {
        T ejecutar(int indice) throws Exception;
    }

    private static <T> List<T> enParalelo(int hilos, Tarea<T> tarea) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(hilos);
        CountDownLatch largada = new CountDownLatch(1);
        try {
            List<Future<T>> futuros = new ArrayList<>();
            for (int i = 0; i < hilos; i++) {
                int indice = i;
                Callable<T> llamada = () -> {
                    largada.await();
                    return tarea.ejecutar(indice);
                };
                futuros.add(pool.submit(llamada));
            }
            largada.countDown();
            List<T> resultados = new ArrayList<>();
            for (Future<T> futuro : futuros) {
                resultados.add(futuro.get(30, TimeUnit.SECONDS));
            }
            return resultados;
        } finally {
            pool.shutdownNow();
        }
    }
}
