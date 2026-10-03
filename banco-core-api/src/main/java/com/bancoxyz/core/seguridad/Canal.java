package com.bancoxyz.core.seguridad;

import com.bancoxyz.core.error.Errores;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;

/**
 * Canal desde el que llega la solicitud, deducido de la credencial de servicio.
 *
 * <p>WEB, MOVIL y CAJERO son los BFF de las semanas 4 a 6. Semana 7: AUTENTICACION es banco-auth (verifica claves para
 * emitir JWT) y TRANSFERENCIAS es transferencias-service (prevalida la cuenta de origen antes de iniciar la saga).</p>
 */
public enum Canal {

    WEB("CANAL_WEB"),
    MOVIL("CANAL_MOVIL"),
    CAJERO("CANAL_CAJERO"),
    AUTENTICACION("CANAL_AUTENTICACION"),
    TRANSFERENCIAS("CANAL_TRANSFERENCIAS");

    private final String rol;

    Canal(String rol) {
        this.rol = rol;
    }

    public String rol() {
        return rol;
    }

    public static Canal desde(Authentication autenticacion) {
        if (autenticacion != null) {
            for (GrantedAuthority autoridad : autenticacion.getAuthorities()) {
                for (Canal canal : values()) {
                    if (("ROLE_" + canal.rol).equals(autoridad.getAuthority())) {
                        return canal;
                    }
                }
            }
        }
        throw Errores.accesoDenegado();
    }
}
