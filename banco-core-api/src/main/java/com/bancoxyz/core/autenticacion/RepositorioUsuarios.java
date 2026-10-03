package com.bancoxyz.core.autenticacion;

import java.util.Optional;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RepositorioUsuarios extends JpaRepository<Usuario, Long> {

    Optional<Usuario> findByUsuario(String usuario);

    Optional<Usuario> findFirstByClienteId(Long clienteId);

    /**
     * Con la fila bloqueada, N intentos simultaneos se evaluan de a uno. Sin el bloqueo, 50 intentos en
     * paralelo leerian intentos_fallidos = 0 y el tope de 5 no limitaria nada.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select u from Usuario u where u.usuario = :usuario")
    Optional<Usuario> buscarParaActualizar(@Param("usuario") String usuario);
}
