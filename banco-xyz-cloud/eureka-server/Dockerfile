# Imagen del servidor Eureka. Contexto de construccion: banco-xyz-cloud/. La misma imagen corre como peer1 o peer2
# segun el perfil (nube-peer1 / nube-peer2), que define su nombre y el del otro nodo.

FROM maven:3.9-eclipse-temurin-21 AS construccion
WORKDIR /fuente
COPY eureka-server/pom.xml .
RUN mvn -B -q -ntp dependency:go-offline
COPY eureka-server/src src
RUN mvn -B -q -ntp package -DskipTests \
 && java -Djarmode=tools -jar target/eureka-server-1.0.0.jar extract --layers --launcher --destination capas

FROM eclipse-temurin:21-jre-alpine
LABEL org.opencontainers.image.title="eureka-server" \
      org.opencontainers.image.description="Banco XYZ - Netflix Eureka (dos peers que se replican)" \
      org.opencontainers.image.version="1.0.0"
RUN addgroup -S -g 10001 banco && adduser -S -D -H -u 10001 -G banco banco
WORKDIR /app
COPY --from=construccion /fuente/capas/dependencies/ ./
COPY --from=construccion /fuente/capas/spring-boot-loader/ ./
COPY --from=construccion /fuente/capas/snapshot-dependencies/ ./
COPY --from=construccion /fuente/capas/application/ ./
USER banco
EXPOSE 8761 8762
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=60 -XX:+UseSerialGC -XX:+ExitOnOutOfMemoryError"
ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
