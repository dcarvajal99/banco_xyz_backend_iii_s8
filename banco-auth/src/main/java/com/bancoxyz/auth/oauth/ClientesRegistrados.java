package com.bancoxyz.auth.oauth;

import java.util.UUID;

import com.bancoxyz.auth.config.PropiedadesAuth;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.factory.PasswordEncoderFactories;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.core.AuthorizationGrantType;
import org.springframework.security.oauth2.core.ClientAuthenticationMethod;
import org.springframework.security.oauth2.core.oidc.OidcScopes;
import org.springframework.security.oauth2.server.authorization.client.InMemoryRegisteredClientRepository;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClient;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClientRepository;
import org.springframework.security.oauth2.server.authorization.settings.ClientSettings;
import org.springframework.security.oauth2.server.authorization.settings.TokenSettings;

/**
 * Los clientes OAuth del banco y lo que cada uno puede pedir.
 *
 * <ul>
 *   <li><b>banca-web</b>: la aplicacion de banca en linea (un backend web, cliente confidencial). Solo authorization_code
 *       con PKCE obligatorio: el usuario escribe su clave en banco-auth, nunca en la aplicacion. Recibe refresh token
 *       que rota en cada uso (el anterior queda invalido).</li>
 *   <li><b>transferencias-service</b>: un servicio, sin usuario. Solo client_credentials y solo el scope
 *       {@code core.cuentas.leer}: con ese token consulta una cuenta en el core.</li>
 *   <li><b>operacion-banco</b>: el equipo de operacion. Solo client_credentials y solo {@code claves.administrar}: con
 *       ese token rota o retira las claves de firma en {@code /actuator/claves}. Ningun otro cliente puede pedirlo.</li>
 * </ul>
 *
 * <p>Los secretos llegan por variable de entorno y se guardan con bcrypt: en memoria no queda el secreto en claro.</p>
 */
@Configuration(proxyBeanMethods = false)
public class ClientesRegistrados {

    @Bean
    public PasswordEncoder codificador() {
        return PasswordEncoderFactories.createDelegatingPasswordEncoder();
    }

    @Bean
    public RegisteredClientRepository clientes(PropiedadesAuth propiedades, PasswordEncoder codificador) {
        PropiedadesAuth.Cliente web = propiedades.bancaWeb();
        RegisteredClient bancaWeb = RegisteredClient.withId(UUID.nameUUIDFromBytes(web.id().getBytes()).toString())
                .clientId(web.id())
                .clientSecret(codificador.encode(web.secreto()))
                .clientName("Banca en linea del Banco XYZ")
                .clientAuthenticationMethod(ClientAuthenticationMethod.CLIENT_SECRET_BASIC)
                .authorizationGrantType(AuthorizationGrantType.AUTHORIZATION_CODE)
                .authorizationGrantType(AuthorizationGrantType.REFRESH_TOKEN)
                .redirectUris(uris -> uris.addAll(web.redirectUris()))
                .scope(OidcScopes.OPENID)
                .scope(OidcScopes.PROFILE)
                .scope(Alcances.TRANSFERENCIAS_ESCRIBIR)
                .scope(Alcances.TRANSFERENCIAS_LEER)
                .scope(Alcances.NOTIFICACIONES_LEER)
                .clientSettings(ClientSettings.builder().requireProofKey(true).requireAuthorizationConsent(false).build())
                .tokenSettings(TokenSettings.builder()
                        .accessTokenTimeToLive(propiedades.duracionToken())
                        .refreshTokenTimeToLive(propiedades.duracionRefresco())
                        .reuseRefreshTokens(false)
                        .build())
                .build();
        RegisteredClient transferencias = servicio(propiedades.transferencias(), "transferencias-service (servicio a servicio)",
                Alcances.CORE_CUENTAS_LEER, propiedades, codificador);
        return new InMemoryRegisteredClientRepository(bancaWeb, transferencias,
                servicio(propiedades.operacion(), "Operacion del banco (administracion de claves)", Alcances.CLAVES_ADMINISTRAR,
                        propiedades, codificador));
    }

    /** Cliente sin usuario: solo client_credentials, un scope y un token de vida corta. */
    private static RegisteredClient servicio(PropiedadesAuth.Cliente cliente, String nombre, String alcance,
                                             PropiedadesAuth propiedades, PasswordEncoder codificador) {
        return RegisteredClient.withId(UUID.nameUUIDFromBytes(cliente.id().getBytes()).toString())
                .clientId(cliente.id())
                .clientSecret(codificador.encode(cliente.secreto()))
                .clientName(nombre)
                .clientAuthenticationMethod(ClientAuthenticationMethod.CLIENT_SECRET_BASIC)
                .authorizationGrantType(AuthorizationGrantType.CLIENT_CREDENTIALS)
                .scope(alcance)
                .tokenSettings(TokenSettings.builder().accessTokenTimeToLive(propiedades.duracionToken()).build())
                .build();
    }
}
