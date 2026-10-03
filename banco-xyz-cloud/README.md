# banco-xyz-cloud — Infraestructura del Banco XYZ (semana 8)

Plataforma sobre la que corren los microservicios del banco, ahora **en contenedores**: el **Config Server** que les
entrega su configuración (con políticas de Resilience4j por entorno), **dos nodos de Eureka** que se replican entre sí,
**PostgreSQL** con el volcado de la migración, la **PKI de desarrollo** y los **scripts** que generan las evidencias.
El `docker-compose.yaml` de la raíz del repositorio orquesta los 11 servicios con un solo comando. Este proyecto no
contiene lógica de negocio.

Los modos de ejecución locales de la semana 7 (`construir.sh`, `preparar_base.sh`, `levantar_servicios.sh`,
`detener_servicios.sh`) se eliminaron: la forma de ejecutar es `docker compose up -d --build` desde la raíz.

| Componente | Dónde vive | Qué hace |
|---|---|---|
| `config-server/` | Imagen `banco-xyz/config-server` · `https://localhost:8888` | Spring Cloud Config, perfil `native`. El repositorio `configuracion/` viaja dentro de la imagen (`/config`). Solo HTTPS, certificado de cliente obligatorio y usuario/clave |
| `eureka-server/` | Imagen `banco-xyz/eureka-server` · `127.0.0.1:8761` y `:8762` | La misma imagen corre como `eureka-1` (perfil `nube-peer1`) y `eureka-2` (`nube-peer2`), que se replican entre sí |
| `configuracion/` | Dentro de la imagen del Config Server | `application.properties` (común), `application-nube.properties` (entorno contenedores) y un archivo por servicio |
| `docker/pki/` | Imagen `banco-xyz/pki` (un solo uso) | Genera la PKI en el volumen `certificados` y la deja legible solo para el uid `10001` |
| `docker/db/` | Imagen `banco-xyz/db` | PostgreSQL 17 con el volcado SQL en `docker-entrypoint-initdb.d` |
| `datos/01_migracion_semana3.sql` | Dentro de la imagen `db` | Volcado del resultado de la migración de `bank_legacy_data` (semanas 1 a 3). Reemplaza al batch |
| `scripts/` | En el equipo | Las 16 evidencias de la semana, `probar_todo.sh`, `generar_certificados.sh` (lo usa la imagen `pki`) y `lib.sh` |
| `../docker-compose.yaml` | Raíz del repositorio | Orquesta los 11 servicios: orden por salud, red, volúmenes, puertos y reinicio |

## El compose: 11 servicios, un comando

```bash
docker compose up -d --build                         # construye las imágenes desde el código y levanta todo en orden
docker compose ps                                    # estado y salud de cada contenedor
docker compose up -d --scale antifraude-service=3    # tres contenedores de antifraude en el mismo grupo de Kafka
docker compose down                                  # detiene todo; los volúmenes (datos, Kafka, certificados) se conservan
docker compose down -v                               # además borra los volúmenes: base, Kafka y PKI nacen de nuevo
```

Los secretos llegan por variable de entorno o por un archivo `.env` (se copia de `.env.ejemplo`; no se versiona). Sin
`.env`, el compose usa los mismos valores de desarrollo que trae la plantilla.

### Servicios, dependencias y puertos

Cada servicio con `depends_on` espera a que sus dependencias estén **sanas** (`condition: service_healthy`); `pki` espera
a terminar con éxito (`service_completed_successfully`).

