# [1.9] Matriz de trazabilidad — Proyecto Cooperativa de Rosas (CIIN1021P)

Cada fila enlaza: logro del curso → tema del sílabo → paso de práctica de campo → sección del entregable → criterio de la rúbrica de la **Evaluación Parcial (EP)** y de la **Evaluación Final (EF)** → componente de evaluación con su peso.

**Logro del curso (sílabo, sección III):** *"Al finalizar el curso, el estudiante implementa un proyecto donde integra la implementación de base datos seguras, toma de decisiones adecuadas a través de la inteligencia de negocios para el correcto tratamiento de grandes volúmenes de datos, haciendo uso correcto de metodologías y herramientas existentes, asegurando la integridad de los datos en todos los contextos."*

**Pesos del sistema de evaluación (sílabo, sección V):** T1 = 10 % (temas 1 a 4) · EP = 20 % (avance hasta la semana 6) · T2 = 20 % (temas 5 a 7) · EF = 50 % (informe y sustentación del proyecto 60 % + laboratorio 40 %).

| Logro del curso (fragmento que cubre la fila) | Tema del sílabo | Paso de práctica de campo | Sección del entregable | Criterio de rúbrica EP (puntaje) | Criterio de rúbrica EF (puntaje) | Componente y peso |
|---|---|---|---|---|---|---|
| "asegurando la integridad de los datos en todos los contextos" | Tema 1: Fundamentos avanzados de BD relacionales | Paso 1: Relevamiento del dominio y selección del dataset | [1.1] Relevamiento, supuestos y articulación curricular | Definición del reto, delimitación del alcance y declaración de supuestos (4 pts); Diagnóstico de riesgos y articulación curricular (4 pts, solo la parte de articulación) | Claridad, estructura de la exposición y comunicación de resultados con soporte en datos (6 pts) | EP (20 %) + T1 (10 %) + EF (50 %) |
| "implementación de base datos seguras" | Temas 1 y 2: Procedimientos, funciones, triggers y transacciones | Paso 2: Diseño de objetos de automatización | [1.2] Automatización mediante objetos de BD | Fundamentación del método y comparación de alternativas técnicas para el bloque de automatización (4 pts) | Automatización con objetos de base de datos y justificación de diseño (2 pts) | EP (20 %) + T1 (10 %) + EF (50 %) |
| "implementación de base datos seguras" | Tema 3: Administración, seguridad y rendimiento | Paso 3: Seguridad y cumplimiento normativo | [1.3] Seguridad y cumplimiento normativo | — (la EP no tiene criterio propio para este bloque) | Seguridad, cumplimiento normativo y análisis de consecuencias sobre los afectados (2 pts) | T1 (10 %) + EF (50 %) |
| "haciendo uso correcto de metodologías y herramientas existentes" | Tema 4: Nuevos paradigmas en el manejo de datos | Paso 4: Exploración NoSQL y decisión de integración | [1.4] Integración SQL–NoSQL | — | Dominio individual y defensa de decisiones técnicas con manejo de alternativas descartadas (6 pts) | T1 (10 %) + EF (50 %) |
| "toma de decisiones adecuadas a través de la inteligencia de negocios" | Tema 5: Inteligencia de negocios y modelado de datos | Paso 5: Diseño del Data Warehouse y ETL | [1.5] Data Warehouse y procesos ETL | — | Data Warehouse, ETL y justificación metodológica (Kimball vs Inmon) (2 pts) | T2 (20 %) + EF (50 %) |
| "toma de decisiones adecuadas a través de la inteligencia de negocios" | Tema 6: Análisis y visualización de datos empresariales | Paso 6: Dashboard BI y análisis OLAP | [1.6] Dashboard BI, KPIs y análisis OLAP | — | Claridad, estructura de la exposición y comunicación de resultados con soporte en datos (6 pts) | T2 (20 %) + EF (50 %) |
| "correcto tratamiento de grandes volúmenes de datos" | Tema 7: Ecosistema Big Data y análisis con Spark | Paso 7: Análisis Big Data con Apache Spark | [1.7] Análisis Big Data con Spark y escalabilidad | — | Claridad, estructura de la exposición y comunicación de resultados con soporte en datos (6 pts) | T2 (20 %) + EF (50 %) |
| "asegurando la integridad de los datos en todos los contextos" (actitud: responsabilidad profesional en la gestión y protección de la información) | Tema 1: Código de ética del ingeniero (subtema 1.1) | Paso 8: Integración, reflexión ética y articulación curricular | [1.8] Reflexión ética y responsabilidad profesional (`07_cierre/07_reflexion_etica.md`) | — | Argumentación ética sobre consecuencias del diseño e impacto sobre los afectados (2 pts) | T1 (10 %) + EF (50 %) |
| "implementa un proyecto donde integra…" (integración de los 3 bloques) | Todos los temas (1 a 7) | Paso 8: Consolidación en repositorio | [1.9] Repositorio de código y trazabilidad; defensa en `07_cierre/07_defensa_decisiones.md` | — | Dominio individual y defensa de decisiones técnicas con manejo de alternativas descartadas (6 pts) | T1 (10 %) + T2 (20 %) + EF (50 %) |

## Cobertura de los 5 criterios de la rúbrica EP (total 20 pts, 4 pts cada uno)

| Criterio EP | Puntaje | Dónde se evidencia |
|---|---|---|
| Definición del reto, delimitación del alcance y declaración de supuestos | 4 | [1.1] `00_datos/00_relevamiento_supuestos_requisitos.md` |
| Planificación y ruta del proyecto con hitos fechados | 4 | Entregable de la EP (cronograma); no forma parte de este repositorio |
| Fundamentación del método y comparación de alternativas técnicas (automatización) | 4 | [1.2] `01_automatizacion/01_justificacion_diseno.md` |
| Validación de viabilidad del componente más incierto | 4 | Entregable de la EP; en la EF los componentes quedan probados en [1.2] a [1.7] |
| Diagnóstico de riesgos y articulación curricular | 4 | Articulación curricular en [1.1] (sección 4.1 del relevamiento); el diagnóstico de riesgos corresponde al entregable de la EP |

## Cobertura de los 6 criterios de la rúbrica EF (total 20 pts)

| Criterio EF | Puntaje | Secciones que lo evidencian |
|---|---|---|
| Automatización con objetos de BD y justificación de diseño | 2 | [1.2] |
| Seguridad, cumplimiento normativo y consecuencias sobre los afectados | 2 | [1.3] |
| Data Warehouse, ETL y justificación metodológica (Kimball vs Inmon) | 2 | [1.5] |
| Dominio individual y defensa de decisiones técnicas | 6 | [1.4], [1.9], `07_defensa_decisiones.md` |
| Argumentación ética sobre consecuencias del diseño | 2 | [1.8] |
| Claridad, estructura de la exposición y comunicación con soporte en datos | 6 | [1.1], [1.6], [1.7] |

Nota: la EP (20 %) cubre el avance hasta la semana 6; la EF (50 %) se compone del informe y la sustentación del proyecto (60 %) y la ejecución de las actividades de laboratorio (40 %). La declaración de uso de IA se entrega con el formato oficial del aula virtual, como anexo del informe (no va en este repositorio).
