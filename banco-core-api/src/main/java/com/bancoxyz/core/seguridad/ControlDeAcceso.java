package com.bancoxyz.core.seguridad;

import java.util.Objects;

import com.bancoxyz.core.autenticacion.RepositorioUsuarios;
import com.bancoxyz.core.autenticacion.Usuario;
import com.bancoxyz.core.cliente.RepositorioClientes;
import com.bancoxyz.core.cuenta.Cuenta;
import com.bancoxyz.core.cuenta.RepositorioCuentas;
import com.bancoxyz.core.error.Errores;
import com.bancoxyz.core.tarjeta.RepositorioTarjetas;
import com.bancoxyz.core.tarjeta.Tarjeta;
import org.springframework.stereotype.Component;

/**
 * Segunda capa de autorizacion: que usuario o tarjeta puede ver que dato.
 *
 * <p>El core confia en la identidad que le pasa un BFF autenticado (subsistema de confianza), pero
 * no en el ROL que ese BFF diga: busca el usuario por id y usa el rol de la base. Asi, aunque un BFF
 * tuviera un error, un cliente nunca ve cuentas ajenas.</p>
 */
@Component
public class ControlDeAcceso {

    public static final String ENCABEZADO_USUARIO = "X-Usuario-Id";
    public static final String ENCABEZADO_TARJETA = "X-Tarjeta-Id";
    public static final String ENCABEZADO_TERMINAL = "X-Terminal-Id";

    private final RepositorioUsuarios usuarios;
    private final RepositorioClientes clientes;
    private final RepositorioCuentas cuentas;
    private final RepositorioTarjetas tarjetas;

    public ControlDeAcceso(RepositorioUsuarios usuarios, RepositorioClientes clientes, RepositorioCuentas cuentas,
                           RepositorioTarjetas tarjetas) {
        this.usuarios = usuarios;
        this.clientes = clientes;
        this.cuentas = cuentas;
        this.tarjetas = tarjetas;
    }

    /** Usuario final propagado por el BFF web o movil. */
    public Usuario usuario(Canal canal, String usuarioId) {
        // banco-auth solo verifica claves: no lee cuentas.
        if (canal == Canal.CAJERO || canal == Canal.AUTENTICACION) {
            throw Errores.accesoDenegado();
        }
        long id = numero(usuarioId, ENCABEZADO_USUARIO);
        Usuario usuario = usuarios.findById(id).filter(Usuario::isActivo).orElseThrow(Errores::accesoDenegado);
        // La consola del ejecutivo no existe en el movil: ni siquiera un BFF movil mal configurado la abre.
        if ((canal == Canal.MOVIL || canal == Canal.TRANSFERENCIAS) && usuario.esEjecutivo()) {
            throw Errores.accesoDenegado();
        }
        return usuario;
    }

    public void exigirEjecutivo(Usuario usuario) {
        if (!usuario.esEjecutivo()) {
            throw Errores.accesoDenegado();
        }
    }

    public void exigirClienteVisible(Usuario usuario, long clienteId) {
        boolean propio = Objects.equals(usuario.getClienteId(), clienteId);
        if ((!usuario.esEjecutivo() && !propio) || !clientes.existsById(clienteId)) {
            throw Errores.clienteNoEncontrado();
        }
    }

    public Cuenta cuentaVisible(Usuario usuario, long cuentaId) {
        Cuenta cuenta = cuentas.findById(cuentaId).orElseThrow(Errores::cuentaNoEncontrada);
        if (!usuario.esEjecutivo() && !Objects.equals(cuenta.getClienteId(), usuario.getClienteId())) {
            throw Errores.cuentaNoEncontrada();
        }
        return cuenta;
    }

    /** Tarjeta y terminal propagados por el BFF cajero. */
    public Tarjeta tarjeta(Canal canal, String tarjetaId, String terminalId) {
        if (canal != Canal.CAJERO) {
            throw Errores.accesoDenegado();
        }
        long id = numero(tarjetaId, ENCABEZADO_TARJETA);
        if (terminalId == null || terminalId.isBlank() || terminalId.length() > 40) {
            throw Errores.identidadRequerida(ENCABEZADO_TERMINAL);
        }
        return tarjetas.findById(id).orElseThrow(Errores::accesoDenegado);
    }

    /** El cajero solo ve la cuenta asociada a la tarjeta que se autentico. */
    public Cuenta cuentaDeTarjeta(Tarjeta tarjeta, long cuentaId) {
        if (!Objects.equals(tarjeta.getCuentaId(), cuentaId)) {
            throw Errores.cuentaNoEncontrada();
        }
        return cuentas.findById(cuentaId).orElseThrow(Errores::cuentaNoEncontrada);
    }

    private static long numero(String valor, String encabezado) {
        if (valor == null || valor.isBlank()) {
            throw Errores.identidadRequerida(encabezado);
        }
        try {
            return Long.parseLong(valor.trim());
        } catch (NumberFormatException e) {
            throw Errores.identidadRequerida(encabezado);
        }
    }
}
