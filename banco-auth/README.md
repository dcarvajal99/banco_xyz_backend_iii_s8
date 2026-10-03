# banco-auth — Banco XYZ

Servidor de autorización OAuth 2.0 y OpenID Connect del Banco XYZ, construido con **Spring Authorization Server**
(`spring-boot-starter-oauth2-authorization-server`). Es el único lugar donde el usuario escribe su clave: la aplicación
cliente lo envía al formulario de banco-auth, la clave la verifica el core y la aplicación solo recibe tokens. Los
tokens se firman con **RS256** y claves RSA que rotan sin cortar el servicio; los demás servicios los validan contra el
**JWK Set** público, sin compartir ningún secreto con este proceso. No guarda credenciales de usuarios ni tiene base de
datos.

En la semana 7 este servicio exponía `POST /api/v1/tokens` y `/.well-known/jwks.json`. Ambos ya no existen: los
reemplazan los endpoints estándar de OAuth 2.0 (`/oauth2/token`, `/oauth2/jwks`).

## Ficha

| Campo | Valor |
|---|---|
| Puerto HTTPS | `8081` (perfiles `tls,nube`, fijados en la imagen) |
| Puerto de operación (health, claves, circuitos) | `9081`, sin TLS; el compose lo publica solo en `127.0.0.1` |
| Nombre en Eureka | `BANCO-AUTH` (instancia HTTPS) |
| Paquete raíz | `com.bancoxyz.auth` (`oauth/`, `claves/`, `core/`, `config/`) |
| Stack | Spring Boot 3.5.16, Spring Cloud 2025.0.3, Spring Authorization Server, Resilience4j; se compila para Java 17 y corre sobre un JRE 21 |
| Base de datos | Ninguna. Las claves, los clientes registrados y las autorizaciones (códigos y refresh tokens) viven en memoria: si el contenedor se reinicia, nacen claves nuevas y los tokens y refresh tokens anteriores dejan de valer |
| Canal ante el core | `AUTENTICACION` (usuario `banco-auth`, clave Basic por `BANCO_CANAL_AUTENTICACION_CLAVE`) más su certificado de cliente (mTLS) |
| Configuración central | `banco-xyz-cloud/configuracion/banco-auth.properties` + `application.properties` + `application-nube.properties` |

## Endpoints

Los publica Spring Authorization Server; `ServidorDeAutorizacion` declara las dos cadenas de seguridad que los protegen.

| Método | Ruta | Quién la usa | Qué hace |
|---|---|---|---|
| GET | `/oauth2/authorize` | Navegador del usuario, enviado por la aplicación cliente | Inicio del flujo `authorization_code`. Sin sesión, redirige a `/login` si el cliente acepta HTML. Exige `code_challenge` (PKCE) |
| POST | `/oauth2/token` | banca-web, transferencias-service y operacion-banco | Entrega tokens para `authorization_code` (con `code_verifier`), `refresh_token` y `client_credentials`. El cliente se autentica con `client_secret_basic` |
| GET | `/oauth2/jwks` | Servidores de recursos | JWK Set con solo las claves **públicas** vigentes (la activa y las que siguen en gracia) |
| POST | `/oauth2/introspect` | Clientes registrados | Introspección de un token (RFC 7662). Publicado por el servidor; ninguna prueba de esta entrega lo ejercita |
| POST | `/oauth2/revoke` | Clientes registrados | Revocación de un token (RFC 7009). Mismo caso que el anterior |
| GET | `/.well-known/openid-configuration` | Clientes OIDC | Metadatos: emisor, endpoints, `S256` como método PKCE, grant types |
| GET | `/userinfo` | Aplicación cliente | Datos del usuario, con el access token como `Bearer` |
| GET, POST | `/login` | Navegador del usuario | Formulario de inicio de sesión (con token CSRF) y su envío |

Operación, en el puerto `9081`:

