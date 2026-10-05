# [1.5] Justificación metodológica — Kimball (bottom-up) vs Inmon (top-down)

**Decisión:** se construyó el Data Warehouse con la metodología de **Ralph Kimball** (modelo dimensional, esquema estrella, de abajo hacia arriba).
Modelo: ver `04_diagrama_estrella.md`. Tablas: `FactVentas` y `FactCosechas` (hechos); `DimTiempo`, `DimCliente`, `DimColor`, `DimTamano` y `DimVivero` (dimensiones). DDL: `04_ddl_datawarehouse.sql`.

| Criterio | Kimball (elegida) | Inmon (descartada) | Resultado para la cooperativa |
|---|---|---|---|
| **Rapidez y tamaño de implementación** | Se construye primero lo que se necesita (ventas y cosechas) y se amplía después. | Exige primero un modelo empresarial normalizado de toda la organización y luego los data marts. | Kimball: la cooperativa tiene 2 socios, un solo proceso de negocio y poco tiempo. |
| **Enfoque en preguntas de negocio** | Las dimensiones (cliente, color, tamaño, tiempo, vivero) responden directo "¿cuánto se vendió a cada cliente por color?". | Prioriza la integración de datos de toda la empresa antes de las preguntas concretas. | Kimball: el dashboard necesita esas preguntas puntuales (RF4). |
| **Complejidad de consulta** | Esquema estrella: pocas uniones, fácil de usar en Power BI. | Modelo normalizado: más tablas y uniones antes de llegar al dato. | Kimball: consultas y drill-down más simples. |
| **Integración de fuentes** | Funciona bien con pocas fuentes (2 archivos). | Conviene con muchas fuentes y áreas. | Kimball: solo hay dos fuentes. |

## Condición en la que Inmon sería preferible
Si la cooperativa creciera a muchas áreas (producción, personal, contabilidad, transporte) con varios sistemas fuente que deban integrarse en una única versión de los datos, convendría un almacén central normalizado al estilo Inmon y derivar de él los data marts dimensionales.
