-- =====================================================================
-- RELWO - Creacion de la base de datos y de sus usuarios (roles)
-- Motor: PostgreSQL 17 con PostGIS
--
-- La base usa dos roles con responsabilidades separadas, aplicadas en el
-- entorno de prueba el 14-09-2026:
--
--   relwo      Dueno de las tablas. Solo lo usan las migraciones y los
--              scripts de carga. Nunca atiende peticiones de la aplicacion.
--   relwo_app  Rol con el que el backend (NestJS) atiende peticiones. No es
--              dueno de nada: lee y escribe datos, pero no puede crear,
--              alterar ni borrar tablas, ni desactivar los disparadores que
--              protegen el registro de auditoria.
--
-- Las contrasenas reales NO se escriben en este archivo: en la nube viven en
-- el gestor de secretos del proveedor de nube. Antes de
-- ejecutar, reemplazar los valores <...>.
--
-- Uso: ejecutar conectado como superusuario (postgres) a la base postgres.
--   psql -U postgres -d postgres -f 00_crear_base_y_usuarios.sql
-- =====================================================================

-- 1. Rol dueno de las tablas (corre las migraciones)
CREATE ROLE relwo LOGIN PASSWORD '<contrasena_del_dueno>';

-- 2. Base de datos de la aplicacion, propiedad del rol dueno
CREATE DATABASE relwo OWNER relwo ENCODING 'UTF8' TEMPLATE template0;

-- 3. Rol de la aplicacion. Se crea por SQL y no desde la consola de Cloud SQL,
--    porque alli quedaria con cloudsqlsuperuser (CREATEDB y CREATEROLE), que
--    es mas de lo que necesita un rol que solo atiende peticiones.
CREATE ROLE relwo_app LOGIN PASSWORD '<contrasena_de_la_aplicacion>'
  NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT;

-- 4. Extensiones (requieren superusuario; se crean dentro de la base relwo)
\connect relwo
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS unaccent;
