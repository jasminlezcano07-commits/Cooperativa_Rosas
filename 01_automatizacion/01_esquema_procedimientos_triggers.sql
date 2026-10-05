--PROYECTO: Cooperativa de Rosas 
--BLOQUE 1: Esquema base + Automatización SQL Server 

-- RE-EJECUTABLE: si la base ya existe, se borra y se vuelve a crear desde cero
-- (así los resultados de las pruebas P1 a P8 salen siempre iguales).
USE master;
GO
IF DB_ID('CooperativaRosas') IS NOT NULL
BEGIN
    ALTER DATABASE CooperativaRosas SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CooperativaRosas;
END
GO
CREATE DATABASE CooperativaRosas;
GO
USE CooperativaRosas;
GO

-- ---------- CATÁLOGOS ----------
CREATE TABLE Viveros (
    id_vivero INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE Trabajadores (
    id_trabajador INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE Colores (
    id_color INT IDENTITY(1,1) PRIMARY KEY,
    nombre_color VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE Clientes (
    id_cliente INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    ciudad VARCHAR(50) DEFAULT 'Chiclayo'
);

-- Tabla de referencia de rangos de tallo y precio (evita "números mágicos")
CREATE TABLE Paquetes (
    id_rango_tallo INT IDENTITY(1,1) PRIMARY KEY,
    tamano_cm INT NOT NULL UNIQUE CHECK (tamano_cm IN (50,60,80)), -- 80 representa el rango 70-90cm
    precio_unitario DECIMAL(6,2) NOT NULL,
    unidades_por_paquete INT NOT NULL DEFAULT 24
);

INSERT INTO Paquetes (tamano_cm, precio_unitario, unidades_por_paquete) VALUES
(50, 20.00, 24),
(60, 23.00, 24),
(80, 26.00, 24);

CREATE TABLE Cosechas (
    id_cosecha INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATE NOT NULL,
    id_vivero INT NOT NULL FOREIGN KEY REFERENCES Viveros(id_vivero),
    id_color INT NOT NULL FOREIGN KEY REFERENCES Colores(id_color),
    id_rango_tallo INT NOT NULL FOREIGN KEY REFERENCES Paquetes(id_rango_tallo),
    cantidad_paquetes INT NOT NULL CHECK (cantidad_paquetes >= 0),
    id_trabajador INT NOT NULL FOREIGN KEY REFERENCES Trabajadores(id_trabajador)
);

CREATE TABLE Ventas (
    id_venta INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATE NOT NULL,
    id_cliente INT NOT NULL FOREIGN KEY REFERENCES Clientes(id_cliente),
    id_color INT NOT NULL FOREIGN KEY REFERENCES Colores(id_color),
    id_rango_tallo INT NOT NULL FOREIGN KEY REFERENCES Paquetes(id_rango_tallo),
    cantidad_paquetes INT NOT NULL CHECK (cantidad_paquetes > 0),
    precio_unitario_paquete DECIMAL(6,2) NOT NULL
);

CREATE TABLE LogAuditoria (
    id_log INT IDENTITY(1,1) PRIMARY KEY,
    tabla_afectada VARCHAR(50),
    operacion VARCHAR(20),
    usuario_bd VARCHAR(100) DEFAULT SUSER_SNAME(),
    fecha_hora DATETIME DEFAULT GETDATE(),
    detalle VARCHAR(500)
);
GO

-- Catálogos base
INSERT INTO Viveros (nombre) VALUES ('Vivero Llagamarca 1'), ('Vivero Llagamarca 2');
INSERT INTO Trabajadores (nombre) VALUES ('Juan Perez'), ('Maria Rojas'), ('Pedro Diaz'), ('Lucia Vega');
INSERT INTO Colores (nombre_color) VALUES ('Rojo'), ('Amarillo'), ('Blanco'), ('Rosado');
INSERT INTO Clientes (nombre) VALUES ('Mayorista Chiclayo Norte'), ('Distribuidora Flor del Valle'), ('Comercial Rosas SAC');
GO

--FUNCIÓN 1: regla única de rangos de tallo (medida en cm -> fila de la tabla Paquetes)
--Rangos acordados con los socios: hasta 50 cm -> rango 50 | 60 cm -> rango 60 | 70-90 cm -> rango 80
--(la fila "80" de Paquetes representa el rango 70-90). Cualquier otra medida devuelve NULL.
--Es la ÚNICA copia de esta regla: la usan fn_PrecioPorTamano y los 2 procedimientos.
CREATE FUNCTION fn_RangoTallo (@tamano_cm INT)
RETURNS INT
AS
BEGIN
    DECLARE @tamano_ref INT = CASE
        WHEN @tamano_cm BETWEEN 1 AND 50 THEN 50
        WHEN @tamano_cm = 60             THEN 60
        WHEN @tamano_cm BETWEEN 70 AND 90 THEN 80
        ELSE NULL
    END;
    RETURN (SELECT id_rango_tallo FROM Paquetes WHERE tamano_cm = @tamano_ref);
END;
GO

--FUNCIÓN 2: calcula el precio según el rango de tallo. Los precios viven SOLO en la
--tabla Paquetes; la función los consulta usando fn_RangoTallo. Sin rango -> NULL.
CREATE FUNCTION fn_PrecioPorTamano (@tamano_cm INT)
RETURNS DECIMAL(6,2)
AS
BEGIN
    RETURN (SELECT precio_unitario FROM Paquetes
            WHERE id_rango_tallo = dbo.fn_RangoTallo(@tamano_cm));
END;
GO

--PROCEDIMIENTO 1: Registrar cosecha (validación + transacción + SAVEPOINT)
--Regla del SAVEPOINT: un vivero no puede registrar más de 120 paquetes en un día
--(supuesto 5 del relevamiento). Si se pasa, se deshace SOLO el INSERT (ROLLBACK TO),
--se deja constancia en el log y se confirma (COMMIT) esa constancia.
CREATE PROCEDURE sp_RegistrarCosecha
    @fecha DATE,
    @id_vivero INT,
    @nombre_color VARCHAR(20),
    @tamano_cm INT,
    @cantidad_paquetes INT,
    @id_trabajador INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @cantidad_paquetes IS NULL OR @cantidad_paquetes < 0
            THROW 50001, 'La cantidad de paquetes no puede ser negativa o nula.', 1;

        DECLARE @id_color INT = (SELECT id_color FROM Colores WHERE nombre_color = @nombre_color);
        IF @id_color IS NULL
            THROW 50002, 'Color de rosa no reconocido en el catálogo.', 1;

        DECLARE @id_rango INT = dbo.fn_RangoTallo(@tamano_cm);   -- misma regla que fn_PrecioPorTamano (50, 60 y 70-90 cm)
        IF @id_rango IS NULL
            THROW 50003, 'Rango de tallo no válido.', 1;

        SAVE TRANSACTION AntesInsertar;

        INSERT INTO Cosechas (fecha, id_vivero, id_color, id_rango_tallo, cantidad_paquetes, id_trabajador)
        VALUES (@fecha, @id_vivero, @id_color, @id_rango, @cantidad_paquetes, @id_trabajador);

        DECLARE @total_dia INT = (SELECT SUM(cantidad_paquetes) FROM Cosechas
                                  WHERE fecha = @fecha AND id_vivero = @id_vivero);

        IF @total_dia > 120
        BEGIN
            ROLLBACK TRANSACTION AntesInsertar;   -- deshace el INSERT (y su fila de trigger), no toda la transacción

            INSERT INTO LogAuditoria (tabla_afectada, operacion, detalle)
            VALUES ('Cosechas', 'RECHAZO_LIMITE',
                    CONCAT('Cosecha rechazada: el vivero ', @id_vivero, ' llegaría a ', @total_dia,
                           ' paquetes el ', CONVERT(VARCHAR(10), @fecha, 23), ' (máximo 120).'));

            COMMIT TRANSACTION;                   -- confirma solo la constancia en el log
            PRINT 'Cosecha rechazada: supera 120 paquetes por vivero y día (ver LogAuditoria).';
            RETURN;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        INSERT INTO LogAuditoria (tabla_afectada, operacion, detalle)
        VALUES ('Cosechas', 'ERROR_INSERT', ERROR_MESSAGE());

        THROW;
    END CATCH
END;
GO

--PROCEDIMIENTO 2: Registrar venta/pedido con validación de stock
--REGLA: la cantidad de ESTA venta no puede superar lo cosechado del mismo color y rango
--de tallo en los 7 días anteriores (hasta la fecha de la venta).
--LIMITACIÓN DECLARADA: la regla NO descuenta las ventas anteriores del mismo color y rango;
--compara cada venta contra la cosecha de los 7 días, no contra un saldo de inventario.
--ALCANCE: aplica a los registros NUEVOS que entran por este procedimiento. El histórico
--sintético (ventas_raw.csv: 30 ventas) NO pasa por aquí: va directo al Data Warehouse por el ETL.
--(Con esta regla, 21 de esas 30 ventas habrían sido rechazadas, porque el dataset sintético
--se generó sin relacionar ventas con cosechas.)
--El precio NO lo escribe el usuario: lo calcula fn_PrecioPorTamano.
CREATE PROCEDURE sp_RegistrarVenta
    @fecha DATE,
    @id_cliente INT,
    @nombre_color VARCHAR(20),
    @tamano_cm INT,
    @cantidad_paquetes INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @cantidad_paquetes IS NULL OR @cantidad_paquetes <= 0
            THROW 50004, 'La cantidad de paquetes vendidos debe ser mayor a cero.', 1;

        DECLARE @id_color INT = (SELECT id_color FROM Colores WHERE nombre_color = @nombre_color);
        IF @id_color IS NULL
            THROW 50005, 'Color de rosa no reconocido en el catálogo.', 1;

        DECLARE @id_rango INT = dbo.fn_RangoTallo(@tamano_cm);   -- misma regla que fn_PrecioPorTamano (50, 60 y 70-90 cm)
        IF @id_rango IS NULL
            THROW 50007, 'Rango de tallo no válido.', 1;

        DECLARE @precio DECIMAL(6,2) = dbo.fn_PrecioPorTamano(@tamano_cm);

        DECLARE @stock_disponible INT = (
            SELECT ISNULL(SUM(cantidad_paquetes),0)
            FROM Cosechas
            WHERE id_color = @id_color AND id_rango_tallo = @id_rango
              AND fecha BETWEEN DATEADD(DAY,-7,@fecha) AND @fecha
        );

        IF @cantidad_paquetes > @stock_disponible
            THROW 50006, 'La venta supera el stock cosechado en los últimos 7 días.', 1;

        INSERT INTO Ventas (fecha, id_cliente, id_color, id_rango_tallo, cantidad_paquetes, precio_unitario_paquete)
        VALUES (@fecha, @id_cliente, @id_color, @id_rango, @cantidad_paquetes, @precio);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        INSERT INTO LogAuditoria (tabla_afectada, operacion, detalle)
        VALUES ('Ventas', 'ERROR_INSERT', ERROR_MESSAGE());

        THROW;
    END CATCH
END;
GO

--TRIGGER 1 (auditoría DML): registra cada cosecha nueva
CREATE TRIGGER trg_AuditoriaCosecha
ON Cosechas
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO LogAuditoria (tabla_afectada, operacion, detalle)
    SELECT 'Cosechas', 'INSERT',
           CONCAT('Cosecha id=', id_cosecha, ' vivero=', id_vivero,
                  ' color_id=', id_color, ' paquetes=', cantidad_paquetes,
                  ' trabajador=', id_trabajador)
    FROM inserted;
END;
GO

--TRIGGER 2 (auditoría DML): registra cada venta nueva (RF3)
CREATE TRIGGER trg_AuditoriaVenta
ON Ventas
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO LogAuditoria (tabla_afectada, operacion, detalle)
    SELECT 'Ventas', 'INSERT',
           CONCAT('Venta id=', id_venta, ' cliente=', id_cliente,
                  ' color_id=', id_color, ' paquetes=', cantidad_paquetes,
                  ' precio=', precio_unitario_paquete)
    FROM inserted;
END;
GO

--TRIGGER 3 (integridad): BLOQUEA cualquier venta cuyo precio no corresponda al
--rango de tallo (evita inconsistencias como las ventas 9 y 22 del dataset crudo).
--Deshace el INSERT (rollback), deja constancia en el log y lanza el error (THROW).
CREATE TRIGGER trg_ValidarPrecioPorTallo
ON Ventas
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Paquetes p ON i.id_rango_tallo = p.id_rango_tallo
        WHERE i.precio_unitario_paquete <> p.precio_unitario
    )
    BEGIN
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        INSERT INTO LogAuditoria (tabla_afectada, operacion, detalle)
        VALUES ('Ventas', 'BLOQUEO_PRECIO', 'Venta bloqueada: el precio no coincide con el rango de tallo vendido.');

        THROW 50010, 'Venta bloqueada: el precio no coincide con el rango de tallo.', 1;
    END
END;
GO

-- =====================================================================
-- PRUEBAS (cada error esperado se captura para que el script continúe)
-- =====================================================================

-- P1. Cosecha y venta correctas
EXEC sp_RegistrarCosecha '2026-01-05', 1, 'Rojo', 60, 15, 1;
EXEC sp_RegistrarVenta   '2026-01-06', 1, 'Rojo', 60, 10;

-- P2. Error controlado: cantidad negativa -> ROLLBACK + ERROR_INSERT en el log
BEGIN TRY
    EXEC sp_RegistrarCosecha '2026-01-05', 1, 'Rojo', 60, -5, 1;
END TRY
BEGIN CATCH
    PRINT 'P2 esperado: ' + ERROR_MESSAGE();
END CATCH;

-- P3. Error controlado: venta mayor al stock -> ROLLBACK + ERROR_INSERT en el log
BEGIN TRY
    EXEC sp_RegistrarVenta '2026-01-06', 1, 'Rojo', 60, 999;
END TRY
BEGIN CATCH
    PRINT 'P3 esperado: ' + ERROR_MESSAGE();
END CATCH;

-- P4. SAVEPOINT: 100 paquetes se aceptan; 30 más el mismo día y vivero (130 > 120)
--     se deshacen con ROLLBACK TO y queda RECHAZO_LIMITE en el log.
EXEC sp_RegistrarCosecha '2026-01-07', 1, 'Rojo', 60, 100, 1;
EXEC sp_RegistrarCosecha '2026-01-07', 1, 'Rojo', 60, 30, 1;
SELECT 'Cosechas del 2026-01-07 (debe haber 1 fila de 100)' AS prueba, id_cosecha, cantidad_paquetes
FROM Cosechas WHERE fecha = '2026-01-07' AND id_vivero = 1;

-- P5. Trigger de integridad: INSERT directo con precio incorrecto (S/99 en vez de S/20)
--     -> trg_ValidarPrecioPorTallo lo bloquea y deja BLOQUEO_PRECIO en el log.
BEGIN TRY
    INSERT INTO Ventas (fecha, id_cliente, id_color, id_rango_tallo, cantidad_paquetes, precio_unitario_paquete)
    VALUES ('2026-01-06', 1, 1, 1, 5, 99.00);
    PRINT 'P5 FALLA: el trigger no bloqueó la venta.';
END TRY
BEGIN CATCH
    PRINT 'P5 esperado: ' + ERROR_MESSAGE();
END CATCH;
SELECT 'Ventas con precio 99 (debe ser 0)' AS prueba, COUNT(*) AS filas
FROM Ventas WHERE precio_unitario_paquete = 99.00;

-- P6. Función fn_PrecioPorTamano: 10 pruebas (RF2)
DECLARE @pruebas TABLE (n INT, tamano_cm INT, esperado DECIMAL(6,2));
INSERT INTO @pruebas VALUES
 (1, 40, 20), (2, 50, 20), (3, 60, 23), (4, 70, 26), (5, 80, 26),
 (6, 90, 26), (7, 30, 20), (8, 55, NULL), (9, 100, NULL), (10, 0, NULL);

SELECT n, tamano_cm, esperado,
       dbo.fn_PrecioPorTamano(tamano_cm) AS obtenido,
       CASE WHEN ISNULL(dbo.fn_PrecioPorTamano(tamano_cm), -1) = ISNULL(esperado, -1)
            THEN 'OK' ELSE 'FALLA' END AS resultado
FROM @pruebas ORDER BY n;

-- P7. Rangos 70-90 cm por los procedimientos (misma regla que la función: S/ 26)
--     Cosecha de 70 cm y venta de 90 cm del mismo color: ambas caen en el rango 70-90 (fila "80").
EXEC sp_RegistrarCosecha '2026-01-08', 2, 'Amarillo', 70, 20, 2;
EXEC sp_RegistrarVenta   '2026-01-09', 2, 'Amarillo', 90, 5;
SELECT 'P7: venta de 90 cm (esperado: rango 70-90 y precio 26.00)' AS prueba,
       v.id_venta, p.tamano_cm AS rango_ref, v.precio_unitario_paquete
FROM Ventas v JOIN Paquetes p ON p.id_rango_tallo = v.id_rango_tallo
WHERE v.fecha = '2026-01-09' AND v.id_cliente = 2;

-- P8. Medida sin precio acordado (55 cm): sigue siendo "Rango de tallo no válido"
BEGIN TRY
    EXEC sp_RegistrarVenta '2026-01-09', 2, 'Amarillo', 55, 1;
    PRINT 'P8 FALLA: aceptó 55 cm.';
END TRY
BEGIN CATCH
    PRINT 'P8 esperado: ' + ERROR_MESSAGE();
END CATCH;

-- Evidencia: log de auditoría y resumen por tipo de operación
SELECT * FROM LogAuditoria ORDER BY id_log DESC;
SELECT tabla_afectada, operacion, COUNT(*) AS veces
FROM LogAuditoria GROUP BY tabla_afectada, operacion ORDER BY tabla_afectada, operacion;
SELECT * FROM Cosechas;
