# [1.3] Reporte comparativo de rendimiento — antes / después del índice

**Consulta crítica:** ventas de un cliente en un rango de fechas (`id_cliente = 1`, `fecha` entre 2026-01-01 y 2026-03-31).
**Tabla medida:** `VentasPrueba`, con 10,000 filas sintéticas y la misma estructura que `Ventas`, sin triggers (no escribe en `LogAuditoria`). Se usa porque, tras el Bloque 1, `Ventas` tiene muy pocas filas y el optimizador no puede mostrar mejora.
**Índice creado:** `idx_ventasprueba_cliente_fecha` sobre `VentasPrueba (id_cliente, fecha)` con `INCLUDE (cantidad_paquetes, precio_unitario_paquete)`; el mismo índice se crea después en `Ventas` como `idx_ventas_cliente_fecha`.
**Script:** sección "ANÁLISIS DE PLAN DE EJECUCIÓN + ÍNDICE" de `02_seguridad_roles_backup_indices.sql`.
**Evidencia:** salida de la pestaña *Mensajes* en `08_evidencias/02_seguridad/mensajes_script02_2026-10-02.txt` (ejecución del 2026-10-02, SQL Server Express).

| Métrica (STATISTICS IO / TIME) | ANTES del índice | DESPUÉS del índice |
|---|---|---|
| Lecturas lógicas (`VentasPrueba`) | **48** | **4** |
| Tiempo de CPU (ms) | 16 | 0 |
| Tiempo transcurrido (ms) | 105 | 36 |
| Filas devueltas | 270 | 270 |
| Plan de ejecución | Plan real en XML generado por el script (operador esperado: Clustered Index Scan; no se guardó captura) | **Index Seek (NonClustered)** sobre `idx_ventasprueba_cliente_fecha`, 270 filas reales (estimadas: 468); captura en `08_evidencias/02_seguridad/plan_despues_indice.png` |

## Conclusión
- **Mejora en lecturas lógicas: 91.7 %** (de 48 a 4, es decir, 12 veces menos páginas leídas) devolviendo las mismas 270 filas, así que el resultado es idéntico.
- La métrica confiable es la de lecturas lógicas: los tiempos (16/0 ms de CPU y 105/36 ms transcurridos) son muy pequeños con 10,000 filas y el "antes" incluye la primera compilación, así que no se usan para justificar la decisión.
- La caída de 48 a 4 lecturas con el mismo número de filas indica que la consulta dejó de recorrer toda la tabla y pasó a leer solo el rango del índice; el plan posterior confirma un Index Seek sobre el índice nuevo (captura guardada); el plan anterior se espera como Clustered Index Scan, que es lo que explica las 48 lecturas lógicas sobre toda la tabla.
- **Decisión: mantener el índice.** Cubre la consulta (`INCLUDE`), cuesta poco en escritura porque la cooperativa registra pocas ventas por semana y mejora a medida que `Ventas` crezca. Si `Ventas` se mantuviera en pocas decenas de filas, el índice no aportaría y podría descartarse.
- La comprobación final del script (`filas_log_antes` = `filas_log_despues`, resultado `OK`) confirma que la medición no ensució `LogAuditoria`.
