Proyecto Integrador — CIIN1021P
Cooperativa de Rosas — Francisco Cueva y Zoila Huamán

Llagamarca, Baños del Inca, Cajamarca — Perú

Proyecto integrador desarrollado para la Evaluación Final, basado en la adaptación del caso académico del curso a una cooperativa real dedicada a la producción y comercialización de rosas.

1. Descripción del proyecto

La Cooperativa de Rosas, ubicada en Llagamarca, Baños del Inca, Cajamarca, trabaja con 2 viveros, 4 colores de rosas, 3 rangos de precio según el tamaño del tallo, 4 trabajadores y 3 clientes mayoristas ubicados en Chiclayo.

A partir del relevamiento realizado con Francisco Cueva y Zoila Huamán, se identificó que la cooperativa no contaba con un sistema digital para gestionar y analizar formalmente la información de sus cosechas y ventas.

Por ello, se desarrolló una solución integrada que permite trabajar con los datos desde diferentes perspectivas:

Automatización y validación mediante SQL Server.
Seguridad, control de accesos, respaldos y rendimiento.
Gestión de información no estructurada mediante MongoDB.
Construcción de un Data Warehouse mediante un esquema estrella.
Procesos de ETL con Python y pandas.
Visualización y análisis mediante Power BI.
Procesamiento y comparación de grandes volúmenes de datos mediante Apache Spark.
Evidencias de ejecución, trazabilidad, reflexión ética y defensa de decisiones técnicas.

El proyecto integra los contenidos de los Temas 1 al 7 del curso.

2. Objetivo

Desarrollar una solución de gestión y análisis de datos para la Cooperativa de Rosas que permita mejorar la integridad, seguridad, organización y análisis de la información relacionada con las cosechas y ventas.

La solución busca demostrar cómo diferentes tecnologías de gestión de datos pueden integrarse para transformar información inicialmente dispersa y con problemas de calidad en información estructurada y útil para la toma de decisiones.

3. Alcance

El proyecto comprende los siguientes componentes:

Bloque	Componente	Tecnología principal
00	Datos, relevamiento y requisitos	Markdown / CSV
01	Automatización de base de datos	SQL Server
02	Seguridad, respaldo y rendimiento	SQL Server / SSMS
03	Gestión NoSQL	MongoDB
04	Data Warehouse y ETL	Python / pandas / SQL Server
05	Dashboard, KPIs y OLAP	Power BI
06	Big Data y escalabilidad	Apache Spark / PySpark
07	Cierre, trazabilidad y reflexión ética	Markdown
08	Evidencias de ejecución	Capturas y archivos de resultados
4. Estructura del repositorio
Grupo04_CIIN1021P_EF_REPO/
│
├── 00_datos/
│   ├── 00_relevamiento_supuestos_requisitos.md
│   ├── cosechas_raw.csv
│   └── ventas_raw.csv
│
├── 01_automatizacion/
│   ├── 01_esquema_procedimientos_triggers.sql
│   └── 01_justificacion_diseno.md
│
├── 02_seguridad/
│   ├── 02_seguridad_roles_backup_indices.sql
│   ├── 02_politica_respaldo.md
│   ├── 02_checklist_ley29733.md
│   └── 02_reporte_indice.md
│
├── 03_nosql/
│   ├── 03_mongodb_operaciones.js
│   └── 03_comparacion_sql_vs_nosql.md
│
├── 04_datawarehouse/
│   ├── 04_etl_datawarehouse.py
│   ├── 04_ddl_datawarehouse.sql
│   ├── 04_diagrama_estrella.md
│   ├── 04_kimball_vs_inmon.md
│   ├── log_etl.txt
│   ├── DimTiempo.csv
│   ├── DimTamano.csv
│   ├── DimCliente.csv
│   ├── DimVivero.csv
│   ├── DimColor.csv
│   ├── FactCosechas.csv
│   └── FactVentas.csv
│
├── 05_dashboard/
│   ├── 05_kpis_dashboard.md
│   ├── dashboard.pbix
│   └── dashboard_volumen.pbix
│
├── 06_bigdata/
│   ├── 06_analisis_spark.ipynb
│   ├── 06_sqlserver_tiempos.sql
│   └── cosechas_limpias.csv
│
├── 07_cierre/
│   ├── 07_matriz_trazabilidad.md
│   ├── 07_reflexion_etica.md
│   └── 07_defensa_decisiones.md
│
├── 08_evidencias/
│   ├── 01_automatizacion/
│   ├── 02_seguridad/
│   ├── 03_nosql/
│   ├── 04_datawarehouse/
│   ├── 05_dashboard/
│   └── 06_bigdata/
│
└── README.md
5. Componentes desarrollados
5.1. Datos y relevamiento

