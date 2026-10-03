package com.bancoxyz.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Todo lo que sirve el Config Server exige usuario y clave; solo el health (puerto de operacion en loopback) queda
 * abierto. El certificado de cliente lo exige antes el conector HTTPS ({@code server.ssl.client-auth=need}).
 */
@Configuration
public class SeguridadDelConfigServer {

    @Bean
    public SecurityFilterChain cadenaDelConfigServer(HttpSecurity http) throws Exception {
        return http
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(a -> a.requestMatchers("/actuator/health").permitAll().anyRequest().authenticated())
                .httpBasic(Customizer.withDefaults())
                .build();
    }
}
