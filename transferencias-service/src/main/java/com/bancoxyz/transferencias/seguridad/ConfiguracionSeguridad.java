package com.bancoxyz.transferencias.seguridad;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

/**
 * La API exige un access token OAuth 2.0 de banco-auth: {@code transferencias.escribir} para transferir y
 * {@code transferencias.leer} para consultar (con el scope que falta: 403). Sin token, o con uno de otra audiencia,
 * vencido, mal firmado o de una clave retirada: 401.
 */
@Configuration
public class ConfiguracionSeguridad {

    @Bean
    public SecurityFilterChain cadenaDeTransferencias(HttpSecurity http) throws Exception {
        return http
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .formLogin(AbstractHttpConfigurer::disable)
                .httpBasic(AbstractHttpConfigurer::disable)
                .headers(h -> h.httpStrictTransportSecurity(hsts -> hsts.maxAgeInSeconds(31_536_000).includeSubDomains(true)))
                .authorizeHttpRequests(a -> a
                        // Cada operacion pide su scope: un token para consultar no sirve para transferir.
                        .requestMatchers(HttpMethod.POST, "/api/v1/transferencias").hasAuthority("SCOPE_transferencias.escribir")
                        .requestMatchers(HttpMethod.GET, "/api/v1/transferencias/*").hasAuthority("SCOPE_transferencias.leer")
                        // El actuator es de solo lectura (salud, circuitos, metricas): su puerto escucha en la red interna
                        // de los contenedores, y un POST como el de Resilience4j que fuerza el estado de un circuito se rechaza.
                        .requestMatchers(HttpMethod.GET, "/actuator/**").permitAll()
                        .requestMatchers("/error").permitAll()
                        .anyRequest().denyAll())
                .oauth2ResourceServer(o -> o.jwt(j -> { }))
                .build();
    }
}
