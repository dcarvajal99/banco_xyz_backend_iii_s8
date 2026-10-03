# transferencias-service — Banco XYZ

Puerta de entrada de la saga coreografiada de transferencias del Banco XYZ. Recibe la solicitud de un cliente
autenticado con OAuth 2.0, la prevalida contra el core, la guarda **PENDIENTE** en su propia base y responde de
inmediato: el resultado lo deciden después el core (reserva de fondos) y antifraude-service, comunicándose por eventos
en Kafka. Este servicio escucha esos resultados y deja la transferencia en su estado final, con la traza completa
disponible para el cliente.

Es a la vez **servidor de recursos** OAuth 2.0 (valida el token del cliente que transfiere) y **cliente OAuth 2.0**
(pide su propio token a banco-auth para consultar el core).

## Ficha

| Campo | Valor |
|---|---|
| Puerto HTTPS | `8082` (perfiles `tls,nube`, fijados en la imagen) |
| Puerto de operación (health, circuitos) | `9082`, sin TLS; el compose lo publica solo en `127.0.0.1` |
| Nombre en Eureka | `TRANSFERENCIAS-SERVICE` (instancia HTTPS) |
| Paquete raíz | `com.bancoxyz.transferencias` (`transferencia/`, `core/`, `evento/`, `outbox/`, `seguridad/`, `config/`) |
| Stack | Spring Boot 3.5.16, Spring Cloud 2025.0.3, Spring Security (resource server y client), Resilience4j, Spring Kafka, Flyway |
| Base de datos | PostgreSQL `banco_xyz`, esquema propio `transferencias` (Flyway `V1`): `transferencia`, `historial`, `evento_procesado`, `outbox`. En `nube` la URL (`jdbc:postgresql://db:5432/banco_xyz`) la entrega el Config Server |
| Identidad ante el core | Token OAuth 2.0 `client_credentials` de banco-auth (cliente `transferencias-service`, scope `core.cuentas.leer`) más su certificado de cliente (mTLS). Ya no hay clave Basic |
| Configuración central | `banco-xyz-cloud/configuracion/transferencias-service.properties` + `transferencias-service-nube.properties` + `application.properties` + `application-nube.properties` |

## API

| Método | Ruta | Autorización | Respuesta |
|---|---|---|---|
| POST | `/api/v1/transferencias` | JWT con `SCOPE_transferencias.escribir` | `202 Accepted` + `Location` (nueva); `200 OK` + `Idempotency-Replayed: true` (reintento con la misma `Idempotency-Key`) |
| GET | `/api/v1/transferencias/{id}` | JWT con `SCOPE_transferencias.leer` | La transferencia si es del cliente del token |

El cuerpo de la solicitud es `{cuentaOrigen, cuentaDestino, monto}` (monto positivo, hasta 2 decimales) y exige el
encabezado `Idempotency-Key`. Códigos de error:

| Estado | Código | Cuándo |
|---|---|---|
| 400 | `SOLICITUD_INVALIDA` | Cuentas o monto ausentes o inválidos |
| 400 | `IDEMPOTENCY_KEY_REQUERIDA` | Falta el encabezado `Idempotency-Key` |
| 401 | — | Sin token, token de otra audiencia, vencido, mal firmado o de una clave retirada |
| 403 | — (`WWW-Authenticate: Bearer error="insufficient_scope"`) | Token válido sin el scope de la operación (por ejemplo, solo `transferencias.leer` en el `POST`) |
| 404 | `CUENTA_ORIGEN_NO_ENCONTRADA` | El core respondió 4xx al prevalidar (no existe o no es del usuario; no se distingue, para no confirmar que existe) |
| 404 | `TRANSFERENCIA_NO_ENCONTRADA` | El `GET` no encuentra una transferencia del cliente con ese id |
| 409 | `IDEMPOTENCIA_CONFLICTO` | La misma `Idempotency-Key` se usó antes con otra cuenta o monto |
| 422 | `MISMA_CUENTA` | Cuenta de origen igual a la de destino |

## Seguridad: el rol OAuth de este servicio

### Como servidor de recursos

`ConfiguracionSeguridad` exige un JWT de banco-auth y un scope por operación; todo lo demás se niega (`denyAll`), salvo
`/error` y los `GET` del actuator. El actuator es de solo lectura: su puerto escucha en la red de los contenedores, y el
`POST /actuator/circuitbreakers/{nombre}` de Resilience4j, que forzaría el estado de un circuito, recibe 401 sin token y
403 con cualquier token:

