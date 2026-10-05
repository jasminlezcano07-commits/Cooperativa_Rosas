--BLOQUE 2: Seguridad y cumplimiento — Ley N.° 29733 / ISO 27001
-- IMPORTANTE: ejecutar con "Incluir plan de ejecución real" (Ctrl+M) DESACTIVADO. Con Ctrl+M activo, las pruebas c y d
-- fallan con "SHOWPLAN permission denied" porque se ejecutan como usuarios sin ese permiso (EXECUTE AS).
-- Los planes del índice se obtienen en este mismo script con SET STATISTICS XML (no necesita Ctrl+M).
USE CooperativaRosas;
GO

-- LIMPIEZA PARA PODER REPETIR EL SCRIPT (no borra las tablas del Bloque 1).
-- Orden: primero los usuarios, luego los roles y al final los logins del servidor.
-- RECOMENDADO: ejecutar siempre primero el script 01 (base limpia) y luego este.
IF DATABASE_PRINCIPAL_ID('admin_socios')      IS NOT NULL DROP USER admin_socios;
IF DATABASE_PRINCIPAL_ID('vendedor_ventas')   IS NOT NULL DROP USER vendedor_ventas;
IF DATABASE_PRINCIPAL_ID('trabajador_stock')  IS NOT NULL DROP USER trabajador_stock;
IF DATABASE_PRINCIPAL_ID('contador_externo')  IS NOT NULL DROP USER contador_externo;
IF DATABASE_PRINCIPAL_ID('rol_administrador')  IS NOT NULL DROP ROLE rol_administrador;
IF DATABASE_PRINCIPAL_ID('rol_vendedor')       IS NOT NULL DROP ROLE rol_vendedor;
IF DATABASE_PRINCIPAL_ID('rol_trabajador_stock') IS NOT NULL DROP ROLE rol_trabajador_stock;
IF DATABASE_PRINCIPAL_ID('rol_contador')       IS NOT NULL DROP ROLE rol_contador;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'admin_socios')     DROP LOGIN admin_socios;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'vendedor_ventas')  DROP LOGIN vendedor_ventas;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'trabajador_stock') DROP LOGIN trabajador_stock;
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'contador_externo') DROP LOGIN contador_externo;
GO

-- ROLES CON PRIVILEGIOS DIFERENCIADOS
-- Regla general: nadie modifica Cosechas ni Ventas directamente (excepto el administrador);
-- el trabajo diario pasa por los procedimientos almacenados, que validan y dejan auditoría.

-- 1) Administrador: los socios (Francisco y Zoila), control total sobre los datos,
--    PERO no pueden modificar ni borrar la auditoría (LogAuditoria queda como evidencia).
CREATE ROLE rol_administrador;
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO rol_administrador;
DENY UPDATE, DELETE ON dbo.LogAuditoria TO rol_administrador;

-- 2) Vendedor: registra pedidos/ventas por WhatsApp. Solo ejecuta sp_RegistrarVenta
--    y consulta cosechas (stock) y ventas. NO registra cosechas.
CREATE ROLE rol_vendedor;
GRANT EXECUTE ON dbo.sp_RegistrarVenta TO rol_vendedor;
GRANT SELECT ON dbo.Cosechas TO rol_vendedor;
GRANT SELECT ON dbo.Ventas TO rol_vendedor;

-- 3) Trabajador de stock: registra cosechas SOLO mediante sp_RegistrarCosecha
--    (así pasa por las validaciones y por la auditoría). Puede consultar Cosechas;
--    no tiene INSERT/UPDATE/DELETE directo.
CREATE ROLE rol_trabajador_stock;
GRANT EXECUTE ON dbo.sp_RegistrarCosecha TO rol_trabajador_stock;
GRANT SELECT ON dbo.Cosechas TO rol_trabajador_stock;
DENY INSERT, UPDATE, DELETE ON dbo.Cosechas TO rol_trabajador_stock;

