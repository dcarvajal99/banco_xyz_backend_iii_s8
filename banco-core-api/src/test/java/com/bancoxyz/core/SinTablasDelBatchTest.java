package com.bancoxyz.core;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.bancoxyz.core.cierre.SincronizadorDeCierre;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Base nueva: el batch nunca corrio. El core debe arrancar igual y responder 503, no 500 ni caerse.
 */
@SpringBootTest(properties =
        "spring.datasource.url=jdbc:h2:mem:sintablas;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH;DB_CLOSE_DELAY=-1")
@AutoConfigureMockMvc
@ActiveProfiles("prueba")
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
class SinTablasDelBatchTest {

    @Autowired
    private SincronizadorDeCierre sincronizador;

    @Autowired
    private MockMvc mvc;

    @Test
    @Order(1)
    @DisplayName("Sin tablas del batch: la sincronizacion avisa y las APIs responden 503 SIN_CIERRE_PUBLICADO")
    void sinTablas() throws Exception {
        assertThat(sincronizador.sincronizar().hayCierre()).isFalse();
        mvc.perform(get("/api/v1/cierres/vigentes").with(PruebaDelCore.canal("web")))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.codigo").value("SIN_CIERRE_PUBLICADO"));
    }

    @Test
    @Order(2)
    @Sql("/sql/esquema-batch.sql")
    @DisplayName("Tablas creadas pero sin ejecucion COMPLETED: tampoco hay cierre")
    void tablasVacias() throws Exception {
        assertThat(sincronizador.sincronizar().hayCierre()).isFalse();
        mvc.perform(get("/api/v1/cierres/vigentes").with(PruebaDelCore.canal("cajero")))
                .andExpect(status().isServiceUnavailable());
    }
}
