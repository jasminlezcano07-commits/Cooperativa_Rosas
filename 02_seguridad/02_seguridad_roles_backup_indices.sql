--BLOQUE 2: Seguridad y cumplimiento — Ley N.° 29733 / ISO 27001
USE CooperativaRosas;
GO

-- ROLES CON PRIVILEGIOS DIFERENCIADOS 
-- 1) Administrador: los socios (Francisco y Zoila), control total
CREATE ROLE rol_administrador;
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO rol_administrador;

-- 2) Analista de ventas: encargado(a) de registrar pedidos/ventas por WhatsApp
CREATE ROLE rol_analista;
GRANT EXECUTE ON sp_RegistrarCosecha TO rol_analista;
GRANT EXECUTE ON sp_RegistrarVenta TO rol_analista;
GRANT SELECT ON Cosechas TO rol_analista;
GRANT SELECT ON Ventas TO rol_analista;

-- 3) Auditor: solo lectura del log y reportes, no puede modificar nada
CREATE ROLE rol_auditor;
GRANT SELECT ON LogAuditoria TO rol_auditor;
GRANT SELECT ON Ventas TO rol_auditor;
GRANT SELECT ON Cosechas TO rol_auditor;
DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo TO rol_auditor;
GO

CREATE LOGIN francisco_admin WITH PASSWORD = 'Coop_Rosas#2026';
CREATE USER francisco_admin FOR LOGIN francisco_admin;
ALTER ROLE rol_administrador ADD MEMBER francisco_admin;

CREATE LOGIN zoila_admin WITH PASSWORD = 'Coop_Rosas#2026';
CREATE USER zoila_admin FOR LOGIN zoila_admin;
ALTER ROLE rol_administrador ADD MEMBER zoila_admin;

CREATE LOGIN encargado_ventas WITH PASSWORD = 'Coop_Rosas#2026';
CREATE USER encargado_ventas FOR LOGIN encargado_ventas;
ALTER ROLE rol_analista ADD MEMBER encargado_ventas;

CREATE LOGIN auditor_externo WITH PASSWORD = 'Coop_Rosas#2026';
CREATE USER auditor_externo FOR LOGIN auditor_externo;
ALTER ROLE rol_auditor ADD MEMBER auditor_externo;
GO

-- POLÍTICA DE RESPALDO (Copia de seguridad) 
BACKUP DATABASE CooperativaRosas
TO DISK = 'C:\Backups\CooperativaRosas_FULL.bak'
WITH INIT, NAME = 'Respaldo completo cooperativa de rosas';

BACKUP DATABASE CooperativaRosas
TO DISK = 'C:\Backups\CooperativaRosas_DIFF.bak'
WITH DIFFERENTIAL, NAME = 'Respaldo diferencial cooperativa de rosas';
GO

-- Script de restauración PROBADO (a una base de prueba)
RESTORE DATABASE CooperativaRosas_TEST
FROM DISK = 'C:\Backups\CooperativaRosas_FULL.bak'
WITH MOVE 'CooperativaRosas' TO 'C:\Backups\CooperativaRosas_TEST.mdf',
     MOVE 'CooperativaRosas_log' TO 'C:\Backups\CooperativaRosas_TEST.ldf',
     REPLACE;
GO

-- ANÁLISIS DE PLAN DE EJECUCIÓN + ÍNDICE 
-- Consulta crítica: buscar pedidos de un cliente en un rango de fechas
SET STATISTICS TIME ON;
SET STATISTICS IO ON;

-- ANTES del índice (se espera Table Scan / Clustered Index Scan)
SELECT v.id_venta, v.fecha, v.cantidad_paquetes, v.precio_unitario_paquete
FROM Ventas v
WHERE v.id_cliente = 1
  AND v.fecha BETWEEN '2026-01-01' AND '2026-03-31';

CREATE NONCLUSTERED INDEX idx_ventas_cliente_fecha
ON Ventas (id_cliente, fecha)
INCLUDE (cantidad_paquetes, precio_unitario_paquete);
GO

-- DESPUÉS del índice (se espera Index Seek)
SELECT v.id_venta, v.fecha, v.cantidad_paquetes, v.precio_unitario_paquete
FROM Ventas v
WHERE v.id_cliente = 1
  AND v.fecha BETWEEN '2026-01-01' AND '2026-03-31';

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
