package com.bancoxyz.core;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.math.BigDecimal;

import com.bancoxyz.core.cierre.ResumenSincronizacion;
import com.bancoxyz.core.cierre.SincronizadorDeCierre;
import com.bancoxyz.core.operacion.ServicioDeRetiros;
import com.bancoxyz.core.tarjeta.Luhn;
import org.hamcrest.Matchers;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

class CierresYSincronizacionTest extends PruebaDelCore {

    @Autowired
    private ServicioDeRetiros retiros;

    @Test
    @DisplayName("Publica la ejecucion COMPLETED aunque haya una FAILED mas reciente, con la fila canonica de cada cuenta")
    void publicaSoloLoQueElDecisorDejoPasar() {
        assertThat(jdbc.sql("select count(*) from core.cuenta").query(Long.class).single()).isEqualTo(5L);
        assertThat(jdbc.sql("select count(*) from core.cuenta where id = 199").query(Long.class).single()).isZero();
        assertThat(jdbc.sql("select titular || '|' || tipo || '|' || saldo_disponible from core.cuenta where id = 101")
                .query(String.class).single()).isEqualTo("Diana Prince|ahorro|8040.00");
        // Canonica aunque traiga OTRA observacion: solo la marca de repetida la descarta.
        assertThat(jdbc.sql("select titular || '|' || tipo from core.cuenta where id = 102").query(String.class).single())
                .isEqualTo("Jane Smith|ahorro");
        assertThat(jdbc.sql("select cliente_id from core.cuenta where id = 104").query(Long.class).optional()).isEmpty();
        assertThat(jdbc.sql("select count(*) from core.cliente").query(Long.class).single()).isEqualTo(2L);
        assertThat(jdbc.sql("select count(*) from core.tarjeta").query(Long.class).single()).isEqualTo(3L);
        assertThat(jdbc.sql("select count(*) from core.usuario").query(Long.class).single()).isEqualTo(3L);
    }

    @Test
    @DisplayName("Sincronizar de nuevo no crea duplicados ni pisa el saldo cambiado por un retiro")
    void sincronizacionIdempotente() {
        retiros.retirar(101, tarjetaDeCuenta(101), "ATM-001", "sincro-00000001", new BigDecimal("3000"));
        ResumenSincronizacion segunda = sincronizador.sincronizar();
        assertThat(segunda.hayCierre()).isTrue();
        assertThat(segunda.jobExecutionId()).isEqualTo(10L);
        assertThat(segunda.calidad()).isEqualTo("DEGRADADA");
        assertThat(segunda.cuentasNuevas()).isZero();
        assertThat(segunda.cuentasExistentes()).isEqualTo(5);
        assertThat(segunda.usuariosNuevos()).isZero();
        assertThat(segunda.tarjetasNuevas()).isZero();
        assertThat(saldo(101)).isEqualTo("5040");
    }

    @Test
    @DisplayName("El numero de tarjeta es Luhn valido y en la base solo queda su HMAC")
    void tarjetaSinPanEnClaro() {
        String pan = SincronizadorDeCierre.numeroDeTarjeta(101);
        assertThat(pan).isEqualTo("4000000000001018");
        assertThat(Luhn.esValido(pan)).isTrue();
        assertThat(jdbc.sql("select count(*) from core.tarjeta where numero_hash = :p").param("p", pan)
                .query(Long.class).single()).isZero();
        assertThat(jdbc.sql("select ultimos4 from core.tarjeta where cuenta_id = 101").query(String.class).single())
                .isEqualTo("1018");
    }

    @Test
    @DisplayName("Cierres vigentes y calidad: DEGRADADA y rechazados solo de la ejecucion publicada, agrupados")
    void calidadDelCierre() throws Exception {
        long ejecutivo = usuarioId("ejecutivo");
        mvc.perform(get("/api/v1/cierres/vigentes").with(canal("movil")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(3))
                .andExpect(jsonPath("$[*].jobExecutionId", Matchers.everyItem(Matchers.is(10))))
                .andExpect(jsonPath("$[0].calidad").value("DEGRADADA"))
                .andExpect(jsonPath("$[0].jobNombre").value("migracionCompletaJob"));
        mvc.perform(get("/api/v1/reportes/calidad").with(canal("web")).header("X-Usuario-Id", ejecutivo))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.rechazados.length()").value(4))
                .andExpect(jsonPath("$.rechazados[?(@.jobNombre=='calculoInteresesMensualesJob' && @.clasificacion=='OMITIDO')].cantidad").value(2))
                .andExpect(jsonPath("$.rechazados[?(@.clasificacion=='FILTRADO')].cantidad").value(1));
        mvc.perform(get("/api/v1/reportes/resumen-diario").param("desde", "2024-06-30").param("hasta", "2024-06-30")
                        .with(canal("web")).header("X-Usuario-Id", ejecutivo))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].fecha").value("2024-06-30"));
    }

    @Test
    @DisplayName("Movimientos: une el cierre con los retiros en linea, pagina en la base y excluye la ejecucion fallida")
    void movimientosDelCierreYEnLinea() throws Exception {
        long diana = usuarioId("diana.prince");
        retiros.retirar(101, tarjetaDeCuenta(101), "ATM-002", "movs-000000001", new BigDecimal("2000"));
        mvc.perform(get("/api/v1/cuentas/101/movimientos").param("tamano", "2").with(canal("web")).header("X-Usuario-Id", diana))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElementos").value(4))
                .andExpect(jsonPath("$.totalPaginas").value(2))
                .andExpect(jsonPath("$.contenido[0].origen").value("EN_LINEA"))
                .andExpect(jsonPath("$.contenido[0].id").value(Matchers.startsWith("L-")))
                .andExpect(jsonPath("$.contenido[0].monto").value(-2000.0))
                .andExpect(jsonPath("$.contenido[0].descripcion").value("Retiro en cajero ATM-002"))
                .andExpect(jsonPath("$.contenido[1].id").value("C-1"));
        mvc.perform(get("/api/v1/cuentas/101/movimientos").param("pagina", "5").with(canal("web")).header("X-Usuario-Id", diana))
                .andExpect(status().isOk()).andExpect(jsonPath("$.contenido.length()").value(0));
        mvc.perform(get("/api/v1/cuentas/101/movimientos").param("tamano", "101").with(canal("web")).header("X-Usuario-Id", diana))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.codigo").value("SOLICITUD_INVALIDA"));
        mvc.perform(get("/api/v1/cuentas/101/estados-anuales").with(canal("movil")).header("X-Usuario-Id", diana))
                .andExpect(status().isOk()).andExpect(jsonPath("$[0].anio").value(2024))
                .andExpect(jsonPath("$[0].totalCargos").value(1600.0));
    }
}
