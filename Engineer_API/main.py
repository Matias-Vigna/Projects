from extraccion_monedas import ejecutar_pipeline

# Función que muestra un menú de opciones para seleccionar pares de monedas
def mostrar_menu_monedas():
    print("Seleccione las monedas que desea importar (separe con coma):")
    print("1. usd-brl (Dólar con Real)")
    print("2. btc-usd (Bitcoin con Dólar)")
    print("3. ars-usd (Peso Argentino con Dólar)")
    
    # Mapeo de opciones numéricas a los pares reales de monedas
    opciones = {
        "1": "usd-brl",
        "2": "btc-usd",
        "3": "ars-usd"
    }

    # Entrada del usuario
    seleccion = input("> Ingrese números separados por coma (ej: 1,3): ")
    indices = [x.strip() for x in seleccion.split(",")]
    monedas = []

    # Validación de cada opción ingresada
    for i in indices:
        if i in opciones:
            monedas.append(opciones[i])
        else:
            print(f"[WARN] Opción inválida ignorada: {i}")
    
    # Si no se seleccionó nada válido, se aborta la ejecución
    if not monedas:
        print("[ERROR] No se seleccionó ninguna moneda válida. Abortando.")
        exit(1)

    return monedas

# Función que permite al usuario elegir entre los dos formatos de salida disponibles
def seleccionar_formato():
    print("\nSeleccione el formato de salida:")
    print("1. csv")
    print("2. txt")
    seleccion = input("> Ingrese el número de opción: ")

    if seleccion == "1":
        return "csv"
    elif seleccion == "2":
        return "txt"
    else:
        print("[ERROR] Opción de formato no válida. Abortando.")
        exit(1)

# Función principal del script, donde se orquesta toda la ejecución
def main():
    print("=== Importador de Cotizaciones ===\n")

    # Paso 1: selección de monedas
    monedas = mostrar_menu_monedas()

    # Paso 2: selección de formato de salida
    formato = seleccionar_formato()

    # Paso 3: ejecución del pipeline con las opciones elegidas
    print("\n[INFO] Iniciando proceso de extracción y guardado...\n")
    ejecutar_pipeline(monedas, formato)
    print("\n[INFO] Proceso finalizado.")

# Punto de entrada del script
if __name__ == "__main__":
    main()
