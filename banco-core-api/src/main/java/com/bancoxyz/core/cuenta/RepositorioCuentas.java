package com.bancoxyz.core.cuenta;

import java.util.List;
import java.util.Optional;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RepositorioCuentas extends JpaRepository<Cuenta, Long> {

    /**
     * SELECT ... FOR UPDATE sobre la cuenta. Dos retiros sobre la misma cuenta se ejecutan uno despues
     * del otro aunque lleguen desde cajeros distintos.
     *
     * <p>No lleva el hint jakarta.persistence.lock.timeout: Hibernate 6.6 lo ignora en PostgreSQL y en
     * H2. El limite de espera se fija por conexion (connection-init-sql).</p>
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select c from Cuenta c where c.id = :id")
    Optional<Cuenta> buscarParaActualizar(@Param("id") long id);

    List<Cuenta> findByClienteIdOrderByIdAsc(Long clienteId);

    long countByClienteId(Long clienteId);
}
