# [2.2] Defensa de decisiones técnicas — alternativa descartada y criterio diferenciador

Cada fila responde lo que pregunta el panel: **qué decidimos, qué descartamos y por qué** (criterio con dato del proyecto). Las cifras salen de los archivos del repositorio.

## Bloque 1 — Automatización (`01_automatizacion/`)

| Decisión | Alternativa descartada | Criterio diferenciador |
|---|---|---|
| Reglas de negocio en SQL Server (procedimientos, funciones y triggers) | Reglas en una aplicación que solo guarda en la base | **Integridad:** el trigger `trg_ValidarPrecioPorTallo` bloquea un precio incorrecto aunque alguien inserte directo (prueba P5); en una aplicación, un INSERT directo se salta la regla. Sería preferible la aplicación si la cooperativa migra de motor o crea una web con mucha lógica propia. |
| Auditoría con triggers `AFTER INSERT` (`trg_AuditoriaCosecha`, `trg_AuditoriaVenta`) más registro de rechazos dentro de los procedimientos | Auditar solo dentro de los procedimientos | **Cobertura:** el trigger registra aunque el INSERT no pase por el procedimiento; el procedimiento deja constancia de lo que el trigger no ve (`RECHAZO_LIMITE`, `ERROR_INSERT`), porque si el INSERT se deshace su fila de trigger se deshace con él. Se complementan. |
| `SAVEPOINT` en `sp_RegistrarCosecha` para el límite de 120 paquetes por vivero y día | `ROLLBACK` de toda la transacción | **Constancia del rechazo:** con `ROLLBACK TO` el savepoint solo se deshace ese INSERT y se confirma el registro `RECHAZO_LIMITE`; con un `ROLLBACK` total se perdería también la constancia. |

## Bloque 2 — Seguridad y cumplimiento (`02_seguridad/`)

| Decisión | Alternativa descartada | Criterio diferenciador |
|---|---|---|
| 4 roles: `rol_administrador`, `rol_vendedor`, `rol_trabajador_stock` y `rol_contador` | 3 roles genéricos del desafío (administrador, analista, auditor) | **Mínimo privilegio:** en la cooperativa quien vende (`EXECUTE sp_RegistrarVenta`) no es quien cosecha (`EXECUTE sp_RegistrarCosecha`); un solo rol "analista" daría acceso a ambas tareas. Administrador = `rol_administrador` y auditor = `rol_contador` (solo lectura). Con más personal de análisis, el rol "analista" sí sería preferible. |
| Un usuario de SQL Server por rol (4 logins, `MUST_CHANGE`) | Un usuario por persona (8 personas) | **Costo de administración vs. trazabilidad individual:** 4 contraseñas en vez de 8, pero `LogAuditoria.usuario_bd` identifica el rol y no a la persona (limitación declarada en `02_checklist_ley29733.md`). Un usuario por persona sería preferible si hubiera conflictos laborales o más personal. |
| Respaldo FULL semanal + DIFFERENTIAL diario (lunes a sábado) | Solo FULL (semanal o diario) | **Pérdida máxima y espacio:** solo FULL semanal puede perder hasta 6 días de registros; con el DIFFERENTIAL diario se pierde como máximo 1 día; solo FULL diario copia toda la base cada día aunque los datos cambian 3 veces por semana. Costo: restaurar exige 2 pasos (FULL `NORECOVERY` y luego DIFFERENTIAL `RECOVERY`). Solo FULL sería preferible si la base fuera muy pequeña y se priorizara restaurar en un solo paso. |

## Bloque 3 — NoSQL y arquitectura híbrida (`03_nosql/`)

| Decisión | Alternativa descartada | Criterio diferenciador |
|---|---|---|
| Híbrida: SQL Server para cosechas y ventas, MongoDB solo para `pedidos_whatsapp` | SQL Server puro | **Modelo de datos (30 %):** los pedidos llegan con campos variables (notas, cintas, urgencia); en SQL sacan 2 y en MongoDB 5; total del caso B: MongoDB 4,0 frente a SQL 3,3. SQL puro sería preferible si todos los pedidos trajeran los mismos campos. |
| Cosechas y ventas se quedan en SQL Server | MongoDB puro | **Consistencia (30 %):** cosechas y ventas necesitan ACID, triggers y `TRY/CATCH`; total del caso A: SQL 4,4 frente a MongoDB 2,9. MongoDB puro sería preferible si el volumen creciera tanto que importara más repartir los datos en varios servidores. |

## Bloque 4 — Data Warehouse y ETL (`04_datawarehouse/`)

