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
| Valores nulos en `cantidad_paquetes` | 17 | Campo vacío (trabajador olvidó anotar) |
| Colores mal escritos / inconsistentes (12 variantes para 4 colores reales) | ~15% de las filas de cosecha | "ROJO", "Rojoo", "Blanc0", "amarillo " (con espacio) |
| Precios inconsistentes con el rango de tallo | 3 de 30 ventas | Tallo de 50cm cobrado a S/25 en vez de S/20 |

## 4. Supuestos declarados
1. **Frecuencia y volumen de cosecha:** se asume que cada vivero cosecha en promedio 4 lotes por color/tamaño en cada día de cosecha (3 veces por semana), dentro del rango real de 20 a 120 paquetes/día informado por los socios. Justificación: no existe registro histórico real, por lo que se simula dentro del rango declarado.
2. **Mezcla de colores por paquete:** se asume que cada paquete contiene un solo color y un solo tamaño de tallo (no mezclado), porque los socios no precisaron paquetes mixtos y así se simplifica el modelo de datos sin perder validez para el proyecto.
3. **Nombres de clientes:** los 3 clientes mayoristas de Chiclayo se representan con nombres ficticios ("Mayorista Chiclayo Norte", "Distribuidora Flor del Valle", "Comercial Rosas SAC") en lugar de sus nombres reales, por confidencialidad del negocio.
4. **Canal de pedidos:** se asume que todos los pedidos de los 3 clientes llegan por WhatsApp con formato libre (no estructurado), tal como lo indicaron los socios, lo que justifica el uso de una colección NoSQL para ese detalle.

## 5. Requerimientos funcionales (con criterio de éxito verificable)
1. **RF1:** El sistema debe registrar cada cosecha (fecha, vivero, color, tamaño, cantidad, trabajador) evitando cantidades negativas o nulas. *Criterio de éxito:* el procedimiento `sp_RegistrarCosecha` rechaza y registra en el log cualquier intento con cantidad negativa.
2. **RF2:** El sistema debe calcular automáticamente el precio de cada venta según el largo del tallo (S/20, S/23, S/26). *Criterio de éxito:* la función `fn_PrecioPorTamano` devuelve el precio correcto para los 3 rangos en al menos 10 pruebas.
3. **RF3:** El sistema debe dejar trazabilidad de quién registró cada operación. *Criterio de éxito:* la tabla `LogAuditoria` contiene un registro por cada INSERT en `Cosechas` y `Ventas`.
4. **RF4:** El sistema debe permitir consultar, en menos de 3 pasos, cuánto se vendió a cada uno de los 3 clientes por color de rosa. *Criterio de éxito:* el dashboard responde esa pregunta con un drill-down.
