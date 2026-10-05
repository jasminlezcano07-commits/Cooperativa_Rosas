# [1.8] Reflexión ética y responsabilidad profesional
## Cooperativa de Rosas — Francisco Cueva y Zoila Huamán (Llagamarca, Baños del Inca, Cajamarca)

Conforme al Código de Ética del Colegio de Ingenieros del Perú (CIP), todo diseño de sistema de
información debe evaluarse no solo por su corrección técnica, sino por sus consecuencias sobre
las personas cuyos datos gestiona: los 2 socios, los 4 trabajadores y los 3 clientes mayoristas
de Chiclayo. Esta reflexión se apoya en estos artículos del Código:

- **Art. 14 (servicio a la sociedad):** los ingenieros están al servicio de la sociedad y deben dar
  importancia primordial a la seguridad; la protección de los datos de las personas es parte de ese
  servicio (roles, respaldo y auditoría del Bloque 2).
- **Art. 15 (integridad, honestidad e imparcialidad):** entre sus principios están la honestidad, el
  respeto y la justicia; guía el trato a trabajadores y clientes (Dilemas 1 y 2).
- **Art. 18 (respeto de las leyes):** el ingeniero respeta las leyes y disposiciones de su profesión
  y actúa con honradez; el diseño cumple la Ley N.° 29733 (ver `02_checklist_ley29733.md`).
- **Art. 19 (diligencia técnica):** el ingeniero actúa conforme a reglas técnicas, con diligencia, y
  autoriza trabajos solo cuando tiene la convicción de su idoneidad y seguridad; las reglas se
  implementan y se prueban en el sistema, no se dejan a la memoria de las personas (funciones, trigger
  y roles).
- **Art. 30 a) (dignidad de los trabajadores):** es contrario a la ética (falta leve) infringir las normas
  de respeto a la dignidad de los trabajadores vinculados a los proyectos del ingeniero. Aquí se aplica
  por extensión: los datos de producción no deben usarse para vigilar ni humillar a quienes cosechan
  (Dilema 1).

*Fuente verificada: texto oficial del Código de Ética del Colegio de Ingenieros del Perú
(`cip.org.pe/publicaciones/reglamentosCNCD2018/codigo_de_etica_del_cip.pdf`), consultado el 01/10/2026.
Los números de artículo y su contenido coinciden con ese texto.*

## Dilema ético 1 — Privacidad y trazabilidad de los datos de los 4 trabajadores

**Descripción del dilema:** el sistema registra qué trabajador realizó cada cosecha (tabla
`Cosechas`, columna `id_trabajador`) para poder auditar producción y detectar inconsistencias. Sin
embargo, esta misma trazabilidad podría usarse indebidamente para vigilar el rendimiento
individual de los 4 trabajadores y tomar decisiones (por ejemplo, de pago o de despido) sin que
ellos lo sepan ni puedan revisar sus propios registros.

**Decisión tomada:** se limitó el propósito declarado del campo `id_trabajador` a trazabilidad de
calidad e inventario (saber qué vivero y qué persona reportó una cosecha, para poder corregir
errores de registro), no a evaluación de desempeño. En la base de datos esto se apoya en los roles
definidos en el Bloque 2:

- `rol_trabajador_stock` registra cosechas únicamente con `sp_RegistrarCosecha` (sin INSERT, UPDATE
  ni DELETE directo) y puede consultar `Cosechas`.
- `rol_vendedor` solo registra ventas con `sp_RegistrarVenta` y consulta `Cosechas` y `Ventas`.
- `rol_contador` tiene solo lectura (log, ventas y cosechas).
- `rol_administrador` (los socios) tiene control total sobre los datos, pero **no puede modificar ni
  borrar `LogAuditoria`** (`DENY UPDATE, DELETE`), de modo que nadie, ni los socios, puede alterar el
  historial de qué operaciones se hicieron, cuándo y con qué usuario de SQL Server. Ese usuario
  identifica el rol, no a la persona: los 4 trabajadores comparten `trabajador_stock`.

Además, por minimización de datos, el nombre del trabajador **no pasa al Data Warehouse ni al
análisis de Spark**: el ETL lo descarta porque ningún KPI lo usa, y así el análisis de producción solo
puede hacerse por vivero, color y semana, nunca por persona. Esta decisión responde al **art. 15**
(respeto y justicia hacia los trabajadores), al **art. 30 a)** (dignidad de los trabajadores) y al
**art. 18** (la Ley N.° 29733 exige usar los datos solo para su finalidad declarada).

