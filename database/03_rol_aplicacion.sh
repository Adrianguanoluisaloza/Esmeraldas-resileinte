#!/bin/sh
# Crea el usuario de base que usa la API, con permisos mínimos (principio de menor privilegio).
# La API NO se conecta como dueño de la base: no puede crear ni borrar tablas, ni borrar reportes.
# Se ejecuta solo la primera vez (docker-entrypoint-initdb.d). Requiere APP_DB_PASSWORD.
set -eu

if [ -z "${APP_DB_PASSWORD:-}" ]; then
  echo "APP_DB_PASSWORD no definida: no se crea el usuario de la aplicación" >&2
  exit 1
fi

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  -v app_pass="$APP_DB_PASSWORD" -v base="$POSTGRES_DB" <<'SQL'
CREATE ROLE resiliente_app LOGIN PASSWORD :'app_pass' NOSUPERUSER NOCREATEDB NOCREATEROLE;
GRANT CONNECT ON DATABASE :"base" TO resiliente_app;
GRANT USAGE ON SCHEMA public TO resiliente_app;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- Lectura de todo el modelo.
GRANT SELECT ON ALL TABLES IN SCHEMA public TO resiliente_app;
-- Escritura solo donde la operación lo necesita. Sin DELETE en ninguna tabla.
GRANT INSERT, UPDATE ON usuarios, reportes, alertas TO resiliente_app;
GRANT UPDATE (ocupacion, activo, actualizado_en) ON puntos_servicio TO resiliente_app;
GRANT UPDATE (estado, actualizado_en) ON vias TO resiliente_app;
GRANT INSERT ON reportes_historial, entregas TO resiliente_app;

-- Límites para que una consulta mala no tumbe el servidor.
ALTER ROLE resiliente_app SET statement_timeout = '10s';
ALTER ROLE resiliente_app SET idle_in_transaction_session_timeout = '30s';
SQL
