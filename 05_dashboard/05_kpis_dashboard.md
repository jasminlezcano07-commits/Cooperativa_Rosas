# [1.6] Bloque 5 — Dashboard BI, KPIs y gobernanza

**Herramienta usada:** Power BI Desktop (gratuito). Archivos: `dashboard.pbix` (ventas) y `dashboard_volumen.pbix` (cosechas, volumen simulado).
**Fuente de datos:** salida del ETL en `04_datawarehouse/` (esquema estrella: `FactVentas`, `FactCosechas` y sus dimensiones).
**Moneda:** todos los montos están en soles (S/); Power BI muestra el símbolo $ por la configuración regional del equipo.
**Actualización de todos los KPI:** semanal (cada lunes). El Data Warehouse se carga por lotes con el ETL (`04_etl_datawarehouse.py`), así que ningún KPI se refresca "en el momento". Las ventas y cosechas sí se registran al instante en SQL Server (`sp_RegistrarVenta`, `sp_RegistrarCosecha`) y quedan en `LogAuditoria`; el dashboard las refleja en el siguiente corte semanal.

> Los valores de conciliación de cada KPI salen de los CSV del ETL (`log_etl.txt`) y sirven para verificar que el dashboard no pierde ni duplica datos.

---

## Página 1 del dashboard — Ventas (`FactVentas`)

### KPI 1: Ingreso total por color de rosa
- **Fórmula:** SUM(`ingreso_total`) agrupado por color
- **Fuente:** `FactVentas` + `DimColor`
- **Responsable de actualización:** Zoila Huamán (refresco semanal)
- **Frecuencia:** semanal
- **Criterios de calidad:**
  - 100 % de las ventas con color dentro de los 4 valores válidos (Rojo, Amarillo, Blanco, Rosado).
  - 100 % de las ventas con precio igual a la regla por tallo (S/ 20, S/ 23, S/ 26); el ETL corrigió 2 precios inconsistentes (ventas 9 y 22).
  - 0 nulos en `ingreso_total`.
  - Conciliación: la suma de los 4 colores = S/ 24,395 (30 ventas).

### KPI 2: Paquetes vendidos por cliente
- **Fórmula:** SUM(`cantidad_paquetes`) agrupado por cliente
- **Fuente:** `FactVentas` + `DimCliente`
- **Responsable de actualización:** Francisco Cueva
- **Frecuencia:** semanal (los 3 clientes de Chiclayo)
- **Criterios de calidad:**
  - 100 % de las ventas asociadas a uno de los 3 clientes de `DimCliente` (sin clave huérfana).
  - 0 nulos y 0 valores ≤ 0 en `cantidad_paquetes`.
  - Conciliación: la suma de los 3 clientes = 1,060 paquetes.

### KPI 3: Ingreso total por semana
- **Fórmula:** SUM(`ingreso_total`) agrupado por semana (`DimTiempo.semana`, semana ISO)
- **Fuente:** `FactVentas` + `DimTiempo`
- **Responsable de actualización:** Francisco Cueva
- **Frecuencia:** semanal
- **Criterios de calidad:**
  - 100 % de las ventas con fecha válida presente en `DimTiempo`.
  - Cobertura: 10 semanas con ventas (semanas ISO 2 a 11 de 2026), sin semanas duplicadas.
  - Conciliación: la suma de las 10 semanas = S/ 24,395 (igual al total del KPI 1).

---

## Dashboard 2 — Volumen de cosechas (`dashboard_volumen.pbix`)
Muestra en Power BI el mismo dataset ampliado del notebook de Spark (Tema 7.4): `cosechas_limpias.csv` replicado ×500 = **111,500 filas**. Como las copias son idénticas, **los totales salen multiplicados por 500** (3,693 paquetes reales × 500); el dashboard sirve para mostrar volumen, no para analizar el negocio real. Segmentadores: `color` y `vivero` (slice/dice).

### KPI 4: Paquetes cosechados por color
- **Fórmula:** SUM(`cantidad_paquetes`) agrupado por color
- **Fuente:** `cosechas_ampliado.csv` (generado en `06_analisis_spark.ipynb` desde `cosechas_limpias.csv`)
- **Responsable de actualización:** Francisco Cueva
- **Frecuencia:** mensual
- **Criterios de calidad:** conciliación con el notebook: Amarillo 531,500, Blanco 462,000, Rosado 439,500 y Rojo 413,500 (total 1,846,500); 0 nulos en `cantidad_paquetes`.

### KPI 5: Paquetes cosechados por tamaño de tallo
- **Fórmula:** SUM(`cantidad_paquetes`) agrupado por `tamano_cm` (50, 60, 80)
- **Fuente / responsable / frecuencia:** igual que el KPI 4
- **Criterios de calidad:** la suma de los 3 tamaños = 1,846,500; solo valores 50, 60 y 80.

