package com.bancoxyz.core.tarjeta;

/** Digito verificador de Luhn, el que usan los numeros de tarjeta. */
public final class Luhn {

    private Luhn() {
    }

    public static String conDigitoVerificador(String sinVerificador) {
        return sinVerificador + digito(sinVerificador);
    }

    public static boolean esValido(String numero) {
        if (numero == null || !numero.matches("\\d{2,19}")) {
            return false;
        }
        return digito(numero.substring(0, numero.length() - 1)) == numero.charAt(numero.length() - 1) - '0';
    }

    private static int digito(String sinVerificador) {
        int suma = 0;
        boolean doblar = true;
        for (int i = sinVerificador.length() - 1; i >= 0; i--) {
            int n = sinVerificador.charAt(i) - '0';
            if (doblar) {
                n *= 2;
                if (n > 9) {
                    n -= 9;
                }
            }
            suma += n;
            doblar = !doblar;
        }
        return (10 - suma % 10) % 10;
    }
}