| Operación | Autoridad exigida |
|---|---|
| `POST /api/v1/transferencias` | `SCOPE_transferencias.escribir` |
| `GET /api/v1/transferencias/*` | `SCOPE_transferencias.leer` |

`DecodificadorDeTokens` valida el token contra el **JWK Set** de banco-auth (`banco.jwt.jwk-set-uri`; en `nube`
`https://banco-auth:8081/oauth2/jwks`), no contra un secreto compartido:

| Validación | Detalle |
|---|---|
| Firma | RS256 con la clave cuyo `kid` trae el token; un `kid` desconocido fuerza a consultar el JWK Set de nuevo |
| Emisor | `banco.jwt.emisor` |
| Audiencia | `banco.jwt.audiencia` (`banco-xyz`) |
| Vencimiento | **Sin tolerancia** (`JwtTimestampValidator(Duration.ZERO)`, en vez de los 60 s que acepta Spring) |
| Caché del JWK Set | 30 s (`banco.jwt.cache-jwks`), **sin refresco anticipado** (`refreshAheadCache(false)`): una clave retirada deja de aceptarse a lo sumo a los 30 s |
| Transporte | El JWK Set se pide por HTTPS confiando solo en la CA del banco (bundle `cliente-core`) |

`UsuarioDelToken` toma del token `usuario_id`, `cliente_id` y `sub`; sin los dos ids lanza error. Cada cliente solo ve
sus transferencias.

### Como cliente: su propio token para llamar al core

`core/TokenDeServicio` obtiene el token con que `ClienteCore` llama al core:

| Aspecto | Detalle |
|---|---|
| Flujo | `client_credentials` contra `banco.jwt.token-uri` (en `nube` `https://banco-auth:8081/oauth2/token`), cliente `transferencias-service`, scope `core.cuentas.leer`, autenticación `client_secret_basic` |
| Gestor | `AuthorizedClientServiceOAuth2AuthorizedClientManager` con `InMemoryOAuth2AuthorizedClientService` |
| Caché | El token se reutiliza hasta **30 s antes de vencer** (`clockSkew(30 s)`): no hay una llamada a banco-auth por cada consulta al core |
| Principal | Fijo: `transferencias-service`. Es un token del servicio, no del usuario, aunque la solicitud HTTP que lo origina traiga el JWT de un cliente |
| `RestClient` propio | El endpoint de tokens se llama con un `RestClient` aparte: sin balanceo (URL fija de banco-auth), con el bundle TLS del servicio (confía solo en la CA del banco) y timeouts de 1 s (conexión) y 3 s (lectura) |
| Interceptor | `OAuth2ClientHttpRequestInterceptor` agrega `Authorization: Bearer <token de servicio>` a cada llamada al core |
| Secreto | `BANCO_OAUTH_TRANSFERENCIAS_SECRETO` |

El core acepta ese token si trae el scope `core.cuentas.leer` y el CN del certificado de cliente de la conexión es el
`sub` del token (`transferencias-service`).

## Validación PREVIA vs. DIFERIDA

Antes de aceptar la transferencia, `ClienteCore.validarCuentaDeOrigen()` llama a `GET /cuentas/{id}` del core con el
encabezado `X-Usuario-Id`, protegido con Resilience4j por anotaciones: `@Bulkhead`, `@CircuitBreaker` y `@Retry` sobre
la instancia `core` (orden `Retry(CircuitBreaker(Bulkhead(llamada)))`).

- Si el core responde, se sabe al instante si la cuenta es del usuario (**404** si no, que se traduce a
  `CUENTA_ORIGEN_NO_ENCONTRADA` y la transferencia ni se guarda). Validación **PREVIA**.
- Si el core no responde, el fallback no rechaza: acepta la transferencia con validación **DIFERIDA**. El core vuelve a
  validar todo (propiedad, tipo de cuenta, saldo) al reservar los fondos dentro de la saga, que es la validación que
  manda. Así una caída del core no impide recibir transferencias: quedan esperando en Kafka y se procesan cuando vuelve.

El fallback se sobrecarga por tipo de excepción, y cada caso termina en DIFERIDA:

