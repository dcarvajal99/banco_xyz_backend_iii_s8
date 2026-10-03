package com.bancoxyz.transferencias.transferencia;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface RepositorioHistorial extends JpaRepository<PasoDelHistorial, Long> {

    List<PasoDelHistorial> findByTransferenciaIdOrderByIdAsc(String transferenciaId);
}