-- 4) Contador: solo lectura del log y reportes, no puede modificar nada
CREATE ROLE rol_contador;
GRANT SELECT ON dbo.LogAuditoria TO rol_contador;
GRANT SELECT ON dbo.Ventas TO rol_contador;
GRANT SELECT ON dbo.Cosechas TO rol_contador;
DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo TO rol_contador;
GO

-- USUARIOS: 4 logins, uno por rol (las personas de un mismo rol comparten el usuario de su rol)
-- La contraseña de abajo es un MARCADOR, no una contraseña real: se usa el mismo texto en los 4 logins y cumple la
-- política de Windows (mayúscula, minúscula, número y símbolo, sin el nombre del login).
-- MUST_CHANGE obliga a cambiarla en el primer inicio de sesión (requiere CHECK_EXPIRATION y CHECK_POLICY activados);
-- las contraseñas definitivas no deben guardarse en el repositorio.
-- LIMITACIÓN DECLARADA: como los 4 trabajadores comparten el usuario trabajador_stock, LogAuditoria.usuario_bd
-- identifica el rol, no la persona; la persona queda en el parámetro id_trabajador de sp_RegistrarCosecha
-- (ver 02_checklist_ley29733.md).

--ADMINISTRADOR (los 2 socios)
CREATE LOGIN admin_socios WITH PASSWORD = 'CambiarEnPrimerInicio#1' MUST_CHANGE, CHECK_EXPIRATION = ON, CHECK_POLICY = ON;
CREATE USER admin_socios FOR LOGIN admin_socios;
ALTER ROLE rol_administrador ADD MEMBER admin_socios;

--VENDEDOR
CREATE LOGIN vendedor_ventas WITH PASSWORD = 'CambiarEnPrimerInicio#1' MUST_CHANGE, CHECK_EXPIRATION = ON, CHECK_POLICY = ON;
CREATE USER vendedor_ventas FOR LOGIN vendedor_ventas;
ALTER ROLE rol_vendedor ADD MEMBER vendedor_ventas;

--TRABAJADOR DE STOCK (los 4 trabajadores)
CREATE LOGIN trabajador_stock WITH PASSWORD = 'CambiarEnPrimerInicio#1' MUST_CHANGE, CHECK_EXPIRATION = ON, CHECK_POLICY = ON;
CREATE USER trabajador_stock FOR LOGIN trabajador_stock;
ALTER ROLE rol_trabajador_stock ADD MEMBER trabajador_stock;

--CONTADOR
CREATE LOGIN contador_externo WITH PASSWORD = 'CambiarEnPrimerInicio#1' MUST_CHANGE, CHECK_EXPIRATION = ON, CHECK_POLICY = ON;
CREATE USER contador_externo FOR LOGIN contador_externo;
ALTER ROLE rol_contador ADD MEMBER contador_externo;
GO

-- PRUEBAS DE PRIVILEGIOS (ambas deben fallar con "permiso denegado")
-- a) Un trabajador no puede insertar directo en Cosechas (se salta el procedimiento y la auditoría)
EXECUTE AS USER = 'trabajador_stock';
BEGIN TRY
    INSERT INTO dbo.Cosechas (fecha, id_vivero, id_color, id_rango_tallo, cantidad_paquetes, id_trabajador)
    VALUES ('2026-01-08', 1, 1, 1, 10, 1);
    PRINT 'FALLA: el trabajador pudo insertar directo.';
END TRY
BEGIN CATCH
    PRINT 'Prueba a esperada: ' + ERROR_MESSAGE();
END CATCH;
REVERT;

-- b) Ni el administrador puede borrar la auditoría
EXECUTE AS USER = 'admin_socios';
BEGIN TRY
    DELETE FROM dbo.LogAuditoria WHERE id_log = 1;
    PRINT 'FALLA: el administrador pudo borrar el log.';
