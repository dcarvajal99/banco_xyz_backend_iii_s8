# banco-core-api — Banco XYZ

Backend principal del Banco XYZ y único dueño de los datos y del dinero. Abre las cuentas del cierre vigente al
arrancar, aplica las reglas que deben cumplirse sin importar el canal —no sobregirar, límite diario, bloqueo por PIN—
y autoriza cada llamada por canal (mTLS más Basic o token OAuth 2.0) y por usuario o tarjeta. Es además el **corazón de
la saga coreografiada de transferencias**: reserva fondos, acredita o compensa según lo que decida antifraude-service, y
todo eso viaja por Kafka con un transactional outbox propio.

En la semana 8 el core pasa a ser un **servidor de recursos OAuth 2.0** para el tráfico servicio a servicio:
transferencias-service ya no entra con una clave Basic sino con un token `client_credentials` emitido por banco-auth.

## Ficha

| Campo | Valor |
|---|---|
| Puerto HTTPS | `8080` (perfiles `tls,nube`, fijados en la imagen). El compose **no** lo publica: solo se alcanza dentro de la red `banco-xyz` y exige certificado de cliente |
| Puerto de operación (health, métricas, circuitos) | `9080`, sin TLS; el compose lo publica solo en `127.0.0.1` |
| Nombre en Eureka | `BANCO-CORE-API` (instancia HTTPS) |
| Paquete raíz | `com.bancoxyz.core` |
| Stack | Spring Boot 3.5.16, Spring Cloud 2025.0.3, Spring Security (resource server), Spring Data JPA, Flyway, Spring Kafka, Resilience4j; se compila para Java 17 y corre sobre un JRE 21 |
| Base de datos | PostgreSQL `banco_xyz`: esquema `public` (volcado SQL de semanas anteriores, el core solo lo lee) y esquema `core` (lo escribe el core con Flyway: `cliente`, `usuario`, `cuenta`, `tarjeta`, `operacion`, `reserva`, `evento_procesado`, `outbox`). En `nube` la URL (`jdbc:postgresql://db:5432/banco_xyz`) la entrega el Config Server |
| Configuración central | `banco-xyz-cloud/configuracion/banco-core-api.properties` + `banco-core-api-nube.properties` + `application.properties` + `application-nube.properties` |

## Su papel en la saga

`ServicioDeTransferencias` implementa los tres pasos del core dentro de la saga coreografiada, cada uno una
transacción local que cambia saldos y guarda en el outbox el evento que avisa el resultado:

| Paso | Dispara con | Hace | Publica |
|---|---|---|---|
| **Reservar** | `TransferenciaSolicitada` (de transferencias-service) | Valida y retiene el monto en la cuenta de origen (baja `saldo_disponible`) | `FondosReservados` o `FondosRechazados` (con motivo) en `cuentas.reservas` |
| **Confirmar** | `TransferenciaAprobada` (de antifraude-service) | Acredita la cuenta de destino y registra los dos movimientos (`TRANSF_ENVIADA` / `TRANSF_RECIBIDA`) | `TransferenciaCompletada` en `cuentas.transferencias` |
| **Liberar (compensación)** | `TransferenciaRechazada` (de antifraude-service) | Devuelve a la cuenta de origen el monto que había quedado retenido | `ReservaLiberada` en `cuentas.transferencias` |

Motivos de rechazo al reservar: `MONTO_INVALIDO`, `MISMA_CUENTA`, **`MONEDA_NO_SOPORTADA`**, `CUENTA_ORIGEN_INEXISTENTE`,
`CUENTA_AJENA`, `CUENTA_NO_ADMITE_RETIROS`, `CUENTA_DESTINO_INEXISTENTE`, `SALDO_INSUFICIENTE`. Las cuentas del banco son en
pesos chilenos: un evento v2 cuya `moneda` no sea `CLP` se rechaza con `MONEDA_NO_SOPORTADA` sin tocar saldos. Los dos
bloqueos de cuenta al confirmar se toman siempre en el mismo orden (id ascendente), para que dos transferencias cruzadas
no se bloqueen mutuamente.