| Excepción | Causa |
|---|---|
| `ResourceAccessException` | Sin conexión |
| `HttpServerErrorException` | El core respondió 5xx |
| `CallNotPermittedException` | Circuito abierto |
| `OAuth2AuthorizationException` | **banco-auth no entregó el token de servicio** (caído o rechazó al cliente): sin token no se puede consultar el core |
| `BulkheadFullException` | **Bulkhead lleno**: ya hay demasiadas llamadas simultáneas al core; esta no espera turno |
| `IllegalStateException` | LoadBalancer sin instancias: el core se dio de baja en Eureka |

Un 4xx del core (`ErrorDeNegocioDelCore`) no tiene fallback, no se reintenta y no cuenta como falla del circuito.

`spring.cloud.loadbalancer.retry.enabled=false`: spring-kafka trae `spring-retry`, y con el reintento propio de Spring
Cloud LoadBalancer activado se sumaría al `@Retry` de Resilience4j sobre la misma llamada. Se apaga para que exista un
solo mecanismo de reintento.

## Resilience4j: las políticas vienen del Config Server

El `application.properties` de este servicio **no trae ninguna propiedad `resilience4j.*`**. Las políticas son
compartidas y se definen una vez en `configuracion/application.properties` como `configs` (`http-interno` y
`publicacion-kafka`); `transferencias-service.properties` declara las instancias de este servicio con `base-config` y su
excepción propia; `application-nube.properties` ajusta los valores para el entorno en contenedores. Las pruebas usan una
copia en `src/test/resources/application-prueba.properties`, que `scripts/verificar_coherencia.sh` comprueba que sea
idéntica a la central.

| Instancia | Mecanismo | `base-config` | Ajustes propios |
|---|---|---|---|
| `core` | `@Bulkhead`, `@CircuitBreaker`, `@Retry` en `ClienteCore` | `http-interno` | `ignore-exceptions`: `ErrorDeNegocioDelCore` (una cuenta ajena es una respuesta válida) y `BulkheadFullException` (exceso de llamadas propias, no falla del core) |
| `kafka` | `Decorators.ofRunnable(envío).withCircuitBreaker(kafka).withRetry(kafka)` en `PublicadorDeOutbox` | `publicacion-kafka` | `record-exceptions` y `retry-exceptions`: `ErrorDePublicacion` |

| Parámetro | Local (base) | Nube |
|---|---|---|
| `core`: `bulkhead.max-concurrent-calls` | 20 | 25 |
| `core`: `circuitbreaker.sliding-window-size` / `minimum-number-of-calls` | 6 / 3 | 10 / 5 |
| `core`: `circuitbreaker.failure-rate-threshold` | 50 % | 50 % |
| `core`: `circuitbreaker.wait-duration-in-open-state` | 10 s | 15 s |
| `core`: `circuitbreaker.permitted-number-of-calls-in-half-open-state` | 2 | 3 |
| `core`: `slow-call-duration-threshold` / `slow-call-rate-threshold` | no definidos | 2 s / 80 % |
| `core`: `retry.max-attempts` / `wait-duration` | 2 / 200 ms | 3 / 300 ms con backoff exponencial ×2 |
| `core`: `retry.retry-exceptions` | `ResourceAccessException` | igual |
| `kafka`: `circuitbreaker.sliding-window-size` / `minimum-number-of-calls` | 4 / 2 | 6 / 3 |
| `kafka`: `circuitbreaker.failure-rate-threshold` | 50 % | 50 % |
| `kafka`: `circuitbreaker.wait-duration-in-open-state` | 10 s | 15 s |
| `kafka`: `circuitbreaker.permitted-number-of-calls-in-half-open-state` | 1 | 1 |
| `kafka`: `retry.max-attempts` / `wait-duration` | 3 / 300 ms | 4 / 500 ms |

"Local" es lo que entrega el Config Server sin perfil y lo que usan las pruebas; "Nube" es lo que recibe el contenedor
con el perfil `nube`.

## Eventos, Kafka y outbox

`ServicioDeTransferencias.solicitar()` guarda la transferencia **PENDIENTE** y su evento `TransferenciaSolicitada` en
`transferencias.outbox`, en la misma transacción (transactional outbox, mismo diseño que el del core).
`PublicadorDeOutbox` los envía a Kafka después con los decoradores de la instancia `kafka`
(`@Scheduled(fixedDelayString = banco.outbox.intervalo-ms:500)`). Con el circuito abierto no se insiste: el resto de los
eventos espera en orden en la tabla hasta la próxima pasada, y nada se pierde mientras Kafka está caído.

