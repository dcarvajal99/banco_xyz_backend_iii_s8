# notificaciones-service — Banco XYZ

Consumidor final de la saga coreografiada de transferencias del Banco XYZ. No decide nada ni cambia ningún saldo:
escucha los eventos que le importan al cliente —una reserva rechazada por el core, una transferencia completada o una
compensación tras el rechazo de antifraude— y arma un aviso en español. Es **stateless** frente a la saga (no tiene
base de datos); guarda las notificaciones en memoria, por cliente, y las expone en su propia API, protegida con OAuth 2.0:
el cliente la consulta con el mismo tipo de token que usó para transferir, pero con su propio scope.

Es un **servidor de recursos** OAuth 2.0: valida los tokens de banco-auth contra su JWK Set y no emite ninguno.

## Ficha

| Campo | Valor |
|---|---|
| Puerto HTTPS | `8084` (perfiles `tls,nube`, fijados en la imagen); el compose lo publica en `127.0.0.1` |
| Puerto de operación (health, métricas) | `9084`, sin TLS; el compose lo publica solo en `127.0.0.1` |
| Nombre en Eureka | `NOTIFICACIONES-SERVICE` (instancia HTTPS) |
| Paquete raíz | `com.bancoxyz.notificaciones` (`notificacion/`, `evento/`, `seguridad/`, `config/`) |
| Stack | Spring Boot 3.5.16, Spring Cloud 2025.0.3, Spring Security (resource server), Spring Kafka; se compila para Java 17 y corre sobre un JRE 21 |
| Base de datos | Ninguna: las notificaciones viven en memoria (`ConcurrentHashMap`, máximo 50 por cliente); un reinicio del contenedor las borra |
| Grupo de consumidores | `notificaciones-service`, con `spring.kafka.listener.concurrency=3` (un consumidor por partición) |
| Configuración central | `banco-xyz-cloud/configuracion/notificaciones-service.properties` + `application.properties` + `application-nube.properties` |

## Eventos

| Tópico | Dirección | Eventos | Notas |
|---|---|---|---|
| `cuentas.reservas` | Consume | `FondosRechazados` | El core no pudo reservar: se avisa el rechazo |
| `cuentas.reservas` | Consume (se ignora) | `FondosReservados` | Todavía no hay nada que avisar: antifraude no decidió |
| `cuentas.transferencias` | Consume | `TransferenciaCompletada` | Aviso de éxito |
| `cuentas.transferencias` | Consume | `ReservaLiberada` | Compensación: antifraude rechazó y el core devolvió el monto retenido |
| `cuentas.reservas.DLT`, `cuentas.transferencias.DLT` | Produce | — | Mensaje ilegible, sin `eventoId`/`tipo`/`transferenciaId` o de una versión que el servicio no entiende; no se reintenta |

No produce eventos de negocio: el `KafkaTemplate` que declara solo existe para que `DeadLetterPublishingRecoverer` pueda
publicar en el DLT lo que no logra leer. El sobre del evento (`EventoDeTransferencia`) es la misma copia que usan los
demás servicios de la saga.

### Eventos v2: versión y moneda

El sobre lleva `version` (`VERSION_ACTUAL = 2`) y `moneda` (`CLP`). `LectorDeEventos` lee así:

| Caso | Resultado |
|---|---|
| Sin `version` ni `moneda` (v1, semana 7) | **Upcasting**: se lee como v2 en `CLP`, sin perder datos |
| `version` = 2 | Se lee tal cual, con su moneda |
| Campo que el servicio no conoce | Se ignora (**lector tolerante**) |
| `version` mayor que 2 o inválida | `VersionNoSoportada`: va a `<tópico>.DLT` **sin reintentos**, para reprocesarlo cuando el consumidor se actualice |
| Texto que no es JSON, JSON sin `eventoId`, `tipo` o `transferenciaId` | `EventoInvalido`: directo a la DLT |

Convención de evolución de los eventos del banco: **primero los consumidores, después los productores**, porque un
consumidor que no entiende una versión nueva la manda a la DLT. Un campo opcional agregado **no sube la versión**; esta
sube solo cuando los consumidores deben entender algo nuevo. La copia del sobre y del lector es la misma en los cuatro
servicios de la saga (`scripts/verificar_coherencia.sh` lo comprueba). Un fallo transitorio se reintenta dos veces con un
segundo de espera antes de ir a la DLT (`DefaultErrorHandler`).

## Textos y deduplicación

`ServicioDeNotificaciones` arma el texto según el tipo de evento, con el monto en formato chileno
(`FormateadorDeMonto`: punto de miles, coma decimal si corresponde) y, en un rechazo o una compensación, el motivo
traducido a una frase (`TraductorDeMotivos`): `SALDO_INSUFICIENTE`, `CUENTA_AJENA`, `CUENTA_ORIGEN_INEXISTENTE`,
`CUENTA_DESTINO_INEXISTENTE`, `MISMA_CUENTA`, `CUENTA_NO_ADMITE_RETIROS`, `MONTO_INVALIDO`, `MONTO_SOBRE_LIMITE` y
`CUENTA_EN_OBSERVACION`; un motivo que no está en la tabla se muestra tal cual, para no ocultar un caso nuevo (hoy es el
caso de `MONEDA_NO_SOPORTADA`, el motivo que agregó el core con los eventos v2). Por ejemplo:

