package com.bancoxyz.antifraude.seguridad;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.config.web.PathPatternRequestMatcherBuilderFactoryBean;
import org.springframework.security.web.SecurityFilterChain;

/**
 * antifraude-service no tiene API publica: solo consume y produce eventos de Kafka. Lo unico que se expone por HTTP es
 * el estado del propio proceso para Eureka y para observabilidad, asi que la unica regla es esa.
 *
 * <p>Cuando {@code management.server.port} difiere de {@code server.port} (perfil {@code tls}), el actuator vive en un
 * contexto aparte y esta cadena no lo alcanza; en las pruebas, sin ese perfil, comparten puerto y por eso hace falta
 * permitir explicitamente {@code /actuator/health} y {@code /actuator/info}.</p>
 */
@Configuration
public class ConfiguracionSeguridad {

    /** Hace que requestMatchers(String) use PathPattern, el comportamiento de Spring Security 7. */
    @Bean
    public PathPatternRequestMatcherBuilderFactoryBean constructorDeRutas() {
        return new PathPatternRequestMatcherBuilderFactoryBean();
    }

    @Bean
    public SecurityFilterChain cadenaDeAntifraude(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .formLogin(AbstractHttpConfigurer::disable)
                .logout(AbstractHttpConfigurer::disable)
                .authorizeHttpRequests(a -> a
                        // Operacion: el puerto de management escucha solo en 127.0.0.1 (perfil tls).
                        .requestMatchers("/actuator/health", "/actuator/info", "/actuator/metrics", "/actuator/metrics/**")
                        .permitAll()
                        .anyRequest().denyAll());
        return http.build();
    }
}
