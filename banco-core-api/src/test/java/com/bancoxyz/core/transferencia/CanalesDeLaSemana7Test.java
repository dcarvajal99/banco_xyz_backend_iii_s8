package com.bancoxyz.core.transferencia;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.bancoxyz.core.PruebaDelCore;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

/**
 * Los canales de banco-auth (solo verifica claves de clientes, con clave Basic) y de transferencias-service (solo lee
 * cuentas propias, con un token OAuth 2.0 client_credentials desde la semana 8). Ambos exigen ademas su certificado.
 */
class CanalesDeLaSemana7Test extends PruebaDelCore {

    @Test
    @DisplayName("banco-auth autentica a un cliente, rechaza al ejecutivo y no puede leer cuentas")
    void canalDeAutenticacion() throws Exception {
        mvc.perform(post("/api/v1/autenticacion/usuarios").with(servicio("banco-auth", "autenticacion-secreto-dev"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"usuario\":\"diana.prince\",\"password\":\"Cliente2026!\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.rol").value("CLIENTE"));
        mvc.perform(post("/api/v1/autenticacion/usuarios").with(servicio("banco-auth", "autenticacion-secreto-dev"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"usuario\":\"ejecutivo\",\"password\":\"Ejecutivo2026!\"}"))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.codigo").value("ROL_NO_PERMITIDO_EN_CANAL"));
        mvc.perform(get("/api/v1/cuentas/101").with(servicio("banco-auth", "autenticacion-secreto-dev"))
                        .header("X-Usuario-Id", usuarioId("diana.prince")))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Semana 8: banco-auth identifica sin clave a un cliente que entro con GitHub; nadie mas puede hacerlo")
    void identificacionParaGitHub() throws Exception {
        mvc.perform(get("/api/v1/autenticacion/usuarios/diana.prince").with(servicio("banco-auth", "autenticacion-secreto-dev")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.usuarioId").value(usuarioId("diana.prince")))
                .andExpect(jsonPath("$.usuario").value("diana.prince")).andExpect(jsonPath("$.rol").value("CLIENTE"));
        mvc.perform(get("/api/v1/autenticacion/usuarios/no.existe").with(servicio("banco-auth", "autenticacion-secreto-dev")))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.codigo").value("USUARIO_NO_ENCONTRADO"));
        mvc.perform(get("/api/v1/autenticacion/usuarios/ejecutivo").with(servicio("banco-auth", "autenticacion-secreto-dev")))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.codigo").value("ROL_NO_PERMITIDO_EN_CANAL"));
        jdbc.sql("update core.usuario set bloqueado_hasta = ? where usuario = 'jane.smith'")
                .param(java.time.LocalDateTime.now(reloj).plusMinutes(10)).update();
        mvc.perform(get("/api/v1/autenticacion/usuarios/jane.smith").with(servicio("banco-auth", "autenticacion-secreto-dev")))
                .andExpect(status().isLocked()).andExpect(jsonPath("$.codigo").value("USUARIO_BLOQUEADO"));
        // Ningun otro canal identifica sin clave: ni la banca web ni transferencias-service con su token.
        mvc.perform(get("/api/v1/autenticacion/usuarios/diana.prince").with(canal("web")))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/autenticacion/usuarios/diana.prince")
                        .with(tokenDeServicio("transferencias-service", "transferencias-service", "core.cuentas.leer")))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("transferencias-service con su token OAuth lee la cuenta propia del usuario (200), una ajena da 404 y no puede retirar")
    void canalDeTransferencias() throws Exception {
        long diana = usuarioId("diana.prince");
        mvc.perform(get("/api/v1/cuentas/101").with(tokenDeServicio("transferencias-service", "transferencias-service", "core.cuentas.leer"))
                        .header("X-Usuario-Id", diana))
                .andExpect(status().isOk()).andExpect(jsonPath("$.cuentaId").value(101));
        mvc.perform(get("/api/v1/cuentas/102").with(tokenDeServicio("transferencias-service", "transferencias-service", "core.cuentas.leer"))
                        .header("X-Usuario-Id", diana))
                .andExpect(status().isNotFound());
        mvc.perform(post("/api/v1/cuentas/101/retiros").with(tokenDeServicio("transferencias-service", "transferencias-service", "core.cuentas.leer"))
                        .header("X-Usuario-Id", diana).contentType(MediaType.APPLICATION_JSON).content("{\"monto\":1000}"))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Semana 8: la antigua clave Basic de transferencias-service ya no existe (401)")
    void sinClaveBasic() throws Exception {
        mvc.perform(get("/api/v1/cuentas/101").with(servicio("transferencias-service", "transferencias-secreto-dev"))
                        .header("X-Usuario-Id", usuarioId("diana.prince")))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.codigo").value("NO_AUTENTICADO"));
    }

    @Test
    @DisplayName("Un token sin el scope core.cuentas.leer (403) o con el certificado de otro servicio (403) no pasa")
    void tokenSinScopeOCertificadoAjeno() throws Exception {
        long diana = usuarioId("diana.prince");
        mvc.perform(get("/api/v1/cuentas/101").with(tokenDeServicio("transferencias-service", "transferencias-service", "otro.scope"))
                        .header("X-Usuario-Id", diana))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/cuentas/101").with(tokenDeServicio("transferencias-service", "banco-auth", "core.cuentas.leer"))
                        .header("X-Usuario-Id", diana))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.codigo").value("CERTIFICADO_NO_CORRESPONDE"));
    }
}
