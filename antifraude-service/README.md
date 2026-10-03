# antifraude-service — Banco XYZ

Participante de la saga coreografiada de transferencias del Banco XYZ. No conoce a los demás servicios ni les
responde directamente: escucha el tópico donde el core anuncia que retuvo los fondos de una transferencia, evalúa el
riesgo con reglas simples (monto máximo, cuentas en observación) y publica su decisión —aprobada o rechazada, con el
motivo— en su propio tópico. El core la consume y sigue la saga (acredita o compensa). Es **stateless**: no tiene base
de datos, y toda su memoria dura lo que dura un evento.

En la semana 8 corre como contenedor y **escala con `docker compose --scale`**: sin hostname ni puertos publicados,
cada contenedor se une al mismo grupo de Kafka y se reparte las particiones.

## Ficha

| Campo | Valor |
|---|---|
| Puerto HTTPS | `8083` (perfiles `tls,nube`, fijados en la imagen); no se publica, nadie lo llama |
| Puerto de operación (health, métricas) | `9083`, sin TLS; **no se publica** (se consulta desde dentro del contenedor) |
| Nombre en Eureka | `ANTIFRAUDE-SERVICE` (una instancia por contenedor; se registran con su IP) |
| Paquete raíz | `com.bancoxyz.antifraude` (`transferencia/`, `config/`, `seguridad/`) |
| Stack | Spring Boot 3.5.16, Spring Cloud 2025.0.3, Spring Kafka; se compila para Java 17 y corre sobre un JRE 21 |
| Base de datos | Ninguna: el servicio es stateless |
| Grupo de consumidores | `antifraude-service`, un consumidor por instancia (`concurrency=1`); escala agregando contenedores hasta las 3 particiones |
| Identificador en Kafka | `client-id = ${spring.application.name}-${HOSTNAME:${server.port}}`: en Docker, `HOSTNAME` es el identificador corto del contenedor |
| Configuración central | `banco-xyz-cloud/configuracion/antifraude-service.properties` + `application.properties` + `application-nube.properties` |

## Eventos

| Tópico | Dirección | Eventos | Notas |
|---|---|---|---|
| `cuentas.reservas` | Consume | `FondosReservados` | Dispara la evaluación de riesgo |
| `cuentas.reservas` | Consume (se ignora) | `FondosRechazados` y cualquier otro tipo | Se registra en INFO y no produce nada: el core ya rechazó la reserva por su cuenta |
| `antifraude.decisiones` | Produce | `TransferenciaAprobada` | Ninguna regla de riesgo aplicó |
| `antifraude.decisiones` | Produce | `TransferenciaRechazada` (con `motivo`) | Alguna regla aplicó |
| `cuentas.reservas.DLT` | Produce | — | Mensaje ilegible, sin `eventoId`/`tipo`/`transferenciaId` o de una versión que el servicio no entiende; no se reintenta |

El sobre del evento (`EventoDeTransferencia`) es una copia exacta del que usa `banco-core-api`: JSON en texto, con
encabezados Kafka `tipo` y `eventoId`, y clave de partición igual a la cuenta de origen. La decisión se construye con
`reserva.siguiente(...)`: mismo `transferenciaId`, mismos datos de la transferencia (incluida la `moneda`), `eventoId`
nuevo y la versión actual del contrato.

### Eventos v2: versión y moneda

El sobre lleva `version` (`VERSION_ACTUAL = 2`) y `moneda` (`CLP`). `LectorDeEventos` lee lo que llega a
`cuentas.reservas` así:

| Caso | Resultado |
|---|---|
| Sin `version` ni `moneda` (v1, semana 7) | **Upcasting**: se lee como v2 en `CLP` y se evalúa normalmente; la decisión se publica en v2 |
| `version` = 2 | Se lee tal cual, con su moneda |
| Campo que el servicio no conoce | Se ignora (**lector tolerante**) |
| `version` mayor que 2 o inválida | `VersionNoSoportada`: va a `cuentas.reservas.DLT` **sin reintentos**, para reprocesarlo cuando el consumidor se actualice |
| Texto que no es JSON, JSON sin `eventoId`, `tipo` o `transferenciaId` | `EventoInvalido`: directo a la DLT |