### KPI 6: Paquetes cosechados en el tiempo
- **Fórmula:** SUM(`cantidad_paquetes`) por fecha
- **Fuente / responsable / frecuencia:** igual que el KPI 4
- **Criterios de calidad:** abarca las 10 semanas registradas; el total de la línea = 1,846,500.
- Tarjetas de apoyo: **Total paquetes** (1,846,500) y **Total filas** (111,500).

## Operación OLAP documentada: Slice/dice
En la Página 1 del dashboard se hace **slice/dice** con el segmentador `color`: al elegir **color = Rojo**, el gráfico de barras del KPI 2 (paquetes vendidos por cliente) muestra solo las ventas de rosas rojas por cada cliente. Resultado esperado con los datos cargados: **214 paquetes** en total (Distribuidora Flor del Valle 84, Mayorista Chiclayo Norte 83 y Comercial Rosas SAC 47). Al cambiar el color en el segmentador se repite el corte con otro color. Responde la pregunta de negocio: *"¿qué cliente compra más de cada color?"*

> **Nota:** `color` y `cliente` son filtros separados en `dashboard.pbix`; no hay una jerarquía color → cliente, por eso la operación documentada es slice/dice y no drill-down.

## Preguntas de negocio que responde el dashboard
1. ¿Qué color de rosa genera más ingresos para la cooperativa? (KPI 1)
2. ¿Cuál de los 3 clientes de Chiclayo compra más paquetes? (KPI 2)
3. ¿Cómo varía el ingreso semana a semana? (KPI 3)

## Valores medidos de calidad de datos (cosechas: 246 filas crudas; ventas: 30)

Medidos sobre `cosechas_raw.csv`, `ventas_raw.csv`, los CSV de `04_datawarehouse/` y `log_etl.txt`. Fórmula: filas que cumplen ÷ filas evaluadas.

| Dimensión | Indicador | Crudo | Cargado al Data Warehouse |
|---|---|---|---|
| Completitud | Filas de cosecha que llegan al DW | — | **223 de 246 (90,7 %)**: 6 duplicados y 17 nulos (tras quitar duplicados) descartados |
| Completitud | `cantidad_paquetes` informada (cosechas) | 227 de 246 (92,3 %); 19 nulos | 223 de 223 (100 %) |
| Completitud | Nulos en fecha, vivero, color y tamaño (cosechas) | 0 | 0 |
| Completitud | Nulos en ventas (30 filas, todas las columnas) | 0 | 0 |
| Consistencia | Cosechas con color del catálogo | 200 de 246 (81,3 %); 46 inconsistentes | 223 de 223 (100 %); 44 corregidos (los otros 2 estaban en filas descartadas) |
| Consistencia | Ventas con precio igual a la regla por tallo | 28 de 30 (93,3 %) | 30 de 30 (100 %); 2 corregidas (ventas 9 y 22) |
| Consistencia | Duplicados exactos en cosechas | 6 (2,4 %) | 0 |
| Consistencia | Hechos con clave existente en sus dimensiones | — | `FactCosechas` 223 de 223 y `FactVentas` 30 de 30 (0 claves huérfanas) |
| Trazabilidad | Pasos del ETL con fecha y hora en `log_etl.txt` | — | 25 de 25 líneas (100 %) |
| Trazabilidad | Filas de cada CSV del DW frente a `log_etl.txt` | — | 7 de 7 coinciden (50, 3, 4, 3, 2, 30 y 223 filas) |
| Trazabilidad | Identificador de origen único en los hechos | — | `id_cosecha` 223 de 223 y `id_venta` 30 de 30 únicos |
| Trazabilidad | KPI con fuente, fórmula, responsable y frecuencia documentados | — | 6 de 6 |

`LogAuditoria` (registros nuevos en SQL Server) no se mide en este cuadro: sus filas se verifican al ejecutar las pruebas P1 a P8 de `01_esquema_procedimientos_triggers.sql`.

## Gobernanza de datos
- **Completitud:** el ETL descarta filas con `cantidad_paquetes` nula antes de cargar al Data Warehouse (17 filas descartadas, ver `log_etl.txt`).
- **Consistencia:** los colores se normalizan a 4 valores válidos (46 detectados en crudo, 44 corregidos en filas cargadas) y los precios se recalculan según el rango de tallo (2 precios inconsistentes corregidos).
- **Trazabilidad:** cada registro nuevo en `Cosechas`/`Ventas` queda en `LogAuditoria` con usuario y fecha/hora (Bloque 1). Cada línea del `log_etl.txt` lleva fecha y hora de ejecución.

> **Alcance:** `dashboard.pbix` (Página 1, KPI 1 a 3, ventas) cumple el mínimo de 3 KPI de la rúbrica; `dashboard_volumen.pbix` (KPI 4 a 6, cosechas) es el segundo dashboard. Por minimización de datos, ningún KPI se desagrega por trabajador (ver Dilema 1 en `07_reflexion_etica.md`).
