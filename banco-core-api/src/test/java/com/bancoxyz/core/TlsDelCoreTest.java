package com.bancoxyz.core;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.cert.X509Certificate;
import java.time.Duration;
import java.util.Base64;

import javax.net.ssl.SSLParameters;
import javax.net.ssl.SSLSession;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalManagementPort;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.jdbc.Sql;

/**
 * El core levantado de verdad con el perfil tls (el mismo application-tls.properties de produccion) sobre una PKI de
 * prueba: handshake real, certificado de cliente real y encabezados tal como salen por el socket.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = "management.server.port=0")
@ActiveProfiles({"prueba", "tls"})
@Import(ConfiguracionDePrueba.class)
@Sql(scripts = {"/sql/esquema-batch.sql", "/sql/datos-cierre.sql"}, executionPhase = Sql.ExecutionPhase.BEFORE_TEST_CLASS)
class TlsDelCoreTest {

    @LocalServerPort
    private int puerto;

    @LocalManagementPort
    private int puertoDeOperacion;

    @DynamicPropertySource
    static void certificados(DynamicPropertyRegistry registro) {
        registro.add("banco.certificados", () -> PkiDePrueba.raiz().toString());
    }

    @Test
    @DisplayName("BFF con certificado y clave: TLS 1.3, HTTP/2, certificado del core y encabezados de seguridad")
    void dosCredenciales() throws Exception {
        HttpResponse<String> respuesta = llamar(cliente("bff-web", null), "bff-web", "web-secreto-dev");

        assertThat(respuesta.statusCode()).isEqualTo(200);
        assertThat(respuesta.version()).isEqualTo(HttpClient.Version.HTTP_2);
        SSLSession sesion = respuesta.sslSession().orElseThrow();
        assertThat(sesion.getProtocol()).isEqualTo("TLSv1.3");
        assertThat(((X509Certificate) sesion.getPeerCertificates()[0]).getSubjectX500Principal().getName())
                .startsWith("CN=banco-core-api");
        assertThat(respuesta.headers().firstValue("strict-transport-security").orElseThrow())
                .contains("max-age=31536000", "includeSubDomains");
        assertThat(respuesta.headers().firstValue("content-security-policy")).hasValue("default-src 'none'; frame-ancestors 'none'");
        assertThat(respuesta.headers().firstValue("referrer-policy")).hasValue("no-referrer");
    }

    @Test
    @DisplayName("Sin certificado de cliente la clave correcta no basta: 401 CERTIFICADO_REQUERIDO")
    void sinCertificado() throws Exception {
        HttpResponse<String> respuesta = llamar(cliente(null, null), "bff-web", "web-secreto-dev");
        assertThat(respuesta.statusCode()).isEqualTo(401);
        assertThat(respuesta.body()).contains("\"codigo\":\"CERTIFICADO_REQUERIDO\"");
    }

    @Test
    @DisplayName("Certificado de bff-movil con la clave de bff-web: 403 CERTIFICADO_NO_CORRESPONDE")
    void certificadoDeOtroCanal() throws Exception {
        HttpResponse<String> respuesta = llamar(cliente("bff-movil", null), "bff-web", "web-secreto-dev");
        assertThat(respuesta.statusCode()).isEqualTo(403);
        assertThat(respuesta.body()).contains("\"codigo\":\"CERTIFICADO_NO_CORRESPONDE\"");
    }

    @Test
    @DisplayName("Certificado con el nombre bff-web pero de una CA ajena: la conexion TLS no se establece")
    void certificadoNoConfiable() {
        assertThatThrownBy(() -> llamar(cliente("bff-web-intruso", null), "bff-web", "web-secreto-dev"))
                .isInstanceOf(IOException.class);
    }

    @Test
    @DisplayName("TLS 1.2 con suite AEAD se acepta; una suite CBC queda fuera de la lista del servidor")
    void suitesPermitidas() throws Exception {
        SSLParameters aead = new SSLParameters(new String[] {"TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"}, new String[] {"TLSv1.2"});
        HttpResponse<String> respuesta = llamar(cliente("bff-web", aead), "bff-web", "web-secreto-dev");
        assertThat(respuesta.statusCode()).isEqualTo(200);
        assertThat(respuesta.sslSession().orElseThrow().getProtocol()).isEqualTo("TLSv1.2");

        SSLParameters cbc = new SSLParameters(new String[] {"TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256"}, new String[] {"TLSv1.2"});
        assertThatThrownBy(() -> llamar(cliente("bff-web", cbc), "bff-web", "web-secreto-dev")).isInstanceOf(IOException.class);
    }

    @Test
    @DisplayName("HTTP plano al puerto HTTPS: 400; health solo en el puerto de operacion (loopback, sin TLS)")
    void httpPlanoYOperacion() throws Exception {
        HttpClient plano = HttpClient.newBuilder().version(HttpClient.Version.HTTP_1_1).build();
        HttpResponse<String> alPuertoSeguro = plano.send(HttpRequest.newBuilder(
                URI.create("http://localhost:" + puerto + "/api/v1/cierres/vigentes")).build(), HttpResponse.BodyHandlers.ofString());
        assertThat(alPuertoSeguro.statusCode()).isEqualTo(400);

        HttpResponse<String> salud = plano.send(HttpRequest.newBuilder(
                URI.create("http://127.0.0.1:" + puertoDeOperacion + "/actuator/health")).build(), HttpResponse.BodyHandlers.ofString());
        assertThat(salud.statusCode()).isEqualTo(200);
        assertThat(salud.body()).contains("UP");
    }

    private HttpClient cliente(String identidad, SSLParameters parametros) {
        HttpClient.Builder constructor = HttpClient.newBuilder().sslContext(PkiDePrueba.contexto(identidad))
                .connectTimeout(Duration.ofSeconds(5));
        if (parametros != null) {
            constructor.sslParameters(parametros);
        }
        return constructor.build();
    }

    private HttpResponse<String> llamar(HttpClient cliente, String usuario, String clave) throws IOException, InterruptedException {
        String basic = Base64.getEncoder().encodeToString((usuario + ":" + clave).getBytes(StandardCharsets.UTF_8));
        return cliente.send(HttpRequest.newBuilder(URI.create("https://localhost:" + puerto + "/api/v1/cierres/vigentes"))
                .header("Authorization", "Basic " + basic).timeout(Duration.ofSeconds(10)).build(), HttpResponse.BodyHandlers.ofString());
    }
}