Idempotencia: un evento ya registrado en `core.evento_procesado` (mismo `eventoId`) se ignora, y una reserva que ya no
está `RESERVADA` no se vuelve a confirmar ni a liberar: Kafka puede entregar un evento dos veces y el saldo cambia una
sola vez.

`V2__saga_transferencias.sql` (Flyway) crea las tres tablas que sostienen esto:

| Tabla | Qué guarda |
|---|---|
| `core.reserva` | Una fila por transferencia que llegó al core: cuentas, monto y estado (`RESERVADA`, `RECHAZADA`, `CONFIRMADA`, `LIBERADA`). Sin FK a `cuenta`: también registra las rechazadas por cuenta inexistente |
| `core.evento_procesado` | Consumidor idempotente: un evento ya procesado se ignora |
| `core.outbox` | Transactional outbox: el evento se guarda en la misma transacción que el cambio de saldo |

## Eventos

| Tópico | Dirección | Eventos | Notas |
|---|---|---|---|
| `transferencias.solicitadas` | Consume | `TransferenciaSolicitada` | Dispara `reservar()`; un tipo desconocido se ignora con un log |
| `antifraude.decisiones` | Consume | `TransferenciaAprobada` → `confirmar()`; `TransferenciaRechazada` → `liberar()` | |
| `cuentas.reservas` | Produce (outbox) | `FondosReservados`, `FondosRechazados` | |
| `cuentas.transferencias` | Produce (outbox) | `TransferenciaCompletada`, `ReservaLiberada` | |
| `transferencias.solicitadas.DLT`, `antifraude.decisiones.DLT` | Produce | — | Mensaje ilegible, sin `eventoId`/`tipo`/`transferenciaId` o de una versión que el core no entiende; no se reintenta. El destino se fija explícito (`<tópico>.DLT`): Spring Kafka 3 usa por defecto `<tópico>-dlt`, que no existe con la creación automática apagada |

Los cuatro tópicos de la saga tienen 3 particiones (`banco.kafka.particiones`), clave = cuenta de origen.
`ConsumidorDeTransferencias` maneja los dos consumidores; `ConfiguracionKafka` declara los tópicos (`KafkaAdmin` solo crea
lo que falta, aunque otro servicio los declare también) y el `DefaultErrorHandler` (2 reintentos a 1 s antes del DLT).

### Eventos v2: versión y moneda

`EventoDeTransferencia` lleva `version` (`VERSION_ACTUAL = 2`) y `moneda` (`CLP`); el core produce siempre en la versión
actual y conserva la moneda del evento que recibió. `LectorDeEventos` lee el sobre así:

| Caso | Resultado |
|---|---|
| Sin `version` ni `moneda` (v1, semana 7) | **Upcasting**: se lee como v2 en `CLP`, sin perder datos |
| `version` = 2 | Se lee tal cual, con su moneda |
| Campo que el core no conoce | Se ignora (**lector tolerante**) |
| `version` mayor que 2 o inválida | `VersionNoSoportada`: va a la DLT **sin reintentos**, para reprocesarlo cuando el consumidor se actualice |
| Texto que no es JSON, JSON sin `eventoId`, `tipo` o `transferenciaId` | `EventoInvalido`: directo a la DLT |

Convención de evolución de los eventos del banco: **primero los consumidores, después los productores**, porque un
consumidor que no entiende una versión nueva la manda a la DLT. Un campo opcional agregado **no sube la versión**; esta
sube solo cuando los consumidores deben entender algo nuevo. La copia del sobre y del lector es la misma en los cuatro
servicios de la saga (`scripts/verificar_coherencia.sh` lo comprueba).

## Outbox y publicador

