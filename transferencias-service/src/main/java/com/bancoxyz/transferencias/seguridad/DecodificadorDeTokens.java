package com.bancoxyz.transferencias.seguridad;

import java.net.MalformedURLException;
import java.net.URI;
import java.time.Duration;
import java.util.List;

import javax.net.ssl.SSLSocketFactory;

import com.bancoxyz.transferencias.config.PropiedadesJwt;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.jwk.source.JWKSourceBuilder;
import com.nimbusds.jose.proc.JWSVerificationKeySelector;
import com.nimbusds.jose.proc.SecurityContext;
import com.nimbusds.jose.util.DefaultResourceRetriever;
import com.nimbusds.jwt.proc.DefaultJWTProcessor;
import org.springframework.boot.ssl.NoSuchSslBundleException;
import org.springframework.boot.ssl.SslBundles;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtIssuerValidator;
import org.springframework.security.oauth2.jwt.JwtTimestampValidator;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;

/**
 * Validacion de los JWT de banco-auth contra su JWK Set (claves publicas RSA), no contra un secreto compartido.
 *
 * <ul>
 *   <li>Firma RS256 con la clave cuyo {@code kid} trae el token. Un kid desconocido (banco-auth roto la clave) hace
 *       que se consulte de nuevo el JWK Set: la clave nueva se acepta sin reiniciar este servicio.</li>
 *   <li>La copia del JWK Set dura {@code banco.jwt.cache-jwks}: una clave retirada deja de aceptarse a lo sumo en ese
 *       tiempo.</li>
 *   <li>Emisor, audiencia y vencimiento sin tolerancia (el valor por defecto de Spring acepta 60 s de mas).</li>
 *   <li>El JWK Set se pide por HTTPS confiando solo en la CA del banco (bundle {@code cliente-core}).</li>
 * </ul>
 */
@Configuration
public class DecodificadorDeTokens {

    @Bean
    public JwtDecoder jwtDecoder(PropiedadesJwt jwt, SslBundles bundles) throws MalformedURLException {
        DefaultResourceRetriever lector = new DefaultResourceRetriever(2000, 2000, 51_200, true, socketsTls(bundles));
        JWKSource<SecurityContext> claves = JWKSourceBuilder.create(URI.create(jwt.jwkSetUri()).toURL(), lector)
                .cache(jwt.cacheJwks().toMillis(), 2000)
                // Sin refresco anticipado: la copia vence justo a los cache-jwks y la clave retirada deja de valer.
                .refreshAheadCache(false)
                .rateLimited(false)
                .build();
        DefaultJWTProcessor<SecurityContext> procesador = new DefaultJWTProcessor<>();
        procesador.setJWSKeySelector(new JWSVerificationKeySelector<>(JWSAlgorithm.RS256, claves));
        // Las reglas de claims las aplica Spring abajo; Nimbus solo verifica la firma.
        procesador.setJWTClaimsSetVerifier((claims, contexto) -> { });
        NimbusJwtDecoder decodificador = new NimbusJwtDecoder(procesador);
        decodificador.setJwtValidator(new DelegatingOAuth2TokenValidator<>(new JwtTimestampValidator(Duration.ZERO),
                new JwtIssuerValidator(jwt.emisor()), audiencia(jwt.audiencia())));
        return decodificador;
    }

    private static OAuth2TokenValidator<Jwt> audiencia(String esperada) {
        return token -> {
            List<String> audiencias = token.getAudience();
            return audiencias != null && audiencias.contains(esperada) ? OAuth2TokenValidatorResult.success()
                    : OAuth2TokenValidatorResult.failure(new OAuth2Error("invalid_token", "Token para otra audiencia", null));
        };
    }

    /** Sockets TLS con la CA del banco; sin el perfil tls (pruebas) se usan los del JDK. */
    private static SSLSocketFactory socketsTls(SslBundles bundles) {
        try {
            return bundles.getBundle("cliente-core").createSslContext().getSocketFactory();
        } catch (NoSuchSslBundleException sinPerfilTls) {
            return (SSLSocketFactory) SSLSocketFactory.getDefault();
        }
    }
}
