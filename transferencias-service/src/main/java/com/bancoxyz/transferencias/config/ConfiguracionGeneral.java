package com.bancoxyz.transferencias.config;

import java.time.Clock;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ConfiguracionGeneral {

    @Bean
    public Clock reloj() {
        return Clock.systemDefaultZone();
    }
}
