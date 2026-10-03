#!/usr/bin/env bash
# Evidencia 01 - Imagenes Docker de los microservicios: construidas desde el codigo (multi-etapa), con un JRE, usuario
# sin privilegios, capas de Spring Boot y healthcheck. Requiere las imagenes construidas (docker compose build).
set -uo pipefail
source "$(dirname "$0")/lib.sh"
if [ "${1:-}" = "-h" ]; then sed -n '2,3p' "$0"; exit 0; fi
APLICACIONES="config-server eureka-server banco-core-api banco-auth transferencias-service antifraude-service notificaciones-service"

titulo "Evidencia 01 · Imágenes Docker de todos los microservicios" \
       "Criterio 2: imágenes funcionales y portables, construidas desde el código fuente."

paso "Imágenes del proyecto: los siete servicios Java más la base con el volcado SQL y la PKI de un solo uso"
docker images --filter reference='banco-xyz/*' --format '{{.Repository}}\t{{.Tag}}\t{{.Size}}' | sort | awk -F'\t' '
  BEGIN {printf "  %-36s %-7s %s\n", "IMAGEN", "TAG", "TAMAÑO"} {printf "  %-36s %-7s %s\n", $1, $2, $3}'
construidas=0
for app in $APLICACIONES; do docker image inspect "banco-xyz/$app:1.0.0" > /dev/null 2>&1 && construidas=$((construidas + 1)); done
comprobar "imágenes de los siete servicios Java" "$construidas" "7"

paso "Cada imagen: base JRE 21, usuario sin privilegios, puertos y healthcheck (docker image inspect)"
printf '  %-24s %-10s %-14s %-12s %s\n' "IMAGEN" "USUARIO" "PUERTOS" "HEALTHCHECK" "PLATAFORMA"
sin_root=0; con_salud=0
for app in $APLICACIONES; do
  datos=$(docker image inspect "banco-xyz/$app:1.0.0" --format '{{.Config.User}}|{{range $p, $v := .Config.ExposedPorts}}{{$p}} {{end}}|{{if .Config.Healthcheck}}si{{else}}no{{end}}|{{.Os}}/{{.Architecture}}')
  IFS='|' read -r usuario puertos salud plataforma <<< "$datos"
  printf '  %-24s %-10s %-14s %-12s %s\n' "$app" "$usuario" "$(echo "$puertos" | sed 's#/tcp##g' | xargs)" "$salud" "$plataforma"
  [ "$usuario" = "banco" ] && sin_root=$((sin_root + 1))
  [ "$salud" = "si" ] && con_salud=$((con_salud + 1))
done
nota "eureka-server define su healthcheck en el compose: la misma imagen corre como peer1 (8761) y peer2 (8762)."
comprobar "imágenes que corren como usuario sin privilegios (banco, uid 10001)" "$sin_root" "7"
comprobar "imágenes con HEALTHCHECK propio" "$con_salud" "6"

paso "Construcción multi-etapa: Maven compila en la primera etapa y la imagen final solo trae el JRE y la aplicación"
grep -nE '^(FROM|COPY|RUN|USER|ENTRYPOINT|HEALTHCHECK)' "$RAIZ_REPO/transferencias-service/Dockerfile" | cut -c1-118 | sed 's/^/  /'
comprobar "etapas en el Dockerfile de transferencias-service" "$(grep -c '^FROM' "$RAIZ_REPO/transferencias-service/Dockerfile")" "2"

paso "Capas de Spring Boot: las dependencias pesan y cambian poco; el código propio es la capa más liviana"
# Las cuatro ultimas COPY de la imagen son las capas de Spring Boot, en el orden inverso al del Dockerfile.
CAPAS=$(docker history banco-xyz/transferencias-service:1.0.0 --format '{{.Size}}\t{{.CreatedBy}}' | grep -m4 'COPY dir:' \
  | paste - <(printf '%s\n' application snapshot-dependencies spring-boot-loader dependencies) | cut -f1,3)
printf '  %s\n' "TAMAÑO     CAPA (COPY --from=construccion /fuente/capas/<capa>/)"
printf '%s\n' "$CAPAS" | tail -r | awk -F'\t' '{printf "  %-10s %s\n", $1, $2}'
nota "dependencies: las librerías · spring-boot-loader: el cargador · application: el código de transferencias-service"
comprobar "la capa más pesada son las dependencias" "$(printf '%s\n' "$CAPAS" | awk -F'\t' '$2 == "dependencies" {print $1}' | grep -c MB)" "1"

paso "Portabilidad: la imagen arranca sola, sin Maven ni el código fuente en la máquina (solo Docker)"
docker run --rm --entrypoint sh banco-xyz/banco-auth:1.0.0 -c \
  'printf "  java:    "; java -version 2>&1 | grep -v "Picked up" | head -1; printf "  usuario: "; id; printf "  /app:    "; ls /app | tr "\n" " "; echo; printf "  maven:   "; command -v mvn || echo "no instalado"'
comprobar "Maven en la imagen final" "$(docker run --rm --entrypoint sh banco-xyz/banco-auth:1.0.0 -c 'command -v mvn || echo no instalado')" "no instalado"

resumen_final
