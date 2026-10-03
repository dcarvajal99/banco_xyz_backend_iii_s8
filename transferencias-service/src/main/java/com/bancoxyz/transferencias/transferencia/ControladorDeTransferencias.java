package com.bancoxyz.transferencias.transferencia;

import java.net.URI;

import com.bancoxyz.transferencias.seguridad.UsuarioDelToken;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@Validated
@RequestMapping("/api/v1/transferencias")
public class ControladorDeTransferencias {

    private final ServicioDeTransferencias servicio;

    public ControladorDeTransferencias(ServicioDeTransferencias servicio) {
        this.servicio = servicio;
    }

    /**
     * 202 Accepted: la transferencia quedo registrada y la saga la procesa en segundo plano. El estado final se consulta
     * en la URL de Location. Un reintento con la misma Idempotency-Key devuelve la misma transferencia (200).
     */
    @PostMapping
    public ResponseEntity<TransferenciaDto> solicitar(@AuthenticationPrincipal Jwt jwt,
                                                      @RequestHeader("Idempotency-Key") @NotBlank @Size(max = 80) String clave,
                                                      @Valid @RequestBody SolicitudTransferencia solicitud) {
        ServicioDeTransferencias.Resultado resultado = servicio.solicitar(UsuarioDelToken.desde(jwt), solicitud, clave);
        URI ubicacion = URI.create("/api/v1/transferencias/" + resultado.transferencia().id());
        if (resultado.repetida()) {
            return ResponseEntity.ok().location(ubicacion).header("Idempotency-Replayed", "true").body(resultado.transferencia());
        }
        return ResponseEntity.accepted().location(ubicacion).body(resultado.transferencia());
    }

    @GetMapping("/{id}")
    public TransferenciaDto consultar(@AuthenticationPrincipal Jwt jwt, @PathVariable String id) {
        return servicio.consultar(UsuarioDelToken.desde(jwt), id);
    }
}
