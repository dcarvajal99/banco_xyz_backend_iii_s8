package com.bancoxyz.core;

import java.time.ZoneId;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;

@TestConfiguration
public class ConfiguracionDePrueba {

    @Bean
    @Primary
    public RelojAjustable relojAjustable() {
        return new RelojAjustable(ZoneId.of("America/Santiago"));
    }
}
