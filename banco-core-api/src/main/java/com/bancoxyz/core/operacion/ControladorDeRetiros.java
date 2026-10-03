package com.bancoxyz.core.operacion;

import com.bancoxyz.core.error.Errores;
import com.bancoxyz.core.seguridad.Canal;
import com.bancoxyz.core.seguridad.ControlDeAcceso;
import com.bancoxyz.core.tarjeta.Tarjeta;
import io.swagger.v3.oas.annotations.Operation;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/cuentas")
public class ControladorDeRetiros {

    public static final String ENCABEZADO_IDEMPOTENCIA = "Idempotency-Key";
    public static final String ENCABEZADO_REPETIDA = "Idempotency-Replayed";

    private final ServicioDeRetiros servicio;
    private final ControlDeAcceso acceso;

    public ControladorDeRetiros(ServicioDeRetiros servicio, ControlDeAcceso acceso) {
        this.servicio = servicio;
        this.acceso = acceso;
    }

    @Operation(summary = "Retiro en cajero, idempotente por Idempotency-Key")
    @PostMapping("/{cuentaId}/retiros")
    public ResponseEntity<OperacionDto> retirar(@PathVariable long cuentaId,
                                                @RequestHeader(value = ENCABEZADO_IDEMPOTENCIA, required = false) String clave,
                                                @RequestHeader(value = ControlDeAcceso.ENCABEZADO_TARJETA, required = false) String tarjetaId,
                                                @RequestHeader(value = ControlDeAcceso.ENCABEZADO_TERMINAL, required = false) String terminalId,
                                                @RequestBody(required = false) SolicitudRetiro solicitud,
                                                Authentication autenticacion) {
        Tarjeta tarjeta = acceso.tarjeta(Canal.desde(autenticacion), tarjetaId, terminalId);
        if (clave == null || clave.length() < 8 || clave.length() > 80) {
            throw Errores.solicitudInvalida("Idempotency-Key es obligatoria y debe tener entre 8 y 80 caracteres");
        }
        ResultadoRetiro resultado = servicio.retirar(cuentaId, tarjeta.getId(), terminalId, clave,
                solicitud == null ? null : solicitud.monto());
        OperacionDto cuerpo = OperacionDto.desde(resultado.operacion());
        if (resultado.repetida()) {
            return ResponseEntity.ok().header(ENCABEZADO_REPETIDA, "true").body(cuerpo);
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(cuerpo);
    }
}