Convención de evolución de los eventos del banco: **primero los consumidores, después los productores**, porque un
consumidor que no entiende una versión nueva la manda a la DLT. Un campo opcional agregado **no sube la versión**; esta
sube solo cuando los consumidores deben entender algo nuevo. Las reglas de riesgo no miran la moneda: rechazar una moneda
no soportada es responsabilidad del core (`MONEDA_NO_SOPORTADA`). `scripts/verificar_coherencia.sh` comprueba que la copia
del sobre y del lector sea la misma en los cuatro servicios de la saga.

Si falla la publicación de la decisión, se relanza la excepción y el `DefaultErrorHandler` reintenta el evento completo
dos veces con un segundo de espera antes de mandarlo a la DLT.

## Reglas de riesgo

Evaluadas en este orden por `ReglasDeRiesgo` (lógica pura, sin Spring, en `transferencia/ReglasDeRiesgo.java`):

1. **`MONTO_SOBRE_LIMITE`**: el monto de la transferencia supera `banco.antifraude.monto-maximo` (el límite es inclusivo:
   un monto igual al máximo se aprueba).
2. **`CUENTA_EN_OBSERVACION`**: la cuenta de origen o la de destino está en `banco.antifraude.cuentas-en-observacion`
   (lista separada por comas).

Si ninguna aplica, la transferencia se aprueba. Los valores, más `banco.antifraude.demora-ms` (una espera que simula
consultar un modelo de riesgo externo), se leen de `PropiedadesAntifraude`
(`@ConfigurationProperties(prefix = "banco.antifraude")`) y los entrega el Config Server desde
`banco-xyz-cloud/configuracion/antifraude-service.properties`. `application.properties` trae valores locales de respaldo,
**distintos a propósito**, para las pruebas:

| Propiedad | En el jar (respaldo) | Config Server |
|---|---|---|
| `banco.antifraude.monto-maximo` | `500000` | `5000` |
| `banco.antifraude.cuentas-en-observacion` | vacía | `104` |
| `banco.antifraude.demora-ms` | `0` | `200` |

Con el compose, el servicio arranca con `BANCO_CONFIG_FAIL_FAST=true`: si el Config Server lo rechaza, no arranca, en vez
de correr en silencio con un límite cien veces mayor. Cambiar una regla es editar su archivo en `configuracion/`,
reconstruir la imagen del Config Server (`docker compose up -d --build config-server`) y reiniciar el servicio
(`docker compose restart antifraude-service`); no hace falta recompilar el servicio.

## Seguridad: el rol OAuth de este servicio

Ninguno: antifraude-service no es servidor de recursos ni cliente OAuth 2.0 (no tiene dependencias de OAuth). No expone
una API: nadie lo llama por HTTP, solo consume y produce eventos de Kafka.

| Aspecto | Detalle |
|---|---|
| `ConfiguracionSeguridad` | Permite `/actuator/health`, `/actuator/info` y `/actuator/metrics` sin credencial y niega todo lo demás (`denyAll`), sin sesión y sin CSRF |
| Puerto de operación | En operación normal (perfil `tls`) el actuator vive en el puerto `9083`, en un contexto aparte que ni siquiera pasa por esa cadena; la regla existe para cuando el servicio corre sin ese perfil (como en las pruebas) |
| TLS | HTTPS con el certificado `antifraude-service` de la CA del banco (TLS 1.3 y 1.2, suites AEAD); no exige certificado de cliente |
| Exposición | El compose no publica ningún puerto de este servicio. En `nube` el puerto de operación escucha en `0.0.0.0` dentro del contenedor, así que es alcanzable desde la red `banco-xyz` sin credenciales |

## Resilience4j

No aplica: el servicio no hace llamadas HTTP y no tiene outbox, así que no usa `@CircuitBreaker`, `@Retry`, `@Bulkhead` ni
decoradores. Su tolerancia a fallos es el manejo de errores del consumidor: dos reintentos a 1 s y después
`cuentas.reservas.DLT` (un mensaje ilegible va directo).