END TRY
BEGIN CATCH
    PRINT 'Prueba b esperada: ' + ERROR_MESSAGE();
END CATCH;
REVERT;
GO

-- PRUEBAS POSITIVAS (deben FUNCIONAR: demuestran que el diseño de roles permite el trabajo diario)
-- c) trabajador_stock SÍ puede registrar una cosecha, pero solo a través de sp_RegistrarCosecha
--    (el INSERT interno funciona por encadenamiento de propiedad, aunque el rol tenga DENY INSERT directo)
EXECUTE AS USER = 'trabajador_stock';
BEGIN TRY
    EXEC dbo.sp_RegistrarCosecha '2026-01-10', 2, 'Blanco', 50, 12, 1;
    PRINT 'Prueba c esperada: trabajador_stock registró una cosecha con sp_RegistrarCosecha.';
END TRY
BEGIN CATCH
    PRINT 'Prueba c FALLA: ' + ERROR_MESSAGE();
END CATCH;
REVERT;

-- d) vendedor_ventas SÍ puede registrar una venta con sp_RegistrarVenta (stock: 12 paquetes de Blanco 50 cm el 2026-01-10)
EXECUTE AS USER = 'vendedor_ventas';
BEGIN TRY
    EXEC dbo.sp_RegistrarVenta '2026-01-11', 3, 'Blanco', 50, 5;
    PRINT 'Prueba d esperada: vendedor_ventas registró una venta con sp_RegistrarVenta.';
END TRY
BEGIN CATCH
    PRINT 'Prueba d FALLA: ' + ERROR_MESSAGE();
END CATCH;
REVERT;

-- Evidencia: las filas existen y la auditoría quedó a nombre de cada usuario
SELECT 'Prueba c: cosecha de trabajador_stock (esperado: 1 fila)' AS prueba, COUNT(*) AS filas
FROM Cosechas WHERE fecha = '2026-01-10' AND id_vivero = 2 AND cantidad_paquetes = 12;
SELECT 'Prueba d: venta de vendedor_ventas (esperado: 1 fila)' AS prueba, COUNT(*) AS filas
FROM Ventas WHERE fecha = '2026-01-11' AND id_cliente = 3 AND cantidad_paquetes = 5;
SELECT TOP (2) id_log, tabla_afectada, operacion, usuario_bd, fecha_hora, detalle
FROM LogAuditoria WHERE operacion = 'INSERT' ORDER BY id_log DESC;   -- usuario_bd debe mostrar quién ejecutó
GO

-- POLÍTICA DE RESPALDO (FULL + DIFFERENTIAL) — detalle en 02_politica_respaldo.md
-- Secuencia que se prueba: FULL -> cambios nuevos -> DIFFERENTIAL -> restaurar FULL + DIFF -> comparar.
-- (Crear antes la carpeta C:\Backups o cambiar la ruta.)

-- 1) FULL
BACKUP DATABASE CooperativaRosas
TO DISK = 'C:\Backups\CooperativaRosas_FULL.bak'
WITH INIT, NAME = 'Respaldo completo cooperativa de rosas';
GO

-- Filas existentes al momento del FULL (para probar luego que el DIFF aportó lo nuevo)
IF OBJECT_ID('tempdb..#conteo_full') IS NOT NULL DROP TABLE #conteo_full;
GO
SELECT 'Cosechas' AS tabla, COUNT(*) AS filas_en_full
INTO #conteo_full
FROM dbo.Cosechas
UNION ALL SELECT 'Ventas', COUNT(*) FROM dbo.Ventas
UNION ALL SELECT 'LogAuditoria', COUNT(*) FROM dbo.LogAuditoria;
GO

-- 2) Cambios POSTERIORES al FULL: solo viajan en el DIFFERENTIAL
EXEC dbo.sp_RegistrarCosecha '2026-01-12', 1, 'Rosado', 60, 18, 2;
EXEC dbo.sp_RegistrarVenta   '2026-01-13', 1, 'Rosado', 60, 8;
GO