| Método | Ruta | Acceso | Qué hace |
|---|---|---|---|
| GET | `/actuator/health`, `/actuator/info` | Libre | Salud (la usa el `HEALTHCHECK` de la imagen) e información |
| GET | `/actuator/claves` | Token con `claves.administrar` | Lista las claves con su estado (`ACTIVA`, `EN_GRACIA`) |
| POST | `/actuator/claves` | Token con `claves.administrar` | Rota: genera una clave activa nueva |
| DELETE | `/actuator/claves/{kid}` | Token con `claves.administrar` | Retira una clave que ya no firma (por ejemplo, comprometida) |
| GET | `/actuator/circuitbreakers`, `circuitbreakerevents`, `retries`, `retryevents`, `bulkheads`, `bulkheadevents` | Libre (solo lectura) | Estado y eventos de Resilience4j |
| POST, DELETE… | cualquier otra operación del actuator | **Rechazada** | Por ejemplo, el `POST /actuator/circuitbreakers/{nombre}` de Resilience4j que fuerza el estado de un circuito |

## Seguridad: el rol OAuth de este servicio

banco-auth es el **servidor de autorización**. Emite tokens, no los consume (salvo `/userinfo`, que valida el access
token con sus propias claves, y el actuator). Tres cadenas de `SecurityFilterChain`:

| Orden | Cadena | Qué protege |
|---|---|---|
| 1 | `cadenaDelProtocolo` | Los endpoints del protocolo (`/oauth2/*`, `/.well-known/openid-configuration`, `/userinfo`). Todo exige autenticación (cliente o token). Si el navegador llega a `/oauth2/authorize` sin sesión, `LoginUrlAuthenticationEntryPoint` lo envía a `/login` |
| 2 | `cadenaDeOperacion` | `/actuator/**`. `/actuator/claves` exige un access token con `claves.administrar` (servidor de recursos JWT); el resto solo admite `GET`; cualquier otro método se rechaza. Sin sesión ni CSRF (token Bearer) |
| 3 | `cadenaDeLogin` | El formulario `/login` (público) y `/error`; todo lo demás exige sesión. HSTS de un año con subdominios. CSRF activo: el formulario lleva su token |

En el entorno `nube` el puerto de operación escucha en `0.0.0.0` dentro del contenedor (`management.server.address`
del Config Server) para que el `HEALTHCHECK` y la red del compose lo alcancen, y el compose lo publica solo en
`127.0.0.1` del equipo. Como cualquier contenedor de la red `banco-xyz` llega a ese puerto, estar en él no da permisos:
administrar las claves exige el token del cliente `operacion-banco`. Los tokens que recibe el propio servidor se
validan como en los demás servidores de recursos: firma con sus claves, vigencia, emisor (`iss`) y audiencia (`aud`).

### Clientes registrados

`ClientesRegistrados` define los tres clientes del banco (en memoria). Los secretos llegan por variable de entorno y se
guardan con bcrypt (`DelegatingPasswordEncoder`).

| | `banca-web` | `transferencias-service` | `operacion-banco` |
|---|---|---|---|
| Tipo | Confidencial (aplicación de banca en línea, con backend) | Servicio, sin usuario | Operación del banco, sin usuario |
| Autenticación del cliente | `client_secret_basic` | `client_secret_basic` | `client_secret_basic` |
| Grant types | `authorization_code`, `refresh_token` | `client_credentials` | `client_credentials` |
| PKCE | **Obligatorio** (`requireProofKey`) | No aplica | No aplica |
| Consentimiento | No se pide | No aplica | No aplica |
| Redirect URI | `banco.auth.banca-web.redirect-uris` (`http://127.0.0.1:8099/callback`) | — | — |
| Scopes permitidos | `openid`, `profile`, `transferencias.escribir`, `transferencias.leer`, `notificaciones.leer` | `core.cuentas.leer` | `claves.administrar` |
| Access token | 5 min (`banco.auth.duracion-token`) | 5 min | 5 min |
| Refresh token | 60 min (`banco.auth.duracion-refresco`), **rotativo**: cada uso entrega uno nuevo e invalida el anterior | No tiene | No tiene |
| Secreto | `BANCO_OAUTH_BANCA_WEB_SECRETO` | `BANCO_OAUTH_TRANSFERENCIAS_SECRETO` | `BANCO_OAUTH_OPERACION_SECRETO` |