| Servicio | Imagen | Espera a (por salud) | Puertos publicados | Memoria | Healthcheck |
|---|---|---|---|---|---|
| `pki` | `banco-xyz/pki:1.0.0` | — | — | — | No tiene: termina al generar la PKI (`restart: "no"`) |
| `db` | `banco-xyz/db:1.0.0` | — | — | 256 MB | `pg_isready` (cada 5 s) |
| `kafka` | `apache/kafka:3.9.1` | — | — | 768 MB | `kafka-broker-api-versions.sh` con heap de 64 MB (cada 5 s); datos en el volumen `kafka` (`KAFKA_LOG_DIRS`) |
| `config-server` | `banco-xyz/config-server:1.0.0` | `pki` (terminado) | `127.0.0.1:8888` | 320 MB | De la imagen, en `:9888` |
| `eureka-1` | `banco-xyz/eureka-server:1.0.0` | — | `127.0.0.1:8761` | 320 MB | Del compose, en `:8761` |
| `eureka-2` | `banco-xyz/eureka-server:1.0.0` | `eureka-1` (iniciado) | `127.0.0.1:8762` | 320 MB | Del compose, en `:8762` |
| `banco-core-api` | `banco-xyz/banco-core-api:1.0.0` | `db`, `kafka`, `config-server`, `eureka-1` | `127.0.0.1:9080` (solo operación) | 640 MB | De la imagen, en `:9080` |
| `banco-auth` | `banco-xyz/banco-auth:1.0.0` | `config-server`, `eureka-1`, `banco-core-api` | `127.0.0.1:8081` y `:9081` | 448 MB | De la imagen, en `:9081` |
| `transferencias-service` | `banco-xyz/transferencias-service:1.0.0` | `db`, `kafka`, `config-server`, `banco-core-api`, `banco-auth` | `127.0.0.1:8082` y `:9082` | 512 MB | De la imagen, en `:9082` |
| `antifraude-service` | `banco-xyz/antifraude-service:1.0.0` | `kafka`, `config-server`, `eureka-1` | Ninguno | 384 MB | De la imagen, en `:9083` |
| `notificaciones-service` | `banco-xyz/notificaciones-service:1.0.0` | `kafka`, `config-server`, `eureka-1` | `127.0.0.1:8084` y `:9084` | 384 MB | De la imagen, en `:9084` |

Diez de los once tienen healthcheck; `pki` es el único que termina. Los límites de memoria suman 4352 MB con una sola
instancia de antifraude.

Orden de arranque resultante: primero `pki`, `db`, `kafka` y `eureka-1`, que no esperan a nadie; después `config-server`
(cuando `pki` terminó) y `eureka-2` (cuando `eureka-1` arrancó); luego `banco-core-api`, que necesita la base, Kafka, la
configuración y el registro; después `banco-auth`, que valida los logins contra el core; por último
`transferencias-service`, que necesita el core y a banco-auth para su token de servicio. `antifraude-service` y
`notificaciones-service` solo esperan a Kafka, al Config Server y a Eureka.

### Red, volúmenes, puertos y reinicio

| Aspecto | Detalle |
|---|---|
| Red | `banco-xyz`: los servicios se encuentran por nombre (`kafka:9092`, `db:5432`, `config-server:8888`, `banco-auth:8081`) |
| Volúmenes | `certificados` (la escribe `pki`; el resto la monta en `/certificados` como solo lectura), `datos` (datos de PostgreSQL) y `kafka` (datos del broker). Nombres reales: `banco-xyz_certificados`, `banco-xyz_datos`, `banco-xyz_kafka` |
| Puertos | **Solo en `127.0.0.1`** del equipo: nada queda expuesto a la red. No se publican `db`, `kafka`, el puerto de negocio del core (`8080`, se alcanza solo dentro de la red y exige certificado de cliente) ni `antifraude-service` |
| Reinicio | `restart: unless-stopped` en todos salvo `pki` (`"no"`): si el proceso de un contenedor muere, Docker lo levanta de nuevo |
| Escalado | `antifraude-service` no define `hostname` ni publica puertos, y se registra en Eureka con su IP: se escala con `--scale antifraude-service=N` hasta las 3 particiones de Kafka |
| Puerto de operación | En el entorno `nube` cada servicio escucha su puerto de operación en `0.0.0.0` dentro del contenedor (`management.server.address` del Config Server); el compose lo publica solo en `127.0.0.1`. Desde otro contenedor de la red es alcanzable sin credenciales |

El broker es un solo nodo KRaft (broker y controlador, sin ZooKeeper), con `KAFKA_AUTO_CREATE_TOPICS_ENABLE=false`: cada
servicio crea sus tópicos con 3 particiones, y un nombre mal escrito falla en vez de crear otro tópico.

## Imágenes Docker

Cada servicio Java tiene un Dockerfile multi-etapa en su propio proyecto; los de infraestructura están aquí.

