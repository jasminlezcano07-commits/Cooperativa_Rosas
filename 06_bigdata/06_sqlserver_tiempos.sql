-- BLOQUE 6 - Tiempos en SQL Server para comparar con Spark (Tema 7)
-- Mismas 2 consultas, mismas 111,500 filas (223 cosechas limpias x 500 copias idénticas) y mismo método que el notebook
-- 06_analisis_spark.ipynb. No hay que cargar ningún CSV: se replica FactCosechas, que ya está en DW_CooperativaRosas.
-- Antes: haber ejecutado 04_datawarehouse/04_ddl_datawarehouse.sql (todas las filas deben dar OK).
--
-- ANTES DE EJECUTAR (una sola vez en SSMS):
--   Query > Query Options > Results > Grid > marcar "Discard results after execution"
--   (equivale a no usar .show() en Spark: se mide el cálculo, no el dibujo de resultados).

USE DW_CooperativaRosas;
GO

-- 1) Tabla de 111,500 filas (mismas columnas que el CSV de Spark)
DROP TABLE IF EXISTS dbo.CosechasAmpliado;
GO
SELECT f.id_cosecha, t.fecha, v.vivero, c.color, z.tamano_cm, f.cantidad_paquetes
INTO dbo.CosechasAmpliado
FROM dbo.FactCosechas f
JOIN dbo.DimTiempo t ON t.id_tiempo_dw = f.id_tiempo_dw
JOIN dbo.DimVivero v ON v.id_vivero_dw = f.id_vivero_dw
JOIN dbo.DimColor  c ON c.id_color_dw  = f.id_color_dw
JOIN dbo.DimTamano z ON z.id_tamano_dw = f.id_tamano_dw
CROSS JOIN (SELECT TOP (500) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS r
            FROM sys.all_objects a CROSS JOIN sys.all_objects b) n;
GO
SELECT COUNT(*) AS filas FROM dbo.CosechasAmpliado;   -- debe dar 111500
GO

-- 2) Medición. "GO 4" ejecuta cada consulta 4 veces seguidas: la 1.a es el calentamiento (se descarta)
--    y las otras 3 son las que cuentan. En la pestaña Mensajes, tomar de cada ejecución la línea
--    "SQL Server Execution Times: ... elapsed time = N ms" (la de la consulta, no la de "parse and compile"),
--    calcular la MEDIANA de las 3 últimas y pasarla a segundos (ms / 1000).
SET STATISTICS TIME ON;
GO

-- Consulta 1 (SparkSQL en el notebook): SUM por color y tamaño
SELECT color, tamano_cm, SUM(cantidad_paquetes) AS total_paquetes
FROM dbo.CosechasAmpliado
GROUP BY color, tamano_cm
ORDER BY total_paquetes DESC;
GO 4

-- Consulta 2 (DataFrame API en el notebook): promedio por color
SELECT color, AVG(cantidad_paquetes * 1.0) AS promedio_paquetes
FROM dbo.CosechasAmpliado
GROUP BY color;
GO 4

SET STATISTICS TIME OFF;
GO

-- LIMPIEZA (opcional, después de anotar los tiempos en el notebook):
-- DROP TABLE dbo.CosechasAmpliado;