-- 3) DIFFERENTIAL (INIT para que el archivo contenga solo este respaldo)
BACKUP DATABASE CooperativaRosas
TO DISK = 'C:\Backups\CooperativaRosas_DIFF.bak'
WITH DIFFERENTIAL, INIT, NAME = 'Respaldo diferencial cooperativa de rosas';
GO

-- Verificar que los archivos de respaldo son legibles y completos
RESTORE VERIFYONLY FROM DISK = 'C:\Backups\CooperativaRosas_FULL.bak';
RESTORE VERIFYONLY FROM DISK = 'C:\Backups\CooperativaRosas_DIFF.bak';
GO

-- 4) Script de restauración PROBADO (a una base de prueba): FULL con NORECOVERY y luego DIFF con RECOVERY
RESTORE DATABASE CooperativaRosas_TEST
FROM DISK = 'C:\Backups\CooperativaRosas_FULL.bak'
WITH MOVE 'CooperativaRosas' TO 'C:\Backups\CooperativaRosas_TEST.mdf',
     MOVE 'CooperativaRosas_log' TO 'C:\Backups\CooperativaRosas_TEST.ldf',
     NORECOVERY, REPLACE;

RESTORE DATABASE CooperativaRosas_TEST
FROM DISK = 'C:\Backups\CooperativaRosas_DIFF.bak'
WITH RECOVERY;
GO

-- 5) Comparación: base original vs base restaurada (FULL + DIFF).
--    "filas_en_full" muestra cuántas filas había al hacer el FULL: si filas_restauradas es MAYOR
--    que filas_en_full y IGUAL a filas_origen, el DIFFERENTIAL se aplicó correctamente.
--    (Válida si no hubo cambios entre el DIFF y esta comparación.)
SELECT c.tabla, c.filas_en_full, o.filas_origen, r.filas_restauradas,
       CASE WHEN o.filas_origen = r.filas_restauradas AND r.filas_restauradas > c.filas_en_full
            THEN 'OK' ELSE 'FALLA' END AS resultado
FROM #conteo_full c
JOIN (SELECT 'Cosechas' AS tabla, COUNT(*) AS filas_origen FROM CooperativaRosas.dbo.Cosechas
      UNION ALL SELECT 'Ventas', COUNT(*) FROM CooperativaRosas.dbo.Ventas
      UNION ALL SELECT 'LogAuditoria', COUNT(*) FROM CooperativaRosas.dbo.LogAuditoria) o ON o.tabla = c.tabla
JOIN (SELECT 'Cosechas' AS tabla, COUNT(*) AS filas_restauradas FROM CooperativaRosas_TEST.dbo.Cosechas
      UNION ALL SELECT 'Ventas', COUNT(*) FROM CooperativaRosas_TEST.dbo.Ventas
      UNION ALL SELECT 'LogAuditoria', COUNT(*) FROM CooperativaRosas_TEST.dbo.LogAuditoria) r ON r.tabla = c.tabla;
GO

-- ANÁLISIS DE PLAN DE EJECUCIÓN + ÍNDICE
-- Consulta crítica: buscar ventas de un cliente en un rango de fechas.
-- Tras ejecutar el Bloque 1, Ventas tiene muy pocas filas y el optimizador no puede mostrar mejora.
-- Por eso la medición se hace sobre una TABLA DE PRUEBA (VentasPrueba) con 10,000 filas:
-- misma estructura que Ventas, SIN triggers, así que no escribe nada en LogAuditoria.
-- Anotar los resultados en 02_reporte_indice.md. Los planes salen como enlace XML en la pestaña Resultados
-- (clic para abrir el plan gráfico) gracias a SET STATISTICS XML; no hace falta activar Ctrl+M.
DROP TABLE IF EXISTS dbo.VentasPrueba;   -- permite repetir la medición con la misma tabla de 10,000 filas
GO
CREATE TABLE dbo.VentasPrueba (
    id_venta INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATE NOT NULL,
    id_cliente INT NOT NULL,
    id_color INT NOT NULL,
    id_rango_tallo INT NOT NULL,
    cantidad_paquetes INT NOT NULL,
    precio_unitario_paquete DECIMAL(6,2) NOT NULL
);
GO

