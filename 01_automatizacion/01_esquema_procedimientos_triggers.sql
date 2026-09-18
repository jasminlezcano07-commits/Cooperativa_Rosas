--PROYECTO: Cooperativa de Rosas 
--BLOQUE 1: Esquema base + Automatización SQL Server 

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

--FUNCIÓN: calcula el precio según el rango de tallo (Paquetes)
CREATE FUNCTION fn_PrecioPorTamano (@tamano_cm INT)
RETURNS DECIMAL(6,2)
AS
BEGIN
    DECLARE @precio DECIMAL(6,2);
    SELECT @precio = precio_unitario FROM Paquetes WHERE tamano_cm = @tamano_cm;
    RETURN @precio;
END;
GO

--PROCEDIMIENTO 1: Registrar cosecha (validación + transacción)
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

        DECLARE @id_rango INT = (SELECT id_rango_tallo FROM Paquetes WHERE tamano_cm = @tamano_cm);
        IF @id_rango IS NULL
            THROW 50003, 'Rango de tallo no válido.', 1;

        SAVE TRANSACTION AntesInsertar;

        INSERT INTO Cosechas (fecha, id_vivero, id_color, id_rango_tallo, cantidad_paquetes, id_trabajador)
        VALUES (@fecha, @id_vivero, @id_color, @id_rango, @cantidad_paquetes, @id_trabajador);

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
--(no permite vender más de lo cosechado en los últimos 7 días)
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

        DECLARE @id_rango INT = (SELECT id_rango_tallo FROM Paquetes WHERE tamano_cm = @tamano_cm);
        DECLARE @precio DECIMAL(6,2) = dbo.fn_PrecioPorTamano(@tamano_cm);

        DECLARE @stock_disponible INT = (
            SELECT ISNULL(SUM(cantidad_paquetes),0)
            FROM Cosechas
            WHERE id_color = @id_color AND id_rango_tallo = @id_rango
              AND fecha BETWEEN DATEADD(DAY,-7,@fecha) AND @fecha
        );

        IF @cantidad_paquetes > @stock_disponible
            THROW 50006, 'La venta supera el stock cosechado en los últimos 7 días.', 1;

        SAVE TRANSACTION AntesInsertarVenta;

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
    INSERT INTO LogAuditoria (tabla_afectada, operacion, detalle)
    SELECT 'Cosechas', 'INSERT',
           CONCAT('Cosecha id=', id_cosecha, ' vivero=', id_vivero,
                  ' color_id=', id_color, ' paquetes=', cantidad_paquetes,
                  ' trabajador=', id_trabajador)
    FROM inserted;
END;
GO

--TRIGGER 2 (integridad): valida que el precio registrado
--corresponda al rango de tallo vendido (evita inconsistencias
--como el problema de calidad detectado en el dataset crudo)
CREATE TRIGGER trg_ValidarPrecioPorTallo
ON Ventas
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Paquetes p ON i.id_rango_tallo = p.id_rango_tallo
        WHERE i.precio_unitario_paquete <> p.precio_unitario
    )
    BEGIN
        INSERT INTO LogAuditoria (tabla_afectada, operacion, detalle)
        VALUES ('Ventas', 'ALERTA_INTEGRIDAD', 'Precio registrado no coincide con el rango de tallo vendido.');
    END
END;
GO

--PRUEBAS
EXEC sp_RegistrarCosecha '2026-01-05', 1, 'Rojo', 60, 15, 1;
EXEC sp_RegistrarVenta   '2026-01-06', 1, 'Rojo', 60, 10;

-- Prueba de error controlado (cantidad negativa) -> debe ir al log
EXEC sp_RegistrarCosecha '2026-01-05', 1, 'Rojo', 60, -5, 1;

-- Prueba de error controlado (venta supera stock) -> debe ir al log
EXEC sp_RegistrarVenta '2026-01-06', 1, 'Rojo', 60, 999;

SELECT * FROM LogAuditoria ORDER BY id_log DESC;

SELECT * FROM Cosechas;