`PublicadorDeOutbox` envía los eventos pendientes a Kafka con Resilience4j como **decoradores programáticos**
(`Decorators.ofRunnable(envío).withCircuitBreaker(kafka).withRetry(kafka)`), el mismo diseño que usa
transferencias-service. Con el circuito abierto no se insiste: los eventos siguen en `core.outbox` y salen en orden
(`for update skip locked`, para que otra instancia del core no publique el mismo evento dos veces) cuando Kafka vuelve.

**La política no vive en el jar.** El `application.properties` del core no trae propiedades `resilience4j.*`: la política
compartida `publicacion-kafka` está en `configuracion/application.properties`, la instancia `kafka` (con
`base-config=publicacion-kafka` y `ErrorDePublicacion` como `record-exceptions` y `retry-exceptions`) en
`banco-core-api.properties`, y `application-nube.properties` ajusta los valores para el entorno en contenedores. Las
pruebas usan una copia en `src/test/resources/application-prueba.properties`, que `scripts/verificar_coherencia.sh`
comprueba que sea idéntica a la central.

| Parámetro (instancia `kafka`) | Local (base) | Nube |
|---|---|---|
| `retry.max-attempts` | 3 | 4 |
| `retry.wait-duration` | 300 ms | 500 ms |
| `circuitbreaker.sliding-window-size` | 4 | 6 |
| `circuitbreaker.minimum-number-of-calls` | 2 | 3 |
| `circuitbreaker.failure-rate-threshold` | 50 % | 50 % |
| `circuitbreaker.wait-duration-in-open-state` | 10 s | 15 s |
| `circuitbreaker.permitted-number-of-calls-in-half-open-state` | 1 | 1 |

"Local" es lo que entrega el Config Server sin perfil y lo que usan las pruebas; "Nube" es lo que recibe el contenedor
con el perfil `nube`. El core no hace llamadas HTTP salientes: no usa las políticas `http-interno`.

## API

| Método | Ruta | Credencial aceptada |
|---|---|---|
| POST | `/api/v1/autenticacion/usuarios` | Canal web o móvil (Basic + mTLS, semanas anteriores) y **banco-auth** (Basic + mTLS) |
| GET | `/api/v1/autenticacion/usuarios/{usuario}` | Solo **banco-auth** (canal AUTENTICACION, Basic + mTLS). Identifica sin clave al cliente cuya cuenta de GitHub está vinculada (la persona ya se autenticó con GitHub): 200 con el contrato `usuario-autenticado.json`, 404 `USUARIO_NO_ENCONTRADO`, 423 bloqueado, 403 ejecutivo. No toca el contador de intentos |
| POST | `/api/v1/autenticacion/tarjetas` | Canal cajero |
| GET | `/api/v1/clientes` | Canal web (solo usuario ejecutivo) |
| GET | `/api/v1/clientes/{clienteId}/cuentas` | Canal web o móvil |
| GET | `/api/v1/cuentas/{cuentaId}` | Canal web, móvil o cajero, y **transferencias-service** (token OAuth 2.0 + mTLS) |
| GET | `/api/v1/cuentas/{cuentaId}/movimientos` | Canal web o móvil |
| GET | `/api/v1/cuentas/{cuentaId}/estados-anuales` | Canal web o móvil |
| POST | `/api/v1/cuentas/{cuentaId}/retiros` | Canal cajero |
| GET | `/api/v1/cierres/vigentes` | Canal web, móvil o cajero |
| GET | `/api/v1/reportes/resumen-diario` | Canal web (solo usuario ejecutivo) |
| GET | `/api/v1/reportes/calidad` | Canal web (solo usuario ejecutivo) |

`/actuator/health`, `/actuator/metrics`, `/v3/api-docs/**`, `/swagger-ui/**` y `/error` no exigen credencial. Los
canales web, móvil y cajero (usuarios `bff-web`, `bff-movil` y `bff-cajero`) se mantienen del código de semanas
anteriores, pero **ningún BFF forma parte de esta entrega**: la semana 8 se concentra en OAuth 2.0, la configuración por
entorno y los contenedores.

## Seguridad: el rol OAuth de este servicio