### Scopes

`Alcances` define un scope por operación; cada servicio exige el suyo.

| Scope | Lo exige | Para qué |
|---|---|---|
| `transferencias.escribir` | transferencias-service (`POST`) | Iniciar una transferencia |
| `transferencias.leer` | transferencias-service (`GET`) | Consultar el estado de una transferencia propia |
| `notificaciones.leer` | notificaciones-service | Leer los avisos propios |
| `core.cuentas.leer` | banco-core-api (vía `TokensDeServicio`) | Servicio a servicio: consultar una cuenta. **Ningún usuario lo recibe**: banca-web no lo tiene permitido (`invalid_scope`) |
| `claves.administrar` | banco-auth (`/actuator/claves`) | Listar, rotar y retirar las claves de firma. Solo lo puede pedir `operacion-banco` |

### Flujos

| Flujo | Pasos |
|---|---|
| `authorization_code` + PKCE (usuario) | 1) la aplicación redirige a `/oauth2/authorize` con `code_challenge` (S256) y `state`; 2) sin sesión, banco-auth muestra `/login`; 3) el usuario escribe su clave, que verifica el core; 4) banco-auth redirige al `redirect_uri` con un código de un solo uso; 5) la aplicación canjea el código en `/oauth2/token` con su secreto y el `code_verifier`: recibe access token, refresh token e ID token |
| `refresh_token` | La aplicación pide tokens nuevos con el refresh token; recibe también un refresh token nuevo y el usado queda invalidado (`invalid_grant` si se reutiliza) |
| `client_credentials` (servicio) | transferencias-service pide su token con `core.cuentas.leer`; el `sub` es el id del cliente y el token no trae datos de usuario |

Sin `code_challenge` no se entrega código (`invalid_request`); un código sin `code_verifier` o con uno incorrecto no se
canjea (`invalid_grant`).

## Claims del token

`claimsDelBanco` (un `OAuth2TokenCustomizer<JwtEncodingContext>`) agrega lo que el resto del banco necesita para
autorizar, no solo para identificar:

| Dónde | Claim | Valor |
|---|---|---|
| Encabezado JWS | `kid` | Clave activa en el momento de firmar; el verificador elige la clave pública correcta del JWK Set sin probarlas todas |
| Access token | `iss` | `banco.auth.emisor` (en `nube`, `https://banco-auth:8081`) |
| Access token | `aud` | `banco.auth.audiencia` (`banco-xyz`). Los servicios rechazan tokens para otra audiencia |
| Access token | `sub` | Usuario (en `authorization_code`) o id del cliente (en `client_credentials`) |
| Access token | `scope` | Lista de scopes concedidos |
| Access token e ID token | `usuario_id`, `cliente_id`, `rol` | Datos del usuario en el core, solo cuando hay usuario: transferir solo desde cuentas propias, ver solo los avisos propios. Un token de `client_credentials` no los trae |
| Access token | `iat`, `exp`, `jti` | Los agrega Spring Authorization Server; `exp` = `iat` + `banco.auth.duracion-token` |

## Inicio de sesión contra el core

`ProveedorDeAutenticacionDelCore` verifica usuario y clave del formulario llamando a `ClienteCore.autenticar()`
(`POST /autenticacion/usuarios` del core, canal `AUTENTICACION`, con Basic y mTLS). banco-auth no guarda claves: las
comprueba el core con bcrypt. Cada respuesta se traduce a la excepción de Spring Security que corresponde y
`FallasDeLogin` la convierte en un código en la URL (`/login?error=<código>`), sin exponer el mensaje interno:

