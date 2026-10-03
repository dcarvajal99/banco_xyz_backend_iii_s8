package com.bancoxyz.core;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.bancoxyz.core.operacion.ServicioDeRetiros;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.dao.CannotAcquireLockException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/** Fallas que no se pueden provocar con datos: bloqueo no obtenido, violacion de unicidad, error inesperado. */
class ErroresTecnicosTest extends PruebaDelCore {

    @MockitoBean
    private ServicioDeRetiros retiros;

    @Test
    @DisplayName("Bloqueo no obtenido -> 503 CUENTA_OCUPADA; unicidad violada -> 409; error inesperado -> 500 sin detalles")
    void traduccionDeFallasTecnicas() throws Exception {
        when(retiros.retirar(anyLong(), anyLong(), anyString(), anyString(), any()))
                .thenThrow(new CannotAcquireLockException("lock timeout"))
                .thenThrow(new DataIntegrityViolationException("uk_operacion_canal_clave"))
                .thenThrow(new IllegalStateException("detalle interno que no debe salir"));
        mvc.perform(retiro()).andExpect(status().isServiceUnavailable()).andExpect(jsonPath("$.codigo").value("CUENTA_OCUPADA"));
        mvc.perform(retiro()).andExpect(status().isConflict()).andExpect(jsonPath("$.codigo").value("IDEMPOTENCIA_CONFLICTO"));
        mvc.perform(retiro()).andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.codigo").value("ERROR_INTERNO"))
                .andExpect(jsonPath("$.detail").value("Error interno del servicio"));
    }

    @Test
    @DisplayName("Errores de Spring MVC tambien llevan codigo: cuerpo ilegible, tipo de parametro y metodo no soportado")
    void erroresDeSpringConCodigo() throws Exception {
        mvc.perform(post("/api/v1/autenticacion/usuarios").with(canal("web")).contentType(MediaType.APPLICATION_JSON).content("{no es json"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.codigo").value("SOLICITUD_INVALIDA"))
                .andExpect(jsonPath("$.instance").value("/api/v1/autenticacion/usuarios"));
        mvc.perform(get("/api/v1/cuentas/abc").with(canal("web")).header("X-Usuario-Id", usuarioId("diana.prince")))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.codigo").value("SOLICITUD_INVALIDA"));
        mvc.perform(get("/api/v1/reportes/resumen-diario").param("desde", "no-es-fecha").with(canal("web"))
                        .header("X-Usuario-Id", usuarioId("ejecutivo")))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.codigo").value("SOLICITUD_INVALIDA"));
    }

    private MockHttpServletRequestBuilder retiro() {
        return post("/api/v1/cuentas/101/retiros").with(canal("cajero")).header("X-Tarjeta-Id", tarjetaDeCuenta(101))
                .header("X-Terminal-Id", "ATM-001").header("Idempotency-Key", "tecnico-000001")
                .contentType(MediaType.APPLICATION_JSON).content("{\"monto\":1000}");
    }
}
