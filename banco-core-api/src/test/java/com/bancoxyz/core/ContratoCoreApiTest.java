package com.bancoxyz.core;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.nio.file.Path;
import java.util.Set;
import java.util.TreeSet;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MvcResult;

/**
 * Prueba de PROVEEDOR del contrato: cada respuesta real del core tiene exactamente las claves de su archivo
 * en {@code contratos/core-api}. Los BFF usan esos mismos archivos como respuesta simulada, asi que si el
 * core renombra o quita un campo, este build falla antes de que un BFF lo descubra en produccion.
 */
class ContratoCoreApiTest extends PruebaDelCore {

    private static final Path CONTRATOS = Path.of("contratos", "core-api");

    @Test
    @DisplayName("Autenticacion de usuario y de tarjeta cumplen su contrato")
    void autenticacion() throws Exception {
        cumple("usuario-autenticado.json", mvc.perform(post("/api/v1/autenticacion/usuarios").with(canal("web"))
                .contentType(MediaType.APPLICATION_JSON).content("{\"usuario\":\"diana.prince\",\"password\":\"Cliente2026!\"}"))
                .andExpect(status().isOk()).andReturn());
        cumple("tarjeta-autenticada.json", mvc.perform(post("/api/v1/autenticacion/tarjetas").with(canal("cajero"))
                .contentType(MediaType.APPLICATION_JSON).content("{\"numeroTarjeta\":\"4000000000001018\",\"pin\":\"1234\"}"))
                .andExpect(status().isOk()).andReturn());
    }

    @Test
    @DisplayName("Clientes, cuentas, movimientos y estados anuales cumplen su contrato")
    void cuentas() throws Exception {
        long diana = usuarioId("diana.prince");
        long ejecutivo = usuarioId("ejecutivo");
        cumple("clientes.json", mvc.perform(get("/api/v1/clientes").with(canal("web")).header("X-Usuario-Id", ejecutivo))
                .andExpect(status().isOk()).andReturn());
        cumple("cuentas.json", mvc.perform(get("/api/v1/clientes/{id}/cuentas", clienteId("Diana Prince"))
                .with(canal("web")).header("X-Usuario-Id", diana)).andExpect(status().isOk()).andReturn());
        cumple("cuenta.json", mvc.perform(get("/api/v1/cuentas/101").with(canal("web")).header("X-Usuario-Id", diana))
                .andExpect(status().isOk()).andReturn());
        cumple("pagina-movimientos.json", mvc.perform(get("/api/v1/cuentas/101/movimientos").with(canal("movil"))
                .header("X-Usuario-Id", diana)).andExpect(status().isOk()).andReturn());
        cumple("estados-anuales.json", mvc.perform(get("/api/v1/cuentas/101/estados-anuales").with(canal("web"))
                .header("X-Usuario-Id", diana)).andExpect(status().isOk()).andReturn());
    }

    @Test
    @DisplayName("Retiro, reportes y cierres cumplen su contrato")
    void operacionesYReportes() throws Exception {
        long ejecutivo = usuarioId("ejecutivo");
        cumple("operacion-retiro.json", mvc.perform(post("/api/v1/cuentas/101/retiros").with(canal("cajero"))
                .header("X-Tarjeta-Id", tarjetaDeCuenta(101)).header("X-Terminal-Id", "ATM-001")
                .header("Idempotency-Key", "contrato-000001").contentType(MediaType.APPLICATION_JSON)
                .content("{\"monto\":1000}")).andExpect(status().isCreated()).andReturn());
        cumple("resumen-diario.json", mvc.perform(get("/api/v1/reportes/resumen-diario").with(canal("web"))
                .header("X-Usuario-Id", ejecutivo)).andExpect(status().isOk()).andReturn());
        cumple("calidad.json", mvc.perform(get("/api/v1/reportes/calidad").with(canal("web"))
                .header("X-Usuario-Id", ejecutivo)).andExpect(status().isOk()).andReturn());
        cumple("cierres-vigentes.json", mvc.perform(get("/api/v1/cierres/vigentes").with(canal("cajero")))
                .andExpect(status().isOk()).andReturn());
    }

    @Test
    @DisplayName("Los errores cumplen la forma de ProblemDetail del contrato")
    void errores() throws Exception {
        cumple("error-pin-incorrecto.json", mvc.perform(post("/api/v1/autenticacion/tarjetas").with(canal("cajero"))
                .contentType(MediaType.APPLICATION_JSON).content("{\"numeroTarjeta\":\"4000000000001018\",\"pin\":\"9999\"}"))
                .andExpect(status().isUnauthorized()).andReturn());
        cumple("error-saldo-insuficiente.json", mvc.perform(post("/api/v1/cuentas/102/retiros").with(canal("cajero"))
                .header("X-Tarjeta-Id", tarjetaDeCuenta(102)).header("X-Terminal-Id", "ATM-001")
                .header("Idempotency-Key", "contrato-000002").contentType(MediaType.APPLICATION_JSON)
                .content("{\"monto\":6000}")).andExpect(status().isUnprocessableEntity()).andReturn());
        cumple("error-cuenta-no-encontrada.json", mvc.perform(get("/api/v1/cuentas/101").with(canal("web"))
                .header("X-Usuario-Id", usuarioId("jane.smith"))).andExpect(status().isNotFound()).andReturn());
        cumple("error-acceso-denegado.json", mvc.perform(post("/api/v1/cuentas/101/retiros").with(canal("movil")))
                .andExpect(status().isForbidden()).andReturn());
    }

    private void cumple(String archivo, MvcResult resultado) throws Exception {
        JsonNode real = json.readTree(resultado.getResponse().getContentAsString());
        JsonNode esperado = json.readTree(CONTRATOS.resolve(archivo).toFile());
        assertThat(claves(real, "$")).as("claves de %s", archivo).isEqualTo(claves(esperado, "$"));
    }

    /** Conjunto recursivo de rutas de claves. Una lista vacia no se puede verificar: falla en vez de pasar en blanco. */
    static Set<String> claves(JsonNode nodo, String ruta) {
        Set<String> rutas = new TreeSet<>();
        if (nodo.isObject()) {
            nodo.fields().forEachRemaining(campo -> {
                rutas.add(ruta + "." + campo.getKey());
                rutas.addAll(claves(campo.getValue(), ruta + "." + campo.getKey()));
            });
        } else if (nodo.isArray()) {
            if (nodo.isEmpty()) {
                throw new AssertionError("Lista vacia en " + ruta + ": el fixture debe poblarla para verificar el contrato");
            }
            nodo.forEach(elemento -> rutas.addAll(claves(elemento, ruta + "[]")));
        }
        return rutas;
    }
}
