#!/usr/bin/env bash
# Evidencia 00 - Organizacion: seis proyectos independientes en una carpeta, cada uno con su build, sus pruebas, su
# Dockerfile y su forma de encontrar a los demas (Config Server, Eureka y topicos de Kafka; nunca una ruta a la carpeta
# vecina). El docker-compose.yaml de la raiz los orquesta.
set -uo pipefail
if [ "${1:-}" = "-h" ]; then sed -n '2,3p' "$0"; exit 0; fi
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
PROYECTOS="${BANCO_PROYECTOS:-$(cd "$RAIZ/.." && pwd)}"
cd "$PROYECTOS" || exit 1
SERVICIOS="banco-core-api banco-auth transferencias-service antifraude-service notificaciones-service"

echo "$(basename "$PROYECTOS")/            una carpeta, seis proyectos; cada uno se puede separar en su propio repositorio"
printf '%-23s %-9s %-27s %-11s %s\n' "PROYECTO" "ARCHIVOS" "POM PADRE" "DOCKERFILE" "IMAGEN (puerto)"
for p in banco-xyz-cloud $SERVICIOS; do
  archivos=$(find "$p" -type f -not -path '*/target/*' -not -path '*/evidencias/*' -not -path '*/certificados/*' -not -name '.DS_Store' | wc -l | tr -d ' ')
  padre=$(sed -n '/<parent>/,/<\/parent>/s/.*<artifactId>\(.*\)<\/artifactId>.*/\1/p' "$p/pom.xml")
  case "$p" in
    banco-xyz-cloud)
      docker="$(ls "$p"/*/Dockerfile "$p"/docker/*/Dockerfile 2>/dev/null | wc -l | tr -d ' ') archivos"
      imagen="config-server (8888), eureka-server (8761/8762), pki, db" ;;
    *)
      docker="$([ -f "$p/Dockerfile" ] && echo si || echo no)"
      imagen="banco-xyz/$p:1.0.0 ($(sed -n 's/^server.port=//p' "$p/src/main/resources/application.properties"))" ;;
  esac
  printf '%-23s %-9s %-27s %-11s %s\n' "$p/" "$archivos" "${padre:-(agregador, sin padre)}" "$docker" "$imagen"
done
echo
echo "# docker-compose.yaml (raiz): $(docker compose -f docker-compose.yaml config --services 2>/dev/null | wc -l | tr -d ' ') servicios"
# En el orden del archivo (por nivel de arranque); config --services los entrega en otro orden.
awk '/^services:/ {s=1; next} /^[a-z]/ {s=0} s && /^  [a-z][a-z0-9-]*:$/ {sub(":", ""); printf "%s ", $1}' docker-compose.yaml \
  | fold -w 110 -s | sed 's/^/  /'; echo
echo
echo "# Topicos de Kafka que produce y consume cada servicio (leidos del codigo: outbox/ProducerRecord y @KafkaListener)"
for p in $SERVICIOS; do
  topicos=$(find "$p/src/main/java" -name Topicos.java | head -1)
  [ -n "$topicos" ] || { printf '  %-23s (no usa Kafka: emite JWT y consulta al core por HTTP)\n' "$p"; continue; }
  nombre() { sed -n "s/.*String $1 = \"\(.*\)\";/\1/p" "$topicos"; }
  produce=$(grep -rhoE "(registrar|ProducerRecord<>)\(Topicos\.[A-Z_]+" "$p/src/main/java" | sed 's/.*Topicos\.//' | sort -u \
    | while read -r c; do nombre "$c"; done | paste -sd',' - | sed 's/,/, /g')
  consume=$(grep -rhE "@KafkaListener" -A1 "$p/src/main/java" | grep -oE "Topicos\.[A-Z_]+" | sed 's/Topicos\.//' | sort -u \
    | while read -r c; do nombre "$c"; done | paste -sd',' - | sed 's/,/, /g')
  printf '  %-23s produce: %s\n  %-23s consume: %s\n' "$p" "${produce:--}" "" "${consume:--}"
done

echo
echo "# Como se encuentran: nombre en Eureka y Config Server (BANCO_CONFIG_SERVER: https://config-server:8888 en el compose)"
for p in $SERVICIOS; do
  f="$p/src/main/resources/application.properties"
  printf '  %-23s nombre=%-23s %s\n' "$p" "$(sed -n 's/^spring.application.name=//p' "$f")" \
    "$(sed -n 's/^spring.config.import=//p' "$f" | sed 's/:https:\/\/localhost:8888//')"
done

echo
echo "# Codigo importado desde otro proyecto (debe ser 0)"
for p in banco-core-api:core banco-auth:auth transferencias-service:transferencias antifraude-service:antifraude \
         notificaciones-service:notificaciones; do
  proyecto=${p%%:*}; propio=${p##*:}
  n=$(grep -rhoE "^import com\.bancoxyz\.[a-z.]+" "$proyecto/src" | grep -v "com.bancoxyz.$propio" | wc -l | tr -d ' ')
  printf '  %-23s %s\n' "$proyecto" "$n"
done