| Respuesta del core | Excepción | Código en `/login` | Texto de `PaginaDeLogin` |
|---|---|---|---|
| 200 | — | — | Sesión iniciada con `UsuarioDelBanco` (ids del core y rol) |
| 401 u otro 4xx | `BadCredentialsException` | `credenciales` | Usuario o clave incorrectos (usuario inexistente y clave mala comparten código para no revelar qué usuarios existen) |
| 423 | `LockedException` | `bloqueado` | El usuario está bloqueado |
| 403 (`ROL_NO_PERMITIDO_EN_CANAL`) | `DisabledException` | `no-habilitado` | Este usuario no puede iniciar sesión en la banca en línea (por ejemplo, el ejecutivo) |
| Core caído, circuito abierto, bulkhead lleno o sin instancias | `AuthenticationServiceException` | `servicio` | El servicio de autenticación no está disponible |

Un código desconocido en la URL muestra el texto de `credenciales`. El token CSRF del formulario viaja en un campo
oculto (`_csrf`).

## Claves y rotación

`AlmacenDeClaves` mantiene una lista de `ClaveDeFirma` (par RSA 2048, `kid` y estado) y es la fuente de claves
(`JWKSource`) del firmador y de `/oauth2/jwks`; el endpoint publica solo la parte pública.

1. **ACTIVA.** Firma los tokens nuevos. Siempre hay exactamente una.
2. **EN_GRACIA.** Al rotar (`POST /actuator/claves` con el token de `operacion-banco`), la activa deja de firmar pero se sigue publicando hasta
   `ahora + banco.auth.duracion-token`, para que ningún token válido en circulación quede sin clave con la que verificarse.
3. **Retirada.** Sale del JWK Set cuando vence su gracia (`retirarVencidas()`, `@Scheduled`, cada 10 s) o a mano con
   `DELETE /actuator/claves/{kid}`. La clave activa no se puede retirar sin rotar antes.

Los servidores de recursos guardan el JWK Set 30 s: una clave retirada deja de aceptarse a lo sumo a los 30 s, y un
`kid` desconocido fuerza a consultarlo de nuevo antes de rechazar el token. El `kid` se genera como
`banco-auth-<fecha>-<sufijo>`.

## Resilience4j

`ClienteCore.autenticar()` combina tres anotaciones sobre la instancia `core`. El orden de los aspectos es el de
Resilience4j: `Retry(CircuitBreaker(Bulkhead(llamada)))`.

| Mecanismo | Qué hace aquí |
|---|---|
| `@Bulkhead(name = "core")` | Limita las llamadas simultáneas al core; la que sobra no espera turno y va al fallback |
| `@CircuitBreaker(name = "core")` | Abre el circuito si el core falla; con el circuito abierto no se llama al core |
| `@Retry(name = "core", fallbackMethod = "coreNoDisponible")` | Reintenta solo los cortes de conexión (`ResourceAccessException`); un 4xx no se reintenta |

`ClienteCore` sobrecarga el fallback por tipo de excepción: `ResourceAccessException` (sin conexión),
`HttpServerErrorException` (5xx), `CallNotPermittedException` (circuito abierto), **`BulkheadFullException`** (bulkhead
lleno) e `IllegalStateException` (LoadBalancer sin instancias: el core se dio de baja en Eureka). Todos terminan en
`CoreNoDisponible`, que el login muestra como `servicio`. Un 4xx del core (`ErrorDeNegocioDelCore`) no tiene fallback ni
cuenta como falla del circuito, igual que el bulkhead lleno: ambos están en `ignore-exceptions`.

