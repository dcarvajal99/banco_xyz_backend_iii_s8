package com.bancoxyz.core;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.hamcrest.Matchers;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/** Matriz de la seccion 4.1: que canal y que usuario puede tocar que recurso. */
class AutorizacionPorCanalTest extends PruebaDelCore {

    @Test
    @DisplayName("Sin credencial o con clave mala: 401 NO_AUTENTICADO con ProblemDetail y correlacion")
    void sinCredencial() throws Exception {
        mvc.perform(get("/api/v1/cierres/vigentes").with(certificado("web")).header("X-Correlacion-Id", "prueba-correlacion-1"))
                .andExpect(status().isUnauthorized())
                .andExpect(header().string("X-Correlacion-Id", "prueba-correlacion-1"))
                .andExpect(jsonPath("$.codigo").value("NO_AUTENTICADO"))
                .andExpect(jsonPath("$.correlacionId").value("prueba-correlacion-1"))
                .andExpect(jsonPath("$.instance").value("/api/v1/cierres/vigentes"));
        mvc.perform(get("/api/v1/cierres/vigentes").with(httpBasic("bff-web", "clave-mala")).with(certificado("web")))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.codigo").value("NO_AUTENTICADO"));
        mvc.perform(get("/api/v1/cierres/vigentes").with(canal("web")).header("X-Correlacion-Id", "con espacios\ninyectados"))
                .andExpect(header().string("X-Correlacion-Id", Matchers.matchesPattern("[0-9a-f-]{36}")));
    }