| Tópico | Dirección | Eventos |
|---|---|---|
| `transferencias.solicitadas` | Produce (outbox) | `TransferenciaSolicitada` |
| `cuentas.reservas` | Consume (grupo `transferencias-service`) | `FondosReservados`, `FondosRechazados` |
| `cuentas.transferencias` | Consume (mismo grupo) | `TransferenciaCompletada`, `ReservaLiberada` |
| `cuentas.reservas.DLT`, `cuentas.transferencias.DLT` | Produce | Mensajes que no se pudieron leer o procesar |

`ConsumidorDeResultados` llama a `ServicioDeTransferencias.aplicar()`:

| Evento | Efecto |
|---|---|
| `FondosReservados` | → `FONDOS_RESERVADOS` |
| `FondosRechazados` | → `RECHAZADA` |
| `TransferenciaCompletada` | → `COMPLETADA` |
| `ReservaLiberada` (compensación de antifraude) | → `RECHAZADA`, con el motivo |

`Transferencia.Estado` solo avanza: **PENDIENTE → FONDOS_RESERVADOS → COMPLETADA** o **RECHAZADA**. Los estados finales
no cambian más (`avanzarA` los protege): un evento atrasado no los pisa. Cada evento que tocó la transferencia queda en
`historial` y se devuelve en el `GET` como la lista `historial`, en orden. El consumidor es idempotente: cada `eventoId`
se registra en `evento_procesado` antes de aplicarse.

### Versión del evento (v2)

`EventoDeTransferencia` lleva `version` (`VERSION_ACTUAL = 2`) y `moneda` (`CLP`). `LectorDeEventos` lee el sobre así:

| Caso | Resultado |
|---|---|
| Sin `version` ni `moneda` (v1, semana 7) | **Upcasting**: se lee como v2 en `CLP`, sin perder datos |
| `version` = 2 | Se lee tal cual, con su moneda |
| Campo que este servicio no conoce | Se ignora (**lector tolerante** explícito, sin depender del `ObjectMapper`) |
| `version` mayor que 2 o inválida (< 1) | `VersionNoSoportada`: no se adivina, va a `<tópico>.DLT` **sin reintentos**, para reprocesarlo cuando el consumidor se actualice |
| Texto que no es JSON, JSON sin `eventoId`, `tipo` o `transferenciaId` | `EventoInvalido`: directo a la DLT, sin reintentos |

Convención de evolución de los eventos del banco: se despliegan **primero los consumidores y después los productores**,
porque un consumidor que no entiende una versión nueva la manda a la DLT. Un campo opcional agregado **no sube la
versión** (los consumidores ignoran campos desconocidos); la versión sube solo cuando los consumidores deben entender
algo nuevo. Este servicio produce siempre en la versión actual. Un fallo transitorio se reintenta dos veces con un
segundo de espera antes de ir a la DLT (`DefaultErrorHandler`). La copia de `EventoDeTransferencia`, `LectorDeEventos` y
`VersionNoSoportada` es la misma en los cuatro servicios de la saga (`verificar_coherencia.sh` lo comprueba).

## Imagen Docker

Construcción multi-etapa desde el código fuente (`transferencias-service/Dockerfile`, contexto `transferencias-service/`):

| Aspecto | Valor |
|---|---|
| Etapa de construcción | `maven:3.9-eclipse-temurin-21`: primero solo el `pom.xml` (`dependency:go-offline`), después `src/` y `package -DskipTests`; el jar se separa en capas de Spring Boot (`jarmode tools extract --layers --launcher`) |
| Etapa final | `eclipse-temurin:21-jre-alpine`: solo el JRE y las capas `dependencies`, `spring-boot-loader`, `snapshot-dependencies` y `application` |
| Usuario | `banco`, uid/gid `10001`, sin privilegios |
| Puertos | `8082` (HTTPS) y `9082` (operación) |
| `HEALTHCHECK` | `wget` a `http://127.0.0.1:9082/actuator/health` buscando `"status":"UP"`; cada 10 s, 3 s de límite, 120 s de arranque, 6 reintentos |
| JVM | `JAVA_TOOL_OPTIONS=-XX:MaxRAMPercentage=60 -XX:+UseSerialGC -XX:+ExitOnOutOfMemoryError` |
| Perfiles | `SPRING_PROFILES_ACTIVE=tls,nube` |
| Límite de memoria en el compose | 512 MB |