| Imagen | Dockerfile (contexto) | Base y contenido |
|---|---|---|
| Servicios (`banco-core-api`, `banco-auth`, `transferencias-service`, `antifraude-service`, `notificaciones-service`) | `<servicio>/Dockerfile` (contexto: la carpeta del servicio) | `maven:3.9-eclipse-temurin-21` compila (primero el `pom.xml` con `dependency:go-offline`, después `src/`) y separa el jar en capas de Spring Boot con `jarmode tools`; `eclipse-temurin:21-jre-alpine` solo trae el JRE y las capas |
| `config-server` | `config-server/Dockerfile` (contexto: `banco-xyz-cloud/`) | Mismo esquema de dos etapas, más `COPY configuracion/ /config/` (`BANCO_CONFIGURACION=file:/config/`): cada versión de la imagen trae su configuración, y cambiarla es construir y desplegar una imagen nueva |
| `eureka-server` | `eureka-server/Dockerfile` (contexto: `banco-xyz-cloud/`) | Mismo esquema de dos etapas. La misma imagen corre como peer 1 o peer 2 según el perfil (`nube-peer1` o `nube-peer2`); no trae `HEALTHCHECK` propio porque cada nodo escucha en un puerto distinto, y lo define el compose |
| `pki` | `docker/pki/Dockerfile` (contexto: `banco-xyz-cloud/`) | `eclipse-temurin:21-jre-alpine` con `bash` y `openssl`; trae `scripts/generar_certificados.sh` y un `entrypoint.sh` |
| `db` | `docker/db/Dockerfile` (contexto: `banco-xyz-cloud/`) | `postgres:17-alpine` con `datos/01_migracion_semana3.sql` en `/docker-entrypoint-initdb.d/` |

Lo que comparten las imágenes Java:

| Aspecto | Valor |
|---|---|
| Usuario | `banco`, uid/gid `10001`, sin privilegios |
| JVM | `JAVA_TOOL_OPTIONS=-XX:MaxRAMPercentage=60 -XX:+UseSerialGC -XX:+ExitOnOutOfMemoryError`: el heap toma el 60 % de la memoria del contenedor y la JVM termina si se queda sin memoria, para que Docker la reinicie |
| Perfiles | `SPRING_PROFILES_ACTIVE=tls,nube` en los cinco servicios; `nube-peer1` o `nube-peer2` en Eureka; `native,tls` en el Config Server (de su `application.properties`) |
| Healthcheck | `wget` al `/actuator/health` del puerto de operación, buscando `"status":"UP"`: cada 10 s, 3 s de límite, 6 reintentos, 120 s de arranque (60 s en el Config Server) |

### La PKI (`pki`)

`docker/pki/entrypoint.sh` genera la PKI en el volumen `certificados` la primera vez, con el mismo
`generar_certificados.sh` de los scripts: una CA de desarrollo (EC P-256), un certificado y un `.p12` por servicio
(válidos como servidor y como cliente, con el nombre del servicio como nombre alternativo), el `truststore.p12` de la CA
y una CA intrusa con un certificado falso para las pruebas negativas. Si la CA ya existe, no la toca (los servicios ya
confían en ella; para regenerarla se borra el volumen con `docker compose down -v`, o se define `BANCO_PKI_REGENERAR=true`
en el contenedor). Al terminar hace `chown` al uid `10001` y deja permisos solo para ese usuario, porque es el único que
lee las claves privadas.

### La base (`db`)

El entrypoint de PostgreSQL carga el volcado solo cuando el volumen `datos` se crea por primera vez (`POSTGRES_DB=banco_xyz`;
usuario y clave por `BANCO_DB_USUARIO` y `BANCO_DB_CLAVE`). El volcado deja el esquema `public` (resultado de la migración
de las semanas 1 a 3, que el core solo lee); los esquemas `core` y `transferencias` los crea Flyway desde cada servicio.

## Config Server protegido

| Capa | Cómo |
|---|---|
| Cifrado | `server.ssl` con el certificado `servicios/config-server` de la CA del banco, TLS 1.3/1.2. El puerto 8888 no habla HTTP plano |
| Identidad del servicio | `server.ssl.client-auth=need`: sin un certificado firmado por la CA del banco el handshake se corta |
| Autenticación | Spring Security con Basic (`SeguridadDelConfigServer`); usuario y clave por `BANCO_CONFIG_USUARIO` / `BANCO_CONFIG_CLAVE` |
| Operación | `/actuator/health` en `127.0.0.1:9888` dentro del contenedor, sin TLS ni credenciales: lo usa el `HEALTHCHECK` de la imagen y no se publica |

