# [1.1] Ficha de relevamiento — Cooperativa de Rosas (Cueva-Huamán)

**Fecha de levantamiento de información:** 29-08-2026
**Fuente:** entrevista directa con los socios Francisco Cueva y Zoila Huamán (dato real de negocio) + dataset sintético generado por el equipo (con autorización de los socios de inventar los registros detallados en vez de usar datos reales de ventas).

## 1. Contexto del dominio
La cooperativa no lleva ningún registro digital (ni Excel). Coordina sus 3 clientes mayoristas de Chiclayo por WhatsApp. Opera 2 viveros en el caserío Llagamarca (Baños del Inca, Cajamarca), con 4 trabajadores que rotan entre ambos viveros. Cosechan 3 veces por semana, entre 20 y 120 paquetes por día de cosecha, de 24 unidades cada paquete, en 4 colores (rojo, amarillo, blanco, rosado) y 3 rangos de precio según el largo del tallo (≤50cm, 60cm, 70-90cm).

## 2. Esquema de tablas fuente (dataset sintético)
| Tabla | Campos | Origen |
|-------|--------|--------|
| `cosechas_raw.csv` | id_cosecha, fecha, vivero, color, tamano_cm, cantidad_paquetes, trabajador | Generado por el equipo, simulando 10 semanas de cosecha |
| `ventas_raw.csv` | id_venta, fecha, cliente, color, tamano_cm, cantidad_paquetes, precio_unitario_paquete | Generado por el equipo, simulando pedidos a los 3 clientes de Chiclayo |

- Volumen: 246 filas de cosecha, 30 filas de venta (10 semanas simuladas).
- Fecha de generación: 29-08-2026.

## 3. Tabla de problemas de calidad detectados (inyectados a propósito)
| Problema | Cantidad de registros afectados | Ejemplo |
|----------|---------------------------------|---------|
| Filas duplicadas exactas | 6 | Misma fila de cosecha repetida dos veces |
| Valores nulos en `cantidad_paquetes` | 19 en el archivo crudo (17 tras quitar los duplicados) | Campo vacío (trabajador olvidó anotar) |
| Colores mal escritos / inconsistentes (12 variantes para 4 colores reales) | 46 de 246 filas de cosecha (18,7 %) | "ROJO", "Rojoo", "Blanc0", "amarillo " (con espacio) |
| Precios inconsistentes con el rango de tallo | 2 de 30 ventas (id_venta 9 y 22) | id 22: tallo de 50cm cobrado a S/25 en vez de S/20; id 9: tallo de 60cm cobrado a S/28 en vez de S/23 |

## 4. Supuestos declarados
1. **Frecuencia y volumen de cosecha:** se asume que cada vivero cosecha en promedio 4 lotes por color/tamaño en cada día de cosecha (3 veces por semana), dentro del rango real de 20 a 120 paquetes/día informado por los socios. Justificación: no existe registro histórico real, por lo que se simula dentro del rango declarado.
2. **Mezcla de colores por paquete:** se asume que cada paquete contiene un solo color y un solo tamaño de tallo (no mezclado), porque los socios no precisaron paquetes mixtos y así se simplifica el modelo de datos sin perder validez para el proyecto.
3. **Nombres de clientes y de trabajadores:** los 3 clientes mayoristas de Chiclayo se representan con nombres ficticios ("Mayorista Chiclayo Norte", "Distribuidora Flor del Valle", "Comercial Rosas SAC") en lugar de sus nombres reales, por confidencialidad del negocio. Los nombres de los 4 trabajadores (Juan Perez, Maria Rojas, Pedro Diaz, Lucia Vega) también son ficticios.
4. **Canal de pedidos:** se asume que todos los pedidos de los 3 clientes llegan por WhatsApp con formato libre (no estructurado), tal como lo indicaron los socios, lo que justifica el uso de una colección NoSQL para ese detalle.
5. **Límite diario de cosecha:** el rango de 20 a 120 paquetes por día informado por los socios se interpreta como máximo por vivero y por día. Justificación: en los datos simulados limpios (sin duplicados) el total diario por vivero va de 20 a 107 paquetes, por lo que la regla es coherente con ellos; `sp_RegistrarCosecha` rechaza (con SAVEPOINT) lo que supere 120 en un vivero y día. (El archivo crudo llega a 114 solo porque cuenta filas duplicadas; tras quitar los 6 duplicados el máximo real es 107.)