**Las políticas no viven en el jar**: el `application.properties` de banco-auth no trae ninguna propiedad
`resilience4j.*`. Las entrega el Config Server: la política compartida `http-interno` (`configuracion/application.properties`),
ajustada para el entorno contenedores en `application-nube.properties`, y la instancia `core` en `banco-auth.properties`
(`base-config=http-interno` y su excepción propia). Las pruebas usan una copia en `src/test/resources/application-prueba.properties`,
que `scripts/verificar_coherencia.sh` comprueba que sea idéntica a la central.

| Parámetro de la instancia `core` | Local (base) | Nube |
|---|---|---|
| `bulkhead.max-concurrent-calls` | 20 | 25 |
| `bulkhead.max-wait-duration` | 0 ms | 0 ms |
| `circuitbreaker.sliding-window-type` / `sliding-window-size` | `COUNT_BASED` / 6 | `COUNT_BASED` / 10 |
| `circuitbreaker.minimum-number-of-calls` | 3 | 5 |
| `circuitbreaker.failure-rate-threshold` | 50 % | 50 % |
| `circuitbreaker.wait-duration-in-open-state` | 10 s | 15 s |
| `circuitbreaker.permitted-number-of-calls-in-half-open-state` | 2 | 3 |
| `circuitbreaker.slow-call-duration-threshold` / `slow-call-rate-threshold` | no definidos | 2 s / 80 % |
| `circuitbreaker.ignore-exceptions` | `ErrorDeNegocioDelCore`, `BulkheadFullException` | igual |
| `retry.max-attempts` | 2 | 3 |
| `retry.wait-duration` | 200 ms | 300 ms |
| `retry.enable-exponential-backoff` / multiplicador | no | sí / 2 |
| `retry.retry-exceptions` | `ResourceAccessException` | igual |

"Local" es lo que entrega el Config Server sin perfil (y lo que usan las pruebas); "Nube" es lo que recibe el contenedor
con el perfil `nube`.

## Imagen Docker

Construcción multi-etapa desde el código fuente (`banco-auth/Dockerfile`, contexto `banco-auth/`):

| Aspecto | Valor |
|---|---|
| Etapa de construcción | `maven:3.9-eclipse-temurin-21`: primero solo el `pom.xml` (`dependency:go-offline`, capa de dependencias reutilizable), después `src/` y `package -DskipTests`; el jar se separa en capas de Spring Boot con `java -Djarmode=tools ... extract --layers --launcher` |
| Etapa final | `eclipse-temurin:21-jre-alpine`: solo el JRE y las cuatro capas (`dependencies`, `spring-boot-loader`, `snapshot-dependencies`, `application`); sin Maven ni código fuente |
| Usuario | `banco`, uid/gid `10001`, sin privilegios (el volumen de certificados se entrega legible solo para él) |
| Puertos | `8081` (HTTPS) y `9081` (operación) |
| `HEALTHCHECK` | `wget` a `http://127.0.0.1:9081/actuator/health` buscando `"status":"UP"`; cada 10 s, 3 s de límite, 120 s de arranque, 6 reintentos |
| JVM | `JAVA_TOOL_OPTIONS=-XX:MaxRAMPercentage=60 -XX:+UseSerialGC -XX:+ExitOnOutOfMemoryError`: el heap toma el 60 % de la memoria del contenedor y la JVM termina si se queda sin memoria, para que Docker la reinicie |
| Perfiles | `SPRING_PROFILES_ACTIVE=tls,nube` (HTTPS y configuración del entorno contenedores) |
| Límite de memoria en el compose | 448 MB |

Variables que el servicio recibe del `docker-compose.yaml` de la raíz (los valores por defecto `-dev` están en `.env.ejemplo`):

