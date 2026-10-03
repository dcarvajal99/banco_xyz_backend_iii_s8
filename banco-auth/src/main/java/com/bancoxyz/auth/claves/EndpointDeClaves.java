package com.bancoxyz.auth.claves;

import java.util.List;
import java.util.Map;

import org.springframework.boot.actuate.endpoint.annotation.DeleteOperation;
import org.springframework.boot.actuate.endpoint.annotation.Endpoint;
import org.springframework.boot.actuate.endpoint.annotation.ReadOperation;
import org.springframework.boot.actuate.endpoint.annotation.Selector;
import org.springframework.boot.actuate.endpoint.annotation.WriteOperation;
import org.springframework.stereotype.Component;

/**
 * Administracion de claves en el puerto de operacion: {@code GET /actuator/claves} las lista, {@code POST /actuator/claves}
 * rota y {@code DELETE /actuator/claves/{kid}} retira una que ya no firma. Las tres exigen un access token con el scope
 * {@code claves.administrar} (cliente operacion-banco); ver {@code ServidorDeAutorizacion#cadenaDeOperacion}.
 */
@Component
@Endpoint(id = "claves")
public class EndpointDeClaves {

    private final AlmacenDeClaves almacen;

    public EndpointDeClaves(AlmacenDeClaves almacen) {
        this.almacen = almacen;
    }

    @ReadOperation
    public List<Map<String, Object>> listar() {
        return almacen.todas().stream().map(c -> Map.<String, Object>of(
                "kid", c.kid(),
                "estado", c.activa() ? "ACTIVA" : "EN_GRACIA",
                "creadaEn", c.creadaEn().toString(),
                "retirarEn", c.retirarEn() == null ? "-" : c.retirarEn().toString())).toList();
    }

    @WriteOperation
    public Map<String, Object> rotar() {
        ClaveDeFirma nueva = almacen.rotar();
        return Map.of("activa", nueva.kid(), "claves", listar());
    }

    @DeleteOperation
    public Map<String, Object> retirar(@Selector String kid) {
        return Map.of("kid", kid, "retirada", almacen.retirar(kid));
    }
}