## 4.1 Declaración de articulación curricular

Este proyecto integra saberes previos del curso **Base de Datos** (ciclo 3) y deja preparado el caso para los **cursos posteriores**.

**Cursos posteriores y la competencia concreta que este proyecto prepara en cada uno**

| Curso posterior | Competencia concreta | Qué aporta este proyecto |
|---|---|---|
| **Ciencia de Datos** | Preparar y analizar datos para responder preguntas de negocio: limpiar, transformar, agregar e interpretar resultados. | El dataset limpio (`cosechas_limpias.csv`), el esquema estrella y las agregaciones por color, vivero y semana del notebook Spark: es el punto de partida para analizar tendencias o pronosticar la cosecha. |
| **Ingeniería de Software** | Construir una aplicación a partir de requisitos con criterios de éxito verificables, usando la base de datos como capa de datos. | Los requisitos RF1 a RF4 con criterio de éxito y los procedimientos `sp_RegistrarCosecha` y `sp_RegistrarVenta` como interfaz que una futura aplicación (por ejemplo, un formulario para los trabajadores) llamaría sin saltarse las reglas. |

**Tres saberes específicos del ciclo 3 (Base de Datos) y cómo se extienden aquí**

| Saber del ciclo 3 | Cómo se extiende en este proyecto |
|---|---|
| **1. Modelo relacional, claves e integridad** (claves primarias y foráneas, `CHECK`) | Se extiende a integridad automática con triggers: `trg_ValidarPrecioPorTallo` bloquea precios incorrectos aunque el `INSERT` sea directo, y los roles impiden saltarse los procedimientos. |
| **2. Consultas y manipulación con SQL** (`SELECT`, `JOIN`, `GROUP BY`, `INSERT`) | Se extiende a procedimientos con transacciones (`TRY/CATCH`, `SAVEPOINT`), a agregaciones sobre el Data Warehouse (`COUNT(*)` de verificación, KPI) y a las mismas consultas en SparkSQL y en la DataFrame API de Spark. |
| **3. Diseño y normalización del esquema** (catálogos para evitar datos repetidos) | Se aplica en la base transaccional (la tabla `Paquetes` guarda los precios una sola vez) y se contrasta con la desnormalización intencional del esquema estrella (hechos y dimensiones) de Kimball. |

**Fuente del dataset y URL:** no hay URL porque el dataset es **sintético**: lo generó el equipo con autorización de los socios (ver el encabezado de esta ficha) y no se descargó de ningún portal de datos abiertos. Los archivos de origen son `cosechas_raw.csv` y `ventas_raw.csv`, incluidos en esta misma carpeta.

## 5. Requerimientos funcionales (con criterio de éxito verificable)
1. **RF1:** El sistema debe registrar cada cosecha (fecha, vivero, color, tamaño, cantidad, trabajador) evitando cantidades negativas o nulas. *Criterio de éxito:* el procedimiento `sp_RegistrarCosecha` rechaza y registra en el log cualquier intento con cantidad negativa.
2. **RF2:** El sistema debe calcular automáticamente el precio de cada venta según el largo del tallo (S/20, S/23, S/26). *Criterio de éxito:* la función `fn_PrecioPorTamano` devuelve el precio correcto para los 3 rangos en al menos 10 pruebas (sección PRUEBAS de `01_esquema_procedimientos_triggers.sql`, que compara resultado esperado vs obtenido).
3. **RF3:** El sistema debe dejar trazabilidad de con qué usuario y cuándo se registró cada operación. *Criterio de éxito:* la tabla `LogAuditoria` contiene un registro por cada INSERT en `Cosechas` (`trg_AuditoriaCosecha`) y en `Ventas` (`trg_AuditoriaVenta`).
4. **RF4:** El sistema debe permitir consultar, en menos de 3 pasos, cuánto se vendió a cada uno de los 3 clientes por color de rosa. *Criterio de éxito:* el dashboard responde esa pregunta con un slice/dice (filtrar el color y ver los paquetes por cliente).
