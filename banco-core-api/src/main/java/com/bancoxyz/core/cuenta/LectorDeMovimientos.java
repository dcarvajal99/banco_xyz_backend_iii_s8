package com.bancoxyz.core.cuenta;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Movimientos de una cuenta: los del cierre publicado del batch mas los retiros en linea del core.
 *
 * <p>La union y la paginacion se hacen en la base (UNION ALL + LIMIT/OFFSET) y no en memoria: una
 * cuenta real tiene miles de movimientos, y traerlos todos para mostrar 20 no escala.</p>
 */
@Repository
public class LectorDeMovimientos {

    private final JdbcClient jdbc;

    public LectorDeMovimientos(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    public PaginaMovimientos pagina(long cuentaId, long jobExecutionId, int pagina, int tamano) {
        List<MovimientoDto> contenido = jdbc.sql("""
                        select origen, id, cuenta_id, fecha, tipo, monto, descripcion, anomalia, observacion from (
                            select 'CIERRE' as origen, m.id as id, m.cuenta_id as cuenta_id, m.fecha as fecha,
                                   m.tipo_transaccion as tipo, m.monto as monto, m.descripcion as descripcion,
                                   m.anomalia as anomalia, m.observacion as observacion
                            from public.movimiento_anual m
                            where m.cuenta_id = :cuenta and m.job_execution_id = :job
                            union all
                            select 'EN_LINEA', o.id, o.cuenta_id, cast(o.creada_en as date), 'retiro', -o.monto,
                                   concat('Retiro en cajero ', coalesce(o.terminal_id, '')), false,
                                   cast(null as varchar(255))
                            from core.operacion o
                            where o.cuenta_id = :cuenta and o.tipo = 'RETIRO'
                        ) movimientos
                        order by fecha desc, id desc
                        limit :limite offset :desplazamiento
                        """)
                .param("cuenta", cuentaId)
                .param("job", jobExecutionId)
                .param("limite", tamano)
                .param("desplazamiento", (long) pagina * tamano)
                .query((rs, fila) -> {
                    String origen = rs.getString("origen");
                    return new MovimientoDto(("CIERRE".equals(origen) ? "C-" : "L-") + rs.getLong("id"),
                            rs.getLong("cuenta_id"), rs.getObject("fecha", LocalDate.class), rs.getString("tipo"),
                            rs.getBigDecimal("monto"), rs.getString("descripcion"), origen,
                            rs.getBoolean("anomalia"), rs.getString("observacion"));
                })
                .list();
        long total = jdbc.sql("""
                        select (select count(*) from public.movimiento_anual m
                                where m.cuenta_id = :cuenta and m.job_execution_id = :job)
                             + (select count(*) from core.operacion o
                                where o.cuenta_id = :cuenta and o.tipo = 'RETIRO')
                        """)
                .param("cuenta", cuentaId)
                .param("job", jobExecutionId)
                .query(Long.class)
                .single();
        int totalPaginas = (int) ((total + tamano - 1) / tamano);
        return new PaginaMovimientos(contenido, pagina, tamano, total, totalPaginas);
    }

    public List<EstadoAnualDto> estadosAnuales(long cuentaId, long jobExecutionId) {
        return jdbc.sql("""
                        select cuenta_id, anio, cantidad_movimientos, total_depositos, total_cargos, saldo_neto,
                               primera_fecha, ultima_fecha, movimientos_con_anomalia
                        from public.estado_cuenta_anual
                        where cuenta_id = :cuenta and job_execution_id = :job
                        order by anio desc
                        """)
                .param("cuenta", cuentaId)
                .param("job", jobExecutionId)
                .query(EstadoAnualDto.class)
                .list();
    }

    static BigDecimal nulo(BigDecimal valor) {
        return valor == null ? BigDecimal.ZERO : valor;
    }
}
