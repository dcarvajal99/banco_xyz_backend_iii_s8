package com.bancoxyz.core.seguridad;

import java.io.IOException;

import com.bancoxyz.core.config.PropiedadesCore;
import com.bancoxyz.core.error.Problemas;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ProblemDetail;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.config.web.PathPatternRequestMatcherBuilderFactoryBean;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.security.web.authentication.www.BasicAuthenticationFilter;
import org.springframework.security.web.header.writers.DelegatingRequestMatcherHeaderWriter;
import org.springframework.security.web.header.writers.ReferrerPolicyHeaderWriter.ReferrerPolicy;
import org.springframework.security.web.header.writers.StaticHeadersWriter;
import org.springframework.security.web.servlet.util.matcher.PathPatternRequestMatcher;

/**
 * Seguridad servicio a servicio del core.
 *
 * <p>El core no lo llaman usuarios finales: lo llaman servicios, cada uno con su credencial y un rol de canal
 * (los BFF de semanas anteriores, banco-auth y transferencias-service). Desde la semana 8 transferencias-service se
 * identifica con un token OAuth 2.0 (client_credentials) en vez de una clave Basic. La autorizacion por URL de esta clase es la primera capa (que canal puede tocar que
 * recurso); {@link ControlDeAcceso} es la segunda (que usuario puede ver que cuenta).</p>
 *
 * <p>Semana 5: cada BFF entra con DOS credenciales. La clave Basic y el certificado de cliente de la conexion TLS,
 * que {@link FiltroCertificadoDeCanal} exige y amarra al mismo usuario de servicio. HTTPS lo configura el perfil
 * {@code tls} (application-tls.properties).</p>
 */
@Configuration
public class ConfiguracionSeguridad {

    /** Hace que requestMatchers(String) use PathPattern, el comportamiento de Spring Security 7. */
    @Bean
    public PathPatternRequestMatcherBuilderFactoryBean constructorDeRutas() {
        return new PathPatternRequestMatcherBuilderFactoryBean();
    }

    /**
     * BCrypt de costo 4 para las credenciales de servicio.
     *
     * <p>Con costo 10 cada llamada BFF->core gasta ~55 ms solo en verificar la clave, y el panel web
     * hace varias llamadas en paralelo. Las claves de servicio son largas y aleatorias: su fortaleza
     * no depende de un hash lento, que existe para frenar diccionarios contra claves humanas.</p>
     */
    @Bean
    public PasswordEncoder codificadorDeCanales() {
        return new BCryptPasswordEncoder(4);
    }

    @Bean
    public UserDetailsService canales(PasswordEncoder codificadorDeCanales, PropiedadesCore propiedades) {
        return new InMemoryUserDetailsManager(
                User.withUsername("bff-web").password(codificadorDeCanales.encode(propiedades.canales().web().clave()))
                        .roles(Canal.WEB.rol()).build(),
                User.withUsername("bff-movil").password(codificadorDeCanales.encode(propiedades.canales().movil().clave()))
                        .roles(Canal.MOVIL.rol()).build(),
                User.withUsername("bff-cajero").password(codificadorDeCanales.encode(propiedades.canales().cajero().clave()))
                        .roles(Canal.CAJERO.rol()).build(),
                User.withUsername("banco-auth").password(codificadorDeCanales.encode(propiedades.canales().autenticacion().clave()))
                        .roles(Canal.AUTENTICACION.rol()).build());
    }

