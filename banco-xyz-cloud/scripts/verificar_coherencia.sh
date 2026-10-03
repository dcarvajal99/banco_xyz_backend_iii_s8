#!/usr/bin/env bash
# Evidencia 15 - Lo que comparten los proyectos independientes sin compartir codigo: el contrato de los eventos (cada
# servicio guarda su copia del sobre y de los nombres de topicos) y los datos de validacion de los JWT. Deben coincidir.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
if [ "${1:-}" = "-h" ]; then sed -n '2,3p' "$0"; exit 0; fi
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
PROYECTOS="${BANCO_PROYECTOS:-$(cd "$RAIZ/.." && pwd)}"
cd "$PROYECTOS" || exit 1
EVENTOS="banco-core-api transferencias-service antifraude-service notificaciones-service"

titulo "Evidencia 15 · Coherencia entre proyectos independientes" \
       "Sin librería compartida: el contrato de los eventos se copia en cada servicio y se verifica que sea el mismo."

paso "Sobre del evento (EventoDeTransferencia): mismos campos y mismos tipos de evento en los cuatro servicios"
ORIGINAL=$(find banco-core-api/src/main/java -name EventoDeTransferencia.java)
campos() { sed -n '/public record EventoDeTransferencia(/,/) {/p' "$1" | tr -s ' \n' ' ' | sed 's/.*(//; s/).*//'; }
tipos() { grep -oE 'String [A-Z_]+ = "[A-Za-z]+"' "$1" | sort | paste -sd',' -; }
printf '  original banco-core-api: %s campos, %s tipos de evento\n' "$(campos "$ORIGINAL" | awk -F, '{print NF}')" \
  "$(tipos "$ORIGINAL" | awk -F, '{print NF}')"
for p in transferencias-service antifraude-service notificaciones-service; do
  copia=$(find "$p/src/main/java" -name EventoDeTransferencia.java)
  comprobar "$p: campos del sobre iguales al original" "$([ "$(campos "$copia")" = "$(campos "$ORIGINAL")" ] && echo si || echo no)" "si"
  comprobar "$p: tipos de evento iguales al original" "$([ "$(tipos "$copia")" = "$(tipos "$ORIGINAL")" ] && echo si || echo no)" "si"
done

paso "Lector de eventos versionado (LectorDeEventos y VersionNoSoportada): la misma lógica en los cuatro servicios"
sin_paquete() { sed '/^package /d' "$1"; }
LECTOR=$(find banco-core-api/src/main/java -name LectorDeEventos.java)
VERSION=$(find banco-core-api/src/main/java -name VersionNoSoportada.java)
printf '  original banco-core-api: version actual %s, moneda por omision %s\n' \
  "$(sed -n 's/.*int VERSION_ACTUAL = \([0-9]*\);/\1/p' "$ORIGINAL")" "$(sed -n 's/.*MONEDA_POR_OMISION = "\([A-Z]*\)";/\1/p' "$ORIGINAL")"
for p in transferencias-service antifraude-service notificaciones-service; do
  iguales=$([ "$(sin_paquete "$LECTOR")" = "$(sin_paquete "$(find "$p/src/main/java" -name LectorDeEventos.java)")" ] \
    && [ "$(sin_paquete "$VERSION")" = "$(sin_paquete "$(find "$p/src/main/java" -name VersionNoSoportada.java)")" ] && echo si || echo no)
  comprobar "$p: lector y version no soportada iguales al original" "$iguales" "si"
done

paso "Nombres de tópicos: cada constante usada tiene el mismo valor en todos los servicios"
for p in $EVENTOS; do
  grep -hoE 'String [A-Z_]+ = "[a-z.]+"' "$(find "$p/src/main/java" -name Topicos.java)" | sed "s/^String /$p /"
done | sort -k2,2 -k1,1 | awk '{printf "  %-23s %-13s %s\n", $1, $2, $4}' | tr -d '"'
DISTINTOS=$(for p in $EVENTOS; do grep -hoE 'String [A-Z_]+ = "[a-z.]+"' "$(find "$p/src/main/java" -name Topicos.java)"; done \
  | sort -u | awk '{print $2}' | uniq -d | wc -l | tr -d ' ')
comprobar "constantes con valores distintos entre servicios" "$DISTINTOS" "0"
comprobar "servicios que publican al DLT con el sufijo .DLT" \
  "$(grep -rl 'topic() + ".DLT"' --include='*.java' $EVENTOS | wc -l | tr -d ' ')" "4"

paso "Validación de JWT: los valores locales de respaldo coinciden con los del Config Server"
for clave in emisor audiencia jwk-set-uri; do
  central=$(sed -n "s/^banco.jwt.$clave=//p" "$RAIZ/configuracion/application.properties")
  printf '  banco.jwt.%-12s Config Server: %s\n' "$clave" "$central"
  for p in banco-core-api transferencias-service notificaciones-service; do
    local_=$(sed -n "s/^banco.jwt.$clave=\${[^:]*:\(.*\)}$/\1/p; s/^banco.jwt.$clave=\([^$].*\)$/\1/p" "$p/src/main/resources/application.properties" | head -1)
    comprobar "$p banco.jwt.$clave" "$local_" "$central"
  done
done

paso "Resilience4j: la copia de las políticas que usan las pruebas es igual a la del Config Server (central + servicio)"
politica() { sed -e ':a' -e '/\\$/N; s/\\\n *//; ta' "$@" | grep '^resilience4j\.' | sort; }
for p in banco-auth transferencias-service banco-core-api; do
  central=$(politica "$RAIZ/configuracion/application.properties" "$RAIZ/configuracion/$p.properties")
  prueba=$(politica "$p/src/test/resources/application-prueba.properties")
  jar=$(grep -c '^resilience4j\.' "$p/src/main/resources/application.properties")
  printf '  %-24s %2s propiedades centrales · %2s en la copia de pruebas · %s en el jar\n' "$p" \
    "$(printf '%s\n' "$central" | grep -c .)" "$(printf '%s\n' "$prueba" | grep -c .)" "$jar"
  comprobar "$p: copia de pruebas igual a la central y jar sin politica" "$([ "$central" = "$prueba" ] && [ "$jar" = 0 ] && echo si || echo no)" "si"
done

paso "Ningún proyecto depende de la carpeta de otro: sin rutas ../ que salgan del proyecto ni pom padre común"
# En banco-xyz-cloud, config-server lee ../configuracion: sube solo hasta banco-xyz-cloud, no sale del proyecto.
for proyecto in banco-xyz-cloud banco-core-api banco-auth transferencias-service antifraude-service notificaciones-service; do
  rutas=$(grep -rn '"\.\.",\|\.\./' "$proyecto" --include='*.java' --include='*.properties' --include=pom.xml 2>/dev/null \
    | grep -v '/target/' | grep -v '\.\./configuracion' | wc -l | tr -d ' ')
  padre=$(sed -n '/<parent>/,/<\/parent>/s/.*<artifactId>\(.*\)<\/artifactId>.*/\1/p' "$proyecto/pom.xml")
  comprobar "$proyecto: rutas hacia otros proyectos · pom padre" "$rutas · ${padre:-(agregador sin padre)}" \
    "0 · $([ "$proyecto" = banco-xyz-cloud ] && echo '(agregador sin padre)' || echo spring-boot-starter-parent)"
done

resumen_final