Variables que recibe del `docker-compose.yaml` de la raíz (valores por defecto `-dev` en `.env.ejemplo`):

| Variable | Para qué |
|---|---|
| `BANCO_CONFIG_SERVER`, `BANCO_CONFIG_USUARIO`, `BANCO_CONFIG_CLAVE`, `BANCO_CONFIG_FAIL_FAST=true` | Config Server (con `fail-fast`, si lo rechaza el servicio no arranca) |
| `BANCO_ALMACEN_CLAVE`, `BANCO_CERTIFICADOS=/certificados` | Clave de los `.p12` y carpeta de la PKI (volumen `certificados`, solo lectura) |
| `EUREKA_INSTANCE_HOSTNAME=transferencias-service` | Nombre con que se registra en Eureka |
| `BANCO_DB_USUARIO`, `BANCO_DB_CLAVE` | Usuario y clave de PostgreSQL |
| `BANCO_OAUTH_TRANSFERENCIAS_SECRETO` | Secreto del cliente OAuth `transferencias-service` |

Depende (por salud) de `db`, `kafka`, `config-server`, `banco-core-api` y `banco-auth`, y publica `127.0.0.1:8082` y
`127.0.0.1:9082`.

## Configuración

| Propiedad | En el jar (`application.properties`) | Config Server | Variable de entorno |
|---|---|---|---|
| `spring.datasource.url` | `jdbc:postgresql://localhost:5439/banco_xyz` | `jdbc:postgresql://db:5432/banco_xyz` (`transferencias-service-nube.properties`) | — |
| `spring.datasource.username` / `password` | `banco` / valor de desarrollo | — | `BANCO_DB_USUARIO`, `BANCO_DB_CLAVE` |
| `banco.core.url` / `descubrimiento` | `https://localhost:8080/api/v1` / `false` | `https://banco-core-api/api/v1` / `true` | — |
| `banco.jwt.emisor` / `audiencia` / `jwk-set-uri` | `https://localhost:8081`, `banco-xyz`, `https://localhost:8081/oauth2/jwks` | Los mismos en `application.properties`; en `nube`, `https://banco-auth:8081` y `https://banco-auth:8081/oauth2/jwks` | — |
| `banco.jwt.cache-jwks` | `30s` | — | — |
| `banco.jwt.token-uri` | `https://localhost:8081/oauth2/token` (valor por defecto del proveedor OAuth) | `https://localhost:8081/oauth2/token`; en `nube`, `https://banco-auth:8081/oauth2/token` | — |
| `spring.security.oauth2.client.registration.core.*` | cliente `transferencias-service`, `client_credentials`, scope `core.cuentas.leer` | — | `BANCO_OAUTH_TRANSFERENCIAS_SECRETO` (secreto) |
| `spring.kafka.bootstrap-servers` | `${BANCO_KAFKA:localhost:9092}` | `localhost:9092`; en `nube`, `kafka:9092` | `BANCO_KAFKA` (solo sin Config Server: con él manda el Config Server) |
| `spring.kafka.listener.concurrency` / `banco.kafka.particiones` | `3` / `3` | `banco.kafka.particiones=3` | — |
| `banco.outbox.intervalo-ms` | `500` | — | — |
| `eureka.client.service-url.defaultZone` | `${BANCO_EUREKA:...}` con los dos nodos locales | igual; en `nube`, `eureka-1:8761` y `eureka-2:8762` | `BANCO_EUREKA` (solo sin Config Server) |
| `management.server.address` | `127.0.0.1` (perfil `tls`) | `0.0.0.0` en `nube` | — |
| `resilience4j.*` | **ninguna** | `http-interno`, `publicacion-kafka` (compartidas), instancias `core` y `kafka`, y valores de `nube` | — |
| Certificados y clave de los almacenes | — | — (nunca van en el Config Server) | `BANCO_CERTIFICADOS`, `BANCO_ALMACEN_CLAVE` |

## Cómo ejecutar

Desde la raíz del repositorio, con el compose:

