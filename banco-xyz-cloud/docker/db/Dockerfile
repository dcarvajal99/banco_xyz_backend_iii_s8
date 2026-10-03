# PostgreSQL 17 con el resultado de la migracion de bank_legacy_data (semanas 1 a 3) incorporado: al crear el volumen
# de datos por primera vez, el entrypoint de postgres carga el volcado. Reemplaza al batch, que no es parte del alcance.
# Contexto: banco-xyz-cloud/.
FROM postgres:17-alpine
COPY datos/01_migracion_semana3.sql /docker-entrypoint-initdb.d/01_migracion_semana3.sql