    @Bean
    public SecurityFilterChain cadenaDelCore(HttpSecurity http, ObjectMapper objectMapper) throws Exception {
        ProblemasDeSeguridad problemas = new ProblemasDeSeguridad(objectMapper);
        String web = Canal.WEB.rol();
        String movil = Canal.MOVIL.rol();
        String cajero = Canal.CAJERO.rol();
        String autenticacion = Canal.AUTENTICACION.rol();
        String transferencias = Canal.TRANSFERENCIAS.rol();
        http
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .formLogin(AbstractHttpConfigurer::disable)
                .logout(AbstractHttpConfigurer::disable)
                // El entry point va en httpBasic Y en exceptionHandling: clave mala y credencial ausente
                // salen por caminos distintos y los dos deben responder el mismo ProblemDetail.
                .httpBasic(basic -> basic.authenticationEntryPoint(problemas))
                // Semana 8: transferencias-service ya no usa clave Basic. Llega con un token OAuth 2.0 de banco-auth
                // (client_credentials, scope core.cuentas.leer) que se valida contra el JWK Set.
                .oauth2ResourceServer(o -> o.authenticationEntryPoint(problemas)
                        .jwt(j -> j.jwtAuthenticationConverter(tokensDeServicio())))
                .exceptionHandling(e -> e.authenticationEntryPoint(problemas).accessDeniedHandler(problemas))
                .addFilterAfter(new FiltroCertificadoDeCanal(problemas), BasicAuthenticationFilter.class)
                .headers(h -> h
                        // Spring Security escribe HSTS solo en respuestas HTTPS: el navegador no vuelve a intentar HTTP.
                        .httpStrictTransportSecurity(hsts -> hsts.maxAgeInSeconds(31_536_000).includeSubDomains(true))
                        .referrerPolicy(r -> r.policy(ReferrerPolicy.NO_REFERRER))
                        // La API solo entrega JSON: nada que cargar ni enmarcar. Swagger UI queda fuera de esta politica.
                        .addHeaderWriter(new DelegatingRequestMatcherHeaderWriter(
                                PathPatternRequestMatcher.withDefaults().matcher("/api/**"),
                                new StaticHeadersWriter("Content-Security-Policy", "default-src 'none'; frame-ancestors 'none'"))))
                .authorizeHttpRequests(a -> a
                        // Las metricas solo existen en el puerto de operacion (127.0.0.1, perfil tls).
                        .requestMatchers("/actuator/health", "/actuator/metrics", "/actuator/metrics/**", "/v3/api-docs/**",
                                "/swagger-ui/**", "/swagger-ui.html", "/error").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/v1/autenticacion/tarjetas").hasRole(cajero)
                        .requestMatchers(HttpMethod.POST, "/api/v1/cuentas/*/retiros").hasRole(cajero)
                        .requestMatchers(HttpMethod.POST, "/api/v1/autenticacion/usuarios").hasAnyRole(web, movil, autenticacion)
                        .requestMatchers(HttpMethod.GET, "/api/v1/clientes", "/api/v1/reportes/**").hasRole(web)
                        .requestMatchers(HttpMethod.GET, "/api/v1/clientes/*/cuentas", "/api/v1/cuentas/*/movimientos",
                                "/api/v1/cuentas/*/estados-anuales").hasAnyRole(web, movil)
                        .requestMatchers(HttpMethod.GET, "/api/v1/cuentas/*").hasAnyRole(web, movil, cajero, transferencias)
                        .requestMatchers(HttpMethod.GET, "/api/v1/cierres/vigentes").hasAnyRole(web, movil, cajero)
                        .anyRequest().denyAll());
        return http.build();
    }

    private static JwtAuthenticationConverter tokensDeServicio() {
        JwtAuthenticationConverter convertidor = new JwtAuthenticationConverter();
        convertidor.setJwtGrantedAuthoritiesConverter(new TokensDeServicio());
        return convertidor;
    }

    /** 401 y 403 de Spring Security, que ocurren fuera de MVC, con el mismo ProblemDetail que el resto. */
    static final class ProblemasDeSeguridad implements AuthenticationEntryPoint, AccessDeniedHandler {

        private final ObjectMapper objectMapper;

        ProblemasDeSeguridad(ObjectMapper objectMapper) {
            this.objectMapper = objectMapper;
        }

        @Override
        public void commence(HttpServletRequest request, HttpServletResponse response, AuthenticationException ex)
                throws IOException {
            rechazar(request, response, HttpStatus.UNAUTHORIZED, "NO_AUTENTICADO", "No autenticado",
                    "Credencial de canal ausente o invalida");
        }

        @Override
        public void handle(HttpServletRequest request, HttpServletResponse response, AccessDeniedException ex)
                throws IOException {
            rechazar(request, response, HttpStatus.FORBIDDEN, "ACCESO_DENEGADO", "Acceso denegado",
                    "El canal no tiene permiso sobre este recurso");
        }

        void rechazar(HttpServletRequest request, HttpServletResponse response, HttpStatus estado, String codigo,
                      String titulo, String detalle) throws IOException {
            escribir(response, Problemas.crear(estado, codigo, titulo, detalle, request.getRequestURI()));
        }

        private void escribir(HttpServletResponse response, ProblemDetail problema) throws IOException {
            response.setStatus(problema.getStatus());
            response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
            objectMapper.writeValue(response.getOutputStream(), problema);
        }
    }
}
