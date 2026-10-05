# [1.4] Comparación SQL Server vs MongoDB y decisión de arquitectura

Casos de uso evaluados:
- **A. Cosechas y ventas** (datos con estructura fija y reglas de negocio).
- **B. Pedidos de WhatsApp** (texto libre; algunos traen notas, cintas o urgencia, otros no).

## Criterios y ponderación
| Criterio | Peso | Qué se mide |
|---|---|---|
| Modelo de datos | 30 % | Qué tan bien encaja la forma de los datos |
| Consistencia | 30 % | Transacciones, validaciones y auditoría |
| Escalabilidad | 20 % | Capacidad de crecer en volumen |
| Latencia / consulta | 20 % | Facilidad y rapidez de las consultas del caso |

Puntaje de 1 (malo) a 5 (muy bueno). Total = suma de puntaje × peso.

## A. Cosechas y ventas
| Criterio | Peso | SQL Server | MongoDB | Resultado |
|---|---|---|---|---|
| Modelo de datos | 30 % | 5 (tablas fijas con claves foráneas) | 2 (se pierde la relación entre tablas) | SQL |
| Consistencia | 30 % | 5 (ACID, triggers, `TRY/CATCH`) | 3 (transacciones posibles, sin triggers) | SQL |
| Escalabilidad | 20 % | 3 | 4 | MongoDB |
| Latencia / consulta | 20 % | 4 (JOIN y agregaciones) | 3 | SQL |
| **Total** | 100 % | **4,4** | **2,9** | **SQL Server** |

## B. Pedidos de WhatsApp
| Criterio | Peso | SQL Server | MongoDB | Resultado |
|---|---|---|---|---|
| Modelo de datos | 30 % | 2 (muchas columnas vacías o tablas extra) | 5 (documentos con campos variables) | MongoDB |
| Consistencia | 30 % | 5 | 3 | SQL |
| Escalabilidad | 20 % | 3 | 4 | MongoDB |
| Latencia / consulta | 20 % | 3 | 4 (un pedido completo en un solo documento) | MongoDB |
| **Total** | 100 % | **3,3** | **4,0** | **MongoDB** |

## Decisión: arquitectura híbrida
- **SQL Server** guarda cosechas, ventas, stock, auditoría y seguridad (caso A): ahí importan la integridad y la trazabilidad.
- **MongoDB** guarda `pedidos_whatsapp` (caso B): los pedidos llegan con campos variables.
- Cuando un pedido se confirma, el vendedor lo registra en SQL Server con `sp_RegistrarVenta`; así la venta pasa por las validaciones y por la auditoría.
- Operaciones CRUD de MongoDB: `03_mongodb_operaciones.js`.

**Limitación:** el paso del pedido a la venta es manual (la conexión automática entre ambos motores no se implementa en este proyecto).
