#!/usr/bin/env bash
# Genera la PKI en el volumen /certificados la primera vez. Si ya existe no la toca: los servicios ya confian en esa CA
# (para regenerarla: BANCO_PKI_REGENERAR=true, o docker compose down -v).
set -euo pipefail
DESTINO=/certificados
if [ -f "$DESTINO/ca/ca.crt" ] && [ "${BANCO_PKI_REGENERAR:-false}" != "true" ]; then
  echo "PKI existente en el volumen: no se regenera."
  openssl x509 -in "$DESTINO/ca/ca.crt" -noout -subject -enddate
else
  /pki/generar_certificados.sh "$DESTINO"
fi
# Los servicios corren como el usuario banco (uid 10001) de sus imagenes: solo ese usuario lee las claves privadas.
chown -R 10001:10001 "$DESTINO"
chmod -R u=rwX,go= "$DESTINO"
echo "Certificados listos en el volumen para el usuario 10001."
