package com.bancoxyz.core;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.GeneralSecurityException;
import java.security.KeyStore;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManagerFactory;

/**
 * PKI efimera de las pruebas, con la misma estructura de carpetas que {@code scripts/generar_certificados.sh}.
 *
 * <p>La crea el keytool del mismo JDK que corre las pruebas: el repositorio no guarda claves privadas ni certificados
 * que venzan. Cada identidad es un certificado EC P-256 autofirmado con SAN localhost/127.0.0.1, y
 * {@code ca/ca.crt} junta los de las identidades legitimas: hace de lista de confianza, igual que la CA del banco en
 * la PKI real. Las identidades que terminan en {@code -intruso} quedan fuera de esa lista.</p>
 */
public final class PkiDePrueba {

    static final List<String> IDENTIDADES = List.of("banco-core-api", "bff-web", "bff-movil", "bff-cajero", "bff-web-intruso",
            "banco-auth", "transferencias-service");

    private static final String CLAVE = "clave-de-prueba";
    private static final Map<String, KeyStore.PrivateKeyEntry> ENTRADAS = new LinkedHashMap<>();
    private static Path raiz;

    private PkiDePrueba() {
    }

    /** Carpeta con servicios/, intruso/ y ca/ca.crt. Se genera una sola vez por JVM. */
    public static synchronized Path raiz() {
        if (raiz == null) {
            try {
                raiz = generar();
            } catch (IOException e) {
                throw new UncheckedIOException(e);
            } catch (GeneralSecurityException | InterruptedException e) {
                throw new IllegalStateException("No se pudo generar la PKI de prueba", e);
            }
        }
        return raiz;
    }

    public static X509Certificate certificado(String identidad) {
        raiz();
        return (X509Certificate) ENTRADAS.get(identidad).getCertificate();
    }

    /** Contexto TLS de un cliente: presenta la identidad indicada (o ninguna si es null) y confia en las legitimas. */
    public static SSLContext contexto(String identidad) {
        raiz();
        try {
            KeyStore llaves = KeyStore.getInstance("PKCS12");
            llaves.load(null, null);
            if (identidad != null) {
                KeyStore.PrivateKeyEntry entrada = ENTRADAS.get(identidad);
                llaves.setKeyEntry("identidad", entrada.getPrivateKey(), CLAVE.toCharArray(), entrada.getCertificateChain());
            }
            KeyStore confianza = KeyStore.getInstance("PKCS12");
            confianza.load(null, null);
            for (Map.Entry<String, KeyStore.PrivateKeyEntry> entrada : ENTRADAS.entrySet()) {
                if (!entrada.getKey().endsWith("-intruso")) {
                    confianza.setCertificateEntry(entrada.getKey(), entrada.getValue().getCertificate());
                }
            }
            KeyManagerFactory kmf = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
            kmf.init(llaves, CLAVE.toCharArray());
            TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
            tmf.init(confianza);
            SSLContext contexto = SSLContext.getInstance("TLS");
            contexto.init(kmf.getKeyManagers(), tmf.getTrustManagers(), null);
            return contexto;
        } catch (IOException | GeneralSecurityException e) {
            throw new IllegalStateException("No se pudo armar el contexto TLS de " + identidad, e);
        }
    }

    private static Path generar() throws IOException, GeneralSecurityException, InterruptedException {
        Path directorio = Files.createTempDirectory("pki-prueba-");
        directorio.toFile().deleteOnExit();
        String keytool = Path.of(System.getProperty("java.home"), "bin",
                System.getProperty("os.name").startsWith("Windows") ? "keytool.exe" : "keytool").toString();
        List<Process> procesos = new ArrayList<>();
        for (String identidad : IDENTIDADES) {
            procesos.add(new ProcessBuilder(keytool, "-genkeypair", "-alias", "identidad", "-keyalg", "EC",
                    "-groupname", "secp256r1", "-sigalg", "SHA256withECDSA", "-validity", "2",
                    "-dname", "CN=" + nombreComun(identidad) + ", O=Banco XYZ Pruebas",
                    "-ext", "SAN=dns:localhost,ip:127.0.0.1",
                    "-keystore", directorio.resolve(identidad + ".p12").toString(), "-storetype", "PKCS12",
                    "-storepass", CLAVE, "-keypass", CLAVE)
                    .redirectErrorStream(true).start());
        }
        for (Process proceso : procesos) {
            if (!proceso.waitFor(60, TimeUnit.SECONDS) || proceso.exitValue() != 0) {
                throw new IllegalStateException("keytool fallo: " + new String(proceso.getInputStream().readAllBytes(), StandardCharsets.UTF_8));
            }
        }
        StringBuilder listaDeConfianza = new StringBuilder();
        for (String identidad : IDENTIDADES) {
            KeyStore almacen = KeyStore.getInstance("PKCS12");
            try (InputStream entrada = Files.newInputStream(directorio.resolve(identidad + ".p12"))) {
                almacen.load(entrada, CLAVE.toCharArray());
            }
            KeyStore.PrivateKeyEntry par = (KeyStore.PrivateKeyEntry) almacen.getEntry("identidad",
                    new KeyStore.PasswordProtection(CLAVE.toCharArray()));
            ENTRADAS.put(identidad, par);
            Path carpeta = directorio.resolve(carpeta(identidad));
            Files.createDirectories(carpeta);
            String certificado = pem("CERTIFICATE", par.getCertificate().getEncoded());
            Files.writeString(carpeta.resolve(identidad + ".crt"), certificado);
            Files.writeString(carpeta.resolve(identidad + ".key"), pem("PRIVATE KEY", par.getPrivateKey().getEncoded()));
            if (!identidad.endsWith("-intruso")) {
                listaDeConfianza.append(certificado);
            }
        }
        Files.createDirectories(directorio.resolve("ca"));
        Files.writeString(directorio.resolve("ca").resolve("ca.crt"), listaDeConfianza);
        return directorio;
    }

    private static String carpeta(String identidad) {
        if (identidad.endsWith("-intruso")) {
            return "intruso";
        }
        return identidad.startsWith("ATM-") ? "terminales" : "servicios";
    }

    private static String nombreComun(String identidad) {
        return identidad.endsWith("-intruso") ? identidad.substring(0, identidad.length() - "-intruso".length()) : identidad;
    }

    private static String pem(String tipo, byte[] der) {
        return "-----BEGIN " + tipo + "-----\n"
                + Base64.getMimeEncoder(64, "\n".getBytes(StandardCharsets.US_ASCII)).encodeToString(der)
                + "\n-----END " + tipo + "-----\n";
    }
}