El core es un **servidor de recursos**: no emite tokens, los valida. A él no llegan usuarios finales sino servicios, y
cada uno entra con dos credenciales: una que dice **quién es** (clave Basic o token OAuth 2.0) y su **certificado de
cliente** (mTLS).

| Quién entra | Credencial | Rol de canal |
|---|---|---|
| bff-web, bff-movil, bff-cajero (semanas anteriores) | Basic + certificado cuyo CN es el mismo usuario | `WEB`, `MOVIL`, `CAJERO` |
| banco-auth | Basic (`BANCO_CANAL_AUTENTICACION_CLAVE`) + certificado `banco-auth`. Solo puede verificar usuario y clave: no lee cuentas ni clientes | `AUTENTICACION` |
| transferencias-service | **Token `Bearer` OAuth 2.0 `client_credentials`** con scope `core.cuentas.leer` + certificado `transferencias-service`. Solo puede leer la cuenta del usuario para la prevalidación previa a la saga. La clave Basic anterior se eliminó | `TRANSFERENCIAS` |

- **Token de servicio.** `ConfiguracionSeguridad` registra `oauth2ResourceServer` con JWT. `DecodificadorDeTokens` valida
  contra el JWK Set de banco-auth: firma RS256 por `kid`, emisor, audiencia `banco-xyz`, vencimiento sin tolerancia
  (`Duration.ZERO`) y caché del JWK Set de 30 s sin refresco anticipado. `TokensDeServicio` convierte los scopes en
  autoridades (`SCOPE_<scope>`) y el scope `core.cuentas.leer` además da el rol de canal `TRANSFERENCIAS`: así
  `ControlDeAcceso` lo trata como antes, pero la credencial es un token firmado que vence en minutos. Un token de
  usuario (sin ese scope) no obtiene el rol y recibe 403.
- **mTLS.** `server.ssl.client-auth=want` acepta la conexión TLS sin certificado (para que Swagger y el contrato sigan
  accesibles), pero `FiltroCertificadoDeCanal` exige en `/api/**` que exista un certificado de cliente y que su CN
  coincida con la identidad autenticada: el usuario de Basic o, con token, el **`sub` del token** (el id del cliente
  OAuth). `401 CERTIFICADO_REQUERIDO` si falta, `403 CERTIFICADO_NO_CORRESPONDE` si es de otro canal.
- **Autorización por canal.** `ConfiguracionSeguridad.cadenaDelCore()` fija, por método y ruta, qué rol de canal puede
  llamarla; todo lo no listado cae en `denyAll()`.
- **Autorización por usuario.** `ControlDeAcceso` es la segunda capa: no confía en la identidad que dice el llamador,
  busca el usuario en la base por el encabezado `X-Usuario-Id` y solo entrega lo propio; ni banco-auth ni
  transferencias-service pueden ver la consola de un usuario ejecutivo. Una cuenta ajena responde
  `404 CUENTA_NO_ENCONTRADA` en vez de `403`, para no confirmar que la cuenta existe.

Resultados esperados del canal de transferencias (los recorre `scripts/proteccion_servicios.sh`):

| Llamada a `GET /api/v1/cuentas/{id}` | Respuesta |
|---|---|
| Token de servicio con `core.cuentas.leer` + su certificado | 200 |
| Antigua clave Basic de transferencias-service | 401 `NO_AUTENTICADO` |
| Token de un usuario (sin `core.cuentas.leer`) | 403 |
| Token de servicio sin certificado de cliente | 401 `CERTIFICADO_REQUERIDO` |
| Token de servicio con el certificado de otro servicio | 403 `CERTIFICADO_NO_CORRESPONDE` |

## Integridad del retiro

