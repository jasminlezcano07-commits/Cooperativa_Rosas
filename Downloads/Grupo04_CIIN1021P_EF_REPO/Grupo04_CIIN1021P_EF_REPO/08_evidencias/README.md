# Evidencias de ejecución

Salidas y capturas que respaldan los resultados de cada bloque.

| Carpeta | Archivo | Qué muestra | Estado |
|---|---|---|---|
| `01_automatizacion/` | `logauditoria.png` | `SELECT * FROM LogAuditoria` tras ejecutar el script limpio (03-10-2026): filas `INSERT`, `ERROR_INSERT`, `RECHAZO_LIMITE` y `BLOQUEO_PRECIO`. Faltan los `id_log` 6 y 8 porque sus filas se deshicieron con el `ROLLBACK` (la numeración no se reutiliza). | Subida |
| `02_seguridad/` | `mensajes_script02_2026-10-02.txt` | 1.ª ejecución: pruebas a y b con "permiso denegado" y STATISTICS IO/TIME antes y después del índice (48 → 4 lecturas lógicas). Las pruebas c y d fallaron por tener Ctrl+M activado; se repitieron en la 2.ª ejecución. | Subida |
| `02_seguridad/` | `mensajes_script02_2026-10-02_ejecucion2.txt` | 2.ª ejecución con Ctrl+M desactivado: pruebas c y d correctas, FULL + DIFF y restauración sin errores | Subida |
| `02_seguridad/` | `plan_despues_indice.png` | Plan de ejecución después del índice: Index Seek (NonClustered) | Subida |
| `04_datawarehouse/` | `bulk_insert_count_ok_2026-10-02.txt` | COUNT(*) por tabla contra las filas esperadas | Subida |
| `05_dashboard/` | `olap_slice_dice.png` | Slice/dice: segmentador color = Rojo, 214 paquetes por cliente | Subida |
| `05_dashboard/` | `dashboard_volumen.png` | `dashboard_volumen.pbix` (03-10-2026): 1,846,500 paquetes y 111,500 filas (3,693 reales ×500); barras por color y por tamaño, línea en el tiempo y segmentadores color y vivero | Subida |
| `06_bigdata/` | `spark_tiempos.png` | Medianas de Spark en Colab (0,9498 s y 0,4666 s) | Subida |
| `06_bigdata/` | `mensajes_script06_sqlserver_2026-10-02.txt` | Tiempos de SQL Server (57 ms y 121 ms) | Subida |
| `03_nosql/` | `mongosh_crud_1.png` y `mongosh_crud_2.png` | CRUD de `03_mongodb_operaciones.js` en `mongosh` (03-10-2026): `insertMany` de 3 pedidos, 2 `find`, `updateOne` (modifiedCount 1), `deleteOne` (deletedCount 1) y estado final de 2 pedidos | Subida |
