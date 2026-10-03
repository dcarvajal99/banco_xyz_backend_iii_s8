# Imagen de antifraude-service: decide cada reserva; escala agregando contenedores.
# Se construye desde el codigo fuente (multi-etapa): la imagen final trae solo un JRE y la aplicacion, sin Maven ni el
# codigo. Construccion aislada: docker build -t banco-xyz/antifraude-service:1.0.0 antifraude-service/  (o desde el docker-compose.yaml).

FROM maven:3.9-eclipse-temurin-21 AS construccion
WORKDIR /fuente
# 1) Solo el pom: las dependencias quedan en una capa propia y no se vuelven a descargar cuando cambia el codigo.
COPY pom.xml .
RUN mvn -B -q -ntp dependency:go-offline
# 2) El codigo y el jar; despues el jar se separa en las capas de Spring Boot (dependencias, cargador, aplicacion):
#    al cambiar el codigo solo cambia la ultima capa, la mas liviana.
COPY src src
RUN mvn -B -q -ntp package -DskipTests \
 && java -Djarmode=tools -jar target/antifraude-service-1.0.0.jar extract --layers --launcher --destination capas

FROM eclipse-temurin:21-jre-alpine
LABEL org.opencontainers.image.title="antifraude-service" \
      org.opencontainers.image.description="Banco XYZ - decide cada reserva; escala agregando contenedores" \
      org.opencontainers.image.version="1.0.0"
# Usuario sin privilegios con uid fijo: el volumen de certificados se entrega legible solo para el.
RUN addgroup -S -g 10001 banco && adduser -S -D -H -u 10001 -G banco banco
WORKDIR /app
COPY --from=construccion /fuente/capas/dependencies/ ./
COPY --from=construccion /fuente/capas/spring-boot-loader/ ./
COPY --from=construccion /fuente/capas/snapshot-dependencies/ ./
COPY --from=construccion /fuente/capas/application/ ./
USER banco
# Negocio por HTTPS en 8083; operacion (health, circuitos, metricas) por HTTP en 9083.
EXPOSE 8083 9083
# La JVM usa para el heap el 60 % de la memoria del contenedor (no de la maquina); el resto queda para metaspace, hilos y
# buffers de red. Termina si se queda sin memoria, para que Docker la reinicie en vez de dejarla viva pero degradada. Perfil tls,nube: HTTPS y la configuracion del entorno en contenedores.
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=60 -XX:+UseSerialGC -XX:+ExitOnOutOfMemoryError" \
    SPRING_PROFILES_ACTIVE=tls,nube \
    BANCO_CERTIFICADOS=/certificados
HEALTHCHECK --interval=10s --timeout=3s --start-period=120s --retries=6 \
  CMD wget -qO- http://127.0.0.1:9083/actuator/health | grep -q '"status":"UP"' || exit 1
ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
