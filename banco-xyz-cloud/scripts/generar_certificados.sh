#!/usr/bin/env bash
# Genera la PKI de DESARROLLO del Banco XYZ con openssl:
#   ca/ca.crt                 CA propia (EC P-256) que firma todo lo demas
#   ca/truststore.p12         la CA en un almacen PKCS12, para los clientes Java del Config Server
#   servicios/<servicio>.*    un certificado por servicio, valido como servidor Y como cliente (mTLS), en PEM y en
#                             PKCS12 (<servicio>.p12, para el cliente del Config Server). Nombres alternativos: el
#                             nombre del servicio en docker-compose (red interna) y localhost (pruebas desde el equipo)
#   intruso/                  una CA ajena y un certificado "transferencias-service" firmado por ella (pruebas negativas)
# Clave de los almacenes PKCS12: BANCO_ALMACEN_CLAVE (por defecto almacen-dev).
#
# Las claves privadas NO se versionan: la carpeta certificados/ esta en .gitignore y se regenera con este script.
# Uso: scripts/generar_certificados.sh [directorio]   (por defecto ./certificados)
set -euo pipefail
if [ "${1:-}" = "-h" ]; then sed -n '2,10p' "$0"; exit 0; fi

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:-$RAIZ/certificados}"
DIAS=825
mkdir -p "$DIR/ca" "$DIR/servicios" "$DIR/intruso"
ALMACEN="${BANCO_ALMACEN_CLAVE:-almacen-dev}"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

clave() { openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "$1" 2>/dev/null; chmod 600 "$1"; }

crear_ca() { # crear_ca DESTINO NOMBRE
  clave "$1.key"
  openssl req -x509 -new -key "$1.key" -sha256 -days 3650 -subj "/C=CL/O=Banco XYZ/OU=Seguridad/CN=$2" \
    -addext "basicConstraints=critical,CA:TRUE,pathlen:0" -addext "keyUsage=critical,keyCertSign,cRLSign" \
    -out "$1.crt" 2>/dev/null
}

emitir() { # emitir CA DESTINO CN USOS [SAN]
  local ca="$1" destino="$2" cn="$3" usos="$4" san="${5:-}"
  clave "$destino.key"
  openssl req -new -key "$destino.key" -subj "/C=CL/O=Banco XYZ/OU=$(basename "$(dirname "$destino")")/CN=$cn" -out "$TMP/solicitud.csr" 2>/dev/null
  {
    echo "basicConstraints=critical,CA:FALSE"
    echo "keyUsage=critical,digitalSignature"
    echo "extendedKeyUsage=$usos"
    [ -n "$san" ] && echo "subjectAltName=$san"
  } > "$TMP/extensiones.cnf"
  openssl x509 -req -in "$TMP/solicitud.csr" -CA "$ca.crt" -CAkey "$ca.key" -CAcreateserial -days "$DIAS" -sha256 \
    -extfile "$TMP/extensiones.cnf" -out "$destino.crt" 2>/dev/null
}

crear_ca "$DIR/ca/ca" "Banco XYZ CA de desarrollo"
for servicio in config-server banco-core-api banco-auth transferencias-service antifraude-service notificaciones-service; do
  emitir "$DIR/ca/ca" "$DIR/servicios/$servicio" "$servicio" "serverAuth,clientAuth" "DNS:$servicio,DNS:localhost,IP:127.0.0.1"
  openssl pkcs12 -export -in "$DIR/servicios/$servicio.crt" -inkey "$DIR/servicios/$servicio.key" -name "$servicio" \
    -passout "pass:$ALMACEN" -out "$DIR/servicios/$servicio.p12"
  chmod 600 "$DIR/servicios/$servicio.p12"
done
rm -f "$DIR/ca/truststore.p12"
keytool -importcert -noprompt -storetype PKCS12 -keystore "$DIR/ca/truststore.p12" -storepass "$ALMACEN" \
  -alias banco-xyz-ca -file "$DIR/ca/ca.crt" > /dev/null
crear_ca "$DIR/intruso/ca-intrusa" "CA desconocida"
emitir "$DIR/intruso/ca-intrusa" "$DIR/intruso/transferencias-service-falso" "transferencias-service" "serverAuth,clientAuth" \
  "DNS:localhost,IP:127.0.0.1"
rm -f "$DIR"/ca/*.srl "$DIR"/intruso/*.srl

printf '\nPKI de desarrollo generada en %s\n\n' "$DIR"
printf '%-34s %-32s %-28s %s\n' "Certificado" "Sujeto (CN)" "Emisor" "Vence"
for crt in "$DIR"/ca/ca.crt "$DIR"/servicios/*.crt "$DIR"/intruso/*.crt; do
  sujeto=$(openssl x509 -in "$crt" -noout -subject -nameopt multiline | awk -F' = ' '/commonName/{print $2}')
  emisor=$(openssl x509 -in "$crt" -noout -issuer -nameopt multiline | awk -F' = ' '/commonName/{print $2}')
  vence=$(openssl x509 -in "$crt" -noout -enddate | cut -d= -f2)
  printf '%-34s %-32s %-28s %s\n' "${crt#$DIR/}" "$sujeto" "$emisor" "$vence"
done
printf '\nVerificacion de la cadena contra la CA del banco:\n'
for crt in "$DIR"/servicios/*.crt "$DIR"/intruso/transferencias-service-falso.crt; do
  printf '  %-34s %s\n' "${crt#$DIR/}" "$(openssl verify -CAfile "$DIR/ca/ca.crt" "$crt" 2>&1 | tail -1 | sed "s#$DIR/##")"
done
printf '\nAlmacenes PKCS12 para clientes Java (clave BANCO_ALMACEN_CLAVE):\n'
printf '  %s\n' "ca/truststore.p12 ($(keytool -list -storetype PKCS12 -keystore "$DIR/ca/truststore.p12" -storepass "$ALMACEN" | grep -c trustedCertEntry) CA)"
for p12 in "$DIR"/servicios/*.p12; do printf '  %s\n' "${p12#$DIR/}"; done