```
Transferencia de $15.000 desde la cuenta 101 a la cuenta 105 realizada.
Transferencia de $15.000 desde la cuenta 101 rechazada: saldo insuficiente.
```

Cada evento se identifica por su `eventoId`; uno ya procesado (reentrega de Kafka) se descarta sin volver a notificar
(`RepositorioDeNotificaciones.yaProcesado`, respaldado en un `Set` concurrente).

## API

| Método | Ruta | Autorización | Respuesta |
|---|---|---|---|
| GET | `/api/v1/notificaciones` | JWT de banco-auth con `SCOPE_notificaciones.leer` | `200` con la lista; `401` sin token o con un token inválido; `403` con un token sin ese scope |

Devuelve la lista de notificaciones del cliente del token (claim `cliente_id`), la más reciente primero:
`{tipo, transferenciaId, texto, ocurridoEn}`.

## Seguridad: el rol OAuth de este servicio

Servidor de recursos. `ConfiguracionSeguridad` exige `SCOPE_notificaciones.leer` para el `GET`, permite `/error` y los
`GET` del actuator (solo lectura: su puerto escucha en la red de los contenedores), y niega todo lo demás (`denyAll`). El scope lo concede banco-auth al cliente `banca-web` cuando la aplicación lo
pide; un token que solo trae `transferencias.leer` recibe 403.

`DecodificadorDeTokens` es el mismo que usan transferencias-service y el core:

| Validación | Detalle |
|---|---|
| Firma | RS256 contra el JWK Set de banco-auth (`banco.jwt.jwk-set-uri`; en `nube`, `https://banco-auth:8081/oauth2/jwks`), con la clave cuyo `kid` trae el token; no hay secreto compartido |
| Emisor y audiencia | `banco.jwt.emisor` y `banco.jwt.audiencia` (`banco-xyz`), ambos exigidos |
| Vencimiento | **Sin tolerancia** (`JwtTimestampValidator(Duration.ZERO)`) |
| Caché del JWK Set | 30 s (`banco.jwt.cache-jwks`), **sin refresco anticipado**: una clave retirada deja de aceptarse a lo sumo a los 30 s; un `kid` desconocido fuerza a consultarlo de nuevo |
| Transporte | El JWK Set se lee por HTTPS confiando solo en la CA del banco (bundle `confianza`, únicamente `truststore`: este servicio nunca llama a otro por mTLS) |

El servicio toma del token `cliente_id` (y `usuario_id`); cada cliente ve solo sus notificaciones.

## Resilience4j

No aplica: el servicio no hace llamadas HTTP salientes ni tiene outbox, así que no usa Resilience4j. Su tolerancia a
fallos es el manejo de errores del consumidor: dos reintentos a 1 s y después el DLT; un mensaje ilegible va directo.

## Imagen Docker

Construcción multi-etapa desde el código fuente (`notificaciones-service/Dockerfile`, contexto `notificaciones-service/`):

| Aspecto | Valor |
|---|---|
| Etapa de construcción | `maven:3.9-eclipse-temurin-21`: primero solo el `pom.xml` (`dependency:go-offline`), después `src/` y `package -DskipTests`; el jar se separa en capas de Spring Boot (`jarmode tools extract --layers --launcher`) |
| Etapa final | `eclipse-temurin:21-jre-alpine`: solo el JRE y las capas `dependencies`, `spring-boot-loader`, `snapshot-dependencies` y `application` |
| Usuario | `banco`, uid/gid `10001`, sin privilegios |
| Puertos | `8084` (HTTPS) y `9084` (operación) |
| `HEALTHCHECK` | `wget` a `http://127.0.0.1:9084/actuator/health` buscando `"status":"UP"`; cada 10 s, 3 s de límite, 120 s de arranque, 6 reintentos |
| JVM | `JAVA_TOOL_OPTIONS=-XX:MaxRAMPercentage=60 -XX:+UseSerialGC -XX:+ExitOnOutOfMemoryError` |
| Perfiles | `SPRING_PROFILES_ACTIVE=tls,nube` |
| Límite de memoria en el compose | 384 MB |

Variables que recibe del `docker-compose.yaml` de la raíz (valores por defecto `-dev` en `.env.ejemplo`):

| Variable | Para qué |
|---|---|
| `BANCO_CONFIG_SERVER`, `BANCO_CONFIG_USUARIO`, `BANCO_CONFIG_CLAVE`, `BANCO_CONFIG_FAIL_FAST=true` | Config Server (con `fail-fast`, si lo rechaza el servicio no arranca) |
| `BANCO_ALMACEN_CLAVE`, `BANCO_CERTIFICADOS=/certificados` | Clave de los `.p12` y carpeta de la PKI (volumen `certificados`, solo lectura) |
| `EUREKA_INSTANCE_HOSTNAME=notificaciones-service` | Nombre con que se registra en Eureka |