`ServicioDeRetiros.retirar()`, en una sola transacción y en este orden: (1) bloquea la fila de la cuenta con
`SELECT … FOR UPDATE` (`@Lock(PESSIMISTIC_WRITE)` en `RepositorioCuentas.buscarParaActualizar`); (2) revisa la clave
`Idempotency-Key` **después** del bloqueo —misma solicitud repetida devuelve el comprobante original con
`Idempotency-Replayed: true`; la misma clave con otra solicitud responde `409 IDEMPOTENCIA_CONFLICTO`—; (3) valida
tarjeta no bloqueada, cuenta de ahorro, límite diario (desde la medianoche de `America/Santiago`) y saldo; (4)
descuenta y registra la operación. La base refuerza esto con `check (saldo_disponible >= 0)` y
`unique (canal, clave_idempotencia)`. Si el bloqueo no se obtiene en 3 s (`SET lock_timeout = '3s'` en la conexión),
responde `503 CUENTA_OCUPADA` sin descontar.

## Config Server y Eureka

El Config Server responde solo por HTTPS y exige certificado de cliente del core más usuario y clave Basic
(`spring.cloud.config.tls.*`, incluida `key-password`). Con `BANCO_CONFIG_FAIL_FAST=true` (lo fija el compose) el core no
arranca si el Config Server lo rechaza. Se registra en Eureka como `BANCO-CORE-API` (instancia HTTPS, con el nombre
`banco-core-api` por `EUREKA_INSTANCE_HOSTNAME`) contra **dos nodos que se replican** (`eureka-1` y `eureka-2` en `nube`).
banco-auth y transferencias-service no conocen su dirección: la piden por nombre (`https://banco-core-api/api/v1`) con
Spring Cloud LoadBalancer. El core no depende de banco-auth para arrancar: el JWK Set se consulta al validar el primer
token.

## Contrato

`contratos/core-api/` guarda el contrato original: 15 archivos JSON, uno por respuesta. `ContratoCoreApiTest` prueba,
como proveedor, que cada respuesta real del core tiene exactamente las claves de su archivo. En semanas anteriores cada
BFF guardaba una copia; en esta entrega no hay BFF y el contrato queda como documentación de la API y prueba del
proveedor.

## Estructura

```
com.bancoxyz.core/
├── BancoCoreApiApplication.java
├── autenticacion/   ControladorDeAutenticacion, ServicioDeAutenticacion, Usuario, RepositorioUsuarios
├── cierre/          ArranqueConSincronizacion, SincronizadorDeCierre, LectorDeCierres, CierrePublicado
├── cliente/         ControladorDeClientes, Cliente, RepositorioClientes
├── config/          ConfiguracionGeneral, FiltroCorrelacion, PropiedadesCore, PropiedadesJwt
├── cuenta/          ControladorDeCuentas, ServicioDeCuentas, Cuenta, RepositorioCuentas, LectorDeMovimientos
├── error/           ManejadorDeErrores, ErrorDeNegocio, Errores, Problemas
├── operacion/       ControladorDeRetiros, ServicioDeRetiros, Operacion, RepositorioOperaciones
├── outbox/          Outbox, PublicadorDeOutbox (Resilience4j: Decorators)
├── reporte/         ControladorDeReportes, LectorDeReportes
├── seguridad/       ConfiguracionSeguridad, ControlDeAcceso, FiltroCertificadoDeCanal, Canal,
│                    DecodificadorDeTokens, TokensDeServicio (OAuth 2.0)
├── tarjeta/         Tarjeta, RepositorioTarjetas, Luhn
└── transferencia/   ServicioDeTransferencias (saga), Reserva, ConsumidorDeTransferencias, ConfiguracionKafka, Topicos,
                     EventoDeTransferencia, LectorDeEventos, VersionNoSoportada, EventoInvalido
```

## Base de datos

El esquema `public` ya no lo escribe un batch dentro de esta entrega: el resultado de la migración de semanas anteriores
(`banco-xyz-cloud/datos/01_migracion_semana3.sql`) viaja dentro de la imagen `banco-xyz/db` (PostgreSQL 17), que lo carga
desde `docker-entrypoint-initdb.d` la primera vez que se crea el volumen `datos`. El core lo lee tal como antes
(`LectorDeCierres`, cierres `COMPLETED`) y sincroniza sus cuentas al arrancar (`ArranqueConSincronizacion`). Con la base
recién creada y sin el volcado, el core arranca igual y responde `503 SIN_CIERRE_PUBLICADO`.