| Decisión | Alternativa descartada | Criterio diferenciador |
|---|---|---|
| Metodología Kimball (de abajo hacia arriba) | Inmon (de arriba hacia abajo) | **Rapidez y preguntas de negocio:** hay 2 socios, un solo proceso y 2 fuentes; Kimball entrega ya "¿cuánto se vendió a cada cliente por color?". Inmon sería preferible con muchas áreas y varios sistemas fuente. |
| Esquema estrella | Copo de nieve | **Uniones vs. ahorro:** las dimensiones son pequeñas (`DimVivero` 2 filas, `DimTamano` 3, `DimCliente` 3, `DimColor` 4, `DimTiempo` 50) y sin jerarquías propias; normalizarlas no ahorra espacio apreciable y agregaría uniones. El copo de nieve sería preferible si una dimensión creciera con jerarquía (por ejemplo vivero → zona → región). |
| Dos tablas de hechos: `FactVentas` y `FactCosechas` | Una sola tabla de hechos combinada | **Granularidad:** una venta (cliente) y una cosecha (vivero) son hechos distintos; mezclarlos dejaría columnas vacías (`id_cliente_dw` en cosechas, `id_vivero_dw` en ventas). Comparten `DimTiempo`, `DimColor` y `DimTamano`. |
| ETL en Python/pandas | SSIS | **Reproducibilidad:** un script que corre con `pip install pandas` en cualquier equipo y deja `log_etl.txt` (corrió en 0,08 s con 246 + 30 filas). SSIS sería preferible con cargas programadas en un servidor con SQL Server Agent. |

## Bloque 5 — Dashboard BI y OLAP (`05_dashboard/`)

| Decisión | Alternativa descartada | Criterio diferenciador |
|---|---|---|
| Power BI Desktop (`dashboard.pbix`) | Metabase | **Infraestructura:** Power BI Desktop es un archivo que se abre sin servidor; Metabase exige levantar y mantener un servidor (Java o Docker) y conectarlo a la base, algo desproporcionado para 2 socios con una carga semanal. Costo: Power BI Desktop solo corre en Windows (declarado en el README). Metabase sería preferible en equipos Linux o macOS, o para compartir el dashboard por web con varios usuarios sin licencias. |
| Operación OLAP documentada: slice/dice (color = Rojo → paquetes por cliente) | Drill-down (color → cliente) como operación principal | **Qué está construido:** en `dashboard.pbix` `color` y `cliente` son filtros separados, sin jerarquía color → cliente; el drill-down exigiría crearla. El slice/dice ya funciona con el segmentador de color sobre el KPI 2 y responde "¿qué cliente compra más de cada color?" (ej. Rojo: 214 paquetes). |

## Bloque 6 — Big Data con Spark (`06_bigdata/`)

| Decisión | Alternativa descartada | Criterio diferenciador |
|---|---|---|
| DataFrame API y SparkSQL | RDDs | **Esquema y simplicidad:** el CSV es tabular con 6 columnas tipadas; DataFrame/SparkSQL se escriben en pocas líneas y Spark los optimiza solo. Los RDD serían preferibles con datos sin estructura, como texto libre. |
| Spark como complemento; el motor del día a día sigue siendo SQL Server | Spark como motor principal | **Volumen real:** la cooperativa tiene 223 cosechas limpias en 10 semanas; los 111.500 registros son una réplica ×500 para poder medir, y Spark paga un costo fijo de arranque. Spark sería preferible con historiales de varios años o muchos viveros (medido sobre 111,500 filas: consulta 1 en 0,057 s con SQL Server y 0,950 s con Spark; consulta 2 en 0,121 s y 0,467 s). |

## Bloque 7 — Ética y responsabilidad profesional (`07_cierre/`)

| Decisión | Alternativa descartada | Criterio diferenciador |
|---|---|---|
| El nombre del trabajador no pasa al Data Warehouse ni a Spark (minimización) | Cargarlo para medir productividad por persona | **Finalidad y dignidad:** el dato se recogió para trazabilidad de calidad, no para evaluar desempeño (Ley N.° 29733, art. 6; CIP, art. 30 a). Sería preferible solo con aviso y consentimiento de los 4 trabajadores. |
| Precio fijo por rango de tallo, calculado por `fn_PrecioPorTamano` | Precio negociado por cliente en una tabla | **Trato uniforme y verificable:** en los datos crudos las 2 ventas con precio inconsistente (ids 9 y 22) eran del mismo cliente y se cobró de más. Los descuentos por volumen serían preferibles si se decidieran y documentaran de forma explícita. |
