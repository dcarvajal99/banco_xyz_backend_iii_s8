package com.bancoxyz.core;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.httpBasic;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.x509;

import com.bancoxyz.core.cierre.SincronizadorDeCierre;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;

/**
 * Base de las pruebas de integracion del core: H2 en modo PostgreSQL, Flyway real, tablas del batch
 * con un cierre de ejemplo y el esquema core re-sincronizado antes de cada prueba.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("prueba")
@Import(ConfiguracionDePrueba.class)
@Sql(scripts = {"/sql/esquema-batch.sql", "/sql/datos-cierre.sql"},
        executionPhase = Sql.ExecutionPhase.BEFORE_TEST_CLASS)
public abstract class PruebaDelCore {

    @Autowired
    protected MockMvc mvc;

    @Autowired
    protected JdbcClient jdbc;

    @Autowired
    protected SincronizadorDeCierre sincronizador;

    @Autowired
    protected RelojAjustable reloj;

    @Autowired
    protected ObjectMapper json;

    @BeforeEach
    void reiniciarEsquemaCore() {
        reloj.volverAlPresente();
        jdbc.sql("delete from core.operacion").update();
        jdbc.sql("delete from core.reserva").update();
        jdbc.sql("delete from core.evento_procesado").update();
        jdbc.sql("delete from core.outbox").update();
        jdbc.sql("delete from core.tarjeta").update();
        jdbc.sql("delete from core.usuario").update();
        jdbc.sql("delete from core.cuenta").update();
        jdbc.sql("delete from core.cliente").update();
        sincronizador.sincronizar();
    }

    /** Las dos credenciales del BFF: clave Basic y el certificado de cliente de su conexion mTLS. */
    protected static RequestPostProcessor canal(String canal) {
        RequestPostProcessor credencial = httpBasic("bff-" + canal, canal + "-secreto-dev");
        RequestPostProcessor certificado = certificado(canal);
        return solicitud -> certificado.postProcessRequest(credencial.postProcessRequest(solicitud));
    }

    /** Credenciales de un servicio con clave Basic (banco-auth): la clave y el certificado de su conexion mTLS. */
    protected static RequestPostProcessor servicio(String usuario, String clave) {
        RequestPostProcessor credencial = httpBasic(usuario, clave);
        RequestPostProcessor certificado = x509(PkiDePrueba.certificado(usuario));
        return solicitud -> certificado.postProcessRequest(credencial.postProcessRequest(solicitud));
    }

    /**
     * Credenciales de un servicio OAuth (semana 8): un token client_credentials de banco-auth ya validado (sub = id del
     * cliente, con sus scopes) y el certificado de su conexion mTLS, cuyo CN es el mismo id.
     */
    protected static RequestPostProcessor tokenDeServicio(String cliente, String certificadoDe, String... scopes) {
        RequestPostProcessor token = jwt().jwt(j -> j.subject(cliente).claim("scope", java.util.List.of(scopes)))
                .authorities(new com.bancoxyz.core.seguridad.TokensDeServicio());
        RequestPostProcessor certificado = x509(PkiDePrueba.certificado(certificadoDe));
        return solicitud -> certificado.postProcessRequest(token.postProcessRequest(solicitud));
    }

    /** El certificado que Tomcat deja en la solicitud despues del handshake mTLS de ese BFF. */
    protected static RequestPostProcessor certificado(String canal) {
        return x509(PkiDePrueba.certificado("bff-" + canal));
    }

    protected long usuarioId(String usuario) {
        return jdbc.sql("select id from core.usuario where usuario = :u").param("u", usuario).query(Long.class).single();
    }

    protected long clienteId(String nombre) {
        return jdbc.sql("select id from core.cliente where nombre = :n").param("n", nombre).query(Long.class).single();
    }

    protected long tarjetaDeCuenta(long cuentaId) {
        return jdbc.sql("select id from core.tarjeta where cuenta_id = :c").param("c", cuentaId).query(Long.class).single();
    }

    protected String saldo(long cuentaId) {
        return jdbc.sql("select saldo_disponible from core.cuenta where id = :c").param("c", cuentaId)
                .query(java.math.BigDecimal.class).single().stripTrailingZeros().toPlainString();
    }
}
