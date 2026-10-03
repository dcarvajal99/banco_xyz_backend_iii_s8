package com.bancoxyz.core.autenticacion;

import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.util.HexFormat;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import com.bancoxyz.core.config.PropiedadesCore;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;

/**
 * Hash de claves de usuario y PIN (BCrypt) y huella del numero de tarjeta (HMAC-SHA256 con pepper).
 *
 * <p>No es un bean {@code PasswordEncoder} a proposito: el unico de ese tipo es el de las credenciales
 * de servicio (costo 4), y dos beans del mismo tipo confundirian a la autoconfiguracion de Spring Security.</p>
 *
 * <p>El PAN se guarda como HMAC y no como SHA-256 simple: un numero de 16 digitos con prefijo conocido
 * tiene poca entropia y un hash sin secreto se revierte por fuerza bruta en minutos.</p>
 */
@Component
public class CodificadorDeSecretos {

    private final BCryptPasswordEncoder bcrypt;
    private final byte[] pepper;
    private final String hashFicticio;

    public CodificadorDeSecretos(PropiedadesCore propiedades) {
        this.bcrypt = new BCryptPasswordEncoder(propiedades.seguridad().bcryptFuerza());
        this.pepper = propiedades.seguridad().pepperTarjetas().getBytes(StandardCharsets.UTF_8);
        this.hashFicticio = bcrypt.encode("valor-que-nunca-coincide");
    }

    public String cifrar(String secreto) {
        return bcrypt.encode(secreto);
    }

    public boolean coincide(String secreto, String hash) {
        return secreto != null && hash != null && bcrypt.matches(secreto, hash);
    }

    /** Gasta lo mismo que una verificacion real para no revelar por tiempo que el usuario o la tarjeta no existen. */
    public void verificarContraFicticio(String secreto) {
        bcrypt.matches(secreto == null ? "" : secreto, hashFicticio);
    }

    public String huellaDeTarjeta(String numero) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(pepper, "HmacSHA256"));
            return HexFormat.of().formatHex(mac.doFinal(numero.getBytes(StandardCharsets.UTF_8)));
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException("HmacSHA256 no disponible", e);
        }
    }
}
