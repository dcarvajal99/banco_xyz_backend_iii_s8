package com.bancoxyz.core.cierre;

import java.math.BigDecimal;
import java.text.Normalizer;
import java.time.Clock;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

import com.bancoxyz.core.autenticacion.CodificadorDeSecretos;
import com.bancoxyz.core.autenticacion.RepositorioUsuarios;
import com.bancoxyz.core.autenticacion.Usuario;
import com.bancoxyz.core.cliente.Cliente;
import com.bancoxyz.core.cliente.RepositorioClientes;
import com.bancoxyz.core.config.PropiedadesCore;
import com.bancoxyz.core.cuenta.Cuenta;
import com.bancoxyz.core.cuenta.RepositorioCuentas;
import com.bancoxyz.core.error.ErrorDeNegocio;
import com.bancoxyz.core.tarjeta.Luhn;
import com.bancoxyz.core.tarjeta.RepositorioTarjetas;
import com.bancoxyz.core.tarjeta.Tarjeta;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Abre en el esquema {@code core} las cuentas del cierre de intereses publicado.
 *
 * <h2>Por que las cuentas se abren una sola vez</h2>
 * <p>El cierre del batch trae el saldo al cierre; los retiros en linea lo cambian despues. Si cada
 * sincronizacion pisara el saldo con el del cierre, un retiro de la tarde desapareceria al volver a
 * arrancar el core. Por eso una cuenta existente no se toca. Conciliar un cierre nuevo con las
 * operaciones en linea queda fuera del alcance de esta semana (documentado en el README).</p>
 *
 * <h2>Cual fila representa a cada cuenta</h2>
 * <p>{@code intereses.csv} repite cada cuenta muchas veces con titulares y tipos distintos. El batch
 * escribe todas las filas validas y marca a todas menos la primera aparicion con
 * {@link #MARCA_CUENTA_REPETIDA}. La fila canonica es la que no lleva esa marca. Es un acoplamiento
 * con el TEXTO de una constante del batch: si alguien la cambia alla, esta clase deja de reconocer
 * las repetidas. Lo cubre una prueba con el texto literal.</p>
 */
@Component
public class SincronizadorDeCierre {

    /** Texto exacto de {@code Constantes.MSG_CUENTA_REPETIDA} del modulo batch. */
    static final String MARCA_CUENTA_REPETIDA = "La cuenta aparece mas de una vez en el archivo con datos distintos";
    static final String SIN_IDENTIFICAR = "Sin identificar";
    private static final String USUARIO_EJECUTIVO = "ejecutivo";

    private static final Logger log = LoggerFactory.getLogger(SincronizadorDeCierre.class);

    /** Una fila de cuenta_interes del cierre publicado. */
    record FilaInteres(long id, long cuentaId, String nombre, String tipo, BigDecimal saldoFinal,
                       BigDecimal tasaMensual, BigDecimal interes, boolean anomalia, String observacion) {
    }

    private final LectorDeCierres cierres;
    private final JdbcClient jdbc;
    private final RepositorioClientes clientes;
    private final RepositorioCuentas cuentas;
    private final RepositorioUsuarios usuarios;
    private final RepositorioTarjetas tarjetas;
    private final CodificadorDeSecretos codificador;
    private final PropiedadesCore propiedades;
    private final Clock reloj;

    public SincronizadorDeCierre(LectorDeCierres cierres, JdbcClient jdbc, RepositorioClientes clientes,
                                 RepositorioCuentas cuentas, RepositorioUsuarios usuarios,
                                 RepositorioTarjetas tarjetas, CodificadorDeSecretos codificador,
                                 PropiedadesCore propiedades, Clock reloj) {
        this.cierres = cierres;
        this.jdbc = jdbc;
        this.clientes = clientes;
        this.cuentas = cuentas;
        this.usuarios = usuarios;
        this.tarjetas = tarjetas;
        this.codificador = codificador;
        this.propiedades = propiedades;
        this.reloj = reloj;
    }

    @Transactional
    public ResumenSincronizacion sincronizar() {
        Optional<CierrePublicado> vigente;
        try {
            vigente = cierres.vigente(Conjunto.INTERESES);
        } catch (ErrorDeNegocio tablasDelBatchInexistentes) {
            log.warn("Sin cierre publicado: las tablas del batch todavia no existen. Ejecute el batch y reinicie el core.");
            return ResumenSincronizacion.sinCierre();
        }
        if (vigente.isEmpty()) {
            log.warn("Sin cierre publicado: no hay una ejecucion COMPLETED de intereses.");
            return ResumenSincronizacion.sinCierre();
        }
        CierrePublicado cierre = vigente.get();
        LocalDateTime ahora = LocalDateTime.now(reloj).truncatedTo(ChronoUnit.SECONDS);

        List<FilaInteres> filas = jdbc.sql("""
                        select id, cuenta_id, nombre, tipo, saldo_final, tasa_mensual, interes, anomalia, observacion
                        from public.cuenta_interes
                        where job_execution_id = :job
                        order by cuenta_id, id
                        """)
                .param("job", cierre.jobExecutionId())
                .query(FilaInteres.class)
                .list();

        int clientesNuevos = 0;
        int cuentasNuevas = 0;
        int cuentasExistentes = 0;
        Map<String, Cliente> clientesPorNombre = new LinkedHashMap<>();
        for (FilaInteres fila : canonicas(filas).values()) {
            Cliente cliente = null;
            if (!SIN_IDENTIFICAR.equalsIgnoreCase(fila.nombre())) {
                cliente = clientesPorNombre.get(fila.nombre());
                if (cliente == null) {
                    Optional<Cliente> existente = clientes.findByNombre(fila.nombre());
                    if (existente.isEmpty()) {
                        clientesNuevos++;
                    }
                    cliente = existente.orElseGet(() -> clientes.save(new Cliente(fila.nombre(), ahora)));
                    clientesPorNombre.put(fila.nombre(), cliente);
                }
            }
            if (cuentas.existsById(fila.cuentaId())) {
                cuentasExistentes++;
                continue;
            }
            cuentas.save(new Cuenta(fila.cuentaId(), cliente == null ? null : cliente.getId(), fila.nombre(),
                    fila.tipo(), fila.saldoFinal(), fila.tasaMensual(), fila.interes(), fila.anomalia(),
                    fila.observacion(), cierre.jobExecutionId(), ahora));
            cuentasNuevas++;
        }

        int usuariosNuevos = 0;
        int tarjetasNuevas = 0;
        List<String> credenciales = new ArrayList<>();
        if (propiedades.datosDemo().habilitados()) {
            for (Cliente cliente : clientes.findAll()) {
                String nombreUsuario = nombreDeUsuario(cliente.getNombre());
                if (usuarios.findByUsuario(nombreUsuario).isEmpty()) {
                    usuarios.save(Usuario.cliente(nombreUsuario, codificador.cifrar(propiedades.datosDemo().claveClientes()),
                            cliente.getId()));
                    usuariosNuevos++;
                }
                credenciales.add("  usuario %-16s cliente %s".formatted(nombreUsuario, cliente.getNombre()));
            }
            if (usuarios.findByUsuario(USUARIO_EJECUTIVO).isEmpty()) {
                usuarios.save(Usuario.ejecutivo(USUARIO_EJECUTIVO,
                        codificador.cifrar(propiedades.datosDemo().claveEjecutivo())));
                usuariosNuevos++;
            }
            credenciales.add("  usuario %-16s ejecutivo (consola web)".formatted(USUARIO_EJECUTIVO));
            for (Cuenta cuenta : cuentas.findAll()) {
                if (!cuenta.esAhorro() || cuenta.getClienteId() == null) {
                    continue;
                }
                String pan = numeroDeTarjeta(cuenta.getId());
                if (tarjetas.findByCuentaId(cuenta.getId()).isEmpty()) {
                    tarjetas.save(new Tarjeta(codificador.huellaDeTarjeta(pan), pan.substring(12), cuenta.getId(),
                            codificador.cifrar(propiedades.datosDemo().pin()), propiedades.cajero().limiteDiario()));
                    tarjetasNuevas++;
                }
                credenciales.add("  tarjeta %s cuenta %d %-14s saldo %s".formatted(pan, cuenta.getId(),
                        cuenta.getTitular(), cuenta.getSaldoDisponible().toPlainString()));
            }
        }

        ResumenSincronizacion resumen = new ResumenSincronizacion(true, cierre.jobExecutionId(), cierre.calidad(),
                cuentasNuevas, cuentasExistentes, clientesNuevos, usuariosNuevos, tarjetasNuevas);
        log.info("Cierre publicado de INTERESES: ejecucion {} ({}), calidad {}", cierre.jobExecutionId(),
                cierre.jobNombre(), cierre.calidad());
        log.info("Sincronizacion: {} cuentas nuevas, {} existentes sin tocar | {} clientes nuevos (total {}) | "
                        + "{} usuarios nuevos | {} tarjetas nuevas (total {})", cuentasNuevas, cuentasExistentes,
                clientesNuevos, clientes.count(), usuariosNuevos, tarjetasNuevas, tarjetas.count());
        if (!credenciales.isEmpty()) {
            log.info("Credenciales de demostracion (claves y PIN en el README):\n{}", String.join("\n", credenciales));
        }
        return resumen;
    }

    /** Una fila por cuenta: la primera sin la marca de repetida o, si no hubiera, la de menor id. */
    static Map<Long, FilaInteres> canonicas(List<FilaInteres> filas) {
        Map<Long, FilaInteres> elegidas = new LinkedHashMap<>();
        Map<Long, FilaInteres> respaldo = new LinkedHashMap<>();
        for (FilaInteres fila : filas) {
            respaldo.merge(fila.cuentaId(), fila, (a, b) -> a.id() <= b.id() ? a : b);
            boolean repetida = fila.observacion() != null && fila.observacion().contains(MARCA_CUENTA_REPETIDA);
            if (!repetida) {
                elegidas.merge(fila.cuentaId(), fila, (a, b) -> a.id() <= b.id() ? a : b);
            }
        }
        respaldo.forEach(elegidas::putIfAbsent);
        Map<Long, FilaInteres> ordenadas = new LinkedHashMap<>();
        elegidas.keySet().stream().sorted().forEach(id -> ordenadas.put(id, elegidas.get(id)));
        return ordenadas;
    }

    /** "Diana Prince" -> "diana.prince". */
    static String nombreDeUsuario(String nombre) {
        String sinTildes = Normalizer.normalize(nombre, Normalizer.Form.NFD).replaceAll("\\p{M}", "");
        return sinTildes.trim().toLowerCase(Locale.ROOT).replaceAll("\\s+", ".").replaceAll("[^a-z0-9.]", "");
    }

    /** PAN de demostracion: 4 + cuenta con 14 digitos + digito Luhn (cuenta 101 -> 4000000000001018). */
    public static String numeroDeTarjeta(long cuentaId) {
        return Luhn.conDigitoVerificador("4" + String.format("%014d", cuentaId));
    }
}
