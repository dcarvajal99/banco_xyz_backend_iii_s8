package com.bancoxyz.core.config;

import java.time.Clock;
import java.time.ZoneId;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ConfiguracionGeneral {

    /**
     * Un unico reloj con la zona del banco.
     *
     * <p>El limite diario de retiro depende de cuando empieza "hoy". Si cada clase llamara a
     * {@code LocalDateTime.now()} sin zona, en un servidor con TZ=UTC un retiro de las 22:00 en
     * Santiago quedaria guardado al dia siguiente y contaria dos veces. Todas las marcas de tiempo
     * salen de este reloj, y las pruebas lo reemplazan por uno fijo.</p>
     */
    @Bean
    public Clock reloj(PropiedadesCore propiedades) {
        return Clock.system(ZoneId.of(propiedades.zonaHoraria()));
    }

    @Bean
    public OpenAPI contratoOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("Banco XYZ - Core API")
                        .version("1.0.0")
                        .description("Backend principal, agnostico del canal. Entrega datos completos y aplica las "
                                + "reglas de negocio comunes. Solo lo consumen los BFF web, movil y cajero, cada uno "
                                + "con su credencial de servicio (HTTP Basic) y propagando la identidad del usuario "
                                + "final en X-Usuario-Id o X-Tarjeta-Id/X-Terminal-Id."))
                .components(new Components().addSecuritySchemes("credencialDeCanal",
                        new SecurityScheme().type(SecurityScheme.Type.HTTP).scheme("basic")
                                .description("bff-web, bff-movil o bff-cajero")))
                .addSecurityItem(new SecurityRequirement().addList("credencialDeCanal"));
    }
}
