package com.bancoxyz.transferencias.transferencia;

import org.springframework.data.jpa.repository.JpaRepository;

public interface RepositorioEventosProcesados extends JpaRepository<EventoProcesado, String> {
}
