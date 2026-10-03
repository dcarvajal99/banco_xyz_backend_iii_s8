# Imagen de un solo uso que genera la PKI de desarrollo en el volumen "certificados" del compose. Contexto: banco-xyz-cloud/.
# Usa el mismo script que el modo local (scripts/generar_certificados.sh): openssl para los certificados y keytool para
# el almacen de confianza de los clientes Java.
FROM eclipse-temurin:21-jre-alpine
RUN apk add --no-cache bash openssl
WORKDIR /pki
COPY scripts/generar_certificados.sh docker/pki/entrypoint.sh ./
RUN chmod +x generar_certificados.sh entrypoint.sh
ENTRYPOINT ["/pki/entrypoint.sh"]
