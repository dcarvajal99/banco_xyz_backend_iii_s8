package com.bancoxyz.transferencias.config;

import com.bancoxyz.transferencias.transferencia.ErrorDeTransferencia;
import jakarta.validation.ConstraintViolationException;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.HandlerMethodValidationException;

/** Errores en el formato del banco: ProblemDetail con {@code codigo}. */
@RestControllerAdvice
@Order(Ordered.HIGHEST_PRECEDENCE)
public class ManejadorDeErrores {

    @ExceptionHandler(ErrorDeTransferencia.class)
    public ProblemDetail deNegocio(ErrorDeTransferencia error) {
        return problema(error.getEstado(), error.getCodigo(), error.getMessage());
    }

    @ExceptionHandler({MethodArgumentNotValidException.class, HandlerMethodValidationException.class,
            ConstraintViolationException.class})
    public ProblemDetail invalida(Exception error) {
        return problema(HttpStatus.BAD_REQUEST, "SOLICITUD_INVALIDA",
                "Cuentas de origen y destino y un monto positivo con hasta 2 decimales son obligatorios");
    }

    @ExceptionHandler(MissingRequestHeaderException.class)
    public ProblemDetail sinClave(MissingRequestHeaderException error) {
        return problema(HttpStatus.BAD_REQUEST, "IDEMPOTENCY_KEY_REQUERIDA",
                "Toda transferencia lleva el encabezado Idempotency-Key: un reintento con la misma clave no la duplica");
    }

    private static ProblemDetail problema(HttpStatus estado, String codigo, String detalle) {
        ProblemDetail problema = ProblemDetail.forStatusAndDetail(estado, detalle);
        problema.setProperty("codigo", codigo);
        return problema;
    }
}
