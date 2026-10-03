package com.bancoxyz.core.transferencia;

import java.util.Optional;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RepositorioReservas extends JpaRepository<Reserva, String> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from Reserva r where r.transferenciaId = :id")
    Optional<Reserva> buscarParaActualizar(@Param("id") String transferenciaId);
}
