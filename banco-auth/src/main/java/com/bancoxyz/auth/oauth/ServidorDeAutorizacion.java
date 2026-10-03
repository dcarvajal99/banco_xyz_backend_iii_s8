package com.bancoxyz.auth.oauth;

import java.util.List;

import com.bancoxyz.auth.claves.AlmacenDeClaves;
import com.bancoxyz.auth.config.PropiedadesAuth;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.proc.SecurityContext;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.oidc.endpoint.OidcParameterNames;
import org.springframework.security.oauth2.jwt.JwtClaimNames;
import org.springframework.security.oauth2.jwt.JwtClaimValidator;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.server.authorization.OAuth2TokenType;
import org.springframework.security.oauth2.server.authorization.config.annotation.web.configuration.OAuth2AuthorizationServerConfiguration;
import org.springframework.security.oauth2.server.authorization.config.annotation.web.configurers.OAuth2AuthorizationServerConfigurer;
import org.springframework.security.oauth2.server.authorization.settings.AuthorizationServerSettings;
import org.springframework.security.oauth2.server.authorization.token.JwtEncodingContext;
import org.springframework.security.oauth2.server.authorization.token.OAuth2TokenCustomizer;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.LoginUrlAuthenticationEntryPoint;
import org.springframework.security.web.util.matcher.MediaTypeRequestMatcher;

/**
 * banco-auth como servidor de autorizacion OAuth 2.0 / OpenID Connect (Spring Authorization Server).
 *
 * <p>Tres cadenas de seguridad:</p>
 * <ol>
 *   <li>Los endpoints del protocolo ({@code /oauth2/authorize}, {@code /oauth2/token}, {@code /oauth2/jwks},
 *       {@code /oauth2/introspect}, {@code /oauth2/revoke}, {@code /.well-known/openid-configuration},
 *       {@code /userinfo}). Si el navegador llega a {@code /oauth2/authorize} sin sesion, lo manda al login.</li>
 *   <li>El actuator (puerto de operacion): la administracion de claves exige un token con {@code claves.administrar};
 *       el resto es solo lectura.</li>
 *   <li>El inicio de sesion: el formulario (la clave la verifica el core) o "Ingresar con GitHub" (identidad federada,
 *       solo cuentas vinculadas a un cliente; ver {@link VinculacionGitHub}), y el resto, que exige sesion.</li>
 * </ol>
 *
 * <p>Los tokens se firman con las claves rotables de {@link AlmacenDeClaves} (RS256): el encabezado lleva el {@code kid}
 * de la clave activa y {@code /oauth2/jwks} publica la activa y las que siguen en periodo de gracia.</p>
 */
@Configuration(proxyBeanMethods = false)
public class ServidorDeAutorizacion {

    @Bean
    @Order(1)
    public SecurityFilterChain cadenaDelProtocolo(HttpSecurity http) throws Exception {
        OAuth2AuthorizationServerConfigurer servidor = OAuth2AuthorizationServerConfigurer.authorizationServer();
        http.securityMatcher(servidor.getEndpointsMatcher())
                .with(servidor, s -> s.oidc(Customizer.withDefaults()))
                .authorizeHttpRequests(a -> a.anyRequest().authenticated())
                .exceptionHandling(e -> e.defaultAuthenticationEntryPointFor(new LoginUrlAuthenticationEntryPoint("/login"),
                        new MediaTypeRequestMatcher(MediaType.TEXT_HTML)))
                // /userinfo se consulta con el access token del propio servidor.
                .oauth2ResourceServer(r -> r.jwt(Customizer.withDefaults()));
        return http.build();
    }

    /**
     * El actuator. En contenedores el puerto de operacion escucha en la red interna, asi que estar en ese puerto no
     * basta: rotar o retirar claves (y listarlas) exige un access token del cliente operacion-banco con el scope
     * {@code claves.administrar}, validado como en cualquier servidor de recursos. Lo demas (salud, circuitos, eventos)
     * es de solo lectura: cualquier otro metodo, como el POST de Resilience4j que fuerza el estado de un circuito, se
     * rechaza. Sin sesion ni cookies: CSRF no aplica a un token Bearer.
     */
    @Bean
    @Order(2)
    public SecurityFilterChain cadenaDeOperacion(HttpSecurity http) throws Exception {
        return http.securityMatcher("/actuator/**")
                .authorizeHttpRequests(a -> a
                        .requestMatchers("/actuator/claves", "/actuator/claves/**").hasAuthority("SCOPE_" + Alcances.CLAVES_ADMINISTRAR)
                        .requestMatchers(HttpMethod.GET, "/actuator/**").permitAll()
                        .anyRequest().denyAll())
                .oauth2ResourceServer(r -> r.jwt(Customizer.withDefaults()))
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .csrf(AbstractHttpConfigurer::disable)
                .build();
    }

