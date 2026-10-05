--DDL del Data Warehouse - Esquema estrella (Kimball)
-- RE-EJECUTABLE: si el Data Warehouse ya existe, se borra y se vuelve a crear.
USE master;
GO
IF DB_ID('DW_CooperativaRosas') IS NOT NULL
BEGIN
    ALTER DATABASE DW_CooperativaRosas SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DW_CooperativaRosas;
END
GO
CREATE DATABASE DW_CooperativaRosas;
GO

USE DW_CooperativaRosas;
GO

CREATE TABLE DimTiempo (
    id_tiempo_dw INT PRIMARY KEY,
    fecha DATE,
    anio INT,
    mes INT,
    semana INT
);

CREATE TABLE DimCliente (
    id_cliente_dw INT PRIMARY KEY,
    cliente VARCHAR(150)
);

CREATE TABLE DimColor (
    id_color_dw INT PRIMARY KEY,
    color VARCHAR(20)
);

CREATE TABLE DimTamano (
    id_tamano_dw INT PRIMARY KEY,
    tamano_cm INT
);

CREATE TABLE DimVivero (
    id_vivero_dw INT PRIMARY KEY,
    vivero VARCHAR(100)
);

CREATE TABLE FactVentas (
    id_venta INT PRIMARY KEY,
    id_tiempo_dw INT FOREIGN KEY REFERENCES DimTiempo(id_tiempo_dw),
    id_cliente_dw INT FOREIGN KEY REFERENCES DimCliente(id_cliente_dw),
    id_color_dw INT FOREIGN KEY REFERENCES DimColor(id_color_dw),
    id_tamano_dw INT FOREIGN KEY REFERENCES DimTamano(id_tamano_dw),
    cantidad_paquetes INT,
    precio_unitario_paquete DECIMAL(6,2),
    ingreso_total DECIMAL(10,2)
);

CREATE TABLE FactCosechas (
    id_cosecha INT PRIMARY KEY,
    id_tiempo_dw INT FOREIGN KEY REFERENCES DimTiempo(id_tiempo_dw),
    id_vivero_dw INT FOREIGN KEY REFERENCES DimVivero(id_vivero_dw),
    id_color_dw INT FOREIGN KEY REFERENCES DimColor(id_color_dw),
    id_tamano_dw INT FOREIGN KEY REFERENCES DimTamano(id_tamano_dw),
    cantidad_paquetes INT
);

GO

/* ============================================================
   CARGA: 7 BULK INSERT de los CSV generados por el ETL
   (04_etl_datawarehouse.py). Los CSV tienen encabezado (por eso
   FIRSTROW = 2), separador coma y las columnas en el mismo orden
   que las tablas de arriba.

   ANTES DE EJECUTAR:
   1) Editar SOLO la variable @ruta (línea marcada abajo): poner la
      carpeta 04_datawarehouse del equipo donde corre SQL Server.
      BULK INSERT lee el archivo desde el servidor, no desde SSMS; la cuenta
      del servicio de SQL Server debe poder leer esa carpeta.
   2) Ejecutar este script completo (se puede repetir: borra y recrea la base).
   Orden: primero las dimensiones y luego los hechos (por las claves foráneas).
   ============================================================ */

DECLARE @ruta NVARCHAR(260) = N'C:\Grupo04_CIIN1021P_EF_REPO\04_datawarehouse\';   -- <== EDITAR SOLO ESTA LÍNEA
DECLARE @opciones NVARCHAR(200) = N''' WITH (FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''\n'', TABLOCK);';
DECLARE @sql NVARCHAR(MAX);

IF RIGHT(@ruta, 1) <> N'\' SET @ruta = @ruta + N'\';   -- por si olvidan la barra final

-- BULK INSERT no acepta variables en FROM, por eso se arma cada instrucción como texto y se ejecuta.
SET @sql = N'BULK INSERT dbo.DimTiempo FROM ''' + @ruta + N'DimTiempo.csv' + @opciones;     EXEC (@sql);
SET @sql = N'BULK INSERT dbo.DimCliente FROM ''' + @ruta + N'DimCliente.csv' + @opciones;   EXEC (@sql);
SET @sql = N'BULK INSERT dbo.DimColor FROM ''' + @ruta + N'DimColor.csv' + @opciones;       EXEC (@sql);
SET @sql = N'BULK INSERT dbo.DimTamano FROM ''' + @ruta + N'DimTamano.csv' + @opciones;     EXEC (@sql);
SET @sql = N'BULK INSERT dbo.DimVivero FROM ''' + @ruta + N'DimVivero.csv' + @opciones;     EXEC (@sql);
SET @sql = N'BULK INSERT dbo.FactVentas FROM ''' + @ruta + N'FactVentas.csv' + @opciones;   EXEC (@sql);
SET @sql = N'BULK INSERT dbo.FactCosechas FROM ''' + @ruta + N'FactCosechas.csv' + @opciones; EXEC (@sql);
GO

/* ============================================================
   VERIFICACIÓN DE CARGA: COUNT(*) por tabla contra las filas
   que registró el ETL en log_etl.txt
   ============================================================ */
SELECT tabla, filas_cargadas, filas_esperadas_log_etl,
       CASE WHEN filas_cargadas = filas_esperadas_log_etl THEN 'OK' ELSE 'REVISAR' END AS estado
FROM (
    SELECT 'DimTiempo'    AS tabla, COUNT(*) AS filas_cargadas, 50  AS filas_esperadas_log_etl FROM DimTiempo
    UNION ALL SELECT 'DimCliente',   COUNT(*), 3   FROM DimCliente
    UNION ALL SELECT 'DimColor',     COUNT(*), 4   FROM DimColor
    UNION ALL SELECT 'DimTamano',    COUNT(*), 3   FROM DimTamano
    UNION ALL SELECT 'DimVivero',    COUNT(*), 2   FROM DimVivero
    UNION ALL SELECT 'FactVentas',   COUNT(*), 30  FROM FactVentas
    UNION ALL SELECT 'FactCosechas', COUNT(*), 223 FROM FactCosechas
) AS verificacion
ORDER BY tabla;
