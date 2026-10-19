-- =====================================================================
-- RELWO - Permisos del rol de aplicacion (relwo_app)
--
-- Equivale a lo que ejecuta el servidor al preparar el rol de aplicacion,
-- en el mismo orden. Es idempotente: parte revocando todo, de modo que el
-- resultado no depende de permisos anteriores.
--
-- Uso: ejecutar conectado a la base relwo COMO EL ROL DUENO (relwo), despues
-- de 01_crear_tablas.sql. Los permisos por omision se declaran desde el dueno.
--   psql -U relwo -d relwo -f 02_usuarios_y_permisos.sql
-- =====================================================================

-- Se parte de cero
REVOKE ALL ON SCHEMA public FROM relwo_app;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM relwo_app;

-- Conexion y uso del esquema (sin CREATE: no puede crear tablas propias)
GRANT CONNECT ON DATABASE relwo TO relwo_app;
GRANT USAGE ON SCHEMA public TO relwo_app;

-- Lectura y escritura de datos sobre las tablas existentes
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO relwo_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO relwo_app;

-- Las tablas que creen las migraciones futuras nacen con los mismos permisos
ALTER DEFAULT PRIVILEGES FOR ROLE relwo IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO relwo_app;
ALTER DEFAULT PRIVILEGES FOR ROLE relwo IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO relwo_app;

-- Tablas de solo agregar: el registro de auditoria y los eventos de producto
-- se insertan y se leen, nunca se modifican ni se borran.
REVOKE UPDATE, DELETE, TRUNCATE ON auditoria FROM relwo_app;
REVOKE UPDATE, DELETE, TRUNCATE ON evento_producto FROM relwo_app;

-- Verificacion
SELECT grantee, table_name, string_agg(privilege_type, ', ' ORDER BY privilege_type) AS permisos
FROM information_schema.role_table_grants
WHERE grantee = 'relwo_app' AND table_name IN ('auditoria', 'evento_producto', 'servicio')
GROUP BY grantee, table_name
ORDER BY table_name;
