package com.bancoxyz.core.autenticacion;

import com.bancoxyz.core.autenticacion.ServicioDeAutenticacion.ResultadoTarjeta;
import com.bancoxyz.core.autenticacion.ServicioDeAutenticacion.ResultadoUsuario;
import com.bancoxyz.core.cliente.RepositorioClientes;
import com.bancoxyz.core.cuenta.RepositorioCuentas;
import com.bancoxyz.core.error.Errores;
import com.bancoxyz.core.seguridad.Canal;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/autenticacion")
public class ControladorDeAutenticacion {

    private final ServicioDeAutenticacion servicio;
    private final RepositorioClientes clientes;
    private final RepositorioCuentas cuentas;

    public ControladorDeAutenticacion(ServicioDeAutenticacion servicio, RepositorioClientes clientes,
                                      RepositorioCuentas cuentas) {
        this.servicio = servicio;
        this.clientes = clientes;
        this.cuentas = cuentas;
    }

    @Operation(summary = "Verifica usuario y clave (canales web y movil)")
    @PostMapping("/usuarios")
    public UsuarioAutenticadoDto usuario(@Valid @RequestBody SolicitudUsuario solicitud, Authentication autenticacion) {
        // El servicio ya confirmo su transaccion: el intento fallido queda contado aunque aqui se lance el error.
        ResultadoUsuario resultado = servicio.autenticarUsuario(Canal.desde(autenticacion), solicitud.usuario(),
                solicitud.password());
        return switch (resultado.estado()) {
            case AUTENTICADO -> {
                Usuario u = resultado.usuario();
                String nombre = u.getClienteId() == null ? "Ejecutivo del banco"
                        : clientes.findById(u.getClienteId()).map(c -> c.getNombre()).orElse(u.getUsuario());
                yield new UsuarioAutenticadoDto(u.getId(), u.getClienteId(), u.getUsuario(), nombre, u.getRol());
            }
            case CREDENCIALES_INVALIDAS -> throw Errores.credencialesInvalidas();
            case BLOQUEADO -> throw Errores.usuarioBloqueado();
            case ROL_NO_PERMITIDO -> throw Errores.rolNoPermitidoEnCanal();
        };
    }

    @Operation(summary = "Verifica tarjeta y PIN (canal cajero)")
    @PostMapping("/tarjetas")
    public TarjetaAutenticadaDto tarjeta(@Valid @RequestBody SolicitudTarjeta solicitud) {
        ResultadoTarjeta resultado = servicio.autenticarTarjeta(solicitud.numeroTarjeta(), solicitud.pin());
        return switch (resultado.estado()) {
            case AUTENTICADA -> {
                var tarjeta = resultado.tarjeta();
                String titular = cuentas.findById(tarjeta.getCuentaId()).map(c -> c.getTitular()).orElse("");
                yield new TarjetaAutenticadaDto(tarjeta.getId(), tarjeta.getCuentaId(), tarjeta.getUltimos4(), titular);
            }
            case TARJETA_INVALIDA -> throw Errores.tarjetaInvalida();
            case PIN_INCORRECTO -> throw Errores.pinIncorrecto(resultado.intentosRestantes());
            case BLOQUEADA -> throw Errores.tarjetaBloqueada();
        };
    }
}
