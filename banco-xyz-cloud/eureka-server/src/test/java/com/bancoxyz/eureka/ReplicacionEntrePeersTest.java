package com.bancoxyz.eureka;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.ConfigurableApplicationContext;

/**
 * Dos nodos Eureka como en el ecosistema (perfiles peer1 y peer2, con puertos libres): una instancia registrada en un
 * nodo aparece en el otro. Si un nodo cae, el catalogo sigue completo en el que queda.
 */
class ReplicacionEntrePeersTest {

    private static ConfigurableApplicationContext nodo1;
    private static ConfigurableApplicationContext nodo2;
    private static int puerto1;
    private static int puerto2;
    private final HttpClient http = HttpClient.newHttpClient();

    @BeforeAll
    static void levantarDosNodos() throws IOException {
        puerto1 = libre();
        puerto2 = libre();
        nodo1 = nodo(puerto1, "127.0.0.1", "http://localhost:" + puerto2 + "/eureka/");
        nodo2 = nodo(puerto2, "localhost", "http://127.0.0.1:" + puerto1 + "/eureka/");
    }

    @AfterAll
    static void detener() {
        nodo2.close();
        nodo1.close();
    }

    @Test
    @DisplayName("Registro en el nodo 1, consulta en el nodo 2: la instancia llega replicada y UP")
    void replicaElRegistro() throws Exception {
        String instancia = """
                {"instance": {"instanceId": "prueba:transferencias-service:8082", "app": "TRANSFERENCIAS-SERVICE",
                  "hostName": "localhost", "ipAddr": "127.0.0.1", "vipAddress": "transferencias-service",
                  "secureVipAddress": "transferencias-service", "status": "UP",
                  "port": {"$": 8082, "@enabled": "false"}, "securePort": {"$": 8082, "@enabled": "true"},
                  "dataCenterInfo": {"@class": "com.netflix.appinfo.InstanceInfo$DefaultDataCenterInfo", "name": "MyOwn"}}}""";
        HttpResponse<String> registro = http.send(HttpRequest.newBuilder(URI.create("http://127.0.0.1:" + puerto1
                        + "/eureka/apps/TRANSFERENCIAS-SERVICE")).header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(instancia)).build(), HttpResponse.BodyHandlers.ofString());
        assertThat(registro.statusCode()).isEqualTo(204);

        String enNodo2 = "";
        for (int i = 0; i < 40 && !enNodo2.contains("\"status\":\"UP\""); i++) {
            Thread.sleep(250);
            enNodo2 = http.send(HttpRequest.newBuilder(URI.create("http://localhost:" + puerto2
                            + "/eureka/apps/TRANSFERENCIAS-SERVICE")).header("Accept", "application/json").GET().build(),
                    HttpResponse.BodyHandlers.ofString()).body();
        }
        assertThat(enNodo2).contains("prueba:transferencias-service:8082").contains("\"status\":\"UP\"");
    }

    private static ConfigurableApplicationContext nodo(int puerto, String nombre, String otroNodo) {
        return new SpringApplicationBuilder(EurekaServerApplication.class).run(
                "--server.port=" + puerto, "--eureka.instance.hostname=" + nombre,
                "--eureka.client.register-with-eureka=true", "--eureka.client.fetch-registry=true",
                "--eureka.client.service-url.defaultZone=" + otroNodo, "--spring.jmx.enabled=false");
    }

    private static int libre() throws IOException {
        try (ServerSocket socket = new ServerSocket(0)) {
            return socket.getLocalPort();
        }
    }
}
