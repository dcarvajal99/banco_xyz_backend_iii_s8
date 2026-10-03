#!/usr/bin/env bash
# Corre ./mvnw verify en cada uno de los seis proyectos por separado y deja el log de todos en un archivo.
# Uso: scripts/probar_todo.sh [log]   (por defecto evidencias/logs/verify-proyectos.log). MVN_OPCIONES="-o" sin red.
set -uo pipefail
if [ "${1:-}" = "-h" ]; then sed -n '2,3p' "$0"; exit 0; fi
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
PROYECTOS="${BANCO_PROYECTOS:-$(cd "$RAIZ/.." && pwd)}"
LOG="${1:-$RAIZ/evidencias/logs/verify-proyectos.log}"
mkdir -p "$(dirname "$LOG")"
: > "$LOG"
fallas=0
for proyecto in banco-xyz-cloud banco-core-api banco-auth transferencias-service antifraude-service notificaciones-service; do
  # shellcheck disable=SC2086
  (cd "$PROYECTOS/$proyecto" && ./mvnw ${MVN_OPCIONES:-} verify) >> "$LOG" 2>&1
  estado=$?
  printf '%-24s %s\n' "$proyecto" "$([ $estado -eq 0 ] && echo 'BUILD SUCCESS' || echo 'BUILD FAILURE')"
  [ $estado -eq 0 ] || fallas=$((fallas + 1))
done
echo "Log: $LOG"
[ $fallas -eq 0 ]