Cada servicio lo importa con `spring.config.import=optional:configserver:${BANCO_CONFIG_SERVER:https://localhost:8888}`
(en el compose, `https://config-server:8888`), presenta su propio `.p12` (`spring.cloud.config.tls.key-store`,
`key-password`) y confía solo en la CA (`trust-store`). Con `BANCO_CONFIG_FAIL_FAST=true` —lo fija el compose— un servicio
que el Config Server rechaza **no arranca**: no queda corriendo con los valores de su jar. `optional:` sigue permitiendo
las pruebas y el desarrollo aislado. El Config Server no reparte secretos: las claves se inyectan por variable de entorno
en cada servicio.

## Lo que entrega el Config Server

Cada servicio recibe, en este orden de prioridad, los archivos de su nombre y perfil y los comunes:

| Archivo | Lo recibe | Contenido |
|---|---|---|
| `application.properties` | Todos | `banco.ecosistema.version=semana-8`; Eureka con los dos nodos locales, renovación cada 5 s y expiración a los 15 s, consulta del catálogo cada 5 s y caché de LoadBalancer de 5 s; Kafka `localhost:9092` y 3 particiones; **OAuth 2.0**: emisor, audiencia, JWK Set (`/oauth2/jwks`) y endpoint de tokens (`/oauth2/token`) de banco-auth; las políticas compartidas de Resilience4j (`http-interno` y `publicacion-kafka`) |
| `application-nube.properties` | Todos, con el perfil `nube` | Direcciones dentro de la red del compose (Eureka `eureka-1`/`eureka-2`, Kafka `kafka:9092`, emisor, JWK Set y tokens de `banco-auth:8081`), `management.server.address=0.0.0.0` y los ajustes de Resilience4j para contenedores |
| `banco-core-api.properties` | Core | Identidad e instancia `kafka` de Resilience4j (`base-config=publicacion-kafka`) |
| `banco-core-api-nube.properties` | Core, perfil `nube` | `spring.datasource.url=jdbc:postgresql://db:5432/banco_xyz` |
| `banco-auth.properties` | banco-auth | Duración del token (5 min), el core por nombre (`https://banco-core-api/api/v1`) y la instancia `core` (circuito, reintento y bulkhead con `base-config=http-interno`) |
| `transferencias-service.properties` | transferencias-service | El core por nombre, la instancia `core` (`http-interno`) y la instancia `kafka` (`publicacion-kafka`) |
| `transferencias-service-nube.properties` | transferencias-service, perfil `nube` | `spring.datasource.url=jdbc:postgresql://db:5432/banco_xyz` |
| `antifraude-service.properties` | antifraude-service | Reglas de riesgo: monto máximo 5000, cuentas en observación (104), demora simulada 200 ms |
| `notificaciones-service.properties` | notificaciones-service | Identidad del servicio |

Ningún archivo trae claves ni secretos (`ConfiguracionCentralTest` lo comprueba). Cambiar una política o una regla es
editar su archivo, reconstruir la imagen del Config Server y reiniciar los servicios que la usan:

```bash
docker compose up -d --build config-server
docker compose restart antifraude-service        # o el servicio que corresponda
```

## Políticas de Resilience4j: en el Config Server, por entorno

Los jar de los servicios **no traen ninguna propiedad `resilience4j.*`**. Las políticas se definen una sola vez como
`configs` en `application.properties` y cada punto protegido las usa con `base-config`; `application-nube.properties`
cambia los valores para el entorno en contenedores.

| Config compartida | La usan |
|---|---|
| `http-interno` | Llamadas HTTP al core: instancia `core` de banco-auth (login) y de transferencias-service (prevalidación) |
| `publicacion-kafka` | Publicación del outbox a Kafka: instancia `kafka` del core y de transferencias-service |