No necesita base de datos ni secretos de OAuth: solo valida tokens. Depende (por salud) de `kafka`, `config-server` y
`eureka-1`, no de banco-auth (el JWK Set se consulta al validar el primer token), y publica `127.0.0.1:8084` y
`127.0.0.1:9084`.

## Configuración

| Propiedad | En el jar (`application.properties`) | Config Server | Variable de entorno |
|---|---|---|---|
| `banco.jwt.emisor` / `audiencia` / `jwk-set-uri` | `https://localhost:8081`, `banco-xyz`, `https://localhost:8081/oauth2/jwks` | Los mismos en `application.properties`; en `nube`, `https://banco-auth:8081` y `https://banco-auth:8081/oauth2/jwks` | — |
| `banco.jwt.cache-jwks` | `30s` | — | — |
| `spring.kafka.bootstrap-servers` | `${BANCO_KAFKA:localhost:9092}` | `localhost:9092`; en `nube`, `kafka:9092` | `BANCO_KAFKA` (solo sin Config Server) |
| `spring.kafka.listener.concurrency` / `banco.kafka.particiones` | `3` / `3` | `banco.kafka.particiones=3` | — |
| `eureka.client.service-url.defaultZone` | `${BANCO_EUREKA:...}` con los dos nodos locales | igual; en `nube`, `eureka-1:8761` y `eureka-2:8762` | `BANCO_EUREKA` (solo sin Config Server) |
| `management.server.address` | `127.0.0.1` (perfil `tls`) | `0.0.0.0` en `nube` | — |
| `resilience4j.*` | no aplica | no aplica | — |
| Certificados y clave de los almacenes | — | — (nunca van en el Config Server) | `BANCO_CERTIFICADOS`, `BANCO_ALMACEN_CLAVE` |

`notificaciones-service.properties` solo trae la identidad del servicio (`info.app.*`); no hay reglas de negocio
centralizadas.

## Escalabilidad

En el compose corre una sola instancia, con hostname y puertos fijos: no se escala con `--scale`. Dos instancias en el
mismo grupo de consumidores (`spring.application.name=notificaciones-service`) se repartirían las particiones sin
coordinación adicional, pero las notificaciones que guarda cada instancia viven solo en su memoria: un cliente podría
recibir el aviso en una instancia distinta de la que atendió su consulta anterior.

## Cómo ejecutar

Desde la raíz del repositorio, con el compose:

```bash
docker compose up -d --build                           # todo el ecosistema, en orden y por salud
docker compose up -d --build notificaciones-service    # solo este servicio y lo que necesita (kafka, config, eureka)
docker compose ps
docker compose logs -f notificaciones-service
```

Los avisos se ven al consultar la API con un token de banco-auth que traiga `notificaciones.leer`; el flujo completo, con
los avisos de cada transferencia, lo recorre `bash banco-xyz-cloud/scripts/saga_transferencias.sh` (ver el
[README de infraestructura](../banco-xyz-cloud/README.md)).

Fuera del compose no es una vía soportada en esta entrega: el compose no publica Kafka. Las pruebas no necesitan ninguna
infraestructura (usan un Kafka embebido).

## Construir y probar

```bash
./mvnw verify
```

20 pruebas. El informe de cobertura JaCoCo queda en `target/site/jacoco/index.html`.

## Pruebas

| Clase | Pruebas | Qué comprueba |
|---|---|---|
| `ServicioDeNotificacionesTest` | 8 | Los textos en español de cada tipo de evento (monto con formato chileno, motivo traducido, incluida la compensación y un motivo sin traducir), que `FondosReservados` y un tipo ignorado no generan notificación, la deduplicación por `eventoId` y el recorte a las 50 notificaciones más recientes por cliente |
| `NotificacionesEnKafkaTest` | 6 | El servicio completo con un Kafka embebido y la API real, con un token que trae `SCOPE_notificaciones.leer`: `TransferenciaCompletada` aparece para el cliente del evento y no para otro; el mismo evento entregado dos veces deja una sola notificación; `FondosReservados` no notifica; un mensaje ilegible termina en `cuentas.transferencias.DLT`; sin token la API responde `401` |
| `LectorDeEventosTest` | 6 | Un evento v1 se lee como v2 en CLP sin perder datos; un v2 se lee con su moneda; un campo desconocido se ignora; versión 3 o 0 lanza `VersionNoSoportada`; texto, JSON de otro tipo o sin `eventoId` lanza `EventoInvalido`; un evento nuevo se escribe en la versión actual |

## Enlaces

- [README general](../README.md)
- [Infraestructura Spring Cloud y compose](../banco-xyz-cloud/README.md)