En 00_datos/ se documenta el contexto del negocio, los supuestos, requisitos y problemas identificados durante el relevamiento.

Los datos detallados de cosechas y ventas utilizados para las pruebas son sintéticos, debido a que la cooperativa no contaba con registros digitales históricos.

Los datos reales utilizados para contextualizar el proyecto corresponden a información obtenida durante el relevamiento, como:

ubicación del negocio;
cantidad de viveros;
colores de rosas;
rangos de precios;
cantidad de trabajadores;
cantidad y tipo de clientes;
características generales del proceso de cosecha y venta.

Los datasets sintéticos fueron utilizados exclusivamente para demostrar el funcionamiento técnico de la solución.

5.2. Automatización — SQL Server

En 01_automatizacion/ se implementó la base de datos operacional y los mecanismos de automatización.

Se desarrollaron:

tablas del sistema;
funciones;
procedimientos almacenados;
triggers;
transacciones;
validaciones de datos;
control de errores;
registro de operaciones en LogAuditoria.

También se realizaron pruebas de inserciones válidas y operaciones rechazadas para verificar que las reglas de negocio funcionaran correctamente.

La evidencia correspondiente se encuentra en:

08_evidencias/01_automatizacion/
5.3. Seguridad, respaldo y rendimiento

En 02_seguridad/ se implementaron mecanismos de:

control de acceso mediante roles;
usuarios diferenciados;
pruebas de permisos;
respaldo FULL;
respaldo DIFFERENTIAL;
restauración de respaldos;
análisis de índices;
comparación de rendimiento;
revisión de aspectos relacionados con la Ley N.° 29733.

El efecto del índice también fue evaluado mediante métricas de ejecución.

Las evidencias se encuentran en:

08_evidencias/02_seguridad/
5.4. NoSQL — MongoDB

En 03_nosql/ se implementó una colección para representar pedidos gestionados mediante un escenario NoSQL.

Se realizaron operaciones CRUD:

insertMany;
find;
updateOne;
deleteOne.

También se documentó la comparación entre el enfoque relacional y NoSQL, justificando el uso de una arquitectura híbrida.

Las evidencias de ejecución se encuentran en:

08_evidencias/03_nosql/
5.5. Data Warehouse y ETL

En 04_datawarehouse/ se desarrolló un Data Warehouse con esquema estrella, siguiendo el enfoque metodológico de Kimball.

El proceso ETL fue desarrollado utilizando Python y pandas.

El proceso incluye:

lectura de los datos originales;
limpieza y transformación;
normalización de información;
generación de dimensiones;
generación de tablas de hechos;
generación de archivos CSV;
registro del proceso mediante log_etl.txt;
carga posterior de los datos en SQL Server mediante BULK INSERT.

El modelo incluye dimensiones como:

Tiempo;
Cliente;
Color;
Vivero;
Tamaño;

y tablas de hechos relacionadas con:

Cosechas;
Ventas.

La evidencia de carga y validación se encuentra en:

08_evidencias/04_datawarehouse/
5.6. Dashboard y Business Intelligence

En 05_dashboard/ se desarrolló el análisis de información mediante Power BI Desktop.

El modelo permite visualizar los datos del Data Warehouse y analizar las ventas y cosechas mediante indicadores y segmentaciones.

Se implementaron:

KPIs;
gráficos;
segmentadores;
análisis por color;
análisis por cliente;
análisis por tamaño;
análisis temporal;
operaciones OLAP de tipo slice/dice.

Los archivos principales son:

dashboard.pbix
dashboard_volumen.pbix

La documentación de los KPIs, criterios de calidad y gobernanza se encuentra en:

05_kpis_dashboard.md

Las evidencias se encuentran en:

08_evidencias/05_dashboard/
5.7. Big Data — Apache Spark

En 06_bigdata/ se realizó un ejercicio de procesamiento de datos utilizando Apache Spark / PySpark.

Se trabajó con:

Spark DataFrame API;
Spark SQL;
consultas de análisis;
comparación de tiempos con SQL Server;
procesamiento de un volumen ampliado de datos.

El notebook utilizado es:

06_analisis_spark.ipynb

Los tiempos obtenidos durante las pruebas se documentaron y compararon con los resultados obtenidos en SQL Server.

Las evidencias se encuentran en:

08_evidencias/06_bigdata/
6. Resultados obtenidos

Como resultado final, se obtuvo una solución integrada que permite:

