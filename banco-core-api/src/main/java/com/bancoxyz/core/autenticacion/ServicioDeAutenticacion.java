package com.bancoxyz.core.autenticacion;

import java.time.Clock;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Optional;

import com.bancoxyz.core.seguridad.Canal;
import com.bancoxyz.core.tarjeta.RepositorioTarjetas;
import com.bancoxyz.core.tarjeta.Tarjeta;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Verifica credenciales de usuario y de tarjeta.
 *
 * <h2>Por que devuelve un resultado y no lanza excepciones</h2>
 * <p>Un intento fallido tiene que QUEDAR REGISTRADO aunque la respuesta sea un error. Si el servicio
 * lanzara una excepcion de negocio, la transaccion se revertiria y el contador de intentos volveria a
 * cero: bastaria con fallar una y otra vez para no bloquear nunca. Por eso el servicio confirma la
 * transaccion y el controlador traduce el resultado a 401 o 423 despues.</p>
 *
 * <h2>Por que el bloqueo de PIN vive aqui y no en el BFF del cajero</h2>
 * <p>Si viviera en el BFF, bastaria con cambiar de cajero para seguir probando PIN. En el core el
 * contador es uno solo por tarjeta, venga el intento desde el terminal que venga.</p>
 */
@Service
public class ServicioDeAutenticacion {

    static final int MAXIMO_INTENTOS_USUARIO = 5;
    static final Duration DURACION_BLOQUEO_USUARIO = Duration.ofMinutes(15);
    static final int MAXIMO_INTENTOS_PIN = 3;

    public enum EstadoUsuario { AUTENTICADO, CREDENCIALES_INVALIDAS, BLOQUEADO, ROL_NO_PERMITIDO }

    public record ResultadoUsuario(EstadoUsuario estado, Usuario usuario) {
    }

    public enum EstadoTarjeta { AUTENTICADA, TARJETA_INVALIDA, PIN_INCORRECTO, BLOQUEADA }

    public record ResultadoTarjeta(EstadoTarjeta estado, Tarjeta tarjeta, int intentosRestantes) {
    }

    private final RepositorioUsuarios usuarios;
    private final RepositorioTarjetas tarjetas;
    private final CodificadorDeSecretos codificador;
    private final Clock reloj;

    public ServicioDeAutenticacion(RepositorioUsuarios usuarios, RepositorioTarjetas tarjetas,
                                   CodificadorDeSecretos codificador, Clock reloj) {
        this.usuarios = usuarios;
        this.tarjetas = tarjetas;
        this.codificador = codificador;
        this.reloj = reloj;
    }

    @Transactional
    public ResultadoUsuario autenticarUsuario(Canal canal, String nombreUsuario, String clave) {
        Optional<Usuario> encontrado = usuarios.buscarParaActualizar(nombreUsuario);
        if (encontrado.isEmpty() || !encontrado.get().isActivo()) {
            codificador.verificarContraFicticio(clave);
            return new ResultadoUsuario(EstadoUsuario.CREDENCIALES_INVALIDAS, null);
        }
        Usuario usuario = encontrado.get();
        LocalDateTime ahora = LocalDateTime.now(reloj);
        // Con un bloqueo vigente la clave ni se evalua: si no, un atacante sabria cuando acerto.
        if (usuario.bloqueadoEn(ahora)) {
            return new ResultadoUsuario(EstadoUsuario.BLOQUEADO, usuario);
        }
        usuario.liberarBloqueoVencido(ahora);
        if (!codificador.coincide(clave, usuario.getPasswordHash())) {
            usuario.registrarFallo(ahora, MAXIMO_INTENTOS_USUARIO, DURACION_BLOQUEO_USUARIO);
            return new ResultadoUsuario(usuario.bloqueadoEn(ahora) ? EstadoUsuario.BLOQUEADO
                    : EstadoUsuario.CREDENCIALES_INVALIDAS, usuario);
        }
        usuario.registrarExito();
        // banco-auth emite tokens para transferir entre cuentas propias: como el movil, es solo para clientes.
        if ((canal == Canal.MOVIL || canal == Canal.AUTENTICACION) && usuario.esEjecutivo()) {
            return new ResultadoUsuario(EstadoUsuario.ROL_NO_PERMITIDO, usuario);
        }
        return new ResultadoUsuario(EstadoUsuario.AUTENTICADO, usuario);
    }

    @Transactional
    public ResultadoTarjeta autenticarTarjeta(String numero, String pin) {
        Optional<Tarjeta> encontrada = tarjetas.buscarPorHuellaParaActualizar(codificador.huellaDeTarjeta(numero));
        if (encontrada.isEmpty()) {
            codificador.verificarContraFicticio(pin);
            return new ResultadoTarjeta(EstadoTarjeta.TARJETA_INVALIDA, null, 0);
        }
        Tarjeta tarjeta = encontrada.get();
        if (tarjeta.isBloqueada()) {
            return new ResultadoTarjeta(EstadoTarjeta.BLOQUEADA, tarjeta, 0);
        }
        if (codificador.coincide(pin, tarjeta.getPinHash())) {
            tarjeta.registrarExito();
            return new ResultadoTarjeta(EstadoTarjeta.AUTENTICADA, tarjeta, MAXIMO_INTENTOS_PIN);
        }
        tarjeta.registrarFallo(MAXIMO_INTENTOS_PIN);
        if (tarjeta.isBloqueada()) {
            return new ResultadoTarjeta(EstadoTarjeta.BLOQUEADA, tarjeta, 0);
        }
        return new ResultadoTarjeta(EstadoTarjeta.PIN_INCORRECTO, tarjeta,
                MAXIMO_INTENTOS_PIN - tarjeta.getIntentosFallidos());
    }
}