| Parámetro | Local (base) | Nube |
|---|---|---|
| `http-interno` · circuito: `sliding-window-type` / `sliding-window-size` | `COUNT_BASED` / 6 | `COUNT_BASED` / 10 |
| `http-interno` · circuito: `minimum-number-of-calls` | 3 | 5 |
| `http-interno` · circuito: `failure-rate-threshold` | 50 % | 50 % |
| `http-interno` · circuito: `wait-duration-in-open-state` | 10 s | 15 s |
| `http-interno` · circuito: `permitted-number-of-calls-in-half-open-state` | 2 | 3 |
| `http-interno` · circuito: `slow-call-duration-threshold` / `slow-call-rate-threshold` | no definidos | 2 s / 80 % |
| `http-interno` · reintento: `max-attempts` | 2 | 3 |
| `http-interno` · reintento: `wait-duration` | 200 ms | 300 ms |
| `http-interno` · reintento: backoff exponencial / multiplicador | no | sí / 2 |
| `http-interno` · reintento: `retry-exceptions` | `ResourceAccessException` | igual |
| `http-interno` · bulkhead: `max-concurrent-calls` | 20 | 25 |
| `http-interno` · bulkhead: `max-wait-duration` | 0 ms | 0 ms |
| `publicacion-kafka` · circuito: `sliding-window-size` | 4 | 6 |
| `publicacion-kafka` · circuito: `minimum-number-of-calls` | 2 | 3 |
| `publicacion-kafka` · circuito: `failure-rate-threshold` | 50 % | 50 % |
| `publicacion-kafka` · circuito: `wait-duration-in-open-state` | 10 s | 15 s |
| `publicacion-kafka` · circuito: `permitted-number-of-calls-in-half-open-state` | 1 | 1 |
| `publicacion-kafka` · reintento: `max-attempts` | 3 | 4 |
| `publicacion-kafka` · reintento: `wait-duration` | 300 ms | 500 ms |

"Local" es lo que entrega el Config Server sin perfil y lo que usan las pruebas; "Nube" es lo que recibe un contenedor
con el perfil `nube`. En la nube se espera más antes de decidir (una red compartida tiene fallas aisladas que no deben
abrir el circuito), se espera más antes de probar de nuevo, las llamadas lentas cuentan como falla y los reintentos
espacian cada vez más. Lo que no figura en la tabla (por ejemplo, `slow-call-*` en local) toma el valor por defecto de la
biblioteca.

Las instancias solo eligen su política y declaran sus excepciones:

| Servicio | Instancia | `base-config` | Excepciones propias |
|---|---|---|---|
| banco-auth | `core` (circuito, reintento, bulkhead) | `http-interno` | `ignore-exceptions`: `ErrorDeNegocioDelCore` y `BulkheadFullException` |
| transferencias-service | `core` (circuito, reintento, bulkhead) | `http-interno` | `ignore-exceptions`: `ErrorDeNegocioDelCore` y `BulkheadFullException` |
| transferencias-service | `kafka` (circuito, reintento) | `publicacion-kafka` | `record-exceptions` y `retry-exceptions`: `ErrorDePublicacion` |
| banco-core-api | `kafka` (circuito, reintento) | `publicacion-kafka` | `record-exceptions` y `retry-exceptions`: `ErrorDePublicacion` |

Las pruebas corren sin Config Server: banco-auth, transferencias-service y banco-core-api guardan una copia de su política
en `src/test/resources/application-prueba.properties`. `scripts/verificar_coherencia.sh` comprueba que esa copia sea
idéntica a la central (`application.properties` más el archivo del servicio) y que el jar no tenga política propia; si se
cambia una política base, hay que cambiar también esas tres copias.

## Eureka con dos peers

- En el compose, `eureka-1` (perfil `nube-peer1`, puerto 8761) usa como `defaultZone` a `http://eureka-2:8762/eureka/` y
  `eureka-2` (perfil `nube-peer2`, puerto 8762) a `http://eureka-1:8761/eureka/`: cada nodo se registra en el otro y le
  replica altas, renovaciones y bajas. En Docker cada nodo tiene su propio nombre de red, así que no hace falta el truco de
  mezclar `127.0.0.1` y `localhost`.
- Los clientes conocen ambos nodos (`http://eureka-1:8761/eureka/,http://eureka-2:8762/eureka/`, de
  `application-nube.properties`); si cae uno, renuevan y consultan con el otro. Al volver, el nodo copia el registro del
  vecino al arrancar (`Got N instances from neighboring DS node`).
- `enable-self-preservation=false`, expulsión cada 5 s y caché de respuestas de solo lectura apagada: el registro refleja
  enseguida las altas y bajas (adecuado para la demostración, no para una red inestable).
- Cada nodo se registra en su peer con el transporte RestClient (`eureka.client.jersey.enabled=false`). Con Jersey, si
  el registro de un nodo expiraba (por ejemplo, tras suspender el equipo), el peer respondía 404 al latido con el JSON de
  error de Spring Boot; el cliente fallaba al leerlo como `InstanceInfo` (400) y el nodo no se volvía a registrar, así que
  el panel lo mostraba como réplica no disponible. RestClient decide por el código y se registra de nuevo.
