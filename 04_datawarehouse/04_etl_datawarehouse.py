"""
BLOQUE 4: Data Warehouse (metodología Ralph Kimball, bottom-up) + ETL
Modelo dimensional: esquema estrella
  - Tablas de hechos: FactVentas (ventas) y FactCosechas (producción)
  - Dimensiones: DimTiempo, DimCliente, DimColor, DimVivero, DimTamano
    (FactVentas usa DimCliente; FactCosechas usa DimVivero; el resto es compartido)

Este ETL limpia a propósito los problemas de calidad inyectados en
cosechas_raw.csv / ventas_raw.csv (duplicados, nulos, colores mal
escritos, precios inconsistentes) — ver [1.1] Ficha de relevamiento.

Por qué Kimball y no Inmon (2 criterios):
  1) Rapidez de implementación: la cooperativa necesita un dashboard
     simple y rápido (bottom-up), no un modelo corporativo completo
     (Inmon exige construir primero un modelo empresarial general).
  2) Orientado a preguntas de negocio concretas (ventas por color,
     cliente y vivero), que es el enfoque bottom-up de Kimball.
"""

import os
import pandas as pd
from datetime import datetime

log = []
def registrar(paso):
    # Cada línea del log lleva fecha y hora de ejecución
    linea = f"[{datetime.now():%Y-%m-%d %H:%M:%S}] {paso}"
    log.append(linea)
    print(linea)

inicio_etl = datetime.now()
registrar("INICIO del ETL")

COLORES_VALIDOS = {"Rojo", "Amarillo", "Blanco", "Rosado"}

# EXTRACT 
cosechas = pd.read_csv("../00_datos/cosechas_raw.csv")
ventas = pd.read_csv("../00_datos/ventas_raw.csv")
registrar(f"Extraídos {len(cosechas)} registros de cosechas y {len(ventas)} de ventas (datos crudos)")
colores_invalidos_cosechas_crudo = int((~cosechas["color"].isin(COLORES_VALIDOS)).sum())
colores_invalidos_ventas_crudo = int((~ventas["color"].isin(COLORES_VALIDOS)).sum())
registrar(f"Colores inconsistentes detectados en datos crudos: {colores_invalidos_cosechas_crudo} en cosechas y {colores_invalidos_ventas_crudo} en ventas")

# TRANSFORM 
# 1) Eliminar duplicados exactos
antes = len(cosechas)
cosechas = cosechas.drop_duplicates()
registrar(f"Duplicados eliminados en Cosechas: {antes - len(cosechas)}")

# 2) Eliminar filas con cantidad de paquetes nula (no se puede inventar ese dato)
antes = len(cosechas)
cosechas = cosechas.dropna(subset=["cantidad_paquetes"])
registrar(f"Filas con cantidad_paquetes nula eliminadas: {antes - len(cosechas)}")

# 3) Normalizar colores mal escritos a los 4 colores válidos
mapa_colores = {
    "rojo": "Rojo", "ROJO": "Rojo", "Rojoo": "Rojo",
    "amarillo ": "Amarillo", "AMARILLO": "Amarillo",
    "Blanc0": "Blanco",
    "rosado": "Rosado", "Rosad0": "Rosado",
}
colores_corregidos_cosechas = int((cosechas["color"] != cosechas["color"].replace(mapa_colores)).sum())
colores_corregidos_ventas = int((ventas["color"] != ventas["color"].replace(mapa_colores)).sum())
cosechas["color"] = cosechas["color"].replace(mapa_colores)
ventas["color"] = ventas["color"].replace(mapa_colores)
registrar(f"Colores corregidos: {colores_corregidos_cosechas} en cosechas y {colores_corregidos_ventas} en ventas (normalizados a: Rojo, Amarillo, Blanco, Rosado)")
descartados_con_color_malo = colores_invalidos_cosechas_crudo - colores_corregidos_cosechas
if descartados_con_color_malo:
    registrar(f"Nota: {descartados_con_color_malo} de los {colores_invalidos_cosechas_crudo} colores inconsistentes estaban en filas descartadas antes (duplicados o cantidad_paquetes nula), por eso no se corrigen")
assert cosechas["color"].isin(COLORES_VALIDOS).all() and ventas["color"].isin(COLORES_VALIDOS).all(), "Quedaron colores fuera del catálogo"
registrar("Verificación: 0 colores fuera del catálogo tras la normalización")

# 4) Corregir precios inconsistentes: recalcular según el tamaño real (regla de negocio)
precio_correcto = {50: 20.00, 60: 23.00, 80: 26.00}
inconsistentes = (ventas["precio_unitario_paquete"] != ventas["tamano_cm"].map(precio_correcto)).sum()
ventas["precio_unitario_paquete"] = ventas["tamano_cm"].map(precio_correcto)
registrar(f"Precios inconsistentes corregidos: {inconsistentes}")

# 5) Enriquecimiento: ingreso total por fila
ventas["ingreso_total"] = ventas["cantidad_paquetes"] * ventas["precio_unitario_paquete"]
registrar("Enriquecimiento: columna 'ingreso_total' calculada")