    @Bean
    @Order(3)
    public SecurityFilterChain cadenaDeLogin(HttpSecurity http, ObjectProvider<ClientRegistrationRepository> registros,
                                             VinculacionGitHub vinculacion) throws Exception {
        // OAuth 2.0 Client con GitHub como proveedor de identidad (el registro llega del Config Server). Sin registro,
        // queda solo el formulario.
        if (registros.getIfAvailable() != null) {
            http.oauth2Login(o -> o.loginPage("/login")
                    .userInfoEndpoint(u -> u.userService(vinculacion))
                    .failureHandler(new FallasDeLogin()));
        }
        return http
                .headers(h -> h.httpStrictTransportSecurity(hsts -> hsts.maxAgeInSeconds(31_536_000).includeSubDomains(true)))
                .authorizeHttpRequests(a -> a
                        .requestMatchers("/error").permitAll()
                        // Por ruta y no por URL exacta: el formulario se abre tambien con ?error=<motivo>.
                        .requestMatchers("/login").permitAll()
                        .anyRequest().authenticated())
                .formLogin(f -> f.loginPage("/login").failureHandler(new FallasDeLogin()))
                .build();
    }

    @Bean
    public AuthorizationServerSettings ajustesDelServidor(PropiedadesAuth propiedades) {
        return AuthorizationServerSettings.builder().issuer(propiedades.emisor()).build();
    }

    /** Fuente de claves del firmador y de {@code /oauth2/jwks}: el endpoint publica solo la parte publica. */
    @Bean
    public JWKSource<SecurityContext> fuenteDeClaves(AlmacenDeClaves almacen) {
        return (selector, contexto) -> selector.select(almacen.conjuntoDeFirma());
    }

    /**
     * Valida los tokens que recibe el propio servidor ({@code /userinfo} y el actuator): firma con sus claves, vigencia,
     * emisor y audiencia, igual que los demas servidores de recursos del banco.
     */
    @Bean
    public JwtDecoder jwtDecoder(JWKSource<SecurityContext> fuenteDeClaves, PropiedadesAuth propiedades) {
        NimbusJwtDecoder decodificador = (NimbusJwtDecoder) OAuth2AuthorizationServerConfiguration.jwtDecoder(fuenteDeClaves);
        decodificador.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
                JwtValidators.createDefaultWithIssuer(propiedades.emisor()),
                new JwtClaimValidator<List<String>>(JwtClaimNames.AUD, aud -> aud != null && aud.contains(propiedades.audiencia()))));
        return decodificador;
    }

    /**
     * Claims del banco en cada token.
     *
     * <ul>
     *   <li>Encabezado: el {@code kid} de la clave activa (con varias claves publicadas el firmador necesita saber cual usar).</li>
     *   <li>Access token: {@code aud=banco-xyz} y, si hay usuario, {@code usuario_id}, {@code cliente_id} y {@code rol};
     *       un token de client_credentials no los trae (no hay usuario: {@code sub} es el id del cliente). {@code origen}
     *       dice como inicio sesion: {@code banco} (formulario) o {@code github}, con su {@code github_login}.</li>
     *   <li>ID token (OpenID Connect): los mismos datos del usuario para la aplicacion.</li>
     * </ul>
     */
    @Bean
    public OAuth2TokenCustomizer<JwtEncodingContext> claimsDelBanco(AlmacenDeClaves almacen, PropiedadesAuth propiedades) {
        return contexto -> {
            contexto.getJwsHeader().keyId(almacen.activa().kid());
            boolean accessToken = OAuth2TokenType.ACCESS_TOKEN.equals(contexto.getTokenType());
            boolean idToken = OidcParameterNames.ID_TOKEN.equals(contexto.getTokenType().getValue());
            if (accessToken) {
                contexto.getClaims().audience(List.of(propiedades.audiencia()));
            }
            Object principal = contexto.getPrincipal().getPrincipal();
            UsuarioDelBanco usuario = principal instanceof UsuarioGitHub github ? github.banco()
                    : principal instanceof UsuarioDelBanco delBanco ? delBanco : null;
            if ((accessToken || idToken) && usuario != null) {
                contexto.getClaims()
                        .claim("usuario_id", usuario.usuarioId())
                        .claim("cliente_id", usuario.clienteId())
                        .claim("rol", usuario.rol())
                        .claim("origen", principal instanceof UsuarioGitHub ? "github" : "banco");
                if (principal instanceof UsuarioGitHub github) {
                    contexto.getClaims().claim("github_login", github.githubLogin());
                }
            }
        };
    }
}
