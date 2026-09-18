# Bloque 5 — Dashboard BI 

Fuente de datos: `FactVentas.csv` + dimensiones (salida del ETL, carpeta `04_datawarehouse/`).
Herramienta sugerida: **Power BI Desktop** (gratuito) o Metabase.

## KPI 1: Ingreso total por color de rosa
- **Fórmula:** SUM(ingreso_total) agrupado por color
- **Fuente:** FactVentas + DimColor
- **Responsable de actualización:** Zoila Huamán (tras cada venta)
- **Frecuencia:** semanal

## KPI 2: Paquetes vendidos por cliente
- **Fórmula:** SUM(cantidad_paquetes) agrupado por cliente
- **Fuente:** FactVentas + DimCliente
- **Responsable:** Francisco Cueva
- **Frecuencia:** semanal (los 3 clientes de Chiclayo)

## KPI 3: Ingreso total por semana
- **Fórmula:** SUM(ingreso_total) agrupado por semana (DimTiempo)
- **Fuente:** FactVentas + DimTiempo
- **Responsable:** Francisco Cueva
- **Frecuencia:** semanal

## Operación OLAP documentada: Drill-down
Partiendo del KPI 1 (ingreso total por color), se hace **drill-down** hasta ver el ingreso por color **y por cliente** en la misma vista (ej. Rojo → Mayorista Chiclayo Norte, Rojo → Distribuidora Flor del Valle). Responde la pregunta de negocio: *"¿qué color le compra más cada cliente?"*

## Preguntas de negocio que responde el dashboard
1. ¿Qué color de rosa genera más ingresos para la cooperativa?
2. ¿Cuál de los 3 clientes de Chiclayo compra más paquetes?

## Gobernanza de datos
- **Completitud:** el ETL descarta filas con `cantidad_paquetes` nula antes de cargar al Data Warehouse (17 filas descartadas, ver `log_etl.txt`).
- **Consistencia:** los colores se normalizan a 4 valores válidos y los precios se recalculan según el rango de tallo (2 precios inconsistentes corregidos).
- **Trazabilidad:** cada registro nuevo en `Cosechas`/`Ventas` queda en `LogAuditoria` con usuario y fecha/hora (Bloque 1).