## Imagen Docker

Construcción multi-etapa desde el código fuente (`banco-core-api/Dockerfile`, contexto `banco-core-api/`):

| Aspecto | Valor |
|---|---|
| Etapa de construcción | `maven:3.9-eclipse-temurin-21`: primero solo el `pom.xml` (`dependency:go-offline`), después `src/` y `package -DskipTests`; el jar se separa en capas de Spring Boot (`jarmode tools extract --layers --launcher`) |
| Etapa final | `eclipse-temurin:21-jre-alpine`: solo el JRE y las capas `dependencies`, `spring-boot-loader`, `snapshot-dependencies` y `application` |
| Usuario | `banco`, uid/gid `10001`, sin privilegios |
| Puertos | `8080` (HTTPS) y `9080` (operación) |
| `HEALTHCHECK` | `wget` a `http://127.0.0.1:9080/actuator/health` buscando `"status":"UP"`; cada 10 s, 3 s de límite, 120 s de arranque, 6 reintentos |
| JVM | `JAVA_TOOL_OPTIONS=-XX:MaxRAMPercentage=60 -XX:+UseSerialGC -XX:+ExitOnOutOfMemoryError` |
| Perfiles | `SPRING_PROFILES_ACTIVE=tls,nube` |
| Límite de memoria en el compose | 640 MB |

Variables que recibe del `docker-compose.yaml` de la raíz (valores por defecto `-dev` en `.env.ejemplo`):

| Variable | Para qué |
|---|---|
| `BANCO_CONFIG_SERVER`, `BANCO_CONFIG_USUARIO`, `BANCO_CONFIG_CLAVE`, `BANCO_CONFIG_FAIL_FAST=true` | Config Server (con `fail-fast`, si lo rechaza el servicio no arranca) |
| `BANCO_ALMACEN_CLAVE`, `BANCO_CERTIFICADOS=/certificados` | Clave de los `.p12` y carpeta de la PKI (volumen `certificados`, solo lectura) |
| `EUREKA_INSTANCE_HOSTNAME=banco-core-api` | Nombre con que se registra en Eureka |
| `BANCO_DB_USUARIO`, `BANCO_DB_CLAVE` | Usuario y clave de PostgreSQL |
| `BANCO_CANAL_AUTENTICACION_CLAVE` | Clave Basic con que banco-auth entra al canal `AUTENTICACION` |

Depende (por salud) de `db`, `kafka`, `config-server` y `eureka-1`, y publica solo `127.0.0.1:9080`. Las claves de los
canales web, móvil y cajero, el pepper de tarjetas y los datos de demostración usan en el jar valores de desarrollo; el
compose no los define.

## Configuración