- Los perfiles `peer1` y `peer2` (`127.0.0.1` ⇄ `localhost`) se conservan para ejecutar Eureka fuera de Docker; el compose
  usa `nube-peer1` y `nube-peer2`.

## Scripts de evidencia

Se ejecutan desde cualquier carpeta con `bash` (por ejemplo, `bash banco-xyz-cloud/scripts/saga_transferencias.sh` desde la
raíz). Cada uno imprime lo que prueba y termina con `Resultado: N verificaciones correctas, M fallas`; salvo
`estructura.sh`, todos suponen el ecosistema arriba (`docker compose up -d --build`). Las llamadas desde el equipo validan
el certificado contra la CA del banco (nunca `-k`); `lib.sh` la copia del contenedor `pki` a `certificados/` (no se
versiona). Lo que no se publica (el core) se llama desde un contenedor de la red con `curlimages/curl:8.11.1`, que se
descarga la primera vez. Las herramientas de consola de Kafka también corren en un contenedor efímero de la red
(`apache/kafka:3.9.1`), nunca dentro del broker: ahí compartirían su límite de memoria.

| N.º | Script | Qué muestra |
|---|---|---|
| 00 | `estructura.sh` | Los seis proyectos independientes (build, pruebas, Dockerfile), los servicios del compose, qué tópicos produce y consume cada uno (leído del código), cómo se encuentran (Config Server y Eureka) y que ninguno importa código de otro |
| 01 | `imagenes_docker.sh` | Las imágenes construidas desde el código: multi-etapa, usuario `banco` sin privilegios, puertos, healthcheck (6 de 7 imágenes Java lo traen; el de Eureka lo define el compose), capas de Spring Boot y que la imagen no trae Maven |
| 02 | `ecosistema_compose.sh` | `up -d --wait` con los 11 contenedores (10 sanos y `pki` terminado), orden real de arranque, red, volúmenes, puertos solo en `127.0.0.1`, configuración tomada del Config Server con el perfil `nube`, registro en Eureka y reinicio automático tras matar un proceso |
| 03 | `oauth2_flujos.sh` | Discovery OpenID, flujo `authorization_code` + PKCE paso a paso (login en banco-auth, la clave la verifica el core), `/userinfo`, refresh token rotativo, código de un solo uso y PKCE obligatorio |
| 04 | `proteccion_servicios.sh` | Scopes por operación (403 `insufficient_scope`), 401 sin token, alterado o `alg=none`, `client_credentials` hacia el core, los rechazos del core (clave Basic antigua, token de usuario, sin certificado, certificado ajeno) y la operación protegida (no se fuerza un circuito ni se leen las claves sin token, tampoco desde otro contenedor) |
| 05 | `claves_jwt.sh` | Tokens RS256 con `kid`, JWK Set solo con claves públicas; la administración exige el token de `operacion-banco` (401 sin token, 403 con el de otro cliente); rotación (`POST /actuator/claves`), periodo de gracia y retiro: el token anterior deja de valer al vencer la caché de 30 s (tarda unos 45 s) |
| 06 | `resiliencia_core.sh` | Se detiene el core: transferencias-service acepta con validación `DIFERIDA` y banco-auth avisa `servicio`; ambos circuitos abren con la política `nube`; al volver el core la saga procesa lo que esperaba y los circuitos se cierran solos |
| 07 | `resiliencia_kafka.sh` | Se detiene Kafka: la API sigue aceptando, el outbox acumula pendientes, el circuito `kafka` abre; al volver el broker el outbox se vacía en orden y las transferencias se completan |
| 08 | `politicas_por_entorno.sh` | Dónde vive cada parte de la política, que los jar no traen ninguna, los valores local y nube que entrega el Config Server, que banco-auth y transferencias-service comparten `http-interno`, y la política nube en ejecución |
| 09 | `topicos_kafka.sh` | Los cuatro tópicos con 3 particiones y su DLT, los grupos de consumidores y el sobre de un evento real (versión 2) |
| 10 | `saga_transferencias.sh` | Camino feliz, rechazo de antifraude con compensación, cuenta en observación, rechazos del core, validaciones previas, idempotencia y avisos de notificaciones |
| 11 | `eventos_versionados.sh` | Evento duplicado (mismo y distinto `eventoId`) sin efecto doble; un evento v1 se procesa como v2; una versión futura y un mensaje ilegible van a la DLT |
| 12 | `escalabilidad.sh` | 48 transferencias con 1 y con 3 contenedores de antifraude (`--scale`), el reparto por partición y un contenedor muerto con `SIGKILL` a mitad de la carga. Usa `colima ssh` para matar el proceso |
| 13 | `config_segura.sh` | HTTP plano rechazado, sin certificado se corta el handshake, sin clave 401, CA ajena rechazada, y un servicio con la clave de Config equivocada que no arranca (`fail-fast`) |
| 14 | `eureka_peers.sh` | Réplicas disponibles, registro igual en los dos nodos, un contenedor nuevo replicado, y la caída y vuelta de `eureka-1` sin cortar el descubrimiento |
| 15 | `verificar_coherencia.sh` | Sobre del evento, lector versionado, nombres de tópicos y datos de JWT iguales entre proyectos; copias de las políticas de pruebas iguales a las centrales; ninguna ruta hacia otra carpeta |
| — | `probar_todo.sh` | `./mvnw verify` en los seis proyectos, cada uno con su propio Maven Wrapper, con el log en `evidencias/logs/verify-proyectos.log` (`MVN_OPCIONES="-o"` para trabajar sin red) |
| — | `generar_certificados.sh` | Genera la PKI de desarrollo; lo usa la imagen `pki` y se puede ejecutar a mano para otro directorio |

