package com.bancoxyz.core;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

import com.bancoxyz.core.autenticacion.ServicioDeAutenticacion;
import com.bancoxyz.core.autenticacion.ServicioDeAutenticacion.EstadoTarjeta;
import com.bancoxyz.core.autenticacion.ServicioDeAutenticacion.EstadoUsuario;
import com.bancoxyz.core.seguridad.Canal;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;

class AutenticacionTest extends PruebaDelCore {

    @Autowired
    private ServicioDeAutenticacion autenticacion;

    @Test
    @DisplayName("20 intentos simultaneos con clave erronea: el contador llega a 5 y bloquea (4 x 401 y 16 x 423)")
    void bloqueoDeUsuarioSinCarreras() throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(20);
        CountDownLatch largada = new CountDownLatch(1);
        List<Future<EstadoUsuario>> futuros = new ArrayList<>();
        for (int i = 0; i < 20; i++) {
            futuros.add(pool.submit(() -> {
                largada.await();
                return autenticacion.autenticarUsuario(Canal.WEB, "jane.smith", "incorrecta").estado();
            }));
        }
        largada.countDown();
        List<EstadoUsuario> estados = new ArrayList<>();
        for (Future<EstadoUsuario> f : futuros) {
            estados.add(f.get(30, TimeUnit.SECONDS));
        }
        pool.shutdownNow();

        Map<EstadoUsuario, Long> conteo = estados.stream().collect(Collectors.groupingBy(e -> e, Collectors.counting()));
        assertThat(conteo).containsEntry(EstadoUsuario.CREDENCIALES_INVALIDAS, 4L).containsEntry(EstadoUsuario.BLOQUEADO, 16L);
        assertThat(jdbc.sql("select intentos_fallidos from core.usuario where usuario = 'jane.smith'")
                .query(Integer.class).single()).isEqualTo(5);
        // Con el bloqueo vigente, ni la clave correcta entra.
        assertThat(autenticacion.autenticarUsuario(Canal.WEB, "jane.smith", "Cliente2026!").estado())
                .isEqualTo(EstadoUsuario.BLOQUEADO);
    }

    @Test
    @DisplayName("Un bloqueo vencido se libera antes de evaluar la clave")
    void bloqueoVencidoSeLibera() {
        reloj.fijar(LocalDateTime.of(2026, 9, 12, 10, 0));
        for (int i = 0; i < 5; i++) {
            autenticacion.autenticarUsuario(Canal.WEB, "diana.prince", "incorrecta");
        }
        assertThat(autenticacion.autenticarUsuario(Canal.WEB, "diana.prince", "Cliente2026!").estado())
                .isEqualTo(EstadoUsuario.BLOQUEADO);
        reloj.fijar(LocalDateTime.of(2026, 9, 12, 10, 16));
        assertThat(autenticacion.autenticarUsuario(Canal.WEB, "diana.prince", "Cliente2026!").estado())
                .isEqualTo(EstadoUsuario.AUTENTICADO);
    }

    @Test
    @DisplayName("Tres PIN incorrectos bloquean la tarjeta y despues ni el PIN correcto entra")
    void bloqueoDeTarjeta() {
        String pan = "4000000000001018";
        var primero = autenticacion.autenticarTarjeta(pan, "0000");
        var segundo = autenticacion.autenticarTarjeta(pan, "0000");
        assertThat(primero.estado()).isEqualTo(EstadoTarjeta.PIN_INCORRECTO);
        assertThat(primero.intentosRestantes()).isEqualTo(2);
        assertThat(segundo.intentosRestantes()).isEqualTo(1);
        assertThat(autenticacion.autenticarTarjeta(pan, "0000").estado()).isEqualTo(EstadoTarjeta.BLOQUEADA);
        assertThat(autenticacion.autenticarTarjeta(pan, "1234").estado()).isEqualTo(EstadoTarjeta.BLOQUEADA);
    }

    @Test
    @DisplayName("Traduccion HTTP: credenciales invalidas, usuario inexistente, ejecutivo por movil, tarjeta invalida y bloqueada")
    void erroresHttp() throws Exception {
        mvc.perform(post("/api/v1/autenticacion/usuarios").with(canal("web")).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"usuario\":\"diana.prince\",\"password\":\"mala\"}"))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.codigo").value("CREDENCIALES_INVALIDAS"));
        mvc.perform(post("/api/v1/autenticacion/usuarios").with(canal("movil")).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"usuario\":\"no.existe\",\"password\":\"x\"}"))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.codigo").value("CREDENCIALES_INVALIDAS"));
        mvc.perform(post("/api/v1/autenticacion/usuarios").with(canal("movil")).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"usuario\":\"ejecutivo\",\"password\":\"Ejecutivo2026!\"}"))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.codigo").value("ROL_NO_PERMITIDO_EN_CANAL"));
        mvc.perform(post("/api/v1/autenticacion/usuarios").with(canal("web")).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"usuario\":\"ejecutivo\",\"password\":\"Ejecutivo2026!\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.rol").value("EJECUTIVO"))
                .andExpect(jsonPath("$.clienteId").isEmpty());
        mvc.perform(post("/api/v1/autenticacion/usuarios").with(canal("web")).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"usuario\":\"\",\"password\":\"\"}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.codigo").value("SOLICITUD_INVALIDA"));
        mvc.perform(post("/api/v1/autenticacion/tarjetas").with(canal("cajero")).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"numeroTarjeta\":\"4111111111111111\",\"pin\":\"1234\"}"))
                .andExpect(status().isUnauthorized()).andExpect(jsonPath("$.codigo").value("TARJETA_INVALIDA"));
        for (int i = 0; i < 3; i++) {
            autenticacion.autenticarTarjeta("4000000000001018", "0000");
        }
        mvc.perform(post("/api/v1/autenticacion/tarjetas").with(canal("cajero")).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"numeroTarjeta\":\"4000000000001018\",\"pin\":\"1234\"}"))
                .andExpect(status().isLocked()).andExpect(jsonPath("$.codigo").value("TARJETA_BLOQUEADA"));
        for (int i = 0; i < 5; i++) {
            autenticacion.autenticarUsuario(Canal.WEB, "jane.smith", "incorrecta");
        }
        mvc.perform(post("/api/v1/autenticacion/usuarios").with(canal("web")).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"usuario\":\"jane.smith\",\"password\":\"Cliente2026!\"}"))
                .andExpect(status().isLocked()).andExpect(jsonPath("$.codigo").value("USUARIO_BLOQUEADO"));
    }
}
