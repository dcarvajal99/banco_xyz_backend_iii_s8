package com.bancoxyz.config;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

/**
 * El Config Server sobre el repositorio real (banco-xyz-cloud/configuracion/), sin TLS (perfil native solo): exige
 * credenciales, entrega a cada servicio su archivo y el comun, y el repositorio no contiene secretos.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "spring.profiles.active=native", "management.server.port=0",
        "spring.cloud.config.server.native.search-locations=file:../configuracion"})
class ConfiguracionCentralTest {

    @Autowired
    private TestRestTemplate http;

    @Test
    @DisplayName("Sin usuario y clave, el Config Server responde 401 y no entrega nada")
    void exigeCredenciales() {
        ResponseEntity<String> respuesta = http.getForEntity("/transferencias-service/default", String.class);
        assertThat(respuesta.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        assertThat(http.withBasicAuth("configuracion", "clave-equivocada")
                .getForEntity("/transferencias-service/default", String.class).getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    @DisplayName("transferencias-service recibe su archivo y el comun: el core por nombre, Eureka con dos nodos, Kafka y JWT")
    void configuracionDeTransferencias() {
        JsonNode entorno = entorno("transferencias-service");
        assertThat(fuentes(entorno)).containsExactly("file:../configuracion/transferencias-service.properties",
                "file:../configuracion/application.properties");
        assertThat(propiedades(entorno))
                .containsEntry("banco.core.url", "https://banco-core-api/api/v1")
                .containsEntry("banco.core.descubrimiento", "true")
                .containsEntry("eureka.client.service-url.defaultZone", "http://127.0.0.1:8761/eureka/,http://localhost:8762/eureka/")
                .containsEntry("spring.kafka.bootstrap-servers", "localhost:9092")
                .containsEntry("banco.jwt.jwk-set-uri", "https://localhost:8081/oauth2/jwks")
                .containsEntry("banco.jwt.token-uri", "https://localhost:8081/oauth2/token");
    }

    @Test
    @DisplayName("Resilience4j por entorno: la misma politica compartida, con los valores de la nube cuando el perfil es nube")
    void politicasPorEntorno() {
        Map<String, String> local = propiedades(entorno("transferencias-service", "default"));
        Map<String, String> nube = propiedades(entorno("transferencias-service", "nube"));
        String circuito = "resilience4j.circuitbreaker.configs.http-interno.";
        assertThat(local).containsEntry("resilience4j.circuitbreaker.instances.core.base-config", "http-interno")
                .containsEntry("resilience4j.circuitbreaker.instances.kafka.base-config", "publicacion-kafka")
                .containsEntry(circuito + "minimum-number-of-calls", "3")
                .containsEntry(circuito + "wait-duration-in-open-state", "10s")
                .doesNotContainKey(circuito + "slow-call-duration-threshold");
        assertThat(nube).containsEntry("resilience4j.circuitbreaker.instances.core.base-config", "http-interno")
                .containsEntry(circuito + "minimum-number-of-calls", "5")
                .containsEntry(circuito + "wait-duration-in-open-state", "15s")
                .containsEntry(circuito + "slow-call-duration-threshold", "2s")
                .containsEntry("resilience4j.retry.configs.http-interno.enable-exponential-backoff", "true")
                .containsEntry("spring.datasource.url", "jdbc:postgresql://db:5432/banco_xyz")
                .containsEntry("eureka.client.service-url.defaultZone", "http://eureka-1:8761/eureka/,http://eureka-2:8762/eureka/");
    }

    @Test
    @DisplayName("banco-auth y transferencias-service comparten la politica http-interno; cada uno ignora su propia excepcion de negocio")
    void politicaCompartida() {
        Map<String, String> auth = propiedades(entorno("banco-auth", "nube"));
        Map<String, String> transferencias = propiedades(entorno("transferencias-service", "nube"));
        auth.keySet().stream().filter(clave -> clave.contains(".configs.http-interno."))
                .forEach(clave -> assertThat(transferencias).containsEntry(clave, auth.get(clave)));
        assertThat(auth.get("resilience4j.circuitbreaker.instances.core.ignore-exceptions")).contains("com.bancoxyz.auth.core");
        assertThat(transferencias.get("resilience4j.circuitbreaker.instances.core.ignore-exceptions")).contains("com.bancoxyz.transferencias.core");
    }

    @Test
    @DisplayName("banco-auth recibe el registro OAuth2 de GitHub y sus vinculos; el client-id es un marcador y no hay client-secret")
    void registroDeGitHub() {
        String github = "spring.security.oauth2.client.registration.github.";
        assertThat(propiedades(entorno("banco-auth", "nube")))
                .containsEntry(github + "client-id", "${BANCO_GITHUB_CLIENT_ID:sin-configurar}")
                .containsEntry(github + "scope", "read:user,user:email")
                .containsEntry(github + "redirect-uri", "{baseUrl}/login/oauth2/code/{registrationId}")
                .containsEntry("banco.auth.github.vinculos.113071563", "diana.prince")
                .doesNotContainKey(github + "client-secret");
    }

    @Test
    @DisplayName("antifraude-service recibe sus reglas de riesgo desde la configuracion central")
    void reglasDeAntifraude() {
        assertThat(propiedades(entorno("antifraude-service")))
                .containsEntry("banco.antifraude.monto-maximo", "5000")
                .containsEntry("banco.antifraude.cuentas-en-observacion", "104")
                .containsEntry("banco.antifraude.demora-ms", "200");
    }

    @ParameterizedTest(name = "{0}")
    @ValueSource(strings = {"banco-core-api", "banco-auth", "transferencias-service", "antifraude-service", "notificaciones-service"})
    @DisplayName("Ningun servicio recibe claves ni secretos desde la configuracion central")
    void sinSecretos(String servicio) {
        assertThat(propiedades(entorno(servicio)).keySet())
                .noneMatch(clave -> clave.matches("(?i).*(password|clave|secret|secreto|pepper).*"));
    }

    private JsonNode entorno(String servicio) {
        return entorno(servicio, "default");
    }

    private JsonNode entorno(String servicio, String perfil) {
        ResponseEntity<JsonNode> respuesta = http.withBasicAuth("configuracion", "config-secreto-dev")
                .getForEntity("/" + servicio + "/" + perfil, JsonNode.class);
        assertThat(respuesta.getStatusCode()).isEqualTo(HttpStatus.OK);
        return respuesta.getBody();
    }

    private static List<String> fuentes(JsonNode entorno) {
        return entorno.get("propertySources").findValuesAsText("name");
    }

    /** Propiedades efectivas: la fuente especifica gana sobre la comun, como en el cliente. */
    private static Map<String, String> propiedades(JsonNode entorno) {
        Map<String, String> resultado = new HashMap<>();
        List<JsonNode> fuentes = entorno.get("propertySources").findValues("source");
        for (int i = fuentes.size() - 1; i >= 0; i--) {
            fuentes.get(i).properties().forEach(par -> resultado.put(par.getKey(), par.getValue().asText()));
        }
        return resultado;
    }
}
