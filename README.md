# Proyecto Integrador — CIIN1021P
## Cooperativa de Rosas — Francisco Cueva y Zoila Huamán
### Llagamarca, Baños del Inca, Cajamarca

Adaptación del caso "DataSalud Perú / DIRESA La Libertad" (evaluación final del curso) a un negocio real: una cooperativa de 2 viveros de rosas, 4 colores, 3 rangos de precio por tallo, 4 trabajadores y 3 clientes mayoristas en Chiclayo.

## Estructura del repositorio
```
00_datos/           -> Relevamiento, supuestos, requisitos y dataset sintético (con problemas de calidad)
01_automatizacion/  -> Esquema SQL Server, 2 procedimientos, 2 triggers, 1 función (Tema 1-2)
02_seguridad/       -> Roles, backup FULL+DIFFERENTIAL, índice/plan de ejecución, checklist Ley 29733 (Tema 3)
03_nosql/           -> Colección MongoDB, CRUD, comparación SQL vs NoSQL (Tema 4)
04_datawarehouse/   -> ETL en Python, DDL del Data Warehouse (esquema estrella, Kimball) (Tema 5)
05_dashboard/       -> KPIs, gobernanza, dashboard en Power BI Desktop (.pbix) y operación OLAP (Tema 6)
```

## Estado de evidencia 
- **Dashboard (Bloque 5):** construido en **Power BI Desktop** (gratuito), conectando `04_datawarehouse/FactVentas.csv` y las dimensiones como modelo en estrella. Contiene los 3 KPIs y el drill-down (Color → Cliente). Ver `05_dashboard/05_kpis_dashboard.md` para las fórmulas, la gobernanza y la justificación de la herramienta.

## Herramientas requeridas (todas gratuitas)
- SQL Server Express + SSMS
- MongoDB Community Server (o MongoDB Atlas free tier)
- Python 3 + pandas
- Power BI Desktop (gratuito) para el dashboard

## Orden de ejecución
1. `00_datos/00_relevamiento_supuestos_requisitos.md` — leer contexto y supuestos.
2. `01_automatizacion/01_esquema_procedimientos_triggers.sql` — ejecutar en SSMS.
3. `02_seguridad/02_seguridad_roles_backup_indices.sql` — ejecutar en SSMS.
4. `03_nosql/03_mongodb_operaciones.js` — ejecutar en `mongosh` o MongoDB Compass.
5. `04_datawarehouse/04_etl_datawarehouse.py` — ejecutar con Python (lee `00_datos/*_raw.csv`, genera el DW en CSV).
6. `04_datawarehouse/05_ddl_datawarehouse.sql` — ejecutar en SSMS y cargar los CSV generados.

## Nota sobre los datos
Los datos detallados de cosechas y ventas son **sintéticos** (generados con autorización de los socios de la cooperativa, quienes no llevan registro digital). Los datos reales del negocio (ubicación, colores, precios, número de clientes/trabajadores, frecuencia de cosecha) sí provienen de la entrevista directa con Francisco Cueva y Zoila Huamán.
