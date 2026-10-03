package com.bancoxyz.core.cuenta;

import java.util.List;

import com.bancoxyz.core.seguridad.Canal;
import com.bancoxyz.core.seguridad.ControlDeAcceso;
import io.swagger.v3.oas.annotations.Operation;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Datos completos de cuentas. Los encabezados de identidad se validan en el servicio, no aqui. */
@RestController
@RequestMapping("/api/v1")
public class ControladorDeCuentas {

    private final ServicioDeCuentas servicio;

    public ControladorDeCuentas(ServicioDeCuentas servicio) {
        this.servicio = servicio;
    }

    @Operation(summary = "Cuentas de un cliente (web y movil)")
    @GetMapping("/clientes/{clienteId}/cuentas")
    public List<CuentaDto> cuentasDeCliente(@PathVariable long clienteId,
                                            @RequestHeader(value = ControlDeAcceso.ENCABEZADO_USUARIO, required = false) String usuarioId,
                                            Authentication autenticacion) {
        return servicio.cuentasDeCliente(Canal.desde(autenticacion), usuarioId, clienteId);
    }

    @Operation(summary = "Una cuenta (web y movil por usuario; cajero por tarjeta)")
    @GetMapping("/cuentas/{cuentaId}")
    public CuentaDto cuenta(@PathVariable long cuentaId,
                            @RequestHeader(value = ControlDeAcceso.ENCABEZADO_USUARIO, required = false) String usuarioId,
                            @RequestHeader(value = ControlDeAcceso.ENCABEZADO_TARJETA, required = false) String tarjetaId,
                            @RequestHeader(value = ControlDeAcceso.ENCABEZADO_TERMINAL, required = false) String terminalId,
                            Authentication autenticacion) {
        return servicio.cuenta(Canal.desde(autenticacion), usuarioId, tarjetaId, terminalId, cuentaId);
    }

    @Operation(summary = "Movimientos del cierre y en linea, paginados")
    @GetMapping("/cuentas/{cuentaId}/movimientos")
    public PaginaMovimientos movimientos(@PathVariable long cuentaId,
                                         @RequestParam(defaultValue = "0") int pagina,
                                         @RequestParam(defaultValue = "20") int tamano,
                                         @RequestHeader(value = ControlDeAcceso.ENCABEZADO_USUARIO, required = false) String usuarioId,
                                         Authentication autenticacion) {
        return servicio.movimientos(Canal.desde(autenticacion), usuarioId, cuentaId, pagina, tamano);
    }

    @Operation(summary = "Estados de cuenta anuales del cierre publicado")
    @GetMapping("/cuentas/{cuentaId}/estados-anuales")
    public List<EstadoAnualDto> estadosAnuales(@PathVariable long cuentaId,
                                               @RequestHeader(value = ControlDeAcceso.ENCABEZADO_USUARIO, required = false) String usuarioId,
                                               Authentication autenticacion) {
        return servicio.estadosAnuales(Canal.desde(autenticacion), usuarioId, cuentaId);
    }
}
