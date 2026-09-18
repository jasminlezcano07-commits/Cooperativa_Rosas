"""
BLOQUE 4: Data Warehouse (metodología Ralph Kimball, bottom-up) + ETL
Modelo dimensional: esquema estrella
  - Tabla de hechos: FactVentas
  - Dimensiones: DimTiempo, DimCliente, DimColor, DimVivero, DimTamano

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

import pandas as pd

log = []
def registrar(paso):
    log.append(paso)
    print(paso)

# EXTRACT 
cosechas = pd.read_csv("../00_datos/cosechas_raw.csv")
ventas = pd.read_csv("../00_datos/ventas_raw.csv")
registrar(f"Extraídos {len(cosechas)} registros de cosechas y {len(ventas)} de ventas (datos crudos)")

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
cosechas["color"] = cosechas["color"].replace(mapa_colores)
ventas["color"] = ventas["color"].replace(mapa_colores)
registrar("Colores normalizados a: Rojo, Amarillo, Blanco, Rosado")

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
    "cantidad_paquetes", "trabajador"
]]
registrar(f"FactCosechas construida con {len(fact_cosechas)} filas (usa DimVivero)")

# LOAD
dim_cliente.to_csv("DimCliente.csv", index=False)
dim_color.to_csv("DimColor.csv", index=False)
dim_tamano.to_csv("DimTamano.csv", index=False)
dim_vivero.to_csv("DimVivero.csv", index=False)
dim_tiempo.to_csv("DimTiempo.csv", index=False)
fact_ventas.to_csv("FactVentas.csv", index=False)
fact_cosechas.to_csv("FactCosechas.csv", index=False)
cosechas.to_csv("cosechas_limpias.csv", index=False)
registrar("Carga completada: dimensiones + FactVentas + FactCosechas + cosechas_limpias generados")

with open("log_etl.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(log))

print("\nLog guardado en log_etl.txt")