`01_*` y `02_*` leen el estado de Docker; los scripts 06, 07, 12 y 14 detienen o reinician contenedores y dejan el
ecosistema como estaba. `ecosistema_compose.sh` y `escalabilidad.sh` usan `colima ssh`, es decir, suponen Colima como
runtime de Docker.

## Construir y probar

```bash
./mvnw verify                              # config-server y eureka-server (12 pruebas)
bash scripts/probar_todo.sh                # los seis proyectos, cada uno por separado
```

12 pruebas propias: **10 del Config Server** y **2 de Eureka**.

| Clase | Pruebas | Qué comprueba |
|---|---|---|
| `ConfiguracionCentralTest` (config-server) | 10 (5 + 5 casos) | Levanta el Config Server sobre `configuracion/` real: sin credenciales (o con clave equivocada) responde 401; transferencias-service recibe su archivo y el común, con el core por nombre, Eureka, Kafka y los datos de JWT; las políticas de Resilience4j cambian entre el perfil por defecto y `nube` (circuito más holgado, llamadas lentas, backoff exponencial, base `db`); banco-auth y transferencias-service comparten `http-interno` y cada uno ignora su propia excepción de negocio; antifraude-service recibe sus reglas; ningún servicio recibe claves ni secretos (un caso por servicio) |
| `ReplicacionEntrePeersTest` (eureka-server) | 1 | Levanta dos nodos con puertos libres, registra una instancia en uno y la encuentra `UP` en el otro |
| `CatalogoTest` (eureka-server) | 1 | Registra una instancia HTTPS y la encuentra `UP` en la consulta siguiente |

El informe de cobertura JaCoCo de cada módulo queda en `target/site/jacoco/index.html`.

## Ejecutar

Desde la raíz del repositorio:

```bash
cp .env.ejemplo .env                       # opcional: sin .env se usan los mismos valores de desarrollo
docker compose up -d --build               # imágenes desde el código y ecosistema completo, en orden y por salud
docker compose ps
bash banco-xyz-cloud/scripts/saga_transferencias.sh
```

Para apagar: `docker compose down`. Paso a paso, credenciales de demostración y solución de problemas: [README general](../README.md).

## Limitaciones conocidas

- Kafka corre como un solo nodo (factor de replicación 1): demuestra particiones y grupos, no la tolerancia del broker.
- El Config Server usa el backend `native` con los archivos dentro de la imagen; en producción apuntaría a un repositorio git.
- La PKI es de desarrollo y los valores por defecto de `.env.ejemplo` son de desarrollo.
- Eureka tiene la autopreservación apagada para que las bajas se vean al instante; en producción se deja encendida.
- Los puertos de operación escuchan en `0.0.0.0` dentro de la red del compose (y se publican solo en `127.0.0.1`). Por
  eso el actuator es de solo lectura en todos los servicios y la administración de claves de banco-auth exige un token
  OAuth con `claves.administrar`; la salud y los circuitos se pueden leer sin credenciales desde la red interna.
