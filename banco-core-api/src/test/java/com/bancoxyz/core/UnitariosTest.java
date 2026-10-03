package com.bancoxyz.core;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Map;

import com.bancoxyz.core.tarjeta.Luhn;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

class UnitariosTest {

    @Test
    @DisplayName("Luhn: calcula y valida el digito verificador")
    void luhn() {
        assertThat(Luhn.conDigitoVerificador("400000000000101")).isEqualTo("4000000000001018");
        assertThat(Luhn.esValido("4000000000001018")).isTrue();
        assertThat(Luhn.esValido("4000000000001019")).isFalse();
        assertThat(Luhn.esValido("4111111111111111")).isTrue();
        assertThat(Luhn.esValido("12ab")).isFalse();
        assertThat(Luhn.esValido(null)).isFalse();
    }

    @Test
    @DisplayName("Nombre de usuario sin tildes, en minusculas y con punto")
    void nombreDeUsuario() {
        assertThat(com.bancoxyz.core.cierre.AccesoParaPruebas.nombreDeUsuario("José  Pérez")).isEqualTo("jose.perez");
        assertThat(com.bancoxyz.core.cierre.AccesoParaPruebas.nombreDeUsuario("Diana Prince")).isEqualTo("diana.prince");
    }

    @Test
    @DisplayName("Fila canonica: si todas llevan la marca de repetida, se usa la de menor id")
    void canonicaDeRespaldo() {
        Map<Long, String> titulares = com.bancoxyz.core.cierre.AccesoParaPruebas.titularesCanonicosTodasRepetidas();
        assertThat(titulares).containsEntry(200L, "Primera");
    }

    @Test
    @DisplayName("Codigo por estado para los errores propios de Spring MVC")
    void codigoPorEstado() {
        assertThat(com.bancoxyz.core.error.AccesoParaPruebasDeErrores.codigo(HttpStatus.NOT_FOUND)).isEqualTo("RECURSO_NO_ENCONTRADO");
        assertThat(com.bancoxyz.core.error.AccesoParaPruebasDeErrores.codigo(HttpStatus.METHOD_NOT_ALLOWED)).isEqualTo("METODO_NO_PERMITIDO");
        assertThat(com.bancoxyz.core.error.AccesoParaPruebasDeErrores.codigo(HttpStatus.UNSUPPORTED_MEDIA_TYPE)).isEqualTo("SOLICITUD_INVALIDA");
        assertThat(com.bancoxyz.core.error.AccesoParaPruebasDeErrores.codigo(HttpStatus.BAD_GATEWAY)).isEqualTo("ERROR_INTERNO");
    }
}
