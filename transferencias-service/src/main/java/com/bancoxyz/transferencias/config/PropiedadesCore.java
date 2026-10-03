package com.bancoxyz.transferencias.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Direccion del core. La credencial ya no es una clave Basic: transferencias-service se identifica con un token OAuth 2.0
 * (client_credentials, ver {@code TokenDeServicio}) y con su certificado de cliente (mTLS, bundle TLS).
 */
@ConfigurationProperties(prefix = "banco.core")
public record PropiedadesCore(String url) {
}
