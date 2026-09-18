--DDL del Data Warehouse - Esquema estrella (Kimball)
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
    cantidad_paquetes INT,
    trabajador VARCHAR(100)
);

/* Los CSV generados por el ETL (ver 04_etl_datawarehouse.py) se cargan
   aquí con BULK INSERT o el asistente de importación de SSMS:
   DimTiempo, DimCliente, DimColor, DimTamano, DimVivero, FactVentas,
   FactCosechas. */
