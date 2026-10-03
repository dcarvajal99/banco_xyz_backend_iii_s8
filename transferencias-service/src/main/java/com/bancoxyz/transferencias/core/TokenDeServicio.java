package com.bancoxyz.transferencias.core;

import java.time.Duration;
import java.util.List;

import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.http.client.ClientHttpRequestFactoryBuilder;
import org.springframework.boot.http.client.ClientHttpRequestFactorySettings;
import org.springframework.boot.ssl.SslBundles;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.converter.FormHttpMessageConverter;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.client.AuthorizedClientServiceOAuth2AuthorizedClientManager;
import org.springframework.security.oauth2.client.InMemoryOAuth2AuthorizedClientService;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClientManager;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClientProviderBuilder;
import org.springframework.security.oauth2.client.endpoint.RestClientClientCredentialsTokenResponseClient;
import org.springframework.security.oauth2.client.http.OAuth2ErrorResponseErrorHandler;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.security.oauth2.client.web.client.OAuth2ClientHttpRequestInterceptor;
import org.springframework.security.oauth2.core.http.converter.OAuth2AccessTokenResponseHttpMessageConverter;
import org.springframework.web.client.RestClient;

/**
 * Token OAuth 2.0 de transferencias-service para llamar al core (flujo client_credentials, scope core.cuentas.leer).
 *
 * <ul>
 *   <li>El token se pide a banco-auth la primera vez y se reutiliza hasta 30 s antes de vencer: no hay una llamada al
 *       servidor de autorizacion por cada consulta al core.</li>
 *   <li>Es un token del servicio, no del usuario: el principal es siempre {@code transferencias-service}, aunque la
 *       solicitud HTTP que lo origino traiga el JWT de un cliente.</li>
 *   <li>El endpoint de tokens se llama con un RestClient propio: sin balanceo (URL fija de banco-auth), con el bundle TLS
 *       del servicio (confia solo en la CA del banco) y con timeouts cortos. No pasa por los personalizadores de los
 *       demas RestClient.</li>
 * </ul>
 */
@Configuration(proxyBeanMethods = false)
public class TokenDeServicio {

    /** Id del registro OAuth del core en {@code spring.security.oauth2.client.registration.*}. */
    static final String REGISTRO = "core";

    private static final Authentication SERVICIO = UsernamePasswordAuthenticationToken.authenticated(
            "transferencias-service", null, List.of());

    @Bean
    OAuth2AuthorizedClientManager gestorDeTokens(ClientRegistrationRepository registros, ObjectProvider<SslBundles> bundles,
                                                 @Value("${spring.http.client.ssl.bundle:}") String bundle) {
        ClientHttpRequestFactorySettings ajustes = ClientHttpRequestFactorySettings.defaults()
                .withConnectTimeout(Duration.ofSeconds(1)).withReadTimeout(Duration.ofSeconds(3));
        if (!bundle.isBlank()) {
            ajustes = ajustes.withSslBundle(bundles.getObject().getBundle(bundle));
        }
        RestClientClientCredentialsTokenResponseClient pedidor = new RestClientClientCredentialsTokenResponseClient();
        pedidor.setRestClient(RestClient.builder()
                .requestFactory(ClientHttpRequestFactoryBuilder.detect().build(ajustes))
                .messageConverters(c -> {
                    c.clear();
                    c.add(new FormHttpMessageConverter());
                    c.add(new OAuth2AccessTokenResponseHttpMessageConverter());
                })
                .defaultStatusHandler(new OAuth2ErrorResponseErrorHandler())
                .build());
        AuthorizedClientServiceOAuth2AuthorizedClientManager gestor = new AuthorizedClientServiceOAuth2AuthorizedClientManager(
                registros, new InMemoryOAuth2AuthorizedClientService(registros));
        gestor.setAuthorizedClientProvider(OAuth2AuthorizedClientProviderBuilder.builder()
                .clientCredentials(c -> c.accessTokenResponseClient(pedidor).clockSkew(Duration.ofSeconds(30)))
                .build());
        return gestor;
    }

    /** Interceptor que agrega {@code Authorization: Bearer <token de servicio>} a cada llamada al core. */
    static OAuth2ClientHttpRequestInterceptor interceptor(OAuth2AuthorizedClientManager gestor) {
        OAuth2ClientHttpRequestInterceptor interceptor = new OAuth2ClientHttpRequestInterceptor(gestor);
        interceptor.setClientRegistrationIdResolver(solicitud -> REGISTRO);
        interceptor.setPrincipalResolver(solicitud -> SERVICIO);
        return interceptor;
    }
}
