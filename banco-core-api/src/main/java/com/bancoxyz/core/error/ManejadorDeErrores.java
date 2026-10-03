package com.bancoxyz.core.error;

import java.net.URI;

import jakarta.persistence.LockTimeoutException;
import jakarta.persistence.PessimisticLockException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.PessimisticLockingFailureException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.MediaType;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.lang.Nullable;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.ServletWebRequest;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import com.bancoxyz.core.config.FiltroCorrelacion;
import org.slf4j.MDC;

/**
 * Traduce toda excepcion a un ProblemDetail con {@code codigo} y {@code correlacionId}.
 *
 * <p>Extiende {@link ResponseEntityExceptionHandler} para cubrir los errores propios de Spring MVC
 * (cuerpo ilegible, validacion, metodo no soportado) y sobrescribe {@code createResponseEntity}
 * para que tambien esos lleven el codigo: un BFF que recibe un error sin codigo no sabe traducirlo.</p>
 */
@RestControllerAdvice
public class ManejadorDeErrores extends ResponseEntityExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(ManejadorDeErrores.class);

    @ExceptionHandler(ErrorDeNegocio.class)
    public ResponseEntity<Object> negocio(ErrorDeNegocio ex, HttpServletRequest request) {
        ProblemDetail problema = Problemas.crear(ex.getEstado(), ex.getCodigo(), ex.getTitulo(), ex.getMessage(),
                request.getRequestURI());
        ex.getExtras().forEach(problema::setProperty);
        return responder(problema);
    }

    /**
     * La unica restriccion de unicidad que una solicitud puede violar es
     * {@code unique(canal, clave_idempotencia)} de los retiros.
     *
     * <p>No se captura dentro del servicio: en PostgreSQL la transaccion queda abortada tras la
     * violacion, asi que ya no se puede releer ni confirmar nada. Se deja revertir completa (sin
     * descuento) y se responde aqui. Como el servicio bloquea la cuenta antes de mirar la clave, dos
     * reintentos sobre la MISMA cuenta nunca llegan a esta restriccion: si salta, la clave se reuso
     * para otra cuenta, y eso es un conflicto.</p>
     */
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Object> integridad(DataIntegrityViolationException ex, HttpServletRequest request) {
        log.warn("Violacion de integridad traducida a IDEMPOTENCIA_CONFLICTO: {}", ex.getMostSpecificCause().getMessage());
        return negocio(Errores.idempotenciaConflicto(), request);
    }

    /** El bloqueo de la cuenta no se obtuvo dentro del lock_timeout: no se desconto nada. */
    @ExceptionHandler({PessimisticLockingFailureException.class, LockTimeoutException.class,
            PessimisticLockException.class})
    public ResponseEntity<Object> bloqueo(RuntimeException ex, HttpServletRequest request) {
        log.warn("No se obtuvo el bloqueo de la cuenta a tiempo: {}", ex.getMessage());
        return negocio(Errores.cuentaOcupada(), request);
    }

    @ExceptionHandler({MethodArgumentTypeMismatchException.class, ConstraintViolationException.class})
    public ResponseEntity<Object> parametroInvalido(RuntimeException ex, HttpServletRequest request) {
        return negocio(Errores.solicitudInvalida("Parametro invalido"), request);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Object> inesperado(Exception ex, HttpServletRequest request) {
        log.error("Error no controlado en {}", request.getRequestURI(), ex);
        ProblemDetail problema = Problemas.crear(HttpStatus.INTERNAL_SERVER_ERROR, "ERROR_INTERNO", "Error interno",
                "Error interno del servicio", request.getRequestURI());
        return responder(problema);
    }

    @Override
    protected ResponseEntity<Object> createResponseEntity(@Nullable Object body, HttpHeaders headers,
                                                          HttpStatusCode statusCode, WebRequest request) {
        if (body instanceof ProblemDetail problema) {
            String codigo = codigoPorEstado(statusCode);
            problema.setType(URI.create("urn:bancoxyz:problema:" + codigo.toLowerCase().replace('_', '-')));
            problema.setProperty("codigo", codigo);
            problema.setProperty("correlacionId", MDC.get(FiltroCorrelacion.CLAVE_MDC));
            if (problema.getInstance() == null && request instanceof ServletWebRequest servlet) {
                problema.setInstance(URI.create(servlet.getRequest().getRequestURI()));
            }
            if (problema.getDetail() == null) {
                problema.setDetail(problema.getTitle());
            }
        }
        return super.createResponseEntity(body, headers, statusCode, request);
    }

    static String codigoPorEstado(HttpStatusCode estado) {
        if (estado.value() == 404) {
            return "RECURSO_NO_ENCONTRADO";
        }
        if (estado.value() == 405) {
            return "METODO_NO_PERMITIDO";
        }
        return estado.is5xxServerError() ? "ERROR_INTERNO" : "SOLICITUD_INVALIDA";
    }

    private static ResponseEntity<Object> responder(ProblemDetail problema) {
        return ResponseEntity.status(problema.getStatus()).contentType(MediaType.APPLICATION_PROBLEM_JSON).body(problema);
    }
}
