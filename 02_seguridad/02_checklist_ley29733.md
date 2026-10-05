# [1.3] Lista de verificación de cumplimiento — Ley N.° 29733 e ISO 27001

Datos personales que maneja el sistema: nombres de los **4 trabajadores** (y qué cosecha registró cada uno) y datos de los **3 clientes** mayoristas. Los clientes y trabajadores del proyecto son ficticios.

**Nota sobre los roles:** los roles de este proyecto no se llaman igual que los del desafío. El administrador del desafío equivale a `rol_administrador` y el auditor equivale a `rol_contador`; los otros dos roles (`rol_vendedor` y `rol_trabajador_stock`) responden a las tareas propias de la cooperativa. Hay un usuario de SQL Server por rol: `admin_socios`, `vendedor_ventas`, `trabajador_stock` y `contador_externo`.

## Ley N.° 29733 (Ley de Protección de Datos Personales)

| Art. | Qué exige | Cómo se cumple en el proyecto | Evidencia | Estado |
|---|---|---|---|---|
| **6** — Principio de finalidad | Usar los datos solo para el fin declarado | El campo `id_trabajador` se usa para trazabilidad de calidad e inventario, no para evaluar el desempeño (ver `07_reflexion_etica.md`). Los socios deben comunicarlo a los trabajadores. | `07_cierre/07_reflexion_etica.md` | Parcial: es un compromiso organizativo, el sistema no lo impide técnicamente |
| **8** — Principio de calidad | Datos veraces, exactos y actualizados | `CHECK` en cantidades, claves foráneas, procedimientos con `TRY/CATCH`, trigger que bloquea precios incorrectos y ETL que limpia duplicados, nulos, colores y precios. | `01_automatizacion/*.sql`, `08_evidencias/01_automatizacion/logauditoria.png`, `04_datawarehouse/log_etl.txt` | **Cumple:** el 2026-10-02 se ejecutaron en SQL Server las pruebas P2 (cantidad negativa), P3 (venta sobre el stock) y P5 (trigger de precio) con el resultado esperado, y la limpieza del ETL está verificada en `log_etl.txt` |
| **9** — Principio de seguridad | Medidas técnicas, organizativas y legales para proteger los datos | 4 roles con privilegios mínimos, logins con `MUST_CHANGE` y política de contraseñas, respaldo FULL + DIFFERENTIAL con restauración de ambos (FULL y luego DIFF) en una base de prueba. | `02_seguridad_roles_backup_indices.sql` (comparación de filas con resultado OK), `02_politica_respaldo.md`, `08_evidencias/02_seguridad/mensajes_script02_2026-10-02_ejecucion2.txt` | **Cumple:** el 2026-10-02 el FULL, el DIFFERENTIAL, ambos `RESTORE VERIFYONLY` y la restauración FULL + DIFF corrieron sin errores y la tabla comparativa dio `OK` en las 3 tablas (Cosechas, Ventas y LogAuditoria) |
| **16** — Seguridad del tratamiento | El titular del banco de datos debe adoptar medidas que eviten alteración, pérdida o acceso no autorizado | Auditoría automática (`LogAuditoria`) que ni siquiera el administrador puede modificar o borrar (`DENY UPDATE, DELETE`); trabajadores sin acceso directo de escritura; contador solo lectura. | `01_…sql` (triggers), `02_…sql` (roles y pruebas de privilegios a, b, c y d), `08_evidencias/02_seguridad/mensajes_script02_2026-10-02_ejecucion2.txt` | **Cumple:** el 2026-10-02, con Ctrl+M desactivado, las pruebas a y b dieron "permiso denegado" como se esperaba y las pruebas positivas c y d registraron la cosecha y la venta a través de los procedimientos, quedando la auditoría a nombre de `trabajador_stock` y `vendedor_ventas` |

**Leyenda del estado:** *Cumple* = verificado con evidencia ya producida (salida de SQL Server guardada en `08_evidencias/`). *Parcial* = es un compromiso organizativo que el sistema no puede imponer técnicamente.

## ISO 27001:2022 (controles del Anexo A aplicados)

| Control | Descripción | Aplicación |
|---|---|---|
| A.5.15 / A.5.18 | Control de acceso y derechos de acceso | Roles con privilegios diferenciados; cada rol entra con su propio usuario. Los 2 socios comparten `admin_socios` y los 4 trabajadores comparten `trabajador_stock` (limitación declarada abajo). |
| A.5.17 | Información de autenticación | Contraseña temporal de laboratorio (marcador, no real) en cada login, cambio obligatorio en el primer inicio de sesión y política de contraseñas. |
| A.8.13 | Copias de seguridad | FULL + DIFFERENTIAL, retención y prueba de restauración de ambos respaldos (FULL y DIFF restaurados en `CooperativaRosas_TEST`, comparación `OK`, 2026-10-02). |
| A.8.15 | Registro de actividad (logging) | `LogAuditoria` con usuario y fecha/hora; protegida contra edición. |

