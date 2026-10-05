# [1.3] Política de respaldo — Cooperativa de Rosas

Base protegida: `CooperativaRosas` (SQL Server). Los comandos están en `02_seguridad_roles_backup_indices.sql`.

| Elemento | Definición |
|---|---|
| **Tipo de respaldo** | FULL + DIFFERENTIAL (el diferencial guarda solo lo que cambió desde el último FULL) |
| **Frecuencia FULL** | 1 vez por semana (domingo, 10:00 p. m.) |
| **Frecuencia DIFFERENTIAL** | Diario, después de cada día de cosecha (lunes a sábado, 10:00 p. m.) |
| **Retención** | FULL: 4 semanas. DIFFERENTIAL: 2 semanas. Los más antiguos se eliminan. |
| **Ubicación** | 1) Disco local `C:\Backups\` (copia rápida). 2) Copia semanal del FULL en un disco externo o en la nube de uno de los socios, guardada fuera del vivero (por si se daña el equipo). |
| **Responsable** | Socios (`rol_administrador`). El contador no ejecuta ni restaura respaldos. |
| **Verificación** | Cada respaldo se revisa con `RESTORE VERIFYONLY`. |
| **Prueba de restauración** | Una vez al mes se restaura el FULL (`NORECOVERY`) y luego el DIFFERENTIAL (`RECOVERY`) en `CooperativaRosas_TEST`, y se comparan las filas de `Cosechas`, `Ventas` y `LogAuditoria` con la base original. El script muestra también cuántas filas había al momento del FULL, para comprobar que el DIFFERENTIAL aportó los cambios posteriores (OK/FALLA). |

## Por qué esta política
- Los datos cambian solo 3 veces por semana, por lo que un FULL semanal + un DIFFERENTIAL diario ocupa poco espacio y deja perder, como máximo, un día de trabajo.
- La copia fuera del equipo protege ante robo, falla del disco o pérdida del equipo.
- Los respaldos contienen datos de trabajadores y clientes, así que deben guardarse con el mismo cuidado que la base (acceso solo de los socios).

## Relación con la norma
Ley N.° 29733, arts. 9 y 16 (medidas técnicas de seguridad; ver `02_checklist_ley29733.md`) e ISO 27001:2022 control A.8.13 (copias de seguridad de la información).