-- 10,000 filas sintéticas repartidas en 3 años (2024-2026), 3 clientes, 4 colores y 3 rangos
;WITH n AS (
    SELECT TOP (10000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.VentasPrueba (fecha, id_cliente, id_color, id_rango_tallo, cantidad_paquetes, precio_unitario_paquete)
SELECT fecha, id_cliente, id_color, id_rango_tallo, cantidad_paquetes,
       CASE id_rango_tallo WHEN 1 THEN 20.00 WHEN 2 THEN 23.00 ELSE 26.00 END
FROM (SELECT DATEADD(DAY, i % 1096, CAST('2024-01-01' AS DATE)) AS fecha,
             (i % 3) + 1       AS id_cliente,
             (i % 4) + 1       AS id_color,
             ((i / 3) % 3) + 1 AS id_rango_tallo,
             (i % 50) + 1      AS cantidad_paquetes
      FROM n) AS t;
GO

SELECT COUNT(*) AS filas_VentasPrueba FROM dbo.VentasPrueba;   -- esperado: 10000
IF OBJECT_ID('tempdb..#log_antes') IS NOT NULL DROP TABLE #log_antes;
GO
SELECT COUNT(*) AS filas_log_antes INTO #log_antes FROM dbo.LogAuditoria;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
SET STATISTICS XML ON;   -- devuelve el plan de ejecución real de cada consulta

-- ANTES del índice (se espera Clustered Index Scan sobre las 10,000 filas)
SELECT v.id_venta, v.fecha, v.cantidad_paquetes, v.precio_unitario_paquete
FROM dbo.VentasPrueba v
WHERE v.id_cliente = 1
  AND v.fecha BETWEEN '2026-01-01' AND '2026-03-31';

CREATE NONCLUSTERED INDEX idx_ventasprueba_cliente_fecha
ON dbo.VentasPrueba (id_cliente, fecha)
INCLUDE (cantidad_paquetes, precio_unitario_paquete);
GO

-- DESPUÉS del índice (se espera Index Seek)
SELECT v.id_venta, v.fecha, v.cantidad_paquetes, v.precio_unitario_paquete
FROM dbo.VentasPrueba v
WHERE v.id_cliente = 1
  AND v.fecha BETWEEN '2026-01-01' AND '2026-03-31';

SET STATISTICS XML OFF;
SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO

-- Mismo índice en la tabla real (queda para el uso diario a medida que crezca Ventas)
DROP INDEX IF EXISTS idx_ventas_cliente_fecha ON dbo.Ventas;
CREATE NONCLUSTERED INDEX idx_ventas_cliente_fecha
ON dbo.Ventas (id_cliente, fecha)
INCLUDE (cantidad_paquetes, precio_unitario_paquete);
GO

-- Comprobación: la medición NO ensució la auditoría (mismo número de filas que antes)
SELECT a.filas_log_antes, (SELECT COUNT(*) FROM dbo.LogAuditoria) AS filas_log_despues,
       CASE WHEN a.filas_log_antes = (SELECT COUNT(*) FROM dbo.LogAuditoria) THEN 'OK' ELSE 'REVISAR' END AS resultado
FROM #log_antes a;
GO

-- LIMPIEZA: ejecutar SOLO después de anotar métricas y capturas en 02_reporte_indice.md
-- DROP TABLE dbo.VentasPrueba;
-- DROP DATABASE CooperativaRosas_TEST;
