package com.bancoxyz.eureka;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;

/**
 * El servidor Eureka levantado de verdad: acepta el registro de una instancia HTTPS y la publica en el catalogo al
 * instante (sin la cache de solo lectura), que es lo que necesitan los BFF para encontrar al core.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class CatalogoTest {

    @Autowired
    private TestRestTemplate http;

    @Test
    @DisplayName("Una instancia HTTPS registrada aparece UP en el catalogo en la consulta siguiente")
    void registroVisibleAlInstante() {
        String instancia = """
                {"instance": {"instanceId": "prueba:banco-core-api:8080", "app": "BANCO-CORE-API", "hostName": "localhost",
                  "ipAddr": "127.0.0.1", "vipAddress": "banco-core-api", "secureVipAddress": "banco-core-api", "status": "UP",
                  "port": {"$": 8080, "@enabled": "false"}, "securePort": {"$": 8080, "@enabled": "true"},
                  "healthCheckUrl": "http://127.0.0.1:9080/actuator/health",
                  "dataCenterInfo": {"@class": "com.netflix.appinfo.InstanceInfo$DefaultDataCenterInfo", "name": "MyOwn"}}}""";
        ResponseEntity<Void> registro = http.exchange("/eureka/apps/BANCO-CORE-API", HttpMethod.POST,
                new HttpEntity<>(instancia, json()), Void.class);
        assertThat(registro.getStatusCode()).isEqualTo(HttpStatus.NO_CONTENT);

        ResponseEntity<String> catalogo = http.exchange("/eureka/apps/BANCO-CORE-API", HttpMethod.GET,
                new HttpEntity<>(json()), String.class);
        assertThat(catalogo.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(catalogo.getBody()).contains("\"status\":\"UP\"").contains("\"securePort\":{\"$\":8080,\"@enabled\":\"true\"}");
    }

    private static HttpHeaders json() {
        HttpHeaders cabeceras = new HttpHeaders();
        cabeceras.setContentType(MediaType.APPLICATION_JSON);
        cabeceras.setAccept(List.of(MediaType.APPLICATION_JSON));
        return cabeceras;
    }
}
