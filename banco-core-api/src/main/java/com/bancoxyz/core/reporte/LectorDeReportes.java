package com.bancoxyz.core.reporte;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import com.bancoxyz.core.cierre.CierrePublicado;
import com.bancoxyz.core.cierre.Conjunto;
import com.bancoxyz.core.cierre.LectorDeCierres;
import com.bancoxyz.core.error.Errores;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class LectorDeReportes {

    private final JdbcClient jdbc;
    private final LectorDeCierres cierres;

    public LectorDeReportes(JdbcClient jdbc, LectorDeCierres cierres) {
        this.jdbc = jdbc;
        this.cierres = cierres;
    }

    public List<ResumenDiarioDto> resumenDiario(LocalDate desde, LocalDate hasta) {
        long job = cierres.exigirVigente(Conjunto.TRANSACCIONES).jobExecutionId();
        // Las condiciones opcionales se agregan al texto y no con ":desde is null": PostgreSQL no puede
        // inferir el tipo de un parametro que solo aparece comparado con null.
        StringBuilder sql = new StringBuilder("""
                select fecha, cantidad_transacciones, total_debitos, total_creditos, monto_maximo,
                       cantidad_anomalias, job_execution_id
                from public.resumen_diario
                where job_execution_id = :job
                """);
        if (desde != null) {
            sql.append(" and fecha >= :desde");
        }
        if (hasta != null) {
            sql.append(" and fecha <= :hasta");
        }
        sql.append(" order by fecha");
        JdbcClient.StatementSpec consulta = jdbc.sql(sql.toString()).param("job", job);
        if (desde != null) {
            consulta = consulta.param("desde", desde);
        }
        if (hasta != null) {
            consulta = consulta.param("hasta", hasta);
        }
        return consulta.query(ResumenDiarioDto.class).list();
    }

    /**
     * Rechazados del cierre vigente de cada conjunto. Se filtra por (ejecucion, archivo) y no por nombre de
     * job: en un cierre completo el batch guarda el nombre del job INDIVIDUAL de cada archivo.
     */
    public CalidadDto calidad() {
        List<CierrePublicado> vigentes = cierres.vigentes();
        if (vigentes.isEmpty()) {
            throw Errores.sinCierrePublicado();
        }
        List<RechazadoDto> rechazados = new ArrayList<>();
        for (CierrePublicado cierre : vigentes) {
            rechazados.addAll(jdbc.sql("""
                            select job_nombre, clasificacion, count(*) as cantidad
                            from public.registro_rechazado
                            where job_execution_id = :job and archivo = :archivo
                            group by job_nombre, clasificacion
                            order by job_nombre, clasificacion
                            """)
                    .param("job", cierre.jobExecutionId())
                    .param("archivo", cierre.conjunto().archivo())
                    .query(RechazadoDto.class)
                    .list());
        }
        return new CalidadDto(vigentes, rechazados);
    }
}
