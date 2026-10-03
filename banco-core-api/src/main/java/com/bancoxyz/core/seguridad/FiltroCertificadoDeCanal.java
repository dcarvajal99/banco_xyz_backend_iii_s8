package com.bancoxyz.core.seguridad;

import java.io.IOException;
import java.security.cert.X509Certificate;
import java.util.Optional;

import javax.naming.InvalidNameException;
import javax.naming.ldap.LdapName;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Segunda credencial del canal: el certificado de cliente de la conexion TLS (mTLS).
 *
 * <p>Tomcat valida la cadena del certificado contra la CA del banco durante el handshake. Este filtro exige que el
 * certificado exista y que su CN sea el mismo usuario de servicio que llega por Basic. Con eso una clave de canal
 * filtrada no sirve sin la clave privada del certificado, y un BFF no puede hacerse pasar por otro: el certificado de
 * bff-movil con la credencial de bff-web se rechaza.</p>
 *
 * <p>Va despues de {@code BasicAuthenticationFilter} para conocer al usuario autenticado. Solo aplica a
 * {@code /api/}: con {@code server.ssl.client-auth=want} la conexion TLS se abre sin certificado (Swagger, contrato
 * OpenAPI) y el rechazo llega como ProblemDetail, no como un handshake cortado que el BFF no sabria explicar.</p>
 *
 * <p>No es un {@code @Component}: se instancia en la cadena de seguridad para que Boot no lo registre ademas como
 * filtro de servlet.</p>
 */
public class FiltroCertificadoDeCanal extends OncePerRequestFilter {

    /** Atributo estandar de Servlet con la cadena que presento el cliente. */
    public static final String ATRIBUTO_CERTIFICADOS = "jakarta.servlet.request.X509Certificate";

    private final ConfiguracionSeguridad.ProblemasDeSeguridad problemas;

    FiltroCertificadoDeCanal(ConfiguracionSeguridad.ProblemasDeSeguridad problemas) {
        this.problemas = problemas;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().startsWith("/api/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        Optional<String> nombre = nombreComun(request);
        if (nombre.isEmpty()) {
            problemas.rechazar(request, response, HttpStatus.UNAUTHORIZED, "CERTIFICADO_REQUERIDO",
                    "Certificado de cliente requerido", "El canal debe presentar su certificado de cliente (mTLS)");
            return;
        }
        Authentication autenticacion = SecurityContextHolder.getContext().getAuthentication();
        if (autenticacion != null && autenticacion.isAuthenticated()
                && !(autenticacion instanceof AnonymousAuthenticationToken)
                && !nombre.get().equals(autenticacion.getName())) {
            problemas.rechazar(request, response, HttpStatus.FORBIDDEN, "CERTIFICADO_NO_CORRESPONDE",
                    "Certificado de otro canal", "El certificado presentado no pertenece a la credencial del canal");
            return;
        }
        chain.doFilter(request, response);
    }

    /** CN del certificado del cliente (el primero de la cadena), si lo hay y tiene un sujeto legible. */
    public static Optional<String> nombreComun(HttpServletRequest request) {
        if (!(request.getAttribute(ATRIBUTO_CERTIFICADOS) instanceof X509Certificate[] cadena) || cadena.length == 0) {
            return Optional.empty();
        }
        try {
            return new LdapName(cadena[0].getSubjectX500Principal().getName()).getRdns().stream()
                    .filter(rdn -> "CN".equalsIgnoreCase(rdn.getType()))
                    .map(rdn -> rdn.getValue().toString())
                    .findFirst();
        } catch (InvalidNameException sujetoIlegible) {
            return Optional.empty();
        }
    }
}