validar y automatizar operaciones de la base de datos;
controlar el acceso a la información;
realizar respaldos y restauraciones;
mejorar el rendimiento mediante índices;
gestionar determinados escenarios mediante NoSQL;
transformar datos mediante procesos ETL;
organizar la información en un Data Warehouse;
analizar indicadores mediante Power BI;
realizar operaciones OLAP;
evaluar el procesamiento de grandes volúmenes mediante Spark;
documentar las decisiones técnicas y sus implicancias éticas.

Las pruebas realizadas y sus resultados se encuentran respaldados mediante las evidencias almacenadas en 08_evidencias/.

7. Evidencias

La carpeta:

08_evidencias/

contiene las capturas y resultados obtenidos durante la ejecución de los diferentes bloques del proyecto.

Entre las evidencias se incluyen:

registros de auditoría;
pruebas de permisos;
resultados de respaldos y restauraciones;
planes de ejecución;
operaciones CRUD en MongoDB;
validación de cargas del Data Warehouse;
análisis OLAP;
dashboards;
resultados de Spark;
comparación de tiempos de procesamiento.
8. Tecnologías utilizadas
Tecnología	Uso
SQL Server	Base de datos operacional, automatización, seguridad y Data Warehouse
SQL Server Management Studio	Administración y ejecución de scripts
MongoDB	Gestión NoSQL y operaciones CRUD
Python	ETL y transformación de datos
pandas	Limpieza y transformación de datos
Power BI Desktop	Dashboard, KPIs y análisis OLAP
Apache Spark / PySpark	Procesamiento y análisis Big Data
Google Colab	Ejecución del notebook de Spark
Git	Control de versiones y repositorio

Las herramientas utilizadas corresponden a alternativas gratuitas o de acceso académico disponibles para el desarrollo del proyecto.

9. Requisitos para reproducir el proyecto

Para reproducir los resultados principales se requiere:

SQL Server Developer o Express;
SQL Server Management Studio;
MongoDB Community y/o mongosh;
Python 3;
pandas;
Power BI Desktop;
PySpark;
Google Colab;
Git.
10. Orden recomendado de ejecución

Para reproducir el proyecto desde cero:

1. Relevamiento y datos

Revisar:

00_datos/00_relevamiento_supuestos_requisitos.md

y los datasets:

00_datos/cosechas_raw.csv
00_datos/ventas_raw.csv
2. Automatización

Ejecutar en SQL Server:

01_automatizacion/01_esquema_procedimientos_triggers.sql
3. Seguridad

Ejecutar:

02_seguridad/02_seguridad_roles_backup_indices.sql

y revisar la documentación de:

02_politica_respaldo.md
02_checklist_ley29733.md
02_reporte_indice.md
4. NoSQL

Ejecutar en MongoDB:

03_nosql/03_mongodb_operaciones.js
5. ETL

Ejecutar con Python:

04_datawarehouse/04_etl_datawarehouse.py

Esto genera los archivos necesarios para el Data Warehouse y el análisis posterior.

6. Data Warehouse

Ejecutar en SQL Server:

04_datawarehouse/04_ddl_datawarehouse.sql
7. Dashboard

Abrir con Power BI Desktop:

05_dashboard/dashboard.pbix
05_dashboard/dashboard_volumen.pbix
8. Big Data

Abrir y ejecutar:

06_bigdata/06_analisis_spark.ipynb

La comparación con SQL Server se encuentra en:

06_bigdata/06_sqlserver_tiempos.sql
11. Documentación de cierre

La carpeta 07_cierre/ contiene la documentación final del proyecto:

07_matriz_trazabilidad.md
07_reflexion_etica.md
07_defensa_decisiones.md

Estos documentos permiten relacionar los componentes desarrollados con los objetivos, criterios de evaluación, decisiones técnicas y consideraciones éticas del proyecto.

12. Integrantes
Chávez Díaz Jhajaira Roxana
Lezcano Moreno Mariana Jasmin
Portal Carrión Mariela
Sandoval Villanueva Becsy Yomar
Yopla Huamán Ana Elizabeth
13. Entregables finales

Los principales entregables del proyecto son:

Grupo04_CIIN1021P_EF_REPO
Grupo04_CIIN1021P_EF.pdf
Grupo04_CIIN1021P_EF_PRES.pptx

La declaración de uso de Inteligencia Artificial, cuando corresponde, se presenta mediante el formato solicitado por el aula virtual.

14. Estado final del proyecto

Proyecto culminado y documentado.

Los componentes técnicos fueron implementados, ejecutados y respaldados mediante evidencias. El repositorio contiene el código fuente, scripts, datasets sintéticos, resultados, documentación técnica, dashboards y evidencias correspondientes a los bloques desarrollados durante la Evaluación Final.
