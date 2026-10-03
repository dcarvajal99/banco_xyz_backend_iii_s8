package com.bancoxyz.core.tarjeta;

import java.util.List;
import java.util.Optional;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RepositorioTarjetas extends JpaRepository<Tarjeta, Long> {

    /** Fila bloqueada: los intentos de PIN simultaneos desde varios cajeros se cuentan todos. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select t from Tarjeta t where t.numeroHash = :huella")
    Optional<Tarjeta> buscarPorHuellaParaActualizar(@Param("huella") String huella);

    List<Tarjeta> findByCuentaId(Long cuentaId);
}
