package com.bancoxyz.notificaciones.seguridad;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

/**
 * La API exige un JWT de banco-auth con el scope {@code transferencias} (el mismo que usa transferencias-service: el
 * cliente ya lo tiene de haber iniciado la transferencia). Sin token: 401; con un token de otra audiencia, vencido,
 * mal firmado o de una clave retirada: 401.
 */
@Configuration
public class ConfiguracionSeguridad {

    @Bean
    public SecurityFilterChain cadenaDeNotificaciones(HttpSecurity http) throws Exception {
        return http
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .formLogin(AbstractHttpConfigurer::disable)
                .httpBasic(AbstractHttpConfigurer::disable)
                .headers(h -> h.httpStrictTransportSecurity(hsts -> hsts.maxAgeInSeconds(31_536_000).includeSubDomains(true)))
                .authorizeHttpRequests(a -> a
                        .requestMatchers(HttpMethod.GET, "/api/v1/notificaciones").hasAuthority("SCOPE_notificaciones.leer")
                        // El actuator es de solo lectura (salud, circuitos, metricas): su puerto escucha en la red interna
                        // de los contenedores, y un POST como el de Resilience4j que fuerza el estado de un circuito se rechaza.
                        .requestMatchers(HttpMethod.GET, "/actuator/**").permitAll()
                        .requestMatchers("/error").permitAll()
                        .anyRequest().denyAll())
                .oauth2ResourceServer(o -> o.jwt(j -> { }))
                .build();
    }
}
