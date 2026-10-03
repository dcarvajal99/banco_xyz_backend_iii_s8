package com.bancoxyz.core.reporte;

import java.time.LocalDate;
import java.util.List;

import com.bancoxyz.core.autenticacion.Usuario;
import com.bancoxyz.core.seguridad.Canal;
import com.bancoxyz.core.seguridad.ControlDeAcceso;
import io.swagger.v3.oas.annotations.Operation;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Reportes del cierre para la consola del ejecutivo (canal web). */
@RestController
@RequestMapping("/api/v1/reportes")
public class ControladorDeReportes {

    private final LectorDeReportes lector;
    private final ControlDeAcceso acceso;

    public ControladorDeReportes(LectorDeReportes lector, ControlDeAcceso acceso) {
        this.lector = lector;
        this.acceso = acceso;
    }

    @Operation(summary = "Resumen diario de transacciones del cierre publicado")
    @GetMapping("/resumen-diario")
    public List<ResumenDiarioDto> resumenDiario(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate desde,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate hasta,
            @RequestHeader(value = ControlDeAcceso.ENCABEZADO_USUARIO, required = false) String usuarioId,
            Authentication autenticacion) {
        exigirEjecutivo(usuarioId, autenticacion);
        return lector.resumenDiario(desde, hasta);
    }

    @Operation(summary = "Calidad de los cierres publicados y filas rechazadas")
    @GetMapping("/calidad")
    public CalidadDto calidad(@RequestHeader(value = ControlDeAcceso.ENCABEZADO_USUARIO, required = false) String usuarioId,
                              Authentication autenticacion) {
        exigirEjecutivo(usuarioId, autenticacion);
        return lector.calidad();
    }

    private void exigirEjecutivo(String usuarioId, Authentication autenticacion) {
        Usuario usuario = acceso.usuario(Canal.desde(autenticacion), usuarioId);
        acceso.exigirEjecutivo(usuario);
    }
}