## Justificación de la segregación de roles (principio de mínimo privilegio)

| Rol (usuario) | Privilegios | Motivo (mínimo privilegio) | Control de la Ley / ISO |
|---|---|---|---|
| `rol_administrador` (`admin_socios`, los 2 socios) | `SELECT, INSERT, UPDATE, DELETE, EXECUTE` sobre `dbo`; `DENY UPDATE, DELETE` sobre `LogAuditoria` | Los socios son dueños del negocio y deben poder corregir datos, pero ni ellos pueden reescribir la evidencia de auditoría. | Ley art. 16; ISO A.5.15 y A.8.15 |
| `rol_vendedor` (`vendedor_ventas`) | `EXECUTE` sobre `sp_RegistrarVenta`; `SELECT` sobre `Cosechas` y `Ventas` | Solo necesita registrar ventas y ver el stock. No escribe directo en las tablas ni registra cosechas. | Ley art. 9; ISO A.5.15 |
| `rol_trabajador_stock` (`trabajador_stock`, los 4 trabajadores) | `EXECUTE` sobre `sp_RegistrarCosecha`; `SELECT` sobre `Cosechas`; `DENY INSERT, UPDATE, DELETE` sobre `Cosechas` | Registra cosechas solo por el procedimiento, así cada dato pasa por las validaciones y deja auditoría. No ve `Ventas` (datos de clientes) ni `LogAuditoria`. | Ley arts. 8 y 16; ISO A.5.15 y A.8.15 |
| `rol_contador` (`contador_externo`) | `SELECT` sobre `LogAuditoria`, `Ventas` y `Cosechas`; `DENY INSERT, UPDATE, DELETE` sobre `dbo` | Revisa y audita sin poder modificar nada (equivale al auditor del desafío). | Ley art. 16; ISO A.5.18 y A.8.15 |

## Consecuencias de las decisiones de seguridad sobre las personas afectadas
Las personas afectadas son los **4 trabajadores**, los **3 clientes mayoristas** y los **2 socios**.

1. **Los trabajadores solo registran cosechas con `sp_RegistrarCosecha` (sin INSERT/UPDATE/DELETE directo).**
   - *Protege:* nadie puede cambiar en silencio lo que un trabajador registró; si hay un reclamo, el historial de `LogAuditoria` respalda al trabajador.
   - *Expone / cuesta:* un trabajador que se equivoca de cantidad no puede corregirla; debe pedírselo a un socio. Además, cada acción queda ligada a su nombre y hora, lo que podría usarse para vigilarlo (Dilema 1 en `07_reflexion_etica.md`).
2. **Sin seguridad por filas y con un contador externo de solo lectura.** Los 4 trabajadores pueden ver las cosechas de sus compañeros, y `contador_externo` puede leer `Ventas` y `LogAuditoria`, es decir, cuánto compra cada uno de los 3 clientes y qué usuario hizo cada operación. Eso expone información comercial de los clientes y datos de actividad de los trabajadores a una persona ajena a la cooperativa. Se mitiga con un compromiso escrito del contador, no con control técnico.
3. **Respaldo diario DIFFERENTIAL y copia semanal fuera del equipo.** Si el equipo falla, se pierde como máximo un día de registros y las personas que cosechan o venden ese día deben volver a ingresarlos. A cambio, la copia en el disco externo o en la nube de un socio contiene nombres de trabajadores y clientes; si esa cuenta o disco se vulnera, los datos quedan expuestos porque los respaldos no están cifrados (limitación declarada abajo).

## Discrepancia detectada en el enunciado del desafío
El desafío pide verificar "el artículo 11 de la Ley N.° 29733 respecto a medidas de seguridad técnica". En el texto de la ley, el **art. 11 es el principio de nivel de protección adecuado** (flujo transfronterizo de datos). Las medidas de seguridad técnica están en el **art. 9** (principio de seguridad) y el **art. 16** (seguridad del tratamiento). Por eso esta lista verifica los arts. 9 y 16, y no el 11. Este proyecto no envía datos fuera del país, por lo que el art. 11 no aplica.

## Limitaciones declaradas
- No hay seguridad por filas: los trabajadores pueden consultar todas las cosechas, no solo las suyas.
- Hay un usuario de SQL Server por rol, no por persona: la auditoría por usuario distingue roles, y la persona que cosechó depende del `id_trabajador` declarado al registrar.
- No se implementó cifrado de la base ni de los respaldos (fuera del alcance del sílabo).