| Propiedad | En el jar (`application.properties`) | Config Server | Variable de entorno |
|---|---|---|---|
| `spring.datasource.url` | `jdbc:postgresql://localhost:5439/banco_xyz` | `jdbc:postgresql://db:5432/banco_xyz` (`banco-core-api-nube.properties`) | — |
| `spring.datasource.username` / `password` | `banco` / valor de desarrollo | — | `BANCO_DB_USUARIO`, `BANCO_DB_CLAVE` |
| `spring.datasource.hikari.maximum-pool-size` / `server.tomcat.threads.max` | `20` / `100` | — | — |
| `banco.core.canales.web`, `movil`, `cajero` (`clave`) | valores de desarrollo | — | `BANCO_CANAL_WEB_CLAVE`, `BANCO_CANAL_MOVIL_CLAVE`, `BANCO_CANAL_CAJERO_CLAVE` |
| `banco.core.canales.autenticacion.clave` | valor de desarrollo | — | `BANCO_CANAL_AUTENTICACION_CLAVE` |
| `banco.core.seguridad.pepper-tarjetas` / `bcrypt-fuerza` | valor de desarrollo / `10` | — | `BANCO_PEPPER_TARJETAS` |
| `banco.core.sincronizar-al-iniciar` / `zona-horaria` | `true` / `America/Santiago` | — | — |
| `banco.core.cajero.limite-diario` | `10000` | — | — |
| `banco.jwt.emisor` / `audiencia` / `jwk-set-uri` / `cache-jwks` | `https://localhost:8081`, `banco-xyz`, `https://localhost:8081/oauth2/jwks`, `30s` | Los mismos en `application.properties`; en `nube`, `https://banco-auth:8081` y `https://banco-auth:8081/oauth2/jwks` | — |
| `spring.kafka.bootstrap-servers` | `${BANCO_KAFKA:localhost:9092}` | `localhost:9092`; en `nube`, `kafka:9092` | `BANCO_KAFKA` (solo sin Config Server) |
| `spring.kafka.listener.concurrency` / `banco.kafka.particiones` / `banco.outbox.intervalo-ms` | `3` / `3` / `500` | `banco.kafka.particiones=3` | — |
| `eureka.client.service-url.defaultZone` | `${BANCO_EUREKA:...}` con los dos nodos locales | igual; en `nube`, `eureka-1:8761` y `eureka-2:8762` | `BANCO_EUREKA` (solo sin Config Server) |
| `management.server.address` | `127.0.0.1` (perfil `tls`) | `0.0.0.0` en `nube` | — |
| `resilience4j.*` | **ninguna** | `publicacion-kafka` (compartida), instancia `kafka` y valores de `nube` | — |
| Certificados y clave de los almacenes | — | — (nunca van en el Config Server) | `BANCO_CERTIFICADOS`, `BANCO_ALMACEN_CLAVE` |

## Cómo ejecutar

Desde la raíz del repositorio, con el compose:

```bash
docker compose up -d --build                    # todo el ecosistema, en orden y por salud
docker compose up -d --build banco-core-api     # solo el core y lo que necesita para arrancar (db, kafka, config, eureka)
docker compose ps
docker compose logs -f banco-core-api
```

Como el puerto `8080` no se publica, las llamadas al core desde el equipo se hacen desde un contenedor de la red (los
scripts de `banco-xyz-cloud/scripts/` lo resuelven con `llamar_interno` y el volumen de certificados). Los usuarios y las
tarjetas de demostración los crea el core al sincronizar el cierre y se listan en su log de arranque; las claves y el PIN
de demostración están en el [README general](../README.md).

Fuera del compose no es una vía soportada en esta entrega: el compose no publica la base ni Kafka. Las pruebas no
necesitan ninguna infraestructura.

## Construir y probar

```bash
./mvnw verify
```

65 pruebas. Usan H2 en modo PostgreSQL, Flyway real, las tablas del batch con un cierre de ejemplo, una PKI de prueba
(`PkiDePrueba`) y Kafka embebido solo en `SagaEnKafkaTest`; el broker se simula en `PublicadorDeOutboxTest`. El informe
de cobertura JaCoCo queda en `target/site/jacoco/index.html`.

## Pruebas

