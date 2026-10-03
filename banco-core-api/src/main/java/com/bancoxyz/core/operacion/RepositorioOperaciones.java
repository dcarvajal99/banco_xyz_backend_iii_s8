package com.bancoxyz.core.operacion;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RepositorioOperaciones extends JpaRepository<Operacion, Long> {

    Optional<Operacion> findByCanalAndClaveIdempotencia(String canal, String claveIdempotencia);

    @Query("""
            select coalesce(sum(o.monto), 0) from Operacion o
            where o.tarjetaId = :tarjeta and o.tipo = 'RETIRO' and o.creadaEn >= :desde
            """)
    BigDecimal sumarRetirosDesde(@Param("tarjeta") Long tarjetaId, @Param("desde") LocalDateTime desde);
}
