import requests
import csv
from datetime import datetime

# Diccionario que mapea cada par de monedas con su correspondiente endpoint de la API
ENDPOINTS = {
    "usd-brl": "https://economia.awesomeapi.com.br/json/last/USD-BRL",
    "btc-usd": "https://economia.awesomeapi.com.br/json/last/BTC-USD",
    "ars-usd": "https://economia.awesomeapi.com.br/json/last/ARS-USD"
}

# Función que consulta la API para un par de monedas específico
def obtener_datos(moneda):
    url = ENDPOINTS.get(moneda)
    if not url:
        print(f"[ERROR] No se encontró endpoint para {moneda}")
        return None

    try:
        print(f"[INFO] Solicitando datos para {moneda}...")
        response = requests.get(url, timeout=10)  # Llamado a la API con timeout de 10 segundos
        response.raise_for_status()  # Lanza excepción si la respuesta tiene error HTTP
        return response.json()  # Retorna el contenido JSON si todo salió bien
    except Exception as e:
        print(f"[ERROR] Falló la solicitud para {moneda}: {e}")
        return None

# Función que toma los datos crudos y los transforma al formato normalizado requerido
def normalizar_dato(moneda, datos_raw):
    try:
        clave = list(datos_raw.keys())[0]  # Ej: 'USDBRL', 'BTCUSD', etc.
        info = datos_raw[clave]  # Accedemos al diccionario con la info puntual

        # Extraemos los campos necesarios
        moneda_base = info["code"]
        moneda_destino = info["codein"]
        valor_compra = float(info["bid"])
        valor_venta = float(info["ask"])
        timestamp = int(info["timestamp"])

        # Convertimos el timestamp a formato UTC legible
        fecha_hora = datetime.utcfromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M:%S')

        # Devolvemos los datos en formato estructurado
        return {
            "moneda_base": moneda_base,
            "moneda_destino": moneda_destino,
            "valor_compra": valor_compra,
            "valor_venta": valor_venta,
            "fecha_hora": fecha_hora
        }
    except Exception as e:
        print(f"[ERROR] Falló la normalización de {moneda}: {e}")
        return None

# Función que guarda todos los datos recolectados en el formato especificado (csv o txt)
def guardar_archivo(datos, formato):
    import os

    # Ruta base: ubicación del script actual (extraccion_monedas.py)
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))

    # Ruta completa a la carpeta 'output/' dentro del proyecto
    output_dir = os.path.join(BASE_DIR, "output")
    os.makedirs(output_dir, exist_ok=True)  # Crea la carpeta si no existe

    # Nombre completo del archivo final dentro de 'output/'
    nombre_archivo = os.path.join(output_dir, f"datos_monedas.{formato}")

    try:
        with open(nombre_archivo, mode="w", newline='', encoding='utf-8') as f:
            # Nombres de las columnas a escribir
            campos = ["moneda_base", "moneda_destino", "valor_compra", "valor_venta", "fecha_hora"]

            if formato == "csv":
                writer = csv.DictWriter(f, fieldnames=campos)
                writer.writeheader()
                writer.writerows(datos)  # Escribimos todas las filas

            elif formato == "txt":
                f.write(",".join(campos) + "\n")  # Cabecera manual
                for fila in datos:
                    f.write(",".join(str(fila[c]) for c in campos) + "\n")  # Cada fila como línea de texto

        print(f"[OK] Archivo generado exitosamente: {nombre_archivo}")

    except Exception as e:
        print(f"[ERROR] No se pudo guardar el archivo: {e}")

# Función principal que orquesta todo el proceso:
# 1. Extrae los datos para cada moneda
# 2. Normaliza los resultados
# 3. Guarda el archivo final
def ejecutar_pipeline(monedas, formato):
    datos_finales = []

    for moneda in monedas:
        datos_raw = obtener_datos(moneda)
        if datos_raw:
            normalizado = normalizar_dato(moneda, datos_raw)
            if normalizado:
                datos_finales.append(normalizado)

    if datos_finales:
        guardar_archivo(datos_finales, formato)
    else:
        print("[WARN] No se obtuvieron datos válidos. No se generó archivo.")