| Variable | Para qué |
|---|---|
| `BANCO_CONFIG_SERVER`, `BANCO_CONFIG_USUARIO`, `BANCO_CONFIG_CLAVE` | Dirección y credencial Basic del Config Server |
| `BANCO_CONFIG_FAIL_FAST=true` | Si el Config Server lo rechaza, el servicio no arranca (no corre con los valores de su jar) |
| `BANCO_ALMACEN_CLAVE`, `BANCO_CERTIFICADOS=/certificados` | Clave de los `.p12` del cliente del Config Server y carpeta de la PKI (volumen `certificados`, solo lectura) |
| `EUREKA_INSTANCE_HOSTNAME=banco-auth` | Nombre con que se registra en Eureka |
| `BANCO_CANAL_AUTENTICACION_CLAVE` | Clave Basic del canal `AUTENTICACION` ante el core |
| `BANCO_OAUTH_BANCA_WEB_SECRETO`, `BANCO_OAUTH_TRANSFERENCIAS_SECRETO`, `BANCO_OAUTH_OPERACION_SECRETO` | Secretos de los tres clientes OAuth |

Depende (por salud) de `config-server`, `eureka-1` y `banco-core-api`, y publica `127.0.0.1:8081` y `127.0.0.1:9081`.

## Configuración

| Propiedad | En el jar (`application.properties`) | Config Server | Variable de entorno |
|---|---|---|---|
| `banco.auth.emisor` / `audiencia` | `${banco.jwt.emisor:https://localhost:8081}` / `${banco.jwt.audiencia:banco-xyz}` | `banco.jwt.emisor` (`https://localhost:8081`, en `nube` `https://banco-auth:8081`) y `banco.jwt.audiencia` (`banco-xyz`) | — |
| `banco.auth.duracion-token` | `5m` | `5m` (`banco-auth.properties`) | — |
| `banco.auth.duracion-refresco` | `60m` | — | — |
| `banco.auth.banca-web.id` / `redirect-uris` | `banca-web` / `http://127.0.0.1:8099/callback` | — | — |
| `banco.auth.banca-web.secreto` | valor de desarrollo | — | `BANCO_OAUTH_BANCA_WEB_SECRETO` |
| `banco.auth.transferencias.id` / `secreto` | `transferencias-service` / valor de desarrollo | — | `BANCO_OAUTH_TRANSFERENCIAS_SECRETO` |
| `banco.auth.operacion.id` / `secreto` | `operacion-banco` / valor de desarrollo | — | `BANCO_OAUTH_OPERACION_SECRETO` |
| `banco.core.url` | `https://localhost:8080/api/v1` | `https://banco-core-api/api/v1` | — |
| `banco.core.descubrimiento` | `false` | `true` (el core se busca por nombre en Eureka) | — |
| `banco.core.usuario` / `clave` | `banco-auth` / valor de desarrollo | — | `BANCO_CANAL_AUTENTICACION_CLAVE` |
| `spring.http.client.connect-timeout` / `read-timeout` | `1s` / `3s` | — | — |
| `eureka.client.service-url.defaultZone` | los dos nodos locales (`127.0.0.1:8761`, `localhost:8762`) | igual; en `nube`, `eureka-1:8761` y `eureka-2:8762` | — |
| `management.server.address` | `127.0.0.1` (perfil `tls`) | `0.0.0.0` en `nube` | — |
| `resilience4j.*` | **ninguna** | `http-interno` (compartida), `core` (instancias) y valores de `nube` | — |
| Certificados y claves de los almacenes | — | — (nunca van en el Config Server) | `BANCO_CERTIFICADOS`, `BANCO_ALMACEN_CLAVE` |
| Credencial del Config Server | usuario y clave de desarrollo | — | `BANCO_CONFIG_USUARIO`, `BANCO_CONFIG_CLAVE` |

El Config Server responde solo por HTTPS y exige usuario y clave Basic más el certificado de cliente de banco-auth
(`spring.cloud.config.tls.*`, incluida `key-password`).

## Cómo ejecutar

Desde la raíz del repositorio, con el compose:

```bash
docker compose up -d --build                  # todo el ecosistema, en orden y por salud
docker compose up -d --build banco-auth       # solo banco-auth y lo que necesita para arrancar
docker compose ps                             # estado y salud de cada contenedor
docker compose logs -f banco-auth
```