```bash
docker compose up -d --build                           # todo el ecosistema, en orden y por salud
docker compose up -d --build transferencias-service    # solo este servicio y lo que necesita para arrancar
docker compose ps
docker compose logs -f transferencias-service
```

La saga de punta a punta se recorre con `bash banco-xyz-cloud/scripts/saga_transferencias.sh`; el core caído y Kafka
caído, con `resiliencia_core.sh` y `resiliencia_kafka.sh` (ver el [README de infraestructura](../banco-xyz-cloud/README.md)).

Fuera del compose no es una vía soportada en esta entrega: el compose no publica la base, Kafka ni el core. Las pruebas
no necesitan ninguna infraestructura.

## Construir y probar

```bash
./mvnw verify
```

22 pruebas. Usan H2 en modo PostgreSQL (`MODE=PostgreSQL`) y Kafka embebido solo en `SagaEnKafkaTest`; el resto simula el
core con `MockRestServiceServer`, reemplaza el gestor de tokens por uno que entrega siempre el mismo token de servicio y
apaga la publicación real del outbox (`banco.outbox.publicar=false`). El informe de cobertura JaCoCo queda en
`target/site/jacoco/index.html`.

## Pruebas

| Clase | Pruebas | Qué comprueba |
|---|---|---|
| `ApiDeTransferenciasTest` | 6 | Sin token 401; token sin `transferencias.escribir` (ninguno o solo lectura) 403; transferencia válida: el core recibe el token de servicio como `Bearer`, 202 con `Location`, `PENDIENTE`, validación `PREVIA` y el evento en el outbox; `Idempotency-Key` repetida devuelve la misma transferencia (200, `Idempotency-Replayed`) y con otro monto 409; cuenta ajena o inexistente 404 sin guardar nada; rechazos que no llegan al core (sin `Idempotency-Key`, monto inválido, misma cuenta); cada cliente ve solo sus transferencias |
| `CircuitoDelCoreTest` | 5 | Core caído: 202 con validación `DIFERIDA`, a la tercera falla el circuito abre y deja de llamar al core; core dado de baja en Eureka también da `DIFERIDA` sin reintento; cuentas ajenas (404) no abren el circuito; bulkhead lleno (20 llamadas simultáneas) da `DIFERIDA` sin llamar al core ni contar como falla; el estado del circuito no se puede forzar por el actuator (401 sin token, 403 con token) |
| `ResultadosDeLaSagaTest` | 3 | `FondosReservados` + `TransferenciaCompletada`: `PENDIENTE` → `FONDOS_RESERVADOS` → `COMPLETADA`, con historial; `ReservaLiberada` (rechazo de antifraude) deja `RECHAZADA` con el motivo; un evento repetido se ignora y uno atrasado no hace retroceder el estado |
| `KafkaCaidoTest` | 1 | Con Kafka caído la API sigue respondiendo 202; los eventos esperan en el outbox, el circuito `kafka` abre y salen cuando Kafka vuelve |
| `SagaEnKafkaTest` | 1 | Con Kafka embebido: el `POST` produce `TransferenciaSolicitada` en el tópico con la cuenta como clave; `FondosReservados` y `TransferenciaCompletada` mueven la transferencia a `COMPLETADA` |
| `LectorDeEventosTest` | 6 | Un evento v1 se lee como v2 en CLP; un v2 se lee con su moneda; un campo desconocido se ignora; versión 3 o 0 lanza `VersionNoSoportada`; texto, JSON de otro tipo o sin `eventoId` lanza `EventoInvalido`; un evento nuevo se escribe en la versión actual (`version` primero, moneda CLP) |

`PruebaDeTransferencias` es la base común (core simulado, JWT de prueba, tablas limpias y el gestor de tokens de servicio).

## Limitaciones conocidas

- Cualquier 4xx del core al prevalidar (incluidos un 401 o 403 por un token o un certificado rechazado) se traduce a
  `CUENTA_ORIGEN_NO_ENCONTRADA` (404): `ClienteCore` lanza `ErrorDeNegocioDelCore` para todo 4xx.
- Los tokens de servicio se guardan en memoria; un reinicio pide uno nuevo a banco-auth.

## Enlaces

- [README general](../README.md)
- [Infraestructura Spring Cloud y compose](../banco-xyz-cloud/README.md)