# 6) Normalización de fechas
cosechas["fecha"] = pd.to_datetime(cosechas["fecha"])
ventas["fecha"] = pd.to_datetime(ventas["fecha"])
registrar("Fechas normalizadas a tipo datetime")

cosechas["cantidad_paquetes"] = cosechas["cantidad_paquetes"].astype(int)

# 7) Minimización de datos: la columna 'trabajador' no se usa en ningún KPI, así que no pasa
#    al Data Warehouse ni al notebook de Spark (trazabilidad, no vigilancia: ver Dilema 1
#    en 07_reflexion_etica.md). Sigue existiendo en el dato crudo y en SQL Server (Cosechas.id_trabajador).
cosechas = cosechas.drop(columns=["trabajador"])
registrar("Minimización de datos: columna 'trabajador' excluida del Data Warehouse y de cosechas_limpias.csv")

# Construcción de dimensiones 
dim_cliente = ventas[["cliente"]].drop_duplicates().reset_index(drop=True)
dim_cliente["id_cliente_dw"] = dim_cliente.index + 1

dim_color = pd.DataFrame({"color": ["Rojo", "Amarillo", "Blanco", "Rosado"]})
dim_color["id_color_dw"] = dim_color.index + 1

dim_tamano = pd.DataFrame({"tamano_cm": [50, 60, 80]})
dim_tamano["id_tamano_dw"] = dim_tamano.index + 1

dim_vivero = cosechas[["vivero"]].drop_duplicates().reset_index(drop=True)
dim_vivero["id_vivero_dw"] = dim_vivero.index + 1

fechas_todas = pd.concat([cosechas["fecha"], ventas["fecha"]]).drop_duplicates().reset_index(drop=True)
dim_tiempo = pd.DataFrame({"fecha": fechas_todas})
dim_tiempo["id_tiempo_dw"] = dim_tiempo.index + 1
dim_tiempo["anio"] = dim_tiempo["fecha"].dt.year
dim_tiempo["mes"] = dim_tiempo["fecha"].dt.month
dim_tiempo["semana"] = dim_tiempo["fecha"].dt.isocalendar().week

registrar("Dimensiones construidas: DimTiempo, DimCliente, DimColor, DimTamano, DimVivero")

# Tabla de hechos: FactVentas 
fact_ventas = ventas.merge(dim_cliente, on="cliente") \
                    .merge(dim_color, on="color") \
                    .merge(dim_tamano, on="tamano_cm") \
                    .merge(dim_tiempo, on="fecha")

fact_ventas = fact_ventas[[
    "id_venta", "id_tiempo_dw", "id_cliente_dw", "id_color_dw", "id_tamano_dw",
    "cantidad_paquetes", "precio_unitario_paquete", "ingreso_total"
]]
registrar(f"FactVentas construida con {len(fact_ventas)} filas")

# Tabla de hechos: FactCosechas (usa DimVivero) 
fact_cosechas = cosechas.merge(dim_vivero, on="vivero") \
                        .merge(dim_color, on="color") \
                        .merge(dim_tamano, on="tamano_cm") \
                        .merge(dim_tiempo, on="fecha")

fact_cosechas = fact_cosechas[[
    "id_cosecha", "id_tiempo_dw", "id_vivero_dw", "id_color_dw", "id_tamano_dw",
    "cantidad_paquetes"
]]
registrar(f"FactCosechas construida con {len(fact_cosechas)} filas (usa DimVivero)")

# LOAD
# Los CSV se escriben con el mismo orden de columnas que el DDL (04_ddl_datawarehouse.sql)
# y con fin de línea CRLF, para que el BULK INSERT del DDL los cargue en SQL Server.
tablas_dw = {
    "DimTiempo":    dim_tiempo[["id_tiempo_dw", "fecha", "anio", "mes", "semana"]],
    "DimCliente":   dim_cliente[["id_cliente_dw", "cliente"]],
    "DimColor":     dim_color[["id_color_dw", "color"]],
    "DimTamano":    dim_tamano[["id_tamano_dw", "tamano_cm"]],
    "DimVivero":    dim_vivero[["id_vivero_dw", "vivero"]],
    "FactVentas":   fact_ventas,
    "FactCosechas": fact_cosechas,
}
for nombre, tabla in tablas_dw.items():
    tabla.to_csv(f"{nombre}.csv", index=False, lineterminator="\r\n")
    registrar(f"Carga a CSV (staging): {nombre}.csv -> {len(tabla)} filas")
# cosechas_limpias.csv se escribe SOLO en 06_bigdata/ (es el insumo del notebook Spark; no se duplica aquí)
os.makedirs("../06_bigdata", exist_ok=True)
cosechas.to_csv("../06_bigdata/cosechas_limpias.csv", index=False)
registrar(f"Carga a CSV: ../06_bigdata/cosechas_limpias.csv -> {len(cosechas)} filas (insumo del notebook Spark; única copia)")
registrar("Los CSV se cargan a SQL Server con el BULK INSERT de 04_ddl_datawarehouse.sql; sus COUNT(*) deben coincidir con las filas de arriba")
fin_etl = datetime.now()
registrar(f"FIN del ETL - duración: {(fin_etl - inicio_etl).total_seconds():.2f} s")

with open("log_etl.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(log))

print("\nLog guardado en log_etl.txt")
