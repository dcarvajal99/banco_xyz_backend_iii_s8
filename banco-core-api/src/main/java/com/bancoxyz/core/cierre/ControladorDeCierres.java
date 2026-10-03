package com.bancoxyz.core.cierre;

import java.util.List;

import com.bancoxyz.core.error.Errores;
import io.swagger.v3.oas.annotations.Operation;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/cierres")
public class ControladorDeCierres {

    private final LectorDeCierres lector;

    public ControladorDeCierres(LectorDeCierres lector) {
        this.lector = lector;
    }

    @Operation(summary = "Ejecuciones del batch publicadas por conjunto de datos")
    @GetMapping("/vigentes")
    public List<CierrePublicado> vigentes() {
        List<CierrePublicado> cierres = lector.vigentes();
        if (cierres.isEmpty()) {
            throw Errores.sinCierrePublicado();
        }
        return cierres;
    }
}
