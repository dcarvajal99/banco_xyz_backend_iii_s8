package com.bancoxyz.auth;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;

import com.bancoxyz.auth.claves.AlmacenDeClaves;
import com.bancoxyz.auth.claves.ClaveDeFirma;
import com.bancoxyz.auth.config.PropiedadesAuth;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/** Rotacion sin Spring: la clave nueva firma, la anterior queda publicada durante la vida del token y luego se retira. */
class RotacionDeClavesTest {

    private Instant ahora = Instant.parse("2026-09-24T12:00:00Z");
    private final Clock reloj = new Clock() {
        @Override
        public java.time.ZoneId getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(java.time.ZoneId zona) {
            return this;
        }

        @Override
        public Instant instant() {
            return ahora;
        }
    };
    private final AlmacenDeClaves almacen = new AlmacenDeClaves(
            new PropiedadesAuth("https://localhost:8081", "banco-xyz", Duration.ofMinutes(5), Duration.ofMinutes(60), null, null, null),
            reloj);

    @Test
    @DisplayName("Al rotar cambia la clave activa y el JWK Set publica las dos; el conjunto de firma trae las privadas")
    void rotarCambiaLaActiva() {
        String inicial = almacen.activa().kid();

        ClaveDeFirma nueva = almacen.rotar();

        assertThat(almacen.activa().kid()).isEqualTo(nueva.kid()).isNotEqualTo(inicial);
        assertThat(almacen.conjuntoPublico().getKeys()).extracting(k -> k.getKeyID()).containsExactlyInAnyOrder(inicial, nueva.kid());
        assertThat(almacen.conjuntoPublico().getKeys()).noneMatch(k -> k.isPrivate());
        assertThat(almacen.conjuntoDeFirma().getKeys()).allMatch(k -> k.isPrivate());
    }

    @Test
    @DisplayName("La clave anterior se retira sola cuando vence su periodo de gracia (la vida del token)")
    void retiroAutomatico() {
        String anterior = almacen.activa().kid();
        almacen.rotar();

        ahora = ahora.plus(Duration.ofMinutes(4));
        almacen.retirarVencidas();
        assertThat(almacen.conjuntoPublico().getKeyByKeyId(anterior)).isNotNull();

        ahora = ahora.plus(Duration.ofMinutes(2));
        almacen.retirarVencidas();
        assertThat(almacen.conjuntoPublico().getKeyByKeyId(anterior)).isNull();
        assertThat(almacen.conjuntoPublico().getKeys()).hasSize(1);
    }

    @Test
    @DisplayName("Retiro manual (clave comprometida): la anterior sale de inmediato; la activa no se puede retirar")
    void retiroManual() {
        String anterior = almacen.activa().kid();
        ClaveDeFirma nueva = almacen.rotar();

        assertThat(almacen.retirar(nueva.kid())).isFalse();
        assertThat(almacen.retirar(anterior)).isTrue();
        assertThat(almacen.conjuntoPublico().getKeys()).extracting(k -> k.getKeyID()).containsExactly(nueva.kid());
    }
}