    @Test
    @DisplayName("mTLS: sin certificado 401 CERTIFICADO_REQUERIDO, certificado de otro canal 403; Swagger y health no lo exigen")
    void certificadoDelCanal() throws Exception {
        mvc.perform(get("/api/v1/cierres/vigentes").with(httpBasic("bff-web", "web-secreto-dev"))
                        .header("X-Correlacion-Id", "prueba-mtls-1"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.codigo").value("CERTIFICADO_REQUERIDO"))
                .andExpect(jsonPath("$.correlacionId").value("prueba-mtls-1"));
        mvc.perform(get("/api/v1/cierres/vigentes").with(httpBasic("bff-web", "web-secreto-dev")).with(certificado("movil")))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.codigo").value("CERTIFICADO_NO_CORRESPONDE"));
        mvc.perform(get("/api/v1/cierres/vigentes").with(canal("cajero"))).andExpect(status().isOk());
        mvc.perform(get("/v3/api-docs")).andExpect(status().isOk());
        mvc.perform(get("/actuator/health")).andExpect(status().isOk());
    }

    @Test
    @DisplayName("Cada canal solo alcanza sus recursos (primera capa, por URL)")
    void matrizPorUrl() throws Exception {
        long diana = usuarioId("diana.prince");
        prohibido(post("/api/v1/cuentas/101/retiros").with(canal("movil")));
        prohibido(post("/api/v1/cuentas/101/retiros").with(canal("web")));
        prohibido(post("/api/v1/autenticacion/tarjetas").with(canal("web")));
        prohibido(post("/api/v1/autenticacion/usuarios").with(canal("cajero")));
        prohibido(get("/api/v1/clientes/1/cuentas").with(canal("cajero")));
        prohibido(get("/api/v1/cuentas/101/movimientos").with(canal("cajero")));
        prohibido(get("/api/v1/reportes/calidad").with(canal("movil")).header("X-Usuario-Id", diana));
        prohibido(get("/api/v1/clientes").with(canal("movil")).header("X-Usuario-Id", diana));
        prohibido(get("/api/v1/ruta/inexistente").with(canal("web")));
    }

    @Test
    @DisplayName("Segunda capa: el cliente ve solo lo suyo, el ejecutivo todo y solo por web")
    void matrizPorUsuario() throws Exception {
        long diana = usuarioId("diana.prince");
        long jane = usuarioId("jane.smith");
        long ejecutivo = usuarioId("ejecutivo");
        mvc.perform(get("/api/v1/cuentas/101").with(canal("web")))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.codigo").value("IDENTIDAD_REQUERIDA"));
        mvc.perform(get("/api/v1/cuentas/101").with(canal("web")).header("X-Usuario-Id", "abc"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.codigo").value("IDENTIDAD_REQUERIDA"));
        mvc.perform(get("/api/v1/cuentas/101").with(canal("web")).header("X-Usuario-Id", 99999))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.codigo").value("ACCESO_DENEGADO"));
        mvc.perform(get("/api/v1/cuentas/101").with(canal("web")).header("X-Usuario-Id", jane))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.codigo").value("CUENTA_NO_ENCONTRADA"));
        mvc.perform(get("/api/v1/cuentas/101").with(canal("web")).header("X-Usuario-Id", ejecutivo))
                .andExpect(status().isOk()).andExpect(jsonPath("$.titular").value("Diana Prince"));
        mvc.perform(get("/api/v1/cuentas/101").with(canal("movil")).header("X-Usuario-Id", ejecutivo))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.codigo").value("ACCESO_DENEGADO"));
        mvc.perform(get("/api/v1/clientes/{id}/cuentas", clienteId("Diana Prince")).with(canal("movil")).header("X-Usuario-Id", jane))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.codigo").value("CLIENTE_NO_ENCONTRADO"));
        mvc.perform(get("/api/v1/clientes/{id}/cuentas", clienteId("Diana Prince")).with(canal("web")).header("X-Usuario-Id", ejecutivo))
                .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(2));
        mvc.perform(get("/api/v1/reportes/calidad").with(canal("web")).header("X-Usuario-Id", diana))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.codigo").value("ACCESO_DENEGADO"));
        mvc.perform(get("/api/v1/clientes").with(canal("web")).header("X-Usuario-Id", ejecutivo))
                .andExpect(status().isOk()).andExpect(jsonPath("$[0].nombre").value("Diana Prince"))
                .andExpect(jsonPath("$[0].usuario").value("diana.prince"))
                .andExpect(jsonPath("$[0].cantidadCuentas").value(2));
    }

    @Test
    @DisplayName("El cajero solo ve la cuenta de su tarjeta y el retiro exige identidad, clave y cuerpo")
    void cajero() throws Exception {
        long tarjeta101 = tarjetaDeCuenta(101);
        mvc.perform(get("/api/v1/cuentas/101").with(canal("cajero")).header("X-Tarjeta-Id", tarjeta101).header("X-Terminal-Id", "ATM-001"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.saldoDisponible").value(8040.0));
        mvc.perform(get("/api/v1/cuentas/102").with(canal("cajero")).header("X-Tarjeta-Id", tarjeta101).header("X-Terminal-Id", "ATM-001"))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.codigo").value("CUENTA_NO_ENCONTRADA"));
        mvc.perform(get("/api/v1/cuentas/101").with(canal("cajero")).header("X-Tarjeta-Id", tarjeta101))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.codigo").value("IDENTIDAD_REQUERIDA"));
        mvc.perform(get("/api/v1/cuentas/101").with(canal("cajero")).header("X-Tarjeta-Id", 99999).header("X-Terminal-Id", "ATM-001"))
                .andExpect(status().isForbidden());

        MockHttpServletRequestBuilder retiro = post("/api/v1/cuentas/101/retiros").with(canal("cajero"))
                .header("X-Tarjeta-Id", tarjeta101).header("X-Terminal-Id", "ATM-001").contentType(MediaType.APPLICATION_JSON);
        mvc.perform(retiro.content("{\"monto\":1000}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.codigo").value("SOLICITUD_INVALIDA"));
        mvc.perform(post("/api/v1/cuentas/101/retiros").with(canal("cajero")).header("X-Tarjeta-Id", tarjeta101)
                        .header("X-Terminal-Id", "ATM-001").header("Idempotency-Key", "http-00000001"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.codigo").value("MONTO_INVALIDO"));
        mvc.perform(post("/api/v1/cuentas/101/retiros").with(canal("cajero")).header("X-Tarjeta-Id", tarjeta101)
                        .header("X-Terminal-Id", "ATM-001").header("Idempotency-Key", "http-00000002")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"monto\":3000}"))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.saldoResultante").value(5040.0))
                .andExpect(header().doesNotExist("Idempotency-Replayed"));
        mvc.perform(post("/api/v1/cuentas/101/retiros").with(canal("cajero")).header("X-Tarjeta-Id", tarjeta101)
                        .header("X-Terminal-Id", "ATM-001").header("Idempotency-Key", "http-00000002")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"monto\":3000}"))
                .andExpect(status().isOk()).andExpect(header().string("Idempotency-Replayed", "true"))
                .andExpect(jsonPath("$.saldoResultante").value(5040.0));
        mvc.perform(post("/api/v1/cuentas/101/retiros").with(canal("cajero")).header("X-Tarjeta-Id", tarjeta101)
                        .header("X-Terminal-Id", "ATM-001").header("Idempotency-Key", "http-00000002")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"monto\":4000}"))
                .andExpect(status().isConflict()).andExpect(jsonPath("$.codigo").value("IDEMPOTENCIA_CONFLICTO"));
    }

    private void prohibido(MockHttpServletRequestBuilder solicitud) throws Exception {
        mvc.perform(solicitud).andExpect(status().isForbidden()).andExpect(jsonPath("$.codigo").value("ACCESO_DENEGADO"));
    }
}
