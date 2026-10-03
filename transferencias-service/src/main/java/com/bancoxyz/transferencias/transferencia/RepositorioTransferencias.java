package com.bancoxyz.transferencias.transferencia;

import java.util.Optional;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RepositorioTransferencias extends JpaRepository<Transferencia, String> {

    Optional<Transferencia> findByClienteIdAndClaveIdempotencia(Long clienteId, String claveIdempotencia);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select t from Transferencia t where t.id = :id")
    Optional<Transferencia> buscarParaActualizar(@Param("id") String id);
}