El flujo completo de OAuth 2.0 se recorre paso a paso con `bash banco-xyz-cloud/scripts/oauth2_flujos.sh`, y la
rotación de claves con `bash banco-xyz-cloud/scripts/claves_jwt.sh` (ver el [README de infraestructura](../banco-xyz-cloud/README.md)).
Las llamadas desde el equipo validan el certificado contra la CA del banco, que los scripts copian del contenedor `pki`.

Fuera del compose no es una vía soportada en esta entrega: el compose no publica el core, la base ni Kafka, y el login
necesita al core. Las pruebas no necesitan ninguna infraestructura.

## Construir y probar

```bash
./mvnw verify
```

26 pruebas. El informe de cobertura JaCoCo queda en `target/site/jacoco/index.html`.

## Pruebas

Corren con el perfil `prueba` (sin Config Server ni Eureka) y simulan el core con `MockRestServiceServer`.
`PruebaOAuth` es la base común (clientes, PKCE y un usuario ya autenticado).

| Clase | Pruebas | Qué comprueba |
|---|---|---|
| `FlujosOAuthTest` | 8 | Discovery OpenID (emisor, endpoints, `S256`); `authorization_code` + PKCE de punta a punta (access token RS256 con `kid` de la clave activa, verificado con el JWK Set, claims del usuario, `aud=banco-xyz`, scopes); PKCE obligatorio (sin `code_challenge` no hay código, sin `code_verifier` no se canjea); banca-web no puede pedir `core.cuentas.leer`; refresh token rotativo (el usado da `invalid_grant`); `client_credentials` sin datos de usuario ni refresh token; secreto incorrecto (401) y scope no permitido (400); al rotar, el token nuevo lleva el `kid` nuevo y `/oauth2/jwks` publica las dos claves sin parte privada |
| `LoginContraElCoreTest` | 5 (2 + 3 casos) | Sin sesión, `/oauth2/authorize` lleva a `/login`; clave correcta: el core la valida y la sesión queda con el usuario y sus ids; el core rechaza con 401, 403 o 423 y el login muestra `credenciales`, `no-habilitado` o `bloqueado` |
| `CircuitoDelCoreTest` | 5 | Core caído: el primer login reintenta una vez y a la tercera falla el circuito abre (el siguiente no llama al core); el formulario dice que el servicio no está disponible, no «clave incorrecta»; cinco claves incorrectas no abren el circuito; core sin instancias en Eureka (`IllegalStateException`) da `servicio` sin reintento; bulkhead lleno da `servicio` sin llamar al core ni contar como falla |
| `OperacionProtegidaTest` | 5 | Sin token no se listan, rotan ni retiran claves (401) y la salud sigue abierta; un token válido de otro cliente da 403; `operacion-banco` lista, rota y retira; nadie puede forzar el estado de un circuito por el actuator (401 sin token, 403 con token); ningún otro cliente puede pedir `claves.administrar` |
| `RotacionDeClavesTest` | 3 | Al rotar cambia la activa y el JWK Set publica las dos (el conjunto de firma trae las privadas); la anterior se retira sola al vencer su gracia; el retiro manual saca la anterior de inmediato y falla sobre la activa |

## Limitaciones conocidas

- Un solo contenedor: las autorizaciones y las claves están en memoria y no se comparten entre instancias.
- El cliente `banca-web` tiene un `redirect_uri` de desarrollo (`http://127.0.0.1:8099/callback`); no hay una aplicación
  real detrás, los scripts hacen de aplicación.
- Los secretos de los clientes y la clave del canal de autenticación tienen valores `-dev` por defecto; en un despliegue
  real se definen por variable de entorno (`.env`).

## Enlaces

- [README general](../README.md)
- [Infraestructura Spring Cloud y compose](../banco-xyz-cloud/README.md)
