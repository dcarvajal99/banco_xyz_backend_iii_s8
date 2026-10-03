package com.bancoxyz.auth.claves;

import java.time.Instant;

import com.nimbusds.jose.jwk.RSAKey;

/**
 * Un par de claves RSA con su identificador ({@code kid}).
 *
 * @param clave       par RSA (la privada solo existe en memoria de banco-auth)
 * @param creadaEn    cuando se genero
 * @param retirarEn   null mientras firma; al rotar, el momento en que deja de publicarse (cuando vence el ultimo token
 *                    que pudo firmar)
 */
public record ClaveDeFirma(RSAKey clave, Instant creadaEn, Instant retirarEn) {

    public String kid() {
        return clave.getKeyID();
    }

    public boolean activa() {
        return retirarEn == null;
    }

    ClaveDeFirma retirandoseEn(Instant momento) {
        return new ClaveDeFirma(clave, creadaEn, momento);
    }
}
