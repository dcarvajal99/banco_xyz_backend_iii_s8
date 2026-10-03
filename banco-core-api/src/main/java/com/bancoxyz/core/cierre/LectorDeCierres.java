package com.bancoxyz.core.cierre;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import com.bancoxyz.core.error.Errores;
import org.springframework.jdbc.BadSqlGrammarException;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Lee de las tablas del batch que ejecucion esta publicada para cada conjunto.
 *
 * <p>Regla: el mayor job_execution_id presente en la tabla del conjunto cuya ejecucion termino en
 * COMPLETED. Una corrida FAILED nunca se publica aunque haya dejado filas escritas: es exactamente lo
 * que el decisor de calidad de las semanas 2 y 3 quiso impedir.</p>
 *
 * <p>SQL de solo lectura y calificado con {@code public.}: el core nunca escribe en el esquema del batch.</p>
 */
@Repository
public class LectorDeCierres {

    static final String PASO_CUARENTENA_AVISO = "cuarentenaAvisoStep";

    private final JdbcClient jdbc;

    public LectorDeCierres(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    /**
     * @return vacio si no hay ejecucion COMPLETED con filas en el conjunto
     * @throws com.bancoxyz.core.error.ErrorDeNegocio SIN_CIERRE_PUBLICADO si las tablas del batch aun no
     *         existen (base nueva donde el batch nunca corrio)
     */
    public Optional<CierrePublicado> vigente(Conjunto conjunto) {
        String sql = """
                select je.job_execution_id, ji.job_name, je.status, je.end_time,
                       case when exists (select 1 from public.batch_step_execution se
                                          where se.job_execution_id = je.job_execution_id
                                            and se.step_name = :pasoCuarentena)
                            then 'DEGRADADA' else 'ACEPTABLE' end as calidad
                from public.batch_job_execution je
                join public.batch_job_instance ji on ji.job_instance_id = je.job_instance_id
                where je.job_execution_id = (
                    select max(t.job_execution_id)
                    from public.%s t
                    join public.batch_job_execution j2 on j2.job_execution_id = t.job_execution_id
                    where j2.status = 'COMPLETED')
                """.formatted(conjunto.tabla());
        try {
            return jdbc.sql(sql)
                    .param("pasoCuarentena", PASO_CUARENTENA_AVISO)
                    .query((rs, fila) -> new CierrePublicado(conjunto, rs.getLong("job_execution_id"),
                            rs.getString("job_name"), rs.getString("status"), rs.getString("calidad"),
                            rs.getObject("end_time", LocalDateTime.class)))
                    .optional();
        } catch (BadSqlGrammarException tablasInexistentes) {
            throw Errores.sinCierrePublicado();
        }
    }

    public CierrePublicado exigirVigente(Conjunto conjunto) {
        return vigente(conjunto).orElseThrow(Errores::sinCierrePublicado);
    }

    public List<CierrePublicado> vigentes() {
        return Arrays.stream(Conjunto.values()).map(this::vigente).flatMap(Optional::stream).toList();
    }
}