| Clase | Pruebas | Qué comprueba |
|---|---|---|
| `AutenticacionTest` | 4 | Intentos concurrentes de clave y PIN erróneos: el contador de fallos no pierde carreras y bloquea al llegar al límite; un bloqueo vencido se libera antes de evaluar la clave; traducción HTTP de credenciales inválidas, usuario inexistente, ejecutivo por móvil, tarjeta inválida y bloqueada |
| `AutorizacionPorCanalTest` | 5 | La matriz completa de qué canal y qué credencial puede tocar cada recurso, incluyendo mTLS; segunda capa por usuario; cajero y su tarjeta |
| `CanalesDeLaSemana7Test` | 5 | banco-auth autentica a un cliente, rechaza al ejecutivo y no puede leer cuentas; banco-auth identifica sin clave a un cliente que entró con GitHub (200), y responde 404, 403 o 423 a un usuario inexistente, al ejecutivo o a uno bloqueado; ni la banca web ni transferencias-service pueden identificar sin clave (403); transferencias-service con su token OAuth lee la cuenta propia (200), una ajena da 404 y no puede retirar; la antigua clave Basic de transferencias-service da 401; un token sin `core.cuentas.leer` (403) o con el certificado de otro servicio (403) no pasa |
| `CierresYSincronizacionTest` | 5 | La sincronización al arrancar publica solo la ejecución `COMPLETED` correcta, con la fila canónica de cada cuenta; no duplica ni pisa saldos; tarjeta Luhn con solo su HMAC; cierres vigentes y calidad; movimientos |
| `ContratoCoreApiTest` | 4 | Cada respuesta real del core cumple exactamente las claves de su archivo en `contratos/core-api` |
| `ErroresTecnicosTest` | 2 | Traducción de fallas técnicas: bloqueo no obtenido a `503`, violación de unicidad a `409`, error inesperado a `500` sin detalles; errores de Spring MVC con código |
| `LectorDeEventosTest` | 6 | Un evento v1 se lee como v2 en CLP; un v2 se lee con su moneda; un campo desconocido se ignora; versión 3 o 0 lanza `VersionNoSoportada`; texto, JSON de otro tipo o sin `eventoId` lanza `EventoInvalido`; un evento nuevo se escribe en la versión actual |
| `LimiteDiarioTest` | 2 | El límite diario se cuenta desde la medianoche de Santiago; reglas de monto, tipo de cuenta y tarjeta ajena |
| `PublicadorDeOutboxTest` | 3 | La política del circuito `kafka` y del reintento es la configurada (ventana 4, mínimo 2, 50 %, 10 s; 3 intentos); con Kafka arriba cada evento sale con su tópico, la cuenta como clave y el tipo en el encabezado, y queda publicado; con Kafka caído reintenta, abre el circuito y deja de insistir hasta que Kafka vuelve |
| `RetirosConcurrentesTest` | 2 | 20 retiros simultáneos sobre la misma cuenta: solo aprueban los que caben en el saldo, nunca queda negativo; reintentos simultáneos con la misma clave descuentan una sola vez |
| `SagaDeTransferenciasTest` | 13 (6 + 7 casos) | Los tres pasos de la saga contra la base: reservar retiene el monto y deja `FondosReservados` en el outbox; siete motivos de rechazo parametrizados (saldo, cuenta ajena, destino inexistente, origen inexistente, misma cuenta, cuenta que no admite retiros, monto inválido) no tocan saldos; un evento en otra moneda se rechaza con `MONEDA_NO_SOPORTADA`; una solicitud duplicada retiene una sola vez; aprobada acredita y registra los dos movimientos; rechazada compensa devolviendo el monto; una decisión sobre una reserva ya resuelta se ignora |
| `SagaEnKafkaTest` | 2 | Con Kafka embebido: solicitud → `FondosReservados` → aprobación → `TransferenciaCompletada`, todo por tópicos reales; un mensaje ilegible no frena la partición y va a `antifraude.decisiones.DLT` con el error |
| `SinTablasDelBatchTest` | 2 | Con la base recién creada, sin el volcado SQL cargado (o sin ejecución `COMPLETED`), el core arranca igual y responde `503 SIN_CIERRE_PUBLICADO` |
| `TlsDelCoreTest` | 6 | El servicio levantado de verdad con el perfil `tls`: TLS 1.3 y HTTP/2, certificado de cliente, certificado de otro canal, CA ajena, suites AEAD, HTTP plano y puerto de operación |
| `UnitariosTest` | 4 | Utilidades: dígito verificador de Luhn, normalización del nombre de usuario, fila canónica, códigos de error de Spring MVC |

## Enlaces

- [README general](../README.md)
- [Infraestructura Spring Cloud y compose](../banco-xyz-cloud/README.md)