## Escalabilidad con `docker compose --scale`

Los tópicos tienen `banco.kafka.particiones=3`. `spring.kafka.listener.concurrency=1`: cada contenedor trae **un solo**
consumidor, así que el paralelismo no se gana con hilos sino agregando contenedores al mismo grupo
(`spring.application.name=antifraude-service`) hasta el número de particiones. Kafka reparte las particiones sin
coordinación adicional; un cuarto contenedor queda de reserva sin trabajo hasta que otro caiga.

El servicio está preparado para escalar así en el compose: no define `hostname` ni publica puertos (varios contenedores no
pueden compartir un puerto del equipo) y registra cada instancia en Eureka con su IP
(`EUREKA_INSTANCE_PREFER_IP_ADDRESS=true`). Desde la raíz del repositorio:

```bash
docker compose up -d --scale antifraude-service=3     # tres contenedores en el mismo grupo de Kafka
docker compose up -d --scale antifraude-service=1     # de vuelta a uno
```

Con varios contenedores activos, cada `FondosReservados` lo procesa uno solo (el dueño de esa partición), y el contador
Micrometer `antifraude.decisiones` (con tag `resultado=aprobada|rechazada`), en `/actuator/metrics/antifraude.decisiones`
del puerto de operación de cada contenedor, permite medir cuánto procesó cada uno. Si un contenedor muere sin avisar,
`session.timeout.ms=10000` hace que Kafka lo dé de baja y reparta sus particiones a los 10 s (por defecto serían 45 s), y
la política `restart: unless-stopped` lo levanta de nuevo y el `HEALTHCHECK` confirma cuándo vuelve a estar sano.

`banco-xyz-cloud/scripts/escalabilidad.sh` mide la misma carga (48 transferencias repartidas en las 3 particiones de
`cuentas.reservas`, con 200 ms simulados por evento) con 1 y con 3 contenedores, comprueba que cada uno procesa una
partición (16 decisiones) y mata con `SIGKILL` el proceso Java de uno a mitad de la carga sin perder transferencias. Mata el
proceso con `colima ssh`, es decir, supone Colima como runtime de Docker.

## Imagen Docker

Construcción multi-etapa desde el código fuente (`antifraude-service/Dockerfile`, contexto `antifraude-service/`):

| Aspecto | Valor |
|---|---|
| Etapa de construcción | `maven:3.9-eclipse-temurin-21`: primero solo el `pom.xml` (`dependency:go-offline`), después `src/` y `package -DskipTests`; el jar se separa en capas de Spring Boot (`jarmode tools extract --layers --launcher`) |
| Etapa final | `eclipse-temurin:21-jre-alpine`: solo el JRE y las capas `dependencies`, `spring-boot-loader`, `snapshot-dependencies` y `application` |
| Usuario | `banco`, uid/gid `10001`, sin privilegios |
| Puertos | `8083` (HTTPS) y `9083` (operación); solo `EXPOSE`, el compose no los publica |
| `HEALTHCHECK` | `wget` a `http://127.0.0.1:9083/actuator/health` buscando `"status":"UP"`; cada 10 s, 3 s de límite, 120 s de arranque, 6 reintentos |
| JVM | `JAVA_TOOL_OPTIONS=-XX:MaxRAMPercentage=60 -XX:+UseSerialGC -XX:+ExitOnOutOfMemoryError` |
| Perfiles | `SPRING_PROFILES_ACTIVE=tls,nube` |
| Límite de memoria en el compose | 384 MB por contenedor |

Variables que recibe del `docker-compose.yaml` de la raíz (valores por defecto `-dev` en `.env.ejemplo`):

| Variable | Para qué |
|---|---|
| `BANCO_CONFIG_SERVER`, `BANCO_CONFIG_USUARIO`, `BANCO_CONFIG_CLAVE`, `BANCO_CONFIG_FAIL_FAST=true` | Config Server (con `fail-fast`, si lo rechaza el servicio no arranca) |
| `BANCO_ALMACEN_CLAVE`, `BANCO_CERTIFICADOS=/certificados` | Clave de los `.p12` y carpeta de la PKI (volumen `certificados`, solo lectura) |
| `EUREKA_INSTANCE_PREFER_IP_ADDRESS=true` | Se registra en Eureka con su IP: no tiene hostname propio |

