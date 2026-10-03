package com.bancoxyz.auth.claves;

import java.time.Clock;
import java.time.Instant;
import java.time.format.DateTimeFormatter;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;

import com.bancoxyz.auth.config.PropiedadesAuth;
import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.jwk.JWK;
import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.KeyUse;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.gen.RSAKeyGenerator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Claves de firma de banco-auth, con rotacion.
 *
 * <ul>
 *   <li>Siempre hay una clave activa: firma los tokens nuevos.</li>
 *   <li>{@link #rotar()} genera una nueva activa. La anterior deja de firmar pero se sigue publicando en el JWK Set
 *       hasta que vence el ultimo token que pudo firmar (vida del token): nadie queda con un token valido rechazado.</li>
 *   <li>Pasado ese momento se retira sola ({@link #retirarVencidas()}); {@link #retirar(String)} la saca antes (clave
 *       comprometida): sus tokens dejan de aceptarse cuando los servicios renuevan su copia del JWK Set.</li>
 * </ul>
 *
 * <p>Las claves privadas viven solo en memoria: no estan en propiedades ni en archivos. Si banco-auth se reinicia, genera
 * claves nuevas y los tokens anteriores dejan de valer (duran minutos).</p>
 */
@Component
public class AlmacenDeClaves {

    private static final Logger log = LoggerFactory.getLogger(AlmacenDeClaves.class);
    private static final DateTimeFormatter FORMATO_KID = DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss").withZone(ZoneOffset.UTC);

    private final List<ClaveDeFirma> claves = new CopyOnWriteArrayList<>();
    private final PropiedadesAuth propiedades;
    private final Clock reloj;

    public AlmacenDeClaves(PropiedadesAuth propiedades, Clock reloj) {
        this.propiedades = propiedades;
        this.reloj = reloj;
        claves.add(nueva());
    }

    public ClaveDeFirma activa() {
        return claves.stream().filter(ClaveDeFirma::activa).findFirst().orElseThrow();
    }

    /** Claves publicas vigentes: la activa y las que siguen en periodo de gracia. */
    public JWKSet conjuntoPublico() {
        List<JWK> publicas = new ArrayList<>();
        for (ClaveDeFirma clave : claves) {
            publicas.add(clave.clave().toPublicJWK());
        }
        return new JWKSet(publicas);
    }

    /**
     * Conjunto con las claves privadas: lo usa el firmador del servidor de autorizacion, que elige la clave por el kid del
     * encabezado. El endpoint {@code /oauth2/jwks} recibe el mismo conjunto y publica solo la parte publica.
     */
    public JWKSet conjuntoDeFirma() {
        return new JWKSet(claves.stream().map(c -> (JWK) c.clave()).toList());
    }

    public List<ClaveDeFirma> todas() {
        return List.copyOf(claves);
    }

    public synchronized ClaveDeFirma rotar() {
        Instant ahora = reloj.instant();
        ClaveDeFirma anterior = activa();
        ClaveDeFirma siguiente = nueva();
        claves.replaceAll(c -> c == anterior ? c.retirandoseEn(ahora.plus(propiedades.duracionToken())) : c);
        claves.add(0, siguiente);
        log.info("Rotacion de claves: firma {}; {} se sigue publicando hasta {}", siguiente.kid(), anterior.kid(),
                ahora.plus(propiedades.duracionToken()));
        return siguiente;
    }

    /** Saca del JWK Set una clave que ya no firma. La activa no se puede retirar sin rotar antes. */
    public synchronized boolean retirar(String kid) {
        boolean retirada = claves.removeIf(c -> c.kid().equals(kid) && !c.activa());
        if (retirada) {
            log.info("Clave {} retirada del JWK Set", kid);
        }
        return retirada;
    }

    @Scheduled(fixedDelay = 10_000)
    public void retirarVencidas() {
        Instant ahora = reloj.instant();
        claves.removeIf(c -> {
            boolean vencida = !c.activa() && !c.retirarEn().isAfter(ahora);
            if (vencida) {
                log.info("Clave {} retirada: vencio su periodo de gracia", c.kid());
            }
            return vencida;
        });
    }

    private ClaveDeFirma nueva() {
        Instant ahora = reloj.instant();
        String kid = "banco-auth-" + FORMATO_KID.format(ahora) + "-" + HexFormat.of().toHexDigits(UUID.randomUUID()
                .getLeastSignificantBits()).substring(0, 6);
        try {
            RSAKey clave = new RSAKeyGenerator(2048).keyID(kid).keyUse(KeyUse.SIGNATURE).algorithm(JWSAlgorithm.RS256)
                    .issueTime(java.util.Date.from(ahora)).generate();
            return new ClaveDeFirma(clave, ahora, null);
        } catch (JOSEException e) {
            throw new IllegalStateException("No se pudo generar la clave RSA", e);
        }
    }
}
