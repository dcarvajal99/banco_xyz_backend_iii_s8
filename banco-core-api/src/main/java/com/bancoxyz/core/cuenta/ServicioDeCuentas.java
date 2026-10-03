package com.bancoxyz.core.cuenta;

import java.util.List;

import com.bancoxyz.core.autenticacion.Usuario;
import com.bancoxyz.core.cierre.Conjunto;
import com.bancoxyz.core.cierre.LectorDeCierres;
import com.bancoxyz.core.error.Errores;
import com.bancoxyz.core.seguridad.Canal;
import com.bancoxyz.core.seguridad.ControlDeAcceso;
import com.bancoxyz.core.tarjeta.Tarjeta;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class ServicioDeCuentas {

    static final int TAMANO_MAXIMO = 100;

    private final ControlDeAcceso acceso;
    private final RepositorioCuentas cuentas;
    private final LectorDeCierres cierres;
    private final LectorDeMovimientos movimientos;

    public ServicioDeCuentas(ControlDeAcceso acceso, RepositorioCuentas cuentas, LectorDeCierres cierres,
                             LectorDeMovimientos movimientos) {
        this.acceso = acceso;
        this.cuentas = cuentas;
        this.cierres = cierres;
        this.movimientos = movimientos;
    }

    public List<CuentaDto> cuentasDeCliente(Canal canal, String usuarioId, long clienteId) {
        Usuario usuario = acceso.usuario(canal, usuarioId);
        acceso.exigirClienteVisible(usuario, clienteId);
        return cuentas.findByClienteIdOrderByIdAsc(clienteId).stream().map(CuentaDto::desde).toList();
    }

    public CuentaDto cuenta(Canal canal, String usuarioId, String tarjetaId, String terminalId, long cuentaId) {
        if (canal == Canal.CAJERO) {
            Tarjeta tarjeta = acceso.tarjeta(canal, tarjetaId, terminalId);
            return CuentaDto.desde(acceso.cuentaDeTarjeta(tarjeta, cuentaId));
        }
        return CuentaDto.desde(acceso.cuentaVisible(acceso.usuario(canal, usuarioId), cuentaId));
    }

    public PaginaMovimientos movimientos(Canal canal, String usuarioId, long cuentaId, int pagina, int tamano) {
        if (pagina < 0 || tamano < 1 || tamano > TAMANO_MAXIMO) {
            throw Errores.solicitudInvalida("pagina debe ser >= 0 y tamano entre 1 y " + TAMANO_MAXIMO);
        }
        acceso.cuentaVisible(acceso.usuario(canal, usuarioId), cuentaId);
        long job = cierres.exigirVigente(Conjunto.MOVIMIENTOS).jobExecutionId();
        return movimientos.pagina(cuentaId, job, pagina, tamano);
    }

    public List<EstadoAnualDto> estadosAnuales(Canal canal, String usuarioId, long cuentaId) {
        acceso.cuentaVisible(acceso.usuario(canal, usuarioId), cuentaId);
        long job = cierres.exigirVigente(Conjunto.MOVIMIENTOS).jobExecutionId();
        return movimientos.estadosAnuales(cuentaId, job);
    }
}