No necesita base de datos ni secretos de OAuth. Depende (por salud) de `kafka`, `config-server` y `eureka-1`, y no publica
puertos.

## Configuración

| Propiedad | En el jar (`application.properties`) | Config Server | Variable de entorno |
|---|---|---|---|
| `banco.antifraude.monto-maximo` / `cuentas-en-observacion` / `demora-ms` | `500000` / vacía / `0` | `5000` / `104` / `200` (`antifraude-service.properties`) | — |
| `spring.kafka.bootstrap-servers` | `${BANCO_KAFKA:localhost:9092}` | `localhost:9092`; en `nube`, `kafka:9092` | `BANCO_KAFKA` (solo sin Config Server) |
| `spring.kafka.listener.concurrency` | `1` | — | — |
| `spring.kafka.client-id` | `${spring.application.name}-${HOSTNAME:${server.port}}` | — | `HOSTNAME` (lo fija Docker) |
| `spring.kafka.consumer.properties.session.timeout.ms` | `10000` | — | — |
| `banco.kafka.particiones` | `3` | `3` | — |
| `eureka.client.service-url.defaultZone` | `${BANCO_EUREKA:...}` con los dos nodos locales | igual; en `nube`, `eureka-1:8761` y `eureka-2:8762` | `BANCO_EUREKA` (solo sin Config Server) |
| `eureka.instance.prefer-ip-address` | no definido | — | `EUREKA_INSTANCE_PREFER_IP_ADDRESS` |
| `management.server.address` | `127.0.0.1` (perfil `tls`) | `0.0.0.0` en `nube` | — |
| `resilience4j.*` | no aplica | no aplica | — |
| Certificados y clave de los almacenes | — | — (nunca van en el Config Server) | `BANCO_CERTIFICADOS`, `BANCO_ALMACEN_CLAVE` |

## Cómo ejecutar

Desde la raíz del repositorio, con el compose:

```bash
docker compose up -d --build                           # todo el ecosistema, en orden y por salud
docker compose up -d --build antifraude-service        # solo este servicio y lo que necesita (kafka, config, eureka)
docker compose up -d --scale antifraude-service=3      # escala a tres contenedores
docker compose ps
docker compose logs -f antifraude-service
```

Fuera del compose no es una vía soportada en esta entrega: el compose no publica Kafka. Las pruebas no necesitan ninguna
infraestructura (usan un Kafka embebido).

## Construir y probar

```bash
./mvnw verify
```

15 pruebas. El informe de cobertura JaCoCo queda en `target/site/jacoco/index.html`.

## Pruebas

| Clase | Pruebas | Qué comprueba |
|---|---|---|
| `ReglasDeRiesgoTest` | 5 | Las reglas puras, sin Spring: aprueba bajo el límite, rechaza sobre el límite, aprueba en el límite exacto, rechaza cuenta de origen o destino en observación |
| `AntifraudeEnKafkaTest` | 4 | El servicio completo con un Kafka embebido: `FondosReservados` chico llega aprobado con el mismo `transferenciaId` y clave = cuenta de origen (con los encabezados `tipo` y `eventoId`); uno sobre el límite llega rechazado con `MONTO_SOBRE_LIMITE`; un `FondosRechazados` no produce ninguna decisión; un mensaje ilegible termina en `cuentas.reservas.DLT` con el error |
| `LectorDeEventosTest` | 6 | Un evento v1 se lee como v2 en CLP sin perder datos; un v2 se lee con su moneda; un campo desconocido se ignora; versión 3 o 0 lanza `VersionNoSoportada`; texto, JSON de otro tipo o sin `eventoId` lanza `EventoInvalido`; un evento nuevo se escribe en la versión actual (`version` primero, moneda CLP) |

Las pruebas de reglas usan un límite de 500000 (el respaldo del jar), no el de 5000 del Config Server.

## Enlaces

- [README general](../README.md)
- [Infraestructura Spring Cloud y compose](../banco-xyz-cloud/README.md)
