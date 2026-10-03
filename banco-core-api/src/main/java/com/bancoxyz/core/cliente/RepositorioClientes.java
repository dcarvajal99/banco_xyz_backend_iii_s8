package com.bancoxyz.core.cliente;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface RepositorioClientes extends JpaRepository<Cliente, Long> {

    Optional<Cliente> findByNombre(String nombre);

    List<Cliente> findAllByOrderByNombreAsc();
}