**Consecuencias sobre los afectados:** los trabajadores cuentan con un historial de operaciones que
no se puede alterar (qué se registró, cuándo y desde qué usuario), lo que ayuda ante reclamos
injustos. Pero ese historial **no prueba quién cosechó**: como los 4 comparten el usuario
`trabajador_stock` y el `id_trabajador` lo declara quien registra, un trabajador podría anotar el id
de otro; en un conflicto habría que contrastarlo con otra evidencia (misma limitación declarada en
`02_checklist_ley29733.md`). Además quedan expuestos a que los socios, como administradores, vean el
detalle completo, y a que cualquier trabajador pueda consultar las cosechas de sus compañeros, porque
**el sistema no implementa restricción por filas**: cada rol ve todas las cosechas, no solo las suyas. Por eso la protección real depende de un
compromiso: los socios deben comunicar explícitamente a los 4 trabajadores qué datos se registran y
para qué, ya que el sistema no impide técnicamente que se usen con otro fin.

## Dilema ético 2 — Transparencia y trato equitativo hacia los 3 clientes mayoristas

**Descripción del dilema:** el sistema maneja 3 precios distintos según el tamaño del tallo
(S/ 20 para 50 cm o menos, S/ 23 para 60 cm, S/ 26 para 70-90 cm) aplicados a solo 3 clientes
fijos. Al automatizar el registro de ventas, existe el riesgo de que se apliquen precios distintos
al mismo cliente por el mismo producto (trato desigual encubierto), o que un cliente no tenga forma
de verificar que se le cobró el precio correcto. En los datos crudos esto ocurrió: las 2 ventas con
precio inconsistente (id 9, cobrada a S/ 28 en vez de S/ 23, e id 22, cobrada a S/ 25 en vez de
S/ 20) correspondían al mismo cliente, Distribuidora Flor del Valle, y en ambos casos el cobro fue
mayor al acordado.

**Decisión tomada:** los 3 precios se definieron como reglas fijas por rango de tamaño (no por
cliente). `sp_RegistrarVenta` no recibe el precio: lo calcula la función `fn_PrecioPorTamano`. Además,
el trigger `trg_ValidarPrecioPorTallo` **bloquea** (con `THROW` y `ROLLBACK`) cualquier venta
insertada directamente con un precio que no corresponda al rango de tallo y deja constancia en
`LogAuditoria`. Esto convierte la política de precios en una regla del sistema, no en una decisión
manual caso por caso, en línea con el **art. 15** (honestidad y justicia hacia los clientes) y con
el **art. 19** (diligencia técnica: la regla se implementó y se probó, no se deja al criterio de
quien registra la venta).

**Consecuencias sobre los afectados:** los 3 clientes de Chiclayo reciben un trato uniforme y
verificable, lo que protege la relación comercial de la cooperativa (2 socios) con sus únicos
compradores. Si en el futuro la cooperativa quisiera dar descuentos por volumen a un cliente
específico, tendría que decidirlo explícitamente y documentarlo. Queda una limitación: los precios
se guardan en la tabla `Paquetes`, y un administrador podría cambiarlos sin que exista un trigger
que registre ese cambio.

## ¿Qué se revisaría si el sistema se escalara (más viveros, más clientes, más trabajadores)?

**A nivel nacional** (por ejemplo, si el mismo sistema se ofreciera a muchas cooperativas florícolas
del país, con cientos de trabajadores y clientes), lo que hoy es un compromiso entre 2 socios y 4
trabajadores tendría que convertirse en obligaciones formales: registrar los bancos de datos
personales ante la Autoridad Nacional de Protección de Datos Personales cuando corresponda, designar
un responsable del tratamiento, cifrar la base y los respaldos, aplicar seguridad por filas y someter
el sistema a auditorías periódicas. Un error o una filtración afectaría a muchas más personas, y el
**art. 14** (servicio a la sociedad) y el **art. 18** (respeto de las leyes) exigirían un nivel de
cuidado proporcional a esa escala. A escala de la cooperativa, se revisaría lo siguiente:

- Formalizar un aviso de privacidad simple para los trabajadores sobre el uso de sus datos de
  producción, y para los clientes sobre cómo se calculan sus precios.
- Revisar la separación de privilegios de `rol_trabajador_stock`: hoy cada trabajador ve todas las
  cosechas; con más personal habría que evaluar limitar lo que cada uno puede ver de su propio trabajo.
- Registrar también los cambios de precios en `Paquetes`.
- Revisar si los respaldos (Bloque 2) y el control de acceso siguen siendo suficientes al
  aumentar el volumen de datos personales almacenados de terceros (más clientes, más
  trabajadores).
