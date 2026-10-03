# Imagen del Config Server. Contexto de construccion: banco-xyz-cloud/ (necesita el modulo y la carpeta configuracion/).
# El repositorio de configuracion viaja dentro de la imagen (perfil native): cada version de la imagen trae su
# configuracion, y cambiarla es construir y desplegar una nueva, con historial.

FROM maven:3.9-eclipse-temurin-21 AS construccion
WORKDIR /fuente
COPY config-server/pom.xml .
RUN mvn -B -q -ntp dependency:go-offline
COPY config-server/src src
RUN mvn -B -q -ntp package -DskipTests \
 && java -Djarmode=tools -jar target/config-server-1.0.0.jar extract --layers --launcher --destination capas

FROM eclipse-temurin:21-jre-alpine
LABEL org.opencontainers.image.title="config-server" \
      org.opencontainers.image.description="Banco XYZ - Spring Cloud Config Server (HTTPS, mTLS y usuario/clave)" \
      org.opencontainers.image.version="1.0.0"
RUN addgroup -S -g 10001 banco && adduser -S -D -H -u 10001 -G banco banco
WORKDIR /app
COPY --from=construccion /fuente/capas/dependencies/ ./
COPY --from=construccion /fuente/capas/spring-boot-loader/ ./
COPY --from=construccion /fuente/capas/snapshot-dependencies/ ./
COPY --from=construccion /fuente/capas/application/ ./
COPY configuracion/ /config/
USER banco
EXPOSE 8888 9888
# server.address=0.0.0.0: dentro del contenedor escucha en su interfaz de red; el compose decide que se publica.
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=60 -XX:+UseSerialGC -XX:+ExitOnOutOfMemoryError" \
    BANCO_CONFIGURACION=file:/config/ \
    BANCO_CERTIFICADOS=/certificados \
    SERVER_ADDRESS=0.0.0.0
HEALTHCHECK --interval=10s --timeout=3s --start-period=60s --retries=6 \
  CMD wget -qO- http://127.0.0.1:9888/actuator/health | grep -q '"status":"UP"' || exit 1
ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
